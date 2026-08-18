' TScreen_Clubs.SetUpScreen
' VA 0x0052BEAC   2980 bytes   mode=reloc   byte-identical vs NSS5.exe (2980/2980)
' Verified with NSS5_NO_LEARN=1 (learned_helpers=None), reloc_masked=130.
' scripts/localise_diff.py: CLEAN -- 0 gaps, 0 subs, 0 branch shifts.
' KIND=Function (static, no implicit Self), SIG ()i, class-table slot 0x34
'
' ASSUMPTIONS (Global names are ours; types are load-bearing)
'   0x00C65234 g_clubs_combolocale:TCombo  ) same three combos as the already-verified
'   0x00C65238 g_clubs_combobased:TCombo   ) TScreen_Clubs.ComboBased / .ComboLocale;
'   0x00C6523C g_clubs_combocomp:TCombo    ) typed TCombo by their construction sites
'   0x00C65240 g_clubs_table:TTable        -- globals_final.tsv says TButton and is WRONG:
'                                             slots 0x94 AddItem([]$,$,$), 0x9C ClearItems,
'                                             0xA4 SetColumnWidth(i,i), 0xEC CountItems are
'                                             all TTable's and TButton has none of them.
'   0x00C65244 g_clubs_title:TButton       (slot 0x64 = TGadget.SetText, inherited)
'   0x00C65248 g_clubs_btnnames:TButton    (slot 0x64 = TGadget.SetText, inherited)
'   0x00C6524C g_clubs_shownames:Int       (bare dword compare, no refcount traffic)
'   0x00C59A44 g_clubs:TList               (ObjectEnumerator 0x8C; downcast to TClub 0xC59DAC)
'   0x00C596F0 g_nations:TList             (downcast to TNation 0xC599C8)
'   Class-table statics: TScreen+0x5C SetActive, TClub+0x94 SortListBy,
'   TClub+0x6C SelectListByLeagueId, TNation+0x58 SelectById,
'   TContinent+0x40 SelectById, TCompetition+0x50 SelectByBasedAndName.
'
' MEASURED SHAPE
'   * sub esp,0x28 = 10 dword slots. bcc register-allocates the rest (ebx/esi/edi and, for
'     the Case-2 TContinent whose live range crosses no call, plain eax) -- which is why
'     Case 1 spills `nat` to [ebp-0x24] but Case 2 never stores its continent anywhere.
'   * The club filter is NESTED Ifs, not `A And B`. Both forms emit the SAME 2980 bytes;
'     they differ only in one `je` displacement. `And` lowers the short-circuit jump to the
'     join that materialises the expression value (+0x26), nested Ifs jump straight to the
'     If's false target at the loop bottom (+0x54). The oracle caught exactly that one byte.
'   * Every `Select` here is a real Select (10.2): all Case compares back to back, then the
'     no-match jmp. The 0x52C3F8 Select has a `Default`, and bcc emits the Default body
'     FIRST, immediately after the compares (no jmp needed), then the Case bodies.
'   * Cases 102-106 and 108 of the promotion-place Select have genuinely EMPTY bodies --
'     five separate `E9` jumps to the join plus one `EB 00`, not a multi-value Case.
'   * `If nat <> Null` is the 9-byte cmp/je form; `If Not compc` is the 21-byte
'     setne/movzx/cmp/jne form (10.3). Both appear in this one function.
'   * `Return 0` inside `If Not compc` is a real early return (mov eax,0 / E9 to epilogue),
'     not an Else -- there is no If-block exit jmp after it.
'   * The two empty-string sentinels are DIFFERENT addresses: 0x00C5D284 at SetActive's and
'     SetText's 2nd argument, 0x005C7D40 at AddItem's 2nd and 3rd. The oracle masks both as
'     in-image data addresses so it cannot discriminate; the likeliest reading is that
'     0x005C7D40 is the compiler-substituted default for an OMITTED String parameter and
'     0x00C5D284 is a literal "" written in the source. Written explicitly here either way.
'!Global g_clubs_combolocale:TCombo
'!Global g_clubs_combobased:TCombo
'!Global g_clubs_combocomp:TCombo
'!Global g_clubs_table:TTable
'!Global g_clubs_title:TButton
'!Global g_clubs_btnnames:TButton
'!Global g_clubs_shownames:Int
'!Global g_clubs:TList
'!Global g_nations:TList
TScreen.SetActive("clubs", "")
TClub.SortListBy(1, 1)
Select g_clubs_shownames
	Case 1
		g_clubs_btnnames.SetText(GetText("Hide Names"), "", -1, -1)
		For Local i:Int = 0 To 16
			Select i
				Case 0
					g_clubs_table.SetColumnWidth(i, 40)
				Case 1
					g_clubs_table.SetColumnWidth(i, 120)
				Case 2
					g_clubs_table.SetColumnWidth(i, 100)
				Case 3
					g_clubs_table.SetColumnWidth(i, 50)
				Case 4
					g_clubs_table.SetColumnWidth(i, 100)
				Case 5
					g_clubs_table.SetColumnWidth(i, 0)
				Case 6
					g_clubs_table.SetColumnWidth(i, 120)
				Case 7
					g_clubs_table.SetColumnWidth(i, 120)
				Case 8
					g_clubs_table.SetColumnWidth(i, 120)
				Case 9
					g_clubs_table.SetColumnWidth(i, 0)
				Case 10
					g_clubs_table.SetColumnWidth(i, 0)
				Case 11
					g_clubs_table.SetColumnWidth(i, 0)
				Case 12
					g_clubs_table.SetColumnWidth(i, 0)
				Case 13
					g_clubs_table.SetColumnWidth(i, 0)
				Case 14
					g_clubs_table.SetColumnWidth(i, 0)
				Case 15
					g_clubs_table.SetColumnWidth(i, 0)
				Case 16
					g_clubs_table.SetColumnWidth(i, 0)
			End Select
		Next
	Case 0
		g_clubs_btnnames.SetText(GetText("Show Names"), "", -1, -1)
		For Local j:Int = 0 To 16
			Select j
				Case 0
					g_clubs_table.SetColumnWidth(j, 40)
				Case 1
					g_clubs_table.SetColumnWidth(j, 120)
				Case 2
					g_clubs_table.SetColumnWidth(j, 0)
				Case 3
					g_clubs_table.SetColumnWidth(j, 0)
				Case 4
					g_clubs_table.SetColumnWidth(j, 0)
				Case 5
					g_clubs_table.SetColumnWidth(j, 30)
				Case 6
					g_clubs_table.SetColumnWidth(j, 0)
				Case 7
					g_clubs_table.SetColumnWidth(j, 0)
				Case 8
					g_clubs_table.SetColumnWidth(j, 0)
				Case 9
					g_clubs_table.SetColumnWidth(j, 30)
				Case 10
					g_clubs_table.SetColumnWidth(j, 100)
				Case 11
					g_clubs_table.SetColumnWidth(j, 100)
				Case 12
					g_clubs_table.SetColumnWidth(j, 80)
				Case 13
					g_clubs_table.SetColumnWidth(j, 100)
				Case 14
					g_clubs_table.SetColumnWidth(j, 80)
				Case 15
					g_clubs_table.SetColumnWidth(j, 40)
				Case 16
					g_clubs_table.SetColumnWidth(j, 40)
			End Select
		Next
End Select
g_clubs_table.ClearItems()
Select g_clubs_combolocale.GetSelectedItem()
	Case 1
		Local nat:TNation = TNation.SelectById(g_clubs_combobased.GetSelectedItemId())
		Local basedn:Int = 0
		If nat <> Null Then basedn = nat.id
		Local compn:TCompetition = TCompetition.SelectByBasedAndName(basedn, g_clubs_combocomp.GetSelectedText())
		For Local c1:TClub = EachIn g_clubs
			If Not nat Or c1.nationid = basedn
				If Not compn Or c1.leagueid = compn.id
					g_clubs_table.AddItem(c1.GetStringArray(), "", "")
				End If
			End If
		Next
		If compn <> Null
			For Local pp:TPromotionPlace = EachIn compn.lplacesthatpromotetome
				Select pp.place
					Case 100
						For Local c2:TClub = EachIn TClub.SelectListByLeagueId(pp.parentid)
							g_clubs_table.AddItem(c2.GetStringArray(), "", "")
						Next
					Case 101
						For Local c3:TClub = EachIn TClub.SelectListByLeagueId(pp.parentid)
							If c3.continentalcompid = 0
								g_clubs_table.AddItem(c3.GetStringArray(), "", "")
							End If
						Next
					Case 102
					Case 103
					Case 104
					Case 105
					Case 106
					Case 107
						For Local c4:TClub = EachIn TClub.SelectListByLeagueId(pp.parentid)
							If c4.continentalcompid > 0
								g_clubs_table.AddItem(c4.GetStringArray(), "", "")
							End If
						Next
					Case 108
				End Select
			Next
		End If
	Case 2
		Local con:TContinent = TContinent.SelectById(g_clubs_combobased.GetSelectedItemId())
		Local basedc:Int = 0
		If con <> Null Then basedc = con.id
		Local compc:TCompetition = TCompetition.SelectByBasedAndName(basedc, g_clubs_combocomp.GetSelectedText())
		If Not compc
			For Local n2:TNation = EachIn g_nations
				If n2.continent = basedc
					For Local c5:TClub = EachIn g_clubs
						If c5.nationid = n2.id
							g_clubs_table.AddItem(c5.GetStringArray(), "", "")
						End If
					Next
				End If
			Next
			Return 0
		End If
		For Local c6:TClub = EachIn g_clubs
			If c6.continentalcompid = compc.id
				g_clubs_table.AddItem(c6.GetStringArray(), "", "")
			End If
		Next
	Default
		For Local c7:TClub = EachIn g_clubs
			g_clubs_table.AddItem(c7.GetStringArray(), "", "")
		Next
End Select
g_clubs_title.SetText(GetText("Clubs") + " (" + g_clubs_table.CountItems() + ")", "", -1, -1)
Return 0
