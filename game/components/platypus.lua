local platypus = require "platypus.platypus"

local events = require "game.utils.events"
local groups = require "game.utils.groups"

local logger = require "ludobits.m.logger"
local log = logger.create("Platypus")

local M = {}

function M.create(bus, config)
	local inst  = {}
	local move_speed = 0
	local jump_speed = 400

	-- flags
	local is_on_ledge = false
	local is_facing_right = true
	local is_sliding = false
  local is_pet_toggled = false

	local plat = platypus.create({
		collisions = {
			separation = platypus.SEPARATION_RAYS,
			groups = {
				[hash("ground")]           = platypus.DIR_ALL,
				[hash("onewayplatform")]   = platypus.DIR_DOWN,
				[hash("ledge_grab_left")]  = platypus.DIR_LEFT,
				[hash("ledge_grab_right")] = platypus.DIR_RIGHT,
			},
			left   = config.rays.left,
			right  = config.rays.right,
			top    = config.rays.top,
			bottom = config.rays.bottom,
		},
		gravity           = -800,
		max_velocity      = 400,
		allow_double_jump = true,
		-- allow_falling_double_jump = true,

		allow_wall_slide = true,
		wall_slide_gravity = -50,

		allow_wall_jump = true,
		wall_jump_power_ratio_x = 0.4,
		wall_jump_power_ratio_y = 0.6,
		
		debug = true
	})

	local release_grab = function(delay)
		msg.post("#trigger_ledge_left", "disable")
		msg.post("#trigger_ledge_right", "disable")
		
		timer.delay(delay, false, function()
			msg.post("#trigger_ledge_left", "enable")
			msg.post("#trigger_ledge_right", "enable")
		end)
	end

	function inst.update(dt)
		if is_sliding then
			if is_facing_right then
				plat.right(move_speed)
			else
				plat.left(move_speed)
			end
    elseif is_pet_toggled then
      -- return
		elseif is_on_ledge then
			return
		end
		
		plat.update(dt)
	end

	function inst.on_event(event_id, data)
		--
		-- Ledge Contact
		if event_id == events.LEDGE_CONTACT then
			is_on_ledge = data.is_on_ledge
		--
		-- Ledge Climbed
		elseif event_id == events.LEDGE_CLIMBED then
			if is_facing_right then
				--TODO: adjust these offset values..
				go.set_position(go.get_position() + vmath.vector3(10, 24, 0))
			else
				--TODO: adjust these offset values..
				go.set_position(go.get_position() + vmath.vector3(-10, 24, 0))
			end
		--
		-- Ledge Drop
		elseif event_id == events.LEDGE_DROP then
			plat.velocity.y = 0
			release_grab(0.25)
		--
		-- Move Right
		elseif event_id == events.AXIS and data.axis.x > 0 then
			is_facing_right = true
			plat.right(move_speed)
		--
		-- Move Left
		elseif event_id == events.AXIS and data.axis.x < 0 then
			is_facing_right = false
			plat.left(move_speed)
		--
		-- Dash
		elseif event_id == events.DASH then
			move_speed = data and data.move_speed or move_speed
		--
		-- Crouch
		elseif event_id == events.CROUCH then
			move_speed = data and data.move_speed or move_speed
		--
		-- Slide
		elseif event_id == events.SLIDE then
			is_sliding = true
			move_speed = data and data.move_speed or move_speed
		--
		-- Stand
		elseif event_id == events.STAND then
			is_sliding = false
			move_speed = data and data.move_speed or move_speed
		--
		-- Ledge Jump
		elseif is_on_ledge and event_id == events.JUMP then
			is_on_ledge = false
			plat.force_jump(jump_speed * 0.8)
		--
		-- Jump
		elseif event_id == events.JUMP then
			plat.jump(jump_speed)
		--
		-- Abort jump
		elseif event_id == events.ABORT_JUMP then
			plat.abort_jump(0.8)
    --
    -- P.E.T.
    elseif event_id == events.PET_TOGGLE then
      is_pet_toggled = data.is_pet_toggled
		--
		-- Teleport!
		elseif event_id == events.TELEPORT then
			go.set_position(data.position)
		end
	end

	function inst.on_message(message_id, message, sender)
		--
		-- Refresh
		if message_id == events.REFRESH then
			move_speed = message.move_speed or move_speed
			jump_speed = message.jump_speed or jump_speed
		--
		-- Trigger
		elseif message_id == events.TRIGGER_RESPONSE then
			if message.group == groups.LEDGE_GRAB_LEFT or message.group == groups.LEDGE_GRAB_RIGHT then
				bus.send(events.LEDGE_CONTACT, { is_on_ledge = message.enter })

				-- log.i("Player", go.get_position())
				-- log.i("Other", go.get_position(message.other_id))

				-- adjust grip position
				if message.enter then
					local xOffset      = 6 * (message.group == groups.LEDGE_GRAB_LEFT and 1 or -1)
					local yOffset      = 20  -- TODO: save somewhere (these are boundingbox sizes)
					local senderPos    = go.get_position() + vmath.vector3(xOffset,yOffset,0)
					local otherPos     = go.get_position(message.other_id)
					local gripOffset   = otherPos - senderPos
					go.set_position(go.get_position() + gripOffset)
				end
			end
		else
			plat.on_message(message_id, message, sender)
			
			if message_id == platypus.GROUND_CONTACT then
				bus.send(events.GROUND_CONTACT)
			elseif message_id == platypus.WALL_CONTACT then
				bus.send(events.WALL_CONTACT)
			elseif message_id == platypus.FALLING then
				bus.send(events.FALLING)
			elseif message_id == platypus.WALL_JUMP then
				bus.send(events.WALL_JUMP)
			elseif message_id == platypus.DOUBLE_JUMP then
				bus.send(events.DBL_JUMP)
			elseif message_id == platypus.WALL_SLIDE then
				bus.send(events.WALL_SLIDE)
			end
		end
	end

	return inst
end

return M