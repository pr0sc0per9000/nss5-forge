' TScreen_MatchPrep.SetUpScreen
' VA 0x0055D904   5081 bytes   mode=reloc   byte-identical vs NSS5.exe (5081/5081)
' KIND=Function, SIG ()i, slot 0x34   (static -- no implicit Self)
' Verified with NSS5_NO_LEARN=1: reloc_masked=409, no learned helpers.
'
' ASSUMPTIONS
'   0x00C6F028 = g_profile:TProfile (globals_final.tsv, construction-site typed; the same
'     Global TScreen_MyContract.SetUpScreen already uses).
'   0x00C68624 = g_matchprep_energy:Float and 0x00C68428 = g_matchprep_energycost:Int
'     (both accessed with fld/fild and no refcount traffic).
'   TLabel: 0x00C685BC lblmoney, 0x00C685C0 lblstatus, 0x00C685C4 lblreason.
'   TButton: 0x00C685C8 btnplay, 0x00C6860C btndrugs, 0x00C68610 btnbooze,
'     0x00C68614 btnshinpads, 0x00C68618 btnboots, 0x00C6861C btnpainkillers,
'     0x00C68620 btnnrg.
'   TProgressBar: 0x00C68628 barenergy, 0x00C685D0 barpace, 0x00C685D4 bardribbling,
'     0x00C685D8 bartackling, 0x00C685DC barpassing, 0x00C685E0 barshooting,
'     0x00C685E4 barheading, 0x00C685E8 barflair, 0x00C685F4 barinjury,
'     0x00C685F8 bardrugs, 0x00C685FC barbooze, 0x00C68600 barshinpads,
'     0x00C68604 barboots, 0x00C68608 barnrg.
'   TImage: 0x00C685A8 imgwatch, 0x00C6F274 g_img_play, 0x00C6857C icondrugs,
'     0x00C68580 iconbooze, 0x00C68584 iconshinpads, 0x00C68588 iconboots.
'     (All the above are construction-site typed in globals_final.tsv; each declared type
'      is load-bearing because it selects the vtable slot for every call through it.)
'   Slots used, all from vtable_map.tsv: TGadget+0x64 SetText($,$,i,i),
'     +0x6C SetColour($,$), +0x70 SetAlph(f); TButton+0x90 SetIcon(:TImage);
'     TProgressBar+0x8C SetPercent(f,i), +0x94 SetBoostIcon(:TImage,i);
'     TProfile+0x58 GetNextFixture(i):TFixture, +0x68 UpdateSelectedForMatch(f),
'     +0x88 GetStat(i,i,i,i)f; TScreen+0x5C SetActive($,$), TScreen+0xB4 Tutorial().
'   TGadget field +0x38 is `alive`; TFixture field +0x3C is `level`.
'   TProfile.helppages is Int[] and the decompilation's [helppages+0x38] is BBArray data
'     (+0x18) + 8*4, i.e. helppages[8].
'   0x004C5549 GetText, 0x0050720B FormatMoney, 0x00505F90 ClampFloat (Var, hence Varptr
'     at the call site) and 0x00507DDD BootBoost are recovered module Functions.
'   Both 20.0 constants really are two separate literal slots (0x00C8C8D4 / 0x00C8C8D8),
'     and both GetStat thresholds are 2.0 (0x00C8C9F4 / 0x00C8C9F8) -- reproduced as
'     written rather than folded.
'   Every string literal was read out of NSS5.exe with harness.read_string.
'!Global g_profile:TProfile
'!Global g_matchprep_energy:Float
'!Global g_matchprep_energycost:Int
'!Global g_matchprep_lblmoney:TLabel
'!Global g_matchprep_lblstatus:TLabel
'!Global g_matchprep_lblreason:TLabel
'!Global g_matchprep_btnplay:TButton
'!Global g_matchprep_imgwatch:TImage
'!Global g_img_play:TImage
'!Global g_matchprep_barenergy:TProgressBar
'!Global g_matchprep_barpace:TProgressBar
'!Global g_matchprep_bardribbling:TProgressBar
'!Global g_matchprep_bartackling:TProgressBar
'!Global g_matchprep_barpassing:TProgressBar
'!Global g_matchprep_barshooting:TProgressBar
'!Global g_matchprep_barheading:TProgressBar
'!Global g_matchprep_barflair:TProgressBar
'!Global g_matchprep_barinjury:TProgressBar
'!Global g_matchprep_bardrugs:TProgressBar
'!Global g_matchprep_barbooze:TProgressBar
'!Global g_matchprep_barshinpads:TProgressBar
'!Global g_matchprep_barboots:TProgressBar
'!Global g_matchprep_barnrg:TProgressBar
'!Global g_matchprep_btndrugs:TButton
'!Global g_matchprep_btnbooze:TButton
'!Global g_matchprep_btnshinpads:TButton
'!Global g_matchprep_btnboots:TButton
'!Global g_matchprep_btnpainkillers:TButton
'!Global g_matchprep_btnnrg:TButton
'!Global g_matchprep_icondrugs:TImage
'!Global g_matchprep_iconbooze:TImage
'!Global g_matchprep_iconshinpads:TImage
'!Global g_matchprep_iconboots:TImage
	Function SetUpScreen()
		TScreen.SetActive("matchprep", "")
		g_matchprep_lblmoney.SetText(FormatMoney(g_profile.bank, 0), "", -1, -1)
		g_matchprep_energy = g_profile.energy - g_matchprep_energycost
		If g_profile.NRG > 0
			g_matchprep_energy = g_matchprep_energy + 20.0
		End If
		If g_profile.NRG > 50
			g_matchprep_energy = g_matchprep_energy + 20.0
		End If
		ClampFloat(Varptr g_matchprep_energy, 0, 100)
		g_matchprep_barenergy.SetPercent(g_matchprep_energy, 1)
		g_matchprep_barenergy.SetText(GetText("Energy") + ": " + Int(g_matchprep_energy) + "%", "", -1, -1)
		g_profile.UpdateSelectedForMatch(g_matchprep_energy)
		g_matchprep_btnplay.SetText(GetText("match_Watch"), "", -1, -1)
		g_matchprep_btnplay.SetIcon(g_matchprep_imgwatch)
		Select g_profile.selectedformatch
			Case -2
				g_matchprep_lblstatus.SetText(GetText("Not Picked"), "", -1, -1)
				g_matchprep_lblreason.SetText(GetText("Low Club Level"), "", -1, -1)
				g_matchprep_lblstatus.SetColour("FF0000", "FFFFFF")
				g_matchprep_lblreason.SetColour("FF0000", "FFFFFF")
			Case -3
				g_matchprep_lblstatus.SetText(GetText("Not Picked"), "", -1, -1)
				g_matchprep_lblreason.SetText(GetText("No Experience"), "", -1, -1)
				g_matchprep_lblstatus.SetColour("FF0000", "FFFFFF")
				g_matchprep_lblreason.SetColour("FF0000", "FFFFFF")
			Case -4
				g_matchprep_lblstatus.SetText(GetText("Not Picked"), "", -1, -1)
				g_matchprep_lblreason.SetText(GetText("Boss Unhappy"), "", -1, -1)
				g_matchprep_lblstatus.SetColour("FF0000", "FFFFFF")
				g_matchprep_lblreason.SetColour("FF0000", "FFFFFF")
			Case -1
				g_matchprep_lblstatus.SetText(GetText("Not Picked"), "", -1, -1)
				g_matchprep_lblreason.SetText(GetText("Poor Form"), "", -1, -1)
				g_matchprep_lblstatus.SetColour("FF0000", "FFFFFF")
				g_matchprep_lblreason.SetColour("FF0000", "FFFFFF")
			Case 1
				g_matchprep_lblstatus.SetText(GetText("1st Team"), "", -1, -1)
				g_matchprep_lblreason.SetText(GetText("Match Fit"), "", -1, -1)
				g_matchprep_lblstatus.SetColour("00FF00", "FFFFFF")
				g_matchprep_lblreason.SetColour("00FF00", "FFFFFF")
				g_matchprep_btnplay.SetText(GetText("Play"), "", -1, -1)
				g_matchprep_btnplay.SetIcon(g_img_play)
			Case 2
				g_matchprep_lblstatus.SetText(GetText("Substitute"), "", -1, -1)
				g_matchprep_lblreason.SetText(GetText("Poor Form"), "", -1, -1)
				Select g_profile.GetNextFixture(0).level
					Case 0
						If g_profile.GetStat(12, 3, 0, 0) < 2.0
							g_matchprep_lblreason.SetText(GetText("No Experience"), "", -1, -1)
						End If
					Case 1
						If g_profile.GetStat(12, 4, 0, 0) < 2.0
							g_matchprep_lblreason.SetText(GetText("No Experience"), "", -1, -1)
						End If
				End Select
				g_matchprep_lblstatus.SetColour("FF9900", "FFFFFF")
				g_matchprep_lblreason.SetColour("FF9900", "FFFFFF")
				g_matchprep_btnplay.SetText(GetText("Play"), "", -1, -1)
				g_matchprep_btnplay.SetIcon(g_img_play)
			Case -5
				g_matchprep_lblstatus.SetText(GetText("Not Picked"), "", -1, -1)
				g_matchprep_lblreason.SetText(GetText("Injured"), "", -1, -1)
				g_matchprep_lblstatus.SetColour("FF0000", "FFFFFF")
				g_matchprep_lblreason.SetColour("FF0000", "FFFFFF")
			Case -6
				g_matchprep_lblstatus.SetText(GetText("Not Picked"), "", -1, -1)
				g_matchprep_lblreason.SetText(GetText("Banned"), "", -1, -1)
				g_matchprep_lblstatus.SetColour("FF0000", "FFFFFF")
				g_matchprep_lblreason.SetColour("FF0000", "FFFFFF")
			Case -7
				g_matchprep_lblstatus.SetText(GetText("Not Picked"), "", -1, -1)
				g_matchprep_lblreason.SetText(GetText("Tiredness"), "", -1, -1)
				g_matchprep_lblstatus.SetColour("FF0000", "FFFFFF")
				g_matchprep_lblreason.SetColour("FF0000", "FFFFFF")
			Case 3
				g_matchprep_lblstatus.SetText(GetText("Substitute"), "", -1, -1)
				g_matchprep_lblreason.SetText(GetText("Tiredness"), "", -1, -1)
				g_matchprep_lblstatus.SetColour("FF9900", "FFFFFF")
				g_matchprep_lblreason.SetColour("FF9900", "FFFFFF")
				g_matchprep_btnplay.SetText(GetText("Play"), "", -1, -1)
				g_matchprep_btnplay.SetIcon(g_img_play)
		End Select
		Local bootslot:Int = -1
		For Local i:Int = 1 To 10
			If g_profile.boots[i - 1] > 0
				bootslot = i
				Exit
			End If
		Next
		Local drugsboost:Int = 0
		Local passboost:Int = 0
		Local shootboost:Int = 0
		Local boozeboost:Int = 0
		Local paceboost:Int = 0
		If bootslot > 0
			g_matchprep_barboots.SetPercent(g_profile.boots[bootslot - 1] * 20, 1)
			Local s:String = g_profile.boots[bootslot - 1] + " " + GetText("Matches")
			If g_profile.boots[bootslot - 1] = 1
				s = g_profile.boots[bootslot - 1] + " " + GetText("Match")
			End If
			g_matchprep_barboots.SetText(s, "", -1, -1)
			paceboost = BootBoost(bootslot, 2)
			passboost = BootBoost(bootslot, 4)
			shootboost = BootBoost(bootslot, 6)
		Else
			g_matchprep_barboots.SetText(GetText("No Boots"), "", -1, -1)
			g_matchprep_barboots.SetPercent(0, 1)
		End If
		Local shinboost:Int = (g_profile.shinpads > 0)
		If g_profile.drugs > 0
			drugsboost = 1
		End If
		If g_profile.drugs > 50
			drugsboost = 2
		End If
		If g_profile.booze > 0
			boozeboost = 1
		End If
		If g_profile.booze > 50
			boozeboost = 2
		End If
		g_matchprep_btnboots.SetText(GetText("Buy"), "", -1, -1)
		If g_profile.sponsor_expires[0] > 0
			g_matchprep_btnboots.SetText(GetText("price_Free"), "", -1, -1)
		End If
		g_matchprep_btnshinpads.SetAlph(1.0)
		g_matchprep_btnshinpads.alive = 1
		g_matchprep_btnshinpads.SetText(FormatMoney(500, 0), "", -1, -1)
		If g_profile.shinpads > 0
			g_matchprep_barshinpads.SetPercent(g_profile.shinpads * 20, 1)
			Local s2:String = g_profile.shinpads + " " + GetText("Matches")
			If g_profile.shinpads = 1
				s2 = g_profile.shinpads + " " + GetText("Match")
			End If
			g_matchprep_barshinpads.SetText(s2, "", -1, -1)
			If g_profile.shinpads = 5
				g_matchprep_btnshinpads.SetAlph(0.5)
				g_matchprep_btnshinpads.alive = 0
			End If
		Else
			g_matchprep_barshinpads.SetText(GetText("No Shin Pads"), "", -1, -1)
			g_matchprep_barshinpads.SetPercent(0, 1)
		End If
		If g_profile.sponsor_expires[2] > 0
			g_matchprep_btnshinpads.SetText(GetText("price_Free"), "", -1, -1)
		End If
		g_matchprep_barpace.SetPercent(g_profile.pace + drugsboost * 10, 1)
		g_matchprep_bardribbling.SetPercent(g_profile.dribbling + paceboost * 10, 1)
		g_matchprep_bartackling.SetPercent(g_profile.tackling + shinboost * 10, 1)
		g_matchprep_barpassing.SetPercent(g_profile.passing + passboost * 10, 1)
		g_matchprep_barheading.SetPercent(g_profile.heading, 1)
		g_matchprep_barshooting.SetPercent(g_profile.shooting + shootboost * 10, 1)
		g_matchprep_barflair.SetPercent(g_profile.flair + boozeboost * 10, 1)
		g_matchprep_barpace.SetBoostIcon(Null, 0)
		g_matchprep_bardribbling.SetBoostIcon(Null, 0)
		g_matchprep_bartackling.SetBoostIcon(Null, 0)
		g_matchprep_barpassing.SetBoostIcon(Null, 0)
		g_matchprep_barheading.SetBoostIcon(Null, 0)
		g_matchprep_barshooting.SetBoostIcon(Null, 0)
		g_matchprep_barflair.SetBoostIcon(Null, 0)
		If bootslot > 0
			If paceboost > 0
				g_matchprep_bardribbling.SetBoostIcon(g_matchprep_iconboots, paceboost)
			End If
			If passboost > 0
				g_matchprep_barpassing.SetBoostIcon(g_matchprep_iconboots, passboost)
			End If
			If shootboost > 0
				g_matchprep_barshooting.SetBoostIcon(g_matchprep_iconboots, shootboost)
			End If
		End If
		If shinboost > 0
			g_matchprep_bartackling.SetBoostIcon(g_matchprep_iconshinpads, shinboost)
		End If
		If drugsboost > 0
			g_matchprep_barpace.SetBoostIcon(g_matchprep_icondrugs, drugsboost)
		End If
		If boozeboost > 0
			g_matchprep_barflair.SetBoostIcon(g_matchprep_iconbooze, boozeboost)
		End If
		g_matchprep_bardrugs.SetPercent(g_profile.drugs, 1)
		g_matchprep_barnrg.SetPercent(g_profile.NRG, 1)
		g_matchprep_barbooze.SetPercent(g_profile.booze, 1)
		g_matchprep_barinjury.SetPercent(g_profile.injury * 10, 1)
		If g_profile.injury = 0
			g_matchprep_btnpainkillers.SetText(FormatMoney(0, 0), "", -1, -1)
			g_matchprep_barinjury.SetText(GetText("No Injury"), "", -1, -1)
		Else
			g_matchprep_btnpainkillers.SetText(FormatMoney(g_profile.injury * 5000, 0), "", -1, -1)
			Local s3:String = g_profile.injury + " " + GetText("Matches")
			If g_profile.injury = 1
				s3 = g_profile.injury + " " + GetText("Match")
			End If
			g_matchprep_barinjury.SetText(s3, "", -1, -1)
		End If
		g_matchprep_btndrugs.SetAlph(1.0)
		g_matchprep_btndrugs.alive = 1
		If g_profile.drugs >= 100 Or g_profile.selectedformatch < 0 Or g_profile.pace > 99 Or (g_profile.pace > 89 And g_profile.drugs > 0)
			g_matchprep_btndrugs.SetAlph(0.5)
			g_matchprep_btndrugs.alive = 0
		End If
		g_matchprep_btnnrg.SetAlph(1.0)
		g_matchprep_btnnrg.alive = 1
		g_matchprep_btnnrg.SetText(FormatMoney(250, 0), "", -1, -1)
		If g_profile.NRG >= 100 Or g_matchprep_energy >= 100.0
			g_matchprep_btnnrg.SetAlph(0.5)
			g_matchprep_btnnrg.alive = 0
		End If
		If g_profile.sponsor_expires[1] > 0
			g_matchprep_btnnrg.SetText(GetText("price_Free"), "", -1, -1)
		End If
		g_matchprep_btnbooze.SetAlph(1.0)
		g_matchprep_btnbooze.alive = 1
		If g_profile.booze >= 100 Or g_profile.selectedformatch < 0
			g_matchprep_btnbooze.SetAlph(0.5)
			g_matchprep_btnbooze.alive = 0
		End If
		g_matchprep_btnpainkillers.SetAlph(1.0)
		g_matchprep_btnpainkillers.alive = 1
		If g_profile.injury = 0
			g_matchprep_btnpainkillers.SetAlph(0.5)
			g_matchprep_btnpainkillers.alive = 0
		End If
		If g_profile.helppages[8] = 0
			TScreen.Tutorial()
			g_profile.helppages[8] = 1
		End If
	End Function
