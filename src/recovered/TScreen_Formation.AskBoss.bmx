' TScreen_Formation.AskBoss
' VA 0x0054CD46   868 bytes  mode=reloc  byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, slot 0x50
' ASSUMPTIONS (Global names are ours; declared TYPES are load-bearing)
'   0x00C5D228 g_difficulty:Int        -- same Global TPlayer.CheckBallContact types Int (1..3)
'   0x00C677B0 g_playerteam:TTeam      -- .formation :TFormation at +0x24; TFormation slot
'                                          0x5C = GetPosFromSelectionNo(i)i (see CheckPosition)
'   0x00C677DC g_screen_formation_selno2:Int -- globals_final says TPlayer(construction), but
'                                          it is pushed as UpdatePosition(i)'s Int argument
'   0x00C6F028 g_profile:TProfile      -- .position +0x30, .shooting +0xA8, .passing +0xAC,
'                                          .tackling +0xB0, .relationboss +0x104
' SHAPE NOTES -- all three cascades are SELECTs, worth 21 bytes together
'   * outer Select on g_difficulty: `mov eax,[g] / cmp eax,1 / je / cmp eax,2 / je /
'     cmp eax,3 / je / jmp` -- every target past the last compare (codegen-patterns 10.2).
'   * Select on g_profile.position with a Default arm, and a Select on `pos` for the
'     failure messages; both keep the subject in a register across all compares.
'   * `Local ok:Int = 0` is a REAL statement -- the original emits `mov ebx,0` right after
'     the first End Select's fallthrough `jmp +0`.
'   * The ok=1 arm ends in an explicit `Return 0` (mov eax,0 / jmp epilogue); as the Then
'     half of an If/Else the body is 863 bytes.
'   * `< 80` is `cmp eax,0x50 / setl`, i.e. the source really spells the threshold 80.
	Function AskBoss:Int()
		'!Global g_difficulty:Int
		'!Global g_playerteam:TTeam
		'!Global g_screen_formation_selno2:Int
		'!Global g_profile:TProfile
		Select g_difficulty
			Case 1
				LogLine("Easy")
				TScreen.DoMessage(GetText("CMESSAGE_NEWPOSITIONSUCCESS"), 0, 0)
				TScreen_Formation.UpdatePosition(g_screen_formation_selno2)
				Return 0
			Case 2
				If g_profile.relationboss < 50
					TScreen.DoMessage(GetText("CMESSAGE_NEWPOSITIONFAIL"), 0, 0)
					TScreen_Formation.CancelRequest()
					Return 0
				End If
			Case 3
				If g_profile.relationboss < 70
					TScreen.DoMessage(GetText("CMESSAGE_NEWPOSITIONFAIL"), 0, 0)
					TScreen_Formation.CancelRequest()
					Return 0
				End If
		End Select
		Local ok:Int = 0
		Local pos:Int = g_playerteam.formation.GetPosFromSelectionNo(g_screen_formation_selno2)
		Select g_profile.position
			Case 1
				If pos = 1 Then ok = 1
			Case 5
				If pos = 5 Then ok = 1
			Default
				If pos = 2 Or pos = 3 Or pos = 4 Then ok = 1
		End Select
		If ok = 1
			TScreen.DoMessage(GetText("CMESSAGE_NEWPOSITIONSUCCESS"), 0, 0)
			TScreen_Formation.UpdatePosition(g_screen_formation_selno2)
			Return 0
		End If
		Select pos
				Case 1
					If g_profile.tackling < 80 And (g_profile.tackling < g_profile.shooting Or g_profile.tackling < g_profile.passing)
						TScreen.DoMessage(GetText("CMESSAGE_NEWPOSITIONFAILDEFENDER"), 0, 0)
						TScreen_Formation.CancelRequest()
						Return 0
					End If
				Case 5
					If g_profile.shooting < 80 And (g_profile.shooting < g_profile.tackling Or g_profile.shooting < g_profile.passing)
						TScreen.DoMessage(GetText("CMESSAGE_NEWPOSITIONFAILFORWARD"), 0, 0)
						Return 0
					End If
				Default
					If g_profile.passing < 80 And (g_profile.passing < g_profile.tackling Or g_profile.passing < g_profile.shooting)
						TScreen.DoMessage(GetText("CMESSAGE_NEWPOSITIONFAILMIDFIELDER"), 0, 0)
						TScreen_Formation.CancelRequest()
						Return 0
					End If
		End Select
		TScreen.DoMessage(GetText("CMESSAGE_NEWPOSITIONSUCCESS"), 0, 0)
		TScreen_Formation.UpdatePosition(g_screen_formation_selno2)
	End Function
