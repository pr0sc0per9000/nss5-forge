' TMyVector.RotateAroundZ
' VA 0x004E2503   145 bytes   vtable slot 0x64   sig (d):TMyVector
' byte-identical vs NSS5.exe (145/145, original length from Ghidra's inventory)
' Cos/Sin resolve to the bcc degree-mode helpers at 0x004a1f10/0x004a1f00.
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables) differ by construction between probe and NSS5.exe; emitted code is identical.

	Method RotateAroundZ:TMyVector(a0:Double)
		Local tx:Double = X
		Local ty:Double = Y
		X = Cos(a0)*tx - Sin(a0)*ty
		Y = Sin(a0)*tx + Cos(a0)*ty
		Return Self
	End Method
