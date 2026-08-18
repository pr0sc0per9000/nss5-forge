' TCompetition.Compare
' VA 0x0050ea70   1124 bytes   vtable slot 0x1c   sig (:Object)i
' byte-identical vs NSS5.exe (1124/1124, original length from Ghidra's inventory, mode=reloc)
' Assumption: module global at 0x00c609a0 declared as Int, named g_competition_int10
' after extracted/globals_named.tsv. The dispatch is a Select on that global.
' Operand order matters: bcc emits 'cmp <left-operand-memory>, <right-operand-register>',
' so 'id > TCompetition(a0).id' and 'TCompetition(a0).id < id' are different bytes even
' though they mean the same thing. Case 23 mixes both forms; that is the original.
'
' Verified from scratch with the '!Global pragma below -> MATCH
' 1124/1124, reloc_masked=62. A BUILD_FAIL without them is a harness
' limitation (it cannot bind a Global from prose alone), not a body defect.
	Method Compare:Int(a0:Object)
		'!Global g_competition_int10:Int
		If a0 = Self Then Return 0
		Select g_competition_int10
			Case 1
				If id > TCompetition(a0).id Then Return 1
				If id < TCompetition(a0).id Then Return -1
			Case 22
				If TCompetition(a0).priority < priority Then Return 1
				If TCompetition(a0).priority > priority Then Return -1
				If TCompetition(a0).based < based Then Return 1
				If TCompetition(a0).based > based Then Return -1
				If TCompetition(a0).compstatus < compstatus Then Return 1
				If TCompetition(a0).compstatus > compstatus Then Return -1
				If TCompetition(a0).id < id Then Return 1
				If TCompetition(a0).id > id Then Return -1
			Case 26
				If TCompetition(a0).based < based Then Return 1
				If TCompetition(a0).based > based Then Return -1
				If TCompetition(a0).compstatus < compstatus Then Return 1
				If TCompetition(a0).compstatus > compstatus Then Return -1
				If TCompetition(a0).startweek < startweek Then Return 1
				If TCompetition(a0).startweek > startweek Then Return -1
				If TCompetition(a0).id < id Then Return 1
				If TCompetition(a0).id > id Then Return -1
			Case 23
				If level > TCompetition(a0).level Then Return -1
				If level < TCompetition(a0).level Then Return 1
				If locale > TCompetition(a0).locale Then Return -1
				If locale < TCompetition(a0).locale Then Return 1
				If based > TCompetition(a0).based Then Return 1
				If based < TCompetition(a0).based Then Return -1
				If comptype > TCompetition(a0).comptype Then Return 1
				If comptype < TCompetition(a0).comptype Then Return -1
				Local val1:Int = startyear * 52 + startweek
				Local val2:Int = TCompetition(a0).startyear * 52 + TCompetition(a0).startweek
				If val1 > val2 Then Return 1
				If val1 < val2 Then Return -1
				If id > TCompetition(a0).id Then Return 1
				If id < TCompetition(a0).id Then Return -1
		End Select
		Return Super.Compare(a0)
	End Method
