' TScreen_ReportBoss.ButtonPlay
' VA 0x005623D3   34 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (34/34, original length from Ghidra's inventory)
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables)
'   differ by construction between probe and NSS5.exe; the emitted code is identical.
' module Global assumed (name ours, type load-bearing): Global g_plr:TPlayer
'   (global at 0x00C6F028; slot 0x6c on TPlayer is UpdateTeamMateId_Human)

	Function ButtonPlay:Int()
		'!Global g_plr:TPlayer
		TScreen_GameMenu.SetUpScreen()
		g_plr.UpdateTeamMateId_Human()
	End Function
