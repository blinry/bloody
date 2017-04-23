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

function remove(tbl, obj)
    j = nil
    for i, value in pairs(tbl) do
        if value == obj then
            j = i
        end
    end

    if j then
        table.remove(tbl, j)
    end
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

    fontsize = 50
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
    zoom = 0.5
    camera:zoomTo(zoom)

    love.graphics.setFont(fonts.unkempt[fontsize])
    love.graphics.setBackgroundColor(0, 0, 0)

    initGame()
end

function createThing(x, y, typ)
    thing = {}
    thing.body = love.physics.newBody(world, 0, 0, "dynamic")

    if typ == "player" then
        f = 2
    elseif typ == "bubble" then
        f = 0.5
    else
        f = 1
        thing.hasOxygen = true
    end
    thing.shape = love.physics.newCircleShape(0, 0, 100*f)
    thing.fixture = love.physics.newFixture(thing.body, thing.shape)
    thing.fixture:setUserData({typ = typ, object = thing})
    thing.body:setInertia(100000)
    thing.body:setMass(1*f^3)
    thing.fixture:setFriction(0)
    thing.body:setPosition(x, y)

    thing.typ = typ
    thing.flip = 1

    table.insert(things, thing)
    return thing
end

function createPath(points)
    prev = nil
    for i, point in pairs(points) do
        if prev then
            createWall(prev[1], prev[2], point[1], point[2])
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
    walls = {}
    things = {}

    tilesize = 3000
    parseWorld("level2.txt")
    wallipyTiles(tilesize)

    player = createThing(startX, startY, "player")
    offset = #things
    n = 20

    for i = 1, n do
        thing = createThing(startX+math.random(-tilesize/4, tilesize/4), startY+math.random(-tilesize/4, tilesize/4), "red")
        thing.follow = things[math.floor((i)/2+offset)]
    end

    organs = {}
    organs["B"] = {name = "Brain"}
    organs["S"] = {name = "Stomach"}
    organs["F"] = {name = "Feet"}
    organs["C"] = {name = "Colon"}
    --organs["H"] = {name = "Heart"}

    for name, organ in pairs(organs) do
        organ.deadline = love.timer.getTime() + math.random(60,100)
    end

    --for i = 1, n do
    --    createThing(math.random(0, 2000)+2000, math.random(0, 2000), "bubble")
    --end
end

function love.update(dt)
    Timer.update(dt)
    world:update(dt)

    ff = 50000
    ff2 = 50000

    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        player.body:applyForce(ff2, 0, 0, 0)
    end
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        player.body:applyForce(-ff2, 0, 0, 0)
    end
    if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
        player.body:applyForce(0, -ff2, 0, 0)
    end
    if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
        player.body:applyForce(0, ff2, 0, 0)
    end

    for i, thing in pairs(things) do
        -- follow
        if thing.follow then
            x1, y1 = thing.follow.body:getPosition()
            x2, y2 = thing.body:getPosition()
            dist = math.sqrt((x1-x2)^2 + (y1-y2)^2)
            if dist > 400 then
                thing.body:applyForce((x1-x2)*ff/dist, (y1-y2)*ff/dist, 0, 0)
            end
        end

        -- damping
        x, y = thing.body:getLinearVelocity()
        thing.body:applyForce(-10*x, -10*y)

        -- streaming
        x, y = thing.body:getPosition()
        fx, fy = getStream(x, y)
        thing.body:applyForce(fx, fy)

        -- flipping
        vx = thing.body:getLinearVelocity()
        if vx >= 200 then
            thing.flip = 1
        end
        if vx <= -200 then
            thing.flip = -1
        end

        -- bubble popping
        if thing.typ == "red" and thing.hasOxygen then
            x, y = thing.body:getPosition()
            organ = getOrgan(x, y)
            if organ then
                thing.hasOxygen = false
                organ.deadline = organ.deadline + 10
            end
        end
    end

    for symbol, organ in pairs(organs) do
        now = love.timer.getTime()
        remaining = math.ceil(organ.deadline-now)
        if remaining <= 0 then
            -- game over
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
    elseif key == "-" and debug then
        zoom = zoom/2
    elseif key == "+" and debug then
        zoom = zoom*2
    end
    camera:zoomTo(zoom)
end

function love.mousepressed(x, y, button, touch)
    if button == 1 then

    end
    if button == 2 then

    end
end

function pickUp(red, bubble)
    if not red.hasOxygen then
        red.hasOxygen = true
        remove(things, bubble)
        bubble.body:destroy()
    end
end

function beginContact(a, b, coll)
    if a:getUserData() and b:getUserData() then
        if a:getUserData().typ == "bubble" and b:getUserData().typ == "red" then
            pickUp(b:getUserData().object, a:getUserData().object)
        elseif a:getUserData().typ == "red" and b:getUserData().typ == "bubble" then
            pickUp(a:getUserData().object, b:getUserData().object)
        end
    end
end

function love.draw()
    love.graphics.setColor(255, 255, 255)

    -- draw world
    camera:attach()

    x, y = camera:worldCoords(0, 0)
    xx = math.floor(x/(images.bg:getWidth()*4))
    yy = math.floor(y/(images.bg:getWidth()*4))
    for x = xx,xx+3 do
        for y = yy,yy+3 do
            love.graphics.draw(images.bg, images.bg:getWidth()*x*4, images.bg:getHeight()*y*4, 0, 4, 4)
        end
    end

    for i, thing in pairs(things) do
        x, y = thing.body:getPosition()
        if thing.typ == "player" then
            if thing.hasOxygen then
                love.graphics.draw(images.bluti, x, y, 0, 2*thing.flip, 2, images.bluti:getWidth()/2, images.bluti:getHeight()/2)
            else
                love.graphics.draw(images.blutiempty, x, y, 0, 2*thing.flip, 2, images.blutiempty:getWidth()/2, images.blutiempty:getHeight()/2)
            end
        elseif thing.typ == "red" then
            if thing.hasOxygen then
                love.graphics.draw(images.bluti, x, y, 0, thing.flip, 1, images.bluti:getWidth()/2, images.bluti:getHeight()/2)
            else
                love.graphics.draw(images.blutiempty, x, y, 0, thing.flip, 1, images.blutiempty:getWidth()/2, images.blutiempty:getHeight()/2)
            end
        elseif thing.typ == "bubble" then
            love.graphics.draw(images.bubble, x, y, 0, 1, 1, images.bubble:getWidth()/2, images.bubble:getHeight()/2)
        end
    end

    love.graphics.setLineWidth(50)
    love.graphics.setColor(200, 0, 0)

    for i, wall in pairs(walls) do
        love.graphics.line(wall.x1, wall.y1, wall.x2, wall.y2)
    end

    love.graphics.setColor(255, 255, 255)

    camera:detach()

    -- draw UI

    y = 100
    for symbol, organ in pairs(organs) do
        now = love.timer.getTime()
        remaining = math.ceil(organ.deadline-now)
        if remaining < 10 then
            love.graphics.setColor(255, 0, 0)
        elseif remaining < 30 then
            love.graphics.setColor(255, 255, 0)
        else
            love.graphics.setColor(255, 255, 255)
        end
        love.graphics.printf(organ.name..": "..remaining, 100, y, 1000, "left")
        y = y+100
    end
end
