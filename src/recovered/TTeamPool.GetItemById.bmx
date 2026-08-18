' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH on its own does
' not certify the text -- see docs/reference/codegen-patterns.md 13.2.
' TTeamPool.GetItemById
' VA 0x0052667E   134 bytes   vtable slot 0x48   sig (i):TTableData
' byte-identical vs NSS5.exe (134/134, original length from Ghidra's inventory, mode=reloc)
' Assumptions:
'   Self.list (:TList at +8) is the enumerated collection; 0x00C64B80 is TTableData's
'   class table, which is the EachIn downcast target -> loop variable type TTableData.
'   TTableData.id is at +8 (object_model), which is Ghidra's puVar2[2].
'   0x004A7AC0 = _bbStringFromInt and 0x004A7C20 = _bbStringConcat: the not-found path is
'   a String + Int concatenation fed to the recovered module Function LogLine (0x00505B91).
'   The literal's TEXT is unrecoverable (address only, relocation-masked).

	Method GetItemById:TTableData(a0:Int)
		For Local t:TTableData = EachIn list
			If t.id = a0 Then Return t
		Next
		LogLine("Could not find id:" + a0)
		Return Null
	End Method
