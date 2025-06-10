#include <sourcemod>
#include <sdktools>
#include <tf2>

#include <scramble>

ConVar g_cvArenaUseQueue;
ConVar g_cvArenaMaxStreak;

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
    g_bAutoScrambleInProgress = false;
    g_bScrambleNextRound = false;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
    if (g_bScrambleNextRound) {
        Event arenaScrambleEvent = CreateEvent("arena_match_maxstreak");
        arenaScrambleEvent.SetInt("streak", g_cvArenaMaxStreak.IntValue);
        arenaScrambleEvent.SetInt("team", GetTeamScore(TFTeam_Blue) >= g_cvArenaMaxStreak.IntValue ? TFTeam_Blue : TFTeam_Red);
        arenaScrambleEvent.Fire();
        EmitSoundToAll("Announcer.AM_TeamScrambleRandom");
        g_bAutoScrambleInProgress = true;
        ScrambleTeams();
        g_bAutoScrambleInProgress = false;
        g_bScrambleNextRound = false;
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
    if (GetTeamScore(TFTeam_Red) >= g_cvArenaMaxStreak.IntValue
        || GetTeamScore(TFTeam_Blue) >= g_cvArenaMaxStreak.IntValue) {
        g_bScrambleNextRound = true;
    }
}
