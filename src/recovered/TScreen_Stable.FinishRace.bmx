' TScreen_Stable.FinishRace
' VA 0x0058946F   832 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, class-table slot 0x68
' (832/832, original length from Ghidra's inventory; verified under NSS5_NO_LEARN=1)
'
' ASSUMPTIONS -- Global NAMES are ours, the declared TYPES are load-bearing.
'   0x00C6E298 g_runners:TList             (already TList in TScreen_Stable.RefreshRunners)
'   0x00C6DF68 g_stable_stake:Int   0x00C6DF6C g_stable_racenum:Int
'   0x00C6DF70 g_stable_state:Int         (all three bare dword traffic, no refcounting)
'   0x00C6F028 g_contractoffer_tplayer:TProfile -- slots 0xfc UpdateBank, 0x150 CheckAchievement
'   0x00C6F0D4 g_snd_win:TSound   0x00C6F090 g_chan_bet:TChannel  (PlaySound arg1/arg2)
'   0x00C6DF1C g_chan_race:TChannel       (sole argument of PauseChannel)
'   0x00C66768 g_pan_stable:TPanel  0x00C6DEB0 g_stable_panNav:TPanel
'   0x00C6DEE4 g_stable_panRace:TPanel  0x00C6DEE8 g_stable_panStake:TPanel
'     -- all four dispatched at slot 0x58 = TGadget.Show (inherited)
'   0x00C6DEBC g_stable_btnStartRace:TButton  -- 0x90 SetIcon(:TImage), 0x80 CreateToolTip($)
'   0x00C6F1B8 g_img_nextrace:TImage      (globals_final says Object; it is SetIcon's arg)
'   THorse: prize +0x4c, owned +0x50, raceposition +0x5c, racenum +0x60, betprice +0x68;
'     slot 0x64 PostRaceUpdate(i).
'   RefreshRunners (+0x5c) and RefreshTableOwned (+0x78) are sibling Functions of this Type.
' SHAPE NOTES
'   * BOTH raceposition dispatches are Selects with Cases 1/2/3 and no Default (10.2).
'   * `h.prize :+ 50000` -- a memory operand, so `add dword [esi+0x4c],0xc350` (guide 6);
'     `h.prize = h.prize + 50000` would not emit that single instruction.
'   * THE ONE HARD BIT: `UpdateBank(g_stable_stake * h.betprice)` written inline puts the
'     receiver load BEFORE the multiply and is 832 bytes but WRONG-ordered.  The original
'     evaluates the argument first and loads the receiver into edx after, which is what a
'     Local consumed by the very next statement produces -- and it costs ZERO bytes
'     (codegen-patterns 16.2, measured for String and holding for Int too).
'   * both string literals read out of NSS5.exe with harness.read_string.
' Body-only format: statements only, parameters are a0, a1, ...
' 0x00C6E298 is the RACE RUNNERS list, not the master horse list. THorse.SelectRunners
' declares both in one body -- g_horses for 0x00C6E294 (the list it enumerates and
' sorts) and g_runners for 0x00C6E298 (the list it Clears and AddLasts into) -- so the
' two are provably different slots, and the module body creates them separately. Spelled
' g_runners here, this body's slot shared the emitted variable of the master list.
'!Global g_runners:TList
'!Global g_stable_stake:Int
'!Global g_stable_racenum:Int
'!Global g_stable_state:Int
'!Global g_profile:TProfile
'!Global g_snd_win:TSound
'!Global g_chan_bet:TChannel
'!Global g_chan_race:TChannel
'!Global g_pan_stable:TPanel
'!Global g_stable_panNav:TPanel
'!Global g_stable_panRace:TPanel
'!Global g_stable_panStake:TPanel
'!Global g_stable_btnStartRace:TButton
'!Global g_img_nextrace:TImage
For Local h:THorse = EachIn g_runners
	If h.raceposition = 1 And g_stable_racenum = h.racenum
		Local w:Int = g_stable_stake * h.betprice
		g_profile.UpdateBank(w)
		g_profile.CheckAchievement(72)
	EndIf
	Select h.raceposition
		Case 1
			h.prize :+ 50000
		Case 2
			h.prize :+ 25000
		Case 3
			h.prize :+ 10000
	End Select
	If h.owned <> 0
		Select h.raceposition
			Case 1
				PlaySound(g_snd_win, g_chan_bet)
				TScreen.DoMessage(GetText("CMESSAGE_HORSEPRIZE").Replace("$cash", FormatMoney(50000, 1)), 0, 0)
				g_profile.UpdateBank(50000)
				g_profile.CheckAchievement(83)
			Case 2
				PlaySound(g_snd_win, g_chan_bet)
				TScreen.DoMessage(GetText("CMESSAGE_HORSEPRIZE").Replace("$cash", FormatMoney(25000, 1)), 0, 0)
				g_profile.UpdateBank(25000)
			Case 3
				PlaySound(g_snd_win, g_chan_bet)
				TScreen.DoMessage(GetText("CMESSAGE_HORSEPRIZE").Replace("$cash", FormatMoney(10000, 1)), 0, 0)
				g_profile.UpdateBank(10000)
		End Select
	EndIf
Next
RefreshRunners(1)
g_stable_state = 0
g_pan_stable.Show()
g_stable_panRace.Show()
g_stable_panNav.Show()
g_stable_panStake.Show()
g_stable_btnStartRace.SetIcon(g_img_nextrace)
g_stable_btnStartRace.CreateToolTip(GetText("tt_NextRace"))
PauseChannel(g_chan_race)
For Local h:THorse = EachIn g_runners
	h.PostRaceUpdate(h.raceposition)
Next
RefreshTableOwned()
