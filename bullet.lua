-- from https://love2d.org/wiki/Tutorial:Fire_Toward_Mouse

-- TO-DO: inherit some properties of the tower class?

local bullet = {}
local bullets = {}  -- can you have a static reference too?

bullet.damage = 1
bullet.speed = 1
bullet.x = 0
bullet.y = 0

function bullet:new(object)
  object = object or {damage = object.damage, speed = object.speed}
  setmetatable(object, self)
  self.__index = self
  return object
end

function bullet:update()
  
  
end

function bullet:computeTrajectory(startX, startY, endX, endY)
	if button == 1 then
 
		local angle = math.atan2((endY - startY), (endX - startX))
 
		local bulletDx = bulletSpeed * math.cos(angle)
		local bulletDy = bulletSpeed * math.sin(angle)
 
		table.insert(bullets, {x = startX, y = startY, dx = bulletDx, dy = bulletDy})
	end
end