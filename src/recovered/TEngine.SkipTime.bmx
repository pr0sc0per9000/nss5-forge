' TEngine.SkipTime  -- KIND=Function (static), slot 0xE4, sig ()i
' VA 0x004D7541   475 bytes
' byte-identical vs NSS5.exe (475/475, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=35)
'
' ASSUMPTIONS
'  * Globals (names ours; all Int -- every access is a bare dword cmp/mov with no
'    refcount traffic, guide 11.2):
'      0x00C6CF90 -> g_trainingon        0x00C6CF98 -> g_trainingmode
'      0x00C5B1FC -> g_matchstate        0x00C5B258 -> g_engine_flag28
'      0x00C5B210 -> g_engine_flag20     0x00C5B208 -> g_engine_half
'      0x00C5B24C -> g_engine_kickoffside
'  * Every `call dword ptr [0x00Cxxxxx]` is a class-table slot, resolved via
'    class_tables.tsv + vtable_map.tsv:
'      0x00C6B274 TScreenMessage+0x40 ClearAll(i)      0x00C5FB44 TPlayer+0x1F8 ResetAnimationsAll
'      0x00C5F9F4 TPlayer+0xA8 ResetKickAll            0x00C5F9FC TPlayer+0xB0 JoyClearAll
'      0x00C5FAB0 TPlayer+0x164 GetHumanPlayer         0x00C5FA8C TPlayer+0x140 SetTunnelPositionAll
'      0x00C5BB10 TEngine+0xE0 EndMatch                0x00C5BB30 TEngine+0x100 PauseEngine
'      0x00C5BAA0 TEngine+0x70 SetUpSetPiece(i,i,i,i)  0x00C5BAA4 TEngine+0x74 SetPiece
'      0x00C5BB18 TEngine+0xE8 ForcePositionResetAll   0x00C67978 TScreen_Formation+0x34 SetUpScreen(i)
'      0x00C6D4F8 TTraining+0x54 StartChallenge
'    TEngine's own slots are written unprefixed (guide 3d).
'  * 0x005071C3 = FlushAllInput (src/recovered_module/).
'  * p.joy.kickenabled is TJoy +0x18; p.matchstats is TPlayer +0x188 and slot 0x44 on
'    TStats_Match is SortListBy(i) -- called with 28.
'  * The training test is an ENCLOSING If with an explicit `Return 0` at its end
'    (`cmp [0xc6cf90],0 / je` with the whole match-state cascade in the else path).
'    Ghidra prints it inverted.
'  * Both `Select` blocks are real Selects, not If/ElseIf: all Case compares are emitted
'    back to back with every target past the last compare (guide 10.2). The training
'    Select has an EMPTY `Case 1` (a bare `EB 08` to End Select) and no Default.
'  * `If ... And p` uses the object truth test (setne al / movzx eax,al), not `p <> Null`
'    spelled as a cmp/je.
	Function SkipTime:Int()
		'!Global g_trainingon:Int
		'!Global g_trainingmode:Int
		'!Global g_matchstate:Int
		'!Global g_engine_flag28:Int
		'!Global g_engine_flag20:Int
		'!Global g_engine_half:Int
		'!Global g_engine_kickoffside:Int
		LogLine("SkipTime")
		TScreenMessage.ClearAll(0)
		TPlayer.ResetAnimationsAll()
		TPlayer.ResetKickAll()
		TPlayer.JoyClearAll()
		FlushAllInput()
		Local p:TPlayer = TPlayer.GetHumanPlayer()
		If p And p.joy
			p.joy.kickenabled = 0
		End If
		If g_trainingon <> 0
			Select g_trainingmode
				Case 0
					TTraining.StartChallenge()
				Case 1
				Case 2
					EndMatch()
			End Select
			Return 0
		End If
		If g_matchstate = 11
			If g_engine_flag28 = 0 And p
				g_engine_flag28 = 1
			Else
				EndMatch()
			End If
		ElseIf g_matchstate = 0
			If g_engine_flag28 = 0 And p
				g_engine_flag28 = 1
				p.matchstats.SortListBy(28)
			Else
				If g_engine_flag20 = 0
					PauseEngine()
					TScreen_Formation.SetUpScreen(0)
				End If
				TPlayer.SetTunnelPositionAll()
				SetUpSetPiece(2, g_engine_half Mod 2 + 1, 0, 0)
			End If
		ElseIf g_matchstate = 8
			Select g_engine_kickoffside
				Case 1
					SetUpSetPiece(2, 2, 0, 0)
				Case 2
					SetUpSetPiece(2, 1, 0, 0)
			End Select
		Else
			If SetPiece() <> 0
				ForcePositionResetAll()
			End If
		End If
	End Function
