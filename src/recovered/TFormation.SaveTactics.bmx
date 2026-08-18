' TFormation.SaveTactics
' VA 0x004D8948   263 bytes   vtable slot 0x40   sig ()i
' byte-identical vs NSS5.exe (263/263, original length from Ghidra's inventory)

'!Global g_datapath:String
LogLine("Saving Tactics:" + name + ".tac")
Local f:TStream = WriteFile(g_datapath + "Tactics\" + name + ".tac")
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
