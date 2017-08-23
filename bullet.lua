-- from https://love2d.org/wiki/Tutorial:Fire_Toward_Mouse

-- TO-DO: inherit some properties of the tower class?

local bullet = {}

bullet.damage = 1
bullet.speed = 1
bullet.x = 0
bullet.y = 0
bullet.destX = 0
bullet.destY = 0

function bullet:new(object)
  object = object or {damage = bullet.damage, speed = bullet.speed}
  
  object.destX = 0
  object.destY = 0
  object.x = 0
  object.y = 0
  
  setmetatable(object, self)
  self.__index = self
  return object
end

function bullet:update()
  
  
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
 
  local bulletDx = bullet.speed * 2000 * math.cos(angle) -- TODO: variable-ize constant
  local bulletDy = bullet.speed * 2000 * math.sin(angle)

 
 
  --moveSet = {}
  --table.insert(moveSet, {x = startX, y = startY, dx = bulletDx, dy = bulletDy})
 
  return startX, startY, bulletDx, bulletDy
  -- table.insert(bullets, {x = startX, y = startY, dx = bulletDx, dy = bulletDy})
end


return bullet