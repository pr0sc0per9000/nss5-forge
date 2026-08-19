' TBall.ResetPosition -- VA 0x004CBC81, 98 bytes
' VA 0x004cbc81   98 bytes   vtable slot 0x9c   sig (i,i,i)i
' byte-identical vs NSS5.exe (98/98, original length from Ghidra's inventory)
' byte-identical vs NSS5.exe
' Parameter names are not recoverable from the binary and do not affect codegen.
Method ResetPosition:Int(a0:Int, a1:Int, a2:Int)
	x = a0
	y = a1
	z = a2
	oldx = x
	oldy = y
	oldz = z
	metax = x
	metay = y
	velocity = 0
	zvelocity = 0
End Method
