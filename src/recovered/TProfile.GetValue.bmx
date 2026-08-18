' TProfile.GetValue
' VA 0x0056a366   1386 bytes   vtable slot 0xb8   sig ()i   KIND=Method
' byte-identical vs NSS5.exe (1386/1386, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=45), verified with NSS5_NO_LEARN=1.
'
' The player's transfer value.  Float constants read out of NSS5.exe at 0x00C8E958..0x00C8E9E4.
' Declares no Globals.
'
' THREE FORMS ARE LOAD-BEARING:
'  * `gs :+ X` (not `gs = gs + X`): the original evaluates X FIRST and only then loads the
'    accumulator (0x0056A42C fmul / 0x0056A432 fld [ebp-4] / faddp) -- guide 16.1.
'    `gs = gs * 10.0` immediately after is the OTHER convention (fld gs first), so both
'    appear in one body (guide 16.5).
'  * `Local st:Int` for the club strength: one field load followed by two `imul eax,edx`.
'    bcc has no CSE, so three inline `Self.myclub.strength` reads would emit three loads;
'    the Local colours edx and costs no frame slot.
'  * The 100.0 guard is `If v < 100.0 / Return 100 / Else ... End If`.  Written the other
'    way round (`If v >= 100.0 ... Else Return 100`) bcc folds the negation into the setcc
'    and emits `setb` where the original has `setae`, and the body comes out 1387 bytes.
' The age table is a Select (24 Case compares back to back at 0x0056A4B6, guide 10.2).
Local yr:Int = Self.date.GetYear()
Self.myclub.GetActualLeagueId()
Local sr:Float = Self.GetSkillRating()
Local ac:Int = Int(Self.GetAchievements() * 0.5)
Local fm:Int = Int(Self.GetFame() * 0.5)
Local gs:Float = Self.GetStat(18, 3, 0, yr)
If yr > 1 Then gs :+ Self.GetStat(18, 3, 0, yr - 1) * 0.5
gs :+ Self.GetStat(18, 4, 0, 0)
gs = gs * 10.0
Local v:Float = sr * sr * ac * fm * gs * 0.0000001
Local st:Int = Self.myclub.strength
v :* (st * st * st)
Select Self.GetAge()
Case 16
	v = v * 1.0
Case 17
	v = v * 1.0
Case 18
	v = v * 1.0
Case 19
	v = v * 1.0
Case 20
	v = v * 1.0
Case 21
	v = v * 1.0
Case 22
	v = v * 1.0
Case 23
	v = v * 1.0
Case 24
	v = v * 1.0
Case 25
	v = v * 1.0
Case 26
	v = v * 1.0
Case 27
	v = v * 0.95
Case 28
	v = v * 0.9
Case 29
	v = v * 0.85
Case 30
	v = v * 0.8
Case 31
	v = v * 0.75
Case 32
	v = v * 0.7
Case 33
	v = v * 0.65
Case 34
	v = v * 0.6
Case 35
	v = v * 0.55
Case 36
	v = v * 0.5
Case 37
	v = v * 0.4
Case 38
	v = v * 0.3
Case 39
	v = v * 0.2
Default
	v = v * 0.1
End Select
If v < 100.0
	Return 100
Else
	If v > 1000000.0
		v = (Int(v) / 100000) * 100000
	ElseIf v > 100000.0
		v = (Int(v) / 10000) * 10000
	ElseIf v > 50000.0
		v = (Int(v) / 1000) * 1000
	ElseIf v > 10000.0
		v = (Int(v) / 500) * 500
	ElseIf v > 1000.0
		v = (Int(v) / 100) * 100
	Else
		v = (Int(v) / 10) * 10
	End If
	Return Int(v)
End If
