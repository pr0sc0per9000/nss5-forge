' main: BaH.Volumes 1.06's core unit (TVolume and the module Functions), Imported by
' vol_win.bmx. The Functions keep Fn_<VA> names here; their 1.06 names are in each file.
' VA 0x00597F64   65 bytes   VolumesMainUnitInit
' byte-identical vs NSS5.exe (65/65, mode=reloc, compare_module_body.py --unit --in-build under NSS5_NO_LEARN=1)
'
'   +0     guard on [0x00C9A910]                                      (bcc template)
'   +31    call ___bb_blitz_blitz                                      implicit, first
'   +36    call ___bb_linkedlist_linkedlist (0x005B34C0)               Import BRL.LinkedList
'   +41    bbObjectRegisterType(TVolume)
'   +54    epilogue; `Global volume_driver:TVolume` has no initialiser and emits nothing
'!Parent vol_win
'!Types TVolume
'!Functions Fn_00598051 Fn_00598068 Fn_0059809B Fn_005980CE Fn_005980E9 Fn_00598100 Fn_00598117 Fn_0059812E Fn_00598145 Fn_00598160
SuperStrict
Import BRL.LinkedList
