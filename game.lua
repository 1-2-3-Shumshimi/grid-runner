local game = {

--declaring variables--
  creepImages = {}, creepButtons = {},
  creepButtonPadding = 20,
  displayButtonInfoBox = -1,

  gameWidth = 0, gameHeight = 0, sideBarWidth = 0, sideBarHeight = 0,
  cellSize = 0, gridWidth = 0, gridHeight = 0,

  tileset = nil,
  tilesetURL = "assets/terrain.png",
  tileWidth = 32, tileHeight = 32, 
  tilesetWidth = -1, tilesetHeight = -1,
  tilesetQuads = {},
  tileTable = {},

  dt = 0,

  initMap = {}, player1Map = {}, player2Map = {},
  walkable = 0, blocked = 10, oppSide = 20,

  player1Cells = nil, player2Cells = nil, 
  player1Finder = nil, player2Finder = nil,

  player1 = nil, player2 = nil,

  playerTopX = 1, playerTopY = 1, playerBottomX = 1, playerBottomY = 1,
  topEnemySpawnX, topEnemySpawnY = 1, bottomEnemySpawnX = 1, bottomEnemySpawnY = 1,
  prevCellX = 1, prevCellY = 1,
  player1Path = nil, player2Path = nil,

  mouseDisabled = false,
  mouseDisabledMax = 10, mouseDisableCounter = 0,

  creepList = {},
  creepTimer = 0, creepTimerMax = 100, creepNumMax = 10,
  creepLocations = {},
  creepUpdated = true,

  creepImageURLs = {"assets/blue-triangle.png", "assets/orange-star.png", "assets/yellow-diamond.png", "assets/teal-circle.png"},
  creepTexts = {"bmg1", "ftr1", "avt1", "amg1"},

  towerList = {},
  towerImageURLs = {"assets/tower_basic.png"},
  towerUpdated = false,

  bulletList = {},
  bulletImageURLs = {"assets/bullet_basic.png"}
--end of declaring variables--
}

function game:enter(arg)

  game.gameHeight = love.graphics.getHeight()
  game.gameWidth = (love.graphics.getWidth() * 4) / 5
  game.sideBarWidth = love.graphics.getWidth() / 5 -- let sidebar take 1/5 of the game window
  game.sideBarHeight = love.graphics.getHeight()

  game.cellSize = utils.findGCF(game.gameWidth, game.gameHeight) / 4
  game.gridWidth = game.gameWidth / game.cellSize
  game.gridHeight = game.gameHeight / game.cellSize

  for j=1,game.gridHeight do
    game.initMap[j] = {}
    for i=1,game.gridWidth do
      game.initMap[j][i] = game.walkable
    end
  end

  game.player1Map, game.player2Map = game.filterMapForPlayer(game.initMap, true, true)

  game.player1Cells = grid(game.player1Map)
  game.player2Cells = grid(game.player2Map)
  game.player1Finder = pathfinder(game.player1Cells, 'ASTAR', game.walkable)
  game.player1Finder:setMode('ORTHOGONAL')
  game.player2Finder = pathfinder(game.player2Cells, 'ASTAR', game.walkable)
  game.player2Finder:setMode('ORTHOGONAL')

  -- setting player base points
  game.playerTopX, game.playerTopY = 1, 1
  game.playerBottomX, game.playerBottomY = game.gridWidth, game.gridHeight

  game.topEnemySpawnX, game.topEnemySpawnY = game.playerBottomX, game.playerBottomY - 6
  game.bottomEnemySpawnX, game.bottomEnemySpawnY = game.playerTopX, game.playerTopY + 6

  --instantiate players
  game.player1 = player(1,game.player1Map,100,100,"boo",1,1,100)
  game.player2 = player(0,game.player2Map,100,100,"eww",1,1,100)

  --instantiate paths
  game.player1Path = game.player1Finder:getPath(game.player1.enemySpawnSiteX, game.player1.enemySpawnSiteY, game.player1.playerX, game.player1.playerY, false)
  game.player2Path = game.player2Finder:getPath(game.player2.enemySpawnSiteX, game.player2.enemySpawnSiteY, game.player2.playerX, game.player2.playerY, false)

  game.player1:refreshMapAndPaths() --players saving local copies of paths
  game.player2:refreshMapAndPaths()

  -- set up creep buttons --
  buttonCoordPointer = {x = game.gameWidth, y = 0}
  for i, url in ipairs(game.creepImageURLs) do
    -- image
    game.creepImages[i] = love.graphics.newImage(url)
    game.creepButtons[i] = button(1000)
    game.creepButtons[i]:setImage(game.creepImages[i])
    game.creepButtons[i]:setSize(game.sideBarWidth / 2 - game.creepButtonPadding, game.sideBarWidth / 2 - game.creepButtonPadding)

    -- coord
    game.creepButtons[i]:setCoord(buttonCoordPointer.x + game.creepButtonPadding / 2, buttonCoordPointer.y + game.creepButtonPadding / 2)
    if buttonCoordPointer.x + game.creepButtons[i].width + game.creepButtonPadding < love.graphics.getWidth() then
      buttonCoordPointer.x = buttonCoordPointer.x + game.creepButtons[i].width + game.creepButtonPadding
    else
      buttonCoordPointer.y = buttonCoordPointer.y + game.creepButtons[i].height + game.creepButtonPadding
      buttonCoordPointer.x = game.gameWidth
    end

    --jonathan: this is currently set up with the vantage point that player 1 has the sidebar/buttons
    --creeps are generated to player2's list
    game.creepButtons[i]:setHit(game.player1.generateCreep)
    game.creepButtons[i]:setText(game.creepTexts[i])

  end

  -- setting up tileset
  game.tileset = love.graphics.newImage(game.tilesetURL)
  game.tilesetWidth = game.tileset:getWidth()
  game.tilesetHeight = game.tileset:getHeight()

  quadInfo = {
    { 0, 352 }, -- 1 - grass 1
    { 32, 352 }, -- 2 - grass 2
    { 64, 352 }, -- 3 - grass 3
  }
  for i, info in ipairs(quadInfo) do
    -- info[1] = x, info[2] = y
    game.tilesetQuads[i] = love.graphics.newQuad(info[1], info[2], game.tileWidth, game.tileHeight, game.tilesetWidth, game.tilesetHeight)
  end
  game.generateTileTable()

end

function game:update(dt)
  --easy way to exit game
  if love.keyboard.isDown('escape') then
    love.event.push('quit')
  end

  --update game's dt variable to be used in animation
  game.dt = dt

  game.player1:update(dt)

  if useAIFlag then --update AI agent
    agent:update()
  end
  game.player2:update(dt)

  --mouse actions
  mouseCoordX, mouseCoordY = love.mouse.getX(), love.mouse.getY()

  --building tower mouse actions
  if love.mouse.isDown(1) and not game.mouseDisabled and game.inGameArea(mouseCoordX, mouseCoordY) then
    cellX, cellY = utils.coordToCell(mouseCoordX, mouseCoordY, game.cellSize)
    game.player1.noCreepInCell = true

    game.player1:checkMoveValidity(cellX, cellY)
  
  end

  --sidebar mouse actions
  game.displayButtonInfoBox = -1
  for i, creepButton in ipairs(game.creepButtons) do
    if creepButton:onButton(mouseCoordX, mouseCoordY) then
      game.displayButtonInfoBox = i
      if love.mouse.isDown(1) and not game.mouseDisabled then
        --creepButton.hit(creepButton.image) commented out for testing purposes with line below
        creepButton.hit(game.player1, love.graphics.newImage("assets/"..game.creepTexts[i]..".png"), dt) --NOT OPTIMAL TODO: FIX
        game.mouseDisableCounter = 0
        game.mouseDisabled = true
      end
      break
    end
  end

  --buffer time between mouse actions
  game.mouseDisableCounter = game.mouseDisableCounter + 1
  if game.mouseDisableCounter > game.mouseDisabledMax and not love.mouse.isDown(1) then
    game.mouseDisableCounter = 0
    game.mouseDisabled = false
  end

end

function game:draw(dt)

  --draw sidebar--
  love.graphics.setColor(255, 255, 255)
  for i, creepButton in ipairs(game.creepButtons) do
    creepButton:draw()
    if (game.displayButtonInfoBox == i) then
      creepButton:drawInfoBox()
    end
  end

  --draw tiles--
  for rowIndex,row in ipairs(game.tileTable) do
    for columnIndex,number in ipairs(row) do
      x, y = (columnIndex)*game.cellSize, (rowIndex-1)*game.cellSize
      love.graphics.draw(game.tileset, game.tilesetQuads[number], x, y, game.cellSize/game.tileWidth, game.cellSize/game.tileHeight)
    end
  end

  --draw grid--
  --vertical lines--
  love.graphics.setColor(255, 255, 255)
  for i=0, game.gameWidth, game.cellSize do
    love.graphics.line(i, 0, i, game.gameHeight)
  end
  --horizontal lines--
  for i=0, game.gameHeight, game.cellSize do
    love.graphics.line(0, i, game.gameWidth, i)
  end

  --midline divider--
  love.graphics.setColor(255, 50, 50)
  love.graphics.line(0, game.gameHeight / 2, game.gameWidth, game.gameHeight / 2)

  self:drawPaths()

  game.player1:draw(dt)
  game.player2:draw(dt)

end

function game.inGameArea(mouseX, mouseY)
  return mouseX < game.gameWidth and mouseY < game.gameHeight 
end

function game.filterMapForPlayer(gameMap, updatePlayer1Flag, updatePlayer2Flag)
  -- copies game.map, but marks half the map as unwalkable
  -- done this way for flexibility - in case creeps would be allowed to traverse any part of map

  player1Map = {}
  player2Map = {}
  -- map population if player is on top half of screen
  if updatePlayer1Flag then
    for j=1,game.gridHeight do
      player1Map[j] = {}
      if j <= (game.gridHeight/2) then
        for i=1,game.gridWidth do
          player1Map[j][i] = gameMap[j][i]
        end
      else
        for i=1,game.gridWidth do
          player1Map[j][i] = game.oppSide
        end
      end
    end
  end

  -- map population if player is on bottom half of screen
  if updatePlayer2Flag then
    for j=1,game.gridHeight do
      player2Map[j] = {}
      if j <= (game.gridHeight/2) then
        for i=1,game.gridWidth do
          player2Map[j][i] = game.oppSide
        end
      else
        for i=1,game.gridWidth do
          player2Map[j][i] = gameMap[j][i]
        end
      end
    end      
  end

  return player1Map, player2Map

end

function game.generateTower(cellX, cellY)
--  towerN = tower:new(({attackSpeed = 1, damage = 2, range = 10, attackCapacity = 1, size = 2}))
  towerN = tower(2,2,2,1,2)
  towerN:setCoord(cellX, cellY)
  towerN:setSpriteSheet(love.graphics.newImage(game.towerImageURLs[1]))
  table.insert(game.towerList, towerN)
end

function game.refreshTowers()
  -- skeleton, for the case that towers may have HP
end

function game.updateScore(creep)
  --blank function to be used later for incrementing score, adding money, etc.--
end

function game.generateTileTable()

  for j=1, game.gridHeight do
    game.tileTable[j] = {}
    for i=1, game.gridWidth do
      game.tileTable[j][i] = math.random(1, #game.tilesetQuads)
    end
  end

end

function game:drawPaths()

  love.graphics.setColor(255, 0, 150)
  if self.player1Path then
    for node in self.player1Path:nodes() do
      coordX, coordY = utils.cellToCoord(node:getX(), node:getY(), game.cellSize)
      love.graphics.circle("fill", coordX + game.cellSize/2, coordY + game.cellSize/2, game.cellSize/8, game.cellSize/8)

    end
  end

  love.graphics.setColor(150, 0, 255)
  if self.player2Path then
    for node in self.player2Path:nodes() do
      coordX, coordY = utils.cellToCoord(node:getX(), node:getY(), game.cellSize)
      love.graphics.circle("fill", coordX + game.cellSize/2, coordY + game.cellSize/2, game.cellSize/8, game.cellSize/8)

    end
  end

end

return game