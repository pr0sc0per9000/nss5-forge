' TScreen_Stable.Update
' byte-identical vs NSS5.exe
' VA 0x00588C99   1072 bytes   mode=reloc   MATCH 1072/1072   reloc_masked=89
' KIND=Function (static), SIG ()i, class-table slot 0x64.
' Verified under NSS5_NO_LEARN=1, learned_helpers empty.
' Body-only format: statements only, parameters are a0, a1, ...
'
' The horse-race screen's per-frame tick. It only does anything in two states: 2 = a race
' is running, 3 = the race has just finished and the frozen greyscale snapshot is up.
'
' ASSUMPTIONS -- Global NAMES are ours; the declared TYPES are load-bearing. Addresses and
' names follow the sibling bodies TScreen_Stable.DoRace / .FinishRace / .RefreshRunners.
'   0x00C6DF70 g_stable_state:Int      0x00C6DF2C g_stable_int01:Int (the freeze timestamp)
'   0x00C6EFD4 g_matchtime:Int         0x00C6EFDC g_screenwidth:Int
'   0x00C6DF4C g_stable_startx:Float   -- the race camera's scroll x (DoRace's name)
'   0x00C6DF54 g_stable_startxprev:Float -- NEW here; last frame's scroll x, written and
'                                          never read in this body
'   0x00C6E29C g_stable_int26:Int      0x00C6E298 g_runners:TList (the selected runners)
'   0x00C6DF28 g_stable_obj845:Object  -- DoRace assigns it Null with full refcount traffic
'   0x00C61724/0x00C61728 g_screen_float01/02:Float  (the GrabPixmap origin)
'   0x00C6DF20 g_stable_sndFlash:TSound  0x00C6F090 g_chan_bet:TChannel
'   0x00C6DF6C g_stable_racenum:Int    0x00C6DF68 g_stable_stake:Int
'   0x00C6B834 g_msg_int01:Int         0x00C5B1C8 g_font_msg:TBitmapFont
'   0x00C6EFE4 g_screen_w:Int          0x00C6EFE8 g_screen_h:Int
'   0x00C6DF18 g_stable_volume:Float   0x00C6DF1C g_chan_race:TChannel (slot 0x38 SetVolume)
'   THorse: x +0x18, raceposition +0x5c, racenum +0x60, betprice +0x68.
'   Class-table calls: THorse+0x60 GetLeadingHorse, THorse+0x50 UpdateAllRunners,
'   TScreen_Stable+0x6c FinishRace (this Type's own slot, so a bare call),
'   TScreenMessage+0x30 Create, TList slot 0x88 Sort (both its defaults emitted at the
'   call site, hence the bare `g_runners.Sort()`), 0x8c ObjectEnumerator.
'   0x0050802D = GreyscaleImage and 0x0050720B = FormatMoney (src/recovered_module),
'   0x005AE4FF = _brl_max2d_GrabPixmap, 0x004C5549 = GetText, 0x005B9690 = _bbFloatToInt.
'   Float constants read out of NSS5.exe: 0x00C93B40 256.0, 0x00C93B44 1.2,
'   0x00C93B48 -11520.0, 0x00C93B4C 1.5, 0x00C93B50 0.25, 0x00C93B54 11552.0,
'   0x00C93B58 0.01. Strings via harness.read_string: 'bet_YouWon' 0x00C909D0,
'   'bet_YouLost' 0x00C909F0, ' ' 0x00C6EF28, 'FFFFFF' 0x00C5D680.
'
' SHAPE NOTES (each one was a measured iteration)
'   * The state dispatch is a Select with a Default and an EMPTY `Case 2`, and the whole
'     race body sits AFTER `End Select`. That is not a stylistic choice: `Case 2`'s label
'     is bound at 0x00588D07 and the two bytes there are `EB 00`, a jump to the
'     end-of-Select label two bytes later. bcc emits `bra(end)` after every case body and
'     cgflow.cpp then deletes the ones that became unreachable -- Case 3's is deleted
'     because its body ends in `Return 0`, and the surviving `EB 00` can only be the
'     `bra(end)` of a case whose body is empty. Written with the race code inside `Case 2`
'     the body is the same length but carries that jump at the END instead.
'   * The two scroll-clamp tests are NESTED Ifs, not `And`. A standalone float If emits
'     the NEGATED setcc (`setbe`) and jumps when it is true; a float compare used as one
'     term of an `And` emits the straight setcc (`seta`). Both spellings are 1072 bytes and
'     they differ in exactly those two setcc/jcc pairs. The later
'     `If allDone And g_stable_volume > 0.0` really is an `And` and shows the straight form.
'   * `Local w:Int = g_stable_stake * h.betprice` is load-bearing and costs zero bytes: the
'     original computes the product BEFORE pushing TScreenMessage.Create's five trailing
'     arguments, which is what a Local consumed by the next statement produces
'     (codegen-patterns 16.2). Inline it and the multiply moves nine bytes later.
'   * `g_matchtime :- (g_matchtime - g_stable_int01)` is the original's own spelling; it
'     emits `sub [mem],reg`, which `g_matchtime = g_stable_int01` does not.
'!Global g_stable_state:Int
'!Global g_stable_int01:Int
'!Global g_matchtime:Int
'!Global g_stable_startx:Float
'!Global g_stable_startxprev:Float
'!Global g_screenwidth:Int
'!Global g_stable_int26:Int
' 0x00C6E298 is the RACE RUNNERS list, not the master horse list. THorse.SelectRunners
' declares both in one body -- g_horses for 0x00C6E294 (the list it enumerates and
' sorts) and g_runners for 0x00C6E298 (the list it Clears and AddLasts into) -- so the
' two are provably different slots, and the module body creates them separately. Spelled
' g_runners here, this body's slot shared the emitted variable of the master list.
'!Global g_runners:TList
'!Global g_stable_obj845:Object
'!Global g_screen_float01:Float
'!Global g_screen_float02:Float
'!Global g_stable_sndFlash:TSound
'!Global g_chan_bet:TChannel
'!Global g_stable_racenum:Int
'!Global g_stable_stake:Int
'!Global g_msg_int01:Int
'!Global g_font_msg:TBitmapFont
'!Global g_screen_w:Int
'!Global g_screen_h:Int
'!Global g_stable_volume:Float
'!Global g_chan_race:TChannel
Select g_stable_state
	Case 3
		If g_stable_int01 And g_matchtime > g_stable_int01 + 2500
			g_stable_state = 2
			g_matchtime :- (g_matchtime - g_stable_int01)
		EndIf
		Return 0
	Case 2
	Default
		Return 0
End Select
g_stable_startxprev = g_stable_startx
Local target:Int = Int(-THorse.GetLeadingHorse().x - 256.0 + g_screenwidth / 1.2)
If g_stable_startx < target
	g_stable_startx = target
EndIf
If g_stable_startx > -11520.0 + g_screenwidth / 1.5
	If g_stable_startx > target
		g_stable_startx = g_stable_startx - (g_stable_startx - target) * 0.25
	EndIf
EndIf
THorse.UpdateAllRunners()
g_stable_int26 = 7
g_runners.Sort()
Local rank:Int = 1
Local allDone:Int = 1
For Local h:THorse = EachIn g_runners
	If Not g_stable_obj845 And h.raceposition = 1
		g_stable_obj845 = GreyscaleImage(GrabPixmap(Int(g_screen_float01), Int(g_screen_float02), 800, 600))
		PlaySound(g_stable_sndFlash, g_chan_bet)
		g_stable_state = 3
		g_stable_int01 = g_matchtime
		If h.racenum = g_stable_racenum
			Local w:Int = g_stable_stake * h.betprice
			TScreenMessage.Create(g_screen_w / 2, g_screen_h / 2, GetText("bet_YouWon") + " " + FormatMoney(w, 1), g_msg_int01, g_font_msg, Null, 1.0, "FFFFFF")
		ElseIf g_stable_racenum > 0
			TScreenMessage.Create(g_screen_w / 2, g_screen_h / 2, GetText("bet_YouLost") + " " + FormatMoney(g_stable_stake, 1), g_msg_int01, g_font_msg, Null, 1.0, "FFFFFF")
		EndIf
	EndIf
	If h.x > 11552.0
		If h.raceposition = 0
			h.raceposition = rank
		EndIf
	Else
		allDone = 0
	EndIf
	rank :+ 1
Next
If allDone And g_stable_volume > 0.0
	g_stable_volume = g_stable_volume - 0.01
EndIf
g_chan_race.SetVolume(g_stable_volume)
If allDone
	FinishRace()
EndIf
