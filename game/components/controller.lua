local state = require "in.state"
local mapper = require "in.mapper"
local triggers = require "in.triggers"

local inputs = require "game.utils.inputs"
local events = require "game.utils.events"

-- local logger = require "ludobits.m.logger"
-- local log = logger.create("[C]Controller")

local SPEED_GROUND = 180
local SPEED_DASH   = 260
local SPEED_CROUCH = 80
local SPEED_SLIDE  = 100
local SPEED_AIR    = 120

local JUMP_SPEED = 400

local COMBO_DELAY = 0.35
local COMBOS = {
	{ event = events.DASH, sequence = { inputs.KEY_LEFT, inputs.KEY_LEFT }, data = { move_speed = SPEED_DASH } },
	{ event = events.DASH, sequence = { inputs.KEY_RIGHT, inputs.KEY_RIGHT }, data = { move_speed = SPEED_DASH } }
}

local M = {}

function M.create(bus)
	local inst = {}
	local last_combo_check = 0
	local combo_sequence = {}

	-- flags
	local is_on_ledge = false

	function inst.init()
		state.acquire()

		-- set bindings for player..?
		mapper.bind(triggers.KEY_W,     inputs.KEY_UP)
		mapper.bind(triggers.KEY_A,     inputs.KEY_LEFT)
		mapper.bind(triggers.KEY_S,     inputs.KEY_DOWN)
		mapper.bind(triggers.KEY_D,     inputs.KEY_RIGHT)
		mapper.bind(triggers.KEY_SPACE, inputs.KEY_JUMP)
    mapper.bind(triggers.KEY_ENTER, inputs.KEY_PET)

		-- bootstrap
		msg.post("#", events.REFRESH, {
			move_speed = SPEED_GROUND,
			jump_speed = JUMP_SPEED
		})
	end

	function inst.update(dt)
		local axis = vmath.vector3()
		
		if state.is_pressed(inputs.KEY_LEFT)  then axis.x = axis.x - 1 end
		if state.is_pressed(inputs.KEY_RIGHT) then axis.x = axis.x + 1 end
		if state.is_pressed(inputs.KEY_UP)    then axis.y = axis.y + 1 end
		if state.is_pressed(inputs.KEY_DOWN)  then axis.y = axis.y - 1 end

		bus.send(events.AXIS, { axis = axis })
	end

	local function processCombo(action_id)
		local now = socket.gettime()
		local last = last_combo_check
		
		last_combo_check = now

		-- clear if delay reached..
		if now - last > COMBO_DELAY then
			combo_sequence = {}
		end

		-- record sequence
		table.insert(combo_sequence, action_id)
	end

	local function triggerCombo()
		for _, combo in ipairs(COMBOS) do
			-- reduce search by matching length..
			if #combo.sequence == #combo_sequence then
				local match = true
				for i=1, #combo.sequence do
					if combo.sequence[i] ~= combo_sequence[i] then
						match = false
						break
					end
				end
				if match then
					return combo.event, combo.data
				end
			end
		end
		return false
	end

	------
	
	function inst.on_input(action_id, action)
		action_id = mapper.on_input(action_id)
		--
		state.on_input(action_id, action)

		-----
		--
		-- On Ledge
		if is_on_ledge then
			if action_id == inputs.KEY_UP and action.pressed then
				bus.send(events.LEDGE_CLIMB)
			elseif action_id == inputs.KEY_DOWN and action.pressed then
				bus.send(events.LEDGE_DROP)
			elseif action_id == inputs.KEY_JUMP and action.pressed then
				bus.send(events.JUMP)
			end
		--
		-- Sliding
		elseif is_sliding then
			if action_id == inputs.KEY_DOWN and action.released then
				bus.send(events.STAND, { move_speed = SPEED_GROUND })
			end
		--
		-- Crouched
		elseif is_crouched then
			if action_id == inputs.KEY_JUMP and action.pressed then
				bus.send(events.SLIDE, { move_speed = SPEED_SLIDE })
			elseif action_id == inputs.KEY_DOWN and action.released then
				bus.send(events.STAND, { move_speed = SPEED_GROUND })
			end
		--
		-- At Rest
		else
			--
			-- Combo..?
			if action_id and action.pressed then
				processCombo(action_id)

				local event_id, data = triggerCombo()
				if event_id then
					bus.send(event_id, data)
					return
				end
			end
			
			--
			-- Crouch
			if action_id == inputs.KEY_DOWN and action.pressed then
				bus.send(events.CROUCH, { move_speed = SPEED_CROUCH })
			--
			-- Jump
			elseif action_id == inputs.KEY_JUMP then
				if     action.pressed  then bus.send(events.JUMP)
				elseif action.released then bus.send(events.ABORT_JUMP)
				end
			--
			-- P.E.T.
      elseif action_id == inputs.KEY_PET then
        if     action.pressed  then bus.send(events.PET_TOGGLE, { is_pet_toggled = true })
				elseif action.released then bus.send(events.PET_TOGGLE, { is_pet_toggled = false })
				end
      end
		end
	end

	function inst.on_event(event_id, data)
		--
		-- Grounded
		if event_id == events.GROUND_CONTACT or event_id == events.SLOW then
			msg.post("#", events.REFRESH, { move_speed = SPEED_GROUND })
		--
		-- On Ledge
		elseif event_id == events.LEDGE_CONTACT then
			is_on_ledge = data.is_on_ledge
		--
		-- Slide
		elseif event_id == events.SLIDE then
			is_sliding = true
			timer.delay(0.5, false, function()
				bus.send(events.STAND, { move_speed = SPEED_GROUND })
			end)
		--
		-- Crouch
		elseif event_id == events.CROUCH then
			is_crouched = true
		--
		-- Stand
		elseif event_id == events.STAND then
			msg.post("#", events.REFRESH, { move_speed = SPEED_GROUND })
			is_crouched = false
			is_sliding  = false
		--
		-- Airborne
		elseif event_id == events.JUMP or event_id == events.FALLING then
			msg.post("#", events.REFRESH, { move_speed = SPEED_AIR })
    end
	end
	
	return inst
end

return M