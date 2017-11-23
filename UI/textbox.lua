textbox = class {
  init = function(self, baseString, extraString, x, y)
    self.baseString = baseString
    self.extraString = extraString
    self.x = x
    self.y = y
  end
}

  function textbox:setExtraString(string)
    self.extraString = string
  end
  
  function textbox:setCoord(x, y)
    self.x = x
    self.y = y
  end
  
  function textbox:draw()
    love.graphics.print(self.baseString..self.extraString, self.x, self.y)
  end
  
return textbox