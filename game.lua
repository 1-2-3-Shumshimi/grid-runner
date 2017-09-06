local game = {
  
--declaring variables--
creepImages = {}, creepButtons = {},
creepButtonPadding = 20,
displayButtonInfoBox = -1,

gameWidth = 0, gameHeight = 0, sideBarWidth = 0, sideBarHeight = 0,
cellSize = 0, gridWidth = 0, gridHeight = 0,

map = {},
walkable = 0, blocked = 10,

cells = nil, myFinder = nil,

startx = 1, starty = 1, endx = 1, endy = 1,
prevCellX = 1, prevCellY = 1,
path = nil,

mouseDisabled = false,
mouseDisabledMax = 10, mouseDisableCounter = 0,

creepList = {},
creepTimer = 0, creepTimerMax = 100, creepNumMax = 10,
creepLocations = {},
creepUpdated = true,

creepImageURLs = {"assets/blue-triangle.png", "assets/orange-star.png", "assets/yellow-diamond.png", "assets/teal-circle.png"},
creepTexts = {"Blue Triangle", "Orange Star", "Yellow Diamond", "Teal Circle"},

towerList = {},
towerUpdated = false,

bulletList = {}
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
    game.map[j] = {}
    for i=1,game.gridWidth do
      game.map[j][i] = game.walkable
    end
  end
  
  game.cells = grid(game.map)
  game.myFinder = pathfinder(game.cells, 'ASTAR', game.walkable)
  game.myFinder:setMode('ORTHOGONAL')
  game.endx, game.endy = game.gridWidth, game.gridHeight
  
  -- so creeps can create their own mini paths --
  creep.cells = game.cells
  creep.cellSize = game.cellSize
  
  -- set initial path --
  game.path = game.myFinder:getPath(game.startx, game.starty, game.endx, game.endy, false)
  
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
    
    --function
    game.creepButtons[i]:setHit(game.generateCreep)
    game.creepButtons[i]:setText(game.creepTexts[i])
    
  end
  
end

function game:update(dt)

  --easy way to exit game
  if love.keyboard.isDown('escape') then
    love.event.push('quit')
  end
  
  --generate creep automatically
  game.creepTimer = game.creepTimer + 1
  if game.creepTimer > game.creepTimerMax and #game.creepList < game.creepNumMax then
    game.creepTimer = 0
    game.generateRandomCreep()
  end

  --check for bullet collisions with creeps or target destinations
  for i, bulletN in ipairs(game.bulletList) do
    for j, creep in ipairs(game.creepList) do
      if bulletN:checkBulletHitCreep(creep.x, creep.y, game.cellSize) then
        -- damage creep health + remove bullet from list
        print("creep", i, "takes damage; HP left: ", creep.HP)
        creep:takeDamage(bulletN.damage)
        if creep:isDead() then
          table.remove(game.creepList, j)
        end
        table.remove(game.bulletList, i)
      elseif bulletN:checkBulletReachDest(game.cellSize) then
        table.remove(game.bulletList, i)
      end
    end
  
  end
  --update creeps
  for i, creep in ipairs(game.creepList) do
    if creep:update(game.path) then
      table.insert(game.creepLocations, {utils.coordToCell(creep.x, creep.y, game.cellSize)})
    else
      game.revertPath()
      game.refreshCreeps()
      break
    end
  end
  
  --mouse actions
  mouseCoordX, mouseCoordY = love.mouse.getX(), love.mouse.getY()
  
  --building tower mouse actions
  if love.mouse.isDown(1) and not game.mouseDisabled and game.inGameArea(mouseCoordX, mouseCoordY) then
    
    cellX, cellY = utils.coordToCell(mouseCoordX, mouseCoordY, game.cellSize)
    noCreepInCell = true
    
    --check to see if obstacle to be placed would be on top of a creep
    --only build if it is not
    for i, coord in ipairs(game.creepLocations) do
      if cellX == coord[1] and cellY == coord[2] then
        noCreepInCell = false
      end
    end
    
    if noCreepInCell then
      --notice cellX and cellY are flipped to coincide with the pathfinder module
      if game.map[cellY][cellX] == game.walkable then
        game.map[cellY][cellX] = game.blocked
        -- print("blocked cell (", cellX, cellY, ")")
        -- print("generating tower")
        game.generateTower(cellX, cellY)
      else
        game.map[cellY][cellX] = game.walkable
      end
      game.prevCellX, game.prevCellY = cellX, cellY --set the revert path mechanism
      game.mouseDisableCounter = 0
      game.mouseDisabled = true
      
      game.path = game.myFinder:getPath(game.startx, game.starty, game.endx, game.endy, false)
      if not game.path then
        game.revertPath()
      end
    end
  end
  
  --sidebar mouse actions
  game.displayButtonInfoBox = -1
  for i, creepButton in ipairs(game.creepButtons) do
    if creepButton:onButton(mouseCoordX, mouseCoordY) then
      game.displayButtonInfoBox = i
      if love.mouse.isDown(1) and not game.mouseDisabled then
        creepButton.hit(creepButton.image)
        game.mouseDisableCounter = 0
        game.mouseDisabled = true
      end
      break
    end
  end
  
  --determine whether any creeps will be attacked by towers--
  for i, tower in ipairs(game.towerList) do
    if not tower:isBusy() then
      if not tower.hasFired then
        game.determineCreepsInRange(tower)
      elseif tower.lastFired >= tower.attackSpeed then
        game.determineCreepsInRange(tower)
      end
    
    -- reset attack occupancy of tower after setting targets -- 
    tower:resetOccupancy()
    tower.lastFired = tower.lastFired + 0.05  -- TODO: variable-ize this constant
    end
  end
  
  --buffer time between mouse actions
  game.mouseDisableCounter = game.mouseDisableCounter + 1
  if game.mouseDisableCounter > game.mouseDisabledMax and not love.mouse.isDown(1) then
    game.mouseDisableCounter = 0
    game.mouseDisabled = false
  end
  
  --reset creep-related variables--
  game.refreshCreeps()
  
  --reset tower items--
  game.refreshTowers()

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
  
  --draw towers--
  love.graphics.setColor(255, 50, 50)
  for j=1, game.gridHeight do
    for i=1, game.gridWidth do
      if game.map[j][i] == game.blocked then
        coordX, coordY = utils.cellToCoord(i, j, game.cellSize)
        
        -- confirm that this grid contains a tower, mark with color
        for k=#game.towerList, 1, -1 do
          if game.towerList[k].x == j and game.towerList[k].y == i then
            
            -- print("found tower")
            love.graphics.setColor(255, 0, 255)
            break
          end
        
        end
        love.graphics.rectangle("fill", coordX, coordY, game.cellSize, game.cellSize)
      end
    end
  end
  
  --draw path--
  love.graphics.setColor(50, 255, 50)
  if game.path then
    for node in game.path:nodes() do
      coordX, coordY = utils.cellToCoord(node:getX(), node:getY(), game.cellSize)
      love.graphics.circle("fill", coordX + game.cellSize/2, coordY + game.cellSize/2, game.cellSize/8, game.cellSize/8)
    end
  end
  
  --draw creeps--
  for i, creep in ipairs(game.creepList) do
    creep:draw()
  end
  
  -- draw bullets --
  love.graphics.setColor(255, 50, 50)
  
  for i=#game.bulletList,1,-1 do
    bulletN = game.bulletList[i]
    startX, startY, bulletDx, bulletDy = bulletN:computeTrajectory(bulletN.x, bulletN.y, bulletN.destX, bulletN.destY)

    deltaTime = love.timer.getDelta()
    bulletN:setCoord(startX + bulletDx * deltaTime, startY + bulletDy* deltaTime)
   
    love.graphics.circle("fill", bulletN.x, bulletN.y, game.cellSize/10)
    
    -- bullet reaching destination, within error range
    -- TODO: fine tune error box
--    if bulletN:checkBulletReachDest(game.cellSize) then
--      -- remove bullet from list
--      table.remove(game.bulletList, i)
--    end
  end
  
end

function game.inGameArea(mouseX, mouseY)
  return mouseX < game.gameWidth and mouseY < game.gameHeight 
end

function game.generateCreep(creepImage)
  newCreep = creep(math.random(1,5)*100, math.random(1,5), creepImage, game.path)
--  newCreep = creep:new({HP = math.random(1,5)*100, speed = math.random(1,5), originalPath = game.path, image = creepImage})
  newCreep:setCoord(game.cellSize/4, game.cellSize/2)
  table.insert(game.creepList, newCreep)
end

function game.generateRandomCreep()
--  newCreep = creep:new({HP = math.random(1,5)*100, speed = math.random(1,5), nil, originalPath = game.path})
  newCreep = creep(math.random(1,5)*100, math.random(1,5), nil, game.path)
  newCreep:setCoord(game.cellSize/4, game.cellSize/2)
  table.insert(game.creepList, newCreep)
end

function game.refreshCreeps()
  game.creepUpdated = true
  game.creepLocations = {}
  for i=#game.creepList, 1, -1 do
    if game.creepList[i]:isDead() or game.creepList[i].atEnd then
      game.updateScore(game.creepList[i])
      table.remove(game.creepList, i)
    end
  end
end

function game.generateTower(cellY, cellX)
--  towerN = tower:new(({attackSpeed = 1, damage = 2, range = 10, attackCapacity = 1, size = 2}))
  towerN = tower(2,2,10,1,2)
  towerN:setCoord(cellX, cellY)
  table.insert(game.towerList, towerN)
end

function game.refreshTowers()
  -- skeleton, for the case that towers may have HP
end

function game.updateScore(creep)
  --blank function to be used later for incrementing score, adding money, etc.--
end


function game.determineCreepsInRange(tower)
  local x = tower.x
  local y = tower.y
  
  for i, creep in ipairs(game.creepList) do
    if tower:isBusy() then
      print("tower is busy")
      break
    end
    
    local creepX = creep.x
    local creepY = creep.y
    
    -- convert creep coordinates to grid cell coordinates
    creepCellY, creepCellX = utils.coordToCell(creepX, creepY, game.cellSize)
    
    --print("POSITIONS", x," ", y, " ", creepCellX, " ", creepCellY) 
    
    local distToTower = utils.dist(x,y,creepCellX,creepCellY)
        
    towerCoordX, towerCoordY = utils.cellToCoord(tower.x, tower.y, game.cellSize)  -- for bullet coordinates
    --print(towerCoordX, towerCoordY, creep.y, creep.x)
    
    print("distToTower", distToTower)
    
    if distToTower <= tower.range then      
      game.generateBullet(towerCoordX, towerCoordY, creep.x, creep.y)
      tower:incrementOccupancy()  -- is there an easy way to increment in Lua?
      tower.hasFired = true
      tower.lastFired = 0
    end
  end
end

function game.generateBullet(towerX, towerY, destX, destY)

  bulletN = bullet(50,3)
  
  bulletN:setOrigin(towerY, towerX)
  bulletN:setCourse(destX, destY)
  
  -- insert into bullet list -- 
  table.insert(game.bulletList, bulletN)
  
end

-- change the previously entered cellX and cellY to walkable
function game.revertPath()
  game.map[game.prevCellY][game.prevCellX] = game.walkable
  print("Can't build blocking path")
  game.path = game.myFinder:getPath(game.startx, game.starty, game.endx, game.endy, false)
end

return game