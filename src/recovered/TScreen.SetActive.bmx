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
' CASE DIRECTION CORRECTED 2026-08-22: 2 call sites -> .ToLower().
' extracted/runtime_helpers.tsv named 0x004A7410 `_brl_retro_Lower` and 0x004A74E0
' `_brl_retro_Upper`. Both were wrong and neither address is a brl.retro wrapper:
' 0x004A7410 is `_bbStringToUpper` and 0x004A74E0 is `_bbStringToLower`. NSS5.exe's
' own 21-byte retro wrappers at 0x0059C8FD (Lower) and 0x0059C912 (Upper) CALL those
' two addresses, and a wrapper cannot be the function it calls. The wrong row masked
' by name, so this body certified with the case conversion running backwards. Full
' derivation and the discriminating 3x4 matrix: docs/reference/codegen-patterns.md
' 15.6. Re-verified under NSS5_NO_LEARN=1 on worker trees 380 and 380b.
LogLine("SetActive:" + a0)
For Local s:TScreen = EachIn g_screens
	If s.name.ToLower() = a0.ToLower()
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
