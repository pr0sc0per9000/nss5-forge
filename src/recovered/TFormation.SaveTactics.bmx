' TFormation.SaveTactics
' VA 0x004D8948   263 bytes   vtable slot 0x40   sig ()i
' byte-identical vs NSS5.exe (263/263, original length from Ghidra's inventory)
' NAME CHANGED 2026-10-11 (byte-neutral): 0x004D8988 `ff35a8e9c600 push dword ptr [0xc6e9a8]`
' is the writable user folder the module body builds as g_userpath; TFormation.LoadTactics
' reads it for the Tactics folder at 0x004D87FA. g_datapath is the install root, 0x00C6E950.

'!Global g_userpath:String
LogLine("Saving Tactics:" + name + ".tac")
Local f:TStream = WriteFile(g_userpath + "Tactics\" + name + ".tac")
If Not f
	LogLine("Cannot save tactics: " + name + ".tac")
	Return 0
EndIf
Local n:Int = 0
For Local i:Int = 0 To 34
	If n < 11
		WriteLine(f, String(m_TacPos[i]))
		If m_TacPos[i] = 1 Then n = n + 1
	EndIf
Next
CloseStream(f)
