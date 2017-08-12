local button = {}

    button.hit = nil
    button.isOff = false
    button.text = nil
    button.image = nil
    button.cooldown = 75
    button.cooldownTimer = 0
    button.x = 0
    button.y = 0
    button.width = 0
    button.height = 0
    
    function button:new(object)
      object = object or {cooldown = button.cooldown}
      object.isOff = button.isOff
      object.cooldownTimer = button.cooldownTimer
      
      setmetatable(object, self)
      self.__index = self
      return object
    end
    
    -- assign a text value to the button
    function button:setText(text)
      self.text = text
    end
    
    function button:setCoord(x, y)
      self.x = x
      self.y = y
    end
    
    function button:setSize(width, height)
      self.width = width
      self.height = height
    end
    
    -- assign a image value to the button
    function button:setImage(image)
      self.image = image
    end
    
    -- assign a function to the button's hit variable
    function button:setHit(func)
      self.hit = func
    end
    
    -- start the buffer time between button hits
    function button:restartCooldown()
      self.isOff = true
      self.cooldownTimer = 0
    end
    
    function button:draw()
      scaleX = self.width / self.image:getWidth()
      scaleY = self.height / self.image:getHeight()
      love.graphics.draw(self.image, self.x, self.y, 0, scaleX, scaleY)
    end

return button