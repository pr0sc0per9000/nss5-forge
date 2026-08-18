' TBitmapFont private accessor -- VA 0x0059109D, 18 bytes
' byte-identical vs NSS5.exe (18/18, mode=exact, verified via try_function)
'
' UNCERTAIN: real name/KIND. Getter companion to Fn_00591083 (ShadowBlend setter);
' see Fn_0059102B's header for the try_function VA-comparison technique. Field
' evidence: a0 dereferenced at +0x24 is TBitmapFont.PrivateData; the result
' dereferenced at +0x24 again is TPrivateBitmapFont.ShadowBlend (same relative
' offset, coincidental -- confirmed by disassembly: `eax=[eax+0x24]` executed twice
' in a row, not a typo). Returns `Self.PrivateData.ShadowBlend`.
Function Fn_0059109D:Int(a0:TBitmapFont)
	Return a0.PrivateData.ShadowBlend
End Function
