' TScreen_ReportBoss.Draw
' VA 0x005623F5   86 bytes
' byte-identical vs NSS5.exe (86/86, original length from Ghidra's inventory, mode=reloc)
' Driven through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_reportboss_img:TImage
SetDrawStateHex("FFFFFF", 1.0, 1.0, 0, 3)
If g_reportboss_img <> Null Then
	DrawImageRect(g_reportboss_img, 0, 60, 400, 480, 0)
End If
