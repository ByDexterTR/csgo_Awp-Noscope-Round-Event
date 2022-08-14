#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

ConVar time_timer = null;
bool Mod = false, noscope = false;

public Plugin myinfo = 
{
	name = "Awp Noscope Event", 
	author = "ByDexter", 
	description = "", 
	version = "1.1", 
	url = "https://steamcommunity.com/id/ByDexterTR/"
}

public void OnPluginStart()
{
	time_timer = CreateConVar("sm_nsevent_timer", "5", "Kaç dakika arayla oylama yapsın", 0, true, 1.0);
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);
	AutoExecConfig(true, "noscopevent", "ByDexter");
}

public void OnMapStart()
{
	Mod = false;
	char filename[256];
	char mapname[32];
	GetPluginFilename(INVALID_HANDLE, filename, sizeof(filename));
	GetCurrentMap(mapname, sizeof(mapname));
	if (StrContains(mapname, "awp_", false) == -1)
	{
		ServerCommand("sm plugins unload %s.smx", filename);
	}
	CreateTimer(time_timer.IntValue * 60.0, EventVoteStart, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action EventVoteStart(Handle timer)
{
	if (IsVoteInProgress())
	{
		CancelVote();
	}
	
	Menu menu = new Menu(VoteMenu_Callback);
	menu.SetTitle("NoScope Turu?\n ");
	menu.AddItem("0", "--> Evet");
	menu.AddItem("1", "--> Hayır");
	menu.ExitButton = false;
	menu.DisplayVoteToAll(20);
	return Plugin_Stop;
}

public int VoteMenu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			if (!Mod)
			{
				CreateTimer(time_timer.IntValue * 60.0, EventVoteStart, _, TIMER_FLAG_NO_MAPCHANGE);
				PrintToChatAll("[SM] \x10NoScope Turu\x01 istenmedi, \x06%d dakika\x01 sonra tekrar oylama yapılacaktır.", time_timer.IntValue);
			}
			else
			{
				PrintToChatAll("[SM] \x10NoScope Turu\x01 istenildi, diğer tur \x10NoScope \x01oynanacak.");
			}
			delete menu;
		}
		case MenuAction_VoteEnd:
		{
			Mod = view_as<bool>(param1);
		}
	}
	return 0;
}

public Action OnRoundStart(Event event, const char[] name, bool db)
{
	if (Mod)
	{
		noscope = true;
		Mod = false;
		PrintToChatAll("[SM] \x10NoScope turu\x01 başladı.");
	}
	return Plugin_Continue;
}

public Action OnRoundEnd(Event event, const char[] name, bool db)
{
	if (noscope)
	{
		noscope = false;
		Mod = false;
		CreateTimer(time_timer.IntValue * 60.0, EventVoteStart, _, TIMER_FLAG_NO_MAPCHANGE);
		PrintToChatAll("[SM] \x10NoScope Turu\x01 sona erdi, \x06%d dakika\x01 sonra tekrar oylama yapılacaktır.", time_timer.IntValue);
	}
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if (noscope && IsValidClient(client) && buttons & IN_ATTACK2)
	{
		buttons &= ~IN_ATTACK2;
		buttons &= ~IN_ATTACK;
	}
	return Plugin_Continue;
}

bool IsValidClient(int client, bool nobots = true)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
	{
		return false;
	}
	return IsClientInGame(client);
} 