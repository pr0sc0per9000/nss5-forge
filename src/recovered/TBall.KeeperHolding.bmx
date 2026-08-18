' TBall.KeeperHolding -- VA 0x004CB54E, 63 bytes
' byte-identical vs NSS5.exe
' (1 absolute-address slot(s) relocation-masked; emitted code identical)
' Parameter names are not recoverable from the binary and do not affect codegen.
Method KeeperHolding:Int()
	If controlledby <> Null And controlledby.KeeperHoldingBall() Then Return True
	Return False
End Method
