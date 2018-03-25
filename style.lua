--default styles

local styleDefault = {
  ['window'] = {
      ['spacing'] = {x = 0, y = 0},
      ['padding'] = {x = 0, y = 0},
      ['group padding'] = {x = 0, y = 0}
  }
  
}

local colors = {
  
  
}

return function ()
--  nk.styleLoadColors(colors)
  nk.stylePush(styleDefault)
  
  
end