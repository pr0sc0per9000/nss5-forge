' TScreen_ReportPhysio.SetUpScreen
' VA 0x00561749   274 bytes
' byte-identical vs NSS5.exe (274/274, original length from Ghidra's inventory, mode=reloc)
' Driven through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_profile:TProfile
'!Global g_rp_btn:TButton              ' 0x00C68A14
'!Global g_img_play:TImage             ' 0x00C6F274
'!Global g_rp_bg:TImage                ' 0x00C68A04
'!Global g_rp_panel:TPanel             ' 0x00C68A0C
'!Global g_rp_label:TLabel             ' 0x00C68A10
'!Global g_img_next:TImage             ' 0x00C6675C
TScreen.SetActive("reportphysio", "btn_play")
g_rp_btn.SetIcon(g_img_play)
g_rp_bg = LoadImageChecked("GameMedia\Images\Backgrounds\report_physio.png", -1)
If g_profile.physioreport.Length <> 0
	g_rp_panel.SetText(GetText("Physio Report"), "", -1, -1)
	g_rp_label.SetText(g_profile.physioreport, "", -1, -1)
	g_profile.physioreport = ""
	If g_profile.bossreport.Length <> 0
		g_rp_btn.SetIcon(g_img_next)
	End If
Else
	TScreen_ReportBoss.SetUpScreen()
End If
