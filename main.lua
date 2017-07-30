--imports--
utils = require('utils')
grid = require('jumper.grid')
pathfinder = require('jumper.pathfinder')
creep = require('creep')
tower = require('tower')

--declare variables--
cellSize = 0
gridWidth = 0
gridHeight = 0

map = {}
walkable = 0

cells = nil
myFinder = nil

startx, starty = 1, 1
endx, endy = 1, 1
path = nil

mouseDisabled = false
mouseDisableCounter = 0

creepList = {}
towerList = {}

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
  myFinder = pathfinder(cells, 'BFS', walkable)
  myFinder:setMode('ORTHOGONAL')
  endx, endy = gridWidth, gridHeight
  
  -- set initial path --
  path = myFinder:getPath(startx, starty, endx, endy, false)
  
  -- testing creep object orientedness
  table.insert(creepList, creep:new())
  creepList[1]:setHP(200)
  table.insert(creepList, creep:new({HP = 100, speed = 5}))
  for i, creep in ipairs(creepList) do
    print (creep:toString())
  end

end

function love.update(dt)

  --easy way to exit game
  if love.keyboard.isDown('escape') then
    love.event.push('quit')
  end
  
  --create obstacle
  if love.mouse.isDown(1) and not mouseDisabled then
    cellX, cellY = utils.coordToCell(love.mouse.getX(), love.mouse.getY(), cellSize)
    --notice cellX and cellY are flipped to coincide with the pathfinder module
    if map[cellY][cellX] == walkable then
      map[cellY][cellX] = blocked
    else
      map[cellY][cellX] = walkable
    end
    mouseDisableCounter = 0
    mouseDisabled = true
    path = myFinder:getPath(startx, starty, endx, endy, false)
  end
  
  mouseDisableCounter = mouseDisableCounter + 1
  if mouseDisableCounter > 10 and not love.mouse.isDown(1) then
    mouseDisableCounter = 0
    mouseDisabled = false
  end

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
  
  --draw blocks--
  love.graphics.setColor(255, 50, 50)
  for j=1, gridHeight do
    for i=1, gridWidth do
      if map[j][i] == blocked then
        cellX, cellY = utils.cellToCoord(i, j, cellSize)
        love.graphics.rectangle("fill", cellX, cellY, cellSize, cellSize)
      end
    end
  end
  
  --draw path--
  love.graphics.setColor(50, 255, 50)
  if path then
    for node in path:nodes() do
      cellX, cellY = utils.cellToCoord(node.x, node.y, cellSize)
      love.graphics.circle("fill", cellX + cellSize/2, cellY + cellSize/2, cellSize/8, cellSize/8)
    end
  end
end

