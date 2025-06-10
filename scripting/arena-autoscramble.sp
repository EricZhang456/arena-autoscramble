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
    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
}

public void OnMapStart() {
    g_iBluWinStreak = 0;
    g_iRedWinStreak = 0;
    g_bAutoScrambleInProgress = false;
    g_bScrambleNextRound = false;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
    if (g_bScrambleNextRound) {
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
        Event arenaScrambleEvent = CreateEvent("arena_match_maxstreak");
        arenaScrambleEvent.SetInt("streak", g_cvArenaMaxStreak.IntValue);
        arenaScrambleEvent.SetInt("team", g_iBluWinStreak >= g_cvArenaMaxStreak.IntValue ? TFTeam_Blue : TFTeam_Red);
        arenaScrambleEvent.Fire();
        g_bScrambleNextRound = true;
        g_iBluWinStreak = 0;
        g_iRedWinStreak = 0;
    }
}
