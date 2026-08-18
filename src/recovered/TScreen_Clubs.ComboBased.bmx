' TScreen_Clubs.ComboBased
' VA 0x0052CB85   606 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function (static, no implicit Self), SIG ()i, class-table slot 0x3C
'
' ASSUMPTIONS
'   0x00C65234 g_clubs_combolocale:TCombo  ) names/types already used elsewhere in the
'   0x00C65238 g_clubs_combobased:TCombo   ) corpus; all three are typed TCombo by their
'   0x00C6523C g_clubs_combocomp:TCombo    ) construction sites in globals_final.tsv
'   0x00C6099C g_competitions:TList        (ObjectEnumerator at slot 0x8C)
'   TCombo slots 0x8C ClearItems, 0x90 AddItem($,$,$,i), 0xBC GetSelectedItem,
'   0xC0 GetSelectedItemId.  Class-table statics: 0x00C59A20 TNation+0x58 SelectById,
'   0x00C60998 TContinent+0x40 SelectById, 0x00C6539C TScreen_Clubs+0x34 SetUpScreen
'   (same Type -> bare name).
'
' MEASURED SHAPE
'   * `cmp eax,1 / je` immediately followed by `cmp eax,2 / je` then an unconditional jmp
'     is a Select, not If/ElseIf (codegen-patterns 10.2).
'   * The last conjunct is an Or, not an And: when the nation/continent lookup returns
'     Null the item IS added.  `Not n` is the 21-byte setne/movzx/cmp/sete/movzx form,
'     and its true-branch `jne` lands on the shared join, which is what makes the Or
'     readable in the bytes.
'   * GetSelectedItem() is called a SECOND time inside the loop -- bcc does no CSE and
'     the original really does re-dispatch it every iteration.
'!Global g_clubs_combolocale:TCombo
'!Global g_clubs_combobased:TCombo
'!Global g_clubs_combocomp:TCombo
'!Global g_competitions:TList
LogLine("ComboBased")
g_clubs_combocomp.ClearItems()
Select g_clubs_combolocale.GetSelectedItem()
	Case 1
		Local n:TNation = TNation.SelectById(g_clubs_combobased.GetSelectedItemId())
		For Local c:TCompetition = EachIn g_competitions
			If c.level = 0 And c.locale = g_clubs_combolocale.GetSelectedItem() - 1 And (Not n Or c.based = n.id)
				g_clubs_combocomp.AddItem(c.name, "BBBBBB", "FFFFFF", 0)
			End If
		Next
	Case 2
		Local ct:TContinent = TContinent.SelectById(g_clubs_combobased.GetSelectedItemId())
		For Local c:TCompetition = EachIn g_competitions
			If c.level = 0 And c.locale = g_clubs_combolocale.GetSelectedItem() - 1 And (Not ct Or c.based = ct.id)
				g_clubs_combocomp.AddItem(c.name, "BBBBBB", "FFFFFF", 0)
			End If
		Next
End Select
SetUpScreen()
