local camera = require "orthographic.camera"
local logger = require "ludobits.m.logger"
local log = logger.create("Camera")

local CAMERA = hash("/camera")

local M = {}

function M.create()
	local inst = {}
	local camera_offset
	local camera_offset_lerp

	function inst.init()
		go.set_position(go.get_position(), CAMERA)

		camera.use_projector(CAMERA, camera.PROJECTOR.FIXED_AUTO)
		camera.set_zoom(CAMERA, 2)
		camera.follow(CAMERA, go.get_id(), { immediate = true })
	end

	function inst.update(dt)
		camera.follow(CAMERA, go.get_id(), { lerp = 0.05 })
	end
	
	return inst
end

return M