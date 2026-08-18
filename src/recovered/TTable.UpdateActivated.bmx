' GLOBAL RENAMED (2026-08-15): g_Object101 -> g_curscreen. Same slot, 0x00C61700 -- THE ACTIVE
' SCREEN. This one slot carried FOUR names across the corpus: g_curscreen (majority, 8
' declarers), g_currentscreen, g_screen, and the decoder auto-name g_Object101. In the
' assembled program those became four independent Globals, so TScreen.SetActive wrote
' the newly-activated screen into one while the main loop's TScreen.Update and
' TScreen.Render read others. The game booted, opened its window and ran the
' fixed-timestep loop -- and drew the boot 'loading' screen forever, because the screen
' the loop rendered was never the screen SetActive had set. Byte-neutral; confirmed
' with scripts/reverify.py.
' Scope check before renaming: g_Object101 resolves to 0x00C61700 and nothing else
' anywhere in src/recovered. g_screen resolves to it only in TScreen.Update.bmx, the one
' file that states the address -- the other 8 g_screen declarers record no VA, and the
' name->address map is many-to-many, so sweeping it would be a guess.
' TTable.UpdateActivated   (KIND=Method, SIG=()i)
' VA 0x005168E1   953 bytes   (Ghidra-authoritative)
' byte-identical vs NSS5.exe (953/953, original length from Ghidra's inventory)
' ORACLE: mode=reloc  matched=953/953  reloc_masked=45  STATUS=MATCH
'
' ASSUMPTIONS / RESOLUTIONS
'   0x00C61700 g_curscreen:Object -- only compared against bbNullObject here, so the
'     declared type does not reach codegen; left as Object.
'   0x00C61724/28/40/44 g_screen_float01..04 -- the viewport origin and the mouse
'     position; (float03-float01, float04-float02) is the mouse in table space.
'   0x00C6F088 -> TChannel (slot 0x48 = TChannel.Playing, resolved against the BRL
'     class table at 0x00C9CC68); 0x00C61720 and 0x00C6171C -> TSound (they are the
'     first argument of _brl_audio_PlaySound).  Named g_chan_ui / g_snd_move /
'     g_snd_select here.
'   0x00C7E098 g_table_int05:Int is the scroll-repeat timestamp, 0x00C61CFC
'     g_table_int02:Int the repeat interval, 0x00C6EFD4 g_player_int50:Int the clock.
'   0x00C625F0 g_table_int03:Int is the inter-row gap.
'   KeyDown(162) = KEY_LCONTROL (`push 0xA2`); 0x005B4721 is the KeyDown|MouseDown
'     alias set, and the operand is a key code.
'   TTable fields: numdisplayitems +0x64, ih +0x68, selecteditem +0x70,
'     itemoffset +0x74, showheadings +0x7C, items +0x60; x/y/w from TGadget.
'   Hit test operand order is byte-observable: the original loads the MOUSE coordinate
'     first and `fxch`es, so it is `mx > Self.x`, not Ghidra's printed `Self.x < mx`.

'!Global g_screen_int03:Int
'!Global g_screen_float01:Float
'!Global g_screen_float02:Float
'!Global g_screen_float03:Float
'!Global g_screen_float04:Float
'!Global g_curscreen:Object
'!Global g_table_int02:Int
'!Global g_table_int03:Int
'!Global g_table_int05:Int
'!Global g_player_int50:Int
'!Global g_snd_move:TSound
'!Global g_snd_select:TSound
'!Global g_chan_ui:TChannel

	Method UpdateActivated()
		Self.Update()
		Local inp:Int = TScreen.GetInput()
		Local n:Int = Self.items.Count()
		Local nd:Int = Self.GetNoofDisplayItems()
		Local mx:Int = Int(g_screen_float03 - g_screen_float01)
		Local my:Int = Int(g_screen_float04 - g_screen_float02)
		Select inp
			Case 0
				If g_screen_int03 And g_curscreen <> Null
					Local yy:Int = Int(Self.y - g_table_int03 / 2 + Self.ih)
					If Self.showheadings = 0
						yy :- Self.ih + g_table_int03
					End If
					For Local i:Int = 1 To nd
						If mx > Self.x And mx < Self.x + Self.w And my >= yy And my < yy + Self.ih
							Self.selecteditem = i
							If i = 1 And g_player_int50 > g_table_int05 + g_table_int02
								Self.ScrollUp()
								g_table_int05 = g_player_int50
							End If
							If i = nd And g_player_int50 > g_table_int05 + g_table_int02
								Self.ScrollDown()
								g_table_int05 = g_player_int50
							End If
							Return 0
						End If
						yy :+ Self.ih + g_table_int03
					Next
				End If
			Case 1
				If g_chan_ui.Playing() = 0
					PlaySound(g_snd_move, g_chan_ui)
				End If
				Self.ScrollUp()
			Case 2
				If g_chan_ui.Playing() = 0
					PlaySound(g_snd_move, g_chan_ui)
				End If
				Self.ScrollDown()
			Case 5
				PlaySound(g_snd_select, g_chan_ui)
				Self.SelectCurrentItem()
			Case 3
				If g_chan_ui.Playing() = 0
					PlaySound(g_snd_move, g_chan_ui)
				End If
				If KeyDown(162)
					Self.selecteditem = 1
					Self.itemoffset = 0
				Else
					For Local i:Int = 1 To Self.numdisplayitems
						Self.ScrollUp()
					Next
				End If
			Case 4
				If g_chan_ui.Playing() = 0
					PlaySound(g_snd_move, g_chan_ui)
				End If
				If KeyDown(162)
					Self.selecteditem = nd
					Self.itemoffset = n - nd
				Else
					For Local i:Int = 1 To Self.numdisplayitems
						Self.ScrollDown()
					Next
				End If
		End Select
	End Method
