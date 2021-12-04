local events = require "game.utils.events"
local groups = require "game.utils.groups"

local logger = require "ludobits.m.logger"
local log = logger.create("[C]Teleport")

local ENERGY_DRAIN_SM = 1
local ENERGY_DRAIN_MD = 10
local MAX_DISTANCE = 200

local M = {}

local draw_line = function(from, to, color)
  msg.post("@render:", "draw_line", {
    start_point = from,
    end_point = to,
    color = color or vmath.vector4(1, 1, 1, 1)
   })
end

function M.create(bus, config)
  local inst   = {}
  local axis   = vmath.vector3()
  local target = vmath.vector3()

  -- flags
  local is_facing_right = true
  local is_toggled = false

  function inst.update(dt)
    if is_toggled then
      if axis.x ~= 0 or axis.y ~= 0 then
        inst.detectViableTarget()
        draw_line(go.get_position(), target, vmath.vector4(1,0,0,1))
      end
    end
  end

  function inst.detectViableTarget()
    local half_width = config.width * 0.5
    local half_height = config.height * 0.5
    local ray_x = 0
    local top_ray_frac = 1
    local bottom_ray_frac = 1

    if is_facing_right then
      ray_x = half_width
    else
      ray_x = -half_width
    end
    
    -- top
    local top_ray_from   = go.get_position() + vmath.vector3(ray_x, half_height, 0)
    local top_ray_to     = top_ray_from + axis * MAX_DISTANCE
    local top_ray_result = physics.raycast(top_ray_from, top_ray_to, { hash("ground") })
    if top_ray_result then
      top_ray_to   = top_ray_result.position
      top_ray_frac = top_ray_result.fraction
    end
    draw_line(top_ray_from, top_ray_to, vmath.vector4(1, 1, 1, 1))
    
    -- bottom
    local bottom_ray_from   = go.get_position() + vmath.vector3(ray_x, -half_height, 0)
    local bottom_ray_to     = bottom_ray_from + axis * MAX_DISTANCE
    local bottom_ray_result = physics.raycast(bottom_ray_from, bottom_ray_to, { hash("ground") })
    if bottom_ray_result then
      bottom_ray_to   = bottom_ray_result.position
      bottom_ray_frac = bottom_ray_result.fraction
    end
    draw_line(bottom_ray_from, bottom_ray_to, vmath.vector4(1, 1, 1, 1))

    -- calculate viable target..
    local min_frac = math.min(top_ray_frac, bottom_ray_frac)
    min_frac = min_frac * 0.8
    target = go.get_position() + axis * min_frac * MAX_DISTANCE
  end

  ----
  -- Event Handing

  function inst.on_event(event_id, data)
    if     event_id == events.AXIS       then inst.onAxis(data.axis)
    elseif event_id == events.PET_TOGGLE then inst.onToggle(data.is_pet_toggled)
    end
  end

  function inst.onAxis(_axis)
    axis = _axis
    
    -- facing..
    if     axis.x > 0 then is_facing_right = true
    elseif axis.x < 0 then is_facing_right = false
    end
  end

  function inst.onToggle(_is_toggled)
    is_toggled = _is_toggled

    if is_toggled then
      --TODO: slow time
      --bus.send(events.SLOW_TIME)
      -- msg.post("@system:", "set_update_frequency", { frequency = 60 * 24 } )

      -- drain energy..
      -- timer.delay(1, true, function()
      --   bus.send(events.ENERGY, { delta = ENERGY_DRAIN_SM })
      -- end)
    else
      --TODO: normal time
      --bus.send(events.NORMAL_TIME)
      -- msg.post("@system:", "set_update_frequency", { frequency = 60 } )

      -- teleport!
      if axis.x ~= 0 or axis.y ~= 0 then
        bus.send(events.ENERGY, { delta = ENERGY_DRAIN_MD })
        bus.send(events.TELEPORT, { position = target })
      end
    end
  end

  ----

  return inst
end

return M