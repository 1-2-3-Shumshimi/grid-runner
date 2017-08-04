local tower = {}
  -- if it belongs to the indv object, do object:function()
  -- if it's static, do object.function()
  
  -- make a object-specific draw function
  

  -- gameplay characteristics
  tower.attackSpeed = 1
  tower.damage = 2
  tower.range = 4
  tower.attackCapacity = 1  -- i.e. # of enemies it can attack simultaneously
  
  -- map placement characteristics
  tower.size = 1
  
  tower.x = 0 -- upper left side coordinates
  tower.y = 0
  tower.needsUpdate = false -- towers are stationary, won't change after initial draw unless upgrade

  
  -- create a new creep object
  -- either pass in a table with {} or set it later
  function tower:new(object)
    object = object or {attackSpeed = tower.attackSpeed, damage = tower.damage, range = tower.range, attackCapacity = tower.attackCapacity, size = tower.size}
    
    object.needsUpdate = true
    
    setmetatable(object, self)
    self.__index = self
    return object
    
  end
  
  -- these are inverted from pathfinder module ... ?
  function tower:setCoord(x, y) 
    self.x = x
    self.y = y
  end
  
  function tower:draw()
    -- redraw all towers on map
    
  end

return tower