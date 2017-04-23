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
    end

    title_bubble_timer = math.random(0.1, 5)
    
end

