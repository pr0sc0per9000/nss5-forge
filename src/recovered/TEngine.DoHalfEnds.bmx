' TEngine.DoHalfEnds
' VA 0x004D4334   731 bytes  mode=reloc  byte-identical vs NSS5.exe (731/731)
' KIND=Function, SIG ()i, slot 0x8C
' ASSUMPTIONS
'   0x00C5B208 / 0x00C5B210 / 0x00C5B254 / 0x00C5B1FC / 0x00C6EFD4 / 0x00C5B1F8 are Ints
'     (bare dword stores, no refcount traffic).
' g_engine_int17 (0x00C5B1F8) original data-section value is 1750, read directly
' from NSS5.exe. See codegen-patterns 21.1/21.3.
'   0x00C6F028 g_profile:TProfile -- slot 0x100 = TProfile.UpdateEnergy(f)i.
'   0x00C5B22C g_fixture:TFixture (already established elsewhere in this tree); +0x2C is
'     TFixture.score1.
'   0x00C5B1C8 :TBitmapFont, and the sound/channel Globals are typed by PlaySound's and
'     TScreenMessage.Create's signatures.
'   NOT A TIDY-UP: the original really does compare g_fixture.score1 against itself in both
'     MatchOver branches (mov edx,[g] / mov eax,[g] / mov eax,[eax+0x2C] / cmp [edx+0x2C],eax).
'     Presumably meant to be score2; reproduced verbatim because the bytes require it.
'   `add dword [0x00C5B208],1` is `:+ 1` on a memory operand -- Ghidra prints it as
'     `= 3` / `= 5` in cases 2 and 4, which is wrong.
' CASE DIRECTION CORRECTED 2026-08-22: 4 call sites -> .ToUpper().
' extracted/runtime_helpers.tsv named 0x004A7410 `_brl_retro_Lower` and 0x004A74E0
' `_brl_retro_Upper`. Both were wrong and neither address is a brl.retro wrapper:
' 0x004A7410 is `_bbStringToUpper` and 0x004A74E0 is `_bbStringToLower`. NSS5.exe's
' own 21-byte retro wrappers at 0x0059C8FD (Lower) and 0x0059C912 (Upper) CALL those
' two addresses, and a wrapper cannot be the function it calls. The wrong row masked
' by name, so this body certified with the case conversion running backwards. Full
' derivation and the discriminating 3x4 matrix: docs/reference/codegen-patterns.md
' 15.6. Re-verified under NSS5_NO_LEARN=1 on worker trees 380 and 380b.
	Function DoHalfEnds:Int()
		'!Global g_profile:TProfile
		'!Global g_fixture:TFixture
		'!Global g_matchstate:Int
		'!Global g_engine_int18:Int
		'!Global g_engine_int20:Int
		'!Global g_engine_int27:Int
		'!Global g_engine_int17:Int = 1750
		'!Global g_player_int50:Int
		'!Global g_engine_font:TBitmapFont
		'!Global g_snd_whistle:TSound
		'!Global g_snd_fulltime:TSound
		'!Global g_snd_crowd:TSound
		'!Global g_chan_whistle:TChannel
		'!Global g_chan_crowd:TChannel
		Select g_engine_int18
			Case 1
				g_profile.UpdateEnergy(10.0)
				g_engine_int20 = 45
				g_engine_int18 :+ 1
				g_matchstate = 0
				TScreenMessage.Create(0, 0, GetText("Half Time").ToUpper(), g_engine_int17, g_engine_font, Null, 1.0, "FFFFFF")
				PlaySound(g_snd_whistle, g_chan_whistle)
			Case 2
				g_engine_int20 = 90
				g_engine_int18 :+ 1
				TScreenMessage.Create(0, 0, GetText("Full Time").ToUpper(), g_engine_int17, g_engine_font, Null, 1.0, "FFFFFF")
				PlaySound(g_snd_fulltime, g_chan_whistle)
				If MatchOver()
					g_matchstate = 11
					g_engine_int27 = g_player_int50
					If g_fixture.score1 <> g_fixture.score1
						PlaySound(g_snd_crowd, g_chan_crowd)
					End If
					TPlayer.RecordPlayerStats()
				Else
					g_matchstate = 0
					g_profile.UpdateEnergy(5.0)
				End If
			Case 3
				g_profile.UpdateEnergy(5.0)
				g_engine_int20 = 105
				g_engine_int18 :+ 1
				g_matchstate = 0
				TScreenMessage.Create(0, 0, GetText("Half Time").ToUpper(), g_engine_int17, g_engine_font, Null, 1.0, "FFFFFF")
				PlaySound(g_snd_whistle, g_chan_whistle)
			Case 4
				g_engine_int20 = 120
				g_engine_int18 :+ 1
				TScreenMessage.Create(0, 0, GetText("Full Time").ToUpper(), g_engine_int17, g_engine_font, Null, 1.0, "FFFFFF")
				PlaySound(g_snd_fulltime, g_chan_whistle)
				If MatchOver()
					g_matchstate = 11
					g_engine_int27 = g_player_int50
					If g_fixture.score1 <> g_fixture.score1
						PlaySound(g_snd_crowd, g_chan_crowd)
					End If
					TPlayer.RecordPlayerStats()
				Else
					DoShootOut()
				End If
		End Select
	End Function
