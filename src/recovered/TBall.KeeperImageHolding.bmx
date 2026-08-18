' TBall.KeeperImageHolding -- VA 0x004CB58D, 95 bytes
' byte-identical vs NSS5.exe
' (1 absolute-address slot(s) relocation-masked; emitted code identical)
' Parameter names are not recoverable from the binary and do not affect codegen.
Method KeeperImageHolding:Int()
	If controlledby <> Null And controlledby.selectionno = 0 And controlledby.ImageHoldingBall(controlledby.imageframenumber) Then Return True
	Return False
End Method
