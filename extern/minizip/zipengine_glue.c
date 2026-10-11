/*
 * zipengine_glue.c -- the three C helpers ZipEngine links beside minizip 1.01e.
 * BEHAVIOUR reconstruction from NSS5.exe 0x00401510..0x004015F1 (gcc -O2, cdecl).
 * Below the measured universe: not byte-matched, never oracled. Function names are ours.
 */
#include <time.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/utime.h>      /* MinGW: struct _utimbuf / utime() */
#include "zlib.h"
#include "unzip.h"
#include "zip.h"

#ifndef DEF_MEM_LEVEL
#define DEF_MEM_LEVEL 8
#endif

/*
 * 0x00401510  zipSetFileDate
 * struct tm on the stack: sec=arg4, min=arg3, hour=arg2, mday=arg5, mon=arg6-1,
 * year=arg7-1900, isdst=-1 (wday/yday left unset). mktime (0x004B44F0) -> actime and
 * modtime of a utimbuf, utime (0x004B4498 _utime). Returns 0, or *_errno() on failure
 * (0x004B44E8). Caller: ZipReader.ExtractFileToDisk, passing the entry's
 * LastModDateTime fields with a 1-based month and a 4-digit year.
 */
int zipSetFileDate(const char *filename, int hour, int minute, int sec,
                   int mday, int mon, int year)
{
    struct tm t;
    struct utimbuf ut;

    t.tm_sec   = sec;
    t.tm_min   = minute;
    t.tm_hour  = hour;
    t.tm_mday  = mday;
    t.tm_mon   = mon - 1;
    t.tm_year  = year - 1900;
    t.tm_isdst = -1;
    ut.actime = ut.modtime = mktime(&t);
    if (utime(filename, &ut) != 0)
        return errno;
    return 0;
}

/*
 * 0x00401580  unzGetCurrentFileSize
 * unzGetCurrentFileInfo(file, &info, 0,0,0,0,0,0) into a 0x50-byte unz_file_info at
 * [ebp-0x58], returns info.uncompressed_size ([ebp-0x3C], +0x1C).
 * NOTE: on file == NULL the original jumps straight to leave/ret with eax never written,
 * i.e. it returns garbage (the C read an uninitialised `info`). 0 is returned here.
 */
uLong unzGetCurrentFileSize(unzFile file)
{
    unz_file_info info;

    if (file == NULL)
        return 0;
    unzGetCurrentFileInfo(file, &info, NULL, 0, NULL, 0, NULL, 0);
    return info.uncompressed_size;
}

/*
 * 0x004015B0  zipOpenNewFileInZipPassword
 * Forwards its 11 arguments to zipOpenNewFileInZip3 (0x00404180) with
 * raw=0, windowBits=-MAX_WBITS (-15), memLevel=DEF_MEM_LEVEL (8),
 * strategy=Z_DEFAULT_STRATEGY (0), crcForCrypting=0.
 * crcForCrypting=0 is why the retail save's ZipCrypto check byte decrypts to 0x00.
 */
int zipOpenNewFileInZipPassword(zipFile file, const char *filename,
                                const zip_fileinfo *zipfi,
                                const void *extrafield_local, uInt size_extrafield_local,
                                const void *extrafield_global, uInt size_extrafield_global,
                                const char *comment, int method, int level,
                                const char *password)
{
    return zipOpenNewFileInZip3(file, filename, zipfi,
                                extrafield_local, size_extrafield_local,
                                extrafield_global, size_extrafield_global,
                                comment, method, level, 0,
                                -MAX_WBITS, DEF_MEM_LEVEL, Z_DEFAULT_STRATEGY,
                                password, 0);
}
