' TScreen_GameMenu.UpdateTitlePanel
' VA 0x0053AADA   360 bytes  mode=reloc  byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, slot 0x38
' ASSUMPTIONS
'   0x00C6677C g_label_name:TLabel        -- globals_final (construction); slot 0x64 = TGadget.SetText
'   0x00C66788 g_label_bank:TLabel        -- globals_final (construction); same Global as
'                                            TScreen_GameMenu.UpdateMatchRefresh's bank label
'   0x00C66790 g_bar_energy:TProgressBar  -- globals_final (construction); 0x8c=SetPercent,
'                                            0x6c=SetColour, 0x64=SetText (inherited TGadget)
'   0x00C6F028 g_profile:TProfile         -- globals_final (construction); .bank at +0x28,
'                                            .energy at +0x15C; slot 0x160 = GetOriginalName
'   0x00C85BB8 / 0x00C85BBC are this function's float literals 50.0 / 20.0, not Globals.
'   The three SetColour calls are SEQUENTIAL Ifs (00FF00 unconditional, then <=50, then
'   <=20), not the ElseIf cascade UpdateMatchRefresh uses -- the decompilation shows the
'   00FF00 store executing before both tests.
'   Global names are ours; the originals are unrecoverable.
	Function UpdateTitlePanel:Int()
		'!Global g_label_name:TLabel
		'!Global g_label_bank:TLabel
		'!Global g_bar_energy:TProgressBar
		'!Global g_profile:TProfile
		LogLine("UpdateTitlePanel")
		g_label_name.SetText(g_profile.GetOriginalName(), "", -1, -1)
		g_label_bank.SetText(FormatMoney(g_profile.bank, 0), "", -1, -1)
		g_bar_energy.SetPercent(g_profile.energy, 1)
		g_bar_energy.SetText(String(Int(g_profile.energy)) + "%", "", -1, -1)
		g_bar_energy.SetColour("", "00FF00")
		If g_profile.energy <= 50.0
			g_bar_energy.SetColour("", "FF9900")
		End If
		If g_profile.energy <= 20.0
			g_bar_energy.SetColour("", "FF0000")
		End If
	End Function
