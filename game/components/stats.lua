local events = require "game.utils.events"

local logger = require "ludobits.m.logger"
local log = logger.create("[C]Teleport")

local M = {}

function M.create(bus, config)
	local inst = {}
	local is_targeting = false

	function inst.init()
		--
	end

	function inst.update(dt)
		--
	end

	function inst.on_event(event_id, data)
		--
	end

	function inst.on_message(message_id, message, sender)
		--
	end

	return inst
end