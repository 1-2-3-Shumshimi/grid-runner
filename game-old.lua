local game = {

--declaring variables--
  player1Card = {name = nil, hp = nil, currency = nil},
  player2Card = {name = nil, hp = nil, currency = nil},
  creepImages = {}, creepButtons = {}, creepButtonBatchNums = {},
  towerImages = {}, towerButtons = {},
  buttonPadding = 9,
  displayCreepButtonInfo = -1,
  displayTowerButtonInfo = -1,
  creepWaveToggle = toggle(1000),
  creepWaveIsBatch = false,
  generateCreepBatchFlag = false,

  gameWidth = 0, gameHeight = 0, sideBarWidth = 0, sideBarHeight = 0,
  cellSize = 0, gridWidth = 0, gridHeight = 0,

  tileset = nil,
  tilesetURL = "assets/terrain.png",
  tileWidth = 32, tileHeight = 32,
  tilesetWidth = -1, tilesetHeight = -1,
  tilesetQuads = {},
  tileTable = {},

  dt = 0,
  incomeTimer = 0,
  incomeLastTimeStamp = nil,
  creepBatchTimer = 0,
  creepBatchLastTimeStamp = nil,

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
  mouseDisabledMax = 15, mouseDisableCounter = 0,

  creepList = {},
  creepTimer = 0, creepTimerMax = 100, creepNumMax = 10,
  creepLocations = {},
  creepUpdated = true,
  creepQueue = {},
  lastCreepQueue = {}, --creep queue from the last batch, reversed

  creepImageURLs = {"bmg1.png", "ftr1.png", "avt1.png", "amg1.png"},
  creepTexts = {"bmg1", "ftr1", "avt1", "amg1"},

  towerList = {},
  towerImageURLs = {"tower_basic.png", "tower_freeze.png"},
  towerTexts = {"the basic tower", "the freeze tower"},
  towerUpdated = false,

  bulletList = {},
  bulletImageURLs = {"assets/bullet_basic.png"}
--end of declaring variables--
}

function game:enter(arg)

  -- load models --
  game.loadModels()
  game.incomeLastTimeStamp = love.timer.getTime()
  
  -- set game map configurations --
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
  game.player1 = player(1,game.player1Map,50,50,"Astro",1,1,100) --TODO variablize names
  game.player2 = player(0,game.player2Map,50,50,"Beyónce",1,1,100)

  --instantiate paths
  game.player1Path = game.player1Finder:getPath(game.player1.enemySpawnSiteX, game.player1.enemySpawnSiteY, game.player1.playerX, game.player1.playerY, false)
  game.player2Path = game.player2Finder:getPath(game.player2.enemySpawnSiteX, game.player2.enemySpawnSiteY, game.player2.playerX, game.player2.playerY, false)

  game.player1:refreshMapAndPaths() --players saving local copies of paths
  game.player2:refreshMapAndPaths()

  -- set up creep buttons --
  buttonCoordPointer = {x = game.gameWidth, y = game.buttonPadding}
  for i, url in ipairs(game.creepImageURLs) do
    -- image
    game.creepImages[i] = love.graphics.newImage("assets/icons/"..url)
    game.creepButtons[i] = button(1000)
    game.creepButtons[i]:setImage(game.creepImages[i])
    game.creepButtons[i]:setSize(game.sideBarWidth / 3 - game.buttonPadding / 2, game.sideBarWidth / 3 - game.buttonPadding / 2)

    -- coord
    game.creepButtons[i]:setCoord(buttonCoordPointer.x + game.buttonPadding / 2, buttonCoordPointer.y + game.buttonPadding / 2)
    if buttonCoordPointer.x + game.creepButtons[i].width + game.buttonPadding < love.graphics.getWidth() then
      buttonCoordPointer.x = buttonCoordPointer.x + game.creepButtons[i].width + game.buttonPadding / 2
    else
      buttonCoordPointer.y = buttonCoordPointer.y + game.creepButtons[i].height + game.buttonPadding / 2
      buttonCoordPointer.x = game.gameWidth
    end

    --jonathan: this is currently set up with the vantage point that player 1 has the sidebar/buttons
    --creeps are generated to player2's list
    game.creepButtons[i]:setHit(game.player1.generateCreep)
    game.creepButtons[i]:setText(game.creepTexts[i]..": "..model.creeps[i].cost)

  end

  -- set up creep wave toggle
  buttonCoordPointer.x = game.gameWidth
  buttonCoordPointer.y = buttonCoordPointer.y + game.creepButtons[1].height + game.buttonPadding * 3
  game.creepWaveToggle:setText("QUICK", "BATCH")
  game.creepWaveToggle:setCoord(buttonCoordPointer.x + game.buttonPadding / 2, buttonCoordPointer.y, 
    buttonCoordPointer.x + game.creepWaveToggle.leftTextBox.width + game.buttonPadding / 2, buttonCoordPointer.y)
  game.creepWaveToggle:setStateChanges(game.updateCreepWaveMode, game.updateCreepWaveMode)
  game.creepWaveToggle:setAlignment("center")
  
  -- set up tower buttons --
  buttonCoordPointer.x = game.gameWidth
  buttonCoordPointer.y = buttonCoordPointer.y + game.creepWaveToggle.leftTextBox.height + game.buttonPadding * 3
  for i, url in ipairs(game.towerImageURLs) do 
    -- image
    game.towerImages[i] = love.graphics.newImage("assets/icons/"..url)
    game.towerButtons[i] = button(1000)
    game.towerButtons[i]:setImage(game.towerImages[i])
    game.towerButtons[i]:setSize(game.sideBarWidth / 3 - game.buttonPadding, game.sideBarWidth / 3 - game.buttonPadding)
    
    -- coord
    game.towerButtons[i]:setCoord(buttonCoordPointer.x + game.buttonPadding / 3, buttonCoordPointer.y + game.buttonPadding / 3)
    if buttonCoordPointer.x + game.towerButtons[i].width + game.buttonPadding < love.graphics.getWidth() then
      buttonCoordPointer.x = buttonCoordPointer.x + game.towerButtons[i].width + game.buttonPadding
    else
      buttonCoordPointer.y = buttonCoordPointer.y + game.towerButtons[i].height + game.buttonPadding
      buttonCoordPointer.x = game.gameWidth
    end
    
    game.towerButtons[i]:setHit(game.setTowerInfo)
    game.towerButtons[i]:setText(game.towerTexts[i]..": "..model.towers[i].cost)
    
  end
  
  -- set up player names, currency, and lives display
  statsCoordPointer = {x = game.gameWidth + game.buttonPadding, y = buttonCoordPointer.y + game.towerButtons[1].height + game.buttonPadding * 3}
  game.player1Card.name = textbox("Player 1: ", game.player1.name, statsCoordPointer.x, statsCoordPointer.y)
  game.player1Card.HP = textbox("HP: ", game.player1.HP, statsCoordPointer.x, statsCoordPointer.y + game.buttonPadding * 2)
  game.player1Card.currency = textbox("Currency: ", game.player1.currency, statsCoordPointer.x, statsCoordPointer.y + game.buttonPadding * 4)
  statsCoordPointer.y = statsCoordPointer.y + game.buttonPadding * 8
  game.player2Card.name = textbox("Player 2: ", game.player2.name, statsCoordPointer.x, statsCoordPointer.y)
  game.player2Card.HP = textbox("HP: ", game.player2.HP, statsCoordPointer.x, statsCoordPointer.y + game.buttonPadding * 2)
  game.player2Card.currency = textbox("Currency: ", game.player2.currency, statsCoordPointer.x, statsCoordPointer.y + game.buttonPadding * 4)

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
  
  --update game's income timer variable, so player classes have synchronized times when they receive income
  currTimeStamp = love.timer.getTime()
  if currTimeStamp - game.incomeLastTimeStamp >= 1 then --every one second
    game.incomeTimer = game.incomeTimer + 1
    game.incomeLastTimeStamp = currTimeStamp
  end
  
  if game.incomeTimer > 15 then --When time is up gather income and release creep wave
    game.player1:takeIncome()
    game.player2:takeIncome()
    game.incomeTimer = 0

    game.generateCreepBatchFlag = true -- signal release a batch of creeps
    game.lastCreepQueue = utils.reverseTable(game.creepQueue)
    game.creepQueue = {}
    game.creepButtonBatchNums = {}
    game.creepBatchLastTimeStamp = currTimeStamp
  end
  
  if game.generateCreepBatchFlag and currTimeStamp - game.creepBatchLastTimeStamp > 0.20 then
    if next(game.lastCreepQueue) ~= nil then
      creepID = table.remove(game.lastCreepQueue, #game.lastCreepQueue)
      if creepID ~= nil then
        game.player1:generateCreep(creepID, dt, true)
        game.creepBatchLastTimeStamp = currTimeStamp
      end
    else
      game.generateCreepBatchFlag = false
    end
  end
  

  --update player game logic
  game.player1:update(dt)
  if useAIFlag then --update AI agent
    agent:update()
  end
  game.player2:update(dt)
  game.updatePlayerCards()

  --mouse actions
  mouseCoordX, mouseCoordY = love.mouse.getX(), love.mouse.getY()

  --building tower mouse actions
  if love.mouse.isDown(1) and not game.mouseDisabled and game.inGameArea(mouseCoordX, mouseCoordY) then
    if game.displayTowerButtonInfo ~= -1 then
      cellX, cellY = utils.coordToCell(mouseCoordX, mouseCoordY, game.cellSize)
      game.player1.noCreepInCell = true
      game.player1:checkMoveValidity(cellX, cellY, game.displayTowerButtonInfo)
    end
  
  end

  --sidebar mouse actions
  if not game.inGameArea(mouseCoordX, mouseCoordY) then
    
    game.displayCreepButtonInfo = -1
    for i, creepButton in ipairs(game.creepButtons) do
      if creepButton:onButton(mouseCoordX, mouseCoordY) then --display hover popup
        game.displayCreepButtonInfo = i
        if love.mouse.isDown(1) and not game.mouseDisabled then --click action depending on creep wave mode
          
          creepID = game.displayCreepButtonInfo
          if game.creepWaveToggle.currentState == toggle.left then
            creepButton.hit(game.player1, creepID, dt)
          elseif game.creepWaveToggle.currentState == toggle.right then
            cMod = model.creeps[creepID]
            if game.player1:spendMoney(cMod.cost, cMod.incomeBoost) then
              table.insert(game.creepQueue, creepID)
              game.creepButtonBatchNums[creepID] = game.creepButtonBatchNums[creepID] == nil and 1 
                or game.creepButtonBatchNums[creepID] + 1
            end
          end
          
          game.mouseDisableCounter = 0
          game.mouseDisabled = true
        
        end
        break
      end
    end
    
    for i, towerButton in ipairs(game.towerButtons) do
      if towerButton:onButton(mouseCoordX, mouseCoordY) then
        if love.mouse.isDown(1) and not game.mouseDisabled then
          towerButton.hit(i)
          game.mouseDisableCounter = 0
          game.mouseDisabled = true
        end
        break
      end
    end
    
    if love.mouse.isDown(1) and not game.mouseDisabled then
      creepWaveToggleFlag = game.creepWaveToggle:onToggle(mouseCoordX, mouseCoordY)
      if creepWaveToggleFlag == toggle.left then
        game.creepWaveToggle.leftStateChange(self, constants.CREEP_WAVE_QUICK)
      elseif creepWaveToggleFlag == toggle.right then
        game.creepWaveToggle.rightStateChange(self, constants.CREEP_WAVE_BATCH)
      end
      game.mouseDisableCounter = 0
      game.mouseDisabled = true
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
    if (game.displayCreepButtonInfo == i) then
      creepButton:drawInfoBox()
    end
    if game.creepButtonBatchNums[i] ~= nil and game.creepButtonBatchNums[i] ~= 0 then
      circleRadius = 12
      labelX = creepButton.x + creepButton.width - circleRadius * 2
      labelY = creepButton.y + circleRadius
      love.graphics.circle("fill", labelX, labelY, circleRadius)
      love.graphics.setColor(0, 0, 0)
      love.graphics.print(game.creepButtonBatchNums[i], labelX - circleRadius / 2 , labelY - circleRadius / 2)
      love.graphics.setColor(255, 255, 255)
    end
  end
  for i, towerButton in ipairs(game.towerButtons) do
    towerButton:draw()
    if (game.displayTowerButtonInfo == i) then
      towerButton:drawInfoBox()
    end
  end
  for i, playerCard in ipairs({game.player1Card, game.player2Card}) do
    for key, text in next, playerCard do
      text:draw()
    end
  end
  
  game.creepWaveToggle:draw()
  love.graphics.setColor(255, 255, 255) --reset color
  
  --draw income timer
  love.graphics.print("Wave countdown: "..(15-game.incomeTimer), game.gameWidth+game.buttonPadding, game.gameHeight-game.buttonPadding*2)

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

function game.loadModels()
  --load tower models
  isFirstLine = true
  for line in love.filesystem.lines("resource/tower-data.csv") do
    tempTable = utils.fromCSV(line)
    if isFirstLine then
      model:setTowerFields(tempTable)
      isFirstLine = false
    else
      model:setTowerRows(tempTable)
    end
  end
  model:printTowers()
  
  --load creep models
  isFirstLine = true
  for line in love.filesystem.lines("resource/creep-data.csv") do
    tempTable = utils.fromCSV(line)
    if isFirstLine then
      model:setCreepFields(tempTable)
      isFirstLine = false
    else
      model:setCreepRows(tempTable)
    end
  end
  model:printCreeps()
  
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

function game.setTowerInfo(index)
  if game.displayTowerButtonInfo == index then
    game.displayTowerButtonInfo = -1
  else
    game.displayTowerButtonInfo = index
  end
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

function game:updatePlayerCards()
  game.player1Card.HP:setExtraString(game.player1.HP)
  game.player1Card.currency:setExtraString(game.player1.currency)
  game.player2Card.HP:setExtraString(game.player2.HP)
  game.player2Card.currency:setExtraString(game.player2.currency)
end

function game:updateCreepWaveMode(mode)
  if mode == constants.CREEP_WAVE_BATCH then
    game.creepWaveIsBatch = true
    game.creepWaveToggle:setState(toggle.right)
  elseif mode == constants.CREEP_WAVE_QUICK then
    game.creepWaveIsBatch = false
    game.creepWaveToggle:setState(toggle.left)
  else
    print("Invalid creep mode given")
  end
end

return game