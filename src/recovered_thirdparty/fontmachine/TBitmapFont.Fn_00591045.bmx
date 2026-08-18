' TBitmapFont private accessor -- VA 0x00591045, 18 bytes
' byte-identical vs NSS5.exe (18/18, mode=exact, verified via try_function)
'
' UNCERTAIN: real name/KIND. Companion getter to Fn_0059102B (SetFaceBlend); see that
' file's header for the full explanation of why try_function's VA route was used
' instead of try_method. Field evidence: a0 dereferenced at +0x24 is
' TBitmapFont.PrivateData; the result dereferenced at +0x28 is
' TPrivateBitmapFont.FaceBlend. So this returns `Self.PrivateData.FaceBlend`.
Function Fn_00591045:Int(a0:TBitmapFont)
	Return a0.PrivateData.FaceBlend
End Function
