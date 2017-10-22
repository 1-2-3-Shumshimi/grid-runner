basicAgent = class {
  init = function(self)
    
    self.name = "Hashtag Basic"
    self.buildNextX = 2
    self.buildNextY = 7
    self.timer = 0
    
    self.buildOrder = {
      {15, 12}, {15, 11}, {15, 10}, {15, 9},
      {16, 7}, {15, 7}, {14, 7}, {13, 7},
      {13, 8}, {13, 9}, {13, 10}, {13, 11},
      {11, 12}, {11, 11}, {11, 10}, {11, 9},
      {12, 7}, {11, 7}, {10, 7}, {9, 7},
      {9, 8}, {9, 9}, {9, 10}, {9, 11}      
    }
    self.buildOrderIndex = 0
    
  end
}

function basicAgent:update()
  if self.timer >= 500 then
    self:generateCreep()
    self:generateTower()
    self:setNextCoord()
    self.timer = 0
  else
    self.timer = self.timer + 1
  end
end

function basicAgent:generateCreep()
  game.player2:generateCreep(love.graphics.newImage("assets/bmg1.png"), game.dt)
end

function basicAgent:generateTower()
  --(Jonthan TODO) write a sligtly modified version of this function 
  -- (i.e. mouseDisabled handler is shared between players right now
  game.player2:checkMoveValidity(self.buildNextX, self.buildNextY)
end

function basicAgent:setNextCoord()
  self.buildOrderIndex = self.buildOrderIndex + 1
  if self.buildOrder[self.buildOrderIndex] then
    self.buildNextX = self.buildOrder[self.buildOrderIndex][1]
  self.buildNextY = self.buildOrder[self.buildOrderIndex][2]
  end
end

return basicAgent