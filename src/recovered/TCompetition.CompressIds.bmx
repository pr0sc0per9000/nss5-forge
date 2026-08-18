' TCompetition.CompressIds
' VA 0x0050D274   156 bytes   vtable slot 0xB0   sig ()i
' byte-identical vs NSS5.exe (156/156, original length from Ghidra's inventory, mode=reloc)
'
' 0x00C616DC = TCompetition + 0x11C (SortListBy(i,i)). 0x00C6099C is the competition TList;
' EachIn downcast class table is TCompetition (0x00C615C0). TCompetition + 0xB4 = ChangeId(i)i.
' 0x005B4C68 = _brl_system_Notify; 0x004A4620 = `End`.
' String literal at 0x00C7D284 is "ERROR COMPRESSING IDS!".
' No explicit null test inside the loop: EachIn supplies it (an explicit one costs 7 bytes).
' Module Globals declared by this body (names are ours; the TYPES are load-bearing):
'   Global g_comps:TList
	Function CompressIds:Int()
		'!Global g_comps:TList
		TCompetition.SortListBy(1, 1)
		Local n:Int = 1
		For Local c:TCompetition = EachIn g_comps
			If c.id <> n Then
				If c.ChangeId(n) = 0 Then
					Notify("ERROR COMPRESSING IDS!", 0)
					End
				End If
			End If
			n = n + 1
		Next
	End Function
