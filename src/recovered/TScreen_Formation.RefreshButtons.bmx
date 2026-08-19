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
'   0x00C5B22C :TFixture, field +0x3C = level. An Int compare at +0x3C against 1 compiles
'     identically regardless of field name, so byte length alone cannot pick between
'     TPlayer.unhappiness and TFixture.level -- both sit at offset 0x3C (object_model.json).
'     TEngine.SetUpMatch.bmx settles the type: it constructs this address directly
'     (`g_fixture = a0:TFixture`) and reads +0xc/+0x10/+0x18/+0x3c/+0x40/+0x50 through it,
'     all TFixture's own fields; TEngine.MatchOver.bmx independently corroborates +0xc
'     matchtype, +0x28 resulttype, +0x2c score1, +0x30 score2 and slot 0x78. Aliased to
'     g_fixture in extracted/global_alias_overrides.tsv; kept as `g_engine_tplayer` at the
'     source level per that file's evidence trail.
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
		'!Global g_engine_tplayer:TFixture
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
					If g_engine_tplayer.level = 1 Or g_screen_formation_int05 Or g_screen_formation_int06 > 0
						b.alive = 0
					End If
			End Select
		Next
	End Function
