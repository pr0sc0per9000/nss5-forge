' TScreen_Shop.CreateScreen
' VA 0x00540e75   2665 bytes   mode=reloc   byte-identical vs NSS5.exe
' (2665/2665, original length from Ghidra's inventory, reloc_masked=217; verified with
'  NSS5_NO_LEARN=1, so no call operand was masked by a name this run taught the table)
' KIND=Function (static, no implicit Self), SIG ()i, class-table slot 0x30
'
' Builds the shop screen: a shared title/nav bar, a tab-selector panel with three buttons
' (Items/Vehicles/Property), and three content panels each holding a 2-column x 5-row grid
' of (name label, buy button, price label) for indices 1..10. SetUpScreen (already
' recovered) shows the runtime side of the same three tabs/panels/globals.
'
' ASSUMPTIONS
'   Module Globals -- the ADDRESSES are fact (globals_final.tsv, construction-typed except
'   the two Object[] arrays, "usage"), the NAMES are ours:
'     0x00C66D18 g_shop_screen:TScreen        -- same Global as TScreen_Shop.SetUpScreen
'     0x00C66768 g_pan_title:TPanel   0x00C667B0 g_pan_nav:TPanel
'       -- the SAME shared title/nav bar Globals used (and re-added) by every other
'       screen's CreateScreen (TScreen_GameMenu.CreateScreen names them identically).
'     0x00C66D24 g_shop_img_items:TImage[]     0x00C66D30 g_shop_img_vehicles:TImage[]
'     0x00C66D3C g_shop_img_property:TImage[]  -- ten icons each, index 0..9, loaded once
'       and cached; globals_final.tsv calls all three "Object[]" (usage-typed only) but
'       every element is the direct return of LoadImageChecked, so TImage.
'     0x00C66D40 g_shop_pan_tabs:TPanel  -- the small panel holding the three tab buttons;
'       not referenced by SetUpScreen, name is ours alone.
'     0x00C66D44 g_shop_panel_property:TPanel  0x00C66D48 g_shop_panel_vehicles:TPanel
'     0x00C66D4C g_shop_panel_items:TPanel     -- same three Globals SetUpScreen names
'       g_shop_panel_property/vehicles/items (its own header documents the construction
'       order = tab 1/2/3 = property/vehicles/items, matching this file's load order).
'   Class-table slots (class_tables.tsv / vtable_map.tsv):
'     0x00C61C64 TScreen+0x38     CreateScreen($,:TImage,()i,()i):TScreen
'     0x00C63294 TPanel+0x88      CreatePanel($,$,i,i,i,i,$,$,i,f,i,i,i):TPanel
'     0x00C623CC TButton+0x88     CreateButton($,$,i,i,i,i,i,i,$,$,:TImage,()i,f,i,$):TButton
'     0x00C634C0 TLabel+0x88      CreateLabel($,$,i,i,i,i,i,$,$,f,i,i,i,i,:TImage,i,i,i,i,$,f):TLabel
'     0x00C638BC THelpBox+0x30    Create(:TGadget,i,i,i,i,$,i,i):THelpBox
'     slot 0x40 on a TScreen = AddGadget(:TGadget)i ; slot 0x74 on a TGadget = AddChild
'     slot 0x90 on a TScreen = GetGadgetByName($):TGadget
'     0x00C66E14 = TScreen_Shop+0x34 SetUpScreen()i ; 0x00C66E18 = TScreen_Shop+0x38
'       ButtonBuy()i -- both this Type's OWN table, read through `push dword [slot]` (the
'       compiled address, not the class-table address itself) because they are used here
'       as ()i VALUES (button callbacks), not calls -- written unqualified as sibling
'       Functions (guide 3d); qualifying them cannot change the bytes either way.
'   Module Functions: GetText, LoadImageChecked, FormatMoney, TierA/TierB/TierC,
'     PropertyName/VehicleName/ItemName (all already in src/recovered_module), plus three
'     new 237-byte siblings of PropertyName/VehicleName/ItemName recovered alongside this
'     body -- PropertyTooltip (0x005076D8), VehicleTooltip (0x005078B2), ItemTooltip
'     (0x00507A8C) -- same Select-over-GetText(key) shape, one GetText call site each in
'     this function (args=1, confirmed from the CALL-argument-count annotation, NOT from
'     Ghidra's merged pseudo-C argument lists, which fold a callee's args together with the
'     following call's pushes and cannot be trusted directly -- reconstructed straight from
'     the raw disassembly instead).
'   FormatMoney's second argument is 1 (abbreviated "$1.2M" form) for every price label
'     here, unlike the 0 used elsewhere for "owned" displays (TProfile.GetStringArray*).
'
' NOTES ON SHAPE
'   * The image-load guard is `If Not g_shop_img_items[0]` -- the `setne al / movzx eax,al`
'     tell of guide 10.3's "If Not x" form, not `If x = Null`.
'   * FIVE Int Locals -- a, x, y, w, h -- live across the whole function, REASSIGNED (never
'     redeclared) between the pan_Shop / pan_ShopProperty / pan_ShopVehicles / pan_ShopItems
'     sections; only x is a register (edi), the other four spill to `sub esp,0x10`'s four
'     slots. A sixth Local `i` is declared fresh in each of the four `For` loops (image
'     load + one grid loop per panel) and lands in ebx every time.
'   * The x advance is `x :+ w + 10` (mov eax,[w]/add eax,10/add edi,eax), matching guide
'     17's `x :+ w + 10` tell; row-wrap resets `x = 20` and advances `y :+ h + 70` -- both
'     expressed through the Locals, not folded to the literal 160, matching the original's
'     `mov eax,[h] / add eax,0x46 / add [y],eax` rather than a bare `add [y],0xa0`.
'   * Every gadget created inside a loop is added inline as AddChild's argument (no
'     intermediate Global), so there is no retain/release pair around it -- same pattern as
'     TScreen_GameMenu.CreateScreen's lbl_bank/lbl_nextopp1.
'   * The vehicles row's two labels share the SAME name literal ("lbl_vehicles" + i) for
'     both the name label and the price label -- reproduced as found (guide 16.8), unlike
'     the property row, which uses "lbl_propertyname" for the first and "lbl_property" for
'     the second. Items likewise share "lbl_items" for both.
'   * String literals read out of NSS5.exe with harness.read_string: "shop", "Shop",
'     "Items", "Vehicles", "Property", "pan_Shop", "pan_ShopProperty", "pan_ShopVehicles",
'     "pan_ShopItems", "btn_items", "btn_vehicles", "btn_property", "lbl_propertyname",
'     "lbl_property", "lbl_vehicles", "lbl_items", "CHELP_SHOPBUTTONS", "FFFFFF", "888888",
'     ".png", and the three "GameMedia\Images\Shop\<Kind>\<Kind>_" path prefixes.
	Function CreateScreen:Int()
		'!Global g_shop_screen:TScreen
		'!Global g_pan_title:TPanel
		'!Global g_pan_nav:TPanel
		'!Global g_shop_img_items:TImage[]
		'!Global g_shop_img_vehicles:TImage[]
		'!Global g_shop_img_property:TImage[]
		'!Global g_shop_pan_tabs:TPanel
		'!Global g_shop_panel_property:TPanel
		'!Global g_shop_panel_vehicles:TPanel
		'!Global g_shop_panel_items:TPanel
		g_shop_screen = TScreen.CreateScreen("shop", Null, Null, Null)
		If Not g_shop_img_items[0]
			For Local i:Int = 1 To 10
				g_shop_img_items[i - 1] = LoadImageChecked("GameMedia\Images\Shop\Items\Items_" + i + ".png", -1)
				g_shop_img_vehicles[i - 1] = LoadImageChecked("GameMedia\Images\Shop\Vehicles\Vehicles_" + i + ".png", -1)
				g_shop_img_property[i - 1] = LoadImageChecked("GameMedia\Images\Shop\Property\Property_" + i + ".png", -1)
			Next
		End If
		g_shop_screen.AddGadget(g_pan_title)
		g_shop_screen.AddGadget(g_pan_nav)
		Local a:Int = 60
		Local x:Int = 10
		Local y:Int = 70
		Local w:Int = 246
		Local h:Int = 40
		g_shop_pan_tabs = TPanel.CreatePanel("pan_Shop", GetText("Shop"), x, y, 780, 30, "FFFFFF", "FFFFFF", 3, 0.8, 1, a, 0)
		y :+ 40
		x :+ 10
		g_shop_screen.AddGadget(g_shop_pan_tabs)
		g_shop_pan_tabs.AddChild(TButton.CreateButton("btn_items", GetText("Items"), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", Null, SetUpScreen, 1.0, 1, ""))
		x :+ w + 10
		g_shop_pan_tabs.AddChild(TButton.CreateButton("btn_vehicles", GetText("Vehicles"), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", Null, SetUpScreen, 1.0, 1, ""))
		x :+ w + 10
		g_shop_pan_tabs.AddChild(TButton.CreateButton("btn_property", GetText("Property"), x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", Null, SetUpScreen, 1.0, 1, ""))
		a = 330
		x = 10
		y = 170
		h = 90
		w = 144
		g_shop_panel_property = TPanel.CreatePanel("pan_ShopProperty", GetText("Property"), x, y, 780, 30, "FFFFFF", "FFFFFF", 3, 0.8, 1, a, 0)
		y :+ 40
		x :+ 10
		g_shop_screen.AddGadget(g_shop_panel_property)
		For Local i:Int = 1 To 10
			g_shop_panel_property.AddChild(TLabel.CreateLabel("lbl_propertyname" + i, PropertyName(i), x, y, w, 30, 2, "FFFFFF", "FFFFFF", 1.0, 2, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
			g_shop_panel_property.AddChild(TButton.CreateButton("btn_property" + i, "", x + 1, y + 30, w - 2, h, 1, 2, "FFFFFF", "FFFFFF", g_shop_img_property[i - 1], ButtonBuy, 0.25, 0, PropertyTooltip(i)))
			g_shop_panel_property.AddChild(TLabel.CreateLabel("lbl_property" + i, FormatMoney(TierA(i), 1), x, y + 30 + h, w, 30, 2, "888888", "FFFFFF", 1.0, 3, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
			x :+ w + 10
			If i = 5
				x = 20
				y :+ h + 70
			End If
		Next
		x = 10
		y = 170
		g_shop_panel_vehicles = TPanel.CreatePanel("pan_ShopVehicles", GetText("Vehicles"), x, y, 780, 30, "FFFFFF", "FFFFFF", 3, 0.8, 1, a, 0)
		y :+ 40
		x :+ 10
		g_shop_screen.AddGadget(g_shop_panel_vehicles)
		For Local i:Int = 1 To 10
			g_shop_panel_vehicles.AddChild(TLabel.CreateLabel("lbl_vehicles" + i, VehicleName(i), x, y, w, 30, 2, "FFFFFF", "FFFFFF", 1.0, 2, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
			g_shop_panel_vehicles.AddChild(TButton.CreateButton("btn_vehicles" + i, "", x + 1, y + 30, w - 2, h, 1, 2, "FFFFFF", "FFFFFF", g_shop_img_vehicles[i - 1], ButtonBuy, 0.25, 0, VehicleTooltip(i)))
			g_shop_panel_vehicles.AddChild(TLabel.CreateLabel("lbl_vehicles" + i, FormatMoney(TierB(i), 1), x, y + 30 + h, w, 30, 2, "888888", "FFFFFF", 1.0, 3, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
			x :+ w + 10
			If i = 5
				x = 20
				y :+ h + 70
			End If
		Next
		x = 10
		y = 170
		g_shop_panel_items = TPanel.CreatePanel("pan_ShopItems", GetText("Items"), x, y, 780, 30, "FFFFFF", "FFFFFF", 3, 0.8, 1, a, 0)
		y :+ 40
		x :+ 10
		g_shop_screen.AddGadget(g_shop_panel_items)
		For Local i:Int = 1 To 10
			g_shop_panel_items.AddChild(TLabel.CreateLabel("lbl_items" + i, ItemName(i), x, y, w, 30, 2, "FFFFFF", "FFFFFF", 1.0, 2, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
			g_shop_panel_items.AddChild(TButton.CreateButton("btn_items" + i, "", x + 1, y + 30, w - 2, h, 1, 2, "FFFFFF", "FFFFFF", g_shop_img_items[i - 1], ButtonBuy, 0.25, 0, ItemTooltip(i)))
			g_shop_panel_items.AddChild(TLabel.CreateLabel("lbl_items" + i, FormatMoney(TierC(i), 1), x, y + 30 + h, w, 30, 2, "888888", "FFFFFF", 1.0, 3, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
			x :+ w + 10
			If i = 5
				x = 20
				y :+ h + 70
			End If
		Next
		g_shop_screen.lHelp.AddLast(THelpBox.Create(g_shop_screen.GetGadgetByName("btn_vehicles"), 0, 0, 0, 0, GetText("CHELP_SHOPBUTTONS"), 1, 2))
	End Function
