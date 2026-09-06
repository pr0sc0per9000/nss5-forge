' TZipEStream.Create
' VA 0x0058F7B5   205 bytes   vtable slot 0xA4   sig ($,$,i,$):TZipEStream
' byte-identical vs NSS5.exe (205/205, mode=reloc, NSS5_NO_LEARN=1)
' THIRD-PARTY MODULE (zipengine) -- this body must NOT be moved into src/recovered/.
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted
'
' a0 is the .zip path, a1 the entry name inside it, a2 the case-sensitivity flag and a3
' the password. reader.OpenZip is class-table slot 0x4C, find_file is slot 0xA8.
'
' Both failure paths return Null rather than throwing, and an unopenable archive only
' writes a DebugLog line -- so a missing or corrupt zip is silent at the point of failure
' and surfaces later as a Null stream coming out of TZipEngineStreamFactory.CreateStream.
'
' The DebugLog callee, 0x005B9674, is a 27-byte thunk that pushes its argument and calls
' through the function-pointer global at 0x005C7BD4 (its zero-argument neighbour at
' 0x005B9660 is DebugStop). extracted/brl_functions.tsv had it under an alias set of two
' maxgui localization setters that happen to share those 27 bytes, and _brl_blitz_DebugLog
' was missing from the set, so the operand refused to mask. Our own _brl_blitz_DebugLog was
' fetched and compared against it directly: identical in all 27 bytes bar the single
' absolute global operand. The name was added to that row's alias set.

	Function Create:TZipEStream(a0:String, a1:String, a2:Int, a3:String)
		Local z:TZipEStream = New TZipEStream
		z.reader = New ZipReader
		If z.reader.OpenZip(a0)
			z.filename = a1
			z.case_sensitive = a2
			z.password = a3
			If Not z.find_file(1) Then z = Null
		Else
			DebugLog "unable to open zip " + a0
			z = Null
		EndIf
		Return z
	End Function
