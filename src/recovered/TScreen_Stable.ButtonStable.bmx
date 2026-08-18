' TScreen_Stable.ButtonStable
' VA 0x005884A4   154 bytes   vtable slot 0x48   sig ()i
' byte-identical vs NSS5.exe (154/154, original length from Ghidra's inventory), harness mode=reloc
' Assumptions (module Globals):
'   * 0x00C6F028 : TProfile (globals_final, construction, high) -- slot 0x10C = GetStableSize()i
'   * 0x00C6DEE4 / 0x00C6DEE8 / 0x00C6DEC0 / 0x00C6DED8 : TPanel
'   * 0x00C6DEB8 / 0x00C6DEBC : TButton
'   * 0x00C61CC0 resolves to class table TScreen + 0x94 = TScreen.DoMessage($,i,i)i
'   * literal 0x00C93A18 = 'CMESSAGE_NOSTABLE'; GetText = module Function 0x004C5549.
' SHAPE (measured): the `< 1` arm ends with an explicit `Return 0`; as If/Else it is 149 bytes.
'   Ghidra shows GetText taking three arguments -- that is the `push 0 / push 0` for
'   DoMessage's trailing arguments being attributed to the inner call.
	'!Global g_profile:TProfile
	'!Global g_stbl_pnl1:TPanel
	'!Global g_stbl_pnl2:TPanel
	'!Global g_stbl_pnl3:TPanel
	'!Global g_stbl_pnl4:TPanel
	'!Global g_stbl_btn1:TButton
	'!Global g_stbl_btn2:TButton
	Function ButtonStable:Int()
		If g_profile.GetStableSize() < 1
			TScreen.DoMessage(GetText("CMESSAGE_NOSTABLE"), 0, 0)
			Return 0
		EndIf
		g_stbl_pnl1.Hide()
		g_stbl_pnl2.Hide()
		g_stbl_pnl3.Show()
		g_stbl_pnl4.Show()
		g_stbl_btn1.Hide()
		g_stbl_btn2.Hide()
	End Function
