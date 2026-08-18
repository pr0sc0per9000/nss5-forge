' TEngine.DrawScores
' VA 0x004D268B   601 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function (static method on the Type, no implicit Self), SIG=()i, class-table slot 0x68
' ORACLE 601/601 reloc_masked=59, first attempt.
'
' ASSUMPTIONS / RESOLUTIONS
'   Globals (names are OURS; the TYPES are load-bearing):
'     0x00C5B32C -> g_engine_labels:TLabel[]   (elements dispatched through slot 0x64
'                   SetText($,$,i,i) and 0x44 Draw(), both TGadget's, inherited by TLabel;
'                   data at +0x18, so +0x18/+0x1C/+0x20/+0x24 are indices 0..3)
'     0x00C5B22C -> g_engine_fixture:TFixture  (+0x18 leg, +0x2C score1, +0x30 score2 --
'                   globals_final guesses TPlayer; TEngine.GetWinningClub already records
'                   the correction to TFixture and the field offsets confirm it)
'     0x00C5B230 -> g_engine_agg2:Int   0x00C5B234 -> g_engine_agg1:Int  (first-leg scores)
'     0x00C5B334 -> g_lbl_agg:TLabel    (+0x3C hidden, +0x4C fntSize -- TGadget fields)
'     0x00C5B330 -> g_lbl_time:TLabel
'     0x00C5B210 -> g_engine_clock:Int
'   Calls: 0x004A7AC0 = _bbStringFromInt, 0x004A7C20 = _bbStringConcat,
'          0x004C5549 = GetText (module Function, ONE argument).
'   String literals read out of NSS5.exe: 0x00C5D284 "", 0x00C6EF28 " ", 0x00C70DD0 " - ",
'          0x00C70E68 "tla_Aggregate", 0x00C70F18 ") ", 0x00C70F28 "(".
'
' CODEGEN NOTES
'   SetText's three trailing arguments are pushed explicitly ("", -1, -1); Ghidra folds
'   them into the preceding _bbStringFromInt call, which is the arg-merging trap.
'   bcc evaluates a `+` chain RIGHT to LEFT: for
'     GetText(..) + " " + String(a) + " - " + String(b)
'   the calls come out String(b), String(a), GetText(..), then four _bbStringConcat.
	Function DrawScores:Int()
		'!Global g_engine_labels:TLabel[]
		'!Global g_engine_fixture:TFixture
		'!Global g_engine_agg2:Int
		'!Global g_engine_agg1:Int
		'!Global g_lbl_agg:TLabel
		'!Global g_lbl_time:TLabel
		'!Global g_engine_clock:Int
		g_engine_labels[0].SetText(String(g_engine_fixture.score1), "", -1, -1)
		g_engine_labels[2].SetText(String(g_engine_fixture.score2), "", -1, -1)
		If g_lbl_agg.hidden = 0
			If g_engine_fixture.leg = 2
				g_lbl_agg.fntSize = 2
				g_lbl_agg.SetText(GetText("tla_Aggregate") + " " + String(g_engine_agg1 + g_engine_fixture.score1) + " - " + String(g_engine_agg2 + g_engine_fixture.score2), "", -1, -1)
				g_engine_labels[0].SetText("(" + String(g_engine_agg1) + ") " + String(g_engine_fixture.score1), "", -1, -1)
				g_engine_labels[2].SetText("(" + String(g_engine_agg2) + ") " + String(g_engine_fixture.score2), "", -1, -1)
			EndIf
			g_lbl_agg.Draw()
		EndIf
		g_engine_labels[0].Draw()
		g_engine_labels[1].Draw()
		g_engine_labels[2].Draw()
		g_engine_labels[3].Draw()
		g_lbl_time.SetText(String(g_engine_clock), "", -1, -1)
		g_lbl_time.Draw()
	End Function
