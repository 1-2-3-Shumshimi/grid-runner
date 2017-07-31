local creep = {}

  creep.HP = 0
  creep.speed = 0
  creep.x = 0
  creep.y = 0
  creep.atEnd = false

-- create a new creep object --
-- either pass in a table with {HP = x, and speed = x}
-- or set it later
  function creep:new(object)
    object = object or {HP = creep.HP, speed = creep.speed}
    object.reachedEnd = creep.reachedEnd
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
  
-- a toString method for creep --
  function creep:toString()
    return "Creep HP = "..self.HP..", speed = "..self.speed
  end
  
  -- creep got to the last cell
  function creep:reachedEnd()
    self.atEnd = true
  end

-- update a creep object
  function creep:update(path, cellSize)
    self_cellX, self_cellY = utils.coordToCell(self.x, self.y, cellSize)
    lookNextCell = false
    isLastCell = false
    next_cellX, next_cellY = nil, nil
    
    if path then
      for node, count in path:iter() do
        if self_cellX == node.x and self_cellY == node.y then --followed path to current; now need next
          lookNextCell = true
          isLastCell = ( count == path:getLength() + 1 ) -- +1 for one-based indexing
        elseif lookNextCell then
          next_cellX, next_cellY = node.x, node.y
          break
        end
      end
      
      if isLastCell then 
        self:reachedEnd()
      elseif next_cellX == nil or next_cellY == nil then
        print ("Couldn't find next path")
      else
        next_coordX, next_coordY = utils.cellToCoord(next_cellX, next_cellY, cellSize)
        self.x = self.x + ((next_coordX - self.x + cellSize/2) / 20) * self.speed
        self.y = self.y + ((next_coordY - self.y + cellSize/2) / 20) * self.speed
      end
      return true
    else
      print ("no path available")
      return false
    end
  end
  
  -- draw creep object
  function creep:draw()
    -- Empty for now, but potentially migrate functionality from main 
    -- drawing becomes more complicated
  end
  
return creep