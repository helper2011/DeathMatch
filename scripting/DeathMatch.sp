#include <sourcemod>
#include <cstrike>
#include <sdktools_entinput>
#include <sdktools_functions>

#pragma newdecls required

enum
{
	MENU_MAIN,
	MENU_PISTOLS,
	MENU_GUNS,
	MENU_TOTAL
}

enum
{
	CLIENT_MODE,
	CLIENT_PISTOL,
	CLIENT_GUN,
	CLIENT_CHOSED_PISTOL,
	CLIENT_CHOSED_GUN,
	CLIENT_ENT_GUN,
	CLIENT_ENT_PISTOL,
	CLIENT_ENT_HE,
	CLIENT_RESPAWNTIMER,
	CLIENT_PROTECTTIMER,
	CLIENT_TEAM,
	CLIENT_DATA_INT_TOTAL
}

enum
{
	SET_REMOVE_WEAPON,
	SET_SPAWN_PROTECT_TIME,
	SET_SPAWN_GIVE_HE,
	SET_SPAWN_GIVE_ARMOR,
	SET_RESPAWN_TIME,
	
	SET_TOTAL
}

ConVar ConVars[SET_TOTAL];

Menu Menus[MENU_TOTAL];
int ClientData[MAXPLAYERS + 1][CLIENT_DATA_INT_TOTAL], Settings[SET_TOTAL], m_clrRender;

public Plugin myinfo = 
{
	name		= "DeathMatch",
	version		= "1.0",
	description	= "Another version of DeathMatch mode",
	author		= "hEl",
	url			= ""
};

public void OnPluginStart()
{
	CreateConVar2(SET_SPAWN_PROTECT_TIME, "dm_spawn_protect_time", "0");
	CreateConVar2(SET_RESPAWN_TIME, "dm_respawn_time", "2");
	CreateConVar2(SET_SPAWN_GIVE_HE, "dm_spawn_give_he", "1");
	CreateConVar2(SET_SPAWN_GIVE_ARMOR, "dm_spawn_give_armor", "100");
	CreateConVar2(SET_REMOVE_WEAPON, "dm_remove_weapon", "1");

	m_clrRender = FindSendPropInfo("CCSPlayer", "m_clrRender");
	LoadTranslations("deathmatch.phrases");
	RegConsoleCmd("sm_guns", Command_GunsMenu);
	HookEvent("player_team", OnPlayerTeam);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_spawn", OnPlayerSpawn);
	
	CreateMenus();
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
}

void CreateConVar2(int iSet, const char[] cvarName, const char[] cvarValue)
{
	ConVars[iSet] = CreateConVar(cvarName, cvarValue);
	Settings[iSet] = ConVars[iSet].IntValue;
	ConVars[iSet].AddChangeHook(OnConVarChange);
}

public void OnConVarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	for(int i; i < SET_TOTAL; i++)
	{
		if(cvar == ConVars[i])
		{
			Settings[i] = cvar.IntValue;
			break;
		}
	}
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if(!strcmp(sArgs, "guns", false))
	{
		Command_GunsMenu(client, 0);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}


public Action Command_GunsMenu(int iClient, int iArgs)
{
	if(iClient && !IsFakeClient(iClient))
	{
		Menus[MENU_MAIN].Display(iClient, 0);
	}
}

void CreateMenus()
{
	Menus[MENU_MAIN] = new Menu(MainMenu, MenuAction_Select|MenuAction_Display|MenuAction_DisplayItem|MenuAction_DrawItem);
	Menus[MENU_PISTOLS] = new Menu(PistolsMenu, MenuAction_Select|MenuAction_Display);
	Menus[MENU_GUNS] = new Menu(GunsMenu, MenuAction_Select|MenuAction_Display);
	
	Menus[MENU_MAIN].AddItem("", "New weapons");
	Menus[MENU_MAIN].AddItem("", "Prev weapons");
	Menus[MENU_MAIN].AddItem("", "Only last weapons");
	Menus[MENU_MAIN].AddItem("", "Random weapons");
	Menus[MENU_MAIN].AddItem("", "Only random weapons");


	Menus[MENU_PISTOLS].AddItem("glock",		"Glock");
	Menus[MENU_PISTOLS].AddItem("usp",			"USP");
	Menus[MENU_PISTOLS].AddItem("p228",			"P-228");
	Menus[MENU_PISTOLS].AddItem("deagle",		"Desert Eagle");
	Menus[MENU_PISTOLS].AddItem("elite",		"Elites");
	Menus[MENU_PISTOLS].AddItem("fiveseven",	"Fiveseven");
	Menus[MENU_GUNS].AddItem("m3",				"M3");
	Menus[MENU_GUNS].AddItem("xm1014",			"XM1014");
	Menus[MENU_GUNS].AddItem("mac10",			"MAC-10");
	Menus[MENU_GUNS].AddItem("tmp",				"TMP");
	Menus[MENU_GUNS].AddItem("mp5navy",			"MP5 Navy");
	Menus[MENU_GUNS].AddItem("ump45",			"UMP-45");
	Menus[MENU_GUNS].AddItem("p90",				"P-90");
	Menus[MENU_GUNS].AddItem("galil",			"Galil");
	Menus[MENU_GUNS].AddItem("famas",			"Famas");
	Menus[MENU_GUNS].AddItem("ak47",			"AK-47");
	Menus[MENU_GUNS].AddItem("m4a1",			"M4A1");
	Menus[MENU_GUNS].AddItem("scout",			"Scout");
	Menus[MENU_GUNS].AddItem("sg550",			"SG-550");
	Menus[MENU_GUNS].AddItem("aug",				"AUG");
	Menus[MENU_GUNS].AddItem("awp",				"AWP");
	Menus[MENU_GUNS].AddItem("g3sg1",			"G3SG1");
	Menus[MENU_GUNS].AddItem("sg552",			"SG552");
	Menus[MENU_GUNS].AddItem("m249",			"M249");
}

public int MainMenu(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			char szBuffer[256];
			FormatEx(szBuffer, 256, "%T", "Main menu title", iClient);
			(view_as<Panel>(iItem)).SetTitle(szBuffer);
		}
		case MenuAction_Select:
		{
			if(!IsPlayerAlive(iClient))
				return 0;
			
			ClientData[iClient][CLIENT_MODE] = iItem;
			
			switch(iItem)
			{
				case 0:
				{
					if(!ClientData[iClient][CLIENT_CHOSED_PISTOL])
					{
						Menus[MENU_PISTOLS].Display(iClient, 0);
					}
					else if(!ClientData[iClient][CLIENT_CHOSED_GUN])
					{
						Menus[MENU_GUNS].Display(iClient, 0);
					}
				}
				case 1,2:
				{
					DM_GiveClientWeapon(iClient);
				}
				default:
				{
					DM_GiveClientWeapon(iClient, _, _, true);
				}
			}
		}
		case MenuAction_DrawItem:
		{
			switch(iItem)
			{
				case 0:
				{
					if(ClientData[iClient][CLIENT_CHOSED_GUN] && ClientData[iClient][CLIENT_CHOSED_PISTOL])
					{
						return ITEMDRAW_DISABLED;
					}
				}
				default:
				{
					if(ClientData[iClient][CLIENT_MODE] == iItem && (iItem == 2 || iItem == 4))
					{
						return ITEMDRAW_DISABLED;
					}
				}
			}
		}
		case MenuAction_DisplayItem:
		{
			char szBuffer[256];
			hMenu.GetItem(iItem, "", 0, _, szBuffer, 256);
			FormatEx(szBuffer, 256, "%T", szBuffer, iClient);
			return RedrawMenuItem(szBuffer);
		}
	}
	return 0;
}
public int PistolsMenu(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			char szBuffer[256];
			FormatEx(szBuffer, 256, "%T", "Pistol menu title", iClient);
			(view_as<Panel>(iItem)).SetTitle(szBuffer);
		}
		case MenuAction_Select:
		{
			if(!IsPlayerAlive(iClient))
				return 0;
			
			DM_GiveClientWeapon(iClient, MENU_PISTOLS, iItem);
			ClientData[iClient][CLIENT_CHOSED_PISTOL] = 1;
			
			if(!ClientData[iClient][CLIENT_CHOSED_GUN])
			{
				Menus[MENU_GUNS].Display(iClient, 0);
			}
			
		}
	}
	return 0;
}

public int GunsMenu(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			char szBuffer[256];
			FormatEx(szBuffer, 256, "%T", "Gun menu title", iClient);
			(view_as<Panel>(iItem)).SetTitle(szBuffer);
		}
		case MenuAction_Select:
		{
			if(!IsPlayerAlive(iClient))
				return 0;
			
			DM_GiveClientWeapon(iClient, MENU_GUNS, iItem);
			ClientData[iClient][CLIENT_CHOSED_GUN] = 1;
			
		}
	}
	return 0;
}

public Action CS_OnCSWeaponDrop(int client, int weaponIndex)
{
	if(Settings[SET_REMOVE_WEAPON])
	{
		RequestFrame(OnWeaponDropped, weaponIndex);
	}
}

public void OnWeaponDropped(int weapon)
{
	if(IsValidEntity(weapon) && GetEntPropEnt(weapon, Prop_Data, "m_hOwnerEntity") == -1 && !GetEntProp(weapon, Prop_Data, "m_iHammerID"))
	{
		AcceptEntityInput(weapon, "kill");
	}
}


public void OnPlayerTeam(Event hEvent, const char[] event, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	
	ClientData[iClient][CLIENT_TEAM] = hEvent.GetInt("team");
	
	if(!IsPlayerAlive(iClient))
	{
		StartClientRespawnTimer(iClient);
	}
}

public void OnPlayerDeath(Event hEvent, const char[] event, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	StartClientRespawnTimer(iClient);
}

public void OnPlayerSpawn(Event hEvent, const char[] event, bool bDontBroadcast)
{
	CreateTimer(0.0, Timer_OnClientSpawned, GetClientOfUserId(hEvent.GetInt("userid")));
}

public Action Timer_OnClientSpawned(Handle hTimer, int iClient)
{
	if(!IsClientInGame(iClient) || !IsPlayerAlive(iClient))
		return Plugin_Handled;
	
	ClientData[iClient][CLIENT_CHOSED_GUN] = 
	ClientData[iClient][CLIENT_CHOSED_PISTOL] = 0;
	
	if(Settings[SET_SPAWN_PROTECT_TIME] > 0)
	{
		StartClientProtectTimer(iClient);
		SetEntProp(iClient, Prop_Data, "m_takedamage", 0, 1);
		SetEntData(iClient, m_clrRender, GetEntData(iClient, m_clrRender, 1), 1, true);
		SetEntData(iClient, m_clrRender + 1, 128, 1, true);
		SetEntData(iClient, m_clrRender + 2, GetEntData(iClient, m_clrRender + 2, 1), 1, true);
		SetEntData(iClient, m_clrRender + 3, 128, 1, true);
		SetEntityRenderMode(iClient, RENDER_TRANSTEXTURE);
	}

	if(Settings[SET_SPAWN_GIVE_ARMOR] > 0)
	{
		SetEntProp(iClient, Prop_Send, "m_ArmorValue", Settings[SET_SPAWN_GIVE_ARMOR]);
		SetEntProp(iClient, Prop_Send, "m_bHasHelmet", 1);
		
	}
	if(Settings[SET_SPAWN_GIVE_HE])
	{
		GivePlayerItem(iClient, "weapon_hegrenade");
	}
	if(!IsFakeClient(iClient))
	{
		switch(ClientData[iClient][CLIENT_MODE])
		{
			case 2:
			{
				DM_GiveClientWeapon(iClient);
			}
			case 4:
			{
				DM_GiveClientWeapon(iClient, _, _, true);
			}
			default:
			{
				Menus[MENU_MAIN].Display(iClient, 0);
			}
		}	
	}
	return Plugin_Handled;
}

public void OnClientPutInServer(int iClient)
{
	ResetClientData(iClient);
}

public void OnClientDisconnect(int iClient)
{
	DeleteRespawnClientTimer(iClient);
	DeleteProtectClientTimer(iClient);
	
}

void StartClientRespawnTimer(int iClient)
{
	if(Settings[SET_RESPAWN_TIME] > 0 && !ClientData[iClient][CLIENT_RESPAWNTIMER])
	{
		ClientData[iClient][CLIENT_RESPAWNTIMER] = view_as<int>(CreateTimer(float(Settings[SET_RESPAWN_TIME]), Timer_RespawnClient, iClient));
	}
}

void StartClientProtectTimer(int iClient)
{
	if(!ClientData[iClient][CLIENT_PROTECTTIMER])
	{
		ClientData[iClient][CLIENT_PROTECTTIMER] = view_as<int>(CreateTimer(float(Settings[SET_SPAWN_PROTECT_TIME]), Timer_ProtectClient, iClient));
	}
}

public Action Timer_RespawnClient(Handle hTimer, int iClient)
{
	ClientData[iClient][CLIENT_RESPAWNTIMER] = 0;
	
	if(1 < ClientData[iClient][CLIENT_TEAM] < 4 && !IsPlayerAlive(iClient))
	{
		CS_RespawnPlayer(iClient);
	}
}

public Action Timer_ProtectClient(Handle hTimer, int iClient)
{
	ClientData[iClient][CLIENT_PROTECTTIMER] = 0;
	
	SetEntProp(iClient, Prop_Data, "m_takedamage", 2, 1);
	SetEntData(iClient, m_clrRender, GetEntData(iClient, m_clrRender, 1), 1, true);
	SetEntData(iClient, m_clrRender + 1, 255, 1, true);
	SetEntData(iClient, m_clrRender + 2, GetEntData(iClient, m_clrRender + 2, 1), 1, true);
	SetEntData(iClient, m_clrRender + 3, 255, 1, true);
	SetEntityRenderMode(iClient, RENDER_TRANSTEXTURE);
}

void DeleteRespawnClientTimer(int iClient)
{
	if(ClientData[iClient][CLIENT_RESPAWNTIMER])
	{
		KillTimer(view_as<Handle>(ClientData[iClient][CLIENT_RESPAWNTIMER]));
		ClientData[iClient][CLIENT_RESPAWNTIMER] = 0;
	}
}

void DeleteProtectClientTimer(int iClient)
{
	if(ClientData[iClient][CLIENT_PROTECTTIMER])
	{
		KillTimer(view_as<Handle>(ClientData[iClient][CLIENT_PROTECTTIMER]));
		ClientData[iClient][CLIENT_PROTECTTIMER] = 0;
	}
}



void DM_GiveClientWeapon(int iClient, int iType = -1, int iWeapon = -1, bool bRandom = false)
{
	if(iType == -1)
	{
		DM_GiveClientWeapon(iClient, MENU_GUNS, iWeapon, bRandom);
		DM_GiveClientWeapon(iClient, MENU_PISTOLS, iWeapon, bRandom);
		return;
	}
	
	int iIndex = iType == MENU_PISTOLS ? CLIENT_PISTOL:CLIENT_GUN, iSlot = iType == MENU_GUNS ? 0:1;
	
	if(ClientData[iClient][iType == MENU_PISTOLS ? CLIENT_CHOSED_PISTOL:CLIENT_CHOSED_GUN])
		return;
	
	if(bRandom)
	{
		ClientData[iClient][iIndex] = GetRandomInt(0, (iType == MENU_PISTOLS ? 5:17));
	}
	else if(iWeapon != -1)
	{
		ClientData[iClient][iIndex] = iWeapon;
	}
	else if((ClientData[iClient][iIndex] = ClientData[iClient][iType == MENU_PISTOLS ? CLIENT_PISTOL:CLIENT_GUN]) == -1)
	{
		return;
	}
	
	RemoveClientWeaponBySlot(iClient, iSlot);
	char szBuffer[32];
	Menus[iType].GetItem(ClientData[iClient][iIndex], szBuffer, 32);
	Format(szBuffer, 32, "weapon_%s", szBuffer);
	ClientData[iClient][iType == MENU_PISTOLS ? CLIENT_ENT_PISTOL:CLIENT_ENT_GUN] = GivePlayerItem(iClient, szBuffer);
	
	
}

void RemoveClientWeaponBySlot(int iClient, int iSlot)
{
	int iWeapon = GetPlayerWeaponSlot(iClient, iSlot);
	
	if(iWeapon != -1)
	{
		RemoveClientWeapon(iClient, iWeapon);
	}
}

void RemoveClientWeapon(int iClient, int iWeapon)
{
	RemovePlayerItem(iClient, iWeapon);
	RemoveEntity(iWeapon);
}



void ResetClientData(int iClient)
{
	ClientData[iClient][CLIENT_MODE] = 
	ClientData[iClient][CLIENT_TEAM] = 
	ClientData[iClient][CLIENT_PROTECTTIMER] = 
	ClientData[iClient][CLIENT_RESPAWNTIMER] = 0;
	
	ClientData[iClient][CLIENT_GUN] = 
	ClientData[iClient][CLIENT_PISTOL] = -1;
}