local you = nil
local tau = 2 * math.pi

function love.load(arg)
  if arg[#arg] == "-debug" then require("mobdebug").start() end
  love.window.setFullscreen(true)
  screen_width, screen_height = love.graphics.getDimensions()
  border_width, border_height = screen_width * 1, screen_height * 1
  downwind = false
  maxsize = screen_height/3
  minsize = 30
  mapsize = (border_width * border_height)/(screen_width * screen_height)
  -- Sets information about the starting circle
  you = {}
  you.mass = 2
  you.x = screen_width/2
  you.dx = 0
  you.px = you.x
  you.y = screen_height/2
  you.dy = 0
  you.py = you.y
  you.size = screen_height/16
  you.psize = you.size
  you.rotate = 0 * tau
  -- you.protate = you.rotate
  you.open = 0 * tau
  -- you.popen = you.open
  -- Particle information:
  particles = {}
  particlenum = 30000
  particlemass = mapsize/particlenum
  for i = 1, particlenum do
    currentdict = {}
    currentdict.x = math.random((screen_width - border_width)/2, screen_width + (border_width - screen_width)/2)
    currentdict.dx = math.random(-100, 100)/100 -- number between -1 and 1, in increments of 0.01
    currentdict.px = currentdict.x
    currentdict.y = math.random((screen_height - border_height)/2, screen_height + (border_height - screen_height)/2)
    if downwind then
      currentdict.dy = math.random(-100, 100)/100
    else
      currentdict.dy = math.random(-100, 100)/100
    end
    currentdict.py = currentdict.y
    particles[i]=currentdict -- So, particles is a list of dictionaries.
  end
end

function love.update(dt)
  circlemove(dt) -- moves you
  partimove(dt) -- moves particles
end

function circlemove(dt)
  you.px, you.py, you.psize = you.x, you.y, you.size
  you.x = you.x + you.dx * 100 * dt
  you.y = you.y + you.dy * 100 * dt
  if love.keyboard.isDown("a") then
    you.open = you.open + tau * dt
  end
  if love.keyboard.isDown("d") then
    you.open = you.open - tau * dt
  end
  if you.open < 0 then you.open = 0 elseif you.open > tau/2 then you.open = tau/2 end
  if love.keyboard.isDown("up") then
    you.size = you.size + 150 * dt
  end
  if love.keyboard.isDown("down") then
    you.size = you.size - 150 * dt
  end
  if you.size > maxsize then you.size = maxsize elseif you.size < minsize then you.size = minsize end
  if love.keyboard.isDown("left") then
    you.rotate = you.rotate - tau/2 * dt
  end
  if love.keyboard.isDown("right") then
    you.rotate = you.rotate + tau/2 * dt
  end
  if you.rotate < 0 then you.rotate = you.rotate + tau elseif you.rotate > tau then you.rotate = you.rotate - tau end
end

function partimove(dt)
  for i = 1, particlenum do
    local x, dx, px, y, dy, py = particles[i].x, particles[i].dx, particles[i].px, particles[i].y, particles[i].dy, particles[i].py
    x = x + dx * 100 * dt
    y = y + dy * 100 * dt
    -- Collisions with map edge.
    local collidecheck = true
    if (x > screen_width + (border_width - screen_width)/2) or (x < (screen_width - border_width)/2) then
      if downwind then
        dx = dx * -1
      else
        dx = dx * -0.9
      end
      if x < (screen_width - border_width)/2 then
        x = (screen_width - border_width)/2
      else
        x = screen_width + (border_width - screen_width)/2
      end
    end
    if (y > screen_height + (border_height - screen_height)/2) or (y < (screen_height - border_height)/2) then
      if downwind then
        dy = dy * -1
      else
        dy = dy * -0.9
      end
      if (y < (screen_height - border_height)/2) or downwind then
        y = (screen_height - border_height)/2
        if downwind then collidecheck = false end -- stops collisions
      else
        y = screen_height + (border_height - screen_height)/2
      end
    end
    
    -- Collisions with you
    if collidecheck then
      local newstats = particle_arc_bounce(x, dx, px, y, dy, py, you.x, you.dx, you.px, you.y, you.dy, you.py, you.size, you.psize, you.rotate, you.open, dt)
      dx = newstats.dx
      dy = newstats.dy
      x = newstats.x
      y = newstats.y
    end
    --[[
    local distance = dist(you.x, you.y, x, y)--distance from particle to your center
    local pdistance = dist(you.px, you.py, px, py)--distance from particle to your center 1 function call ago
    if (distance <= you.size and pdistance > you.psize) or (distance >= you.size and pdistance < you.psize) then
      --touches if closed
      local out = 0
      if pdistance > you.psize then 
        out = 1
      else
        out = -1
      end
      local collisionangle = (math.atan2(you.y-y, you.x-x) + tau/2) % tau -- between 0 and tau
      local collisionlowangle = (you.rotate - you.open/2) % tau -- bottom
      local collisionhighangle = (you.rotate + you.open/2) % tau -- if collisionlowangle < collisionangle < collisionhighangle, then right half of circle was hit
      if collisionlowangle > tau/2 and collisionhighangle < tau/2 then
        -- collisionangle 0 does not hit
        if collisionlowangle > collisionangle and collisionangle > collisionhighangle then -- lowangle>highangle, of course.  Modulo wraps back here. 
          local newstats = coll(x, y, dx, dy, px, py, collisionangle, dt, out)
          dx = newstats.dx
          dy = newstats.dy
          x = newstats.x
          y = newstats.y
        end
      else
        if collisionlowangle > collisionangle or collisionangle > collisionhighangle then -- lowangle<=highangle here, and modulo does not wrap.
          local newstats = coll(x, y, dx, dy, px, py, collisionangle, dt, out)
          dx = newstats.dx
          dy = newstats.dy
          x = newstats.x
          y = newstats.y
        end
      end
    end
    --]]
    px = x
    py = y
    particles[i].x, particles[i].dx, particles[i].px, particles[i].y, particles[i].dy, particles[i].py = x, dx, px, y, dy, py
  end
end

function coll(x, y, dx, dy, px, py, collisionangle, dt, out)
  -- After a real collision, this function to change the velocity is called
  local expandspeed = 0 -- in effect, we can add the movement of the circle to the point's movement, and subtract afterward
  if not (you.size == maxsize or you.size == minsize) then -- if we are not at the max or min size,
    --then check what buttons we are pressing to find our speed.
    if love.keyboard.isDown("up") then
      expandspeed = 1
    end
    if love.keyboard.isDown("down") then
      expandspeed = expandspeed - 1
    end
  end
  --At this point, expandspeed is the speed at which you are opening or closing.
  local youdx = expandspeed * math.cos(collisionangle) + you.dx -- positive is going right
  local youdy = expandspeed * math.sin(collisionangle) + you.dy -- positive is going down
  -- Here, we could subtrac youdx and youdy to dx and dy to "switch into a different frame of reference," where the circle is stationary(
  local dx = dx - youdx
  local dy = dy - youdy
  --)
  local moveangle = math.atan2(dy, dx) + math.random(-40, 40) * tau / 1000 -- I added randomness here!!!!
  local movespeed = dist(0, 0, dx, dy)
  local newangle = 2 * collisionangle - moveangle + tau/2 --reflect moveangle over collisionangle to find newangle
  -- local newmovespeed = -- use later when circle movement speed is readded
  local newdx = math.cos(newangle) * movespeed
  local newdy = math.sin(newangle) * movespeed
  -- we could have found collision values in a new frame of reference, but we would need to use a frame of reference where the circle is moving.
  -- Because our "correct" frame of reference should have the circle moving, we could add youdx and youdy to every dx and dy.(
  newdx = newdx + youdx
  newdy = newdy + youdy
  --)
  -- Use the law of conservation of momentum to calculate the circle's new velocity(
  -- By the law of conservation of momentum, before and after the collision, the dy/dx of the center of mass remains constant.
  local particleddx = (newdx - dx) * particlemass
  local particleddy = (newdy - dy) * particlemass
  you.dx = you.dx - particleddx/you.mass
  you.dy = you.dy - particleddy/you.mass
  --)
  local newx = you.x + math.cos(collisionangle) * (you.size+(1 * out))--sets particle position to 1 outside or inside the circle
  local newy = you.y + math.sin(collisionangle) * (you.size+(1 * out))
  -- use these
  local newstats = {}
  newstats.dx=newdx
  newstats.dy=newdy
  newstats.x=newx
  newstats.y=newy
  --return this dict
  return newstats
end

function love.draw()
  local x = you.x
  local y = you.y
  local offx = you.x - screen_width/2
  local offy = you.y - screen_height/2
  local screentransform = love.math.newTransform(-offx, -offy)
  love.graphics.push()
    love.graphics.applyTransform(screentransform)
    love.graphics.setColor(50/256, 205/256, 50/256)
    love.graphics.arc("line", "open", x, y, you.size, (you.rotate - you.open/2) + tau, (you.rotate + you.open/2), 80)
    if you.open < tau/16 then -- if you are almost fully closed, then
      love.graphics.line(x + you.size * math.cos(you.rotate), y + you.size * math.sin(you.rotate), x + (you.size * 9/8) * math.cos(you.rotate), y + (you.size * 9/8) * math.sin(you.rotate)) -- draw this helpful line to show you how much you are rotated
    end
    love.graphics.setColor(1, 0.4, 0.9)
    for i = 1, particlenum do
      love.graphics.points(particles[i].x, particles[i].y)
    end
    love.graphics.setColor(1,1,1)
    love.graphics.rectangle("line", (screen_width - border_width)/2, (screen_height - border_height)/2, border_width, border_height)
  love.graphics.pop()
  --Draw a minimap:
  love.graphics.setColor(0, 0, 0)
  love.graphics.rectangle("fill", 0, 0, screen_width/10, screen_height/10)
  --A black area to render the minimap has been drawn
  heiratio = border_height/screen_height
  widratio = border_width/screen_width
  heiwidratio = heiratio/widratio
  widheiratio = 1/heiwidratio
  local scaler = 0
  if heiwidratio > 1 then
    -- (screen_width/2, (screen_height - border_height)/2) -> (screen_width/20, screen_height/100)
    -- (screen_width/2, (screen_height + border_height)/2) -> (screen_width/20, 9 * screen_height/100)
    scaler = (9 * screen_height)/(100 * border_height)
  else
    scaler = (9 * screen_width)/(100 * border_width)
  end
  local minitransform = love.math.newTransform(screen_width/20 - (screen_width * scaler/2), screen_height/100 - ((screen_height - border_height) * scaler/2), 0, scaler)
  love.graphics.push()
    love.graphics.applyTransform(minitransform)
    love.graphics.setColor(1,1,1)
    love.graphics.rectangle("line", (screen_width - border_width)/2, (screen_height - border_height)/2, border_width, border_height)
    love.graphics.setColor(50/256, 205/256, 50/256)
    love.graphics.arc("line", "open", x, y, you.size, (you.rotate - you.open/2) + tau, (you.rotate + you.open/2), 80)
    --Draw particles: optional
    love.graphics.setColor(1, 0.4, 0.9)
    for i = 1, math.min(particlenum, 500) do
      love.graphics.points(particles[i].x, particles[i].y)
    end
  love.graphics.pop()
  --A rectangle representing the borders has been drawn, and you have been drawn in the minimap
end

function dist(x1, y1, x2, y2)
  return math.sqrt((x1-x2)^2+(y1-y2)^2)
end

function particle_arc_bounce(x, dx, px, y, dy, py, arcx, arcdx, arcpx, arcy, arcdy, arcpy, arcsize, arcpsize, arcrotate, arcopen, dt) -- Can be adapted for circles
  local distance = dist(arcx, arcy, x, y)--distance from particle to your center
  local pdistance = dist(arcpx, arcpy, px, py)--distance from particle to your center 1 function call ago
  if (distance <= arcsize and pdistance > arcpsize) or (distance >= arcsize and pdistance < arcpsize) then
    --touches if closed
    local out = 0
    if pdistance > arcpsize then 
      out = 1
    else
      out = -1
    end
    local collisionangle = (math.atan2(arcy-y, arcx-x) + tau/2) % tau -- between 0 and tau
    local collisionlowangle = (arcrotate - arcopen/2) % tau -- bottom
    local collisionhighangle = (arcrotate + arcopen/2) % tau -- if collisionlowangle < collisionangle < collisionhighangle, then right half of circle was hit
    if collisionlowangle > tau/2 and collisionhighangle < tau/2 then
      -- collisionangle 0 does not hit
      if collisionlowangle > collisionangle and collisionangle > collisionhighangle then -- lowangle>highangle, of course.  Modulo wraps back here. 
        local newstats = coll(x, y, dx, dy, px, py, collisionangle, dt, out)
        return newstats
      end
    else
      if collisionlowangle > collisionangle or collisionangle > collisionhighangle then -- lowangle<=highangle here, and modulo does not wrap.
        local newstats = coll(x, y, dx, dy, px, py, collisionangle, dt, out)
        return newstats
      end
    end
  end
  -- We did not have a collision, so we return old values
  local newstats = {}
  newstats.x = x
  newstats.y = y
  newstats.dx = dx
  newstats.dy = dy
  return newstats
end

function love.keypressed(key)
  if key == "escape" then
    love.event.quit()
  end
  if key == "z" then
    for i = 1, particlenum do
      currentdict = particles[i]
      currentdict.dx = currentdict.dx*2/3
      currentdict.dy = currentdict.dy*2/3
      particles[i]=currentdict -- So, particles is a list of dictionaries.
    end
  end
end