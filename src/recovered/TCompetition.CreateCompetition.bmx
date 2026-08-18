' TCompetition.CreateCompetition
' VA 0x005092E3   2026 bytes   KIND=Function (static)   SIG=($,:TStream)i   slot 0x34
'
' MODULE GLOBAL
'   0x00C6EF74 -> g_club_int07:Int -- the SAME address TClub.CreateClub already declares
'   under this name (globals_final.tsv associates it with TClub, but section 10.7/11.2 of
'   the codegen guide establish the table's "owning Type" column is not load-bearing; it is
'   one module Global read here on `cmp dword [0xc6ef74],0`, no retain/release, so Int).
'   Selects whether TCompetition.labelname is the full name or the tla, exactly the same
'   choice TClub.CreateClub makes for its own labelname/labelshortname.
'
' CALL TARGETS RESOLVED
'   0x00505BCB -> module Function NextFieldInt($ Var,$)i   (src/recovered_module)
'   0x00505C64 -> module Function NextField($ Var,$)$      (src/recovered_module)
'   0x00505F6D -> module Function ClampInt(*i,i,i)i        (src/recovered_module)
'   0x004A8F20 -> _bbObjectNew -- `New TCompetition` (classtable 0x00C615C0) and
'                 `New TTeamPool` (classtable 0x00C64940)
'   0x004A8590 -> inlined BBRELEASE's GC free; never written in source
'   0x004A6A30 -> _bbStringCompare -- both the TLA literal-equality chain and the "//"
'                 sentinel-line tests
'   0x004A6480 -> _bbArraySlice("TTeamPool", arr, beg, end) -- what `arr = arr[..n]` lowers
'                 to (confirmed identically in TCompetition.CreateTeamPool)
'   0x005B80B9 -> alias set incl. _brl_stream_Eof -- `Eof(a1)`
'   0x005B82EF -> alias set incl. _brl_stream_ReadLine -- `ReadLine(a1)`
'   call [0x00C5A2D4] -> TFixture+0x34 = CreateFromString($):TFixture (classtable+slot)
'   call [obj+0x30] on the new TTeamPool -> TTeamPool.LoadData(:TStream)i
'   call [obj+0x44] on lfixturelist -> TList.AddLast(:Object):TLink
'   call [obj+0xB8] on Self -> TCompetition.SetPriority()
'   call [obj+0x118] on Self -> TCompetition.SortFixtureList()
'
' LITERALS -- read out of NSS5.exe with harness.read_string (a MATCH masks a literal's
' ADDRESS, never its text):
'   0x00C6FCC0 "~t"    0x00C6FE94 "//"
'   0x00C7C7B0 "EURO1"       0x00C7C7C8 "UEFA WCQ"     0x00C7C7E4 "EUROQF"
'   0x00C7C7FC "EUROSF"      0x00C7C814 "EUROF"        0x00C7C82C "EURO QF"
'   0x00C7C848 "EURO SF"     0x00C7C864 "EURO FNL"
'
' FIELD OFFSETS (object_model.json, TCompetition)
'   +0x08 id  +0x0C name  +0x10 tla  +0x14 labelname  +0x18 locale  +0x1C level
'   +0x20 based  +0x24 comptype  +0x28 startyear  +0x2C startweek  +0x30 duration
'   +0x34 recurring  +0x38 primarymatchday  +0x3C secondarymatchday  +0x40 groups
'   +0x44 rounds  +0x48 legs  +0x4C townregion  +0x50 compstatus  +0x54 priority
'   +0x58 minstrength  +0x5C maxstrength  +0x60 lfixturelist:TList
'   +0x64 lpromotionplaces:TList  +0x68 lplacesthatpromotetome:TList
'   +0x6C teampool:TTeamPool[]
'
' ORIGINAL QUIRK -- +0x54 priority is never read from the CSV line at all: the parse walks
' straight from compstatus (+0x50) to minstrength (+0x58), skipping it. Verified against the
' full disassembly (no `[edi + 0x54]` operand anywhere in the function). SetPriority(), which
' this function calls near its end, is presumably what actually fills it in.
'
' SOURCE FORM
'   `Local line:String = a0` is a genuine separate frame slot at [ebp-4] (distinct from the
'   parameter's own [ebp+8]) -- every NextField/NextFieldInt call passes `lea eax,[ebp-4]`.
'   The id guard is the EARLY-RETURN spelling `< 1` (cmp ebx,1 / jge), same family as
'   TStadium.CreateStadium / TClub.CreateClub / TNation.CreateNation.
'   The g_club_int07 If/Else is byte-identical in shape to TClub.CreateClub's: `je` on the
'   zero test lands on the tla-branch, so the FALL-THROUGH (non-zero) branch is `Then` and
'   sets labelname = name; this is not the section-21 swap case, it decompiles exactly as
'   written, matching the already-verified sibling.
'   The startweek cascade (233-247 in the original) is FIVE INDEPENDENT `If x > N Then x :- N`
'   statements over 50/40/30/20/10, each re-testing the field's current (already-reduced)
'   value -- not an ElseIf chain, confirmed by each `cmp`/`jle` pair being self-contained with
'   its own fall-through to the next.
'   `line` is REUSED (not a fresh Local) as the loop variable holding each `ReadLine(a1)`
'   result in both trailing While loops -- same [ebp-4] slot the CSV parse used, confirmed by
'   every ReadLine result being stored back to that identical frame offset.
'   The two trailing While loops are independent (not one loop with a mode flag): loop 1's
'   `Exit` and loop 2's own pretest jump land on the exact same address, which is simply what
'   two consecutive `While Not Eof(a1) ... Wend` loops compile to.
'   `comp.teampool = comp.teampool[..i+1]` grows the array one slot at a time inside the loop
'   (bbArraySlice("TTeamPool", teampool, 0, i+1)), matching TCompetition.CreateTeamPool's
'   already-verified use of the same idiom.

Function CreateCompetition:Int(a0:String, a1:TStream)
	'!Global g_club_int07:Int
	Local line:String = a0
	Local id:Int = NextFieldInt(line, "~t")
	If id < 1 Then Return 0
	Local comp:TCompetition = New TCompetition
	comp.id = id
	comp.name = NextField(line, "~t")
	comp.tla = NextField(line, "~t")
	If g_club_int07 <> 0
		comp.labelname = comp.name
	Else
		comp.labelname = comp.tla
	EndIf
	comp.locale = NextFieldInt(line, "~t")
	comp.level = NextFieldInt(line, "~t")
	comp.based = NextFieldInt(line, "~t")
	comp.comptype = NextFieldInt(line, "~t")
	comp.startyear = NextFieldInt(line, "~t")
	comp.startweek = NextFieldInt(line, "~t")
	comp.duration = NextFieldInt(line, "~t")
	If comp.comptype = 1 And comp.duration > 1 Then comp.duration = 1
	If comp.comptype = 0 And comp.locale = 0 And comp.level = 0
		If comp.startweek > 50 Then comp.startweek :- 50
		If comp.startweek > 40 Then comp.startweek :- 40
		If comp.startweek > 30 Then comp.startweek :- 30
		If comp.startweek > 20 Then comp.startweek :- 20
		If comp.startweek > 10 Then comp.startweek :- 10
	EndIf
	comp.recurring = NextFieldInt(line, "~t")
	comp.primarymatchday = NextFieldInt(line, "~t")
	comp.secondarymatchday = NextFieldInt(line, "~t")
	If comp.level = 0
		ClampInt(Varptr comp.primarymatchday, 1, 7)
		ClampInt(Varptr comp.secondarymatchday, 1, 7)
	Else
		If comp.primarymatchday = 99 And comp.duration > 8 Then comp.primarymatchday = 6
		If comp.secondarymatchday = 99 And comp.duration > 8 Then comp.secondarymatchday = 3
	EndIf
	If comp.comptype = 3 Or comp.comptype = 5 Or comp.comptype = 2
		comp.startweek = 1
		comp.duration = 0
		comp.primarymatchday = 99
		comp.secondarymatchday = 99
	EndIf
	comp.groups = NextFieldInt(line, "~t")
	If comp.groups < 1 Then comp.groups = 1
	comp.rounds = NextFieldInt(line, "~t")
	If comp.comptype = 1 Then comp.rounds = 1
	comp.legs = NextFieldInt(line, "~t")
	comp.townregion = NextFieldInt(line, "~t")
	comp.compstatus = NextFieldInt(line, "~t")
	comp.minstrength = NextFieldInt(line, "~t")
	comp.maxstrength = NextFieldInt(line, "~t")
	If comp.tla = "EURO1" Or comp.tla = "UEFA WCQ" Or comp.tla = "EUROQF" Or comp.tla = "EUROSF" Or comp.tla = "EUROF" Or comp.tla = "EURO QF" Or comp.tla = "EURO SF" Or comp.tla = "EURO FNL"
		comp.compstatus = 1
	EndIf
	comp.SetPriority()
	If a1 <> Null
		Local i:Int = 0
		While Not Eof(a1)
			line = ReadLine(a1)
			If line = "//" Then Exit
			comp.teampool = comp.teampool[..i + 1]
			comp.teampool[i] = New TTeamPool
			comp.teampool[i].LoadData(a1)
			i = i + 1
		Wend
		While Not Eof(a1)
			line = ReadLine(a1)
			If line = "//" Then Exit
			comp.lfixturelist.AddLast(TFixture.CreateFromString(line))
		Wend
	EndIf
	comp.SortFixtureList()
End Function
