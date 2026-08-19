' TBall.Update -- VA 0x004C81B6, 91 bytes
' VA 0x004c81b6   91 bytes   vtable slot 0x4c   sig ()i
' byte-identical vs NSS5.exe (91/91, original length from Ghidra's inventory)
' byte-identical vs NSS5.exe
' Parameter names are not recoverable from the binary and do not affect codegen.
Method Update:Int()
	UpdateAlpha()
	CheckAfterTouch()
	UpdateMovement()
	UpdateMetaBall()
	UpdateAnimation()
	CheckGoals()
	CheckSideLines()
	CheckAdHoardings()
End Method
