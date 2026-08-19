' TBall.GetHeightScale -- VA 0x004CC466, 35 bytes
' VA 0x004cc466   35 bytes   vtable slot 0xc0   sig (i)f
' byte-identical vs NSS5.exe (35/35, original length from Ghidra's inventory)
' byte-identical vs NSS5.exe
' (2 absolute-address slot(s) relocation-masked; emitted code identical)
' Parameter names are not recoverable from the binary and do not affect codegen.
Method GetHeightScale:Float(a0:Int)
	Return 1.0 + a0 * 0.01
End Method
