' minizip 1.01e (zlib 1.2.3 contrib/minizip) and the ZipEngine C glue, the C side of the
' zipengine module. NSS5.exe links the same versions statically below 0x004BA000; their
' addresses are named in scripts/helper_map.py BRL_ALIAS_ADDITIONS. Plain Extern: cdecl.
' `$z` where the original brackets an argument with _bbStringToCString / _bbMemFree; Byte
' Ptr where it pushes a literal 0.
Import Pub.ZLib
Import "unzip.c"
Import "zip.c"
Import "ioapi.c"
Import "zipengine_glue.c"
Include "extern.bmx"
