' TScreen_TestFixtures.SetUpScreen
' VA 0x005396F3   581 bytes   vtable slot 0x34   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (581/581, original length from Ghidra's inventory)
' Globals (names ours; the addresses and the types they imply):
'   0x00C6660C g_testfix_label:TButton   -- reached through TGadget slot 0x64 SetText($,$,i,i)
'   0x00C6F028 g_profile:TProfile        -- the name 8 other recovered files already use
'   0x00C66610 g_testfix_combo:TCombo    -- slots 0xB8 CountItems, 0x90 AddItem
'   0x00C6080C g_continents:TList        0x00C6099C g_competitions:TList
'   0x00C66608 g_testfix_table:TTable    -- slots 0x9C ClearItems, 0x94 AddItem([]$,$,$).
'      globals_final.tsv types this one TButton; TButton has no 0x94/0x9C of that shape and
'      TTable does, so the code overrides the table (11.2).
' 0x00C66714 = TScreen_TestFixtures+0x38 = CheckShowFixtures, its own Type -> plain call.
' THE TWO-STATEMENT ARRAY BUILD IS LOAD-BEARING. Written as one expression
'   g_testfix_table.AddItem([comp.name] + f.GetStringArray(...)[1..], "", "")
' the body is 584 bytes and the two "" literals get pushed before the array is built.
' Written with a single Local holding the whole concatenation it is 580. The original
' assigns the one-element literal to the Local FIRST (`mov ebx,eax` at +432, with the
' element routed through edx so the array can stay in eax) and appends to it in a second
' statement (`mov ebx,eax` again at +495) -- which is what leaves eax free for the `A1`
' load of the table Global. `a :+ ...` emits the same bytes as `a = a + ...` here.
	Function SetUpScreen:Int()
		'!Global g_testfix_label:TButton
		'!Global g_profile:TProfile
		'!Global g_testfix_combo:TCombo
		'!Global g_continents:TList
		'!Global g_testfix_table:TTable
		'!Global g_competitions:TList
		TScreen.SetActive("fixtures", "")
		g_testfix_label.SetText(g_profile.date.GetString("YY-WW-DDD"), "", -1, -1)
		If g_testfix_combo.CountItems() = 0
			For Local c:TContinent = EachIn g_continents
				g_testfix_combo.AddItem(c.name, "BBBBBB", "FFFFFF", c.id)
			Next
		EndIf
		g_testfix_table.ClearItems()
		TCompetition.SortListBy(1, 1)
		For Local comp:TCompetition = EachIn g_competitions
			If CheckShowFixtures(comp)
				For Local f:TFixture = EachIn comp.lfixturelist
					If f.sdate = g_profile.date.sdate
						Local a:String[] = [comp.name]
						a = a + f.GetStringArray(comp.groups > 1)[1..]
						g_testfix_table.AddItem(a, "", "")
					EndIf
				Next
			EndIf
		Next
	End Function
