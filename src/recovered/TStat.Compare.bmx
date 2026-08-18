' TStat.Compare
' VA 0x0056E8FF   301 bytes   vtable slot 0x1c   sig (:Object)i
' byte-identical vs NSS5.exe (301/301, original length from Ghidra's inventory)
' ASSUMPTION: module Global 'g_stat_int:Int' at 0x00C6A8A4 (name taken from
' globals_named.tsv; the original name is unrecoverable, only the declared
' type Int is load-bearing).
' Select, not If/ElseIf: the original loads the global once ('mov eax,[0xC6A8A4]')
' and then cmp eax,0x1B / cmp eax,0x1C.
	Method Compare:Int(a0:Object)
		'!Global g_stat_int:Int
		Select g_stat_int
			Case 27
				If minute > TStat(a0).minute Then Return 1
				If minute < TStat(a0).minute Then Return -1
				If stype > TStat(a0).stype Then Return 1
				If stype < TStat(a0).stype Then Return -1
			Case 28
				If stype > TStat(a0).stype Then Return 1
				If stype < TStat(a0).stype Then Return -1
				If minute > TStat(a0).minute Then Return 1
				If minute < TStat(a0).minute Then Return -1
		End Select
		Return Super.Compare(a0)
	End Method
