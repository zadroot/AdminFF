/**
* Admin's Friendly Fire Manager by Root
*
* Description:
*   Allow admin's to give or take more or less friendly fire damage (or disable it at all).
*
* Version 1.2
* Changelog & more info at http://goo.gl/4nKhJ
*/

#include <sdkhooks>

// ====[ CONSTANTS ]=========================================================
#define PLUGIN_NAME    "Admin's Friendly Fire Manager"
#define PLUGIN_VERSION "1.2"

// ====[ VARIABLES ]=========================================================
new	Handle:adminff_enable     = INVALID_HANDLE,
	Handle:adminff_give       = INVALID_HANDLE,
	Handle:adminff_take       = INVALID_HANDLE,
	Handle:adminff_customflag = INVALID_HANDLE,
	bool:IsClientAdmin[MAXPLAYERS + 1];

// ====[ PLUGIN ]============================================================
public Plugin:myinfo =
{
	name        = PLUGIN_NAME,
	author      = "Root",
	description = "Changes friendly fire damage for admins",
	version     = PLUGIN_VERSION,
	url         = "http://dodsplugins.com/"
}


/* OnPluginStart()
 *
 * When the plugin starts up.
 * -------------------------------------------------------------------------- */
public OnPluginStart()
{
	// Create ConVars
	CreateConVar("sm_adminff_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY|FCVAR_DONTRECORD);

	adminff_enable     = CreateConVar("sm_adminff_enable",     "1",   "Whether or not enable Admin's Friendly Fire manager",                  FCVAR_PLUGIN, true, 0.0, true, 1.0);
	adminff_give       = CreateConVar("sm_adminff_give",       "0",   "Friendly fire damage multipler.\nSet to 0 to disable FF from admins.", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	adminff_take       = CreateConVar("sm_adminff_take",       "0.5", "Teammates damage multipler.\nSet to 0 to disable damage to admins.",   FCVAR_PLUGIN, true, 0.0, true, 2.0);
	adminff_customflag = CreateConVar("sm_adminff_customflag", "0",   "Manage FF for admins with:\n0 - Generic flag\n1 - Custom flag (6th)",  FCVAR_PLUGIN, true, 0.0, true, 1.0);

	// Create and exec plugin's config from cfg/sourcemod folder
	AutoExecConfig();
}

/* OnClientPostAdminCheck()
 *
 * Called once a client is authorized and fully in-game.
 * -------------------------------------------------------------------------- */
public OnClientPostAdminCheck(client)
{
	// Check whether or not plugin is enabled
	if (GetConVarBool(adminff_enable))
	{
		// Hooks TraceAttack/OnTakeDamage callbacks when player connects
		SDKHook(client, SDKHook_TraceAttack,  OnTraceAttack);
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		IsClientAdmin[client] = CheckPlayerAccess(client);
	}
}

/* OnTraceAttack(SDKHooks)
 *
 * Called when a client takes damage to another and bullets are penetrating.
 * -------------------------------------------------------------------------- */
public Action:OnTraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if (IsValidClient(attacker) && IsValidClient(victim) && GetClientTeam(attacker) == GetClientTeam(victim) && attacker != victim)
	{
		// Checking attacker's admin access
		if (IsClientAdmin[attacker])
		{
			if (!GetConVarFloat(adminff_give))
			{
				// Disable TraceAttack if plugin should block given damage
				return Plugin_Handled;
			}
		}
		else if (IsClientAdmin[victim])
		{
			// Also disable taking damage via hook
			if (!GetConVarFloat(adminff_take))
			{
				return Plugin_Handled;
			}
		}
	}

	// Otherwise if any damage is set - dont handle TraceAttack hook
	return Plugin_Continue;
}

/* OnTakeDamage(SDKHooks)
 *
 * Called when a client takes damage to another.
 * -------------------------------------------------------------------------- */
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	// Make sure both clients is valid and they're a teammates
	if (IsValidClient(attacker) && IsValidClient(victim) && GetClientTeam(attacker) == GetClientTeam(victim) && attacker != victim)
	{
		if (IsClientAdmin[attacker])
		{
			// Multiply given damage
			damage *= GetConVarFloat(adminff_give);
		}

		// Both clients should not have any admin rights though
		else if (IsClientAdmin[victim])
		{
			damage *= GetConVarFloat(adminff_take);
		}

		// We should call Plugin_Changed if damage was actually changed
		return Plugin_Changed;
	}

	// Dont forget to return Plugin_Continue, or damage will not deal
	return Plugin_Continue;
}

/* CheckPlayerAccess()
 *
 * Checks if player got admin access.
 * -------------------------------------------------------------------------- */
bool:CheckPlayerAccess(client)
{
	// If customflag cvar is specified - check admins with 6th custom flag
	if (GetConVarBool(adminff_customflag))
		return (GetAdminFlag(GetUserAdmin(client), Admin_Custom6));
	else /* If not - change FF for admins with a generic abilities */
		return (GetAdminFlag(GetUserAdmin(client), Admin_Generic));
}

/* IsValidClient()
 *
 * Checks if a client is valid.
 * -------------------------------------------------------------------------- */
bool:IsValidClient(client)
{
	// Simply and default client validating check
	return (1 <= client <= MaxClients && IsClientInGame(client)) ? true : false;
}