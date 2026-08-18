' TTraining.Update  -- KIND=Function (STATIC method on TTraining), slot 0x58, sig ()i
' VA 0x0057FD94   621 bytes   (original length from Ghidra's inventory)
' ORACLE: MATCH mode=reloc  621/621  reloc_masked=60
'
' ASSUMPTIONS / RESOLUTIONS
'   FUN_0059B25E = _brl_audio_PlaySound.  Push order gives PlaySound(sound, channel).
'   Class-table interiors (globals_classtable_slots.tsv), written as ordinary static calls:
'     0x00C6D6A8 = TTrainingObject+0x30 UpdateAll()      0x00C6D534 = TTraining+0x90 TimeUp()
'     0x00C6D504..0x00C6D528 = TTraining+0x60..+0x84 =
'        UpdatePace, UpdateDribbling, UpdateFlair, UpdateTackling1, UpdateTackling2,
'        UpdatePassing, UpdateHeading1, UpdateHeading2, UpdateShooting1, UpdateShooting2
'   Globals (names ours, TYPES load-bearing):
'     0x00C6CF90 g_train_mode:Int        0x00C6CF98 g_train_state:Int
'     0x00C6CF9C g_train_counter:Int     0x00C6CFA0 g_train_lasttick:Int
'     0x00C6EFD4 g_time:Int              0x00C6EFE4 g_screen_w:Int
'     0x00C6CF64 g_snd_beep2:TSound      0x00C6CF60 g_snd_beep1:TSound
'        (both are "Object, init=bbNullObject, no call-site typing" in globals_final;
'         TSound is forced by PlaySound's signature, not by a construction site)
'     0x00C6F090 g_chan_sfx:TChannel     (same -- forced by PlaySound arg 2)
'     0x00C6CFB0 g_train_scrollx:Float   0x00C6CFB4 g_train_scrollx2:Float
'     0x00C5B1C4 g_font_scroll:TBitmapFont   (slot 0x54 = TBitmapFont.GetTxtWidth($)i)
'     0x00C6CFAC g_train_scrolltext:String   -- globals_final says Int; it is a String.
'        TTraining.TimeUp (already recovered) shows full retain/release traffic on this
'        address, and here it is the ($) argument of GetTxtWidth.
'     0x00C61724 g_screen_top:Float
'     0x00C6D010 g_train_fade:Float      0x00C6D014 g_train_fadestep:Float
'   Float constants read out of the image: 7.5, 10.0, 0.5, 10.0, 1.25, 10.0, 10.0
'   (0x00C928EC..0x00C92904).
'
' TWO SOURCE-FORM POINTS THAT COST BYTES
'  * `0 - g_font_scroll.GetTxtWidth(...)` is required, NOT the unary `-`.  The unary form
'    emits `neg eax` and no ebx; the original emits `push ebx / mov ebx,0 / sub ebx,eax /
'    pop ebx`.  That single character is the whole 614-vs-621 length gap.
'  * Both dispatches are Select, not If/ElseIf: every `cmp eax,imm / je` sits back to back
'    ahead of all the bodies (guide 10.2).  The first has an empty `Case 0` and no Default
'    (the `EB 52` before it is the no-match path); the second has an empty `Case 2`.
'
' `g_train_counter :- 1` emits `sub dword [g],1`; the `x = x - 1` spelling does not.
	Function Update:Int()
		'!Global g_train_mode:Int
		'!Global g_train_state:Int
		'!Global g_train_counter:Int
		'!Global g_train_lasttick:Int
		'!Global g_time:Int
		'!Global g_snd_beep2:TSound
		'!Global g_snd_beep1:TSound
		'!Global g_chan_sfx:TChannel
		'!Global g_train_scrollx:Float
		'!Global g_train_scrollx2:Float
		'!Global g_font_scroll:TBitmapFont
		'!Global g_train_scrolltext:String
		'!Global g_screen_w:Int
		'!Global g_screen_top:Float
		'!Global g_train_fade:Float
		'!Global g_train_fadestep:Float
		If g_train_mode = 0 Then Return 0
		TTrainingObject.UpdateAll()
		If g_train_state = 1
			If g_train_counter > -1
				If g_time > g_train_lasttick + 1000
					g_train_lasttick = g_time
					g_train_counter :- 1
					If g_train_counter < 6
						PlaySound(g_snd_beep2, g_chan_sfx)
					Else
						PlaySound(g_snd_beep1, g_chan_sfx)
					EndIf
				EndIf
				If g_train_counter <= 0
					g_train_counter = 0
					TTraining.TimeUp()
				EndIf
			EndIf
			Select g_train_mode
				Case 0
				Case 1
					TTraining.UpdatePace()
				Case 2
					TTraining.UpdateDribbling()
				Case 3
					TTraining.UpdateFlair()
				Case 4
					TTraining.UpdateTackling1()
				Case 5
					TTraining.UpdateTackling2()
				Case 6
					TTraining.UpdatePassing()
				Case 7
					TTraining.UpdateHeading1()
				Case 8
					TTraining.UpdateHeading2()
				Case 9
					TTraining.UpdateShooting1()
				Case 10
					TTraining.UpdateShooting2()
			End Select
		Else
			g_train_scrollx2 = g_train_scrollx
			g_train_scrollx = g_train_scrollx - 7.5
			If g_train_scrollx < 0 - g_font_scroll.GetTxtWidth(g_train_scrolltext)
				g_train_scrollx = g_screen_w
				g_train_scrollx2 = g_screen_w
			EndIf
		EndIf
		Select g_train_state
			Case 0
				g_train_fade = g_screen_top + 10.0
				g_train_fadestep = 0.5
			Case 1
				If g_train_fade > 10.0
					g_train_fade = g_train_fade - g_train_fadestep
					g_train_fadestep = g_train_fadestep * 1.25
				EndIf
				If g_train_fade < 10.0
					g_train_fade = 10.0
				EndIf
			Case 2
		End Select
	End Function
