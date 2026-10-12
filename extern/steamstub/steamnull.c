/* Steam for the reconstruction, without STEAMSTUB.DLL in the import table.

   STEAMSTUB.DLL is the game's own Steam wrapper, and Steam only answers when Steam
   started the game (Steam sets SteamAppId for it). So when SteamAppId is set and the
   game's steamstub.dll sits beside the exe, these forward to it. Otherwise they answer
   offline, exactly as the stripped build always did, and nothing loads.

   The real exports are all cdecl (they end in a plain ret), as the '!Raw Extern
   blocks declare. */
#include <windows.h>

static HMODULE steamstub(void)
{
    static HMODULE h;
    static int tried;
    if (!tried) {
        tried = 1;
        if (GetEnvironmentVariableA("SteamAppId", NULL, 0))
            h = LoadLibraryA("steamstub.dll");
    }
    return h;
}

static FARPROC real(const char *name)
{
    return steamstub() ? GetProcAddress(steamstub(), name) : NULL;
}

/* 1 online, 0 offline. -1 when Steam started the game but would not open. */
int OpenSteam(int appid)
{
    int (*f)(int) = (int (*)(int))real("OpenSteam");
    return f ? f(appid) : 0;
}

int GetSteamAchievement(const char *name)
{
    int (*f)(const char *) = (int (*)(const char *))real("GetSteamAchievement");
    return f ? f(name) : 0;
}

void SetSteamAchievement(const char *name)
{
    void (*f)(const char *) = (void (*)(const char *))real("SetSteamAchievement");
    if (f) f(name);
}
