function parseWorld(filename)
    local legend = {}
    legend[" "] = "empty"

    legend["|"] = "vertical"
    legend["-"] = "horizontal"

    legend["t"] = "top_right"
    legend["r"] = "right_bottom"
    legend["b"] = "bottom_left"
    legend["l"] = "left_top"

    legend["^"] = "t-cross_top"
    legend[">"] = "t-cross_right"
    legend["v"] = "t-cross_bottom"
    legend["<"] = "t-cross_left"
    legend["+"] = "cross"

    legend["H"] = "heart"
    legend["L"] = "lung"
    legend["B"] = "brain"

    level = {}
    level.veins = {}
    level.name = string.match(string.match(filename, "[^/]+.txt"), "[^/.]+"):sub(4):gsub("_", " ")
    level.solved = false
    level.story = {}
    level.won = {}

    for i = 1,151 do
        level.veins[i] = {}

        for j = 1,151 do
            level.veins[i][j] = "empty"
        end
    end

    local f = love.filesystem.newFile(filename)
    f:open("r")

    local lineNr = 1
    local phase = 1

    for line in f:lines() do
        --local line = f:read()
        --if line == nil then noObjectList() end

        if phase == 1 then
            if line == "---" then
                phase = 2
            else
                for i = 1, #line, 1 do
                  local c = line:sub(i,i)
                  level.veins[i][lineNr] = legend[c]
                end
                lineNr = lineNr+1
            end
        elseif phase == 2 then
            if line == "---" or line == nil  then
                phase = 3
            else
            -- feel free to add stuff <3
            end
        elseif phase == 3 then
           if line == nil or line == "---" then
               phase = 4
           else
           end
        elseif phase == 4 then
           if line == nil or line == "---" then
               break
           else
           end
        end
    end
end

function createCirclePath(x, y, radius, points, startangle, endangle)
  local path = {}

  local stepsize = (endangle - startangle) / (points-1)

  table.insert(path, {(x + math.cos(startangle) * radius), (y + math.sin(startangle) * radius)})

  for i = 1,(points-2) do
    table.insert(path, {(x+math.cos(startangle + i * stepsize)*radius), (y+math.sin(startangle+i*stepsize)*radius)})
  end

  table.insert(path, {(x + math.cos(endangle) * radius), (y + math.sin(endangle) * radius)})
  createPath(path)
end

function createLine(startx, starty, endx, endy)
  local path = {}

  table.insert(path, {startx, starty})
  table.insert(path, {endx, endy})
  createPath(path)
end

function createSegment(symbol, x, y, tilesize, roundpoints)
  local path = {}
  if symbol == "empty" then
  elseif symbol == "vertical" then
    createLine((0.25+x) * tilesize, (0+y) * tilesize, (0.25+x) * tilesize, (1+y) * tilesize)
    createLine((0.75+x) * tilesize, (0+y) * tilesize, (0.75+x) * tilesize, (1+y) * tilesize)

  elseif symbol == "horizontal" then
    createLine((0+x) * tilesize, (0.25+y) * tilesize, (1+x) * tilesize, (0.25+y) * tilesize)
    createLine((0+x) * tilesize, (0.75+y) * tilesize, (1+x) * tilesize, (0.75+y) * tilesize)

  elseif symbol == "top_right" then
    createCirclePath((1+x)*tilesize, (0+y)*tilesize, 0.25*tilesize, 25, 1.0*math.pi, 1.5*math.pi)
    createCirclePath((1+x)*tilesize, (0+y)*tilesize, 0.75*tilesize, 25, 1.0*math.pi, 1.5*math.pi)
    
  elseif symbol == "right_bottom" then
    createCirclePath((1+x)*tilesize, (1+y)*tilesize, 0.25*tilesize, 25, 0.5*math.pi, 1.0*math.pi)
    createCirclePath((1+x)*tilesize, (1+y)*tilesize, 0.75*tilesize, 25, 0.5*math.pi, 1.0*math.pi)
    
  elseif symbol == "bottom_left" then
    createCirclePath((0+x)*tilesize, (1+y)*tilesize, 0.25*tilesize, 25, 0.0*math.pi, 0.5*math.pi)
    createCirclePath((0+x)*tilesize, (1+y)*tilesize, 0.75*tilesize, 25, 0.0*math.pi, 0.5*math.pi)
    
  elseif symbol == "left_top" then
    createCirclePath((0+x)*tilesize, (0+y)*tilesize, 0.25*tilesize, 25, 1.5*math.pi, 2.0*math.pi)
    createCirclePath((0+x)*tilesize, (0+y)*tilesize, 0.75*tilesize, 25, 1.5*math.pi, 2.0*math.pi)

  elseif symbol == "t-cross_top" then
    createLine((0+x)*tilesize, (0.75+y)*tilesize, (1+x)*tilesize, (0.75+y)*tilesize)

    createCirclePath((0+x)*tilesize, (0+y)*tilesize, 0.25*tilesize, 25, 1.5*math.pi, 2.0*math.pi)
    createCirclePath((1+x)*tilesize, (0+y)*tilesize, 0.25*tilesize, 25, 1.0*math.pi, 1.5*math.pi)
    
  elseif symbol == "t-cross_right" then
    createLine((0.25+x)*tilesize, (0+y)*tilesize, (0.25+x)*tilesize, (1+y)*tilesize)

    createCirclePath((1+x)*tilesize, (0+y)*tilesize, 0.25*tilesize, 25, math.pi, 1.5*math.pi)
    createCirclePath((1+x)*tilesize, (1+y)*tilesize, 0.25*tilesize, 25, 0.5*math.pi, math.pi)
    
  elseif symbol == "t-cross_bottom" then
    createLine((0+x) * tilesize, (0.25+y) * tilesize, (1+x) * tilesize, (0.25+y) * tilesize)

    createCirclePath((0+x)*tilesize, (1+y)*tilesize, 0.25*tilesize, 25, 0.0*math.pi, 0.5*math.pi)
    createCirclePath((1+x)*tilesize, (1+y)*tilesize, 0.25*tilesize, 25, 0.5*math.pi, 1.0*math.pi)
    
  elseif symbol == "t-cross_left" then
    createLine((0.75+x) * tilesize, (0+y) * tilesize, (0.75+x) * tilesize, (1+y) * tilesize)

    createCirclePath((0+x)*tilesize, (0+y)*tilesize, 0.25*tilesize, 25, 1.5*math.pi, 2.0*math.pi)
    createCirclePath((0+x)*tilesize, (1+y)*tilesize, 0.25*tilesize, 25, 0.0*math.pi, 0.5*math.pi)
    
  elseif symbol == "cross" then
    createCirclePath((0+x)*tilesize, (0+y)*tilesize, 0.25*tilesize, 25, 1.5*math.pi, 2.0*math.pi)
    createCirclePath((0+x)*tilesize, (1+y)*tilesize, 0.25*tilesize, 25, 0.0*math.pi, 0.5*math.pi)
    createCirclePath((1+x)*tilesize, (0+y)*tilesize, 0.25*tilesize, 25, math.pi, 1.5*math.pi)
    createCirclePath((1+x)*tilesize, (1+y)*tilesize, 0.25*tilesize, 25, 0.5*math.pi, math.pi)

  elseif symbol == "heart" then
    
  elseif symbol == "lung" then
    
  elseif symbol == "brain" then
    
  end

end

function wallipyTiles(tilesize)
  for x = 1,150 do
    for y = 1,150 do
      createSegment( level.veins[x][y], x, y, tilesize )
    end
  end
end
      
