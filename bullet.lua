-- from https://love2d.org/wiki/Tutorial:Fire_Toward_Mouse

bullet = class {
  init = function(self, damage, speed)
    self.damage = damage
    self.speed = speed
    self.x = 0
    self.y = 0
    self.destX = 0
    self.destY = 0
    self.onHit = nil
  end
}

function bullet:update()


end

function bullet:setOnHit(func)
  self.onHit = func
end

function bullet:setOrigin(towerX, towerY)
  self.x = towerX
  self.y = towerY
end
function bullet:setCourse(destX, destY)
  self.destX = destX
  self.destY = destY
end
function bullet:setCoord(intermedX, intermedY)
  self.x = intermedX
  self.y = intermedY
end

function bullet:computeTrajectory(startX, startY, endX, endY)

  local angle = math.atan2((endY - startY), (endX - startX))

  local bulletDx = self.speed * 2000 * math.cos(angle) -- TODO: variable-ize constant
  local bulletDy = self.speed * 2000 * math.sin(angle)

  return startX, startY, bulletDx, bulletDy
end

function bullet:checkBulletReachDest(errorRange)
  return math.abs(self.x-self.destX) < errorRange and math.abs(self.y-self.destY) < errorRange
end

function bullet:checkBulletHitCreep(creepX, creepY, errorRange)
--  print(math.abs(self.x-creepX), math.abs(self.y-creepY), errorRange)
  return math.abs(self.x-creepX) < errorRange and math.abs(self.y-creepY) < errorRange
end
return bullet