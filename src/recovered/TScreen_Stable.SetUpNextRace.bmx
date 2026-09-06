' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH on its own does
' not certify the text -- see docs/reference/codegen-patterns.md 13.2.
' TScreen_Stable.SetUpNextRace
' VA 0x00588574   275 bytes   vtable slot 0x50   sig ()i   KIND=Function
' byte-identical vs NSS5.exe (275/275, mode=reloc, reloc_masked=28)
'
' assumes module globals:
'   Global g_stable_panel:TPanel      ' 0x00c6dee4  (SetText is TGadget slot 0x64)
'   Global g_stable_racecount:Int     ' 0x00c6df64
'   Global g_stable_int04:Int         ' 0x00c6df6c
'   Global g_stable_int05:Int         ' 0x00c6df70
'   Global g_stable_button:TButton    ' 0x00c6debc  (SetIcon 0x90, CreateToolTip 0x80)
'   Global g_stable_icon:TImage       ' 0x00c6dea8  -- globals_final says Object; it is
'                                     '   passed to TButton.SetIcon(:TImage), so TImage.
'
' String literals are masked absolute .data pointers -- the GetText keys and the two
' literal fragments in the SetText expression are PLACEHOLDERS; only their COUNT and
' concat ORDER are pinned by the bytes:
'   GetText(k) + <lit> + <Int racenum> + <lit>   (three _bbStringConcat, one _bbStringFromInt)
'
' Class-table interior pointers resolved:
'   0x00c6e7f0 = THorse+0x68        THorse.SelectRunners(i)
'   0x00c6e7f4 = THorse+0x6c        THorse.SetRaceOdds()
'   0x00c6e264 = TScreen_Stable+0x5c  own Function -> unqualified RefreshRunners(0)
'   0x00c61cc0 = TScreen+0x94       TScreen.DoMessage($,i,i)
'
' The `If ... Return 0 / EndIf` early-return form is what emits `mov eax,0 / jmp end`;
' an If/Else would have emitted the jmp alone.

	Function SetUpNextRace:Int()
		' 0x00C6DF64, measured: 0x00588585 `830564dfc60001 add dword ptr [0xc6df64],1`,
' 0x0058858C `833d64dfc60006 cmp dword ptr [0xc6df64],6` and 0x005885CE
' `ff3564dfc600 push dword ptr [0xc6df64]` into the panel caption. THorse.Render,
' TScreen_Stable.FinishRace and TScreen_Stable.Update use the g_stable_racenum spelling
' for the DIFFERENT slot 0x00C6DF6C, which TScreen_Stable.RefreshRunners calls
' g_stable_selectedrunner, so this counter shared a variable with theirs.
		'!Global g_stable_racecount:Int
		'!Global g_stable_panel:TPanel
		'!Global g_stable_int04:Int
		'!Global g_stable_int05:Int
		'!Global g_stable_button:TButton
		'!Global g_stable_icon:TImage
		LogLine("SetUpNextRace")
		g_stable_racecount :+ 1
		If g_stable_racecount > 6
			TScreen.DoMessage(GetText("CMESSAGE_NOMORERACES"),0,0)
			Return 0
		EndIf
		g_stable_panel.SetText(GetText("stable_Race") + " " + g_stable_racecount + " / 6","",-1,-1)
		g_stable_int04 = 0
		g_stable_int05 = 1
		THorse.SelectRunners(6)
		THorse.SetRaceOdds()
		RefreshRunners(0)
		g_stable_button.SetIcon(g_stable_icon)
		g_stable_button.CreateToolTip(GetText("tt_StartRace"))
	End Function
