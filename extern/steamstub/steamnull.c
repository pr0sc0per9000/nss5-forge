/* Null stand-ins for the two STEAMSTUB.DLL exports TProfile.CheckAchievement calls.
   Both calls sit behind g_profile_int43 = 1 (Steam online), which the stripped
   SteamInit never sets, so neither runs. They exist so the body links without
   STEAMSTUB.DLL in the import table. cdecl, as the body's '!Raw Extern declares. */
int GetSteamAchievement(const char *name) { (void)name; return 0; }
void SetSteamAchievement(const char *name) { (void)name; }
