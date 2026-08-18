' TScreen_GameMenu.UpdateMatchRefresh
' VA 0x0053b193   347 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, class-table slot 0x40
' ASSUMPTIONS
'   0x00C6EFD4 g_gametime:Int          -- globals_final "Int (verified)"
'   0x00C85C20 g_lastrefresh:Int       -- globals_final "Int (usage)"
'   0x00C66788 g_label_bank:TLabel     -- globals_final (construction); slot 0x64 = SetText
'   0x00C66790 g_bar_energy:TProgressBar -- globals_final (construction); 0x8c=SetPercent,
'                                          0x6c=SetColour, 0x64=SetText(inherited TGadget)
'   0x00C6F028 g_profile:TProfile      -- globals_final (construction); .bank at +0x28,
'                                          .energy at +0x15c, both named in object_model.json
'   Global names are ours; the originals are unrecoverable.
'   0x00C85C24 / 0x00C85C28 are this function's float literals 20.0 / 50.0, not Globals.
'   Comparison sense is byte-observable: the original emits `seta`, so the source spells
'   the thresholds as `<=` with the FF0000 arm first. Written `>` with the arms swapped it
'   emits `setbe` and diverges at byte 214 (same length).
	Function UpdateMatchRefresh:Int()
		'!Global g_gametime:Int
		'!Global g_lastrefresh:Int
		'!Global g_label_bank:TLabel
		'!Global g_bar_energy:TProgressBar
		'!Global g_profile:TProfile
		If g_gametime < g_lastrefresh + 1000 Then Return 0
		g_lastrefresh = g_gametime
		g_label_bank.SetText(FormatMoney(g_profile.bank, 0), "", -1, -1)
		g_bar_energy.SetPercent(g_profile.energy, 1)
		g_bar_energy.SetText(String(Int(g_profile.energy)) + "%", "", -1, -1)
		If g_profile.energy <= 20.0
			g_bar_energy.SetColour("", "FF0000")
		ElseIf g_profile.energy <= 50.0
			g_bar_energy.SetColour("", "FF9900")
		Else
			g_bar_energy.SetColour("", "00FF00")
		End If
	End Function
