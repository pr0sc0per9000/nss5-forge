' TScreen_EditContinents.SetUpScreen
' VA 0x00528D01   636 bytes  mode=reloc  byte-identical vs NSS5.exe (636/636)
' KIND=Function, SIG (i)i, slot 0x34
' ASSUMPTIONS
'   0x00C64EC4 :TContinent (the SelectById return type), 0x00C64ED0 / 0x00C64EF0 :TButton,
'     0x00C64ED8..0x00C64EEC :TInputBox, 0x00C64EF4 :TTable (construction sites);
'     0x00C596F0 g_nations:TList -- the EachIn downcasts to ClassTable_TNation.
'   Field offsets from object_model.json: TContinent id/name/tla/continentality/
'     federationname/federationshortname/strength at 0x08..0x20; TNation id 0x0C,
'     name 0x10, strength 0x24, continent 0x64.
'   0x00C59058 is the BBArray element-type descriptor for String (first byte 0x24 = '$').
'   THE ARRAY IS AN ARRAY LITERAL, not New + three element stores.  `New String[3]`
'     followed by arr[0..2] = ... emits a full BBRELEASE of the old element on every
'     store and comes out 700 bytes; the literal form emits bbArrayNew1D plus a bare
'     retain-and-store per element and is exact at 636.
	Function SetUpScreen:Int(a0:Int)
		'!Global g_nations:TList
		'!Global g_ec_continent:TContinent
		'!Global g_ec_btn_id:TButton
		'!Global g_ec_ib_name:TInputBox
		'!Global g_ec_ib_tla:TInputBox
		'!Global g_ec_ib_continentality:TInputBox
		'!Global g_ec_ib_fedname:TInputBox
		'!Global g_ec_ib_fedshort:TInputBox
		'!Global g_ec_ib_strength:TInputBox
		'!Global g_ec_btn_nations:TButton
		'!Global g_ec_table:TTable
		TScreen.SetActive("editcontinents", "")
		g_ec_continent = TContinent.SelectById(a0)
		g_ec_btn_id.SetText(String(g_ec_continent.id), "", -1, -1)
		g_ec_ib_name.SetText(g_ec_continent.name, "", -1, -1)
		g_ec_ib_tla.SetText(g_ec_continent.tla, "", -1, -1)
		g_ec_ib_continentality.SetText(g_ec_continent.continentality, "", -1, -1)
		g_ec_ib_fedname.SetText(g_ec_continent.federationname, "", -1, -1)
		g_ec_ib_fedshort.SetText(g_ec_continent.federationshortname, "", -1, -1)
		g_ec_ib_strength.SetText(String(g_ec_continent.strength), "", -1, -1)
		g_ec_table.ClearItems()
		For Local n:TNation = EachIn g_nations
			If n.continent = g_ec_continent.id
				g_ec_table.AddItem([String(n.id), n.name, String(n.strength)], "", "")
			End If
		Next
		g_ec_btn_nations.SetText(GetText("Nations") + " (" + String(g_ec_table.CountItems()) + ")", "", -1, -1)
	End Function
