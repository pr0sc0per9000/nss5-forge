/* NSS5 mod loader launcher. Runs from Mods\core, started by the winmm anchor in NSS5.exe.
 *
 * On the player's first click of Play it builds our game from the shipped stripped exe and
 * their own NSS5.exe (no toolchain, about a second), copies the Steam and audio DLLs it needs
 * next to itself, and writes a settings file. A small progress window shows what it is doing
 * and closes the moment the game window appears. Then it waits for the game and exits with the
 * game's code, so the anchor and Steam see the session end.
 *
 * GUI subsystem: no console. Build with -mwindows. (GitHub auto-update is added in update.c.)
 */
#define _WIN32_WINNT 0x0501
#define _WIN32_IE 0x0400
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <commctrl.h>
#include <stdio.h>
#include "forge_core.h"
#include "update.h"

#define PATHMAX 1024
#define WM_PROGRESS (WM_APP + 1)   /* wParam = percent, lParam = (wchar_t*) status (owned) */
#define WM_HIDEUI   (WM_APP + 2)
#define WM_DONE     (WM_APP + 3)   /* wParam = exit code */

static HWND g_win, g_bar, g_text;
static HANDLE g_heap;
static wchar_t g_core[PATHMAX], g_root[PATHMAX];
static DWORD g_exit;

static void progress(int pct, const wchar_t *msg)
{
    wchar_t *copy = HeapAlloc(g_heap, 0, (wcslen(msg) + 1) * sizeof(wchar_t));
    if (copy) wcscpy(copy, msg);
    PostMessageW(g_win, WM_PROGRESS, (WPARAM)pct, (LPARAM)copy);
}

/* ---------------------------------------------------------------- file helpers */

static unsigned char *slurp(const wchar_t *p, size_t *n)
{
    HANDLE f = CreateFileW(p, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING,
                           FILE_FLAG_SEQUENTIAL_SCAN, NULL);
    LARGE_INTEGER sz;
    unsigned char *b;
    DWORD got, done = 0;
    if (f == INVALID_HANDLE_VALUE) return NULL;
    GetFileSizeEx(f, &sz);
    b = HeapAlloc(g_heap, 0, (size_t)sz.QuadPart);
    if (!b) { CloseHandle(f); return NULL; }
    while (done < sz.QuadPart && ReadFile(f, b + done, (DWORD)(sz.QuadPart - done), &got, NULL) && got)
        done += got;
    CloseHandle(f);
    *n = (size_t)sz.QuadPart;
    return b;
}

static int dump(const wchar_t *p, const void *b, size_t n)
{
    DWORD wr;
    HANDLE f = CreateFileW(p, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, 0, NULL);
    int ok;
    if (f == INVALID_HANDLE_VALUE) return 0;
    ok = WriteFile(f, b, (DWORD)n, &wr, NULL) && wr == n;
    CloseHandle(f);
    return ok;
}

static int exists(const wchar_t *p) { return GetFileAttributesW(p) != INVALID_FILE_ATTRIBUTES; }

static int sha_matches(const wchar_t *p, const unsigned char *want32)
{
    char hex[65], wanthex[65];
    int i;
    char u[PATHMAX * 3];
    if (!WideCharToMultiByte(CP_UTF8, 0, p, -1, u, sizeof u, NULL, NULL)) return 0;
    if (!forge_sha_hex(u, hex)) return 0;
    for (i = 0; i < 32; i++) sprintf(wanthex + 2 * i, "%02x", want32[i]);
    return !memcmp(hex, wanthex, 64);
}

/* ---------------------------------------------------------------- setup steps */

static void ensure_dll(const wchar_t *name)
{
    wchar_t dst[PATHMAX], src[PATHMAX];
    _snwprintf(dst, PATHMAX, L"%ls\\%ls", g_core, name);
    if (exists(dst)) return;
    _snwprintf(src, PATHMAX, L"%ls\\%ls", g_root, name);
    CopyFileW(src, dst, FALSE);   /* the player's own file, copied locally; absent is not fatal */
}

static void ensure_settings(void)
{
    wchar_t dir[PATHMAX], file[PATHMAX];
    static const char SETTINGS[] =
        "saveloc=0\r\ndebug=0\r\nopengl=1\r\nfullnames=0\r\nnettimeout=5\r\nport=0\r\nproxy=0\r\n";
    _snwprintf(dir, PATHMAX, L"%ls\\Settings", g_core);
    CreateDirectoryW(dir, NULL);
    _snwprintf(file, PATHMAX, L"%ls\\Settings.txt", dir);
    if (!exists(file)) dump(file, SETTINGS, sizeof SETTINGS - 1);
}

/* Rebuild nss5_forge.exe from the stripped exe and the player's NSS5.exe, unless it is already
   there and correct. Returns 0 ok, else a message in *why. */
static int prepare_game(const char **why)
{
    wchar_t gameexe[PATHMAX], stripped[PATHMAX], manifest[PATHMAX], nss5[PATHMAX], tmp[PATHMAX];
    unsigned char *sbuf, *mbuf, *nbuf;
    size_t slen, mlen, nlen;
    int rc;

    _snwprintf(gameexe, PATHMAX, L"%ls\\nss5_forge.exe", g_core);
    _snwprintf(stripped, PATHMAX, L"%ls\\nss5_forge.exe.stripped", g_core);
    _snwprintf(manifest, PATHMAX, L"%ls\\refill.bin", g_core);
    _snwprintf(nss5, PATHMAX, L"%ls\\NSS5.exe", g_root);

    mbuf = slurp(manifest, &mlen);
    if (!mbuf) { *why = "the loader files are incomplete (refill.bin missing)"; return 1; }
    if (mlen >= 76 && exists(gameexe) && sha_matches(gameexe, mbuf + 8)) {
        HeapFree(g_heap, 0, mbuf);
        return 0;                                   /* already built and current */
    }

    progress(30, L"Preparing New Star Soccer 5 (first run)...");
    sbuf = slurp(stripped, &slen);
    nbuf = slurp(nss5, &nlen);
    if (!sbuf || !nbuf) {
        *why = nbuf ? "the loader files are incomplete (stripped exe missing)"
                    : "cannot read your NSS5.exe next to the loader";
        return 1;
    }
    progress(60, L"Preparing New Star Soccer 5 (first run)...");
    rc = forge_refill(sbuf, slen, nbuf, nlen, mbuf, mlen, why);
    if (rc) return 1;
    progress(85, L"Saving...");
    _snwprintf(tmp, PATHMAX, L"%ls\\nss5_forge.exe.new", g_core);
    if (!dump(tmp, sbuf, slen)) { *why = "cannot write the game exe"; return 1; }
    DeleteFileW(gameexe);
    if (!MoveFileW(tmp, gameexe)) { *why = "cannot replace the game exe"; return 1; }
    HeapFree(g_heap, 0, sbuf); HeapFree(g_heap, 0, nbuf); HeapFree(g_heap, 0, mbuf);
    return 0;
}

/* ---------------------------------------------------------------- run the game */

static int has_window(DWORD pid)
{
    HWND h = NULL;
    while ((h = FindWindowExW(NULL, h, NULL, NULL)) != NULL) {
        DWORD p = 0;
        GetWindowThreadProcessId(h, &p);
        if (p == pid && IsWindowVisible(h)) return 1;
    }
    return 0;
}

static DWORD run_game(void)
{
    wchar_t gameexe[PATHMAX], cmd[PATHMAX];
    STARTUPINFOW si;
    PROCESS_INFORMATION pi;
    DWORD code = 0;
    int i;

    _snwprintf(gameexe, PATHMAX, L"%ls\\nss5_forge.exe", g_core);
    _snwprintf(cmd, PATHMAX, L"\"%ls\"", gameexe);
    ZeroMemory(&si, sizeof si);
    si.cb = sizeof si;
    progress(100, L"Starting...");
    if (!CreateProcessW(gameexe, cmd, NULL, NULL, FALSE, 0, NULL, g_root, &si, &pi))
        return (DWORD)-1;
    /* close the progress window the moment the game puts up its own window */
    for (i = 0; i < 1200; i++) {
        if (WaitForSingleObject(pi.hProcess, 0) == WAIT_OBJECT_0) break;
        if (has_window(pi.dwProcessId)) break;
        Sleep(50);
    }
    PostMessageW(g_win, WM_HIDEUI, 0, 0);
    WaitForSingleObject(pi.hProcess, INFINITE);
    GetExitCodeProcess(pi.hProcess, &code);
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    return code;
}

static DWORD WINAPI worker(LPVOID arg)
{
    const char *why = "ok";
    (void)arg;
    progress(5, L"Checking files...");
    ensure_dll(L"steamstub.dll");
    ensure_dll(L"steam_api.dll");
    ensure_dll(L"OpenAL32.dll");
    ensure_dll(L"wrap_oal.dll");
    ensure_settings();
    update_check(g_core, progress);      /* pull a newer build from GitHub if there is one */
    if (prepare_game(&why)) {
        wchar_t w[1024];
        MultiByteToWideChar(CP_UTF8, 0, why, -1, w, 1024);
        MessageBoxW(g_win, w, L"New Star Soccer 5", MB_ICONERROR | MB_OK);
        PostMessageW(g_win, WM_DONE, 1, 0);
        return 1;
    }
    g_exit = run_game();
    PostMessageW(g_win, WM_DONE, g_exit, 0);
    return 0;
}

/* ---------------------------------------------------------------- window */

static LRESULT CALLBACK wndproc(HWND h, UINT m, WPARAM w, LPARAM l)
{
    switch (m) {
    case WM_PROGRESS:
        SendMessageW(g_bar, PBM_SETPOS, w, 0);
        if (l) { SetWindowTextW(g_text, (wchar_t *)l); HeapFree(g_heap, 0, (void *)l); }
        return 0;
    case WM_HIDEUI:
        ShowWindow(h, SW_HIDE);
        return 0;
    case WM_DONE:
        g_exit = (DWORD)w;
        PostQuitMessage((int)w);
        return 0;
    case WM_CLOSE:
        return 0;                 /* ignore the X: we close ourselves when the game exits */
    }
    return DefWindowProcW(h, m, w, l);
}

int WINAPI WinMain(HINSTANCE inst, HINSTANCE prev, LPSTR cmdline, int show)
{
    INITCOMMONCONTROLSEX icc = { sizeof icc, ICC_PROGRESS_CLASS };
    WNDCLASSEXW wc;
    MSG msg;
    wchar_t self[PATHMAX], *slash;
    int sw = 440, sh = 130, sx, sy;
    RECT wr;
    (void)prev; (void)cmdline; (void)show;

    g_heap = GetProcessHeap();
    GetModuleFileNameW(NULL, self, PATHMAX);
    slash = wcsrchr(self, '\\');
    if (!slash) return 1;
    *slash = 0;
    wcscpy(g_core, self);                 /* <root>\Mods\core */
    wcscpy(g_root, self);
    slash = wcsrchr(g_root, '\\'); if (slash) *slash = 0;   /* <root>\Mods */
    slash = wcsrchr(g_root, '\\'); if (slash) *slash = 0;   /* <root> */

    InitCommonControlsEx(&icc);
    ZeroMemory(&wc, sizeof wc);
    wc.cbSize = sizeof wc;
    wc.lpfnWndProc = wndproc;
    wc.hInstance = inst;
    wc.hCursor = LoadCursorW(NULL, (LPCWSTR)IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszClassName = L"NSS5Launcher";
    RegisterClassExW(&wc);

    SystemParametersInfoW(SPI_GETWORKAREA, 0, &wr, 0);
    sx = (wr.right - wr.left - sw) / 2;
    sy = (wr.bottom - wr.top - sh) / 2;
    g_win = CreateWindowExW(WS_EX_TOPMOST, L"NSS5Launcher", L"New Star Soccer 5",
                            WS_POPUP | WS_CAPTION, sx, sy, sw, sh, NULL, NULL, inst, NULL);
    g_text = CreateWindowExW(0, L"STATIC", L"Starting...", WS_CHILD | WS_VISIBLE,
                             18, 18, sw - 40, 20, g_win, NULL, inst, NULL);
    g_bar = CreateWindowExW(0, PROGRESS_CLASSW, NULL, WS_CHILD | WS_VISIBLE,
                            18, 48, sw - 56, 22, g_win, NULL, inst, NULL);
    SendMessageW(g_bar, PBM_SETRANGE, 0, MAKELPARAM(0, 100));
    ShowWindow(g_win, SW_SHOW);
    UpdateWindow(g_win);

    CreateThread(NULL, 0, worker, NULL, 0, NULL);
    while (GetMessageW(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    return (int)g_exit;
}
