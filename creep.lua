local creep = {}

  creep.HP = 0
  creep.speed = 0

-- create a new creep object --
-- either pass in a table with {HP = x, and speed = x}
-- or set it later
  function creep:new(object)
    object = object or {HP = creep.HP, speed = creep.speed}
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
  
-- a toString method for creep --
  function creep:toString()
    return "Creep HP = "..self.HP..", speed = "..self.speed
  end

-- update a creep object
  function creep.update() 
    
  end
  
return creep