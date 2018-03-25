local game = {

  gridRowSize = 32,
  gridColSize = 15, --for a single player, combined grid col size will be 30

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
  creepTitles = {"Cheap", "Tank", "Fast"}


}

function game:enter(arg)

  -- Setting the screen layout
  self:updateDimensions()

end

function game:update(dt)

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
    game.gridWidth = game.gridHeight * game.gridRowSize / (game.gridColSize * 2)

    game.cellWidth = game.gridWidth / game.gridRowSize
    game.cellHeight = game.gridHeight / (game.gridColSize * 2)

    game.sideBarWidth = game.gameWidth - game.gridWidth
    game.sideBarHeight = game.gameHeight

    utils.log("game width", game.gameWidth, "game height", game.gameHeight)
    utils.log("grid width", game.gridWidth, "grid height", game.gridHeight)
    utils.log("cell width", game.cellWidth, "cell height", game.cellHeight)
    utils.log("side bar width", game.sideBarWidth, "side bar height", game.sideBarHeight)
  end

end

function game:makeGrid()

  nk.layoutRow('dynamic', game.cellHeight, game.gridRowSize)
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
  nk.stylePush {
    ['button'] = {
      ['normal'] = '#64b4c8',
      ['hover'] = '#3c8cc8',
      ['active'] = '#1450c8'
    }
  }
  for i=1, game.gridColSize do
    for j=1, game.gridRowSize do
      if nk.button("") then
        utils.log("player 1 button press!")
        utils.log(i, j)
      end
    end
  end
  nk.stylePop()

  -- Player 2 (opponent)
  nk.stylePush {
    ['button'] = {
      ['normal'] = '#c864b4',
      ['hover'] = '#c83c8c',
      ['active'] = '#c81450'
    }
  }
  for i=1, game.gridColSize do
    for j=1, game.gridRowSize do
      if nk.button("") then
        utils.log("player 2 button press!")
        utils.log(i, j)
      end
    end
  end
--  end
  nk.stylePop()
  nk.stylePop()

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