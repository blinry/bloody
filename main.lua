require "slam"
require "game"
vector = require "hump.vector"
Timer = require "hump.timer"
Camera = require "hump.camera"

-- convert HSL to RGB (input and output range: 0 - 255)
function HSL(h, s, l, a)
    if s<=0 then return l,l,l,a end
    h, s, l = h/256*6, s/255, l/255
    local c = (1-math.abs(2*l-1))*s
    local x = (1-math.abs(h%2-1))*c
    local m,r,g,b = (l-.5*c), 0,0,0
    if h < 1     then r,g,b = c,x,0
    elseif h < 2 then r,g,b = x,c,0
    elseif h < 3 then r,g,b = 0,c,x
    elseif h < 4 then r,g,b = 0,x,c
    elseif h < 5 then r,g,b = x,0,c
    else              r,g,b = c,0,x
    end

    return (r+m)*255,(g+m)*255,(b+m)*255,a
end

-- take the values from tbl from first to last, with stepsize step
function table.slice(tbl, first, last, step)
    local sliced = {}

    for i = first or 1, last or #tbl, step or 1 do
        sliced[#sliced+1] = tbl[i]
    end

    return sliced
end

-- linear interpolation between a and b, with t between 0 and 1
function lerp(a, b, t)
    return a + t*(b-a)
end

-- return a value between 0 and 1, depending on where value is between min and
-- max, clamping if it's outside.
function range(value, min, max)
    if value < min then
        return 0
    elseif value > max then
        return 1
    else
        return (value-min)/(max-min)
    end
end

function worldCoords(camera, x1, y1, x2, y2, x3, y3, x4, y4)
    a1, b1 = camera:worldCoords(x1, y1)
    a2, b2 = camera:worldCoords(x2, y2)
    a3, b3 = camera:worldCoords(x3, y3)
    a4, b4 = camera:worldCoords(x4, y4)
    return a1, b1, a2, b2, a3, b3, a4, b4
end

function cameraCoords(camera, x1, y1, x2, y2, x3, y3, x4, y4)
    a1, b1 = camera:cameraCoords(x1, y1)
    if x2 then
        a2, b2 = camera:cameraCoords(x2, y2)
    end
    if x3 then
        a3, b3 = camera:cameraCoords(x3, y3)
    end
    if x4 then
        a4, b4 = camera:cameraCoords(x4, y4)
    end
    return a1, b1, a2, b2, a3, b3, a4, b4
end

function love.load()
    images = {}
    for i,filename in pairs(love.filesystem.getDirectoryItems("images")) do
        images[filename:sub(1,-5)] = love.graphics.newImage("images/"..filename)
    end

    sounds = {}
    for i,filename in pairs(love.filesystem.getDirectoryItems("sounds")) do
        sounds[filename:sub(1,-5)] = love.audio.newSource("sounds/"..filename, "static")
    end

    music = {}
    for i,filename in pairs(love.filesystem.getDirectoryItems("music")) do
        music[filename:sub(1,-5)] = love.audio.newSource("music/"..filename)
        music[filename:sub(1,-5)]:setLooping(true)
    end

    fonts = {}
    for i,filename in pairs(love.filesystem.getDirectoryItems("fonts")) do
        fonts[filename:sub(1,-5)] = {}
        fonts[filename:sub(1,-5)][fontsize] = love.graphics.newFont("fonts/"..filename, fontsize)
    end

    love.physics.setMeter(100)
    world = love.physics.newWorld(0, 0, true)
    world:setCallbacks(beginContact)

    camera = Camera(300, 300)
    camera.smoother = Camera.smooth.damped(3)
    camera:zoom(0.5)

    --love.graphics.setFont(fonts.unkempt[fontsize])
    love.graphics.setBackgroundColor(0, 0, 0)

    initGame()
end

function createCell(x, y)
    cell = {}
    cell.body = love.physics.newBody(world, 0, 0, "dynamic")
    cell.shape = love.physics.newCircleShape(0, 0, 100)
    cell.fixture = love.physics.newFixture(cell.body, cell.shape)
    cell.body:setInertia(100000)
    cell.body:setMass(10)
    cell.fixture:setFriction(0)
    cell.body:setPosition(x, y)
    return cell
end

function createPath(points)
    prev = nil
    for i, point in pairs(points) do
        if prev then
            createWall(prev.x, prev.y, point.x, point.y)
        end
        prev = point
    end
end

function createWall(x1, y1, x2, y2)
    wall = {}
    wall.body = love.physics.newBody(world, 0, 0)
    wall.shape = love.physics.newEdgeShape(x1, y1, x2, y2)
    wall.fixture = love.physics.newFixture(wall.body, wall.shape)
    wall.fixture:setFriction(0)

    wall.x1 = x1
    wall.y1 = y1
    wall.x2 = x2
    wall.y2 = y2

    table.insert(walls, wall)
end

function initGame()
    cells = {}
    for i = 1, 20 do
        c = createCell(math.random(0, 1000), math.random(0, 1000))
        table.insert(cells, c)
    end
    player = cells[2]

    walls = {}

    parseWorld("level.txt")
    wallipyTiles()
    --createPath({{x=0, y=0}, {x=4000, y=0}, {x=4000, y=4000}, {x=0, y=4000}, {x=0, y=0}})
end

function love.update(dt)
    Timer.update(dt)
    world:update(dt)

    for i, cell in pairs(cells) do
        if i%2 == 0 then
            if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
                cell.body:applyForce(100000, 0, 0, 0)
            end
            if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
                cell.body:applyForce(-100000, 0, 0, 0)
            end
            if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
                cell.body:applyForce(0, -100000, 0, 0)
            end
            if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
                cell.body:applyForce(0, 100000, 0, 0)
            end
        end
    end

    x, y = player.body:getPosition()

    camera:lookAt(x, y)
end

function love.keypressed(key)
    if key == "escape" then
        love.window.setFullscreen(false)
        love.timer.sleep(0.1)
        love.event.quit()
    end
end

function love.mousepressed(x, y, button, touch)
    if button == 1 then

    end
    if button == 2 then

    end
end

function beginContact(a, b, coll)

end

function love.draw()
    -- draw world
    camera:attach()

    for i, cell in pairs(cells) do
        x, y = cell.body:getPosition()
        love.graphics.draw(images.red, x, y)
    end

    for i, wall in pairs(walls) do
        love.graphics.line(wall.x1, wall.y1, wall.x2, wall.y2)
    end

    camera:detach()

    -- draw UI
end
