creep = class {
  init = function(self, HP, speed, spriteSheet, originalPath)
    self.HP = HP
    self.speed = speed
    self.x = 0
    self.y = 0
    
    self.atEnd = false
    self.recentlyOffPath = false
    self.originalPath = originalPath
    self.newPath = nil
    self.finder = pathfinder(game.cells, 'ASTAR', walkable)
    self.finder:setMode('ORTHOGONAL')
    
    self.spriteSheet = spriteSheet
    if self.spriteSheet then
      self.grid = anim8.newGrid(32, 32, spriteSheet:getWidth(), spriteSheet:getHeight())
      self.upAnim = anim8.newAnimation(self.grid('1-2', 1), game.dt*10) --TODO: variablize animation rate?
      self.downAnim = anim8.newAnimation(self.grid('1-2', 2), game.dt*10)
      self.leftAnim = anim8.newAnimation(self.grid(3, '1-2'), game.dt*10)
      self.rightAnim = anim8.newAnimation(self.grid(4, '1-2'), game.dt*10)
    end
    self.direction = "down"
  end
}

-- set health points of creep --
  function creep:setHP(HP)
    self.HP = HP
  end
  
-- set speed of creep --
  function creep:setSpeed(speed)
    self.speed = speed
  end
  
  -- set x and y coord of creep --
  function creep:setCoord(x, y)
    self.x = x
    self.y = y
  end
  
  -- creep is dead if HP is less than or equal to 0
  function creep:isDead()
    return self.HP <= 0
  end
  
  -- set new path as creep's current coord as the start
  function creep:setNewPath()
    oldPath = self.originalPath
    x, y = utils.coordToCell(self.x, self.y, game.cellSize)
    if oldPath then
      self.newPath = self.finder:getPath(x, y, oldPath._nodes[oldPath:getLength() + 1]:getX(), oldPath._nodes[oldPath:getLength() + 1]:getY())
    end
  end
  
-- a toString method for creep --
  function creep:toString()
    return "Creep HP = "..self.HP..", speed = "..self.speed
  end
  
  -- creep got to the last cell
  function creep:reachedEnd()
    self.atEnd = true
  end

-- update a creep object
  function creep:update(path)
    self_cellX, self_cellY = utils.coordToCell(self.x, self.y, game.cellSize)
    lookNextCell = false
    isLastCell = false
    next_cellX, next_cellY = nil, nil
    
    if path then
      for node, count in path:iter() do
        if self_cellX == node:getX() and self_cellY == node:getY() then --followed path to current; now need next
          lookNextCell = true
          isLastCell = ( count == path:getLength() + 1 ) -- +1 for one-based indexing
        elseif lookNextCell then
          next_cellX, next_cellY = node:getX(), node:getY()
          break
        end
      end
      
      if isLastCell then 
        self:reachedEnd()
      elseif next_cellX and next_cellY then
        self:move(self_cellX, self_cellY, next_cellX, next_cellY)
        self.recentlyOffPath = false
      elseif self.recentlyOffPath then
        self:setNewPath()
        if self.newPath then
          for node, count in self.newPath:iter() do
            if self_cellX == node:getX() and self_cellY == node:getY() then --followed path to current; now need next
              lookNextCell = true
              isLastCell = ( count == self.newPath:getLength() + 1 ) -- +1 for one-based indexing
            elseif lookNextCell then
              next_cellX, next_cellY = node:getX(), node:getY()
              break
            end
          end
          self:move(next_cellX, next_cellY)
        else 
          print ("creep is trapped")
          return false
        end
      else
        print ("Getting back on the main path")
        self.recentlyOffPath = true
      end
      return true
    else
      print ("no path available")
      return false
    end
  end
  
  -- takes the cell size and next cell x,y of the creep and sets the creep x,y
  function creep:move(self_cellX, self_cellY, next_cellX, next_cellY)
    next_coordX, next_coordY = utils.cellToCoord(next_cellX, next_cellY, game.cellSize)
    self:updateDirection(self_cellX, self_cellY, next_cellX, next_cellY)
    
    if self.direction == "right" then
      self.x = self.x + self.speed
    elseif self.direction == "left" then
      self.x = self.x - self.speed
    elseif self.direction == "up" then
      self.y = self.y - self.speed
    elseif self.direction == "down" then
      self.y = self.y + self.speed
    end
  end
  
  function creep:updateDirection(self_cellX, self_cellY, next_cellX, next_cellY)
    if self.spriteSheet then
      xDiffBigger = math.abs(self_cellX - next_cellX) - math.abs(self_cellY - next_cellY) > 0
      if xDiffBigger then 
        if self_cellX < next_cellX then 
          self.direction = "right"
          self.rightAnim:update(game.dt)
        else
          self.direction = "left"
          self.leftAnim:update(game.dt)
        end
      else
        if self_cellY > next_cellY then
          self.direction = "up"
          self.upAnim:update(game.dt)
        else
          self.direction = "down"
          self.downAnim:update(game.dt)
        end
      end
    end
  end
  
  -- draw creep object
  function creep:draw()
    if self.spriteSheet then
      love.graphics.setColor(255, 255, 255)
--      scaleX = (creep.cellSize / 2) / self.image:getWidth()
--      scaleY = (creep.cellSize / 2) / self.image:getHeight()
--      love.graphics.draw(self.image, self.x, self.y, 0, scaleX, scaleY, creep.cellSize, creep.cellSize)
      if self.direction == "right" then
        self.rightAnim:draw(self.spriteSheet, self.x, self.y)
      elseif self.direction == "left" then
        self.leftAnim:draw(self.spriteSheet, self.x, self.y)
      elseif self.direction == "up" then
        self.upAnim:draw(self.spriteSheet, self.x, self.y)
      else
        self.downAnim:draw(self.spriteSheet, self.x, self.y)
      end
    else
      love.graphics.setColor(50, 50, 255)
      love.graphics.circle("fill", self.x, self.y, game.cellSize/6, game.cellSize/6)
    end
  end
  
return creep