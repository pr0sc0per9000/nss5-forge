' TBitmapFont.GetShadowBlend
' VA 0x0059109D   18 bytes   vtable slot 0x94   sig ()i
' byte-identical vs NSS5.exe (18/18, mode=exact)
' THIRD-PARTY MODULE (fontmachine) -- this body must NOT be moved into src/recovered/.
'
' NAME RESOLVED. This body was banked as `TBitmapFont.Fn_0059109D.bmx`, verified through
' try_function's VA route because the reflection table appeared to have no record for it.
' It does: the record sat behind TBitmapFont's `GetFaceImage (b):brl.max2d.TImage`, and
' parse_reflection.py's TYPE_ATOM refused the dots in a namespaced class name, so the decl
' loop broke there and TBitmapFont lost its last fifteen methods -- slots 0x5C..0x94. With
' the regex fixed the slot, name and signature come straight out of NSS5.exe, and the body
' re-verifies as an ordinary Method through try_method. The earlier file's field reasoning
' (a0+0x24 = PrivateData, then +0x24 = ShadowBlend) was right; only the KIND and the name
' were open, and both are now read rather than inferred.

	Method GetShadowBlend:Int()
		Return PrivateData.ShadowBlend
	End Method
