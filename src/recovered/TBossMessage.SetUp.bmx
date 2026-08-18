' TBossMessage.SetUp
' VA 0x005708D1   162 bytes
' byte-identical vs NSS5.exe (162/162, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_boss_list:TList
'!Global g_boss_img:TImage
If Not g_boss_list Then g_boss_list = CreateList()
If Not g_boss_img
	g_boss_img = LoadImageChecked("EngineMedia/Match/Other/Speech.png", -1)
	SetImageHandle(g_boss_img, 51.0, 127.0)
End If
