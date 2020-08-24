#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <multicolors>

#pragma semicolon 1
#pragma newdecls required

int Digerel = 2;
int Endleme;
int m_flNextSecondaryAttack = -1;
ConVar ConVar_NSE_T;
Handle Timer_Event;

public Plugin myinfo =
{
	name = "Awp Noscope Event",
	author = "ByDexter",
	description = "",
	version = "1.0",
	url = "https://steamcommunity.com/id/ByDexterTR/"
}

public void OnPluginStart()
{
	ConVar_NSE_T = CreateConVar("sm_nsevent_timer", "180.0", "Kaç saniyede bir oylama yapsın");
	m_flNextSecondaryAttack = FindSendPropInfo("CBaseCombatWeapon", "m_flNextSecondaryAttack");
	HookEvent("round_end", Control_REnd);
	HookEvent("round_start", Control_RStart);
	AutoExecConfig(true, "noscopevent", "ByDexter");
}

public void OnMapStart()
{
	Timer_Event = CreateTimer(ConVar_NSE_T.FloatValue, EventVoteStart, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void OnMapEnd()
{
	delete Timer_Event;
}

public Action EventVoteStart(Handle timer, any data)
{
	VoteYaptirma();
}

void VoteYaptirma()
{
	if (IsVoteInProgress())
	{
		return;
	}
 
	Menu menu = new Menu(Handle_VoteMenu);
	menu.SetTitle("<-- NoScope Turu? -->");
	menu.AddItem("yes", "--> Evet <--");
	menu.AddItem("no", "--> Hayır <--");
	menu.ExitButton = false;
	menu.DisplayVoteToAll(20);
}

public int Handle_VoteMenu(Menu menu, MenuAction action, int param1,int param2)
{
	if (action == MenuAction_End)
	{
		if(Digerel == 2)
		{
			Timer_Event = CreateTimer(ConVar_NSE_T.FloatValue, EventVoteStart, _, TIMER_FLAG_NO_MAPCHANGE);
			CPrintToChatAll("{darkred}[ByDexter] {green}%d saniye {default}sonra tekrar oylama yapılacak", ConVar_NSE_T.IntValue);
		}
		delete menu;
	} 
	else if (action == MenuAction_VoteEnd) 
	{
		/* 0=yes, 1=no */
		if (param1 == 0)
		{
			delete Timer_Event;
			CPrintToChatAll("{darkred}[ByDexter] {green}Diğer tur {default}noscope turu olacaktır");
			Digerel = 1;
		}
		if (param1 == 1)
		{
			CPrintToChatAll("{darkred}[ByDexter] {green}Noscope turu {default}istenmedi.");
			Digerel = 2;
		}
	}
}

void SilahlariSil(int client)
{
	for(int j = 0; j < 5; j++)
	{
		int weapon = GetPlayerWeaponSlot(client, j);
		if(weapon != -1)
		{
			RemovePlayerItem(client, weapon);
			RemoveEdict(weapon);						
		}
	}
	GivePlayerItem(client, "weapon_awp");
	GivePlayerItem(client, "weapon_knife");
}

public Action OnPreThink(int client)
{
	SetNoScope(GetPlayerWeaponSlot(client, 0));
}

void SetNoScope(int weapon)
{
	if (IsValidEdict(weapon))
	{
		char classname[MAX_NAME_LENGTH];
		if (GetEdictClassname(weapon, classname, sizeof(classname))
			 || StrEqual(classname[7], "ssg08") || StrEqual(classname[7], "aug")
			 || StrEqual(classname[7], "sg550") || StrEqual(classname[7], "sg552")
			 || StrEqual(classname[7], "sg556") || StrEqual(classname[7], "awp")
			 || StrEqual(classname[7], "scar20") || StrEqual(classname[7], "g3sg1"))
		{
			SetEntDataFloat(weapon, m_flNextSecondaryAttack, GetGameTime() + 1.0);
		}
	}
}

public Action Control_RStart(Handle event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++) 
	if(Digerel == 1 && IsClientInGame(i) && !IsFakeClient(i))
	{
		Endleme = 1;
		SDKHook(i, SDKHook_PreThink, OnPreThink);
		SilahlariSil(i);
		CPrintToChatAll("{darkred}[ByDexter] {green}Noscope turu {default}başlıyor");
	}
}

public Action Control_REnd(Handle event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++) 
	if(Endleme && IsClientInGame(i) && !IsFakeClient(i))
	{
		Endleme = 0;
		Digerel = 2;
		SDKUnhook(i, SDKHook_PreThink, OnPreThink);
		Timer_Event = CreateTimer(ConVar_NSE_T.FloatValue, EventVoteStart, _, TIMER_FLAG_NO_MAPCHANGE);
		CPrintToChatAll("{darkred}[ByDexter] {green}%d saniye {default}sonra tekrar oylama yapılacak", ConVar_NSE_T.IntValue);
	}
}

public void OnAutoConfigsBuffered()
{
    CreateTimer(3.0, awpcontrol);
}

public Action awpcontrol(Handle timer)
{
    char filename[512];
    GetPluginFilename(INVALID_HANDLE, filename, sizeof(filename));
    char mapname[PLATFORM_MAX_PATH];
    GetCurrentMap(mapname, sizeof(mapname));
    if (StrContains(mapname, "awp_", false) == -1)
    {
        ServerCommand("sm plugins unload %s", filename);
    }
    return Plugin_Stop;
}