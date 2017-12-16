toggle = class {
  init = function(self, cooldown)
    self.leftStateChange = nil
    self.leftTextBox = nil
    self.rightStateChange = nil
    self.rightTextBox = nil
    self.cooldown = cooldown
    self.cooldownTimer = 0
    self.currentState = toggle.left
  end
}

toggle.left = 0
toggle.right = 1

  -- assign text values to the toggle
  function toggle:setText(leftString, rightString)
    self.leftTextBox = textbox(leftString, "", 0, 0, 20)
    self.rightTextBox = textbox(rightString, "", 0, 0, 20)
    
    self.leftTextBox:setOutlineColor(255, 255, 255)
    self.rightTextBox:setOutlineColor(255, 255, 255)
  end
    
  function toggle:setCoord(leftX, leftY, rightX, rightY)
    self.leftTextBox:setCoord(leftX, leftY)
    self.rightTextBox:setCoord(rightX, rightY)
  end
    
  -- assign a function to the toggle's state change variables
  function toggle:setStateChanges(leftFunc, rightFunc)
    self.leftStateChange = leftFunc
    self.rightStateChange = rightFunc
  end
    
  function toggle:onToggle(mouseX, mouseY)
    if self.leftTextBox:onTextbox(mouseX, mouseY) then
      return toggle.left
    elseif self.rightTextBox:onTextbox(mouseX, mouseY) then
      return toggle.right
    else
      return -1
    end
  end
    
  -- start the buffer time between toggle hits
  function toggle:restartCooldown()
    self.isOff = true
    self.cooldownTimer = 0
  end
    
  function toggle:setState(state)
    self.currentState = state
  end
  
  function toggle:setAlignment(alignString)
    self.leftTextBox:setAlignment(alignString)
    self.rightTextBox:setAlignment(alignString)
  end
  
  function toggle:draw()
    if self.currentState == toggle.left then
      self.leftTextBox:setBoxColor(255, 255, 255)
      self.leftTextBox:setTextColor(0, 0, 0)
      self.rightTextBox:setBoxColor(0, 0, 0)
      self.rightTextBox:setTextColor(255, 255, 255)
      
      love.graphics.setColor(0, 0, 0)
      love.graphics.line(self.leftTextBox.x, self.leftTextBox.y + self.leftTextBox.height, 
        self.leftTextBox.x + self.leftTextBox.width, self.leftTextBox.y + self.leftTextBox.height)
      
    elseif self.currentState == toggle.right then
      self.leftTextBox:setBoxColor(0, 0, 0)
      self.leftTextBox:setTextColor(255, 255, 255)
      self.rightTextBox:setBoxColor(255, 255, 255)
      self.rightTextBox:setTextColor(0, 0, 0)
      
      love.graphics.setColor(0, 0, 0)
      love.graphics.line(self.rightTextBox.x, self.rightTextBox.y + self.rightTextBox.height, 
        self.rightTextBox.x + self.rightTextBox.width, self.rightTextBox.y + self.rightTextBox.height)
      
    else
      print("State error in drawing the toggle button")
  
    end
    self.leftTextBox:draw()
    self.rightTextBox:draw()
    
  end

return toggle