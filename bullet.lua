-- from https://love2d.org/wiki/Tutorial:Fire_Toward_Mouse

bullets = {}
towerHitList = {}  -- map tower to # of creeps currently engaged

function computeTrajectory(startX, startY, endX, endY)
	if button == 1 then
 
		local angle = math.atan2((endY - startY), (endX - startX))
 
		local bulletDx = bulletSpeed * math.cos(angle)
		local bulletDy = bulletSpeed * math.sin(angle)
 
		table.insert(bullets, {x = startX, y = startY, dx = bulletDx, dy = bulletDy})
	end
end