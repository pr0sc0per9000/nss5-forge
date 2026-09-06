' TSlotMachine.DoPrize
' VA 0x005784EF   407 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, class-table slot 0x44
' ASSUMPTIONS
'  * '!Global g_slot_bet:Int             -- 0x00C6B85C (the stake; read once into a Local)
'    Original data-section value is 50, read directly from NSS5.exe. See
'    codegen-patterns 21.1/21.3.
'  * '!Global g_slot_reel1:TSlotStrip    -- 0x00C6C558 (construction-typed)
'  * '!Global g_slot_reel2:TSlotStrip    -- 0x00C6C55C
'  * '!Global g_slot_reel3:TSlotStrip    -- 0x00C6C560   (.fruit is +0x2C)
'  * '!Global g_slot_snd_win:TSound      -- 0x00C6C550 (arg 1 of _brl_audio_PlaySound)
'  * '!Global g_audio_channel:TChannel   -- 0x00C6F090 (arg 2 of _brl_audio_PlaySound)
'  * '!Global g_profile:TProfile         -- 0x00C6F028; slot 0xFC = TProfile.UpdateBank(i),
'    slot 0x150 = TProfile.CheckAchievement(i)
'  * '!Global g_msg_int01:Int            -- 0x00C6B834 (4th arg of TScreenMessage.Create)
'  * '!Global g_font_main:TBitmapFont    -- 0x00C5B1C8 (construction-typed)
'  * '!Global g_screen_w:Int             -- 0x00C6EFE4
'  * '!Global g_screen_h:Int            -- 0x00C6EFE8
' SHAPE NOTES
'  * `Local bet:Int = g_slot_bet` is real: the Global is loaded into edx once, before the
'    reel compares, and re-used in both arms. Reading the Global inline would re-load it.
'  * The `* 10` is a SEPARATE statement in each arm (`mov ebx,eax / imul ebx,ebx,10`).
'    Folding it into one expression emits `imul eax,eax,10 / mov ebx,eax` and diverges
'    at byte 85.
'  * If / ElseIf, not Select: the first arm ends in a `jmp` past the second arm's tests.
	Function DoPrize:Int()
		'!Global g_slot_bet:Int = 50
		'!Global g_slot_reel1:TSlotStrip
		'!Global g_slot_reel2:TSlotStrip
		'!Global g_slot_reel3:TSlotStrip
		'!Global g_slot_snd_win:TSound
		'!Global g_audio_channel:TChannel
		'!Global g_profile:TProfile
		'!Global g_msg_int01:Int
		'!Global g_font_main:TBitmapFont
		' THE RUNTIME WINDOW SIZE IS 0x00C6EFE4/0x00C6EFE8, NOT 0x00C6EFDC/0x00C6EFE0.
' The lower pair are the 800x600 DESIGN canvas: they are static initialisers in the PE
' image and no instruction anywhere in the program stores to them. The upper pair are
' written from the chosen TGraphicsMode in FUN_00506A5D (0x00506AF6
' `mov [0xc6efe4],eax`, fallback 0x00506B3A `mov [0xc6efe4],0x320`).
' TScreen.UpdateOffset settles which is which: 0x00510825 `mov eax,[0xc6efe4]` /
' `sub eax,[0xc6efdc]` halved into the borderX float, and 0x00510844 the same for
' 0x00C6EFE8 minus 0x00C6EFE0 into borderY.
' g_screen_width and g_screen_height are TScreen_Kits.CreateScreen's and
' TScreen_Pairs.CreateScreen's names for the LOWER pair, so this win message was centred
' on (400,300) rather than the window centre. The three sibling win messages in the
' casino read the upper pair.
		'!Global g_screen_w:Int
		'!Global g_screen_h:Int
		Local prize:Int = 0
		Local bet:Int = g_slot_bet
		If g_slot_reel1.fruit = g_slot_reel2.fruit And g_slot_reel2.fruit = g_slot_reel3.fruit
			prize = bet * 30 / 10
			prize = prize * 10
		ElseIf g_slot_reel1.fruit = g_slot_reel2.fruit Or g_slot_reel1.fruit = g_slot_reel3.fruit Or g_slot_reel2.fruit = g_slot_reel3.fruit
			prize = Int(bet * 2.4 / 10.0)
			prize = prize * 10
		EndIf
		If prize > 0
			PlaySound(g_slot_snd_win, g_audio_channel)
			g_profile.UpdateBank(prize)
			TScreenMessage.Create(g_screen_w / 2, g_screen_h / 2, GetText("bet_YouWon") + " " + FormatMoney(prize, 1), g_msg_int01, g_font_main, Null, 1.0, "FFFFFF")
			g_profile.CheckAchievement(74)
		EndIf
		TScreen_GameMenu.UpdateTitlePanel()
	End Function
