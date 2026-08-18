' TCompetition.WriteData
' VA 0x00509d95   1082 bytes   vtable slot 0x40   KIND=Function (static)   sig (:TStream,i)i
' byte-identical vs NSS5.exe (1082/1082, harness mode=reloc)
'
' MODULE GLOBALS (name ours; type load-bearing)
'   0x00C6099C g_competitions:TList -- slot 0x8C ObjectEnumerator opens the loop; same
'                                      identity TCompetition.LoadData already declares.
' RESOLVED CALLS
'   0x005B8307 WriteLine (ALIAS SET, first argument is the TStream parameter -- guide 3h)
'   TTeamPool + 0x34 = WriteData(:TStream)i ; TFixture + 0x38 = WriteData(:TStream)i
'   TList + 0x38 = IsEmpty (BRL slot order: New 0x10, Delete 0x14, _pad, Clear 0x34,
'                           IsEmpty 0x38) -- read off extracted/brl_type_methods.tsv
'   _bbStringFromInt / _bbStringConcat / _bbObjectDowncast are implicit.
'
' SEPARATOR SIDE IS THE OPPOSITE OF WriteDataMobile'S, and it is byte-observable (16.1):
'   here the original emits _bbStringConcat(field, "~t") then _bbStringConcat(acc, that),
'   i.e. the tab groups with the field on its RIGHT -> `s :+ field + "~t"`, and the FIRST
'   column is the accumulator's initialiser (`Local s:String = c.id + "~t"`, no acc concat).
'   Every column, including the last, carries a trailing tab.
'
' The written column list SKIPS TCompetition.priority (+0x54) between compstatus (+0x50) and
' minstrength (+0x58) -- 20 columns, exactly matching the header literal at 0x00C7C964, which
' was read out of NSS5.exe with harness.read_string.
' field offsets: +0x08 id +0x0c name +0x10 tla +0x18 locale +0x1c level +0x20 based
'   +0x24 comptype +0x28 startyear +0x2c startweek +0x30 duration +0x34 recurring
'   +0x38 primarymatchday +0x3c secondarymatchday +0x40 groups +0x44 rounds +0x48 legs
'   +0x4c townregion +0x50 compstatus +0x58 minstrength +0x5c maxstrength
'   +0x60 lfixturelist:TList  +0x6c teampool:TTeamPool[]
Function WriteData:Int(a0:TStream, a1:Int)
	'!Global g_competitions:TList
	WriteLine(a0, "id~tname~ttla~tlocale~tlevel~tbased~tcomptype~tstartyear~tstartweek~tduration~trecurring~tprimarymatchday~tsecondarymatchday~tgroups~trounds~tlegs~ttownregion~tcompstatus~tminstrength~tmaxstrength")
	For Local c:TCompetition = EachIn g_competitions
		Local s:String = c.id + "~t"
		s :+ c.name + "~t"
		s :+ c.tla + "~t"
		s :+ c.locale + "~t"
		s :+ c.level + "~t"
		s :+ c.based + "~t"
		s :+ c.comptype + "~t"
		s :+ c.startyear + "~t"
		s :+ c.startweek + "~t"
		s :+ c.duration + "~t"
		s :+ c.recurring + "~t"
		s :+ c.primarymatchday + "~t"
		s :+ c.secondarymatchday + "~t"
		s :+ c.groups + "~t"
		s :+ c.rounds + "~t"
		s :+ c.legs + "~t"
		s :+ c.townregion + "~t"
		s :+ c.compstatus + "~t"
		s :+ c.minstrength + "~t"
		s :+ c.maxstrength + "~t"
		WriteLine(a0, s)
		If a1 = 0
			For Local tp:TTeamPool = EachIn c.teampool
				tp.WriteData(a0)
			Next
			WriteLine(a0, "//")
			If c.lfixturelist <> Null And c.lfixturelist.IsEmpty() = 0
				For Local f:TFixture = EachIn c.lfixturelist
					f.WriteData(a0)
				Next
			EndIf
			WriteLine(a0, "//")
		EndIf
	Next
	WriteLine(a0, "//")
End Function
