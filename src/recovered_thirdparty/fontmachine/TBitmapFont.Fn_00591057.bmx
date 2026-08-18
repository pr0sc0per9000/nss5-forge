' TBitmapFont private accessor -- VA 0x00591057, 26 bytes
' byte-identical vs NSS5.exe (26/26, mode=exact, verified via try_function)
'
' UNCERTAIN: real name/KIND. Sibling of Fn_0059102B/Fn_00591045; see Fn_0059102B's
' header for the full explanation of the try_function VA-comparison technique.
' Field evidence: a0 dereferenced at +0x24 is TBitmapFont.PrivateData; the store at
' +0x2c on that pointer is TPrivateBitmapFont.BorderBlend (offset 44). So this is
' `Self.PrivateData.BorderBlend = a1`.
Function Fn_00591057:Int(a0:TBitmapFont, a1:Int)
	a0.PrivateData.BorderBlend = a1
End Function
