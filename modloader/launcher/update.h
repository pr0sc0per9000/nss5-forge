/* Pull a newer build from the public GitHub repo when one is published. */
#ifndef UPDATE_H
#define UPDATE_H

typedef void (*progress_fn)(int pct, const wchar_t *msg);

/* Check the repo's latest release against the installed version in `core`; if newer, download
   the stripped exe and manifest into `core`. Never fails the launch: on any network or parse
   error it simply leaves the installed build in place. */
void update_check(const wchar_t *core, progress_fn progress);

#endif
