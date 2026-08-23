' TEngine.RenderScoreboard
' VA 0x004d0ab3   7128 bytes   mode=reloc   byte-identical vs NSS5.exe (7128/7128, original length from Ghidra's inventory)
' KIND=Function, SIG ()i, class-table slot 0x64
' ASSUMPTIONS (module Globals -- names ours, declared types load-bearing):
'   0x00C5B1FC g_matchstate:Int      0x00C73DD8 g_sbalpha:Float      0x00C73DDC g_sbfadein:Float
'   0x00C73DE0 g_sbfadeout:Float     0x00C73DE4 g_sbscroll:Int       0x00C5B25C g_posshome:Float
'   0x00C5B260 g_possaway:Float      0x00C6EFE4 g_screen_w:Int       0x00C6EFE8 g_screen_h:Int
'   0x00C6EFEC g_joyactive:Int       0x00C5B2D4 g_homebadge:TImage   0x00C5B2D8 g_awaybadge:TImage
'   0x00C6F34C g_sbbar1:TImage       0x00C6F3B0 g_sbbar2:TImage      0x00C5B218 g_hometeam:TTeam
'   0x00C5B21C g_awayteam:TTeam      0x00C5B22C g_fixture:TFixture   0x00C5B258 g_sbpage:Int
'   0x00C5B264/68 shots h/a          0x00C5B26C/70 on-target h/a     0x00C5B274/78 free kicks h/a
'   0x00C5B27C/80 corners h/a        0x00C5B284/88 penalties h/a     0x00C5B28C/90 offside h/a
'   0x00C5B294/98 yellows h/a        0x00C5B29C/A0 reds h/a          0x00C5D254 g_units:Int
'   0x00C73EF4 g_possbarh:Float      0x00C73EF8 g_possbara:Float     0x00C73F38 g_sbfontscale:Float
'   0x00C5B238 g_kickcount:Int       0x00C5B240 g_kickresults:Int[]  0x00C5D1CC g_ctrlright:Int[]
'   0x00C5D1C4 g_ctrlleft:Int[]      0x00C7407C g_joyposthresh:Float 0x00C74080 g_joynegthresh:Float
' ASSUMPTION 0x00C5B218/0x00C5B21C are TTeam (globals_final flags TKit/TTeam construction conflict);
'   TTeam.name is at +0xc, which is what the two scoreboard captions read.
' ASSUMPTION 0x00C5B22C is TFixture, not the TPlayer globals_final guesses: +0x2c/+0x30 are
'   score1/score2 read as Ints through bbStringFromInt (TPlayer+0x2c is a String).
' ASSUMPTION 0x00C5B240 is Int[] (elements compared against the literal 1), not Object[].
' NOTE 0x004A7410 is named _brl_retro_Lower in runtime_helpers.tsv, so the source form is
'   Lower(GetText(...)) -- a String method .ToLower() emits a DIFFERENT helper and does not match.
' All string literals recovered with harness.read_string from NSS5.exe.

' CASE DIRECTION CORRECTED 2026-08-22: 21 call sites -> .ToUpper().
' extracted/runtime_helpers.tsv named 0x004A7410 `_brl_retro_Lower` and 0x004A74E0
' `_brl_retro_Upper`. Both were wrong and neither address is a brl.retro wrapper:
' 0x004A7410 is `_bbStringToUpper` and 0x004A74E0 is `_bbStringToLower`. NSS5.exe's
' own 21-byte retro wrappers at 0x0059C8FD (Lower) and 0x0059C912 (Upper) CALL those
' two addresses, and a wrapper cannot be the function it calls. The wrong row masked
' by name, so this body certified with the case conversion running backwards. Full
' derivation and the discriminating 3x4 matrix: docs/reference/codegen-patterns.md
' 15.6. Re-verified under NSS5_NO_LEARN=1 on worker trees 380 and 380b.
	Function RenderScoreboard()
		'!Global g_matchstate:Int
		'!Global g_sbalpha:Float
		' g_sbfadein/g_sbfadeout original data-section values are both 0.025
		' (0x00C73DDC / 0x00C73DE0). Never stored to anywhere in the corpus -- see
		' codegen-patterns 21.1.
		'!Global g_sbfadein:Float = 0.025
		'!Global g_sbfadeout:Float = 0.025
		'!Global g_sbscroll:Int
		'!Global g_posshome:Float
		'!Global g_possaway:Float
		'!Global g_screen_w:Int
		'!Global g_screen_h:Int
		'!Global g_joyactive:Int
		'!Global g_homebadge:TImage
		'!Global g_awaybadge:TImage
		'!Global g_object872:TImage
		'!Global g_object873:TImage
		'!Global g_hometeam:TTeam
		'!Global g_awayteam:TTeam
		'!Global g_fixture:TFixture
		'!Global g_sbpage:Int
		'!Global g_stat_shots_h:Int
		'!Global g_stat_shots_a:Int
		'!Global g_stat_ontarget_h:Int
		'!Global g_stat_ontarget_a:Int
		'!Global g_stat_freekicks_h:Int
		'!Global g_stat_freekicks_a:Int
		'!Global g_stat_corners_h:Int
		'!Global g_stat_corners_a:Int
		'!Global g_stat_pens_h:Int
		'!Global g_stat_pens_a:Int
		'!Global g_stat_offside_h:Int
		'!Global g_stat_offside_a:Int
		'!Global g_stat_yellows_h:Int
		'!Global g_stat_yellows_a:Int
		'!Global g_stat_reds_h:Int
		'!Global g_stat_reds_a:Int
		'!Global g_units:Int
		' g_possbarh/g_possbara/g_sbfontscale original data-section values are
		' 100.0 / 100.0 / 0.8 (0x00C73EF4 / 0x00C73EF8 / 0x00C73F38). Never stored to
		' anywhere in the corpus -- see codegen-patterns 21.1.
		'!Global g_possbarh:Float = 100.0
		'!Global g_possbara:Float = 100.0
		'!Global g_sbfontscale:Float = 0.8
		'!Global g_kickcount:Int
		'!Global g_kickresults:Int[]
		'!Global g_ctrlright:Int[]
		'!Global g_ctrlleft:Int[]
		' g_joyposthresh/g_joynegthresh original data-section values are
		' 0.5 / -0.5 (0x00C7407C / 0x00C74080). Never stored to anywhere in the
		' corpus -- see codegen-patterns 21.1.
		'!Global g_joyposthresh:Float = 0.5
		'!Global g_joynegthresh:Float = -0.5

		Local fs:Float
		Local h:Int
		Local xmid:Int
		Local xleft:Int
		Local xright:Int
		Local p:TPlayer
		Local yy:Int
		Local ph:Int
		Local pa:Int

		SetColor(255,255,255)
		SetAlpha(1.0)

		If (g_matchstate = 0 Or g_matchstate = 8 Or g_matchstate = 2 Or g_matchstate = 11) And g_sbalpha < 1.0
			g_sbalpha :+ g_sbfadein
		ElseIf g_sbalpha > 0
			g_sbalpha :- g_sbfadeout
		EndIf

		If (g_matchstate = 0 Or g_matchstate = 11) And TScreenMessage.Count() = 0

			If g_posshome + g_possaway <> 0

				xmid = g_screen_w / 2 - g_sbscroll
				xleft = xmid - 200
				xright = xmid + 200
				yy = g_screen_h / 2 - 220
				h = 36

				DrawImageRect(g_object872, 0, yy - 30, g_screen_w, 500, 0)
				DrawImageRect(g_object873, 0, yy - 32, g_screen_w, 4, 0)
				DrawImageRect(g_object873, 0, yy + 468, g_screen_w, 4, 0)

				If g_homebadge <> Null And g_awaybadge <> Null
					DrawImage(g_homebadge, xleft, yy - 58, 0)
					DrawImage(g_awaybadge, xright, yy - 58, 0)
				EndIf

				DrawMyText(g_hometeam.name, xleft, yy, 1, 1, 1.0, g_sbalpha, "FFFFFF", 0)
				DrawMyText(g_awayteam.name, xright, yy, 1, 1, 1.0, g_sbalpha, "FFFFFF", 0)

				yy :+ h * 2
				DrawMyText(String(g_fixture.score1), xleft, yy, 1, 1, 1.0, g_sbalpha, "FFFFFF", 1)
				DrawMyText(String(g_fixture.score2), xright, yy, 1, 1, 1.0, g_sbalpha, "FFFFFF", 1)

				yy :+ h * 2
				DrawMyText(String(g_stat_shots_h), xleft, yy, 1, 1, 1.0, g_sbalpha, "00FF00", 0)
				DrawMyText(String(g_stat_shots_a), xright, yy, 1, 1, 1.0, g_sbalpha, "00FF00", 0)
				DrawMyText(GetText("Shots").ToUpper(), xmid, yy, 1, 1, 1.0, g_sbalpha, "00FF00", 0)

				yy :+ h
				DrawMyText(String(g_stat_ontarget_h), xleft, yy, 1, 1, 1.0, g_sbalpha, "99FF99", 0)
				DrawMyText(String(g_stat_ontarget_a), xright, yy, 1, 1, 1.0, g_sbalpha, "99FF99", 0)
				DrawMyText(GetText("On Target").ToUpper(), xmid, yy, 1, 1, 1.0, g_sbalpha, "99FF99", 0)

				yy :+ h
				DrawMyText(String(g_stat_corners_h), xleft, yy, 1, 1, 1.0, g_sbalpha, "FFFFFF", 0)
				DrawMyText(String(g_stat_corners_a), xright, yy, 1, 1, 1.0, g_sbalpha, "FFFFFF", 0)
				DrawMyText(GetText("Corners").ToUpper(), xmid, yy, 1, 1, 1.0, g_sbalpha, "FFFFFF", 0)

				yy :+ h
				DrawMyText(String(g_stat_offside_h), xleft, yy, 1, 1, 1.0, g_sbalpha, "FFFFFF", 0)
				DrawMyText(String(g_stat_offside_a), xright, yy, 1, 1, 1.0, g_sbalpha, "FFFFFF", 0)
				DrawMyText(GetText("Offside").ToUpper(), xmid, yy, 1, 1, 1.0, g_sbalpha, "FFFFFF", 0)

				yy :+ h
				DrawMyText(String(g_stat_pens_h), xleft, yy, 1, 1, 1.0, g_sbalpha, "FFFFFF", 0)
				DrawMyText(String(g_stat_pens_a), xright, yy, 1, 1, 1.0, g_sbalpha, "FFFFFF", 0)
				DrawMyText(GetText("Penalties").ToUpper(), xmid, yy, 1, 1, 1.0, g_sbalpha, "FFFFFF", 0)

				yy :+ h
				DrawMyText(String(g_stat_freekicks_h), xleft, yy, 1, 1, 1.0, g_sbalpha, "FFFFFF", 0)
				DrawMyText(String(g_stat_freekicks_a), xright, yy, 1, 1, 1.0, g_sbalpha, "FFFFFF", 0)
				DrawMyText(GetText("Free Kicks").ToUpper(), xmid, yy, 1, 1, 1.0, g_sbalpha, "FFFFFF", 0)

				yy :+ h
				DrawMyText(String(g_stat_yellows_h), xleft, yy, 1, 1, 1.0, g_sbalpha, "FFFF00", 0)
				DrawMyText(String(g_stat_yellows_a), xright, yy, 1, 1, 1.0, g_sbalpha, "FFFF00", 0)
				DrawMyText(GetText("Yellow Cards").ToUpper(), xmid, yy, 1, 1, 1.0, g_sbalpha, "FFFF00", 0)

				yy :+ h
				DrawMyText(String(g_stat_reds_h), xleft, yy, 1, 1, 1.0, g_sbalpha, "FF0000", 0)
				DrawMyText(String(g_stat_reds_a), xright, yy, 1, 1, 1.0, g_sbalpha, "FF0000", 0)
				DrawMyText(GetText("Red Cards").ToUpper(), xmid, yy, 1, 1, 1.0, g_sbalpha, "FF0000", 0)

				yy :+ h + 6
				ph = Int(g_possbarh / (g_posshome + g_possaway) * g_posshome)
				pa = Int(g_possbara / (g_posshome + g_possaway) * g_possaway)
				If ph + pa < 100 Then ph = 100 - pa
				DrawMyText(String(ph), xleft, yy, 1, 1, 1.0, g_sbalpha, "FFFFFF", 0)
				DrawMyText(String(pa), xright, yy, 1, 1, 1.0, g_sbalpha, "FFFFFF", 0)
				DrawMyText(GetText("Possession").ToUpper(), xmid, yy, 1, 1, 1.0, g_sbalpha, "FFFFFF", 0)

				yy = g_screen_h / 2 - 210
				yy :+ h
				xmid :+ g_screen_w - 10

				p = TPlayer.GetHumanPlayer()
				If p <> Null

					DrawMyText(GetText("My Stats"), xmid + 40, yy, 2, 1, 1.0, g_sbalpha, "FFFFFF", 1)
					yy :+ h * 2
					fs = g_sbfontscale
					h = Int(h * fs)

					DrawMyText(GetText("Goals").ToUpper(), xmid - 40, yy, 2, 1, fs, g_sbalpha, "00FF00", 0)
					DrawMyText(String(p.matchstats.CountStat(5)), xmid, yy, 1, 1, fs, g_sbalpha, "00FF00", 0)
					yy :+ h + 5

					DrawMyText(GetText("Shots").ToUpper(), xmid - 40, yy, 2, 1, fs, g_sbalpha, "99FF99", 0)
					DrawMyText(String(p.matchstats.CountStat(2)), xmid, yy, 1, 1, fs, g_sbalpha, "99FF99", 0)
					yy :+ h + 5

					DrawMyText(GetText("Passes").ToUpper(), xmid - 40, yy, 2, 1, fs, g_sbalpha, "0000FF", 0)
					DrawMyText(String(p.matchstats.CountStat(3)), xmid, yy, 1, 1, fs, g_sbalpha, "0000FF", 0)
					yy :+ h + 5

					DrawMyText(GetText("Assists").ToUpper(), xmid - 40, yy, 2, 1, fs, g_sbalpha, "990099", 0)
					DrawMyText(String(p.matchstats.CountStat(4)), xmid, yy, 1, 1, fs, g_sbalpha, "990099", 0)
					yy :+ h + 5

					DrawMyText(GetText("Headers").ToUpper(), xmid - 40, yy, 2, 1, fs, g_sbalpha, "9999FF", 0)
					DrawMyText(String(p.matchstats.CountStat(6)), xmid, yy, 1, 1, fs, g_sbalpha, "9999FF", 0)
					yy :+ h + 5

					DrawMyText(GetText("Tackles").ToUpper(), xmid - 40, yy, 2, 1, fs, g_sbalpha, "FF0099", 0)
					Local tk:Int = p.matchstats.CountStat(8) + p.matchstats.CountStat(7)
					DrawMyText(String(tk), xmid, yy, 1, 1, fs, g_sbalpha, "FF0099", 0)
					yy :+ h + 5

					DrawMyText(GetText("Fouls").ToUpper(), xmid - 40, yy, 2, 1, fs, g_sbalpha, "FF9900", 0)
					DrawMyText(String(p.matchstats.CountStat(11)), xmid, yy, 1, 1, fs, g_sbalpha, "FF9900", 0)
					yy :+ h + 5

					DrawMyText(GetText("Yellow Cards").ToUpper(), xmid - 40, yy, 2, 1, fs, g_sbalpha, "FFFF00", 0)
					DrawMyText(String(p.matchstats.yellows), xmid, yy, 1, 1, fs, g_sbalpha, "FFFF00", 0)
					yy :+ h + 5

					DrawMyText(GetText("Red Cards").ToUpper(), xmid - 40, yy, 2, 1, fs, g_sbalpha, "FF0000", 0)
					DrawMyText(String(p.matchstats.reds), xmid, yy, 1, 1, fs, g_sbalpha, "FF0000", 0)
					yy :+ h + 5

					Select g_units
					Case 0
						DrawMyText(GetText("Distance").ToUpper() + " (" + GetText("tla_Yards") + ")", xmid - 40, yy, 2, 1, fs, g_sbalpha, "FFFFFF", 0)
						DrawMyText(String(Int(TPitch.PixelsToYards(p.matchstats.distance))), xmid, yy, 1, 1, fs, g_sbalpha, "FFFFFF", 0)
					Case 1
						DrawMyText(GetText("Distance").ToUpper() + " (" + GetText("tla_Metres") + ")", xmid - 40, yy, 2, 1, fs, g_sbalpha, "FFFFFF", 0)
						DrawMyText(String(Int(TPitch.PixelsToMetres(p.matchstats.distance))), xmid, yy, 1, 1, fs, g_sbalpha, "FFFFFF", 0)
					End Select

					p.matchstats.DrawPitch(xmid + 225, g_screen_h / 2)

					If g_sbscroll = 0
						If KeyDown(g_ctrlright[0]) Or (g_joyactive And (JoyDown(g_ctrlright[1], 0) Or JoyX(0) > g_joyposthresh))
							g_sbpage = 1
							p.matchstats.SortListBy(28)
						EndIf
					ElseIf g_sbscroll = g_screen_w
						If KeyDown(g_ctrlleft[0]) Or (g_joyactive And (JoyDown(g_ctrlleft[1], 0) Or JoyX(0) < g_joynegthresh))
							g_sbpage = 0
						EndIf
					EndIf
				Else
					g_sbpage = 0
				EndIf

				Select g_sbpage
				Case 0
					If g_sbscroll > 0
						g_sbscroll :- 50
						If g_sbscroll < 0 Then g_sbscroll = 0
					EndIf
				Case 1
					If g_sbscroll < g_screen_w
						g_sbscroll :+ 50
						If g_sbscroll > g_screen_w Then g_sbscroll = g_screen_w
					EndIf
					If g_sbscroll > g_screen_w
						g_sbscroll :- 50
						If g_sbscroll < g_screen_w Then g_sbscroll = g_screen_w
					EndIf
				Case 2
					If g_sbscroll < g_screen_w * 2
						g_sbscroll :+ 50
						If g_sbscroll > g_screen_w * 2 Then g_sbscroll = g_screen_w * 2
					EndIf
				End Select

			Else

				TPanel_Controls.RenderPauseReplay(g_screen_w - 142, 10)
				DrawImageRect(g_object872, 0, g_screen_h / 2 - 180, g_screen_w, 360, 0)
				DrawImageRect(g_object873, 0, g_screen_h / 2 - 182, g_screen_w, 4, 0)
				DrawImageRect(g_object873, 0, g_screen_h / 2 + 178, g_screen_w, 4, 0)
				DrawMyText(g_hometeam.name, g_screen_w / 2, g_screen_h / 2 - 100, 1, 1, 1.0, g_sbalpha, "FFFFFF", 1)
				DrawMyText(GetText("tla_Versus"), g_screen_w / 2, g_screen_h / 2, 1, 1, 1.0, g_sbalpha, "FFFFFF", 0)
				DrawMyText(g_awayteam.name, g_screen_w / 2, g_screen_h / 2 + 100, 1, 1, 1.0, g_sbalpha, "FFFFFF", 1)

			EndIf

			TPanel_Controls.RenderKickToContinue()

		Else

			g_sbpage = 0
			g_sbscroll = 0
			DrawScores()

			If g_matchstate = 8 Or g_matchstate = 6 Or g_matchstate = 5
				TPanel_Controls.RenderPauseReplay(g_screen_w - 142, 10)
			Else
				Local hp:TPlayer = TPlayer.GetHumanPlayer()
				If Not hp Or hp.selectionno > 10
					TPanel_Controls.RenderPauseSkipTime(g_screen_w - 142, 10)
				EndIf
			EndIf

			If g_kickcount > 0
				DrawMyText(GetText("Penalties").ToUpper(), 10, g_screen_h - 100, 0, 0, 0.5, 1.0, "FFFFFF", 0)
				If g_homebadge <> Null And g_awaybadge <> Null
					SetScale(0.5, 0.5)
					DrawImage(g_homebadge, 30, g_screen_h - 60, 0)
					DrawImage(g_awaybadge, 30, g_screen_h - 30, 0)
					SetScale(1.0, 1.0)
				EndIf
				Local kx:Int = 40
				Local ky:Int = g_screen_h - 60
				For Local i:Int = 1 To g_kickcount - 1
					Select (i Mod 2) + 1
					Case 1
						ky = g_screen_h - 30
					Case 2
						ky = g_screen_h - 60
						kx :+ 26
					End Select
					If g_kickresults[i] = 1
						DrawMyText("1", kx, ky, 1, 1, 0.5, 1.0, "00FF00", 0)
					Else
						DrawMyText("0", kx, ky, 1, 1, 0.5, 1.0, "FF0000", 0)
					EndIf
				Next
			EndIf

		EndIf
	End Function
