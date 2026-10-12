/* Native refill: rebuild our build from the shipped stripped exe and the player's NSS5.exe.
   Same algorithm as modloader/forge/, in C, so the launcher needs no Python. */
#ifndef FORGE_CORE_H
#define FORGE_CORE_H
#include <stddef.h>

typedef struct { unsigned char b[32]; } sha_t;

void forge_sha256(const void *data, size_t n, sha_t *out);
int forge_sha_hex(const char *path, char hex[65]);   /* 1 ok, 0 cannot read */

/* Fill the 11 asset holes in `stripped` (length `slen`, modified in place) with the bytes
   from `nss5` (length `nlen`), checked against the binary manifest `man` (length `mlen`).
   Returns 0 on success, or a negative code; *why gets a short reason on failure. */
int forge_refill(unsigned char *stripped, size_t slen,
                 const unsigned char *nss5, size_t nlen,
                 const unsigned char *man, size_t mlen,
                 const char **why);

#endif
