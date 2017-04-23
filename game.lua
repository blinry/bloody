function parseWorld(filename)
    local legend = {}
    legend[" "] = "empty"
    legend["#"] = "vein"
    legend["^"] = "up"
    legend[">"] = "right"
    legend["v"] = "down"
    legend["<"] = "left"
    legend["@"] = "start"
    legend["H"] = "heart"
    legend["L"] = "lung"
    legend["B"] = "brain"

    level = {}
    level.veins = {}

    for i = 1,150 do
        level.veins[i] = {}

        for j = 1,150 do
            level.veins[i][j] = "empty"
        end
    end

    local f = love.filesystem.newFile(filename)
    f:open("r")

    local lineNr = 1

    for line in f:lines() do
        for i = 1, #line, 1 do
          local c = line:sub(i,i)
          level.veins[i][lineNr] = legend[c]
        end
        lineNr = lineNr+1
    end
end

function createCirclePath(x, y, radius, points, startangle, endangle)
  local path = {}

  local stepsize = (endangle - startangle) / (points-1)

  table.insert(path, {(x + math.cos(startangle) * radius), (y - math.sin(startangle) * radius)})

  for i = 1,(points-2) do
    table.insert(path, {(x+math.cos(startangle + i * stepsize)*radius), (y-math.sin(startangle+i*stepsize)*radius)})
  end

  table.insert(path, {(x + math.cos(endangle) * radius), (y - math.sin(endangle) * radius)})
  createPath(path)
end

function createLine(startx, starty, endx, endy)
  local path = {}

  table.insert(path, {startx, starty})
  table.insert(path, {endx, endy})
  createPath(path)
end

--function createSegment(symbol, x, y, tilesize, roundpoints)
--  local path = {}
--  if symbol == "empty" then
--  elseif symbol == "vertical" then
--    createLine((0.25+x) * tilesize, (0+y) * tilesize, (0.25+x) * tilesize, (1+y) * tilesize)
--    createLine((0.75+x) * tilesize, (0+y) * tilesize, (0.75+x) * tilesize, (1+y) * tilesize)
--
--  elseif symbol == "horizontal" then
--    createLine((0+x) * tilesize, (0.25+y) * tilesize, (1+x) * tilesize, (0.25+y) * tilesize)
--    createLine((0+x) * tilesize, (0.75+y) * tilesize, (1+x) * tilesize, (0.75+y) * tilesize)
--
--  elseif symbol == "top_right" then
--    createCirclePath((1+x)*tilesize, (0+y)*tilesize, 0.25*tilesize, 25, 1.0*math.pi, 1.5*math.pi)
--    createCirclePath((1+x)*tilesize, (0+y)*tilesize, 0.75*tilesize, 25, 1.0*math.pi, 1.5*math.pi)
--    
--  elseif symbol == "right_bottom" then
--    createCirclePath((1+x)*tilesize, (1+y)*tilesize, 0.25*tilesize, 25, 0.5*math.pi, 1.0*math.pi)
--    createCirclePath((1+x)*tilesize, (1+y)*tilesize, 0.75*tilesize, 25, 0.5*math.pi, 1.0*math.pi)
--    
--  elseif symbol == "bottom_left" then
--    createCirclePath((0+x)*tilesize, (1+y)*tilesize, 0.25*tilesize, 25, 0.0*math.pi, 0.5*math.pi)
--    createCirclePath((0+x)*tilesize, (1+y)*tilesize, 0.75*tilesize, 25, 0.0*math.pi, 0.5*math.pi)
--    
--  elseif symbol == "left_top" then
--    createCirclePath((0+x)*tilesize, (0+y)*tilesize, 0.25*tilesize, 25, 1.5*math.pi, 2.0*math.pi)
--    createCirclePath((0+x)*tilesize, (0+y)*tilesize, 0.75*tilesize, 25, 1.5*math.pi, 2.0*math.pi)
--
--  elseif symbol == "t-cross_top" then
--    createLine((0+x)*tilesize, (0.75+y)*tilesize, (1+x)*tilesize, (0.75+y)*tilesize)
--
--    createCirclePath((0+x)*tilesize, (0+y)*tilesize, 0.25*tilesize, 25, 1.5*math.pi, 2.0*math.pi)
--    createCirclePath((1+x)*tilesize, (0+y)*tilesize, 0.25*tilesize, 25, 1.0*math.pi, 1.5*math.pi)
--    
--  elseif symbol == "t-cross_right" then
--    createLine((0.25+x)*tilesize, (0+y)*tilesize, (0.25+x)*tilesize, (1+y)*tilesize)
--
--    createCirclePath((1+x)*tilesize, (0+y)*tilesize, 0.25*tilesize, 25, math.pi, 1.5*math.pi)
--    createCirclePath((1+x)*tilesize, (1+y)*tilesize, 0.25*tilesize, 25, 0.5*math.pi, math.pi)
--    
--  elseif symbol == "t-cross_bottom" then
--    createLine((0+x) * tilesize, (0.25+y) * tilesize, (1+x) * tilesize, (0.25+y) * tilesize)
--
--    createCirclePath((0+x)*tilesize, (1+y)*tilesize, 0.25*tilesize, 25, 0.0*math.pi, 0.5*math.pi)
--    createCirclePath((1+x)*tilesize, (1+y)*tilesize, 0.25*tilesize, 25, 0.5*math.pi, 1.0*math.pi)
--    
--  elseif symbol == "t-cross_left" then
--    createLine((0.75+x) * tilesize, (0+y) * tilesize, (0.75+x) * tilesize, (1+y) * tilesize)
--
--    createCirclePath((0+x)*tilesize, (0+y)*tilesize, 0.25*tilesize, 25, 1.5*math.pi, 2.0*math.pi)
--    createCirclePath((0+x)*tilesize, (1+y)*tilesize, 0.25*tilesize, 25, 0.0*math.pi, 0.5*math.pi)
--    
--  elseif symbol == "cross" then
--    createCirclePath((0+x)*tilesize, (0+y)*tilesize, 0.25*tilesize, 25, 1.5*math.pi, 2.0*math.pi)
--    createCirclePath((0+x)*tilesize, (1+y)*tilesize, 0.25*tilesize, 25, 0.0*math.pi, 0.5*math.pi)
--    createCirclePath((1+x)*tilesize, (0+y)*tilesize, 0.25*tilesize, 25, math.pi, 1.5*math.pi)
--    createCirclePath((1+x)*tilesize, (1+y)*tilesize, 0.25*tilesize, 25, 0.5*math.pi, math.pi)
--
--  elseif symbol == "heart" then
--    
--  elseif symbol == "lung" then
--    
--  elseif symbol == "brain" then
--    
--  end
--
--end

function wallipyTiles()
  for x = 2,150-1 do
    for y = 2,150-1 do

      if level.veins[x][y] == "start" then
          startX = (x+0.5)*tilesize
          startY = (y+0.5)*tilesize
      end

      if level.veins[x][y] == "lung" then
          for i = 1,50 do
              createThing((x+0.5)*tilesize+math.random(-tilesize/4,tilesize/4), (y+0.5)*tilesize+math.random(-tilesize/4,tilesize/4), "bubble")
          end
      end

      if level.veins[x][y] ~= "empty" then
          l = level.veins[x-1][y] ~= "empty"
          r = level.veins[x+1][y] ~= "empty"
          t = level.veins[x][y-1] ~= "empty"
          b = level.veins[x][y+1] ~= "empty"

          tl = level.veins[x-1][y-1] ~= "empty"
          tr = level.veins[x+1][y-1] ~= "empty"
          bl = level.veins[x-1][y+1] ~= "empty"
          br = level.veins[x+1][y+1] ~= "empty"

          if t and r and not tr then
              createCirclePath((1+x)*tilesize, (0+y)*tilesize, 0.25*tilesize, 25, 1.0*math.pi, 1.5*math.pi)
          end
          if r and b and not br then
              createCirclePath((1+x)*tilesize, (1+y)*tilesize, 0.25*tilesize, 25, 0.5*math.pi, 1.0*math.pi)
          end
          if b and l and not bl then
              createCirclePath((0+x)*tilesize, (1+y)*tilesize, 0.25*tilesize, 25, 0.0*math.pi, 0.5*math.pi)
          end
          if l and t and not tl then
              createCirclePath((0+x)*tilesize, (0+y)*tilesize, 0.25*tilesize, 25, 1.5*math.pi, 2.0*math.pi)
          end
          if t and b and not r then
              createLine((0.75+x) * tilesize, (0+y) * tilesize, (0.75+x) * tilesize, (1+y) * tilesize)
          end
          if t and b and not l then
              createLine((0.25+x)*tilesize, (0+y)*tilesize, (0.25+x)*tilesize, (1+y)*tilesize)
          end
          if r and l and not t then
              createLine((0+x) * tilesize, (0.25+y) * tilesize, (1+x) * tilesize, (0.25+y) * tilesize)
          end
          if r and l and not b then
              createLine((0+x)*tilesize, (0.75+y)*tilesize, (1+x)*tilesize, (0.75+y)*tilesize)
          end
          if not t and not r then
              createCirclePath((0+x)*tilesize, (1+y)*tilesize, 0.75*tilesize, 25, 0.0*math.pi, 0.5*math.pi)
          end
          if not r and not b then
              createCirclePath((0+x)*tilesize, (0+y)*tilesize, 0.75*tilesize, 25, 1.5*math.pi, 2.0*math.pi)
          end
          if not b and not l then
              createCirclePath((1+x)*tilesize, (0+y)*tilesize, 0.75*tilesize, 25, 1.0*math.pi, 1.5*math.pi)
          end
          if not l and not t then
              createCirclePath((1+x)*tilesize, (1+y)*tilesize, 0.75*tilesize, 25, 0.5*math.pi, 1.0*math.pi)
          end
          --createSegment( level.veins[x][y], x, y, tilesize )
      end

    end
  end
end

function getStream(x, y)
    local ff = 40000
    typ = level.veins[math.floor(x/tilesize)][math.floor(y/tilesize)]
    if typ == "up" then
        return 0, -ff
    elseif typ == "right" then
        return ff, 0
    elseif typ == "down" then
        return 0, ff
    elseif typ == "left" then
        return -ff, 0
    else
        return 0, 0
    end
end
