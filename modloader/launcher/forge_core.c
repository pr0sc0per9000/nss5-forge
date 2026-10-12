#include "forge_core.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

/* ---------------------------------------------------------------- sha256 */

typedef struct { unsigned int h[8]; unsigned char buf[64]; unsigned long long len; int n; } sha256_t;

static const unsigned int K[64] = {
    0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
    0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
    0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
    0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
    0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
    0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
    0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
    0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2};

#define ROR(x, n) (((x) >> (n)) | ((x) << (32 - (n))))

static void sha_block(sha256_t *s, const unsigned char *p)
{
    unsigned int w[64], a, b, c, d, e, f, g, h, t1, t2;
    int i;
    for (i = 0; i < 16; i++) w[i] = p[4*i] << 24 | p[4*i+1] << 16 | p[4*i+2] << 8 | p[4*i+3];
    for (; i < 64; i++)
        w[i] = (ROR(w[i-2],17) ^ ROR(w[i-2],19) ^ (w[i-2]>>10)) + w[i-7]
             + (ROR(w[i-15],7) ^ ROR(w[i-15],18) ^ (w[i-15]>>3)) + w[i-16];
    a=s->h[0]; b=s->h[1]; c=s->h[2]; d=s->h[3]; e=s->h[4]; f=s->h[5]; g=s->h[6]; h=s->h[7];
    for (i = 0; i < 64; i++) {
        t1 = h + (ROR(e,6)^ROR(e,11)^ROR(e,25)) + ((e&f)^(~e&g)) + K[i] + w[i];
        t2 = (ROR(a,2)^ROR(a,13)^ROR(a,22)) + ((a&b)^(a&c)^(b&c));
        h=g; g=f; f=e; e=d+t1; d=c; c=b; b=a; a=t1+t2;
    }
    s->h[0]+=a; s->h[1]+=b; s->h[2]+=c; s->h[3]+=d; s->h[4]+=e; s->h[5]+=f; s->h[6]+=g; s->h[7]+=h;
}

static void sha_init(sha256_t *s)
{
    static const unsigned int iv[8] = {0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,
                                       0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19};
    memcpy(s->h, iv, sizeof iv); s->len = 0; s->n = 0;
}

static void sha_update(sha256_t *s, const unsigned char *p, size_t n)
{
    s->len += n;
    while (n--) { s->buf[s->n++] = *p++; if (s->n == 64) { sha_block(s, s->buf); s->n = 0; } }
}

static void sha_final(sha256_t *s, sha_t *out)
{
    unsigned long long bits = s->len * 8;
    unsigned char pad = 0x80, len[8];
    int i;
    sha_update(s, &pad, 1);
    pad = 0;
    while (s->n != 56) sha_update(s, &pad, 1);
    for (i = 0; i < 8; i++) len[i] = (unsigned char)(bits >> (56 - 8 * i));
    sha_update(s, len, 8);
    for (i = 0; i < 8; i++) {
        out->b[4*i]   = s->h[i] >> 24; out->b[4*i+1] = s->h[i] >> 16;
        out->b[4*i+2] = s->h[i] >> 8;  out->b[4*i+3] = s->h[i];
    }
}

void forge_sha256(const void *data, size_t n, sha_t *out)
{
    sha256_t s; sha_init(&s); sha_update(&s, data, n); sha_final(&s, out);
}

int forge_sha_hex(const char *path, char hex[65])
{
    static unsigned char chunk[65536];
    sha256_t s; sha_t out; size_t got; int i;
    FILE *f = fopen(path, "rb");
    if (!f) return 0;
    sha_init(&s);
    while ((got = fread(chunk, 1, sizeof chunk, f)) > 0) sha_update(&s, chunk, got);
    fclose(f);
    sha_final(&s, &out);
    for (i = 0; i < 32; i++) sprintf(hex + 2 * i, "%02x", out.b[i]);
    return 1;
}

/* ---------------------------------------------------------------- incbin locator */

#define MAXASSET 64
#define ALIGN 4
typedef struct { size_t start, end; } span_t;

static int u32(const unsigned char *p) { return p[0] | p[1]<<8 | p[2]<<16 | p[3]<<24; }

/* Find each Incbin asset's byte range in `d`, in source order. Mirrors forge/incbin.py. */
static int incbin_spans(const unsigned char *d, size_t n, span_t *out, int max)
{
    size_t hdrs[MAXASSET]; unsigned lns[MAXASSET];
    int count = 0, i, j;
    size_t k;
    for (k = 0; k + 6 <= n; k++) {
        if (!(d[k]=='I' && d[k+1]==0 && d[k+2]=='n' && d[k+3]==0 && d[k+4]=='c' && d[k+5]==0))
            continue;
        if (k < 12) continue;
        {
            unsigned cls = (unsigned)u32(d + k - 12);
            unsigned refs = (unsigned)u32(d + k - 8);
            unsigned ln = (unsigned)u32(d + k - 4);
            int bad = 0;
            if (refs != 0x7FFFFFFFu || ln == 0 || ln >= 512 || cls < 0x400000 || cls >= 0x1000000)
                continue;
            if (k + (size_t)ln * 2 > n) continue;
            for (j = 0; j < (int)ln; j++)           /* reject if the path has an embedded NUL */
                if (d[k + 2*j] == 0 && d[k + 2*j + 1] == 0) { bad = 1; break; }
            if (bad) continue;
            if (count >= MAXASSET) return -1;
            hdrs[count] = k - 12; lns[count] = ln; count++;
        }
    }
    if (count == 0 || count > max) return -1;
    /* sort by header offset (insertion sort, tiny n) */
    for (i = 1; i < count; i++) {
        size_t h = hdrs[i]; unsigned l = lns[i];
        for (j = i - 1; j >= 0 && hdrs[j] > h; j--) { hdrs[j+1] = hdrs[j]; lns[j+1] = lns[j]; }
        hdrs[j+1] = h; lns[j+1] = l;
    }
    for (i = 0; i < count; i++) {
        size_t start;
        if (i == 0) start = 0;                      /* fixed up below */
        else { start = hdrs[i-1] + 12 + (size_t)lns[i-1] * 2; start = (start + ALIGN - 1) & ~(size_t)(ALIGN - 1); }
        out[i].start = start; out[i].end = hdrs[i];
    }
    { size_t s = out[0].end; while (s > 0 && d[s-1] != 0) s--; out[0].start = s; }
    for (i = 0; i < count; i++) {
        int m = 0;
        while (m < ALIGN - 1 && out[i].end - 1 > out[i].start && d[out[i].end - 1] == 0x90) { out[i].end--; m++; }
    }
    return count;
}

/* ---------------------------------------------------------------- refill */

int forge_refill(unsigned char *stripped, size_t slen,
                 const unsigned char *nss5, size_t nlen,
                 const unsigned char *man, size_t mlen,
                 const char **why)
{
    span_t spans[MAXASSET];
    sha_t got;
    const unsigned char *target_sha, *stub_sha, *rec;
    unsigned nassets;
    int found, i;

    *why = "ok";
    if (mlen < 4 + 4 + 32 + 32 + 4 || memcmp(man, "NSSF", 4) || u32(man + 4) != 1) {
        *why = "bad manifest"; return -1;
    }
    target_sha = man + 8;
    stub_sha = man + 40;
    nassets = (unsigned)u32(man + 72);
    rec = man + 76;
    if (mlen < 76 + (size_t)nassets * 40) { *why = "truncated manifest"; return -2; }

    forge_sha256(stripped, slen, &got);
    if (memcmp(got.b, stub_sha, 32)) { *why = "stripped exe does not match manifest"; return -3; }

    found = incbin_spans(nss5, nlen, spans, MAXASSET);
    if (found < 0 || (unsigned)found != nassets) { *why = "NSS5.exe assets not found"; return -4; }

    for (i = 0; i < (int)nassets; i++) {
        unsigned off = (unsigned)u32(rec + i*40);
        unsigned len = (unsigned)u32(rec + i*40 + 4);
        const unsigned char *asha = rec + i*40 + 8;
        size_t alen = spans[i].end - spans[i].start;
        if (alen != len) { *why = "NSS5.exe asset is the wrong size"; return -5; }
        if ((size_t)off + len > slen) { *why = "manifest offset out of range"; return -6; }
        forge_sha256(nss5 + spans[i].start, alen, &got);
        if (memcmp(got.b, asha, 32)) { *why = "NSS5.exe asset does not match"; return -7; }
        memcpy(stripped + off, nss5 + spans[i].start, len);
    }

    forge_sha256(stripped, slen, &got);
    if (memcmp(got.b, target_sha, 32)) { *why = "refilled exe does not match the target build"; return -8; }
    return 0;
}
