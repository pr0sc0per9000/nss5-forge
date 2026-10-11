' TVolSpace.refresh
' VA 0x00598A99   82 bytes   vtable slot 0x34   sig ()i
' THIRD-PARTY MODULE (volumes): BaH.Volumes 1.06, MIT
' byte-identical vs NSS5.exe (82/82, mode=reloc, harness.try_method under NSS5_NO_LEARN=1)
'
' SetErrorMode(1) -> edi, ToWString(vol) -> ebx, GetDiskFreeSpaceExW into the
' three Long fields, result -> esi, MemFree, SetErrorMode(edi), return esi.
' Needs the module Consts / Extern / Globals declared as pragmas in Fn_00598051.bmx.
	Method refresh:Int()
		Local mode:Int = SetErrorMode(SEM_FAILCRITICALERRORS)

		Local dir:Short Ptr = vol.toWString()

		Local ret:Int = GetDiskFreeSpaceEx(dir, fbc, tb, fb)

		If dir Then
			MemFree(dir)
		End If

		SetErrorMode(mode)
		Return ret
	End Method
