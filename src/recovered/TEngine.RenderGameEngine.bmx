' TEngine.RenderGameEngine
' VA 0x004CF821   587 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG (f)i, class-table slot 0x50
' ASSUMPTIONS
'   The leading three-way dispatch is a Select with no Default (all three cmp/je back to
'     back at 0x004CF82F, then fstp st(0)/jmp for the no-match path -- codegen-patterns 10.2).
'   0x004A8550 is the BlitzMax builtin GCMemAlloced() -- NOT in runtime_helpers.tsv, so the
'     oracle learned that name inside this run (codegen-patterns 13.1). The identification
'     rests on context ("Mem: " + String(...)) plus the emitted length being exact; treat the
'     callee identity as inferred, the surrounding shape as proved.
'   TScreen.Render / TEngine.Render / TEngine.RenderReplay / TEngine.GetStringMatchState /
'     TPlayer.GetHumanPlayer / TScreenMessage.DrawAll are all KIND=Function (static),
'     resolved from class-table slots 0x68 / 0x5c / 0xb0 / 0xf4 / 0x164 / 0x38.
'   TPlayer.matchstats = +0x188 (:TStats_Match), TStats_Match.rating = +0x28.
'   Literals "Rating: " "FPS: " "Time: " "Mem: " "FFFFFF" read with harness.read_string.
'   The last guard is `g_player_int50 > g_engine_int169 + 1000`; the reversed spelling
'     compiles to the same length but emits 3B/7D instead of 39/7E (codegen-patterns 10.1).
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_engine_int13:Int
'!Global g_engine_int161:Int
'!Global g_engine_int162:Int
'!Global g_engine_int163:Int
'!Global g_engine_int168:Int
'!Global g_engine_int169:Int
'!Global g_engine_int170:Int
'!Global g_player_int50:Int
Select g_engine_int13
	Case 1
		TScreen.Render(a0)
	Case 2
		TEngine.Render(a0)
	Case 3
		TEngine.RenderReplay(a0)
End Select
TScreenMessage.DrawAll()
If g_engine_int161 = 2 Then
	SetDrawStateHex("FFFFFF", 1.0, 1.0, 0, 3)
	Local p:TPlayer = TPlayer.GetHumanPlayer()
	If p <> Null Then
		DrawText("Rating: " + String(p.matchstats.rating), g_engine_int162 - 100, g_engine_int163 - 60)
	End If
	DrawText("FPS: " + String(g_engine_int170), g_engine_int162 - 100, g_engine_int163 - 40)
	DrawText("Time: " + String(g_player_int50), g_engine_int162 - 100, g_engine_int163 - 30)
	DrawText("Mem: " + String(GCMemAlloced()), g_engine_int162 - 100, g_engine_int163 - 20)
	DrawText(TEngine.GetStringMatchState(), g_engine_int162 - 100, g_engine_int163 - 10)
End If
Flip(1)
g_engine_int168 = g_engine_int168 + 1
If g_player_int50 > g_engine_int169 + 1000 Then
	g_engine_int169 = g_player_int50
	g_engine_int170 = g_engine_int168
	g_engine_int168 = 0
End If
Return 0
