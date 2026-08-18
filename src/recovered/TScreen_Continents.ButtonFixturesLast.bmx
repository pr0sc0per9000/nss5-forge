' TScreen_Continents.ButtonFixturesLast
' VA 0x005488FB   117 bytes   vtable slot 0x60   sig ()i
' byte-identical vs NSS5.exe (117/117, original length from Ghidra's inventory)
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables)
'   differ by construction between probe and NSS5.exe; the emitted code is identical.
' module Global assumed (name ours, type load-bearing): Global g_comp:TCompetition (0x00C67220)
' Select (not If/ElseIf) is load-bearing: it loads comptype into a register before comparing,
'   which is the 4-byte difference against the If form.

	Function ButtonFixturesLast:Int()
		'!Global g_comp:TCompetition
		If g_comp <> Null
			Select g_comp.comptype
			Case 1
				g_comp = g_comp.GetCupLastRound()
				TScreen_Continents.SetUpFixturesTable(1)
			Default
				TScreen_Continents.SetUpFixturesTable(9999999)
			End Select
		End If
	End Function
