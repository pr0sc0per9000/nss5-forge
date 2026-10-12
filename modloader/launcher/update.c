/* Pull a newer build from the public GitHub repo when one is published.
 *
 * Asks the repo for its releases, reads the newest one's tag, and if it differs from the tag
 * recorded in Mods\core\version.txt, downloads that release's nss5_forge.exe.stripped and
 * refill.bin into Mods\core and records the new tag. The launcher then rebuilds the game from
 * the new stripped exe. Every failure (offline, rate limited, asset missing, bad download) is
 * swallowed: the launch continues on whatever is already installed.
 */
#define _WIN32_WINNT 0x0501
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <wininet.h>
#include <stdio.h>
#include <string.h>
#include "update.h"

#define OWNER_REPO "pr0sc0per9000/nss5-forge"
#define UA L"nss5-mod-loader"
#define MAXRESP (256 * 1024)

static HANDLE heap(void) { return GetProcessHeap(); }

/* GET a URL fully into memory (NUL-terminated). Returns malloc'd buffer or NULL. */
static char *http_get(const wchar_t *url, DWORD cap, DWORD *outlen)
{
    HINTERNET root = InternetOpenW(UA, INTERNET_OPEN_TYPE_PRECONFIG, NULL, NULL, 0);
    HINTERNET h;
    char *buf;
    DWORD total = 0, got;
    if (!root) return NULL;
    h = InternetOpenUrlW(root, url, L"User-Agent: nss5-mod-loader\r\n", (DWORD)-1,
                         INTERNET_FLAG_RELOAD | INTERNET_FLAG_NO_UI | INTERNET_FLAG_SECURE, 0);
    if (!h) { InternetCloseHandle(root); return NULL; }
    buf = HeapAlloc(heap(), 0, cap + 1);
    if (buf) {
        while (total < cap && InternetReadFile(h, buf + total, cap - total, &got) && got)
            total += got;
        buf[total] = 0;
    }
    InternetCloseHandle(h);
    InternetCloseHandle(root);
    if (outlen) *outlen = total;
    return buf;
}

/* Download a URL to a file. Returns bytes written, or -1. */
static long http_to_file(const wchar_t *url, const wchar_t *path)
{
    HINTERNET root = InternetOpenW(UA, INTERNET_OPEN_TYPE_PRECONFIG, NULL, NULL, 0);
    HINTERNET h;
    HANDLE f;
    static char chunk[65536];
    DWORD got, wr;
    long total = 0;
    if (!root) return -1;
    h = InternetOpenUrlW(root, url, L"User-Agent: nss5-mod-loader\r\n", (DWORD)-1,
                         INTERNET_FLAG_RELOAD | INTERNET_FLAG_NO_UI | INTERNET_FLAG_SECURE, 0);
    if (!h) { InternetCloseHandle(root); return -1; }
    f = CreateFileW(path, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, 0, NULL);
    if (f == INVALID_HANDLE_VALUE) { InternetCloseHandle(h); InternetCloseHandle(root); return -1; }
    while (InternetReadFile(h, chunk, sizeof chunk, &got) && got) {
        if (!WriteFile(f, chunk, got, &wr, NULL) || wr != got) { total = -1; break; }
        total += got;
    }
    CloseHandle(f);
    InternetCloseHandle(h);
    InternetCloseHandle(root);
    return total;
}

/* Copy the value of "key":"value" starting at/after p into out. Returns end, or NULL. */
static const char *json_str(const char *p, const char *key, char *out, int cap)
{
    char pat[64];
    const char *q, *s;
    int i = 0;
    _snprintf(pat, sizeof pat, "\"%s\"", key);
    q = strstr(p, pat);
    if (!q) return NULL;
    q = strchr(q + strlen(pat), ':');
    if (!q) return NULL;
    q++;
    while (*q == ' ' || *q == '\t') q++;
    if (*q != '"') return NULL;
    s = ++q;
    while (*s && *s != '"' && i < cap - 1) {
        if (*s == '\\' && s[1]) s++;              /* keep it simple: unescape one char */
        out[i++] = *s++;
    }
    out[i] = 0;
    return s;
}

/* Find a browser_download_url whose value ends with `suffix`, within [p, end). */
static int find_asset(const char *p, const char *end, const char *suffix, wchar_t *out, int cap)
{
    const char *q = p;
    size_t sl = strlen(suffix);
    while ((q = strstr(q, "\"browser_download_url\"")) && q < end) {
        char url[512];
        const char *e = json_str(q, "browser_download_url", url, sizeof url);
        q += 22;
        if (!e) continue;
        {
            size_t ul = strlen(url);
            if (ul >= sl && !memcmp(url + ul - sl, suffix, sl)) {
                MultiByteToWideChar(CP_UTF8, 0, url, -1, out, cap);
                return 1;
            }
        }
    }
    return 0;
}

static void read_file_small(const wchar_t *p, char *out, int cap)
{
    HANDLE f = CreateFileW(p, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, 0, NULL);
    DWORD got = 0;
    out[0] = 0;
    if (f == INVALID_HANDLE_VALUE) return;
    ReadFile(f, out, cap - 1, &got, NULL);
    out[got] = 0;
    while (got && (out[got-1] == '\r' || out[got-1] == '\n' || out[got-1] == ' ')) out[--got] = 0;
    CloseHandle(f);
}

static void write_file_small(const wchar_t *p, const char *s)
{
    HANDLE f = CreateFileW(p, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, 0, NULL);
    DWORD wr;
    if (f == INVALID_HANDLE_VALUE) return;
    WriteFile(f, s, (DWORD)strlen(s), &wr, NULL);
    CloseHandle(f);
}

void update_check(const wchar_t *core, progress_fn progress)
{
    char *resp;
    DWORD len;
    char tag[128], installed[128];
    const char *first_end;
    wchar_t strip_url[512], man_url[512], vpath[1024], tmp1[1024], tmp2[1024], dst1[1024], dst2[1024];

    progress(10, L"Checking for updates...");
    resp = http_get(L"https://api.github.com/repos/" OWNER_REPO L"/releases?per_page=5",
                    MAXRESP, &len);
    if (!resp || len == 0) { if (resp) HeapFree(heap(), 0, resp); return; }

    /* newest release is the first array element; bound the search to it */
    if (!json_str(resp, "tag_name", tag, sizeof tag)) { HeapFree(heap(), 0, resp); return; }
    first_end = strstr(resp + 1, "\"tag_name\"");      /* start of the 2nd release, or NULL */
    if (!first_end) first_end = resp + len;

    /* version.txt is the DISPLAY version the game shows in the menu: always the repo's newest
       release tag, refreshed every boot. Separate from which build is installed. */
    _snwprintf(vpath, 1024, L"%ls\\version.txt", core);
    write_file_small(vpath, tag);

    /* installed.txt records which release our built exe came from, to decide downloads. */
    {
        wchar_t ipath[1024];
        _snwprintf(ipath, 1024, L"%ls\\installed.txt", core);
        read_file_small(ipath, installed, sizeof installed);
        if (installed[0] && !strcmp(installed, tag)) { HeapFree(heap(), 0, resp); return; }
    }

    if (!find_asset(resp, first_end, "nss5_forge.exe.stripped", strip_url, 512) ||
        !find_asset(resp, first_end, "refill.bin", man_url, 512)) {
        HeapFree(heap(), 0, resp);     /* this release is not a mod-loader build; leave as is */
        return;
    }
    HeapFree(heap(), 0, resp);

    progress(15, L"Downloading update...");
    _snwprintf(tmp1, 1024, L"%ls\\nss5_forge.exe.stripped.dl", core);
    _snwprintf(tmp2, 1024, L"%ls\\refill.bin.dl", core);
    if (http_to_file(strip_url, tmp1) <= 0 || http_to_file(man_url, tmp2) <= 8) {
        DeleteFileW(tmp1); DeleteFileW(tmp2);
        return;                        /* download failed: keep the installed build */
    }
    _snwprintf(dst1, 1024, L"%ls\\nss5_forge.exe.stripped", core);
    _snwprintf(dst2, 1024, L"%ls\\refill.bin", core);
    DeleteFileW(dst1); DeleteFileW(dst2);
    if (MoveFileW(tmp1, dst1) && MoveFileW(tmp2, dst2)) {
        wchar_t ipath[1024];
        _snwprintf(ipath, 1024, L"%ls\\installed.txt", core);
        write_file_small(ipath, tag);  /* new build in place; prepare_game rebuilds from it */
    }
}
