' TCompetition.NewCompetition
' VA 0x00509ACD   352 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function (static method on the Type), SIG=(i):TCompetition, class-table slot 0x38
' ORACLE 352/352 reloc_masked=10, re-run under NSS5_NO_LEARN=1 (learned_helpers
'   empty, so no call operand was masked by a name this body taught the table).
'
' assumes module global:  Global g_competitions:TList     ' 0x00c6099c
'   (globals_final types it Object/low confidence; slot 0x8c ObjectEnumerator is used
'    here, which per codegen-patterns 10.7 is the TList tell.)
'
' CODEGEN NOTE -- Ghidra prints `if (iVar6 < puVar4[2])` for the running maximum, but the
' original is `cmp dword [eax+8], esi / jle`, i.e. the FIELD is the left operand:
'     If c.id > highest      -> 39 70 08 / 7E     (correct, 352/352)
'     If highest < c.id      -> 3B 70 08 / 7D     (diverges at byte 88, same length)
' This is exactly the operand-order normalisation of section 10.1.
'
' `found` is the function's only stack local ([ebp-4], initialised to bbNullObject);
' `highest` and the New'd competition are register-allocated. Object locals carry no
' retain/release here.

	Function NewCompetition:TCompetition(a0:Int)
		'!Global g_competitions:TList
		Local highest:Int = 1
		Local found:TCompetition = Null
		For Local c:TCompetition = EachIn g_competitions
			If c.id = a0 Then found = c
			If c.id > highest Then highest = c.id
		Next
		Local comp:TCompetition = New TCompetition
		comp.id = highest + 1
		If found <> Null
			comp.name = found.name
			comp.tla = found.tla
			comp.locale = found.locale
			comp.level = found.level
			comp.based = found.based
			comp.comptype = found.comptype
			comp.startyear = found.startyear
			comp.startweek = found.startweek
			comp.duration = found.duration
			comp.recurring = found.recurring
			comp.primarymatchday = found.primarymatchday
			comp.secondarymatchday = found.secondarymatchday
			comp.groups = found.groups
			comp.rounds = found.rounds
			comp.legs = found.legs
			comp.townregion = found.townregion
			comp.compstatus = found.compstatus
		EndIf
		Return comp
	End Function
