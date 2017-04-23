require "slam"
require "game"
require "title"
require "quests"
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

    music.intro:setVolume(.3)
    music.party:setVolume(.3)

    fontsize = 50
    fonts = {}
    for i,filename in pairs(love.filesystem.getDirectoryItems("fonts")) do
        fonts[filename:sub(1,-5)] = {}
        fonts[filename:sub(1,-5)][fontsize] = love.graphics.newFont("fonts/"..filename, fontsize)
    end

    love.physics.setMeter(100)
    world = love.physics.newWorld(0, 0, true)
    world:setCallbacks(beginContact)

    camera = Camera(30000, 30000)
    camera.smoother = Camera.smooth.damped(3)
    zoom = 0.25
    camera:zoomTo(zoom)

    love.graphics.setFont(fonts.unkempt[fontsize])
    love.graphics.setBackgroundColor(0, 0, 0)

    initGame()
    initTitle()
end

function createThing(x, y, typ, this_world)
    thing = {}

    if typ == "player" then
        f = 2
    elseif typ == "bubble" then
        f = 0.5
    else
        f = 1
        --thing.hasOxygen = true
    end

    if typ == "oxystation" then
        thing.body = love.physics.newBody(this_world, 0, 0)
        --thing.shape = love.physics.newRectangleShape(200, 200, 600, 600)
        --thing.fixture = love.physics.newFixture(thing.body, thing.shape)
        --thing.body:setInertia(100000)
        --thing.body:setMass(1*f^3)
        thing.body:setPosition(x+600, y+300)
    else
        thing.body = love.physics.newBody(this_world, 0, 0, "dynamic")
        thing.shape = love.physics.newCircleShape(0, 0, 100*f)
        thing.fixture = love.physics.newFixture(thing.body, thing.shape)
        thing.fixture:setUserData({typ = typ, object = thing})
        thing.body:setInertia(100000)
        thing.body:setMass(1*f^3)
        thing.fixture:setFriction(0)
        thing.body:setPosition(x, y)
    end

    thing.typ = typ
    thing.flip = 1

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

    quests = {}
    quest = Quest.create("abc", 1000, "cde")
    quest:textAppear({"Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.", "At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.", "At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet."})
    table.insert(quests, quest)

    game_points = 0
    mode = "title"

    organs = {}
    organs["B"] = {name = "Brain"}
    organs["S"] = {name = "Stomach"}
    organs["F"] = {name = "Feet"}
    organs["C"] = {name = "Colon"}
    organs["H"] = {name = "Heart", immune = true}

    tilesize = 3000
    parseWorld("level.txt")
    wallipyTiles(tilesize)

    player = createThing(startX, startY, "player", world)
    table.insert(things, player)
    x, y = player.body:getPosition()

    offset = #things
    n = 20

    for i = 1, n do
        thing = createThing(startX+math.random(-tilesize/4, tilesize/4), startY+math.random(-tilesize/4, tilesize/4), "red", world)
        thing.follow = things[math.floor((i)/2+offset)]
        table.insert(things, thing)
    end

    for name, organ in pairs(organs) do
        organ.deadline = love.timer.getTime() + math.random(120,240)
        organ.alive = true
    end

    --for i = 1, n do
    --    createThing(math.random(0, 2000)+2000, math.random(0, 2000), "bubble")
    --end

    intro_music = music.intro:play()
end

function love.update(dt)
    Timer.update(dt)

    ff = 50000
    ff2 = 50000

    if mode == "game" then
        world:update(dt)

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

            if thing.body then
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
            end

            -- bubble popping
            if thing.typ == "red" and thing.hasOxygen then
                x, y = thing.body:getPosition()
                organ = getOrgan(x, y)
                if organ and not organ.immune then
                    thing.hasOxygen = false
                    organ.deadline = organ.deadline + 30
                    sounds.drop_oxygen:play()
                end
            end

            if thing.typ == "red" and not thing.hasOxygen then
                for i, thing2 in pairs(things) do
                    if thing2.typ == "oxystation" then
                        x, y = thing.body:getPosition()
                        x2, y2 = thing2.body:getPosition()
                        dist = math.sqrt((x-x2)^2 + (y-y2)^2)
                        if dist < 1500 then
                            thing.hasOxygen = true
                        end
                    end
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

        cx, cy = camera:position()
        x, y = player.body:getPosition()
        dx, dy = player.body:getLinearVelocity()
        tx = x+dx*0.7
        ty = y+dy*0.7
        lx = cx + 2*dt*(tx-cx)
        ly = cy + 2*dt*(ty-cy)
        camera:lookAt(lx, ly)

        speedX, speedY = player.body:getLinearVelocity()
        speed = math.sqrt(speedX^2 + speedY^2)
        targetzoom = zoom/(1+range(speed, 0, 20000))
        z = lerp(camera.scale, targetzoom, dt)
        camera:zoomTo(z)


    elseif mode == "title" or mode == "gameover" then
        title_world:update(dt)

        if #title_bubbles == 0 then
          red = createThing(math.random(-tilesize/2, tilesize/2), math.random(-tilesize/2, tilesize/2), "red", title_world)
          red.hasOxygen = false
          table.insert(title_bloodies,red)

          bub = createThing(math.random(-tilesize/2, tilesize/2), math.random(-tilesize/2, tilesize/2), "bubble", title_world)
          table.insert(title_bubbles, bub)
        end

        for i, red in pairs(title_bloodies) do
          if not red.hasOxygen and red.follow then
            x1, y1 = red.follow.body:getPosition()
            x2, y2 = red.body:getPosition()
            dist = math.sqrt((x1-x2)^2 + (y1-y2)^2)
            if dist > 100 then
              red.body:applyForce((x1-x2)*ff/dist, (y1-y2)*ff/dist, 0, 0)
            end
          elseif not red.hasOxygen and #title_bubbles > 0 then
            aimFor = math.random(#title_bubbles)
            red.follow = title_bubbles[aimFor]
          elseif red.hasOxygen and love.timer.getTime() - red.pickUp > math.random(8,20) then
            bub = createThing(math.random(-tilesize/2, tilesize/2), math.random(-tilesize/2, tilesize/2), "bubble", title_world)
            table.insert(title_bubbles, bub)
            red.hasOxygen = false

          end
          -- damping
          x, y = red.body:getLinearVelocity()
          red.body:applyForce(-10*x, -10*y)

          -- flipping
          vx = red.body:getLinearVelocity()
          if vx >= 200 then
            red.flip = 1
          end
          if vx <= -200 then
            red.flip = -1
          end
        end
        for i,bub in pairs(title_bubbles) do
          -- damping
          x, y = bub.body:getLinearVelocity()
          bub.body:applyForce(-10*x, -10*y)
        end

      camera:lookAt(0,0)
    end
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
    elseif key == "p" and mode == "game" then
        saveX, saveY = player.body:getPosition()
        mode = "title"
    elseif key == "return" and mode == "title" then
        mode = "game"
        camera:lookAt(startX, startY)
        intro_music:stop()
        game_music = music.party:play()
        heart_beat = music.heart_beat:play()
    end

    for i, quest in pairs(quests) do
      quest:inputHandle(key)
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
        remove(title_bubbles, bubble)

        for i, thing in pairs(things) do
          if thing.follow == bubble then
            thing.follow = nil
          end
        end
        for i, red in pairs(title_bloodies) do
          if red.follow == bubble then
            red.follow = nil
          end
        end

        red.pickUp = love.timer.getTime()

        bubble.body:destroy()
        love.audio.play(sounds.pick_up_oxygen)
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
    if mode == "game" then
        -- draw world
        camera:attach()

        drawLevel()

        f = 0.5

        for i, thing in pairs(things) do
            x, y = thing.body:getPosition()
            if thing.typ == "player" then
                if thing.hasOxygen then
                    love.graphics.draw(images.bluti, x, y, 0, f*2*thing.flip, f*2, images.bluti:getWidth()/2, images.bluti:getHeight()/2)
                else
                    love.graphics.draw(images.blutiempty, x, y, 0, f*2*thing.flip, f*2, images.blutiempty:getWidth()/2, images.blutiempty:getHeight()/2)
                end
            elseif thing.typ == "red" then
                if thing.hasOxygen then
                    love.graphics.draw(images.bluti, x, y, 0, f*thing.flip, f, images.bluti:getWidth()/2, images.bluti:getHeight()/2)
                else
                    love.graphics.draw(images.blutiempty, x, y, 0, f*thing.flip, f, images.blutiempty:getWidth()/2, images.blutiempty:getHeight()/2)
                end
            elseif thing.typ == "bubble" then
                love.graphics.draw(images.bubble, x, y, 0, f, f, images.bubble:getWidth()/2, images.bubble:getHeight()/2)
            elseif thing.typ == "oxystation" then
                t = love.timer.getTime()
                dy = math.sin(t*4)*100
                love.graphics.draw(images.lunge, x+1200, y-100+dy, 0, -f*3, f*3, images.bubble:getWidth()/2, images.bubble:getHeight()/2)
                love.graphics.draw(images.Eiswagen, x, y, 0, f*2, f*2, images.bubble:getWidth()/2, images.bubble:getHeight()/2)
            end
        end

        love.graphics.setNewFont(150)
        for i, sign in pairs(signs) do
            if sign.ox then
                sx = (sign.pos[1]+0.5)*tilesize+sign.ox
                sy = (sign.pos[2]+0.5)*tilesize+sign.oy
                l = tilesize/2
                o = tilesize/8

                if sign.left then
                    love.graphics.draw(images.sign, sx, sy, math.pi, 5, 5, 0, images.sign:getHeight()/2)
                    love.graphics.setColor(0, 0, 0)
                    love.graphics.printf(sign.left, sx-l-o, sy, l, "right")
                    love.graphics.setColor(255, 255, 255)
                end
                if sign.right then
                    love.graphics.draw(images.sign, sx, sy, 0, 5, 5, 0, images.sign:getHeight()/2)
                    love.graphics.setColor(0, 0, 0)
                    love.graphics.printf(sign.right, sx+o, sy, l, "left")
                    love.graphics.setColor(255, 255, 255)
                end
                if sign.up then
                    love.graphics.draw(images.sign, sx, sy, math.pi/2*3, 5, 5, 0, images.sign:getHeight()/2)
                    love.graphics.setColor(0, 0, 0)
                    love.graphics.printf(sign.up, sx, sy-l-o, l, "right", math.pi/2)
                    love.graphics.setColor(255, 255, 255)
                end
                if sign.down then
                    love.graphics.draw(images.sign, sx, sy, math.pi/2, 5, 5, 0, images.sign:getHeight()/2)
                    love.graphics.setColor(0, 0, 0)
                    love.graphics.printf(sign.down, sx, sy+o, l, "left", math.pi/2)
                    love.graphics.setColor(255, 255, 255)
                end
            end
        end


        --love.graphics.setLineWidth(50)
        --love.graphics.setColor(200, 0, 0)

        --for i, wall in pairs(walls) do
        --    love.graphics.line(wall.x1, wall.y1, wall.x2, wall.y2)
        --end

        --love.graphics.setColor(255, 255, 255)

        camera:detach()
        -- draw UI

        for i, quest in pairs(quests) do
          quest:draw()
        end

        love.graphics.setNewFont(50)

        x, y = player.body:getPosition()
        organ = getOrgan(x, y)
        if organ then
            love.graphics.printf("Current position: "..organ.name, 100, 20, 1000, "left")
        end

        y = 100
        for symbol, organ in pairs(organs) do
            if not organ.immune then
                now = love.timer.getTime()
                remaining = math.ceil(organ.deadline-now)
                if remaining < 0 then
                    organ.alive = false
                    mode = "gameover"
                    game_music:stop()
                    heart_beat:stop()
                    game_over_music = music.blues:play()
                elseif remaining < 10 then
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

    elseif mode == "title"  or mode == "gameover" then

      love.graphics.setColor(255,255,255)
      love.graphics.draw(images.bg, 0, 0)

      if love.timer.getTime() - blink_timer > 0.5 then
        blink_timer = love.timer.getTime()
        blink = not blink
      end

      camera:attach()
      x,y = camera:worldCoords(0,0)

      for i, red in pairs(title_bloodies) do
        x, y = red.body:getPosition()
        if red.hasOxygen then
          love.graphics.draw(images.bluti, x, y, 0, red.flip, 1, images.bluti:getWidth()/2, images.bluti:getHeight()/2)
        else
          love.graphics.draw(images.blutiempty, x, y, 0, red.flip, 1, images.blutiempty:getWidth()/2, images.blutiempty:getHeight()/2)
         end
      end
      for i, bub in pairs(title_bubbles) do
        x,y = bub.body:getPosition()
        love.graphics.draw(images.bubble, x, y, 0, 1, 1, images.bubble:getWidth()/2, images.bubble:getHeight()/2)
      end

      camera:detach()

      width, height = love.graphics.getDimensions()
      if mode == "title" then
        love.graphics.setColor(255,255,255)
        love.graphics.setFont(title_font)
        love.graphics.printf("A Bloody Small World!", 0, 100, width, "center")

        love.graphics.setFont(subtitle_font)
        love.graphics.printf("made in 48 hours for Ludum Dare 38", 0, height/2-50, width, "center")
        love.graphics.printf("by A, B, C", 0, height/2+50, width, "center")

        if blink then
          love.graphics.setColor(175, 175, 236)
          love.graphics.setFont(love.graphics.newFont(25))
          love.graphics.printf("Press <Enter> to start!", 0, height - 75, width, "center")
        end
      elseif mode == "gameover" then
        braindead = not organs["B"].alive
        good_shape = nil
        time = 0
        now = love.timer.getTime()
        for symbol, organ in pairs(organs) do
          if organ.deadline - now > time then
            good_shape = organ.name
            time = organ.deadline - now
          end
        end
        love.graphics.setColor(255,255,255)
        love.graphics.setFont(love.graphics.newFont(40))
        love.graphics.printf("You died!", 0, 100, width, "center")
        if braindead then
          love.graphics.printf("You are braindead!", 0, 200, width, "center")
        end
        if good_shape then
          gshape_string = "... "..good_shape
          love.graphics.printf("At least you took good care about your "..gshape_string,0,300, width, "center")
        end

      end

    elseif mode == "menu" then
    end

end
