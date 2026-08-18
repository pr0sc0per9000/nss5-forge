' TCompetition.WriteDataMobile
' VA 0x0050A1CF   766 bytes   class-table slot 0x44   KIND=Function (static)
' sig (:TStream,i)i   -- a0:TStream, a1:Int (a1 is UNUSED by the body)
' byte-identical vs NSS5.exe (766/766, original length from Ghidra's inventory, mode=reloc)
' Body-only format: statements only, parameters are a0, a1.
'
' ASSUMPTIONS / RESOLUTIONS
'  * Global 0x00C6099C declared TList (globals_final.tsv says only `Object`,
'    type_source=usage, confidence=low). TList is forced by the call site: slot 0x8C =
'    TList.ObjectEnumerator, and the downcast class table in the loop is TCompetition.
'  * 0x005B8307 = _brl_stream_WriteLine, 0x004A7AC0 = _bbStringFromInt,
'    0x004A7C20 = _bbStringConcat.
'  * String literals read out of NSS5.exe's .data at the pushed BBString addresses; the
'    separator constant at 0x00C6FCC0 is a single TAB and the trailer at 0x00C6FE94 is "//".
'  * The concat grouping is the load-bearing detail. The original builds
'    concat(s, concat(field, TAB)) for every field -- i.e. `s :+ field + "~t"`, NOT a
'    left-associated `s = s + field + "~t"` (which would emit concat(concat(s,field),TAB)).
'  * 17 fields written, in the exact order named by the header line.
'!Global g_competitions:TList
WriteLine(a0, "id~ttla~tlocale~tlevel~tbased~tcomptype~tstartyear~tstartweek~tduration~trecurring~tprimarymatchday~tsecondarymatchday~tgroups~trounds~tlegs~ttownregion~tcompstatus")
For Local c:TCompetition = EachIn g_competitions
	Local s:String = c.id + "~t"
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
	WriteLine(a0, s)
Next
WriteLine(a0, "//")
