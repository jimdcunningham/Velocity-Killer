AddCSLuaFile()

local cmds = {
	"vk_commands",
	"vk_examples",
	"vk_status",
	"vk_blacklist"
}

for i, command in pairs( cmds ) do
	if SERVER then
		concommand.Add( command, function( ply, cmd, args, fullstring )
			VelocityKiller.PerformCommand( ply, cmd, args, fullstring )
		end )
	elseif CLIENT then
		concommand.Add( command, function( ply, cmd, args, fullstring )
			net.Start( "VelocityKillerCommand" )
			net.WriteString( cmd )
			net.WriteTable( args )
			net.WriteString( fullstring )
			net.SendToServer()
		end )
	end
end