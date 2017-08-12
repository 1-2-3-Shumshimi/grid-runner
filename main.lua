--imports--
utils = require('utils')
grid = require('jumper.grid')
pathfinder = require('jumper.pathfinder')
creep = require('creep')
tower = require('tower')
bullet = require('bullet')

--declare variables--
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
  
  cellSize = utils.findGCF(love.graphics.getWidth(), love.graphics.getHeight()) / 4
  gridWidth = love.graphics.getWidth() / cellSize
  gridHeight = love.graphics.getHeight() / cellSize
  
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
  
  --create obstacle/tower
  if love.mouse.isDown(1) and not mouseDisabled then
    cellX, cellY = utils.coordToCell(love.mouse.getX(), love.mouse.getY(), cellSize)
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
  
  --determine whether any creeps will be attacked by towers--
  for i, tower in ipairs(towerList) do
    if not tower:isBusy() then
      if not tower.hasFired then
        determineCreepsInRange(tower)
      else if tower.lastFired >= tower.attackSpeed then
        determineCreepsInRange(tower)
      end
    end
    tower.lastFired = tower.lastFired + 0.01  -- TODO: variable-ize this constant
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

  --draw grid--
  --vertical lines--
  love.graphics.setColor(255, 255, 255)
  for i=0, love.graphics:getWidth(), cellSize do
    love.graphics.line(i, 0, i, love.graphics:getHeight())
  end
  --horizontal lines--
  for i=0, love.graphics:getHeight(), cellSize do
    love.graphics.line(0, i, love.graphics.getWidth(), i)
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
            
            -- reset attack occupancy of towers -- 
            towerList[k]:resetOccupancy()
            
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
      coordX, coordY = utils.cellToCoord(node.x, node.y, cellSize)
      love.graphics.circle("fill", coordX + cellSize/2, coordY + cellSize/2, cellSize/8, cellSize/8)
    end
  end
  
  --draw creeps--
  love.graphics.setColor(50, 50, 255)
  for i, creep in ipairs(creepList) do
    love.graphics.circle("fill", creep.x, creep.y, cellSize/6, cellSize/6)
  end
  
  -- draw bullets --
  love.graphics.setColor(255, 50, 50)
  for i, bullet in ipairs(bulletList) do
    print("creating bullet")
    --moveSet = bullet:computeTrajectory(bullet.x, bullet.y, bullet.destX, bullet.destY)
    startX, startY, bulletDx, bulletDy = bullet:computeTrajectory(bullet.x, bullet.y, bullet.destX, bullet.destY)
    
    
    
    
    deltaTime = love.timer.getDelta()
    bullet:setCoord(startX + bulletDx * deltaTime, startY + bulletDy* deltaTime)
   
    --bullet:setCoord(moveSet.x + moveSet.dx * dt, moveSet.y + moveSet.dy * dt)
    love.graphics.circle("fill", bullet.x, bullet.y, cellSize/8, cellSize/8)
    
    -- bullet reaching destination, within error range
    if utils.dist(bullet.x, bullet.y, bullet.destX, bullet.destY) < 0.05 then
      -- remove bullet from list
      table.remove(bulletList, i)
      i = i-1
    end
    
  end
  

  
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
  towerN = tower:new(({attackSpeed = 1, damage = 2, range = 4, attackCapacity = 1, size = 2}))
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