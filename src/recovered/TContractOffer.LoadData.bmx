' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH never
' certifies the text -- see docs/reference/codegen-patterns.md 13.2.
' TContractOffer.LoadData
' VA 0x00570FBD   115 bytes   vtable slot 0x30   sig (:TStream)i
' byte-identical vs NSS5.exe (115/115, original length from Ghidra's inventory, mode=reloc)
' Assumptions:
'   LogLine is the recovered module-level entry tracer; its literal is this function's name.
'   0x005B82EF is the alias set _brl_stream_ReadLine|_maxgui_proxygadgets_SplitterOrientation
'   -> ReadLine picked from context (a TStream loop).
'   0x005B80B9 is the 4-way alias set containing _brl_stream_Eof -> Eof.
'   0x005B812B is the alias set containing _brl_stream_CloseStream -> CloseStream.
'   PTR_FUN_00C6B7F0 = TContractOffer classtable(0x00C6B7B8) + 0x38 -> CreateContract($)i
'   harness.read_string(0x00C6FE94) reads "//", the sentinel the body below uses.
'   `If s = "//" Then Return 0` is an explicit Return, not Exit: its target is the
'   epilogue, whereas the While's own exit lands on CloseStream.

	Function LoadData:Int(a0:TStream)
		LogLine("TContractOffer.LoadData")
		ReadLine(a0)
		While Not Eof(a0)
			Local s:String = ReadLine(a0)
			If s = "//" Then Return 0
			TContractOffer.CreateContract(s)
		Wend
		CloseStream(a0)
	End Function
