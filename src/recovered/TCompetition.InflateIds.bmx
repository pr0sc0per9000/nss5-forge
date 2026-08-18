' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH never
' certifies the text -- see docs/reference/codegen-patterns.md 13.2.
' TCompetition.InflateIds
' VA 0x0050D1D4   160 bytes   vtable slot 0xAC   sig ()i
' byte-identical vs NSS5.exe (160/160, original length from Ghidra's inventory, mode=reloc)
' module Global assumed: 0x00C6099C : TList  (the competition list; globals_final had it
'   only as untyped Object, but it is the EachIn subject and 0x00C615C0 -- TCompetition's
'   class table -- is the downcast target, so the element type is TCompetition).
' resolved call targets:
'   PTR_FUN_00C61670 = TCompetition classtable(0x00C615C0) + 0xB0 -> CompressIds()i
'   PTR_FUN_00C616DC = TCompetition classtable + 0x11C            -> SortListBy(i,i)i
'   slot 0xB4 on the loop variable                                 -> TCompetition.ChangeId(i)i
'   0x005B4C68 = _brl_system_Notify ; 0x004A4620 is the 19-byte `End` stub.

	Function InflateIds:Int()
		'!Global g_complist:TList
		TCompetition.CompressIds()
		TCompetition.SortListBy(1, 0)
		For Local c:TCompetition = EachIn g_complist
			If Not c.ChangeId(c.id * 10)
				Notify("ERROR INFLATING IDS!", 0)
				End
			End If
		Next
		TCompetition.SortListBy(1, 1)
	End Function
