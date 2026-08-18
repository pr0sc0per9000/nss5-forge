' TFixture.Compare
' VA 0x004C5150   304 bytes   vtable slot 0x1c   sig (:Object)i
' byte-identical vs NSS5.exe (304/304, original length from Ghidra's inventory)
' ASSUMPTION: module Global 'g_nation_int05:Int' at 0x00C59E44 (name from
' globals_named.tsv).
' A one-arm Select, not an If -- the global is loaded into eax first.
' The comparison directions on level and result really are inverted relative to
' sdate and round in the original; that is not a transcription slip.
	Method Compare:Int(a0:Object)
		'!Global g_nation_int05:Int
		If a0 = Self Then Return 0
		Select g_nation_int05
			Case 17
				If sdate > TFixture(a0).sdate Then Return 1
				If sdate < TFixture(a0).sdate Then Return -1
				If level < TFixture(a0).level Then Return 1
				If level > TFixture(a0).level Then Return -1
				If round > TFixture(a0).round Then Return 1
				If round < TFixture(a0).round Then Return -1
				If result < TFixture(a0).result Then Return 1
				If result > TFixture(a0).result Then Return -1
		End Select
		Return Super.Compare(a0)
	End Method
