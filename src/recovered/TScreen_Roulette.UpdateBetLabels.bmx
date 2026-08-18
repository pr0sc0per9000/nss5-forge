' TScreen_Roulette.UpdateBetLabels
' VA 0x00575106   948 bytes   vtable slot 0x48   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (948/948, original length from Ghidra's inventory, mode=reloc)
'
' assumptions: 0x00C6BA48 declared TScreen -- named g_roulette_screen to match the
' construction-site comment already used in TScreen_Roulette.CreateScreen.bmx.
' 0x00C6BA60 declared Int[] (g_screen_roulette_arr), same Global already used by
' TScreen_Roulette.GetBetTotal / ClearBets. TGadget.SetText($,$,i,i)i is slot 0x64
' (100 decimal); TButton/TLabel.SetIcon(:TImage)i is slot 0x90 (144 decimal); the
' args=5/bytes=20 CALL annotations on the SetText sites are Self + 4 params, matching.
' TScreen.GetGadgetByName($):TGadget is slot 0x90 on TScreen -- the "second argument"
' Ghidra prints on those virtual calls is bbObjectDowncast's own class-table operand,
' not a real GetGadgetByName parameter (codegen-patterns.md 3d/5).
' TScreen_Roulette.GetBetTotal() and TScreen_Casino.GetChipImage(i):TImage are direct
' class-table static calls (CTSLOT), already-verified Functions.
' FormatMoney(a0:Int, a1:Int):String is the verified module Function (src/recovered_module).
	Function UpdateBetLabels:Int()
		'!Global g_roulette_screen:TScreen
		'!Global g_screen_roulette_arr:Int[]
		TLabel(g_roulette_screen.GetGadgetByName("lbl_odd")).SetText(FormatMoney(g_screen_roulette_arr[0], 0), "", -1, -1)
		TLabel(g_roulette_screen.GetGadgetByName("lbl_even")).SetText(FormatMoney(g_screen_roulette_arr[1], 0), "", -1, -1)
		TLabel(g_roulette_screen.GetGadgetByName("lbl_red")).SetText(FormatMoney(g_screen_roulette_arr[2], 0), "", -1, -1)
		TLabel(g_roulette_screen.GetGadgetByName("lbl_black")).SetText(FormatMoney(g_screen_roulette_arr[3], 0), "", -1, -1)
		TLabel(g_roulette_screen.GetGadgetByName("lbl_1to18")).SetText(FormatMoney(g_screen_roulette_arr[4], 0), "", -1, -1)
		TLabel(g_roulette_screen.GetGadgetByName("lbl_19to36")).SetText(FormatMoney(g_screen_roulette_arr[5], 0), "", -1, -1)
		TLabel(g_roulette_screen.GetGadgetByName("lbl_total2")).SetText(FormatMoney(TScreen_Roulette.GetBetTotal(), 0), "", -1, -1)
		TButton(g_roulette_screen.GetGadgetByName("btn_odd")).SetIcon(TScreen_Casino.GetChipImage(g_screen_roulette_arr[0]))
		TButton(g_roulette_screen.GetGadgetByName("btn_even")).SetIcon(TScreen_Casino.GetChipImage(g_screen_roulette_arr[1]))
		TButton(g_roulette_screen.GetGadgetByName("btn_red")).SetIcon(TScreen_Casino.GetChipImage(g_screen_roulette_arr[2]))
		TButton(g_roulette_screen.GetGadgetByName("btn_black")).SetIcon(TScreen_Casino.GetChipImage(g_screen_roulette_arr[3]))
		TButton(g_roulette_screen.GetGadgetByName("btn_1to18")).SetIcon(TScreen_Casino.GetChipImage(g_screen_roulette_arr[4]))
		TButton(g_roulette_screen.GetGadgetByName("btn_19to36")).SetIcon(TScreen_Casino.GetChipImage(g_screen_roulette_arr[5]))
	End Function
