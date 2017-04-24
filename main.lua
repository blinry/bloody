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

    music.blues:setVolume(.3)
    music.intro:setVolume(.3)
    music.party:setVolume(.3)

    fontsizes = {30, 50}
    fonts = {}
    for i,filename in pairs(love.filesystem.getDirectoryItems("fonts")) do
        fonts[filename:sub(1,-5)] = {}
        for i,fontsize in ipairs(fontsizes) do
          fonts[filename:sub(1,-5)][fontsize] = love.graphics.newFont("fonts/"..filename, fontsize)
        end
    end

    love.physics.setMeter(100)
    world = love.physics.newWorld(0, 0, true)
    world:setCallbacks(beginContact)

    camera = Camera(30000, 30000)
    camera.smoother = Camera.smooth.damped(3)
    zoom = 0.25
    camera:zoomTo(zoom)

    large_font = fonts.unkempt[50]
    organ_font = fonts.unkempt[30]
    small_font = love.graphics.newFont(18)

    love.graphics.setFont(large_font)
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
        thing.body:setPosition(x, y)
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
    time = 8 --o'clock
    paused = false

    walls = {}
    things = {}

    quests = {}

    quests[8] = {organ="F", before={
        "Okay, class! Welcome to your first day in the blood stream! This is the heart, where all our journeys begin and end. If any of you gets lost, we'll meet back here, alright?",
        "Also, there might be more cells joining us later in the day. Be nice to them!",
        "Alright. attention, everyone! Our human is about to wake up! First, she will need some energy in her legs, to get up and walk to work! Everybody pick up some oxygen from Mr Lung! Then, follow me allll the way down!"
    }, after={
        "Nicely done! Thanks to you, our human got to work on time, even though she left a little late. You're all doing a really great job! Yay!"
    }}

    quests[10] = {organ="B", before={
        "Next: Heavy office work coming up! Let's get some oxygen to the brain! We've discussed before that we have a huge responsibility here, right? Without us, none of the other organs would be able to function!"
    }, after={
        "Good job, class! The grey matter seems to be running smoothly!\n--- HEY, YOU THERE, IN THE BACK, what are you doing with that dirty thought? Put it back! Jeez!"
    }}

    quests[12] = {organ="S", before={
        "Are you cells hungry? Let's go to the stomach for a lunch break! Our human should gulp down some food soon, as well, and will need the oxygen!"
    }, after={
        "Ewww, what is that? Spinach? Our human certainly has a weird taste. Well."
    }}

    quests[16] = {organ="C", before={
        "Attention, class! Remember that lunch from earlier? We're now needed in the bowel! Don't worry, this will be a fun ride! I think they even take a picture at the end, so put on your cutest smile!"
    }, after={
        "(to write)"
    }}

    quests[18] = {organ=nil, before={
        "Eeew, someone sneezed at our human! Be careful to avoid the viruses, they will steal your bubbles!"
    }, after={
        ""
    }}

    quests[20] = {organ=nil, before={
        "Work's over, so the rest of the day should be easy! ...",
        "Oh, I just got an emergency report: Our human started drinking cocktails! Quickly, everyone, follow me to the liver!"
    }, after={
        "Wow, look at all these nice colors! She must have drunken a Grasshopper, and a Tequila Sunrise, and a... Bloody Mary? Huh. Not sure how I feel about this. I hope our human gets back home safely."
    }}

    quests[24] = {organ=nil, before={
        "We did it, class! Our human is asleep. Good job! Let's go visit the dream cinema, I hear they will play a good horror movie tonight! And tomorrow, we'll do an excursion to the outside of the body!",
        "Thanks for playing \"A Bloody Small World\"! <3"
    }, after={
        ""
    }}


    currentQuest = nil

    box = Quest.create("?", 99999999999999, "?")
    --walk = Quest.create("F",
    --walk:textAppear({"Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.", "At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.", "At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet."})
    --table.insert(quests, quest)

    game_points = 0
    mode = "title"

    organs = {}
    organs["B"] = {key="B", name = "Brain"}
    organs["S"] = {key="S", name = "Stomach"}
    organs["F"] = {key="F", name = "Feet"}
    organs["C"] = {key="C", name = "Colon"}
    organs["L"] = {key="L", name = "Liver", immune = true}
    organs["H"] = {key="H", name = "Heart", immune = true}
    organs["O"] = {key="O", name = "Lung", immune = true}

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

    --for i = 1, n do
    --    createThing(math.random(0, 2000)+2000, math.random(0, 2000), "bubble")
    --end

    intro_music = music.intro:play()
    sounds.pick_up_oxygen:setVolume(.2)
end

function love.update(dt)
    Timer.update(dt)

    ff = 50000
    ff2 = 50000

    if mode == "game" then
        world:update(dt)

        if not paused then
            time = time+dt*(10/(16*60))
            q = quests[math.floor(time)]
            if q then
                currentQuest = q
                quests[math.floor(time)] = nil
                box:textAppear(currentQuest.before)
                if q.organ then
                    organs[q.organ].displayed = true
                end
            end

            for i, organ in pairs(organs) do
                if organ.displayed then
                    organ.remaining = organ.remaining - dt
                    if organ.remaining <= 0 then
                        organ.alive = false
                        mode = "gameover"
                        game_music:stop()
                        heart_beat:stop()
                        game_over_music = music.blues:play()
                        sounds.pick_up_oxygen:setVolume(.2)
                    end
                end
            end
        end

        x, y = player.body:getPosition()
        organ = getOrgan(x, y)
        if organ and currentQuest and organ.key == currentQuest.organ then
            box:textAppear(currentQuest.after)
            currentQuest = nil
        end

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
                    organ.remaining = organ.remaining + 10
                    sounds.drop_oxygen:setPitch(math.random(90, 110)/100)
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
                            sounds.pick_up_oxygen:setPitch(math.random(90, 110)/100)
                            sounds.pick_up_oxygen:play()
                        end
                    end
                end
            end
        end

        for symbol, organ in pairs(organs) do
            now = love.timer.getTime()
            if organ.remaining <= 0 then
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

        for name, organ in pairs(organs) do
            organ.remaining = 60
            organ.alive = true
        end

        camera:lookAt(startX, startY)
        intro_music:stop()
        game_music = music.party:play()
        heart_beat = music.heart_beat:play()
        sounds.pick_up_oxygen:setVolume(.5)
    end

    box:inputHandle(key)
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
        sounds.pick_up_oxygen:setPitch(math.random(90, 110)/100)
        sounds.pick_up_oxygen:play()
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

function display_organ_notification(x, y, organ, title_callback)
  if not organ then
    return
  end

  local thumbnail_size = 50
  local box_height = thumbnail_size + 20

  local old_r, old_g, old_b, old_a = love.graphics.getColor()
  local old_font = love.graphics.getFont()

  love.graphics.setColor(0, 0, 0, 150)
  love.graphics.rectangle("fill", x, y, 4 * box_height, box_height, 5)

  love.graphics.setColor(255, 255, 255, 255)

  if organ.image then
    love.graphics.draw(organ.image, x + 10, y + 10, 0, thumbnail_size / organ.image:getWidth())
  end

  love.graphics.setFont(small_font)
  title_callback(x + thumbnail_size + 20, y + 10)

  love.graphics.setFont(organ_font)
  love.graphics.printf(organ.name, x + thumbnail_size + 20, y + 30, 1000, "left")

  love.graphics.setColor(old_r, old_g, old_b, old_a)
  love.graphics.setFont(old_font)
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
                love.graphics.draw(images.lunge, x+200, y+dy-300, 0, -f*3, f*3, images.lunge:getWidth()/2, images.lunge:getHeight()/2)
                love.graphics.draw(images.Eiswagen, x-300, y, 0, f*2, f*2, images.Eiswagen:getWidth()/2, images.Eiswagen:getHeight()/2)
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

        box:draw()

        love.graphics.setNewFont(50)

        x, y = player.body:getPosition()
        organ = getOrgan(x, y)

        display_organ_notification(10, 10, organ, function (x, y)
          love.graphics.printf("Current position", x, y, 1000, "left")
        end)

        min_remaining_oxygen = math.huge

        y = 10
        for symbol, organ in pairs(organs) do
            if not organ.immune and organ.displayed then
                now = love.timer.getTime()
                remaining = organ.remaining
                min_remaining_oxygen = math.min(min_remaining_oxygen, remaining)
                display_organ_notification(990, y, organ, function (title_x, title_y)
                    local old_r, old_g, old_b, old_a = love.graphics.getColor()

                    local bar_width = remaining

                    if remaining > 100 then
                        love.graphics.setColor(0, 255, 0)
                        bar_width = 100 + math.min(100, remaining / 5)
                    elseif remaining > 50 then
                        love.graphics.setColor(255 * (100 - remaining) / 50, 255, 0)
                    elseif remaining > 20 then
                        love.graphics.setColor(255, 255 * (remaining - 20) / 30, 0)
                    else
                        love.graphics.setColor(255, 0, 0)
                    end

                    --love.graphics.printf(remaining, title_x, title_y, 1000, "left")
                    love.graphics.rectangle("fill", title_x, title_y, bar_width, 10, 2)

                    love.graphics.setColor(old_r, old_g, old_b, old_a)
                end)
                y = y+75
            end
        end

        hours = math.floor(time) % 24
        minutes = math.floor((time-math.floor(time))*60)
        width = love.graphics.getDimensions()

        love.graphics.printf(string.format("%02d:%02d", hours, minutes), 0, 20, width, "center")

        heart_beat_rate = 1.0 + math.max(0, 100 - min_remaining_oxygen) / 100.0
        heart_beat:setPitch(heart_beat_rate)
        heart_beat:setVolume(0.5 * heart_beat_rate)

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
          if organ.remaining > 0 then
            good_shape = organ.name
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
          love.graphics.printf("At least you took good care of your "..gshape_string,0,300, width, "center")
        end

      end

    elseif mode == "menu" then
    end

end
