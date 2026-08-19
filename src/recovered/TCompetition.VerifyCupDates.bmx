' TCompetition.VerifyCupDates
' VA 0x0050E7C6   416 bytes   mode=reloc   MATCH 416/416
' KIND=Function (static method on TCompetition), SIG=()i, SLOT=0x10C
' Body-only format: statements only, parameters are a0, a1, ...
'
' ASSUMPTIONS
'   Globals declared here (name is ours; the original is unrecoverable):
'     0x00C6099C -> g_competitions:TList
'         globals_final says type=Object/usage/low. Typed TList from the code: slot 0x8c
'         (TList.ObjectEnumerator) is called on it and the loop downcasts to
'         ClassTable_TCompetition.
'   Slots resolved:
'     [0xC616DC] = TCompetition+0x11C -> SortListBy(i,i)i        (own Type -> unprefixed)
'     [0xC6160C] = TCompetition+0x4C  -> SelectById(i):TCompetition (own Type -> unprefixed)
'     [0xC6632C] = TMyDate+0x30       -> TMyDate.Create(i,i,i):TMyDate
'     TMyDate slots 0x3C AddDays, 0x4C GetDay, 0x50 GetWeek, 0x54 GetYear
'   Fields (object_model.json): TCompetition +0x18 locale, +0x20 based, +0x24 comptype,
'     +0x28 startyear, +0x2C startweek, +0x38 primarymatchday, +0x68
'     lplacesthatpromotetome:TList; TPromotionPlace +0x08 parentid; TMyDate +0x08 sdate.
'   The `puVar3 != Null` / `puVar6 != Null` guards Ghidra prints are the null-skip that
'   For..EachIn emits itself (guide 10.6) and are NOT written.
' byte-identical vs NSS5.exe
'!Global g_competitions:TList
SortListBy(1,1)
For Local c:TCompetition = EachIn g_competitions
	If c.comptype = 1
		Local d:TMyDate = TMyDate.Create(c.primarymatchday,c.startweek,c.startyear)
		For Local pp:TPromotionPlace = EachIn c.lplacesthatpromotetome
			Local c2:TCompetition = SelectById(pp.parentid)
			If c2 <> Null And c2.locale = c.locale And c2.based = c.based
				Local d2:TMyDate = TMyDate.Create(c2.primarymatchday,c2.startweek,c2.startyear)
				d2.AddDays(6)
				If d.sdate < d2.sdate
					d.sdate = d2.sdate
					While d.GetDay() <> c.primarymatchday
						d.AddDays(1)
					Wend
					c.startyear = d.GetYear()
					c.startweek = d.GetWeek()
				EndIf
			EndIf
		Next
	EndIf
Next
