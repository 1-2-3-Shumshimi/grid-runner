tower = class{
  init = function(self, attackSpeed, damage, range, attackCapacity, size)
    self.attackSpeed = attackSpeed
    self.damage = damage
    self.range = range
    self.attackCapacity = attackCapacity
    self.size = size
    
    self.attackOccupancy = 0 
    self.hasFired = false
    self.lastFired = 0
    self.x = 0
    self.y = 0
    self.coordX = 0
    self.coordY = 0
    self.needsUpdate = false
    
    self.width = 32
    self.height = 32
    self.spritesheet = nil
    self.upAnim = nil
    self.downAnim = nil
    self.leftAnim = nil
    self.rightAnim = nil
    self.direction = "left"
  end
}
  
  -- these are inverted from pathfinder module ... ?
  function tower:setCoord(x, y) 
    self.x = x
    self.y = y
    self.coordX, self.coordY = utils.cellToCoord(self.x, self.y, game.cellSize)
    self.coordY = self.coordY + 9
    self.coordX = self.coordX + 9
  end
  
  -- determines whether tower is attacking max # of creeps
  function tower:isBusy()
    return (self.attackCapacity == self.attackOccupancy)
  end
  
  function tower:incrementOccupancy()
    self.attackOccupancy = self.attackOccupancy + 1
  end
  
  function tower:resetOccupancy()
    self.attackOccupancy = 0
  end
  
  function tower:draw()
    
    if self.spriteSheet then
      love.graphics.setColor(255, 255, 255)
      if self.direction == "right" then
        self.rightAnim:draw(self.spriteSheet, self.coordX, self.coordY)
      elseif self.direction == "left" then
        self.leftAnim:draw(self.spriteSheet, self.coordX, self.coordY)
      elseif self.direction == "up" then
        self.upAnim:draw(self.spriteSheet, self.coordX, self.coordY)
      else
        self.downAnim:draw(self.spriteSheet, self.coordX, self.coordY)
      end
    else
      love.graphics.setColor(255, 50, 50)
      love.graphics.rectangle("fill", self.coordX, self.coordY, game.cellSize, game.cellSize)
    end
  end
  
  function tower:setSpriteSheet(spriteSheet)
    self.spriteSheet = spriteSheet
    self.grid = anim8.newGrid(self.width, self.height, spriteSheet:getWidth(), spriteSheet:getHeight())
    -- towers just have one sprite per direction here so not actually animating
    self.upAnim = anim8.newAnimation(self.grid(3, 1), game.dt*10) --TODO: variablize animation rate?
    self.downAnim = anim8.newAnimation(self.grid(4, 1), game.dt*10)
    self.leftAnim = anim8.newAnimation(self.grid(1, 1), game.dt*10)
    self.rightAnim = anim8.newAnimation(self.grid(2, 1), game.dt*10)
  end
  
  function tower:updateDirection(creep_CoordX, creep_CoordY)
    
    if self.spriteSheet then
      xDiffBigger = math.abs(self.coordX - creep_CoordX) - math.abs(self.coordY - creep_CoordY) > 0
      if xDiffBigger then
        if self.coordX < creep_CoordX then
          self.direction = "right"
        else
          self.direction = "left"
        end
      else
        if self.coordY < creep_CoordY then
          self.direction = "down"
        else
          self.direction = "up"
        end
      end
    end
  end

return tower