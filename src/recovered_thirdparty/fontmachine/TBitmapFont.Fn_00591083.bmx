' TBitmapFont private accessor -- VA 0x00591083, 26 bytes
' byte-identical vs NSS5.exe (26/26, mode=exact, verified via try_function)
'
' UNCERTAIN: real name/KIND. Sibling of Fn_0059102B/Fn_00591057; see Fn_0059102B's
' header for the full explanation of the try_function VA-comparison technique.
' Field evidence: a0 dereferenced at +0x24 is TBitmapFont.PrivateData; the store at
' +0x24 on that pointer is TPrivateBitmapFont.ShadowBlend (offset 36 -- the same
' relative offset as PrivateData itself within TBitmapFont, purely coincidental).
' So this is `Self.PrivateData.ShadowBlend = a1`.
Function Fn_00591083:Int(a0:TBitmapFont, a1:Int)
	a0.PrivateData.ShadowBlend = a1
End Function
