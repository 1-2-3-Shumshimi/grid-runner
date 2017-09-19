top = 1
bottom = 0

player = class {
  init = function(self, topOrBottom, gameMap, HP, currency, name, towerSkin, creepSkin, defenseRating)
    
    self.status = topOrBottom -- 1 = top, 0 = bottom half of gameboard
    self.setBase(topOrBottom)
    
    self.HP = HP  -- TODO: determine standard (HP = 100?)
    self.name = name
    self.towerSkin = towerSkin --TODO: implement
    self.creepSkin = creepSkin --TODO: implement
    self.currency = currency
    self.defenseRating = defenseRating -- resistance to creep damage
    
    
    -- game map generation
    self.attackMap = {}
    self.generateAttackMap(gameMap)
    
    -- each player has its own pathfinder
    self.finder = pathfinder(game.cells, 'ASTAR', game.walkable)
    --set initial path
    
    self.path = self.finder:getPath(self.creepSpawnSiteX, self.creepSpawnSiteY, self.enemyX, self.enemyY, false)
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
  
  function player:generateAttackMap(gameMap)
    -- copies game.map, but marks half the map as unwalkable
    -- done this way for flexibility - in case creeps would be allowed to traverse any part of map
    
    -- map population if player is on top half of screen
    if self.status == top then
      for j=1,game.gridHeight do
        self.attackMap[j] = {}
        if j <= (game.gridHeight/2) then
          for i=1,game.gridWidth do
            game.map[j][i] = game.blocked
          end
        else
          for i=1,game.gridWidth do
            game.map[j][i] = game.walkable
          end
        end
      end
    
    -- map population if player is on bottom half of screen
    elseif self.status == bottom then
      for j=1,game.gridHeight do
        self.attackMap[j] = {}
        if j <= (game.gridHeight/2) then
          for i=1,game.gridWidth do
            game.map[j][i] = game.walkable
          end
        else
          for i=1,game.gridWidth do
            game.map[j][i] = game.blocked
          end
        end
      end      
    end
    
    
  end
  
  function player:setBase(status)
    if status == top then
      self.playerX = game.playerTopX
      self.playerY = game.playerTopY
      self.enemyX = game.playerBottomX
      self.enemyY = game.playerBottomY
      
      -- set up spawn site for creeps (on enemy player's half of board, aligned with player base
      self.creepSpawnSiteX = self.playerX+6
      self.creepSpawnSiteY = self.playerY
      
    elseif status == bottom then
      self.playerX = game.playerBottomX
      self.playerY = game.playerBottomY
      self.enemyX = game.playerTopX
      self.enemyY = game.playerTopY
      self.creepSpawnSiteX = self.playerX-6
      self.creepSpawnSiteY = self.playerY
    end
  end
  
