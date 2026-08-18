' TScreen_MainMenu.LoadCredits
' VA 0x0051CDB5   264 bytes
' byte-identical vs NSS5.exe (264/264, original length from Ghidra's inventory, mode=reloc)
' Driven through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_credits:String[]            ' 0x00C63990
LogLine("LoadCredits")
Local s:TStream = ReadFile("incbin::Inc/Credits.txt")
If Not s
	LogLine("Could not open file: Credits.txt")
	Return 0
End If
While Not Eof(s)
	g_credits = g_credits[..g_credits.Length + 1]
	g_credits[g_credits.Length - 1] = ReadLine(s)
Wend
CloseFile(s)
LogLine("CreditsLoaded")
