local logger = require "ludobits.m.logger"
local log = logger.create("Bus")

local M = {}

function M.create()
	local inst = {}
	local listeners = {}

	function inst.listen(cb)
		assert(cb, "Please provide a callback function")
		-- log.i(("Listening for %s"):format(tostring(cb)))
		listeners[cb] = true
	end

	function inst.send(event_id, ...)
		assert(event_id, "Please provide an event_id")
		for cb, _ in pairs(listeners) do
			local ok, err = pcall(cb, event_id, ...)
			if not ok then
				print(err)
			end
		end
	end
	
	return inst
end

return M