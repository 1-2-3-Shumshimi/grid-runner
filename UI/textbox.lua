textbox = class {
  init = function(self, baseString, extraString, x, y, fontSize)
    self.baseString = baseString
    self.extraString = extraString
    self.x = x
    self.y = y
    self.font = love.graphics.newFont(16)
    self.width = self.font:getWidth(self.baseString..self.extraString)
    self.height = self.font:getHeight()
    self.outlineColor = nil
    self.boxColor = nil
    self.textColor = nil
    self.alignment = "left"
  end
}

  function textbox:setExtraString(string)
    self.extraString = string
    self.width = self.font:getWidth(self.baseString..self.extraString)
    self.height = self.font:getHeight()
  end
  
  function textbox:setCoord(x, y)
    self.x = x
    self.y = y
  end
  
  function textbox:setOutlineColor(r, g, b)
    self.outlineColor = {r, g, b}
  end
  
  function textbox:setBoxColor(r, g, b)
    self.boxColor = {r, g, b}
  end
  
  function textbox:setTextColor(r, g, b)
    self.textColor = {r, g, b}
  end
  
  function textbox:setAlignment(alignString)
    if alignString == "left" or alignString == "right" or alignString == "center" then
      self.alignment = alignString
    else
      print("invalid align string")
    end
  end
  
  function textbox:draw()
    if self.boxColor then
      love.graphics.setColor(self.boxColor[1], self.boxColor[2], self.boxColor[3])
      love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    end
    if self.outlineColor then
      love.graphics.setColor(self.outlineColor[1], self.outlineColor[2], self.outlineColor[3])
      love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    end
    if self.textColor then
      love.graphics.setColor(self.textColor[1], self.textColor[2], self.textColor[3])
    end
    love.graphics.printf(self.baseString..self.extraString, self.x, self.y + self.height / 5, self.width, self.alignment)
  end
  
  function textbox:onTextbox(mouseX, mouseY)
    return mouseX > self.x and mouseX < self.x + self.width and mouseY > self.y and mouseY < self.y + self.height
  end
  
return textbox