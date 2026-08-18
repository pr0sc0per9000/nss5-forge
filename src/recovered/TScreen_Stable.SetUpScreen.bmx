' TScreen_Stable.SetUpScreen
' VA 0x0058798E   684 bytes  mode=reloc  byte-identical vs NSS5.exe
' KIND=Function, SIG (i)i, slot 0x34
' ASSUMPTIONS (Global names are ours; declared TYPES are load-bearing)
'   0x00C6DEA0 g_stable_screen:TScreen   (construction) slot 0x90 = GetGadgetByName($):TGadget
'   0x00C6DEB8/BC g_stable_btn01/02:TButton, 0x00C6DECC/D0/D4 g_stable_btn03/04/05:TButton
'   0x00C6DEC0 g_stable_pnl01:TPanel, 0x00C6DED8 g_stable_pnl02:TPanel,
'   0x00C6DEE4 g_stable_pnl03:TPanel, 0x00C6DEE8 g_stable_pnl04:TPanel
'   0x00C6DF1C g_stable_channel:TChannel -- same Global TScreen_Stable.ButtonQuit types TChannel
'   0x00C6DF24 g_stable_sndGallop:TSound -- LoadSoundChecked construction site (CreateScreen)
'   0x00C6DF70 g_stable_state:Int, 0x00C6E298 g_horses:TList (slot 0x70 = TList.Count)
'   0x00C6F028 g_profile:TProfile, slot 0x10C = GetStableSize()i
'   TGadget slots: 0x54 Hide, 0x58 Show, 0x70 SetAlph(f); TGadget.alive at +0x38.
' SHAPE NOTES
'   * `If Not g_stable_channel` -- the original emits the 21-byte setne/movzx form
'     (codegen-patterns 10.3); `= Null` is 12 bytes and leaves the body 9 short.
'   * The two count guards are spelled DIFFERENTLY and both are byte-observable:
'     GetStableSize() < 1 (`cmp eax,1 / jge`) but CountHorsesOwned() <= 0 (`cmp eax,0 / jg`).
	Function SetUpScreen:Int(a0:Int)
		'!Global g_stable_screen:TScreen
		'!Global g_stable_btn01:TButton
		'!Global g_stable_btn02:TButton
		'!Global g_stable_pnl01:TPanel
		'!Global g_stable_btn03:TButton
		'!Global g_stable_btn04:TButton
		'!Global g_stable_btn05:TButton
		'!Global g_stable_pnl02:TPanel
		'!Global g_stable_pnl03:TPanel
		'!Global g_stable_pnl04:TPanel
		'!Global g_stable_channel:TChannel
		'!Global g_stable_sndGallop:TSound
		'!Global g_stable_state:Int
		'!Global g_horses:TList
		'!Global g_profile:TProfile
		TScreen.SetActive("stable", "")
		TScreen_GameMenu.UpdateTitlePanel()
		g_stable_pnl03.Show()
		g_stable_pnl04.Show()
		g_stable_pnl01.Hide()
		g_stable_pnl02.Hide()
		g_stable_btn01.Show()
		g_stable_btn02.Show()
		If a0 <> 0
			g_stable_pnl03.Hide()
			g_stable_pnl04.Hide()
			g_stable_pnl01.Show()
			g_stable_pnl02.Show()
			g_stable_btn01.Hide()
			g_stable_btn02.Hide()
		End If
		g_stable_btn01.SetAlph(1.0)
		If g_profile.GetStableSize() < 1
			g_stable_btn01.SetAlph(0.5)
		End If
		If Not g_stable_channel
			g_stable_channel = AllocChannel()
			CueSound(g_stable_sndGallop, g_stable_channel)
		End If
		g_stable_screen.GetGadgetByName("lbl_StableSize").SetText(String(g_profile.GetStableSize()), "", -1, -1)
		g_stable_btn03.SetAlph(1.0)
		g_stable_btn04.SetAlph(1.0)
		g_stable_btn05.SetAlph(1.0)
		g_stable_btn03.alive = 1
		g_stable_btn04.alive = 1
		g_stable_btn05.alive = 1
		If THorse.CountHorsesOwned() <= 0
			g_stable_btn03.SetAlph(0.5)
			g_stable_btn04.SetAlph(0.5)
			g_stable_btn05.SetAlph(0.5)
			g_stable_btn03.alive = 0
			g_stable_btn04.alive = 0
			g_stable_btn05.alive = 0
		End If
		TScreen_Stable.RefreshTableForSale()
		TScreen_Stable.RefreshTableOwned()
		If g_horses.Count() = 0 Or g_stable_state = 0
			TScreen_Stable.SetUpNextRace()
		End If
	End Function
