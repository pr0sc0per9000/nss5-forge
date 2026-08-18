' TBall.Update -- VA 0x004C81B6, 91 bytes
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
