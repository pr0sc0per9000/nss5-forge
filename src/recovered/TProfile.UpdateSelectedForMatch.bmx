' TProfile.UpdateSelectedForMatch
' VA 0x0056726C   1844 bytes   vtable slot 0x68   sig (f)i   KIND=Method
' byte-identical vs NSS5.exe (1844/1844, original length from Ghidra's inventory, mode=reloc,
' 53 addresses masked)
'
' Fields (TProfile): injury +0x16C, baninternational +0x1A0, bancontinent +0x19C,
'   banclub +0x198, relationboss +0x104, clubid +0x20, transferlisted +0x134,
'   myclub:TClub +0x1D0, mynation:TNation +0x1CC, date:TMyDate +0x10,
'   selectedformatch +0x1D8 (the output field this method computes).
' TFixture: level +0x3C (0=domestic, 1=international), compid +0x40.
' TClub/TNation both Extend TBase_Team: leagueid/climate +0x68, strength +0x24 (TBase_Team).
' TCompetition: locale +0x18 (Field, not a method); SelectById(i):TCompetition is a
'   cross-Type static Function at TCompetition's own class-table slot 0x4C
'   (call dword ptr [0xC6160C] -- classtable+slot, no receiver); IsTopDivision()i is a
'   virtual Method at slot 0x104 on the object SelectById returns.
' TMyDate: GetWeek()i slot 0x50, GetYear()i slot 0x54.
' TProfile: GetNextFixture(i):TFixture 0x58, GetStat(i,i,i,i)f 0x88,
'   GetAverageForm(i,i,i)f 0x98, GetLastMatchRating(i)i 0x9C (all already recovered
'   elsewhere in this Type).
' g_player_int15 (0x00C5D228) is a difficulty/league-tier selector already used by
'   TProfile.UpdateHealth.bmx and others; its Case values 1/2/3 gate different
'   thresholds throughout this body.
' String literals ("clubform:", "intform:", "lastmatch:", "rating:", "avgform:",
'   "relationship:") and every float constant (10.0, 20.0, 30.0, 5.0, 8.0, 1.0, 6.5, ...)
'   were read directly out of NSS5.exe's data section with harness.read_string /
'   struct.unpack, not guessed from Ghidra's decompilation (which masks both).
'
' Shape notes, all confirmed by byte match:
'  - `formvalue` (the running form score) is a bare `Local formvalue:Float` followed by a
'    SEPARATE `formvalue = 0.0` statement, not a combined `Local formvalue:Float = 0.0` --
'    the original emits a real fld/fstp store of 0.0 (from a Global at 0x00C8DD64) and a
'    combined declare+init to the constant 0.0 gets elided by bcc (codegen-patterns 16.3).
'  - The outer `fx.level` branch (international vs domestic) and all three `g_player_int15`
'    threshold tables are `Select`, not `If/ElseIf` -- each subject is loaded into a register
'    ONCE and every `Case` compares the SAME register (codegen-patterns 10.2). Writing them
'    as `If/ElseIf` instead re-reads the field/Global for every comparison and costs bytes
'    at every site (confirmed: 4 separate `Select` blocks, each length-exact only this way).
'  - `banned`, `bad`, `bad2`, `bad3`, `bad4` are single short-circuit boolean EXPRESSIONS
'    (`x:Int = cond1 And cond2`), not `Local x:Int` + `If cond1 Then x = cond2 EndIf` guard
'    blocks. The guard-block form emits an extra explicit `mov reg,0` zero-init that the
'    original does not have -- the original builds the boolean value directly via
'    `sete`/`setg`+`movzx` reused as the expression's own storage.
'  - `banned`'s two AND-terms are OR'd, and this needs EXPLICIT parentheses --
'    `(A And B) Or (C And D)` -- to get the right short-circuit shape. Without them the
'    original's full skip-the-whole-second-AND-term jump (0x20 bytes) comes out as a
'    partial 0x0C-byte skip instead; BlitzMax's And/Or do not associate the way a typical
'    C-family reader expects here.
'  - `Self.date.GetWeek() Mod 4 = 0` must be written as ONE expression, not split into a
'    `Local wk:Int = Self.date.GetWeek()` followed by `wk Mod 4 = 0` -- the original loads
'    the divisor constant 4 into a callee-saved register (ebx) BEFORE the GetWeek() call
'    (it is live across the call), which only happens when Mod's operands are evaluated as
'    a single expression; splitting it moves the constant load after the call into a
'    caller-saved register (ecx) and costs a same-length register-identity byte (`F7 FB`
'    vs `F7 F9`, codegen-patterns 18).
'  - `bad`/`bad2`/`bad3` reload `fx.level` fresh via three SEPARATE plain `If fx.level = N`
'    tests (each its own memory load from the `fx` Local's stack slot) -- these are NOT
'    part of either `Select fx.level` block above; verified by the original re-loading
'    `[ebp-0x14]` and `[eax+0x3C]` at each site rather than reusing a cached register.
'!Global g_player_int15:Int
	LogLine("UpdateSelectedForMatch")
	If Self.injury > 0
		Self.selectedformatch = -5
		Return 0
	EndIf
	Local fx:TFixture = Self.GetNextFixture(0)
	Local formvalue:Float
	formvalue = 0.0
	Select fx.level
	Case 1
		If Self.baninternational > 0
			Self.selectedformatch = -6
			Return 0
		EndIf
		Local clubform:Float = Self.GetAverageForm(3, 0, 0)
		Local intformf:Float = Self.GetAverageForm(4, 0, 0)
		Local intform:Int = Int(intformf)
		Local lastmatch:Int = Self.GetLastMatchRating(3)
		formvalue = clubform + intform + lastmatch
		LogLine("clubform:" + clubform)
		LogLine("intform:" + intform)
		LogLine("lastmatch:" + lastmatch)
		LogLine("rating:" + formvalue)
		If TCompetition.SelectById(Self.myclub.leagueid).IsTopDivision() = 0
			Self.selectedformatch = -2
			Return 0
		EndIf
		Select g_player_int15
		Case 1
			If Self.GetStat($C, 3, 0, 0) < 10.0
				Self.selectedformatch = -3
				Return 0
			EndIf
		Case 2
			If Self.GetStat($C, 3, 0, 0) < 20.0
				Self.selectedformatch = -3
				Return 0
			EndIf
		Case 3
			If Self.date.GetYear() < 2
				Self.selectedformatch = -3
				Return 0
			EndIf
		End Select
		If a0 < 30.0
			Self.selectedformatch = -7
			Return 0
		EndIf
	Case 0
		Local comp2:TCompetition = TCompetition.SelectById(fx.compid)
		Local banned:Int = (comp2.locale = 1 And Self.bancontinent > 0) Or (comp2.locale = 0 And Self.banclub > 0)
		If banned
			Self.selectedformatch = -6
			Return 0
		EndIf
		If Self.relationboss < 15
			Self.selectedformatch = -4
			Return 0
		EndIf
		If a0 < 20.0
			Self.selectedformatch = -7
			Return 0
		EndIf
		Local recentform:Float = Self.GetAverageForm(3, 0, 0)
		Local lastmatch2:Int = Self.GetLastMatchRating(3)
		Local relb:Int = Self.relationboss / 10
		If Self.GetStat($C, 3, Self.clubid, Self.date.GetYear()) < 5.0 And recentform < 8.0
			recentform = 8.0
		EndIf
		If Self.transferlisted = 4
			If recentform < 5.0
				recentform = 5.0
			EndIf
			recentform = recentform + 1.0
		EndIf
		formvalue = recentform + lastmatch2 + relb
		LogLine("avgform:" + recentform)
		LogLine("lastmatch:" + lastmatch2)
		LogLine("relationship:" + relb)
		LogLine("rating:" + formvalue)
	End Select
	Local formLow:Int = 12
	Local formHigh:Int = 19
	Select g_player_int15
	Case 1
		formLow = 11
		formHigh = 18
	Case 2
		formLow = 12
		formHigh = 19
	Case 3
		formLow = 13
		formHigh = 20
	End Select
	If formvalue < formLow
		If Self.date.GetWeek() Mod 4 = 0
			Self.selectedformatch = 2
		Else
			Self.selectedformatch = -1
		EndIf
		Return 0
	EndIf
	If formvalue < formHigh
		Self.selectedformatch = 2
		Return 0
	EndIf
	Local domMin:Int = 0
	Local intlMin:Int = 0
	Select g_player_int15
	Case 1
		domMin = 0
		intlMin = 1
	Case 2
		domMin = 0
		intlMin = 2
	Case 3
		domMin = 3
		intlMin = 3
	End Select
	Local bad:Int = fx.level = 0 And Self.GetStat($C, 3, 0, 0) < domMin
	If bad
		Self.selectedformatch = 2
		Return 0
	EndIf
	Local bad2:Int = fx.level = 1 And Self.GetStat($C, 4, 0, 0) < intlMin
	If bad2
		Self.selectedformatch = 2
		Return 0
	EndIf
	Local bad3:Int = fx.level = 1 And Self.myclub.strength < Self.mynation.strength - 20
	Local bad4:Int = bad3 And Self.GetStat($12, 4, 0, 0) < 6.5
	If bad4
		Self.selectedformatch = 2
		Return 0
	EndIf
	If a0 < 30.0
		Self.selectedformatch = 3
		Return 0
	EndIf
	Self.selectedformatch = 1
	Return 0
