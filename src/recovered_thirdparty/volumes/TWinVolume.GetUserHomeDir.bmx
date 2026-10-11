' TWinVolume.GetUserHomeDir
' VA 0x005988DE   23 bytes   vtable slot 0x44   sig ()$
' THIRD-PARTY MODULE (volumes): BaH.Volumes 1.06, MIT
' byte-identical vs NSS5.exe (23/23, mode=reloc, harness.try_method under NSS5_NO_LEARN=1)
'
' push 0x28 (CSIDL_PROFILE); Self slot 0x5C (_getFolderPath).
' Needs the module Consts / Extern / Globals declared as pragmas in Fn_00598051.bmx.
	Method GetUserHomeDir:String()
		Return _getFolderPath(CSIDL_PROFILE)
	End Method
