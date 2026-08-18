' TRouletteWheel.Update
' VA 0x00575bbb   123 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (123/123, original length from Ghidra's inventory)
' float literals recovered from .data: 0.02 and 360.0.
' Parameter names are not recoverable from the binary; a0/a1/... as emitted by the harness.
	Method Update:Int()
		oldfRot = fRot
		fSpeed :- 0.02
		If fSpeed <= 0.0 Then fSpeed = 0.0
		fRot :+ fSpeed
		If fRot > 360.0
			fRot :- 360.0
			oldfRot :- 360.0
		EndIf
	End Method
