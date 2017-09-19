player = class {
  init = function(self, HP, currency, name, towerSkin, creepSkin, defenseRating)
    self.HP = HP  -- TODO: determine standard (HP = 100?)
    self.name = name
    self.towerSkin = towerSkin --TODO: implement
    self.creepSkin = creepSkin --TODO: implement
    self.currency = currency
    self.defenseRating = defenseRating -- resistance to creep damage
  end
 }
  function player:hasLost()
    return self.HP <= 0
  end
  
  function player:spendMoney(amount)
    self.currency = self.currency - amount
    if self.currency < 0 then
      --reject purchase--
      return false
    end
    return true
  end
  
  function player:toString()
    return "Player "..self.name..", HP = "..self.HP..", Currency = "..self.currency
  end
  
  function player:generateID()
    -- TODO: randomly generate ID for easier comparison (e.g. ID'ing creeps and towers)
  end
  
