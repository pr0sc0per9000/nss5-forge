' TRoulette.GetResult
' VA 0x00575795   687 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, slot 0x40
' ASSUMPTIONS
'  * Globals (names ours; only the declared TYPE is load-bearing):
'      0x00C6BBC4 g_roulette_spinning:Int   0x00C6BBC8 g_roulette_result:Int
'      0x00C6BCBC g_roulette_pockets:Int[]  0x00C6BA60 g_roulette_bets:Int[]
'      0x00C6BBBC g_roulette_wheel:TRouletteWheel
'      0x00C6BBC0 g_roulette_ball:TRouletteBall
'      0x00C6F028 g_profile:TProfile        0x00C5B1C8 g_font_msg:TBitmapFont
'      0x00C6B834 g_blackjack_int01:Int
'      0x00C6EFE4 g_engine_int162:Int       0x00C6EFE8 g_engine_int163:Int
'      0x00C6B850 g_snd_lose:TSound         0x00C6F0D4 g_snd_win:TSound
'      0x00C6F090 g_chan_bet:TChannel
'    Both "Object[]" rows are really Int[]: every element load is a bare `mov` with no
'    refcount traffic (guide 11.2/16.7).
'    The two sound Globals and the channel come from BRL PlaySound(:TSound,:TChannel)
'    and the push order (0x00C6F090 pushed first = argument 1).
'  * `Local win` and `Local r` are register locals (esi / ebx); the prologue has no
'    `sub esp` at all, so nothing in this body reaches the stack.
'  * `/ 2` is the signed-division idiom `cdq / and edx,1 / add / sar 1`, not `Shr`.
'  * The message text is the left-associative `GetText(..) + " " + FormatMoney(..)`
'    form (concat(text," ") first) -- guide 16.1.
'  * All literals read out of NSS5.exe.

'!Global g_roulette_spinning:Int
'!Global g_roulette_result:Int
'!Global g_roulette_pockets:Int[]
'!Global g_roulette_wheel:TRouletteWheel
'!Global g_roulette_ball:TRouletteBall
'!Global g_roulette_bets:Int[]
'!Global g_profile:TProfile
'!Global g_snd_lose:TSound
'!Global g_snd_win:TSound
'!Global g_chan_bet:TChannel
'!Global g_font_msg:TBitmapFont
'!Global g_blackjack_int01:Int
'!Global g_engine_int162:Int
'!Global g_engine_int163:Int

Function GetResult:Int()
	g_roulette_spinning = 1
	g_roulette_result = g_roulette_pockets[Int(g_roulette_ball.fPocket)]
	g_roulette_wheel.fSpeed = 0.0
	FlushAllInput()
	Local win:Int = 0
	Local r:Int = g_roulette_result
	If r > 0 And r < 37 And r Mod 2 = 1
		win = win + g_roulette_bets[0] * 2
	End If
	If r > 0 And r < 37 And r Mod 2 = 0
		win = win + g_roulette_bets[1] * 2
	End If
	If TRouletteWheel.GetColour(r) = 1
		win = win + g_roulette_bets[2] * 2
	End If
	If TRouletteWheel.GetColour(r) = 0
		win = win + g_roulette_bets[3] * 2
	End If
	If r > 0 And r < 19
		win = win + g_roulette_bets[4] * 2
	End If
	If r > 18 And r < 37
		win = win + g_roulette_bets[5] * 2
	End If
	If win > 0
		g_profile.UpdateBank(win)
		PlaySound(g_snd_win, g_chan_bet)
		TScreenMessage.Create(g_engine_int162 / 2, g_engine_int163 / 2, GetText("bet_YouWon") + " " + FormatMoney(win, 1), g_blackjack_int01, g_font_msg, Null, 1.0, "FFFFFF")
		g_profile.CheckAchievement(73)
	Else
		PlaySound(g_snd_lose, g_chan_bet)
		TScreenMessage.Create(g_engine_int162 / 2, g_engine_int163 / 2, GetText("bet_YouLost") + " " + FormatMoney(TScreen_Roulette.GetBetTotal(), 1), g_blackjack_int01, g_font_msg, Null, 1.0, "FFFFFF")
	End If
	TScreen_Roulette.SetUpScreen(0)
End Function
