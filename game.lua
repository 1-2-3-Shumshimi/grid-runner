local game = {

  GRID_ROW_SIZE = 32,
  GRID_COL_SIZE = 15, --for a single player, combined grid col size will be 30

  --to be set in enter() func and updated in update()
  gameWidth = 0, gameHeight = 0,
  gridWidth = 0, gridHeight = 0, 
  cellWidth = 0, cellHeight = 0,
  sideBarWidth = 0, sideBarHeight = 0,

  --sidebar logic variables
  tabNames = {"Towers", "Creeps", "Special"},
  currentTab = 1,
  baseHotKeys = {"Q", "W", "E"}, upgradeHotKeys = {"A", "S", "D", "Z", "X", "C"},

  --asset urls
  iconURL = "assets/icons/",
  creepURL = "assets/creep/",
  towerURL = "assets/tower/",
  towerStrings = {"tower_damage", "tower_slow", "tower_distance"},
  towerTitles = {"Damage", "Slow", "Distance"},
  creepStrings = {"creep_cheap", "creep_tank", "creep_fast"},
  creepTitles = {"Cheap", "Tank", "Fast"},
  
  --map and path logic
  player1PathMap = {}, player2PathMap = {},
  WALKABLE = 0, BLOCKED = 1,
  player1Finder = nil, player2Finder = nil,
  -- paths will be a list of the following data structure...
  -- {startX, startY, endX, endY, pathObject}
  player1Paths = {}, player2Paths = {},
  
  --contains all static-position entities
  --to centralize updating/drawing these game elements (instead of building each element
  --by type, do it by each grid cell)
  player1DetailMap = {}, player2DetailMap = {},
  PATH = 1, START = 2, GOAL = 3, WAYPOINT = 4, TOWER = 5, RANDOM_BLOCK = 6,
  TOWER_1 = 5.1, TOWER_2 = 5.2, TOWER_3 = 5.3,
  EMPTY_SPACE = 0,
  
  TOP_START_COORD = {}, TOP_GOAL_COORD = {},
  BOTTOM_START_COORD = {}, BOTTOM_GOAL_COORD = {},
  
  prevCellX = 1, prevCellY = 1

}

function game:enter(arg)

  self:updateDimensions()
  self:initEndPoints()
  self:initPathFinding()

end

function game:update(dt)

  self:refreshMap()

  nk.frameBegin()
  style()
  if nk.windowBegin("Grid Runner", 0, 0, game.gameWidth, game.gameHeight) then

    nk.layoutRow('dynamic', game.gameHeight, {game.gridWidth/game.gameWidth, game.sideBarWidth/game.gameWidth})

    nk.groupBegin('Grid')
    self:makeGrid()
    nk.groupEnd()

    nk.groupBegin('Sidebar')
    self:makeSideBar()
    nk.groupEnd()

    nk.stylePop()

  end
  nk.windowEnd()
  nk.stylePop() --matches with style()
  nk.frameEnd()

end

function game:draw(dt)

  nk.draw()

end

-- Dynamically change the dimensions of game elements
function game:updateDimensions()

  if game.gameWidth ~= love.graphics.getWidth() or game.gameHeight ~= love.graphics.getHeight() then
    game.gameWidth = love.graphics.getWidth()
    game.gameHeight = love.graphics.getHeight()

    -- Have the grid actual dimensions be proportional to the number of cells in the grid's rows and columns
    -- x2 col size since players grids are placed top and bottom from each other
    game.gridHeight = game.gameHeight
    game.gridWidth = game.gridHeight * game.GRID_ROW_SIZE / (game.GRID_COL_SIZE * 2)

    game.cellWidth = game.gridWidth / game.GRID_ROW_SIZE
    game.cellHeight = game.gridHeight / (game.GRID_COL_SIZE * 2)

    game.sideBarWidth = game.gameWidth - game.gridWidth
    game.sideBarHeight = game.gameHeight

    utils.log("game width", game.gameWidth, "game height", game.gameHeight)
    utils.log("grid width", game.gridWidth, "grid height", game.gridHeight)
    utils.log("cell width", game.cellWidth, "cell height", game.cellHeight)
    utils.log("side bar width", game.sideBarWidth, "side bar height", game.sideBarHeight)
  end

end

function game:initEndPoints()
  
  game.TOP_START_COORD = {x = game.GRID_ROW_SIZE, y = game.GRID_COL_SIZE}
  game.TOP_GOAL_COORD = {x = 1, y = 1}
  game.BOTTOM_START_COORD = {x = 1, y = 1}
  game.BOTTOM_GOAL_COORD = {x = game.GRID_ROW_SIZE, y = game.GRID_COL_SIZE}

end

function game:initPathFinding()
  
  repeat
    self:resetMaps()
  
    game.player1Finder = pathfinder(grid(game.player1PathMap), 'ASTAR', game.WALKABLE)
    game.player2Finder = pathfinder(grid(game.player2PathMap), 'ASTAR', game.WALKABLE)
  
    --VERY IMPORTANT TODO
    --TODO: check to see if map actually updates the path
    self:generateRandomBlocks()
    
    player1Path = game.player1Finder:getPath(game.TOP_START_COORD.x, game.TOP_START_COORD.y, game.TOP_GOAL_COORD.x, game.TOP_GOAL_COORD.y, false)
    player2Path = game.player2Finder:getPath(game.BOTTOM_START_COORD.x, game.BOTTOM_START_COORD.y, game.BOTTOM_GOAL_COORD.x, game.BOTTOM_GOAL_COORD.y, false)
    
    if player1Path and player2Path then
      table.insert(game.player1Paths, {game.TOP_START_COORD.x, game.TOP_START_COORD.y, game.TOP_GOAL_COORD.x, game.TOP_GOAL_COORD.y, player1Path})
      table.insert(game.player2Paths, {game.BOTTOM_START_COORD.x, game.BOTTOM_START_COORD.y, game.BOTTOM_GOAL_COORD.x, game.BOTTOM_GOAL_COORD.y, player2Path})
    end
    
  until ( next(game.player1Paths) ~= nil and next(game.player2Paths) ~= nil )
  
  
end

function game:generateRandomBlocks()
  utils.doRandomSeeding()
  NUM_RANDOM_BLOCKS = 12
  i = 1
  while i < NUM_RANDOM_BLOCKS do
    randomX = math.random(1, game.GRID_ROW_SIZE)
    randomY = math.random(1, game.GRID_COL_SIZE)
    randomXReflect, randomYReflect = self:reflectCoordinates(randomX, randomY)
    if not self:isEndPoint(randomX, randomY) or not self:isEndPoint(randomXReflect, randomYReflect) then
      self:updateMap(1, game.RANDOM_BLOCK, randomX, randomY)
      self:updateMap(2, game.RANDOM_BLOCK, randomXReflect, randomYReflect)
      i = i + 1
    end
  end
end

function game:reflectCoordinates(x, y)
  return game.GRID_ROW_SIZE - x + 1, game.GRID_COL_SIZE - y + 1
end

function game:isEndPoint(x, y)
  return (x == game.TOP_START_COORD.x and y == game.TOP_START_COORD.y)
    or (x == game.TOP_GOAL_COORD.x and y == game.TOP_GOAL_COORD.y)
    or (x == game.BOTTOM_START_COORD.x and y == game.BOTTOM_START_COORD.y)
    or (x == game.BOTTOM_GOAL_COORD.x and y == game.BOTTOM_GOAL_COORD.y)
end

function game:resetMaps()
  for j=1,game.GRID_COL_SIZE do
    game.player1PathMap[j] = {}
    game.player2PathMap[j] = {}
    
    game.player1DetailMap[j] = {}
    game.player2DetailMap[j] = {}
    
    for i=1,game.GRID_ROW_SIZE do
      game.player1PathMap[j][i] = game.WALKABLE
      game.player2PathMap[j][i] = game.WALKABLE
      
      game.player1DetailMap[j][i] = game.EMPTY_SPACE
      game.player2DetailMap[j][i] = game.EMPTY_SPACE
    end
    
  end
end

--TODO: 
function game:refreshMap()
  
end

--single function to update BOTH path map AND detail map
--playerNum = 1 or 2 (player 1 or player 2)
--tag = PATH, START, GOAL, WAYPOINT, RANDOM_BLOCK (for detail map)
--x, y = coordinates
--returns True if successfully updated, False otherwise
function game:updateMap(playerNum, tag, x, y)
  if playerNum ~= 1 and playerNum ~= 2 then
    utils.log("in game:updateMap(), playerNum is not 1 or 2")
    return false
  elseif tag < game.EMPTY_SPACE or tag > game.RANDOM_BLOCK then
    utils.log("in game:updateMap(), tag is invalid")
    return false
  elseif not self:inMapArea(x, y) then
    utils.log("in game:updateMap(), coordinates are invalid")
    return false
  end
  
  if playerNum == 1 then
    game.player1DetailMap[y][x] = tag
    if tag >= game.TOWER then
      game.player1PathMap[y][x] = game.BLOCKED
    else
      game.player1PathMap[y][x] = game.WALKABLE
    end
  else
    game.player2DetailMap[y][x] = tag
    if tag >= game.TOWER then
      game.player2PathMap[y][x] = game.BLOCKED
    else
      game.player2PathMap[y][x] = game.WALKABLE
    end
  end
  return true
end

function game:inMapArea(x, y)
  return x > 0 and x <= game.GRID_ROW_SIZE and y > 0 and y <= game.GRID_COL_SIZE
end

function game:makeGrid()

  nk.layoutRow('dynamic', game.cellHeight, game.GRID_ROW_SIZE)
  nk.stylePush {
    ['window'] = {
      ['spacing'] = {x = 0, y = 0},
      ['padding'] = {x = 0, y = 0}
    },
    ['button'] = {
      ['rounding'] = 0
    }
  }

  -- Player 1 (self)
  for i=1, game.GRID_COL_SIZE do
    for j=1, game.GRID_ROW_SIZE do
      
      self:pushGridCellStyle(1, j, i)
      if nk.button("") then
        utils.log("player 1 button press!")
        utils.log(i, j)
      end
      nk.stylePop()
      
    end
  end

  -- Player 2 (opponent)
  for i=1, game.GRID_COL_SIZE do
    for j=1, game.GRID_ROW_SIZE do
      
      self:pushGridCellStyle(2, j, i)
      if nk.button("") then
        utils.log("player 2 button press!")
        utils.log(i, j)
      end
      nk.stylePop()
    end
  end
  
  nk.stylePop() --matches with the window style push

end

--function to push style changes depending on the type of cell
--NOTE: following this function, there MUST be a nk.stylePop() called
--playerNum = 1 or 2 (player 1 or player 2)
--x, y = coordinates
--returns True if successfully updated, False otherwise
function game:pushGridCellStyle(playerNum, x, y)
  if playerNum ~= 1 and playerNum ~= 2 then
    utils.log("in game:pushGridCellStyle(), playerNum is not 1 or 2")
    return false
  elseif not self:inMapArea(x, y) then
    utils.log("in game:pushGridCellStyle(), coordinates are invalid")
    return false
  end
  
  if playerNum == 1 then
    --Depending on what is assigned to the detailed map cell,
    --give the cell a different color
    if game.player1DetailMap[y][x] == game.RANDOM_BLOCK then
      nk.stylePush {
        ['button'] = {
          ['normal'] = '#213d47'
        }
      }
    else
      nk.stylePush {
        ['button'] = {
          ['normal'] = '#64b4c8',
          ['hover'] = '#3c8cc8',
          ['active'] = '#1450c8'
        }
      }
    end

  else
    if game.player2DetailMap[y][x] == game.RANDOM_BLOCK then
      nk.stylePush {
        ['button'] = {
          ['normal'] = '#33182e'
        }
      }
    else
      nk.stylePush {
        ['button'] = {
          ['normal'] = '#c864b4',
          ['hover'] = '#c83c8c',
          ['active'] = '#c81450'
        }
      }
    end
  end
    
end

--TODO: VARIABLIZE EVERYTHING
function game:makeSideBar()

  nk.stylePush {
    ['window'] = {
      ['group padding'] = {x = 5, y = 5}
    }
  }

  self:makePlayerCard()
  self:makeMainTabs()

  -- generated depending on which tab is active
  self:nkSpace(20)
  nk.label(game.tabNames[game.currentTab])
  self:nkSpace(5)
  
  nk.stylePush {
    ['button'] = {
      ['hover'] = "#bfbfbf",
      ['active'] = "#e5e5e5"
    } 
  }

  ----- TOWERS -----
  if game.currentTab == 1 then 

    self:makeBaseTowerLayout()
    self:makeUpgradeTowerLayout()

    ----- CREEPS -----
  elseif game.currentTab == 2 then

    self:makeBaseCreepLayout()
    self:makeUpgradeCreepLayout()

  else -- special
  
    self:makeSpecialUnitLayout()

  end

  nk.stylePop()
  nk.stylePop()

end

function game:makePlayerCard()

  self:nkSpace(20)
  nk.label('Player 1 name')
  nk.label('Lives: 50')
  nk.label('Currency: 0')
  nk.label('Income: 0')
  nk.label('Next wave in: 30')
  nk.progress(1, 10)

end

function game:makeMainTabs()
  -- "tabs" - but actually buttons
  nk.stylePush {
    ['button'] = {
      ['rounding'] = 0
    }
  }
  nk.layoutRow('dynamic', 25, 3)
  nk.spacing(3)
  for i, tabName in ipairs(game.tabNames) do
    if nk.button(tabName) then
      utils.log("tab "..i.." selected!", tabName)
      game.currentTab = i
    end
  end
  nk.stylePop()
end

function game:makeBaseTowerLayout()
  towerLabelTitle = ""
  towerLabelCost = ""
  towerLabelDamage = ""
  towerLabelRange = ""
  towerLabelAttackSpeed = ""
  towerLabelEffect = ""

  -- base tower buttons
  nk.layoutRow('dynamic', 30, 3)
  for i=1, 3 do

    if nk.widgetIsHovered() then
      towerLabelTitle = game.towerTitles[i].." Tower - "..game.baseHotKeys[i]
      towerLabelCost = "Cost: "--TODO: add cost and other traits dynamically here
      towerLabelDamage = "Damage: "
      towerLabelRange = "Range: "
      towerLabelAttackSpeed = "Attack Speed: "
      towerLabelEffect = "Effect: "
    end

    if nk.button("", love.graphics.newImage(game.iconURL..game.towerStrings[i].."_icon.png")) then
      utils.log(game.tabNames[game.currentTab], "pressed - "..i)
    end

  end
  self:nkSpace(5)

  nk.layoutRow('dynamic', 15, 1)
  nk.label(towerLabelTitle, 'wrap')
  nk.label(towerLabelCost, 'wrap')
  nk.label(towerLabelDamage, 'wrap')
  nk.label(towerLabelRange, 'wrap')
  nk.label(towerLabelAttackSpeed, 'wrap')
  nk.label(towerLabelEffect, 'wrap')
  self:nkSpace(5)
end

function game:makeUpgradeTowerLayout()
  nk.layoutRow('dynamic', 20, 1)
  nk.label('Upgrades')
  self:nkSpace(5)

  nk.layoutRow('dynamic', 30, 3)
  for i=1, 6 do
    if nk.button(game.upgradeHotKeys[i]) then
      utils.log(game.tabNames[game.currentTab], "pressed upgrade - "..i)
    end
  end
  self:nkSpace(5)

  nk.layoutRow('dynamic', 90, 1)
  nk.label("this is a description of the upgrade effects to the base towers", 'wrap')
end

function game:makeBaseCreepLayout()
  creepLabelTitle = ""
  creepLabelCost = ""
  creepLabelHP = ""
  creepLabelSpeed = ""
  creepLabelGhost = ""
  creepLabelShield = ""

  nk.layoutRow('dynamic', 30, 3)
  for i=1, 3 do
    if nk.widgetIsHovered() then
      creepLabelTitle = game.creepTitles[i].." Creep - "..game.baseHotKeys[i]
      creepLabelCost = "Cost: "--TODO: add cost and other traits dynamically here
      creepLabelHP = "HP: "
      creepLabelSpeed = "Speed: "
      creepLabelGhost = "Ghost: "
      creepLabelShield = "Shield: "
    end

    if nk.button("", love.graphics.newImage(game.iconURL..game.creepStrings[i].."_icon.png")) then
      utils.log(game.tabNames[game.currentTab], "pressed - "..i)
    end
  end
  self:nkSpace(5)

  nk.layoutRow('dynamic', 15, 1)
  nk.label(creepLabelTitle, 'wrap')
  nk.label(creepLabelCost, 'wrap')
  nk.label(creepLabelHP, 'wrap')
  nk.label(creepLabelSpeed, 'wrap')
  nk.label(creepLabelGhost, 'wrap')
  nk.label(creepLabelShield, 'wrap')
  self:nkSpace(5)
end

function game:makeUpgradeCreepLayout()
  nk.layoutRow('dynamic', 20, 1)
  nk.label('Upgrades')
  self:nkSpace(5)

  nk.layoutRow('dynamic', 30, 3)
  for i=1, 6 do
    if nk.button(tostring(i)) then
      utils.log(game.tabNames[game.currentTab], "pressed upgrade - "..i)
    end
  end
  self:nkSpace(5)

  nk.layoutRow('dynamic', 90, 1)
  nk.label("this is a description of the upgrade effects to the base creeps", 'wrap')
end

function game:makeSpecialUnitLayout()
  nk.layoutRow('dynamic', 30, 3)

----TODO: THIS IS WRONG
--  for i=1, 3 do

--    if nk.widgetIsHovered() then
--      towerLabelTitle = game.towerTitles[i].." Tower - "..game.baseHotKeys[i]
--      towerLabelCost = "Cost: "--TODO: add cost and other traits dynamically here
--      towerLabelDamage = "Damage: "
--      towerLabelRange = "Range: "
--      towerLabelAttackSpeed = "Attack Speed: "
--      towerLabelEffect = "Effect: "
--    end

--    if nk.button("", love.graphics.newImage(game.iconURL..game.towerStrings[i].."_icon.png")) then
--      utils.log(game.tabNames[game.currentTab], "pressed - "..i)
--    end

--  end
--  self:nkSpace(5)

--  nk.layoutRow('dynamic', 15, 1)
--  nk.label(towerLabelTitle, 'wrap')
--  nk.label(towerLabelCost, 'wrap')
--  nk.label(towerLabelDamage, 'wrap')
--  nk.label(towerLabelRange, 'wrap')
--  nk.label(towerLabelAttackSpeed, 'wrap')
--  nk.label(towerLabelEffect, 'wrap')
--  self:nkSpace(5)
end

function game:nkSpace(size)
  nk.layoutRow('dynamic', size, 1)
  nk.spacing(1)
end

return game