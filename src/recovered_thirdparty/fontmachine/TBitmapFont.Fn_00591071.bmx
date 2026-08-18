' TBitmapFont private accessor -- VA 0x00591071, 18 bytes
' byte-identical vs NSS5.exe (18/18, mode=exact, verified via try_function)
'
' UNCERTAIN: real name/KIND. Getter companion to Fn_00591057 (BorderBlend setter);
' see Fn_0059102B's header for the try_function VA-comparison technique. Field
' evidence: a0 dereferenced at +0x24 is TBitmapFont.PrivateData; the result
' dereferenced at +0x2c is TPrivateBitmapFont.BorderBlend. Returns
' `Self.PrivateData.BorderBlend`.
Function Fn_00591071:Int(a0:TBitmapFont)
	Return a0.PrivateData.BorderBlend
End Function
