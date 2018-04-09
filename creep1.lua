--creep class for "cheap creep"
--medium health, medium speed, low cost
BASE_HP = 10
BASE_SPEED = 5
BASE_COST = 5

creep1 = class { __includes = creep,
  init = function(self, playerOwner, upgradeHPLevel, upgradeSpeedLevel)
    
    --upgrade levels are 0-based indices
    
    -- HP: 10, 20, 40, 80, 160, 320, ...
    HP = BASE_HP * math.pow(2, upgradeHPLevel)
    -- Speed: 5, 7, 9, 11, 13, ...
    speed = BASE_SPEED + 2 * upgradeSpeedLevel
    -- Bounty: 5, 10, 15, 20, ...
    bounty = BASE_COST * (upgradeHPLevel + upgradeSpeedLevel + 1)
    -- Income boost: 1, 1, 1, 2, 2, 2, 3, 3, 3, ...
    incomeBoost = (BASE_COST / 5) * (math.floor((upgradeHPLevel + upgradeSpeedLevel) / 3) + 1)
    
    --creepID, HP, speed, shield, bounty, incomeBoost, playerOwner
    creep.init(1, HP, speed, 0, bounty, incomeBoost, playerOwner)
  end
}

