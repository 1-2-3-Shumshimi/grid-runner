--base class for other creep classes
--handles positioning, pathfinding, and external resource management (i.e. currency)

creep = class {
  init = function(self, creepID, HP, speed, shield, bounty, incomeBoost, playerOwner)
    
    self.creepID = creepID
    self.HP = HP
    self.speed = speed
    self.isGhost = false
    self.shield = shield
    self.bounty = bounty
    self.incomeBoost = incomeBoost
    self.x = 0
    self.y = 0
    self.direction = constants.DOWN
    
    self.isAtEnd = false
    self.isTrapped = false
    self.path = nil
    self.finder = nil
    self.checkpointCellX, self.checkpointCellY = nil, nil
    self.currPathIndex = 1
    self.currPathNodeIndex = 1
    self.playerOwner = playerOwner
    self.playerDefender = nil
    
    if self.playerOwner == 1 then
      --creeps go on the opposing player's path
      self.playerDefender = 2
      self.finder = pathfinder(grid(game.player2PathMap), 'ASTAR', game.WALKABLE)
    elseif playerOwner == 2 then
      self.playerDefender = 1
      self.finder = pathfinder(grid(game.player1PathMap), 'ASTAR', game.WALKABLE)
    else
      utils.log("in creep init(), unexpected playerOwner input")
    end
    
    if self.finder ~= nil then
      self.finder:setMode('ORTHOGONAL')
      self.path = game.getPath(self.playerDefender, 1)
      self:setNewCheckpoint(game.getGoalCoordsOfPath(self.playerDefender, self.currPathIndex))
    end
    
    self.width = game.cellWidth
    self.height = game.cellHeight
    
  end
  
}

function creep:updateHP(deltaHP)
  self.HP = self.HP + deltaHP
end

function creep:updateSpeed(deltaSpeed)
  self.speed = self.speed + deltaSpeed
end

function creep:setCoord(x, y)
  self.x = x
  self.y = y
end

function creep:isDead()
  return self.HP <= 0
end

--return true is a new path is successfully created, false otherwise
function creep:setNewPath()
  cellX, cellY = utils.coordToCell(self.x, self.y, game.cellWidth)
  self.path = self.finder:getPath(cellX, cellY, self.checkpointCellX, self.checkpointCellY)
  return self.path ~= nil
end

function creep:setNewCheckpoint(x, y)
  self.checkpointCellX, self.checkpointCellY = x, y
end

function creep:didReachEnd(playerNum, x, y)
  endGoalCoords = game.getEndGoalCoords(playerNum)
  if endGoalCoords[0] ~= nil then
    return endGoalCoords[0] == x and endGoalCoords[1] == y
  end
end

function creep:update()
  currCellX, currCellY = utils.coordToCell(self.x, self.y, game.cellWidth)
  nextCellX, nextCellY = nil, nil
  
  --TODO
  --countsdown and executes (if possible), delayed actions
  --delayed actions are usually handling effects of bullets
--  self:decrementAndCheckDelayedActions() 
  
  if self.path then
    lookNextCell = false
    isLastCell = false
    for i = self.currPathNodeIndex, #self.path._nodes do
      node = self.path._nodes[i]
      if currCellX == node:getX() and currCellY == node:getY() then
        --followed path to current; now need the next
        lookNextCell = true
        isLastCell = ( count == #self.path._nodes ) --true if reached the end of current path
      elseif lookNextCell then
        self.currPathNodeIndex = self.currPathNodeIndex + 1
        nextCellX, nextCellY = node:getX(), node:getY()
        break
      end
    end
    
    if isLastCell then
      if self:didReachEnd(self.playerDefender, currCellX, currCellY) then
        self.isAtEnd = true
      else
        self:moveToNextCheckpoint()
      end
    elseif nextCellX and nextCellY then
      self:move(currCellX, currCellY, nextCellX, nextCellY)
    else
      --there was no next cell to go, try making new path
      self:setNewPath()
    end
  else
    self.isTrapped = true
  end
  
end

function creep:moveToNextCheckpoint()
  self.currPathIndex = self.currPathIndex + 1
  self:setNewCheckpoint(game.getGoalCoordsOfPath(self.playerDefender, self.currPathIndex))
  self:setNewPath()
  self.currPathNodeIndex = 1
end

function creep:move(currCellX, currCellY, nextCellX, nextCellY)

  self:updateDirection(currCellX, currCellY, nextCellX, nextCellY)
  if self.direction == constants.RIGHT then
    self.x = self.x + self.speed
  elseif self.direction == constants.LEFT then
    self.x = self.x - self.speed
  elseif self.direction == constants.DOWN then
    self.y = self.y + self.speed
  elseif self.direction == constants.UP then
    self.y = self.y - self.speed
  end
end

function creep:updateDirection(currCellX, currCellY, nextCellX, nextCellY)
  
  nextCoordX, nextCoordY = utils.cellToCoord(nextCellX, nextCellY, game.cellWidth)
  if currCellX < nextCellX and nextCoordY + game.cellWidth > self.y + self.height then
    self.direction = constants.RIGHT
  elseif currCellX > nextCellX and nextCoordY + game.cellWidth > self.y + self.height then
    self.direction = constants.LEFT
  elseif currCellY < nextCellY and nextCoordX + game.cellWidth > self.x + self.width then
    self.direction = constants.DOWN
  elseif currCellY > nextCellY and nextCoordX + game.cellWidth > self.x + self.width then
    self.direction = constants.UP
  end
end