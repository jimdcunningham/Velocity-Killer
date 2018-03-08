AddCSLuaFile()

include( "autorun/shared/sh_velocitykiller.lua" )

net.Receive( "VelocityKillerMessage", function()
	print( net.ReadString() )
end )