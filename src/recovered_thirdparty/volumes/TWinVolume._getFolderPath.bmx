' TWinVolume._getFolderPath
' VA 0x00598986   76 bytes   vtable slot 0x5C   sig (i)$
' THIRD-PARTY MODULE (volumes): BaH.Volumes 1.06, MIT
' byte-identical vs NSS5.exe (76/76, mode=reloc, harness.try_method under NSS5_NO_LEARN=1)
' Parameter names: a0.. as the harness emits them (1.06 source name in the note)
'
' a0 is `kind`. Edit: Pub.Win32's `MAX_PATH` -> `PATH_MAX` (both 260 = push 0x104;
' the probe does not import Pub.Win32). SHGetFolderPathW pushes b+0x18, 0, 0, kind, 0
' (stdcall, no add esp); ret is dead (no store). 0x004A78D0 = bbStringFromWString.
' Needs the module Consts / Extern / Globals declared as pragmas in Fn_00598051.bmx.
	Method _getFolderPath:String(a0:Int)
		Local b:Short[] = New Short[PATH_MAX]

		Local ret:Int = SHGetFolderPath(Null, a0, Null, SHGFP_TYPE_CURRENT, b)

		Return String.fromWString(b)
	End Method
