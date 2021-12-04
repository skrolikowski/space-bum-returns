local M = {}

-- refresh "sister components" w/ data..
M.REFRESH = hash("refresh")

M.TRIGGER_RESPONSE = hash("trigger_response")

-- stat
M.ENERGY = hash("energy")

-- grounded/movement
M.GROUND_CONTACT = hash("ground_contact")
M.AXIS           = hash("axis")
M.TELEPORT       = hash("teleport")
M.SLOW           = hash("slow")
M.DASH           = hash("dash")
M.CROUCH         = hash("crouch")
M.STAND          = hash("stand")
M.SLIDE          = hash("slide")

-- p.e.t.
M.PET_TOGGLE   = hash("pet_toggle")

-- airborne
M.JUMP           = hash("jump")
M.DBL_JUMP       = hash("dbl_jump")
M.ABORT_JUMP     = hash("abort_jump")
M.FALLING        = hash("falling")

-- ledge
M.LEDGE_CONTACT  = hash("ledge_contact")
M.LEDGE_CLIMB    = hash("ledge_climb")
M.LEDGE_CLIMBED  = hash("ledge_climbed")
M.LEDGE_DROP     = hash("ledge_drop")

-- wall
M.WALL_CONTACT   = hash("wall_contact")
M.WALL_JUMP      = hash("wall_jump")
M.WALL_SLIDE     = hash("wall_slide")
M.WALL_HANG      = hash("wall_hang")
M.WALL_CLIMB     = hash("wall_climb")

return M