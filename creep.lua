local creep = {}

  creep.HP = 0
  creep.speed = 0
  creep.x = 0
  creep.y = 0
  creep.atEnd = false
  creep.recentlyOffPath = false
  creep.originalPath = nil
  creep.newPath = nil
  creep.cells = nil
  creep.finder = nil
  creep.cellSize = 0
  creep.image = nil

-- create a new creep object --
-- either pass in a table with {HP = x, speed = x, originalPath = path}
-- or set it later
  function creep:new(object)
    object = object or {HP = creep.HP, speed = creep.speed}
    object.reachedEnd = creep.reachedEnd
    object.recentlyOffPath = creep.recentlyOffPath

    creep.finder = pathfinder(creep.cells, 'ASTAR', walkable)
    creep.finder:setMode('ORTHOGONAL')
    
    setmetatable(object, self)
    self.__index = self
    return object
  end

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
    x, y = utils.coordToCell(self.x, self.y, creep.cellSize)
    if oldPath then
      self.newPath = creep.finder:getPath(x, y, oldPath._nodes[oldPath:getLength() + 1]:getX(), oldPath._nodes[oldPath:getLength() + 1]:getY())
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
    self_cellX, self_cellY = utils.coordToCell(self.x, self.y, creep.cellSize)
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
        self:move(next_cellX, next_cellY)
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
  function creep:move(next_cellX, next_cellY)
    next_coordX, next_coordY = utils.cellToCoord(next_cellX, next_cellY, creep.cellSize)
    self.x = self.x + ((next_coordX - self.x + creep.cellSize/2) / 20) * self.speed
    self.y = self.y + ((next_coordY - self.y + creep.cellSize/2) / 20) * self.speed
  end
  
  -- draw creep object
  function creep:draw()
    if self.image then
      love.graphics.setColor(255, 255, 255)
      scaleX = (creep.cellSize / 2) / self.image:getWidth()
      scaleY = (creep.cellSize / 2) / self.image:getHeight()
      love.graphics.draw(self.image, self.x, self.y, 0, scaleX, scaleY, creep.cellSize, creep.cellSize)
    else
      love.graphics.setColor(50, 50, 255)
      love.graphics.circle("fill", self.x, self.y, cellSize/6, cellSize/6)
    end
  end
  
return creep