' TBitmapFont private accessor -- VA 0x0059102B, 26 bytes
' byte-identical vs NSS5.exe (26/26, mode=exact, verified via try_function)
'
' UNCERTAIN: real name/KIND. Not in extracted/vtable_map.tsv or object_model.json's
' TBitmapFont member list -- no reflection record exists (BlitzMax only emits
' BBDebugScope data for reflected/public members; this one is Private, or a bare
' module Function, we cannot tell which from bytes alone). Located by disassembling
' the "blank Type/Member" rows MANIFEST.tsv carries for the fontmachine block
' (earlier passes investigated and left these). harness.try_method could not verify it
' (find_method looks the name up in
' the ORIGINAL's reflection table, which has no entry), so it is verified through
' harness.try_function's VA-comparison route instead -- same technique already used
' for src/recovered_module's Fn_ files, applied here for the first time to a body
' that takes a Type instance as its first parameter. This works because legacy bcc's
' calling convention makes a Method's implicit Self and a Function's first cdecl
' parameter identical machine code; MATCH proves the shapes really do coincide.
'
' Field evidence pins the receiver as TBitmapFont, not a guess: offset +0x24 on a0
' is TBitmapFont.PrivateData (object_model.json, offset 36); the second dereference
' at +0x28 on that pointer is TPrivateBitmapFont.FaceBlend (offset 40). So this is
' (in effect) `TBitmapFont.PrivateData.FaceBlend = a1`, with the value passed back
' as an unused Int return (compiler-default 0 -- no explicit Return in source).
Function Fn_0059102B:Int(a0:TBitmapFont, a1:Int)
	a0.PrivateData.FaceBlend = a1
End Function
