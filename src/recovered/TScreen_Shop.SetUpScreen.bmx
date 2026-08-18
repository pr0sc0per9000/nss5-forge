' TScreen_Shop.SetUpScreen
' VA 0x005418DE   3072 bytes   mode=reloc   byte-identical vs NSS5.exe (3072/3072)
' KIND=Function (static), SIG ()i, slot 0x34
' Oracle: matched=3072 total=3072 reloc_masked=215, NSS5_NO_LEARN=1.
'
' ASSUMPTIONS
'  * Prologue is `push ebp / mov ebp,esp / push ebx / push esi / push edi` with NO `sub esp`
'    (guide 16.3): the source has NO memory-slot Locals. Every Local here (the four loop
'    counters and `s`) lives in a register.
'  * Globals (names ours; declared types are load-bearing):
'      0x00C66D18 -> g_shop_screen:TScreen (globals_final.tsv, construction-typed). Slot 0x60
'        = TScreen.SetActiveGadget($) is a static Function, so the call site pushes only the
'        String and no Self -- that is why the receiver is an instance yet no Self appears.
'        Slot 0x90 = TScreen.GetGadgetByName($):TGadget is a Method and does push Self.
'      0x00C66D44 / 0x00C66D48 / 0x00C66D4C -> TPanel (construction-typed): the property,
'        vehicles and items panels, in that order (tab 1/2/3). Only slot 0x58 = TGadget.Show
'        is used, which TPanel inherits unchanged.
'      0x00C87A7C -> g_shop_tab:Int -- the selected tab, 0 = none / 1 = property /
'        2 = vehicles / 3 = items.
'      0x00C6E91C -> g_col_highlight:String. globals_final.tsv says Int ("read-only int
'        slot", confidence low) and is WRONG: it is pushed as argument 1 of
'        TGadget.SetColour($,$). Corroborated by the already-verified
'        TScreen_Options.RefreshButtons and TScreen_Stable.SetStake, which both declare it
'        String ("00FF00").
'      0x00C6F028 -> g_profile:TProfile. Fields used: items (Int[], +0xF0),
'        vehicles (Int[], +0xF4), property (Int[], +0xF8), helppages (Int[], +0x1C8).
'        `[eax+0x5C]` on helppages is BBArray data (+0x18) + 17*4, i.e. helppages[17].
'  * Class-table calls: 0x00C61C88 = TScreen+0x5C SetActive($,$); 0x00C621CC = TGadget+0x7C
'    GetActiveGadgetName()$; 0x00C61CE0 = TScreen+0xB4 Tutorial(); 0x00C66E1C =
'    TScreen_Shop+0x3C HidePanels() -- a sibling Function, so written unprefixed (guide 3d).
'  * Downcast class table 0x00C62344 = TButton (class_tables.tsv). The three colour resets
'    and the highlight write `TButton(...)`; the SetAlph / SetText call sites have no
'    downcast at all and keep the TGadget receiver GetGadgetByName returns.
'  * Slots: TGadget+0x6C SetColour($,$), +0x70 SetAlph(f), +0x64 SetText($,$,i,i).
'    0x3E800000 = 0.25, 0x3F800000 = 1.0.
'  * Module Functions called: PlayTrack (0x004BCB98), PropertyName (0x005075EB),
'    VehicleName (0x005077C5), ItemName (0x0050799F) -- all already in src/recovered_module.
'  * BOTH tab dispatches are `Select`, not If/ElseIf (guide 10.2): three `cmp`/`je` back to
'    back with every target past the last compare, then a `jmp` for the no-match path.
'    Control: rewriting the panel one as If/ElseIf gives 3075 bytes, MISMATCH at 507.
'  * The two scan loops `Exit` on the first empty slot. Control: dropping the Exit gives
'    3070 bytes, MISMATCH at 177.
'  * String literals read out of NSS5.exe with harness.read_string: 0x00C87734 "shop",
'    0x00C5D284 "", 0x00C5D680 "FFFFFF", 0x00C87898 "btn_items", 0x00C878D4 "btn_vehicles",
'    0x00C87914 "btn_property", 0x00C87964 "lbl_propertyname", 0x00C879E0 "lbl_vehicles",
'    0x00C87A2C "lbl_items", 0x00C70F08 " (", 0x00C70EF8 ")", and the thirty numbered
'    "btn_items1".."btn_property10" at 0x00C87A80..0x00C87EBC.
'    NOTE the asymmetry, reproduced as found: the property LABEL prefix is
'    "lbl_propertyname" while the other two are "lbl_vehicles" / "lbl_items".
'  * `s = " (" + n + ")"` is left-associative: ")" is pushed first, then " " + String(n) is
'    concatenated, then the result is concatenated with ")" (guide 16.1/16.2).
	Function SetUpScreen:Int()
		'!Global g_shop_screen:TScreen
		'!Global g_shop_panel_property:TPanel
		'!Global g_shop_panel_vehicles:TPanel
		'!Global g_shop_panel_items:TPanel
		'!Global g_shop_tab:Int
		'!Global g_col_highlight:String
		'!Global g_profile:TProfile
		TScreen.SetActive("shop", "")
		PlayTrack(5)
		If g_shop_tab = 0
			g_shop_screen.SetActiveGadget("btn_property")
			For Local i:Int = 0 To 9
				If g_profile.vehicles[i] = 0
					g_shop_screen.SetActiveGadget("btn_vehicles")
					Exit
				End If
			Next
			For Local i:Int = 0 To 9
				If g_profile.items[i] = 0
					g_shop_screen.SetActiveGadget("btn_items")
					Exit
				End If
			Next
		End If
		Select TGadget.GetActiveGadgetName()
			Case "btn_property"
				g_shop_tab = 1
			Case "btn_vehicles"
				g_shop_tab = 2
			Case "btn_items"
				g_shop_tab = 3
		End Select
		TButton(g_shop_screen.GetGadgetByName("btn_property")).SetColour("FFFFFF", "FFFFFF")
		TButton(g_shop_screen.GetGadgetByName("btn_vehicles")).SetColour("FFFFFF", "FFFFFF")
		TButton(g_shop_screen.GetGadgetByName("btn_items")).SetColour("FFFFFF", "FFFFFF")
		Select g_shop_tab
			Case 1
				TButton(g_shop_screen.GetGadgetByName("btn_property")).SetColour(g_col_highlight, "FFFFFF")
			Case 2
				TButton(g_shop_screen.GetGadgetByName("btn_vehicles")).SetColour(g_col_highlight, "FFFFFF")
			Case 3
				TButton(g_shop_screen.GetGadgetByName("btn_items")).SetColour(g_col_highlight, "FFFFFF")
		End Select
		HidePanels()
		Select g_shop_tab
			Case 1
				g_shop_panel_property.Show()
			Case 2
				g_shop_panel_vehicles.Show()
			Case 3
				g_shop_panel_items.Show()
		End Select
		For Local i:Int = 1 To 10
			g_shop_screen.GetGadgetByName("btn_items" + i).SetAlph(0.25)
			g_shop_screen.GetGadgetByName("btn_vehicles" + i).SetAlph(0.25)
			g_shop_screen.GetGadgetByName("btn_property" + i).SetAlph(0.25)
		Next
		If g_profile.items[0] > 0 Then g_shop_screen.GetGadgetByName("btn_items1").SetAlph(1.0)
		If g_profile.items[1] > 0 Then g_shop_screen.GetGadgetByName("btn_items2").SetAlph(1.0)
		If g_profile.items[2] > 0 Then g_shop_screen.GetGadgetByName("btn_items3").SetAlph(1.0)
		If g_profile.items[3] > 0 Then g_shop_screen.GetGadgetByName("btn_items4").SetAlph(1.0)
		If g_profile.items[4] > 0 Then g_shop_screen.GetGadgetByName("btn_items5").SetAlph(1.0)
		If g_profile.items[5] > 0 Then g_shop_screen.GetGadgetByName("btn_items6").SetAlph(1.0)
		If g_profile.items[6] > 0 Then g_shop_screen.GetGadgetByName("btn_items7").SetAlph(1.0)
		If g_profile.items[7] > 0 Then g_shop_screen.GetGadgetByName("btn_items8").SetAlph(1.0)
		If g_profile.items[8] > 0 Then g_shop_screen.GetGadgetByName("btn_items9").SetAlph(1.0)
		If g_profile.items[9] > 0 Then g_shop_screen.GetGadgetByName("btn_items10").SetAlph(1.0)
		If g_profile.vehicles[0] > 0 Then g_shop_screen.GetGadgetByName("btn_vehicles1").SetAlph(1.0)
		If g_profile.vehicles[1] > 0 Then g_shop_screen.GetGadgetByName("btn_vehicles2").SetAlph(1.0)
		If g_profile.vehicles[2] > 0 Then g_shop_screen.GetGadgetByName("btn_vehicles3").SetAlph(1.0)
		If g_profile.vehicles[3] > 0 Then g_shop_screen.GetGadgetByName("btn_vehicles4").SetAlph(1.0)
		If g_profile.vehicles[4] > 0 Then g_shop_screen.GetGadgetByName("btn_vehicles5").SetAlph(1.0)
		If g_profile.vehicles[5] > 0 Then g_shop_screen.GetGadgetByName("btn_vehicles6").SetAlph(1.0)
		If g_profile.vehicles[6] > 0 Then g_shop_screen.GetGadgetByName("btn_vehicles7").SetAlph(1.0)
		If g_profile.vehicles[7] > 0 Then g_shop_screen.GetGadgetByName("btn_vehicles8").SetAlph(1.0)
		If g_profile.vehicles[8] > 0 Then g_shop_screen.GetGadgetByName("btn_vehicles9").SetAlph(1.0)
		If g_profile.vehicles[9] > 0 Then g_shop_screen.GetGadgetByName("btn_vehicles10").SetAlph(1.0)
		If g_profile.property[0] > 0 Then g_shop_screen.GetGadgetByName("btn_property1").SetAlph(1.0)
		If g_profile.property[1] > 0 Then g_shop_screen.GetGadgetByName("btn_property2").SetAlph(1.0)
		If g_profile.property[2] > 0 Then g_shop_screen.GetGadgetByName("btn_property3").SetAlph(1.0)
		If g_profile.property[3] > 0 Then g_shop_screen.GetGadgetByName("btn_property4").SetAlph(1.0)
		If g_profile.property[4] > 0 Then g_shop_screen.GetGadgetByName("btn_property5").SetAlph(1.0)
		If g_profile.property[5] > 0 Then g_shop_screen.GetGadgetByName("btn_property6").SetAlph(1.0)
		If g_profile.property[6] > 0 Then g_shop_screen.GetGadgetByName("btn_property7").SetAlph(1.0)
		If g_profile.property[7] > 0 Then g_shop_screen.GetGadgetByName("btn_property8").SetAlph(1.0)
		If g_profile.property[8] > 0 Then g_shop_screen.GetGadgetByName("btn_property9").SetAlph(1.0)
		If g_profile.property[9] > 0 Then g_shop_screen.GetGadgetByName("btn_property10").SetAlph(1.0)
		For Local i:Int = 1 To 10
			Local s:String = ""
			If g_profile.property[i - 1] > 0 Then s = " (" + g_profile.property[i - 1] + ")"
			g_shop_screen.GetGadgetByName("lbl_propertyname" + i).SetText(PropertyName(i) + s, "", -1, -1)
			s = ""
			If g_profile.vehicles[i - 1] > 0 Then s = " (" + g_profile.vehicles[i - 1] + ")"
			g_shop_screen.GetGadgetByName("lbl_vehicles" + i).SetText(VehicleName(i) + s, "", -1, -1)
			s = ""
			If g_profile.items[i - 1] > 0 Then s = " (" + g_profile.items[i - 1] + ")"
			g_shop_screen.GetGadgetByName("lbl_items" + i).SetText(ItemName(i) + s, "", -1, -1)
		Next
		If g_profile.helppages[17] = 0
			TScreen.Tutorial()
			g_profile.helppages[17] = 1
		End If
	End Function
