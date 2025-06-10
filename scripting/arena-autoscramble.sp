#include <sourcemod>
#include <sdktools>
#include <tf2>

#include <scramble>

ConVar g_cvArenaUseQueue;
ConVar g_cvArenaMaxStreak;

int g_iBluWinStreak = 0;
int g_iRedWinStreak = 0;

bool g_bAutoScrambleInProgress;
bool g_bScrambleNextRound;

public Plugin myinfo = {
    name = "TF2 Arena Autoscramble Fix",
    author = "Eric Zhang",
    description = "Scramble teams in arena with arena queue off.",
    version = "1.0",
    url = "https://ericaftereric.top"
};

public void OnPluginStart() {
    g_cvArenaUseQueue = FindConVar("tf_arena_use_queue");
    g_cvArenaMaxStreak = FindConVar("tf_arena_max_streak");
    HookEvent("arena_win_panel", Event_ArenaWin);
    HookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
    PrecacheScriptSound("Announcer.AM_TeamScrambleRandom");
}

public void OnMapStart() {
    g_iBluWinStreak = 0;
    g_iRedWinStreak = 0;
    g_bAutoScrambleInProgress = false;
    g_bScrambleNextRound = false;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
    if (g_bScrambleNextRound) {
        Event arenaScrambleEvent = CreateEvent("arena_match_maxstreak");
        arenaScrambleEvent.SetInt("streak", g_cvArenaMaxStreak.IntValue);
        arenaScrambleEvent.SetInt("team", g_iBluWinStreak >= g_cvArenaMaxStreak.IntValue ? TFTeam_Blue : TFTeam_Red);
        arenaScrambleEvent.Fire();
        EmitSoundToAll("Announcer.AM_TeamScrambleRandom");
        g_bAutoScrambleInProgress = true;
        ScrambleTeams();
        g_bAutoScrambleInProgress = false;
        ForceRespawn();
        g_bScrambleNextRound = false;
        g_iBluWinStreak = 0;
        g_iRedWinStreak = 0;
    }
}

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast) {
    if (!event.GetBool("silent")) {
        event.BroadcastDisabled = g_bAutoScrambleInProgress;
    }
    return Plugin_Continue;
}

public void Event_ArenaWin(Event event, const char[] name, bool dontBroadcast) {
    if (g_cvArenaUseQueue.BoolValue) {
        return;
    }
    switch (event.GetInt("winning_team")) {
        case TFTeam_Blue: {
            g_iBluWinStreak++;
        }
        case TFTeam_Red: {
            g_iRedWinStreak++;
        }
        default: {
            return;
        }
    }
    if (g_iBluWinStreak >= g_cvArenaMaxStreak.IntValue || g_iRedWinStreak >= g_cvArenaMaxStreak.IntValue) {
        g_bScrambleNextRound = true;
    }
}

void ForceRespawn() {
	int flags = GetCommandFlags("mp_forcerespawnplayers");
	SetCommandFlags("mp_forcerespawnplayers", flags & ~FCVAR_CHEAT);
	ServerCommand("mp_forcerespawnplayers");
	// wait 0.1 seconds before resetting flag or else it would complain
	// about not having sv_cheats 1
	CreateTimer(0.1, Post_RespawnCommandRun, flags);
}

public Action Post_RespawnCommandRun(Handle timer, int flags) {
	SetCommandFlags("mp_forcerespawnplayers", flags);
	return Plugin_Continue;
}
