local M = {}

function M.create(...)
	local inst = {}
	local modules = {}
	local actions = {
		init = {},
		final = {},
		update = {},
		on_message = {},
		on_input = {},
		on_reload = {},
		on_event = {}
	}

	for _, module in pairs({...}) do
		modules[module] = true
		if module.init       then table.insert(actions.init, module.init) end
		if module.final      then table.insert(actions.final, module.final) end
		if module.update     then table.insert(actions.update, module.update) end
		if module.on_message then table.insert(actions.on_message, module.on_message) end
		if module.on_input   then table.insert(actions.on_input, module.on_input) end
		if module.on_reload  then table.insert(actions.on_reload, module.on_reload) end
		if module.on_event   then table.insert(actions.on_event, module.on_event) end
	end

	local function invoke_functions(funcs, ...)
		for _, func in ipairs(funcs) do
			local ok, err = pcall(func, ...)
			if not ok then
				print(err)
			end
		end
	end
	
	local function invoke_all_once(name, ...)
		local invoked = {}
		for _, func in ipairs(actions[name]) do
			if not invoked[func] then
				local ok, err = pcall(func, ...)
				if not ok then
					print(err)
				end
				invoked[func] = true
			end
		end
	end

	function inst.init(...)
		invoke_all_once("init")
	end

	function inst.final(...)
		invoke_all_once("init")
	end

	function inst.update(dt, ...)
		invoke_functions(actions.update, dt, ...)
	end

	function inst.on_message(message_id, message, sender, ...)
		invoke_functions(actions.on_message, message_id, message, sender, ...)
	end

	function inst.on_input(action_id, action, ...)
		invoke_functions(actions.on_input, action_id, action, ...)
	end

	function inst.on_reload(...)
		invoke_functions(actions.on_reload, ...)
	end

	function inst.on_event(event_id, ...)
		invoke_functions(actions.on_event, event_id, ...)
	end
	
	return inst
end

return M