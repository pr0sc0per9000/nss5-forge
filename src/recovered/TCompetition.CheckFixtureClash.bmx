' TCompetition.CheckFixtureClash
' VA 0x0050BEF9   757 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Method (implicit Self at [ebp+8]; a0 is the TMyDate), SIG=(:TMyDate)i,
'   class-table slot 0x74
' ORACLE 757/757 reloc_masked=13, first attempt.
'
' ASSUMPTIONS / RESOLUTIONS
'   Globals (name is OURS; the TYPE is load-bearing):
'     0x00C6099C -> g_competitions:TList  (slot 0x8C ObjectEnumerator; the same address and
'       name TCompetition.NewCompetition already declares)
'   Calls: 0x004A7C20 = _bbStringConcat, 0x004A8F60 = _bbObjectDowncast,
'     0x00505B91 = LogLine (module Function). TMyDate slot 0x50 = GetWeek(),
'     TCompetition slot 0x80 = GetMyContinentId().
'   Field offsets (object_model.json): TCompetition +0x08 id, +0x0C name, +0x14 labelname,
'     +0x18 locale, +0x1C level, +0x20 based, +0x24 comptype, +0x60 lfixturelist:TList;
'     TMyDate/TFixture +0x08 sdate.
'   String literals read out of NSS5.exe: 0x00C7CE04 "Clash: ", 0x00C7CDEC " with ".
'
' CODEGEN NOTES
'   The opening guard is a real early `Return 1` (`mov eax,1 / jmp epilogue`), with the
'   whole search as the fall-through and a final `Return 0`.
'   `a0.GetWeek()` is called TWICE -- bcc does no CSE, so the Or must be spelled with two
'   calls, not hoisted into a Local.
'   The four-arm cascade is If/ElseIf (test and body interleaved), not Select: the subject
'   changes from arm to arm.
'   The innermost test assigns clash=0 on the MATCHING side and clash=1 on the else side;
'   spelling it as `If Not (...) Then clash = 1` loses the `bVar10 = false` arm.
	Method CheckFixtureClash:Int(a0:TMyDate)
		'!Global g_competitions:TList
		If Self.level = 1 And (a0.GetWeek() > 47 Or a0.GetWeek() < 7)
			Return 1
		EndIf
		Local cont:Int = Self.GetMyContinentId()
		For Local c:TCompetition = EachIn g_competitions
			If c.id <> Self.id
				Local clash:Int = 0
				If c.level = 1 And c.locale = 2
					clash = 1
				ElseIf Self.level = 0 And c.level = 1 And cont = c.based
					clash = 1
				ElseIf Self.level = 0 And Self.locale = 0 And c.level = 0 And c.locale = 1 And cont = c.based
					clash = 1
				ElseIf Self.level = 0 And c.level = 0 And Self.locale = c.locale And Self.based = c.based
					If (c.comptype = 0 Or c.comptype = 4) And (Self.comptype = 0 Or Self.comptype = 4)
						clash = 0
					Else
						clash = 1
					EndIf
				EndIf
				If clash
					For Local f:TFixture = EachIn c.lfixturelist
						If f.sdate = a0.sdate
							LogLine("Clash: " + Self.name + " with " + c.labelname)
							Return 1
						EndIf
					Next
				EndIf
			EndIf
		Next
		Return 0
	End Method
