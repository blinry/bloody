Quest = {}
Quest.__index = Quest

function Quest:create(questgiver, timer)
  local que = {}
  setmetatable(que, Quest)
  que.questgiver = questgiver
  que.timer = timer
  que.textarray = {}
  que.textstate = 1
  que.state = "not_started"
  que.toDraw = false
  que.drawTimer = love.timer.getTime()
  que.appearTime = 1.0
  que.font =  love.graphics.newFont(25)
  return que
end

function Quest:start()
  self.state = "started"
  self.drawTimer = love.timer.getTime()
end

function Quest:finish()
  self.state = "finished"
  self.toDraw = true
  self.drawTimer = love.timer.getTime()
end

function Quest:draw()
  if not self.toDraw then
    return
  end

  diff = love.timer.getTime() - self.drawTimer
  rectanglePercent = diff / self.appearTime
  if rectanglePercent > 1 then
    rectanglePercent = 1
  end

  x = (1260/2) - rectanglePercent * ((1260/2)-10)
  y = (200/2) - rectanglePercent * ((200/2)-10) + 500

  rectangleAppear({255,255,255}, {0,0,0}, x, y, 1260 * rectanglePercent, 200 * rectanglePercent)

  old_font = love.graphics.getFont()
  love.graphics.setFont(self.font)

  if love.timer.getTime() - self.drawTimer > self.appearTime then
    love.graphics.printf(self.textarray[self.textstate], 25, 525, 1235, "center")

    if self.textstate < #self.textarray then
      local vertices = {1210, 650, 1210, 675, 1235, 663}
      love.graphics.polygon('fill', vertices) 
    end
  end

  love.graphics.setFont(old_font)
end

function Quest:inputHandle(key)
  if not self.toDraw or key ~= "return" then
    return
  end

  diff = love.timer.getTime() - self.drawTimer
  if diff > (self.appearTime + 0.5) then
    self.textstate = self.textstate+1
  end

  if self.textstate > #self.textarray then
    self.textstate = 1
    self.toDraw = false
  end
end

function Quest:textAppear(inputtext)
  self.textarray = inputtext
  self.toDraw = true
  self.drawTimer = love.timer.getTime()
  self.textstate = 1

end

function rectangleAppear(bordercolor, fillcolor, x, y, width, height)
  r, g, b, a = love.graphics.getColor()
  love.graphics.setColor(fillcolor[1], fillcolor[2], fillcolor[3], 200)
  love.graphics.rectangle("fill", x, y, width, height)

  if width > 10 and height > 10 then
    love.graphics.setColor(bordercolor[1], bordercolor[2], bordercolor[3], 200)
    love.graphics.rectangle("line", x+5, y+5, width-10, height-10)
  end

  love.graphics.setColor(r, g, b, a)
end

