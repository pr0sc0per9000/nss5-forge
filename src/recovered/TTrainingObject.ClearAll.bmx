' TTrainingObject.ClearAll
' VA 0x00582e22   121 bytes   vtable slot 0x40   sig ()i
' byte-identical vs NSS5.exe (121/121, original length from Ghidra's inventory, mode=reloc)
' assumes module Global (name ours, type load-bearing): Global g_trainobjs:TList (0x00C6D568)
' the EachIn downcast class table is TTrainingObject (0x00C6D678); slot 0x44 = Clear()
' the leading `If Not ... Then Return 0` is the guard form -- Ghidra renders the early
' return as an If wrapping the whole loop.
'!Global g_trainobjs:TList

	Function ClearAll:Int()
		If Not g_trainobjs Then Return 0
		For Local o:TTrainingObject = EachIn g_trainobjs
			o.Clear()
		Next
	End Function
