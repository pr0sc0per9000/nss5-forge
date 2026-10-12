/* Standalone test: refill a stripped exe from NSS5.exe using refill.bin, write the result.
   Usage: refill_test <stripped> <refill.bin> <NSS5.exe> <out> */
#include "forge_core.h"
#include <stdio.h>
#include <stdlib.h>

static unsigned char *slurp(const char *p, size_t *n)
{
    FILE *f = fopen(p, "rb");
    unsigned char *b;
    if (!f) { fprintf(stderr, "cannot open %s\n", p); exit(2); }
    fseek(f, 0, SEEK_END); *n = ftell(f); fseek(f, 0, SEEK_SET);
    b = malloc(*n);
    if (fread(b, 1, *n, f) != *n) { fprintf(stderr, "short read %s\n", p); exit(2); }
    fclose(f);
    return b;
}

int main(int argc, char **argv)
{
    size_t slen, mlen, nlen;
    unsigned char *stripped, *man, *nss5;
    const char *why;
    int rc;
    FILE *o;
    if (argc != 5) { fprintf(stderr, "usage: refill_test <stripped> <refill.bin> <NSS5.exe> <out>\n"); return 2; }
    stripped = slurp(argv[1], &slen);
    man = slurp(argv[2], &mlen);
    nss5 = slurp(argv[3], &nlen);
    rc = forge_refill(stripped, slen, nss5, nlen, man, mlen, &why);
    if (rc) { fprintf(stderr, "refill failed (%d): %s\n", rc, why); return 1; }
    o = fopen(argv[4], "wb");
    fwrite(stripped, 1, slen, o);
    fclose(o);
    printf("refill ok -> %s\n", argv[4]);
    return 0;
}
