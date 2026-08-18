' TBase_Team.Compare
' VA 0x004BD41E   358 bytes   vtable slot 0x1c   sig (:Object)i
' byte-identical vs NSS5.exe (358/358, original length from Ghidra's inventory)
' ASSUMPTION: module Global 'g_screen_continents_int01:Int' at 0x00C59310
' (name from globals_named.tsv).
' Case order 1, 2, 11, 5 is the original's order, not sorted.
' 'id' has Self on the left of the comparison; labelname, strength and randno
' have the downcast on the left. That asymmetry shows up in the operand order of
' the emitted cmp (and in the bbStringCompare argument order for labelname) and
' is required for the byte match.
	Method Compare:Int(a0:Object)
		'!Global g_screen_continents_int01:Int
		If a0 = Self Then Return 0
		Select g_screen_continents_int01
			Case 1
				If id > TBase_Team(a0).id Then Return 1
				If id < TBase_Team(a0).id Then Return -1
			Case 2
				If TBase_Team(a0).labelname < labelname Then Return 1
				If TBase_Team(a0).labelname > labelname Then Return -1
			Case 11
				If TBase_Team(a0).strength < strength Then Return 1
				If TBase_Team(a0).strength > strength Then Return -1
			Case 5
				If TBase_Team(a0).randno < randno Then Return 1
				If TBase_Team(a0).randno > randno Then Return -1
		End Select
		Return Super.Compare(a0)
	End Method
