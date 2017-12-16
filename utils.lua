local utils = {}

-- Collision detection taken function from http://love2d.org/wiki/BoundingBox.lua
-- Returns true if two boxes overlap, false if they don't
-- x1,y1 are the left-top coords of the first box, while w1,h1 are its width and height
-- x2,y2,w2 & h2 are the same, but for the second box
function utils.checkCollision(x1,y1,w1,h1, x2,y2,w2,h2)
  return x1 < x2+w2 and
  x2 < x1+w1 and
  y1 < y2+h2 and
  y2 < y1+h1
end

-- Uses the Euclidean algorithm to find the greatest common factor
-- Arguments are order; largeN is greater than smallN
function utils.findGCF(largeN, smallN)
  while (smallN ~= 0) do
    temp = smallN
    smallN = largeN % smallN
    largeN = temp
  end
  return largeN
end

-- Convert x and y coordinates into grid position
function utils.coordToCell(x, y, cellSize)
  return math.floor(x / cellSize) + 1, math.floor(y / cellSize) + 1
end

-- Convert coordinates relative to grid into the x, y coordinates of
-- the cell's top-left corner
function utils.cellToCoord(cellX, cellY, cellSize)
  return (cellX - 1) * cellSize, (cellY - 1) * cellSize
end

-- Computes euclidean distance between 2D points
function utils.dist(x1,y1, x2,y2) return ((x2-x1)^2+(y2-y1)^2)^0.5 end

-- Taken from http://www.lua.org/pil/20.4.html
-- Given a string input, a table with the comma separated elements is returned
function utils.fromCSV (s)
  s = s .. ','        -- ending comma
  local t = {}        -- table to collect fields
  local fieldstart = 1
  repeat
    -- next field is quoted? (start with '"'?)
    if string.find(s, '^"', fieldstart) then
      local a, c
      local i  = fieldstart
      repeat
        -- find closing quote
        a, i, c = string.find(s, '"("?)', i+1)
      until c ~= '"'    -- quote not followed by quote?
      if not i then error('unmatched "') end
      local f = string.sub(s, fieldstart+1, i-1)
      table.insert(t, (string.gsub(f, '""', '"')))
      fieldstart = string.find(s, ',', i) + 1
    else                -- unquoted; find next comma
      local nexti = string.find(s, ',', fieldstart)
      table.insert(t, string.sub(s, fieldstart, nexti-1))
      fieldstart = nexti + 1
    end
  until fieldstart > string.len(s)
  return t
end

-- Given a table, return a table with the order of its contents reversed
function utils.reverseTable (t)
  local i, j = 1, #t
  local ret = {}
  
  while i < j do
    ret[i], ret[j] = t[j], t[i]
    i = i + 1
    j = j - 1
  end
  
  return ret
  
end

return utils