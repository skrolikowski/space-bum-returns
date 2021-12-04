local logger = require "ludobits.m.logger"
local log = logger.create("Animator")

local anims = require "game.utils.animations"
local events = require "game.utils.events"

local M = {}

function M.create(url, bus, animations)
	local inst = {}
	local anim_current = nil
	local anim_queue = {}

	-- movement axis
	local axis = vmath.vector3()

	-- flags
	local is_grounded     = false
	local is_on_ledge     = false
	local is_sliding      = false
	local is_climbing     = false
	local is_on_wall      = false
	local is_moving       = false
	local is_dashing      = false
	local is_falling      = false
	local is_flipping     = false
	local is_looking_up   = false
	local is_crouching    = false
	local is_landing      = false
	local is_wall_sliding = false
	----

	local function play(anim_id, cb)
		anim_current = anim_id
		-- log.i("Play",anim_current)

		sprite.play_flipbook(url, animations[anim_id], 
			function(self, message_id, message, sender)
				-- anim_current = nil

				-- post animation..
				if cb then cb() end

				-- pull from queue..
				if #anim_queue > 0 then
					local anim_next = table.remove(anim_queue)
					play(anim_next.anim_id, anim_next.cb)
				end
			end)
	end
	
	function inst.play(anim_id, cb)
		assert(animations[anim_id], ("Unknown animation id %s"):format(tostring(anim_id)))
		if anim_current ~= anim_id then
			play(anim_id, cb)
		end
	end

	function inst.play_next(anim_id, cb)
		assert(animations[anim_id], ("Unknown animation id %s"):format(tostring(anim_id)))
		table.insert(anim_queue, { anim_id = anim_id, cb = cb })
		play(anim_id, cb)
	end

	----
	
	function inst.onAxis(value)
		axis = vmath.vector3(value)
		-- log.i("onAxis",axis,is_grounded)
		
		-- update flags..
		is_moving     = axis.x ~= 0
		is_looking_up = is_grounded and axis.y < 0 and not is_moving
		is_crouching  = is_grounded and axis.y > 0
		is_crawling   = is_crouching and is_moving
		
		-- disable dash..
		if not is_moving then
			is_dashing = false
			bus.send(events.SLOW)
		end

		-- exit on axis-lock..
		if is_on_ledge or is_sliding then
			return
		end

		if axis.x > 0 then
			-- flip sprite..
			sprite.set_hflip("#sprite", false)

			-- flip ledge trigger..
			msg.post("#trigger_ledge_left", "disable")
			msg.post("#trigger_ledge_right", "enable")
		elseif axis.x < 0 then
			-- flip sprite..
			sprite.set_hflip("#sprite", true)
				
			-- flip ledge trigger..
			msg.post("#trigger_ledge_left", "enable")
			msg.post("#trigger_ledge_right", "disable")
		end
	end

	function inst.onGrounded()
		is_grounded     = true
		is_falling      = false
		is_landing      = true
		is_flipping     = false
		is_wall_sliding = false
	end

	function inst.onWallContact()
		-- 
	end

	function inst.onLedgeContact(on_ledge)
		is_on_ledge = on_ledge
	end

	function inst.onLedgeClimb()
		is_climbing = true
	end

	function inst.onLedgeClimbed()
		is_climbing = false
		bus.send(events.LEDGE_CLIMBED)
	end

	function inst.onFalling()
		is_grounded = false
		is_falling  = true
	end

	function inst.onDash()
		is_dashing = true
	end

	function inst.onSlide()
		is_sliding = true
	end

	function inst.onCrouch()
		is_crouching = true
	end
	
	function inst.onStand()
		is_sliding   = false
		is_crouching = false
	end
	
	function inst.onJump()
		is_grounded = false
		is_falling  = false
	end

	function inst.onDblJump()
		is_flipping = true
	end

	function inst.onWallSlide()
		is_wall_sliding = true
	end

	function inst.onWallJump()
		is_wall_sliding = false
	end

	----

	function inst.update(dt)
		if is_grounded then
			if     is_crawling   then inst.play(anims.CRAWL)
			elseif is_sliding    then inst.play(anims.SLIDE)
			elseif is_dashing    then inst.play(anims.DASH)
			elseif is_moving     then inst.play(anims.WALK)
			elseif is_crouching  then inst.play(anims.CROUCH)
			elseif is_looking_up then inst.play(anims.LOOK_UP)
			elseif is_landing    then inst.play(anims.LAND, function() is_landing = false end)
			elseif not is_moving then inst.play(anims.IDLE)
			end
		elseif is_climbing then
			inst.play(anims.CLIMB, function() inst.onLedgeClimbed() end)
		elseif is_on_ledge then
			inst.play(anims.HANG)
		elseif is_wall_sliding then
			inst.play(anims.WALL_SLIDE)
		else
			if     is_flipping then inst.play(anims.FLIP)
			elseif is_falling  then inst.play(anims.FALL)
			else inst.play(anims.JUMP)
			end
		end
	end
	
	function inst.on_event(event_id, data)
		--
		-- Animation FSM
		--

		if     event_id == events.AXIS           then inst.onAxis(data.axis)
		elseif event_id == events.DASH           then inst.onDash()
		elseif event_id == events.STAND          then inst.onStand()
		elseif event_id == events.SLIDE          then inst.onSlide()
		elseif event_id == events.GROUND_CONTACT then inst.onGrounded()
		elseif event_id == events.WALL_CONTACT   then inst.onWallContact()
		elseif event_id == events.LEDGE_CONTACT  then inst.onLedgeContact(data.is_on_ledge)
		elseif event_id == events.LEDGE_CLIMB    then inst.onLedgeClimb()
		elseif event_id == events.FALLING        then inst.onFalling()
		elseif event_id == events.JUMP           then inst.onJump()
		elseif event_id == events.DBL_JUMP       then inst.onDblJump()
		elseif event_id == events.WALL_SLIDE     then inst.onWallSlide()
		elseif event_id == events.WALL_JUMP      then inst.onWallJump()
		end
	end

	return inst
end

return M