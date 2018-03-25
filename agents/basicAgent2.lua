-- basic agent 2 is just like basic agent 1
-- except basic agent 2 cares about the cost of things

basicAgent2 = class {
  init = function(self)
    
    self.name = "Hashtag Basic 2"
    self.buildNextX = 2
    self.buildNextY = 7
    self.timer = 0
    
    self.creepCosts = {}
    self.towerCosts = {}
    
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

function basicAgent2:update()
  if next(self.creepCosts) == nil or next(self.towerCosts) == nil then
    self:setCreepCosts()
    self:setTowerCosts()
  end
  
  if self.timer >= 100 then
    self:generateCreep()
    self:generateTower()
    self.timer = 0
  else
    self.timer = self.timer + 1
  end
end

function basicAgent2:generateCreep()
  creepID = self:getBestPurchase(self.creepCosts)
  if creepID ~= -1 then
    game.player2:generateCreep(creepID, game.dt)
  end
end

function basicAgent2:generateTower()
  towerID = self:getBestPurchase(self.towerCosts)
  if towerID ~= -1 then
    game.player2:checkMoveValidity(self.buildNextX, self.buildNextY, towerID)
    self:setNextCoord()
  end
end

function basicAgent2:setNextCoord()
  self.buildOrderIndex = self.buildOrderIndex + 1
  if self.buildOrder[self.buildOrderIndex] then
    self.buildNextX = self.buildOrder[self.buildOrderIndex][1]
  self.buildNextY = self.buildOrder[self.buildOrderIndex][2]
  end
end

function basicAgent2:setCreepCosts()
  for i, creep in ipairs(model.creeps) do
    self.creepCosts[creep.creepID] = creep.cost
  end
end

function basicAgent2:setTowerCosts()
  for i, tower in ipairs(model.towers) do
    self.towerCosts[tower.towerID] = tower.cost
  end
end

--input a table with ID key and cost values, 
--return the ID with the highest cost that the player can pay for
-- -1 if there is nothing in the list that the player can pay for
function basicAgent2:getBestPurchase(costTable)
  highestCost = 0
  highestCostID = -1
  currentCurrency = game.player2.currency
  for id, cost in ipairs(costTable) do
    if cost > highestCost and cost <= currentCurrency then
      highestCost = cost
      highestCostID = id
    end
  end
  return highestCostID
end

return basicAgent2