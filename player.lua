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
    self.enemyCreepLocations = {}
    
    -- local copies of paths in the game
    self.map = game.player1Map
    self.myPath = nil
    self.enemyPath = nil
    
    self.playerActionFlag = false
    self.noCreepInCell= true
    
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
  
  function player:setBase(status)
    if status == top then
      self.playerX = game.playerTopX
      self.playerY = game.playerTopY
      self.enemyX = game.playerBottomX
      self.enemyY = game.playerBottomY
      
      -- set up spawn site for enemy creeps (on player's half of board, aligned with enemy base
      self.enemySpawnSiteX = self.enemyX   -- TODO: define constant
      self.enemySpawnSiteY = self.enemyY - 6
      
    elseif status == bottom then
      self.playerX = game.playerBottomX
      self.playerY = game.playerBottomY
      self.enemyX = game.playerTopX
      self.enemyY = game.playerTopY
      
      self.enemySpawnSiteX = self.enemyX  -- TODO: define constant
      self.enemySpawnSiteY = self.enemyY + 6
    end
  end
  
  function player:refreshMapAndPaths()
    
    if self.status == top then
      self.map = game.player1Map
      self.myPath = game.player1Path
      self.enemyPath = game.player2Path
    elseif self.status == bottom then
      self.map = game.player2Map
      self.myPath = game.player2Path
      self.enemyPath = game.player1Path
    end
    
  end
  
  function player:update(dt)
    
    if self.playerActionFlag then
      self:refreshMapAndPaths()
      self.playerActionFlag = false
    end
    
     --(1/3) check for bullet collisions with enemy creeps or target destinations
    for i, bulletN in ipairs(self.playerBullets) do
      for j, creep in ipairs(self.enemyCreeps) do
        if bulletN:checkBulletHitCreep(creep.x, creep.y, game.cellSize) then
          -- damage creep health + remove bullet from list
          print("creep", i, "takes damage; HP left: ", creep.HP)
          creep:takeDamage(bulletN.damage)
          table.remove(self.playerBullets, i)
        elseif bulletN:checkBulletReachDest(game.cellSize) then
          table.remove(self.playerBullets, i)
        end
      end
    end
    
    --(2/3) update enemy creep movement
    for i, creep in ipairs(self.enemyCreeps) do
      if creep:update(self.myPath) then
        table.insert(self.enemyCreepLocations, {utils.coordToCell(creep.x, creep.y, game.cellSize)})
      else
        --1st revert path: when a creep is trapped
        self:revertPath()
        self:refreshCreeps()
        break
      end
    end
    
    -- (3/3) determine whether any creeps will be attacked by towers--
    for i, tower in ipairs(self.playerTowers) do
      if not tower:isBusy() then
        if not tower.hasFired then
          self:determineCreepsInRange(tower)
        elseif tower.lastFired >= tower.attackSpeed then
          self:determineCreepsInRange(tower)
        end
      
      -- reset attack occupancy of tower after setting targets -- 
      tower:resetOccupancy()
      tower.lastFired = tower.lastFired + 0.05  -- TODO: variable-ize this constant
      end
    end
    
    self:refreshCreeps()
    
  end
  
  function player:draw(dt)
    
    -- draw towers--
    for i, tower in ipairs(self.playerTowers) do
      tower:draw()
    end
    
    -- draw enemy creeps--
    for i, creep in ipairs(self.enemyCreeps) do
      creep:draw()
    end
    
    -- draw bullets --
    love.graphics.setColor(255, 50, 50)
    
    for i=#self.playerBullets,1,-1 do
      bulletN = self.playerBullets[i]
      startX, startY, bulletDx, bulletDy = bulletN:computeTrajectory(bulletN.x, bulletN.y, bulletN.destX, bulletN.destY)

      deltaTime = love.timer.getDelta()
      bulletN:setCoord(startX + bulletDx * deltaTime, startY + bulletDy* deltaTime)
     
      love.graphics.circle("fill", bulletN.x, bulletN.y, game.cellSize/10)
    end
  end
  
  function player:generateTower(cellX, cellY)
    towerN = tower(2,2,2,1,2)
    towerN:setCoord(cellX, cellY)
    towerN:setSpriteSheet(love.graphics.newImage(game.towerImageURLs[1]))
    table.insert(self.playerTowers, towerN)
  end
  
  function player:removeTower(cellX, cellY)
    for i, tower in ipairs(self.playerTowers) do
      if tower.x == cellX and tower.y == cellY then
        table.remove(self.playerTowers, i)
      end
    end
  end
  
  function player:determineCreepsInRange(tower)
    local x = tower.x
    local y = tower.y
  
    for i, creep in ipairs(self.enemyCreeps) do
      if tower:isBusy() then
        print("tower is busy")
        break
      end
    
      local creepX = creep.x
      local creepY = creep.y
    
      -- convert creep coordinates to grid cell coordinates
      creepCellX, creepCellY = utils.coordToCell(creepX, creepY, game.cellSize)
    
      local distToTower = utils.dist(x,y,creepCellX,creepCellY)
    
      if distToTower <= tower.range then      
        self:generateBullet(tower.coordX + tower.width/2, tower.coordY + tower.height/2, creep.x, creep.y)
        tower:updateDirection(creep.x, creep.y)
        tower:incrementOccupancy()
        tower.hasFired = true
        tower.lastFired = 0
      end
    end
  end

  function player:generateBullet(towerX, towerY, destX, destY)

    bulletN = bullet(50,1)
    
    bulletN:setOrigin(towerX, towerY)
    bulletN:setCourse(destX, destY)
    
    -- insert into bullet list -- 
    table.insert(self.playerBullets, bulletN)
    
  end

  function player:generateCreep(creepSpriteSheet, dt)
    
    --insert creep to the OPPOSING player's enemyCreeps table
    --thus, assign the creep the OPPOSING player path to follow
    if self.status == top then
      newCreep = creep(math.random(1,5)*100, 0.5, 1, creepSpriteSheet, game.player2Path, bottom)
      newCreepCoordX, newCreepCoordY = utils.cellToCoord(game.bottomEnemySpawnX, game.bottomEnemySpawnY, game.cellSize)
      newCreep:setCoord(newCreepCoordX + game.cellSize/4, newCreepCoordY)
      table.insert(game.player2.enemyCreeps, newCreep)
      
  elseif self.status == bottom then
      newCreep = creep(math.random(1,5)*100, 0.5, 1, creepSpriteSheet, game.player1Path, top)
      newCreepCoordX, newCreepCoordY = utils.cellToCoord(game.topEnemySpawnX, game.topEnemySpawnY, game.cellSize)
      newCreep:setCoord(newCreepCoordX + game.cellSize/4, newCreepCoordY)
      table.insert(game.player1.enemyCreeps, newCreep)
    
    else
      print("Something went wrong with player status/topOrBottom")
    end
  end
  
  function player:refreshCreeps()
    game.creepUpdated = true
    self.enemyCreepLocations = {}
    for i=#self.enemyCreeps, 1, -1 do
      if self.enemyCreeps[i]:isDead() then
        self.currency = self.currency + self.enemyCreeps[i].bounty
        table.remove(self.enemyCreeps, i)
        print("currency for player "..self.status.." is "..self.currency)
      elseif self.enemyCreeps[i].atEnd then
        self.HP = self.HP - 1
        table.remove(self.enemyCreeps, i)
        print("hp for player "..self.status.." is "..self.HP)
      end
      
--      game.updateScore(self.enemyCreeps[i]) --jonathan: making score updates player-side
        
    end
  end
  
  function player:checkMoveValidity(cellX, cellY)
    --check if last cell
    isLastCell = (cellX == game.bottomEnemySpawnX and cellY == game.bottomEnemySpawnY) or 
                 (cellX == game.topEnemySpawnX and cellY == game.topEnemySpawnY)
    
    for i, coord in ipairs(self.enemyCreepLocations) do
      if cellX == coord[1] and cellY == coord[2] then
        self.noCreepInCell = false
      end
    end
    if self.noCreepInCell and not isLastCell then
      --notice cellX and cellY are flipped to coincide with the pathfinder module
      if self.map[cellY][cellX] == game.walkable then
        self:updateCellStatus(cellX, cellY, game.blocked)
        print("generating tower (", cellX, cellY, ")")
        self:generateTower(cellX, cellY)
      elseif self.map[cellY][cellX] == game.blocked then
        self:updateCellStatus(cellX, cellY, game.walkable)
        self:removeTower(cellX, cellY)
        print("removing tower (", cellX, cellY, ")")
      elseif self.map[cellY][cellX] == game.oppSide then
        print("you cannot build on opponent side!")
      end
      game.prevCellX, game.prevCellY = cellX, cellY --set the revert path mechanism
      game.mouseDisableCounter = 0
      game.mouseDisabled = true
      
      self:updatePathStatus()
      if not game.player1Path or not game.player2Path then
        --2nd revert path: where the game path (from spawn point to base point) has been blocked
        self:revertPath()
      end
      
      --trigger map and path refresh next game update iteration
      self.playerActionFlag = true
      
    end
  end
  
  function player:revertPath()
    self:updateCellStatus(game.prevCellX, game.prevCellY, game.walkable)
    self:removeTower(game.prevCellX, game.prevCellY)
    print("Can't build blocking path")
    self:updatePathStatus()
  end
  
  function player:updateCellStatus(cellX, cellY, status)
    if self.status == top then
      game.player1Map[cellY][cellX] = status
    elseif self.status == bottom then
      game.player2Map[cellY][cellX] = status
    end
  end
  
  function player:updatePathStatus()
    if self.status == top then
      game.player1Path = game.player1Finder:getPath(self.enemySpawnSiteX, self.enemySpawnSiteY, self.playerX, self.playerY, false)
    elseif self.status == bottom then
      game.player2Path = game.player2Finder:getPath(self.enemySpawnSiteX, self.enemySpawnSiteY, self.playerX, self.playerY, false)
    end
  end
  
return player
  
