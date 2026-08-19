' TBall.KeeperHolding -- VA 0x004CB54E, 63 bytes
' VA 0x004cb54e   63 bytes   vtable slot 0x88   sig ()i
' byte-identical vs NSS5.exe (63/63, original length from Ghidra's inventory)
' byte-identical vs NSS5.exe
' (1 absolute-address slot(s) relocation-masked; emitted code identical)
' Parameter names are not recoverable from the binary and do not affect codegen.
Method KeeperHolding:Int()
	If controlledby <> Null And controlledby.KeeperHoldingBall() Then Return True
	Return False
End Method
