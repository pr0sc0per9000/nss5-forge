' vol_win: BaH.Volumes 1.06's Win32 driver unit, Imported by volumes.bmx.
' VA 0x0059827C   152 bytes   VolumesWinUnitInit
' byte-identical vs NSS5.exe (152/152, mode=reloc, compare_module_body.py --unit --in-build under NSS5_NO_LEARN=1)
'
'   +0     guard on [0x00C9ABD8]                                      (bcc template)
'   +31    call ___bb_blitz_blitz                                      implicit, first
'   +36    bank, linkedlist, win32 (0x005AB414), map                   the four module Imports
'   +56    call 0x00597F64, main.bmx's init                            Import "main.bmx"
'   +61    3 x bbObjectRegisterType, the Types in '!Types order
'   +100   Global winVolume_driver = New TWinVolumeDriver, bit 1 of [0x00C9AFEC]; its New
'          sets volume_driver, which every GetUser*Dir Function forwards through
'!Parent volumes
'!Types TWinVolumeDriver TWinVolume TVolSpace
SuperStrict
Import BRL.Bank
Import BRL.LinkedList
Import Pub.Win32
Import BRL.Map
Import "main.bmx"
'!Statements
Global winVolume_driver:TWinVolumeDriver = New TWinVolumeDriver
