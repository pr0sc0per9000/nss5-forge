' TScreen_Formation.RefreshButtons
' VA 0x0054C01C   879 bytes   vtable slot 0x3c   sig ()i   KIND=Function
' byte-identical vs NSS5.exe (879/879, original length from Ghidra's inventory, mode=reloc)
' assumptions:
'   0x00C677A0 :TScreen (the formation screen; +0x0C gadgetlist is walked)
'   0x00C677B0 :TTeam   -- globals_final says "Object/usage/low". TTeam is what the code
'     proves: +0x3C is read as an Int (newstarselno) and +0x24 is an object whose +0x08 is
'     a String, i.e. formation:TFormation with TFormation.name at +0x08.
'   0x00C677D8 :Int, 0x00C677DC :Int (globals_final calls the latter TPlayer -- it is
'     compared `> 0` and `= 0` with a bare dword, so it is an Int).
'   0x00C5B22C :TPlayer, field +0x3C = unhappiness (NOT selectionno at +0xBC -- that
'     spelling is 3 bytes long and was the only divergence in the first draft).
'   0x00C6E91C is a STRING (a colour), not the Int globals_final claims -- it is pushed
'     straight into TGadget.SetColour($,$).
'   TGadget slots 0x54 Hide, 0x58 Show, 0x6C SetColour, 0x70 SetAlph; +0x38 alive.
' Shape: this is a Select on b.name, not an If/ElseIf cascade -- all eight string compares
' are emitted back to back with every target past the last one (guide 10.2). "pan_title"
' and "btn_team" are Cases with EMPTY bodies. The Default body is the fall-through right
' after the compares, so no no-match `jmp` is emitted.
	Function RefreshButtons:Int()
		'!Global g_screen_formation_screen:TScreen
		'!Global g_screen_formation_team:TTeam
		'!Global g_screen_formation_int05:Int
		'!Global g_screen_formation_int06:Int
		'!Global g_engine_tplayer:TPlayer
		'!Global g_screen_stable_colour:String
		For Local b:TButton = EachIn g_screen_formation_screen.gadgetlist
			Select b.name
				Case "pan_title"
				Case "btn_play"
					b.SetAlph(0.5)
					b.alive = 0
					If g_screen_formation_int06 = 0
						b.SetAlph(1.0)
						b.alive = 1
					End If
				Case "btn_team"
				Case "btn_position"
					b.Hide()
					If g_screen_formation_team.newstarselno > 0 And g_screen_formation_int05 = 0
						b.Show()
					End If
				Case "btn_ask"
					b.Hide()
					If g_screen_formation_int05 = 0 Then b.Show()
					b.SetAlph(0.5)
					b.alive = 0
					If g_screen_formation_int06 > 0
						b.SetAlph(1.0)
						b.alive = 1
					End If
				Case "btn_cancel"
					b.Hide()
					If g_screen_formation_int05 = 0 Then b.Show()
					b.SetAlph(0.5)
					b.alive = 0
					If g_screen_formation_int06 > 0
						b.SetAlph(1.0)
						b.alive = 1
					End If
				Case "btn_opponent"
					b.Hide()
					If g_screen_formation_int05 = 0 Then b.Show()
					b.SetAlph(0.5)
					b.alive = 0
					If g_screen_formation_int06 = 0
						b.SetAlph(1.0)
						b.alive = 1
					End If
				Case "btn_help"
					b.Hide()
					If g_screen_formation_int05 = 0 Then b.Show()
				Default
					b.SetColour("FFFFFF", "FFFFFF")
					If b.name = g_screen_formation_team.formation.name
						b.SetColour(g_screen_stable_colour, "FFFFFF")
					End If
					b.alive = 1
					If g_engine_tplayer.unhappiness = 1 Or g_screen_formation_int05 Or g_screen_formation_int06 > 0
						b.alive = 0
					End If
			End Select
		Next
	End Function
