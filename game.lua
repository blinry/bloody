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

