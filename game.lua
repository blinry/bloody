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

    local world = {}
    world.veins = {}
    world.name = string.match(string.match(filename, "[^/]+.txt"), "[^/.]+"):sub(4):gsub("_", " ")
    world.solved = false
    world.story = {}
    world.won = {}

    for i = 1,151 do
        world.veins[i] = {}

        for j = 1,151 do
            world.veins[i][j] = "empty"
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
                  world.veins[i][lineNr] = legend[c]
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

-- createPath
function createSegment(symbol, x, y, tilesize)
  path = {}
  position = {}
  if symbol == "empty" then
  elseif symbol == "vertical" then
    position[1] = 0.25 * tilesize + x * tilesize
    position[2] = 0 * tilesize + y * tilesize
    path.insert(position)
    position[2] = 1 * tilesize + y * tilesize
    path.insert(position)
    createPath(path)

    path = {}
    position[1] = 0.75 * tilesize + x * tilesize
    position[2] = 0 * tilesize + y * tilesize
    path.insert(position)
    position[2] = 1 * tilesize + y * tilesize
    path.insert(position)
    createPath(path)

  elseif symbol == "horizontal" then
    position[2] = 0.25 * tilesize + y * tilesize
    position[1] = 0 * tilesize + x * tilesize
    path.insert(position)
    position[1] = 1 * tilesize + x * tilesize
    path.insert(position)
    createPath(path)

    path = {}
    position[2] = 0.75 * tilesize + y * tilesize
    position[1] = 0 * tilesize + x * tilesize
    path.insert(position)
    position[1] = 1 * tilesize + x * tilesize
    path.insert(position)
    createPath(path)
    

  elseif symbol == "top_right" then
    
  elseif symbol == "right_bottom" then
    
  elseif symbol == "bottom_left" then
    
  elseif symbol == "left_top" then
    

  elseif symbol == "t-cross_top" then
    
  elseif symbol == "t-cross_right" then
    
  elseif symbol == "t-cross_bottom" then
    
  elseif symbol == "t-cross_left" then
    
  elseif symbol == "cross" then
    

  elseif symbol == "heart" then
    
  elseif symbol == "lung" then
    
  elseif symbol == "brain" then
    
  end

end

function wallipyTiles()
  for x = 1,150 do
    for y = 1,150 do
      createSegment( world.veins[x][y], x, y, 100 )
    end
  end
end
      
