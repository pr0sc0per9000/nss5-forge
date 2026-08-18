' TScreen.SetActive
' VA 0x00510a2b   296 bytes
' byte-identical vs NSS5.exe (296/296, original length from Ghidra's inventory, mode=reloc, 23 masked)
' Body-only format: statements only; parameters are a0, a1, ...
' Function ($,$):TScreen, vtable slot 0x5c.
' ASSUMPTIONS: Globals 0x00C616FC:TList, 0x00C61700:TScreen, 0x00C61CF8:TGadget (fields
' alive/+0x38 and hidden/+0x3c fix the type). 0x004A74E0 is _brl_retro_Upper.
' The If/Else order is load-bearing: the a1="" arm must come FIRST (jne vs je at byte 194).
'!Global g_screens:TList
'!Global g_curscreen:TScreen
'!Global g_activegadget:TGadget
LogLine("SetActive:" + a0)
For Local s:TScreen = EachIn g_screens
	If Upper(s.name) = Upper(a0)
		g_curscreen = s
	End If
Next
If a1 = ""
	If g_activegadget And g_activegadget.alive And g_activegadget.hidden = 0
		TScreen.SetActiveGadget(TGadget.GetActiveGadgetName())
	End If
Else
	TScreen.SetActiveGadget(a1)
End If
Return g_curscreen
