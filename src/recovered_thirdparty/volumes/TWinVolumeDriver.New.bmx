' TWinVolumeDriver.New
' VA 0x00598314   70 bytes   vtable slot 0x10   sig ()i
' THIRD-PARTY MODULE (volumes): BaH.Volumes 1.06, MIT
' byte-identical vs NSS5.exe (70/70, mode=reloc, harness.try_method under NSS5_NO_LEARN=1)
'
' `volume_driver = TWinVolume.Create()`: call [0x00C9AEE0] is TWinVolume's class
' table 0x00C9AE88 + 0x58 (Create), then the standard Global object store into
' 0x00C9ABC0 (inc new, dec/bbGCFree old). volume_driver comes from Fn_00598051.bmx.
' Needs the module Consts / Extern / Globals declared as pragmas in Fn_00598051.bmx.
	Method New()
		volume_driver = TWinVolume.Create()
	End Method
