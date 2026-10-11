' volumes: BaH.Volumes 1.06's module file. assemble.py emits it as src/assembled/volumes.bmx.
' VA 0x00597F30   52 bytes   VolumesModuleInit
' byte-identical vs NSS5.exe (52/52, mode=reloc, compare_module_body.py --unit --in-build under NSS5_NO_LEARN=1)
'
'   +0     guard on [0x00C9A908]                                      (bcc template)
'   +31    call ___bb_blitz_blitz                                      implicit, first
'   +36    call 0x0059827C, vol_win.bmx's init                         ?win32 Import "vol_win.bmx"
'   +41    epilogue
SuperStrict
Import "vol_win.bmx"
