' TMyVector.RotateAroundX
' VA 0x004E23DF   145 bytes   vtable slot 0x5c   sig (d):TMyVector
' byte-identical vs NSS5.exe (145/145, original length from Ghidra's inventory)
' Cos/Sin resolve to the bcc degree-mode helpers at 0x004a1f10/0x004a1f00.
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables) differ by construction between probe and NSS5.exe; emitted code is identical.

	Method RotateAroundX:TMyVector(a0:Double)
		Local ty:Double = Y
		Local tz:Double = Z
		Y = Cos(a0)*ty - Sin(a0)*tz
		Z = Sin(a0)*ty + Cos(a0)*tz
		Return Self
	End Method
