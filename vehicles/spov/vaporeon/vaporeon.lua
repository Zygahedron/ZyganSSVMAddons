--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/scripts/vore/vsosimple.lua")
require("/vehicles/spov/playable_vso.lua")
--[[

vaporeon plan:

	state chart:
		0   *          sleep
		|   V            |
		0  idle - sit - lay - back
		|   :         \        :
		0   :   sleep - pin - bed - hug
		·   :            V         L
		1  idle - sit - lay - back
		|   :            |
		1   :          sleep
		·   :
		2  idle - sit - lay - sleep

	(struggling not included in chart, everything in full has it)

	todo:
	- pills to control the chance of entering/leaving a desired state (and states leading toward it)


	eventually if I can figure out how:
	- walk around
	- follow nearby player
	- eat automatically if low health, to protect (and heal w/ pill)
	- attack enemies
	- ride on back to control
	  - shlorp in from back -> control from inside?

]]--

-------------------------------------------------------------------------------

p.vsoMenuName = "vappy"

function onForcedReset( )	--helper function. If a victim warps, vanishes, dies, force escapes, this is called to reset me. (something went wrong)

	p.onForcedReset()

end

function onBegin()	--This sets up the VSO ONCE.

	p.onBegin()

	vsoOnInteract( "state_stand", interact_state_stand )

	vsoOnInteract( "state_sit", p.onInteraction )
	vsoOnInteract( "state_lay", p.onInteraction )
	vsoOnInteract( "state_sleep", p.onInteraction )
	vsoOnInteract( "state_back", p.onInteraction )
	vsoOnInteract( "state_bed", p.onInteraction )
	vsoOnInteract( "state_hug", p.onInteraction )
	vsoOnInteract( "state_pinned", p.onInteraction )
	vsoOnInteract( "state_pinned_sleep", p.onInteraction )

	vsoOnBegin( "state_smol", begin_state_smol )
	vsoOnEnd( "state_smol", end_state_smol )

	vsoOnBegin( "state_chonk_ball", begin_state_chonk_ball )
	vsoOnEnd( "state_chonk_ball", end_state_chonk_ball )

end

function onEnd()

	p.onEnd()

end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

p.registerStateScript( "stand", "eat", function( args )
	if p.entityLounging( args.id ) then return end
	if p.visualOccupants == p.maxOccupants then
		sb.logError("[Vappy] Can't eat more than two people!")
		return false
	end
	local i = p.visualOccupants + 1
	vsoSetTarget( i, args.id )
	if p.eat( vsoGetTargetId( i ), i ) then
		vsoMakeInteractive( false )
		p.showEmote("emotehappy")
		vsoVictimAnimSetStatus( "occupant"..i, { "vsoindicatemaw" } );
		return true, function()
			vsoMakeInteractive( true )
			vsoVictimAnimReplay( "occupant"..i, "center", "bodyState")
			vsoSound( "swallow" )
		end
	else
		vsoSetTarget( i, nil )
		return false
	end
end)
p.registerStateScript( "stand", "letout", function( args )
	if p.occupants == 0 then
		sb.logError( "[Vappy] No one to let out!" )
		return false
	end
	local i = args.index
	local victim = vsoGetTargetId( "occupant"..i )

	if not victim then -- could be part of above but no need to log an error here
		return false
	end
	vsoMakeInteractive( false )
	vsoVictimAnimSetStatus( "occupant"..i, { "vsoindicatemaw" } );

	return true, function()
		vsoMakeInteractive( true )
		p.uneat( i )
		vsoApplyStatus( victim, "droolsoaked", 5.0 );
	end
end)
p.registerStateScript( "stand", "bapeat", function()
	local position = p.localToGlobal( p.stateconfig.stand.control.primaryAction.projectile.position )
	if p.visualOccupants < p.maxOccupants then
		local prey = world.entityQuery(position, 2, {
			withoutEntityId = vehicle.entityLoungingIn(p.control.driver),
			includedTypes = {"creature"}
		})
		local entityaimed = world.entityQuery(vehicle.aimPosition(p.control.driver), 2, {
			withoutEntityId = vehicle.entityLoungingIn(p.control.driver),
			includedTypes = {"creature"}
		})
		if #prey > 0 then
			for i = 1, #prey do
				if prey[i] == entityaimed[1] then
					animator.setGlobalTag( "bap", "" )
					p.doTransition( "eat", {id=prey[i]} )
				end
			end
		end
	end
end)

function state_stand()

	p.idleStateChange()
	p.handleBelly()

	if p.control.driving then
		if p.control.keydown[p.control.keys.down] then
			p.movement.downframes = p.movement.downframes + 1
		else
			if p.movement.downframes > 0 and p.movement.downframes < 10 and p.control.notMoving() and p.control.probablyOnGround() then
				p.doTransition( "down" )
			end
			p.movement.downframes = 0
		end
		if p.movement.wasspecial1 ~= true and p.movement.wasspecial1 ~= false and p.movement.wasspecial1 > 0 then
			-- a bit of a hack, prevents the special1 press from activating vappy from also doing this by adding a 10 frame delay before checking if you're pressing it
			p.movement.wasspecial1 = p.movement.wasspecial1 - 1
		elseif p.control.standalone and p.control.keydown[p.control.keys.special1] then
			if not p.movement.wasspecial1 then
				-- vsoAnim( "bodyState", "smolify" )
				vsoEffectWarpOut()
				if p.visualOccupants < 2 then
					p.setState( "smol" )
				else
					vsoNext( "state_chonk_ball" )
				end
			end
			p.movement.wasspecial1 = true
		else
			p.movement.wasspecial1 = false
		end
		if p.control.standalone and p.control.keydown[p.control.keys.special2]  then
			if p.occupants > 0 then
				p.doTransition( "escape", {index=p.occupants} ) -- last eaten
			end
		end
		p.control.drive()
	else
		p.control.doPhysics()
	end

	p.control.updateDriving()

end

function interact_state_stand( targetid )
	if mcontroller.yVelocity() > -5 then
		p.onInteraction( targetid )
	end
end

-------------------------------------------------------------------------------

p.registerStateScript( "sit", "pin", function( args )
	local pinnable = { args.id }
	-- if not interact target or target isn't in front
	if args.id == nil or p.globalToLocal( world.entityPosition( args.id ) )[1] < 3 then
		local pinbounds = vsoRelativeRect( 2.75, -4, 3.5, -3.5 )
		pinnable = world.playerQuery( pinbounds[1], pinbounds[2] )
		if #pinnable == 0 and p.control.driving then
			pinnable = world.npcQuery( pinbounds[1], pinbounds[2] )
		end
	end
	vsoSetTarget( 1, pinnable[1] )
	if #pinnable >= 1 and p.eat( vsoGetTargetId( 1 ), 1 ) then
		vsoVictimAnimSetStatus( "occupant1", {} )
		return true
	else
		return true, nil, p.stateconfig.sit.transitions.down[2] -- normal laydown
	end
end)

state_sit = p.standardState

-----------------------------------------------------------------------------

state_lay = p.standardState

-------------------------------------------------------------------------------

state_sleep = p.standardState

-------------------------------------------------------------------------------

p.registerStateScript( "back", "bed", function( args )
	vsoSetTarget( 1, args.id )
	if p.eat( vsoGetTargetId( 1 ), 1 ) then
		vsoVictimAnimSetStatus( "occupant1", {} );
		return true
	else
		vsoSetTarget( 1, nil )
		return false
	end
end)

function state_back()
	p.standardState()

	-- simulate npc interaction when nearby
	if p.occupants == 0 and p.control.standalone then
		if vsoChance(0.1) then -- every frame, we don't want it too often
			local npcs = world.npcQuery(mcontroller.position(), 4)
			if npcs[1] ~= nil then
				p.doTransition( "bed", {id=npcs[1]} )
			end
		end
	end
end

-------------------------------------------------------------------------------

p.registerStateScript( "bed", "unbed", function()
	vsoSetTarget( 1, nil )
	p.uneat( 1 )
	return true
end)

state_bed = p.standardState

-------------------------------------------------------------------------------

p.registerStateScript( "hug", "absorb", function()
	vsoSound( "slurp" )
	return true, function()
		vsoVictimAnimReplay( "occupant1", "center", "bodyState")
	end
end)

function state_hug()

	p.standardState()

	if p.control.driving and p.control.keydown[p.control.keys.jump] then
		p.doTransition( "absorb" )
	end

end

-------------------------------------------------------------------------------

p.registerStateScript( "pinned", "unpin", function()
	return true, function()
		vsoSetTarget( 1, nil )
		p.uneat( 1 )
	end
end)
p.registerStateScript( "pinned", "absorb", function()
	vsoSound( "slurp" )
	return true, function()
		vsoVictimAnimReplay( "occupant", "center", "bodyState")
	end
end)

function state_pinned()

	p.standardState()
	if p.control.driving then
		p.control.primaryAction() -- lick
	end

	if p.control.driving and p.control.keydown[p.control.keys.jump] then
		p.doTransition( "absorb" )
	end

end

-------------------------------------------------------------------------------

state_pinnedsleep = p.standardState

-------------------------------------------------------------------------------

-- stuff after this point hasn't been migrated yet, only the bare minimum to make things not completely break

function begin_state_smol()
	mcontroller.applyParameters( self.cfgVSO.movementSettings.smol )
end

function state_smol()

	p.idleStateChange()

	-- p.handleBelly()
	if p.occupants > 0 then
		p.bellyEffects()
	end
	-- if p.control.probablyOnGround() and p.control.notMoving() then
	-- 	p.handleStruggles()
	-- end

	if p.control.standalone and p.control.keydown[p.control.keys.special1] then
		if not p.movement.wasspecial1 then
			-- vsoAnim( "bodyState", "unsmolify" )
			vsoEffectWarpIn()
			p.setState( "stand" )
		end
		p.movement.wasspecial1 = true
	else
		p.movement.wasspecial1 = false
	end
	p.control.drive()

	p.control.updateDriving()

end

function end_state_smol()
	mcontroller.applyParameters( self.cfgVSO.movementSettings.default )
end

-------------------------------------------------------------------------------

local CurBallFrame
function roll_chonk_ball()
	if CurBallFrame > 11 then
		CurBallFrame = 0
	elseif CurBallFrame < 0 then
		CurBallFrame = 11
	end
	animator.setGlobalTag("rotationFrame", CurBallFrame)
	vsoAnim( "bodyState", "chonk_ball" )
end


function begin_state_chonk_ball()
	animator.setGlobalTag("rotationFlip", self.vsoCurrentDirection)

	mcontroller.applyParameters( self.cfgVSO.movementSettings.chonk_ball )
	CurBallFrame = 0
	BallLastPosition = mcontroller.position()
	vsoAnim( "bodyState", "chonk_ball" )
	--initCommonParameters()
end

function state_chonk_ball()

	vsoAnim( "legsState", "none" )
	vsoAnim( "tailState", "none" )
	vsoAnim( "headState", "none" )

	if p.occupants > 0 then
		p.bellyEffects()
		-- if not stateQueued() and probablyOnGround() and notMoving() then
		-- 	local escape, who = handleStruggles{ {2, 5}, {5, 15}, {10, 20} }
		-- 	-- local escape, who = handleStruggles{ {1, 1}, {1, 1}, {1, 1} } -- guarantee escape for testing
		-- 	if escape then
		-- 		if p.occupants == 1 then
		-- 			letout( 1 )
		-- 		else
		-- 			if who == 1 then
		-- 				swapOccupants()
		-- 			end
		-- 			letout( 2 )
		-- 		end
		-- 	end
		-- end
	end

	local dx = 0
	local speed = 20
	if p.visualOccupants > 0 then
		speed = 10
	end
	if p.control.keydown[p.control.keys.down] then
		p.movement.downframes = p.movement.downframes + 1
	else
		-- if p.movement.downframes > 0 and p.movement.downframes < 10 and notMoving() and probablyOnGround() then
		-- 	vsoAnim( "bodyState", "sitdown" )
		-- 	nextState( "sit" )
		-- end
		p.movement.downframes = 0
	end
	if p.control.keydown[p.control.keys.special1] then
		if not p.movement.wasspecial1 then
			-- vsoAnim( "bodyState", "unsmolify" )
			vsoEffectWarpIn()
			vsoNext( "state_stand" )
		end
		p.movement.wasspecial1 = true
	else
		p.movement.wasspecial1 = false
	end
	if p.control.keydown[p.control.keys.special2] then
		if p.occupants > 0 then
			-- letout( p.occupants ) -- last eaten
		end
	end

	-- p.movement controls, use vanilla methods because they need to be held
	if p.control.keydown[p.control.keys.left] then
		dx = dx - 1
		if vsoAnimEnd( "bodyState" ) then
			CurBallFrame = CurBallFrame - 1
			roll_chonk_ball()
		end
	end
	if p.control.keydown[p.control.keys.right] then
		dx = dx + 1
		if vsoAnimEnd( "bodyState" ) then
			CurBallFrame = CurBallFrame + 1
			roll_chonk_ball()
		end
	end

	if not p.control.underWater() then
		if p.control.keydown[p.control.keys.lshift] or p.control.keydown[p.control.keys.rshift] then
			speed = 10
		end
		if p.control.keydown[p.control.keys.down] and not probablyOnGround() then
			mcontroller.applyParameters{ ignorePlatformCollision = true }
		else
			mcontroller.applyParameters{ ignorePlatformCollision = false }
		end
	else
		p.movement.jumped = false
		if p.visualOccupants == 2 then
			speed = 10
		end
		if p.control.keydown[p.control.keys.jump] then
			mcontroller.approachYVelocity( 10, 50 )
		else
			mcontroller.approachYVelocity( -10, 50 )
		end
	end
	if not p.control.underWater() then
		p.movement.waswater = false
		mcontroller.setXVelocity( dx * speed )
		if mcontroller.yVelocity() > 0 and p.control.keydown[p.control.keys.jump]  then
			mcontroller.approachYVelocity( -100, world.gravity(mcontroller.position()) )
		else
			mcontroller.approachYVelocity( -200, 2 * world.gravity(mcontroller.position()) )
		end
	else
		p.movement.waswater = true
		mcontroller.approachXVelocity( dx * speed, 50 )
	end
	p.control.updateDriving()
end

function end_state_chonk_ball()
	mcontroller.applyParameters( self.cfgVSO.movementSettings.default )
end
