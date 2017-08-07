--imports--
utils = require('utils')
grid = require('jumper.grid')
pathfinder = require('jumper.pathfinder')
creep = require('creep')
tower = require('tower')

--declare variables--
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
  
  --create obstacle
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
  love.graphics.setColor(50, 50, 255)
  for i, creep in ipairs(creepList) do
    love.graphics.circle("fill", creep.x, creep.y, cellSize/6, cellSize/6)
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
  towerN = tower:new(({attackSpeed = 1, damage = 2, range = 4, size = 2}))
  towerN:setCoord(cellX, cellY)
  table.insert(towerList, towerN)
end

function refreshTowers()
  -- skeleton, for the case that towers may have HP
end

function updateScore(creep)
  --blank function to be used later for incrementing score, adding money, etc.--
end

-- change the previously entered cellX and cellY to walkable
function revertPath()
  map[prevCellY][prevCellX] = walkable
  print("Can't build blocking path")
  path = myFinder:getPath(startx, starty, endx, endy, false)
end