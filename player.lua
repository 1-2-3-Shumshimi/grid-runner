player = class {
  
  init = function(self, playerNum, name)
    
    self.playerNum = playerNum
    self.name = name
    self.HP = 50
    self.currency = 0
    self.income = 5
    
    self.towers = {}
    self.bullets = {}
    self.enemyCreeps = {}
    
  end
}

function player:hasLost()
  return self.HP <= 0
end

--returns true if currency has been successfully spent
function player:spendMoney(amount)
  if amount <= self.currency then
    self.currency = self.currency - amount
    return true
  end
  return false
end

function player:boostIncome(amount)
  self.income = self.income + amount
end

function player:takeIncome()
  self.currency = self.currency + self.income
end

function player:update(dt)
  
end