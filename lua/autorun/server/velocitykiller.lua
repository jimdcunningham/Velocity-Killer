include( "autorun/shared/sh_velocitykiller.lua" )

VelocityKiller = {}
VelocityKiller.version = "v1.3"
VelocityKiller.enabled = false
VelocityKiller.activated = false
VelocityKiller.data_dir = "velocitykiller/"
VelocityKiller.file_blacklist = VelocityKiller.data_dir .. "blacklist.txt"
VelocityKiller.msg_prefix = "Velocity Killer: "
VelocityKiller.msg_activated = VelocityKiller.msg_prefix .. "Script Activated!"
VelocityKiller.msg_deactivated = VelocityKiller.msg_prefix .. "Script Deactivated!"
VelocityKiller.msg_usage = "Incorrect command usage."
VelocityKiller.msg_commands = "Type \"vk_commands\" for a list of commands."
-- OLD: (Cause: Gamemode \"" .. GAMEMODE_NAME .. "\" is blacklisted.)
VelocityKiller.bl_string = "bhop,deathrun,sandbox"
VelocityKiller.blacklist = {
	"bhop",
	"deathrun",
	"sandbox"
}

local function SendMessage( plys, msg )
	msg = VelocityKiller.msg_prefix .. msg
	if IsValid( plys ) then
		net.Start( "VelocityKillerMessage" )
		net.WriteString( msg )
		net.Send( plys )
		return
	end
	print( msg )
end

function VelocityKiller.GetStatus()
	local status = "The current gamemode \"" .. GAMEMODE_NAME .. "\" is "
	if VelocityKiller.activated then
		status = status .. "not blacklisted"
		if VelocityKiller.enabled then
			status = status .. ", and the script is active."
		else
			status = status .. ", but the script is disabled."
		end
	else
		status = status .. "blacklisted, so the script is deactivated."
	end
	return status
end

function VelocityKiller.SetEnabled( toggle )
	if VelocityKiller.enabled ~= toggle then
		VelocityKiller.enabled = toggle
		if toggle then
			local msg = "CyberScriptz: Velocity Killer Enabled"
			if VelocityKiller.IsOnBlacklist( GAMEMODE_NAME ) then
				msg = msg .. ", but the gamemode \"" .. GAMEMODE_NAME .. "\" is blacklisted!"
			else
				msg = msg .. ", and the script is active."
			end
			print( msg )
		else
			print( "CyberScriptz: Velocity Killer Disabled." )
		end
		return true
	end
	return false
end

function VelocityKiller.SetActivated( toggle, silent )
	if VelocityKiller.activated ~= toggle then
		VelocityKiller.activated = toggle
		if VelocityKiller.enabled and not silent then
			if toggle then
				print( VelocityKiller.msg_activated )
			else
				print( VelocityKiller.msg_deactivated )
			end
		end
		return true
	end
	return false
end

function VelocityKiller.LoadBlacklist()
	VelocityKiller.bl_string = file.Read( VelocityKiller.file_blacklist )
	VelocityKiller.blacklist = {}
	for i, gmname in pairs( string.Split( VelocityKiller.bl_string, "," ) ) do
		table.insert( VelocityKiller.blacklist, gmname )
	end
end

function VelocityKiller.SaveBlacklist()
	local str = ""
	for i, gmname in pairs( VelocityKiller.blacklist ) do
		if i ~= 1 then
			str = str .. ","
		end
		str = str .. gmname
	end
	VelocityKiller.bl_string = str
	file.Write( VelocityKiller.file_blacklist, str )
end

function VelocityKiller.AddToBlacklist( gmname )
	if not VelocityKiller.IsOnBlacklist( gmname ) then
		table.insert( VelocityKiller.blacklist, gmname )
		if GAMEMODE_NAME == gmname then
			VelocityKiller.SetActivated( false )
		end
		VelocityKiller.SaveBlacklist()
		return true
	end
	return false
end

function VelocityKiller.RemoveFromBlacklist( gmname )
	if table.RemoveByValue( VelocityKiller.blacklist, gmname ) then
		if GAMEMODE_NAME == gmname then
			VelocityKiller.SetActivated( true )
		end
		VelocityKiller.SaveBlacklist()
		return true
	end
	return false
end

function VelocityKiller.IsOnBlacklist( gmname )
	return table.HasValue( VelocityKiller.blacklist, gmname )
end

function VelocityKiller.PerformCommand( ply, cmd, args, fullstring )
	if cmd == "vk_commands" then
		SendMessage( ply, "List of Console Commands" )
		SendMessage( ply, "----------------------------" )
		SendMessage( ply, "Permission = [ ] Everyone, [*] Admin, [S] Server" )
		SendMessage( ply, "[S] vk_enabled [0 or 1] - If 0, the script will no longer activate." )
		SendMessage( ply, "[S] vk_speedlimit [0 thru 600+] - Sets the speed at which to start killing velocity. If 0, always kill velocity." )
		SendMessage( ply, "[S] vk_suppressor [0 thru 100] - Sets how soft to slow down players. The higher the number, the softer the impact." )
		SendMessage( ply, "[ ] vk_commands - Retrieve a list of console commands." )
		SendMessage( ply, "[ ] vk_examples - Retrieve a list of command examples." )
		SendMessage( ply, "[ ] vk_status - Retrieve the current status of the script." )
		SendMessage( ply, "[ ] vk_blacklist - Retrieve a list of blacklisted gamemodes." )
		SendMessage( ply, "[*] vk_blacklist add [gamemode] - Add a gamemode to the blacklist." )
		SendMessage( ply, "[*] vk_blacklist remove [gamemode] - Remove a gamemode from the blacklist." )
		return
	elseif cmd == "vk_examples" then
		SendMessage( ply, "Console Command Examples" )
		SendMessage( ply, "----------------------------" )
		SendMessage( ply, "\"vk_enabled 0\" - Forces the script to no longer activate." )
		SendMessage( ply, "\"vk_speedlimit 600\" - Sets the speed limit to 600, which is good for Sandbox." )
		SendMessage( ply, "\"vk_suppressor 50\" - Sets the suppressing speed to 50, which is also good for Sandbox." )
		SendMessage( ply, "\"vk_blacklist add sandbox\" - Adds sandbox to the blacklist." )
		SendMessage( ply, "\"vk_blacklist remove terrortown\" - Removes TTT from the blacklist." )
		return
	elseif cmd == "vk_status" then
		SendMessage( ply, VelocityKiller.GetStatus() )
		return
	elseif cmd == "vk_blacklist" and #args == 0 then
		SendMessage( ply, "Blacklist - \"" .. VelocityKiller.bl_string .. "\"" )
		return
	elseif cmd == "vk_blacklist" and #args == 2 then
		if IsValid( ply ) and not ply:IsAdmin() then
			SendMessage( ply, "You are not allowed to perform the command \"vk_blacklist\"." )
			return
		end
		local request = args[1]:lower()
		local gmname = args[2]:lower()
		if request == "add" then
			if VelocityKiller.AddToBlacklist( gmname ) then
				SendMessage( ply, "Added \"" .. gmname .. "\" to the blacklist." )
			else
				SendMessage( ply, "The blacklist already contains \"" .. gmname .. "\"." )
			end
			return
		elseif request == "remove" then
			if VelocityKiller.RemoveFromBlacklist( gmname ) then
				SendMessage( ply, "Removed \"" .. gmname .. "\" from the blacklist." )
			else
				SendMessage( ply, "The blacklist doesn't contain \"" .. gmname .. "\"." )
			end
			return
		end
	end
	SendMessage( ply, VelocityKiller.msg_usage )
	SendMessage( ply, VelocityKiller.msg_commands )
end

util.AddNetworkString( "VelocityKillerMessage" )
util.AddNetworkString( "VelocityKillerCommand" )

net.Receive( "VelocityKillerCommand", function( len, ply )
	VelocityKiller.PerformCommand( ply, net.ReadString(), net.ReadTable(), net.ReadString() )
end )

if not file.Exists( VelocityKiller.file_blacklist, "DATA" ) then
	file.CreateDir( VelocityKiller.data_dir )
	VelocityKiller.SaveBlacklist()
else
	VelocityKiller.LoadBlacklist()
end

CreateConVar( "vk_enabled", "1", { FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE } )
CreateConVar( "vk_speedlimit", "300", { FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE } )
CreateConVar( "vk_suppressor", "50", { FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE } )

VelocityKiller.enabled = GetConVar( "vk_enabled" ):GetBool()
VelocityKiller.speedlimit = GetConVar( "vk_speedlimit" ):GetInt()
VelocityKiller.suppressor = GetConVar( "vk_suppressor" ):GetInt()

cvars.AddChangeCallback( "vk_enabled", function( convar_name, value_old, value_new )
	VelocityKiller.SetEnabled( tobool( value_new ) )
end )

cvars.AddChangeCallback( "vk_speedlimit", function( convar_name, value_old, value_new )
	value_new = tonumber( value_new )
	if value_new < 0 then
		GetConVar( "vk_speedlimit" ):SetInt( 0 )
		return
	end
	VelocityKiller.speedlimit = value_new
end )

cvars.AddChangeCallback( "vk_suppressor", function( convar_name, value_old, value_new )
	value_new = tonumber( value_new )
	if value_new > 100 then
		GetConVar( "vk_suppressor" ):SetInt( 100 )
		return
	elseif value_new < 0 then
		GetConVar( "vk_suppressor" ):SetInt( 0 )
		return
	end
	VelocityKiller.suppressor = value_new
end )

hook.Add( "OnGamemodeLoaded", "CyberScriptz_VelocityKiller", function()
	if not VelocityKiller.IsOnBlacklist( GAMEMODE_NAME ) then
		VelocityKiller.SetActivated( true, true )
	end
	
	local Old_OnPlayerHitGround = GAMEMODE.OnPlayerHitGround
	function GAMEMODE:OnPlayerHitGround( ply, inWater, onFloater, speed )
		if VelocityKiller.enabled and VelocityKiller.activated then
			local vel = ply:GetVelocity()
			if VelocityKiller.speedlimit == 0 or ( vel.x > VelocityKiller.speedlimit or vel.x < -VelocityKiller.speedlimit or vel.y > VelocityKiller.speedlimit or vel.y < -VelocityKiller.speedlimit ) then
				local suppressor = 1 + (VelocityKiller.suppressor / 100)
				ply:SetVelocity( Vector( -( vel.x / suppressor ), -( vel.y / suppressor ), 0 ) )
			end
		end
		return Old_OnPlayerHitGround( self, ply, inWater, onFloater, speed )
	end
	
	print( VelocityKiller.msg_prefix .. VelocityKiller.version .. " Initialization Complete. Retrieving Status..." )
	print( VelocityKiller.msg_prefix .. VelocityKiller.GetStatus() )
end )