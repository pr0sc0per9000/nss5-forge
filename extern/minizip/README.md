# minizip

`unzip.c`, `unzip.h`, `zip.c`, `zip.h`, `ioapi.c`, `ioapi.h` and `crypt.h` are minizip
1.01e by Gilles Vollant, unmodified, from `contrib/minizip` of zlib 1.2.3
(`zlib-1.2.3.tar.gz`, sha256 `1795c7d067a43174113fdf03447532f373e1c6c57c08d61d9e4e9be5e244b05e`).
Licence: the zlib licence, stated in each file's header. NSS5.exe links the same version.

`zipengine_glue.c` is this project's own: the three C helpers ZipEngine links beside
minizip, rebuilt from their behaviour in NSS5.exe (0x00401510..0x004015F1).

`minizip.bmx` declares all of it for the zipengine bodies in `src/recovered_thirdparty/zipengine/`.
