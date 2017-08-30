--imports--
utils = require('utils')
grid = require('jumper.grid') --https://github.com/Yonaba/Jumper.git
pathfinder = require('jumper.pathfinder')
button = require('UI.button')
creep = require('creep')
tower = require('tower')
bullet = require('bullet')

--declare variables--
titleText = "Grid Runner"
creepImageURLs = {"assets/blue-triangle.png", "assets/orange-star.png", "assets/yellow-diamond.png", "assets/teal-circle.png"}
creepTexts = {"Blue Triangle", "Orange Star", "Yellow Diamond", "Teal Circle"}
creepImages = {}
creepButtons = {}
creepButtonPadding = 20
displayButtonInfoBox = -1

gameWidth = 0
gameHeight = 0
sideBarWidth = 0
sideBarHeight = 0

cellSize = 0
gridWidth = 0
gridHeight = 0

map = {}
walkable = 0
blocked = 10

cells = nil
myFinder = nil

startx, starty = 1, 1
endx, endy = 1, 1
path = nil
prevCellX, prevCellY = 1, 1

mouseDisabled = false
mouseDisabledMax = 10
mouseDisableCounter = 0

creepList = {}
creepTimer = 0
creepTimerMax = 100
creepNumMax = 10
creepLocations = {}
creepUpdated = true

towerList = {}
towerUpdated = false

bulletList = {}

function love.load(arg)
  
  gameHeight = love.graphics.getHeight()
  gameWidth = (love.graphics.getWidth() * 4) / 5
  sideBarWidth = love.graphics.getWidth() / 5 -- let sidebar take 1/5 of the game window
  sideBarHeight = love.graphics.getHeight()
  
  cellSize = utils.findGCF(gameWidth, gameHeight) / 4
  gridWidth = gameWidth / cellSize
  gridHeight = gameHeight / cellSize
  
  for j=1,gridHeight do
    map[j] = {}
    for i=1,gridWidth do
      map[j][i] = walkable
    end
  end
  
  cells = grid(map)
  myFinder = pathfinder(cells, 'ASTAR', walkable)
  myFinder:setMode('ORTHOGONAL')
  endx, endy = gridWidth, gridHeight
  
  -- so creeps can create their own mini paths --
  creep.cells = cells
  creep.cellSize = cellSize
  
  -- set initial path --
  path = myFinder:getPath(startx, starty, endx, endy, false)
  
  -- set up creep buttons --
  buttonCoordPointer = {x = gameWidth, y = 0}
  for i, url in ipairs(creepImageURLs) do
    -- image
    creepImages[i] = love.graphics.newImage(url)
    creepButtons[i] = button:new()
    creepButtons[i]:setImage(creepImages[i])
    creepButtons[i]:setSize(sideBarWidth / 2 - creepButtonPadding, sideBarWidth / 2 - creepButtonPadding)
    
    -- coord
    creepButtons[i]:setCoord(buttonCoordPointer.x + creepButtonPadding / 2, buttonCoordPointer.y + creepButtonPadding / 2)
    if buttonCoordPointer.x + creepButtons[i].width + creepButtonPadding < love.graphics.getWidth() then
      buttonCoordPointer.x = buttonCoordPointer.x + creepButtons[i].width + creepButtonPadding
    else
      buttonCoordPointer.y = buttonCoordPointer.y + creepButtons[i].height + creepButtonPadding
      buttonCoordPointer.x = gameWidth
    end
    
    --function
    creepButtons[i]:setHit(generateCreep)
    creepButtons[i]:setText(creepTexts[i])
    
  end
  
end

function love.update(dt)

  --easy way to exit game
  if love.keyboard.isDown('escape') then
    love.event.push('quit')
  end
  
  --generate creep automatically
  creepTimer = creepTimer + 1
  if creepTimer > creepTimerMax and #creepList < creepNumMax then
    creepTimer = 0
    generateRandomCreep()
  end
  
  --update creeps
  for i, creep in ipairs(creepList) do
    if creep:update(path) then
      table.insert(creepLocations, {utils.coordToCell(creep.x, creep.y, cellSize)})
    else
      revertPath()
      refreshCreeps()
      break
    end
  end
  
  --mouse actions
  mouseCoordX, mouseCoordY = love.mouse.getX(), love.mouse.getY()
  
  --building tower mouse actions
  if love.mouse.isDown(1) and not mouseDisabled and inGameArea(mouseCoordX, mouseCoordY) then
    
    cellX, cellY = utils.coordToCell(mouseCoordX, mouseCoordY, cellSize)
    noCreepInCell = true
    
    --check to see if obstacle to be placed would be on top of a creep
    --only build if it is not
    for i, coord in ipairs(creepLocations) do
      if cellX == coord[1] and cellY == coord[2] then
        noCreepInCell = false
      end
    end
    
    if noCreepInCell then
      --notice cellX and cellY are flipped to coincide with the pathfinder module
      if map[cellY][cellX] == walkable then
        map[cellY][cellX] = blocked
        -- print("blocked cell (", cellX, cellY, ")")
        -- print("generating tower")
        generateTower(cellX, cellY)
      else
        map[cellY][cellX] = walkable
      end
      prevCellX, prevCellY = cellX, cellY --set the revert path mechanism
      mouseDisableCounter = 0
      mouseDisabled = true
      
      path = myFinder:getPath(startx, starty, endx, endy, false)
      if not path then
        revertPath()
      end
    end
  end
  
  --sidebar mouse actions
  displayButtonInfoBox = -1
  for i, creepButton in ipairs(creepButtons) do
    if creepButton:onButton(mouseCoordX, mouseCoordY) then
      displayButtonInfoBox = i
      if love.mouse.isDown(1) and not mouseDisabled then
        creepButton.hit(creepButton.image)
        mouseDisableCounter = 0
        mouseDisabled = true
      end
      break
    end
  end
  
  --determine whether any creeps will be attacked by towers--
  for i, tower in ipairs(towerList) do
    if not tower:isBusy() then
      if not tower.hasFired then
        determineCreepsInRange(tower)
      else if tower.lastFired >= tower.attackSpeed then
        determineCreepsInRange(tower)
      end
    end
    -- reset attack occupancy of tower after setting targets -- 
    tower:resetOccupancy()
    tower.lastFired = tower.lastFired + 0.05  -- TODO: variable-ize this constant
  end
end
  
  --buffer time between mouse actions
  mouseDisableCounter = mouseDisableCounter + 1
  if mouseDisableCounter > mouseDisabledMax and not love.mouse.isDown(1) then
    mouseDisableCounter = 0
    mouseDisabled = false
  end
  
  --reset creep-related variables--
  refreshCreeps()
  
  --reset tower items--
  refreshTowers()

end

function love.draw(dt)
  
  --draw sidebar--
  love.graphics.setColor(255, 255, 255)
  for i, creepButton in ipairs(creepButtons) do
    creepButton:draw()
    if (displayButtonInfoBox == i) then
      creepButton:drawInfoBox()
    end
  end

  --draw grid--
  --vertical lines--
  love.graphics.setColor(255, 255, 255)
  for i=0, gameWidth, cellSize do
    love.graphics.line(i, 0, i, gameHeight)
  end
  --horizontal lines--
  for i=0, gameHeight, cellSize do
    love.graphics.line(0, i, gameWidth, i)
  end
  
  --draw towers--
  love.graphics.setColor(255, 50, 50)
  for j=1, gridHeight do
    for i=1, gridWidth do
      if map[j][i] == blocked then
        coordX, coordY = utils.cellToCoord(i, j, cellSize)
        
        -- confirm that this grid contains a tower, mark with color
        for k=#towerList, 1, -1 do
          if towerList[k].x == j and towerList[k].y == i then
            
            -- print("found tower")
            love.graphics.setColor(255, 0, 255)
            break
          end
        
        end
        love.graphics.rectangle("fill", coordX, coordY, cellSize, cellSize)
      end
    end
  end
  
  --draw path--
  love.graphics.setColor(50, 255, 50)
  if path then
    for node in path:nodes() do
      coordX, coordY = utils.cellToCoord(node:getX(), node:getY(), cellSize)
      love.graphics.circle("fill", coordX + cellSize/2, coordY + cellSize/2, cellSize/8, cellSize/8)
    end
  end
  
  --draw creeps--
  for i, creep in ipairs(creepList) do
    creep:draw()
  end
  
  -- draw bullets --
  love.graphics.setColor(255, 50, 50)
  
  for i=#bulletList,1,-1 do
    bullet = bulletList[i]
    startX, startY, bulletDx, bulletDy = bullet:computeTrajectory(bullet.x, bullet.y, bullet.destX, bullet.destY)

    deltaTime = love.timer.getDelta()
    bullet:setCoord(startX + bulletDx * deltaTime, startY + bulletDy* deltaTime)
   
    love.graphics.circle("fill", bullet.x, bullet.y, cellSize/10)
    
    -- bullet reaching destination, within error range
    if utils.checkBulletCollision(bullet.x, bullet.y, bullet.destX, bullet.destY, cellSize, cellSize) then
      -- remove bullet from list
      table.remove(bulletList, i)
    end
  end
end

function inGameArea(mouseX, mouseY)
  return mouseX < gameWidth and mouseY < gameHeight 
end

function generateCreep(creepImage)
  newCreep = creep:new({HP = math.random(1,5)*100, speed = math.random(1,5), originalPath = path, image = creepImage})
  newCreep:setCoord(cellSize/4, cellSize/2)
  table.insert(creepList, newCreep)
end

function generateRandomCreep()
  newCreep = creep:new({HP = math.random(1,5)*100, speed = math.random(1,5), originalPath = path})
  newCreep:setCoord(cellSize/4, cellSize/2)
  table.insert(creepList, newCreep)
end

function refreshCreeps()
  creepUpdated = true
  creepLocations = {}
  for i=#creepList, 1, -1 do
    if creepList[i]:isDead() or creepList[i].atEnd then
      updateScore(creepList[i])
      table.remove(creepList, i)
    end
  end
end

function generateTower(cellY, cellX)
  --towerN = tower:new(({attackSpeed = 1, damage = 2, range = 10, attackCapacity = 1, size = 2}))
  
  towerN = tower(1, 2, 10, 1, 2)
  towerN:setCoord(cellX, cellY)
  table.insert(towerList, towerN)
end

function refreshTowers()
  -- skeleton, for the case that towers may have HP
end

function updateScore(creep)
  --blank function to be used later for incrementing score, adding money, etc.--
end


function determineCreepsInRange(tower)
  local x = tower.x
  local y = tower.y
  
  for i, creep in ipairs(creepList) do
    if tower:isBusy() then
      print("tower is busy")
      break
    end
    
    local creepX = creep.x
    local creepY = creep.y
    
    -- convert creep coordinates to grid cell coordinates
    creepCellY, creepCellX = utils.coordToCell(creepX, creepY, cellSize)
    
    --print("POSITIONS", x," ", y, " ", creepCellX, " ", creepCellY) 
    
    local distToTower = utils.dist(x,y,creepCellX,creepCellY)
        
    towerCoordX, towerCoordY = utils.cellToCoord(tower.x, tower.y, cellSize)  -- for bullet coordinates
    --print(towerCoordX, towerCoordY, creep.y, creep.x)
    
    print("distToTower", distToTower)
    
    if distToTower <= tower.range then      
      generateBullet(towerCoordX, towerCoordY, creep.x, creep.y)
      tower:incrementOccupancy()  -- is there an easy way to increment in Lua?
      tower.hasFired = true
      tower.lastFired = 0
    end
  end
end


count = 0

function generateBullet(towerX, towerY, destX, destY)
  
  bulletN = bullet:new({damage=1, speed=1})
  
  bulletN:setOrigin(towerY, towerX)
  bulletN:setCourse(destX, destY)
  
  -- insert into bullet list -- 
  table.insert(bulletList, bulletN)
  
end

-- change the previously entered cellX and cellY to walkable
function revertPath()
  map[prevCellY][prevCellX] = walkable
  print("Can't build blocking path")
  path = myFinder:getPath(startx, starty, endx, endy, false)
end