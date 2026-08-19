' TCompetition.Test_CheckNoofTeamsInLeagues
' VA 0x0050FCFF   324 bytes   mode=reloc   reloc_masked=21
' byte-identical vs NSS5.exe
' KIND=Function (static method on the Type), SIG=()i, SLOT=0x130
' Body-only format: statements only, parameters are a0, a1, ...
'
' ASSUMPTIONS
'   Globals declared and typed:
'     0x00C6099C g_competitions:TList   (table said Object/low; call through slot 0x8C
'                                        ObjectEnumerator proves TList -- guide 10.7)
'   Fields (extracted/object_model.json, TCompetition):
'     +0x08 id:Int  +0x0C name:String  +0x24 comptype:Int
'     +0x6C teampool:TTeamPool[]  +0x70 tempNoofTeams:Int
'     TTeamPool +0x08 list:TList
'   Slots resolved:  TList 0x70 = Count(), TList 0x8C = ObjectEnumerator()
'   `If c.teampool` is the BARE array truth test -- original reads [eax+0x10] (size),
'     not [eax+0x14] (scales[0]), so it is NOT `.Length` (guide 11.1).
'   `c.teampool[0]` -- constant index 0 folds to [eax+0x18] (BBArray data).
'   Comparison written memory-operand-first to match `cmp dword [esi+0x70], eax`.
'   Calls: 0x00505B91 = LogLine (module Function, src/recovered_module/LogLine.bmx);
'     0x004A7AC0 = Int->String (1 arg), 0x004A7C20 = String concat (2 args) -- both
'     emitted implicitly by the `+` chain, 7 concats confirmed against the original.
'   String literals read from the image with harness.read_string:
'     0x00C7D5EC 0x00C7D660 0x00C6EF28 0x00C7D644 0x00C7D630
'!Global g_competitions:TList
LogLine("Test_CheckNoofTeamsInLeagues")
For Local c:TCompetition = EachIn g_competitions
	If c.teampool And c.comptype = 0
		If c.tempNoofTeams <> c.teampool[0].list.Count()
			LogLine("WARNING! Number of teams changed in: " + c.id + " " + c.name + ". From " + c.tempNoofTeams + " to " + c.teampool[0].list.Count())
		EndIf
	EndIf
Next
