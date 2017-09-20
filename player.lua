top = 1
bottom = 0

player = class {
  init = function(self, topOrBottom, gameMap, HP, currency, name, towerSkin, creepSkin, defenseRating)
    
    -- determine positions
    self.status = topOrBottom -- 1 = top, 0 = bottom half of gameboard
    self.playerX = nil
    self.playerY = nil
    self.enemyX = nil
    self.enemyY = nil
    self.enemySpawnSiteX = nil
    self.enemySpawnSiteY = nil
    self:setBase(topOrBottom)
    
    self.HP = HP  -- TODO: determine standard (HP = 100?)
    self.name = name
    self.towerSkin = towerSkin --TODO: implement
    self.creepSkin = creepSkin --TODO: implement
    self.currency = currency
    self.defenseRating = defenseRating -- resistance to creep damage
    
    -- lists of objects
    self.playerTowers = {}
    self.playerBullets = {}
    self.enemyCreeps = {} -- keep track of enemy's creeps on player's turf
    
    -- game map generation
    self.attackMap = {}
    self.generateAttackMap(gameMap)
    
    -- each player has its own pathfinder
    self.finder = pathfinder(game.cells, 'ASTAR', game.walkable)
    self.finder:setMode('ORTHOGONAL')
    
    --set initial path of enemy creeps to player's base
    self.path = self.finder:getPath(self.enemySpawnSiteX, self.enemySpawnSiteY, self.playerX, self.playerY, false)
    
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
      
      -- set up spawn site for enemy creeps (on player's half of board, aligned with enemy base
      self.enemySpawnSiteX = self.enemyX - 6   -- TODO: define constant
      self.enemySpawnSiteY = self.enemyY
      
    elseif status == bottom then
      self.playerX = game.playerBottomX
      self.playerY = game.playerBottomY
      self.enemyX = game.playerTopX
      self.enemyY = game.playerTopY
      
      self.enemySpawnSiteX = self.enemyX + 6  -- TODO: define constant
      self.enemySpawnSiteY = self.enemyY
    end
  end
  
  function player:update(dt)
    
     --check for bullet collisions with enemy creeps or target destinations
    for i, bulletN in ipairs(self.playerBullets) do
      for j, creep in ipairs(self.enemyCreeps) do
        if bulletN:checkBulletHitCreep(creep.x, creep.y, game.cellSize) then
          -- damage creep health + remove bullet from list
          print("creep", i, "takes damage; HP left: ", creep.HP)
          creep:takeDamage(bulletN.damage)
          if creep:isDead() then
            table.remove(self.enemyCreeps, j)
          end
          table.remove(self.playerBullets, i)
        elseif bulletN:checkBulletReachDest(game.cellSize) then
          table.remove(self.playerBullets, i)
        end
      end
    end
    
    --update enemy creep movement
    for i, creep in ipairs(self.enemyCreeps) do
      if creep:update(game.path) then
        table.insert(game.creepLocations, {utils.coordToCell(creep.x, creep.y, game.cellSize)})
      else
        game.revertPath()   -- TODO: turn into player functions
        game.refreshCreeps()  -- TODO: turn into player functions
        break
      end
    end
  end
  
  
return player
  
