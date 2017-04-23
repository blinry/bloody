function initTitle()
    title_world = love.physics.newWorld(0, 0, true)
    title_world:setCallbacks(beginContact)

    count = game_points + 1

    title_bubbles = {}
    title_bloodies = {}

    for i=1, count do
        bloody = createThing(math.random(-tilesize/2, tilesize/2), math.random(-tilesize/2, tilesize/2), "red", title_world)
        bloody.hasOxygen = false
        table.insert(title_bloodies, bloody)

        bub = createThing(math.random(-tilesize/2, tilesize/2), math.random(-tilesize/2, tilesize/2), "bubble", title_world)
        table.insert(title_bubbles, bub)
    end

    title_font = love.graphics.newFont(100)
    subtitle_font = love.graphics.newFont(40)

    blink = true
    blink_timer = love.timer.getTime()

end

