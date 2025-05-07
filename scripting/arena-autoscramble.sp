#include <sourcemod>
#include <sdktools>
#include <tf2>

ConVar g_cvArenaMaxStreak;

int g_iBluWinStreak = 0;
int g_iRedWinStreak = 0;

int g_iTeamManagerBlu;
int g_iTeamManagerRed;

public Plugin myinfo = {
    name = "TF2 Arena Autoscramble Fix",
    author = "Eric Zhang",
    description = "Scramble teams in arena with arena queue off.",
    version = "1.0",
    url = "https://ericaftereric.top"
};

public void OnPluginStart() {
    g_cvArenaMaxStreak = FindConVar("tf_arena_max_streak");
    HookEvent("arena_win_panel", Event_ArenaWin);
}

public void OnMapStart() {
    int teamEnt = -1;
    while ((teamEnt = FindEntityByClassname(teamEnt, "tf_team")) != -1) {
        switch (GetEntProp(teamEnt, Prop_Send, "m_iTeamNum")) {
            case TFTeam_Blue: g_iTeamManagerBlu = teamEnt;
            case TFTeam_Red: g_iTeamManagerRed = teamEnt;
        }
    }
}

void ResetTeamScores() {
    SetEntProp(g_iTeamManagerBlu, Prop_Send, "m_iScore", 0);
    SetEntProp(g_iTeamManagerBlu, Prop_Send, "m_iRoundsWon", 0);
    SetEntProp(g_iTeamManagerRed, Prop_Send, "m_iScore", 0);
    SetEntProp(g_iTeamManagerRed, Prop_Send, "m_iRoundsWon", 0);
}

public void Event_ArenaWin(Event event, const char[] name, bool dontBroadcast) {
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
        if (g_iBluWinStreak >= g_cvArenaMaxStreak.IntValue) {
            arenaScrambleEvent.SetInt("team", TFTeam_Blue);
        }
        if (g_iRedWinStreak >= g_cvArenaMaxStreak.IntValue) {
            arenaScrambleEvent.SetInt("team", TFTeam_Red);
        }
        arenaScrambleEvent.Fire();
        ServerCommand("mp_scrambleteams");
        ResetTeamScores();
        g_iBluWinStreak = 0;
        g_iRedWinStreak = 0;
    }
}
