function parseWorld(filename)
    local legend = {}
    legend[" "] = "empty"
    legend["#"] = "vein"
    legend["^"] = "up"
    legend[">"] = "right"
    legend["v"] = "down"
    legend["<"] = "left"
    legend["@"] = "start"
    legend["O"] = "O"
    legend["H"] = "H"
    legend["B"] = "B"
    legend["S"] = "S"
    legend["L"] = "L"
    legend["C"] = "C"
    legend["F"] = "F"

    level = {}
    level.tiles = {}

    for i = 1,30 do
        level.tiles[i] = {}

        for j = 1,50 do
            level.tiles[i][j] = {typ="empty"}
        end
    end

    local f = love.filesystem.newFile(filename)
    f:open("r")

    local lineNr = 1

    signs = {}
    local phase = 1
    for line in f:lines() do
        if phase == 1 then
            if line == "---" then
                phase = 2
            else
                for i = 1, #line, 1 do
                    local c = line:sub(i,i)
                    if string.match(c, "[a-uw-z]") then
                        signs[c] = {pos = {i, lineNr}}
                    else
                        level.tiles[i][lineNr].typ = legend[c]
                    end
                end
            end
        else
            local c = line:sub(1,1)
            local offset = line:sub(2,2)

            signs[c].ox = 0
            signs[c].oy = 0

            o = 1200

            if offset == "<" then
                signs[c].ox = -o
            end
            if offset == ">" then
                signs[c].ox = o
            end
            if offset == "v" then
                signs[c].oy = o
            end
            if offset == "^" then
                signs[c].oy = -o
            end

            words = {}
            for w in line:gmatch("%S+") do
                dir = w:sub(1,1)
                text = w:sub(2)
                if dir == "<" then
                    signs[c].left = text
                elseif dir == ">" then
                    signs[c].right = text
                elseif dir == "^" then
                    signs[c].up = text
                elseif dir == "v" then
                    signs[c].down = text
                end
            end
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
  for x = 2,#level.tiles-1 do
    for y = 2,#level.tiles[x]-1 do

      if level.tiles[x][y].typ == "start" then
          startX = (x+0.5)*tilesize
          startY = (y+0.5)*tilesize
      end

      if level.tiles[x][y].typ == "B" then
          if not organs["B"].pos then
              organs["B"].pos = {x, y}
              organs["B"].image = images.Gehirn
          end
      end

      if level.tiles[x][y].typ == "H" then
          if not organs["H"].pos then
              organs["H"].pos = {x, y}
              organs["H"].image = images.herz
          end
      end

      if level.tiles[x][y].typ == "S" then
          if not organs["S"].pos then
              organs["S"].pos = {x, y}
              organs["S"].image = images.organ
              organs["S"].rot = math.pi
          end
      end

      if level.tiles[x][y].typ == "L" then
          if not organs["L"].pos then
              organs["L"].pos = {x, y}
              organs["L"].image = images.organ
              organs["L"].rot = math.pi/2*3
          end
      end

      if level.tiles[x][y].typ == "C" then
          if not organs["C"].pos then
              organs["C"].pos = {x, y}
              organs["C"].image = images.organ
              organs["C"].rot = 0
          end
      end

      if level.tiles[x][y].typ == "F" then
          if not organs["F"].pos then
              organs["F"].pos = {x, y}
              organs["F"].image = images.organ
              organs["F"].rot = 0
          end
      end

      if level.tiles[x][y].typ == "O" then
          if not organs["O"].pos then
              organs["O"].pos = {x, y}
              organs["O"].image = images.lunge_groß
              oxy = createThing((x+1)*tilesize, (y+1)*tilesize, "oxystation", world)
              table.insert(things, oxy)
          end
      end

      --if level.tiles[x][y].typ == "lung" then
      --    --for i = 1,50 do
      --    --    bub = createThing((x+0.5)*tilesize+math.random(-tilesize/4,tilesize/4), (y+0.5)*tilesize+math.random(-tilesize/4,tilesize/4), "bubble", world)
      --    --    table.insert(things, bub)
      --    --end
      --    oxy = createThing((x+0.5)*tilesize, (y+0.5)*tilesize, "oxystation", world)
      --    table.insert(things, oxy)
      --end

      if level.tiles[x][y].typ ~= "empty" then
          l = isNotDirOrEmpty(level.tiles[x-1][y].typ) or level.tiles[x-1][y].typ == "right" or level.tiles[x][y].typ == "left" or (isNotDirOrEmpty(level.tiles[x][y].typ) and level.tiles[x-1][y].typ ~= "empty")
          r = isNotDirOrEmpty(level.tiles[x+1][y].typ) or level.tiles[x+1][y].typ == "left" or level.tiles[x][y].typ == "right" or (isNotDirOrEmpty(level.tiles[x][y].typ) and level.tiles[x+1][y].typ ~= "empty")
          t = isNotDirOrEmpty(level.tiles[x][y-1].typ) or level.tiles[x][y-1].typ == "down" or level.tiles[x][y].typ == "up" or (isNotDirOrEmpty(level.tiles[x][y].typ) and level.tiles[x][y-1].typ ~= "empty")
          b = isNotDirOrEmpty(level.tiles[x][y+1].typ) or level.tiles[x][y+1].typ == "up" or level.tiles[x][y].typ == "down" or (isNotDirOrEmpty(level.tiles[x][y].typ) and level.tiles[x][y+1].typ ~= "empty")

          --tl = level.tiles[x-1][y-1].typ ~= "empty"
          --tr = level.tiles[x+1][y-1].typ ~= "empty"
          --bl = level.tiles[x-1][y+1].typ ~= "empty"
          --br = level.tiles[x+1][y+1].typ ~= "empty"

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

          if t and b and not r and not l then
              if math.random(1,2) == 1 then
                  level.tiles[x][y].image = images.Gerade1
              else
                  level.tiles[x][y].image = images.Gerade2
              end
              level.tiles[x][y].rot = math.pi*math.random(0,1)
          end
          if r and l and not t and not b then
              if math.random(1,2) == 1 then
                  level.tiles[x][y].image = images.Gerade1
              else
                  level.tiles[x][y].image = images.Gerade2
              end
              level.tiles[x][y].rot = math.pi/2+math.pi*math.random(0,1)
          end
          if t and r and not b and not l and not tr then
              level.tiles[x][y].image = images.Kurve
              level.tiles[x][y].rot = 0
          end
          if not t and r and b and not l and not br then
              level.tiles[x][y].image = images.Kurve
              level.tiles[x][y].rot = math.pi/2
          end
          if not t and not r and b and l and not bl then
              level.tiles[x][y].image = images.Kurve
              level.tiles[x][y].rot = math.pi
          end
          if t and not r and not b and l and not tl then
              level.tiles[x][y].image = images.Kurve
              level.tiles[x][y].rot = math.pi*3/2
          end
          if l and r and b and not t then
              level.tiles[x][y].image = images.t
              level.tiles[x][y].rot = 0+math.pi
          end
          if l and not r and b and t then
              level.tiles[x][y].image = images.t
              level.tiles[x][y].rot = math.pi/2+math.pi
          end
          if l and r and not b and t then
              level.tiles[x][y].image = images.t
              level.tiles[x][y].rot = math.pi+math.pi
          end
          if not l and r and b and t then
              level.tiles[x][y].image = images.t
              level.tiles[x][y].rot = math.pi/2*3+math.pi
          end

          --createSegment( level.tiles[x][y], x, y, tilesize )
      else
          if math.random(1,2) == 1 then
              level.tiles[x][y].image = images.leerfeld
          else
              level.tiles[x][y].image = images.leerfeld_var2
          end
          level.tiles[x][y].rot = math.pi/2*math.random(0,3)
      end

    end
  end
end

function getStream(x, y)
    local ff = 40000
    typ = level.tiles[math.floor(x/tilesize)][math.floor(y/tilesize)].typ
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

function getOrgan(x, y)
    symbol = level.tiles[math.floor(x/tilesize)][math.floor(y/tilesize)].typ
    return organs[symbol]
end

function drawLevel()
    for x = 1,#level.tiles do
        for y = 1,#level.tiles[x] do
            if level.tiles[x][y].image then
                love.graphics.draw(level.tiles[x][y].image, (x+0.5)*tilesize, (y+0.5)*tilesize, level.tiles[x][y].rot, 3, 3, level.tiles[x][y].image:getWidth()/2, level.tiles[x][y].image:getHeight()/2)
            end
        end
    end
    for symbol, organ in pairs(organs) do
        if organ.pos then
            if not organ.rot then
                organ.rot = 0
            end
            love.graphics.draw(organ.image, (organ.pos[1]+0.5)*tilesize, (organ.pos[2]+0.5)*tilesize, organ.rot, 3, 3, tilesize/2/3, tilesize/2/3)
        end
    end
end

function isNotDirOrEmpty(typ)
    return not (typ == "empty" or typ == "left" or typ == "right" or typ == "down" or typ == "up")
end
