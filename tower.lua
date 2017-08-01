local tower = {}
  -- if it belongs to the indv object, do object:function()
  -- if it's static, do object.function()
  
  -- make a object-specific draw function
  

  tower.attackSpeed = 1
  tower.damage = 2
  tower.range = 4
  tower.areaOfEffect = 1
  tower.needsUpdate = false -- since towers are stationary, won't change unless upgrade
  
  
  function tower:draw()
    -- redraw all towers on map
    
  end

return tower