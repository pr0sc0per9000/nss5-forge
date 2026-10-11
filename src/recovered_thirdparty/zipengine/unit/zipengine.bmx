' zipengine: the ZipEngine module's own compile unit. assemble.py emits it as
' src/assembled/zipengine.bmx, Types and Functions filled from ../ and this file's source
' lines kept as written. bcc compiles it to the unit initialiser below.
' VA 0x0058DACC   295 bytes   ZipEngineModuleInit
' byte-identical vs NSS5.exe (295/295, mode=reloc, compare_module_body.py --unit --in-build under NSS5_NO_LEARN=1)
'
'   +0     guard on [0x00C94808]                                      (bcc template)
'   +31    call ___bb_blitz_blitz                                      implicit, first
'   +36    call ___bb_zlib_zlib (0x0059C75C)                           Import Pub.ZLib
'   +41    call ___bb_basic_basic (0x0059CA88)                         Import BRL.Basic
'   +46    call ___bb_system_system, ___bb_retro_retro, ___bb_map_map  the other three
'   +61    13 x bbObjectRegisterType, the Types in '!Types order
'   +230   New TZipEngineStreamFactory, result discarded: the stream factory registers
'          itself from TStreamFactory.New(), which is why "zipe::" urls resolve at all
'   +243   Global g_zipfilefunc_streams:TMap = New TMap, bit 0 of [0x00C95B8C]
' An Import is called only if no earlier Import already reaches it, so the order above
' is forced. Including extern.bmx and importing the C files add no call. The module name
' and the Global's name are not recoverable.
'!Types ZipFile ZipWriter ZipReader ZipRamStream TZipFileList tm tm_zip zip_fileinfo SZIPFileDataDescriptor SZIPCentralFileHeader SZipFileEntry TZipEngineStreamFactory TZipEStream
'!Functions Fn_0058FB20 Fn_0058FB9F Fn_0058FBE2 Fn_0058FC25 Fn_0058FC5C Fn_0058FD9E Fn_0058FDB9
SuperStrict
Import Pub.ZLib
Import BRL.Basic
Import BRL.System
Import BRL.Retro
Import BRL.Map
Import "<repo>/extern/minizip/unzip.c"
Import "<repo>/extern/minizip/zip.c"
Import "<repo>/extern/minizip/ioapi.c"
Import "<repo>/extern/minizip/zipengine_glue.c"
Include "<repo>/extern/minizip/extern.bmx"
'!Statements
New TZipEngineStreamFactory
Global g_zipfilefunc_streams:TMap = New TMap
