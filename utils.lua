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

return utils