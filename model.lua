local model = {
  
  towers = {}, towerFields = {},
  creeps = {}, creepFields = {},
  bullets = {}, bulletFields = {}
    
}

-- sets the keys for the towers table
function model:setTowerFields(inputTowerModel)
  self.towerFields = inputTowerModel
end

-- taking in a table that has been processed from a csv file,
-- assigns key value pairs of the attributes for each tower
function model:setTowerRows(inputTowerRow)
  --towerID, name, attackSpeed, damage, range, attackCapacity, size - current model
  if #self.towerFields == #inputTowerRow then --same number of fields
    towerRow = {}
    for i, field in ipairs(self.towerFields) do
      inputTowerNumber = tonumber(inputTowerRow[i]) --convert values to numbers if you can
      if inputTowerNumber ~= nil then
        towerRow[field] = inputTowerNumber
      else
        towerRow[field] = inputTowerRow[i]
      end
    end
    table.insert(self.towers, towerRow)
  else
    print("number tower fields and input tower row does not match")
  end
end

-- prints a string representation of towers model
function model:printTowers()
  for i, row in ipairs(self.towers) do
    tempString = ""
    for key, value in next, row do
      tempString = tempString..key..": "..value..", "
    end
    print(string.sub(tempString, 1, -3)) --cut off trailing comma and space
  end
end

-- sets the keys for the creeps table
function model:setCreepFields(inputCreepModel)
  self.creepFields = inputCreepModel
end

-- taking in a table that has been processed from a csv file,
-- assigns key value pairs of the attributes for each creep
function model:setCreepRows(inputCreepRow)
  --creepID, name, HP, speed, bounty - current model
  if #self.creepFields == #inputCreepRow then --same number of fields
    creepRow = {}
    for i, field in ipairs(self.creepFields) do
      inputCreepNumber = tonumber(inputCreepRow[i]) --convert values to numbers if you can
      if inputCreepNumber ~= nil then
        creepRow[field] = inputCreepNumber
      else
        creepRow[field] = inputCreepRow[i]
      end
    end
    table.insert(self.creeps, creepRow)
  else
    print("number creep fields and input creep row does not match")
  end
end

-- prints a string representation of the creeps model
function model:printCreeps()
  for i, row in ipairs(self.creeps) do
    tempString = ""
    for key, value in next, row do
      tempString = tempString..key..": "..value..", "
    end
    print(string.sub(tempString, 1, -3)) --cut off trailing comma and space
  end
end

return model