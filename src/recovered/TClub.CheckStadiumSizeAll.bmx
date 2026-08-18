' TClub.CheckStadiumSizeAll
' VA 0x004C2311   464 bytes   mode=reloc   MATCH 464/464
' KIND=Function (static method on TClub), SIG ()i, class-table slot 0x90.
' Body-only format: statements only, parameters are a0, a1, ...
'
' ASSUMPTIONS
'  * Global 0x00C6099C declared TList (globals_final.tsv has it as bare "Object",
'    init=bbNullObject, no call-site typing). It is dispatched through slot 0x8C =
'    ObjectEnumerator and the loop downcasts to ClassTable_TCompetition, so it is a TList of
'    TCompetition. Name is ours.
'  * Global 0x00C59A44 likewise TList, downcast to ClassTable_TClub. Name is ours.
'  * TCompetition fields (object_model.json): compstatus 0x50, locale 0x18, comptype 0x24.
'  * TClub Extends TBase_Team (class_tables.tsv super 0x00C596AC), so strength 0x24,
'    stadiumcapacity 0x38 and name 0x10 are the inherited TBase_Team fields.
'  * 0x00505B91 = LogLine (src/recovered_module/); 0x004A7C20 = the string concat bcc emits
'    for "literal" + name.
'  * The literal at 0x00C70D38 was read out of NSS5.exe with harness.read_string():
'    'Club stadium upgrade:' (no trailing space). The oracle masks the literal's address, so
'    that spelling is certified by the read, not by the MATCH.
'  * Cascade form is ElseIf, not three separate Ifs: the first two arms end in an
'    unconditional jmp to the loop tail (E9 8A.. and EB 44).
'!Global g_competitions:TList
'!Global g_clubs:TList
For Local c:TCompetition = EachIn g_competitions
	If c.compstatus > 0 And c.locale = 0 And c.comptype = 0 Then
		For Local cl:TClub = EachIn g_clubs
			If cl.strength > 80 And cl.stadiumcapacity < 20000 Then
				cl.stadiumcapacity = 20000
				LogLine("Club stadium upgrade:" + cl.name)
			ElseIf cl.strength > 70 And cl.stadiumcapacity < 10000 Then
				cl.stadiumcapacity = 10000
				LogLine("Club stadium upgrade:" + cl.name)
			ElseIf cl.strength > 60 And cl.stadiumcapacity < 5000 Then
				cl.stadiumcapacity = 5000
				LogLine("Club stadium upgrade:" + cl.name)
			EndIf
		Next
	EndIf
Next
