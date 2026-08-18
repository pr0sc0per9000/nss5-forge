' TMyVector.RotateAroundY
' VA 0x004E2470   147 bytes   vtable slot 0x60   sig (d):TMyVector
' byte-identical vs NSS5.exe (147/147, original length from Ghidra's inventory)
' Cos/Sin resolve to the bcc degree-mode helpers at 0x004a1f10/0x004a1f00.
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables) differ by construction between probe and NSS5.exe; emitted code is identical.

	Method RotateAroundY:TMyVector(a0:Double)
		Local tx:Double = X
		Local tz:Double = Z
		X = Cos(a0)*tx + Sin(a0)*tz
		Z = -Sin(a0)*tx + Cos(a0)*tz
		Return Self
	End Method
