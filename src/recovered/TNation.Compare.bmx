' TNation.Compare
' VA 0x004BFB48   629 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Method, SIG=(:Object)i, class-table slot 0x1c
' ORACLE 629/629 reloc_masked=34, re-run under NSS5_NO_LEARN=1 (learned_helpers
'   empty, so no call operand was masked by a name this body taught the table).
' Body-only format: statements only, parameters are a0, a1, ...
'
' ASSUMPTIONS
'   Globals declared and typed:
'     0x00C596F4 g_nation_sortby:Int  (bare dword, no refcount traffic -> Int)
'     NOTE this is NOT the same Global as TBase_Team.Compare's 0x00C59310; the two
'     Compare methods key off different sort selectors.
'   TNation Extends TBase_Team (class_tables.tsv), so id(+0x0C), labelname(+0x1C),
'     strength(+0x24) and randno(+0x08) are all inherited TBase_Team fields.
'   Calls: 0x004A8F60 = bbObjectDowncast (the TNation(a0) casts, one per comparison --
'     bcc does no CSE, hence the repetition); 0x0059F089 = _brl_random_Rand;
'     0x004A6A30 = String compare; 0x004BD41E = TBase_Team.Compare (Super).
'
' CODEGEN NOTES
'   * Same family as TBase_Team.Compare -- Select, not If/ElseIf, and no Default: the
'     tail comparisons and `Return Super.Compare` sit AFTER End Select, which is what
'     emits each Case's trailing jmp.
'   * Case order 1, 2, 11, 15, 5 is the original's order, not sorted.
'   * Operand order is byte-observable. `id` keeps Self on the left (cmp [edi+0xC],eax);
'     labelname / strength / randno put the downcast on the left (cmp [eax+8],edx and
'     the bbStringCompare argument order). Ghidra normalises all of these away.
'   * `Rand(5)` supplies BlitzMax's default max_value=1, giving `push 1 / push 5`.
'   * `strength + Rand(5)` loads strength into ebx BEFORE the call (left-to-right).
'!Global g_nation_sortby:Int
If a0 = Self Then Return 0
Select g_nation_sortby
	Case 1
		If id > TNation(a0).id Then Return 1
		If id < TNation(a0).id Then Return -1
	Case 2
		If TNation(a0).labelname < labelname Then Return 1
		If TNation(a0).labelname > labelname Then Return -1
	Case 11
		If TNation(a0).strength < strength Then Return 1
		If TNation(a0).strength > strength Then Return -1
	Case 15
		If TNation(a0).strength > strength + Rand(5) Then Return 1
		If TNation(a0).strength < strength - Rand(5) Then Return -1
		If TNation(a0).randno > randno Then Return 1
		If TNation(a0).randno < randno Then Return -1
	Case 5
		If TNation(a0).randno < randno Then Return 1
		If TNation(a0).randno > randno Then Return -1
End Select
If id > TNation(a0).id Then Return 1
If id < TNation(a0).id Then Return -1
Return Super.Compare(a0)
