' TVolSpace.GetDiskSpace
' VA 0x00598A4B   78 bytes   vtable slot 0x30   sig ($):TVolSpace
' THIRD-PARTY MODULE (volumes): BaH.Volumes 1.06, MIT
' byte-identical vs NSS5.exe (78/78, mode=reloc, harness.try_method under NSS5_NO_LEARN=1)
' Parameter names: a0.. as the harness emits them (1.06 source name in the note)
'
' a0 is `vol` (it shadows the field in 1.06). this in ebx, dir in esi;
' GetDiskFreeSpaceExW(dir, &fbc +0x10, &tb +0x18, &fb +0x20) as Long Var; ret dead;
' If dir -> bbMemFree.
' Needs the module Consts / Extern / Globals declared as pragmas in Fn_00598051.bmx.
	Function GetDiskSpace:TVolSpace(a0:String)
		Local this:TVolSpace = New TVolSpace

		Local dir:Short Ptr = a0.toWString()

		Local ret:Int = GetDiskFreeSpaceEx(dir, this.fbc, this.tb, this.fb)

		If dir Then
			MemFree(dir)
		End If

		Return this
	End Function
