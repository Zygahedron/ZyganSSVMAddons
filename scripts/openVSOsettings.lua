local oldinit = init
function init()
	oldinit()
	message.setHandler( "openVSOsettings", function(_,_, vso, occupants, maxOccupants, vsoMenuName )
		local pane = root.assetJson("/interface/scripted/"..vsoMenuName.."settings/"..vsoMenuName.."settings.config")
		pane.vso = vso
		pane.occupants = occupants
		pane.maxOccupants = maxOccupants
		player.interact( "ScriptPane", pane, vso )
	end)
	message.setHandler( "openVSOcontrols", function(_,_, vso )
		local pane = root.assetJson("/interface/scripted/vsocontrols/vsocontrols.config")
		player.interact( "ScriptPane", pane, vso )
	end)
	message.setHandler( "loadVSOsettings", function(_,_, vsoMenuName )
		return player.getProperty( vsoMenuName.."Settings" ) or {}
	end)
	message.setHandler( "isLounging", function()
		return player.isLounging(), player.loungingIn()
	end)
	-- override handler from ssvm maybe?? we'll see
	message.setHandler("vsoForcePlayerSit", function( _, _, sourceEntityId, seatindex )
		world.sendEntityMessage( sourceEntityId, "forcedsit", seatindex )
		return player.lounge( sourceEntityId, seatindex );
	end )

	message.setHandler("spawnSmolPrey", function(_,_, species )
		local position = world.entityPosition( entity.id() )
		local settings = player.getProperty( species.."Settings" ) or {}
		world.spawnVehicle( "spov"..species, { position[1], position[2] + 1.5 }, { driver = entity.id(), settings = settings, uneaten = true } )
	end )
end