' TPitch.DrawBosses
' VA 0x004E96A0   1070 bytes   class-table slot 0x50   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (1070/1070, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=51)
'
' ASSUMPTIONS
'  Module Globals -- NAMES ARE OURS, declared TYPES are load-bearing:
'    0x00C5B1FC Int      g_player_int01   (already hand-verified elsewhere in the corpus)
'    0x00C5B24C Int      g_engine_int26
'    0x00C5D678 Int      g_pitch_int18
'    0x00C5D67C Int      g_pitch_int19
'    0x00C5D674 Int      g_pitch_int17
'    0x00C5B248 TPlayer  g_player_tplayer01  (globals_final: vtable-call evidence, the only
'                                              Type with all four slots)
'    0x00C5B1CC Int      g_engine_int13
'    0x00C5B2C8 Int      g_engine_int52
'    0x00C5B1D0 Int      g_pitch_int02
'    0x00C6EFD4 Int      g_player_int50   (already hand-verified elsewhere in the corpus)
'    0x00C5D620 TImage[] g_pitch_arr06    -- globals_final says Object[]; the element pushed
'                        straight into TDrawOb.AddDrawOb's :TImage parameter with NO
'                        bbObjectDowncast call, so the array must already be TImage[].
'  Fields: TBall .y +0x1C (Float), TPlayer .y +0x50 (Float).
'  Slots resolved: TBall+0x44 = GetActiveBall():TBall (niladic static call through a data
'    pointer, no push/no `add esp` -- not "STDCALL", just zero arguments), TDrawOb+0x34 =
'    AddDrawOb(:TImage,f,f,f,i,i,f,i,$,f,f,i,f,$,i,i)i.
'  Literals read from NSS5.exe's data section: 0x3e800000=0.25 (both AddDrawOb calls),
'    0x3f800000=1.0, 0x3eb33333=0.35, 0x3e4ccccd=0.2; string literals "" / "FFFFFF" / "000000"
'    (addresses only -- contents not re-verified against the exe this pass).
' SHAPE NOTES (each measured)
'  * `(g_engine_int52 / 8) Mod 2` -- bcc constant-folds the "/ 8" into the sign-adjusted
'    `sar eax,3` idiom (any power-of-two divisor), but the following "Mod 2" still emits a
'    real `idiv`; no special syntax needed; the shift-vs-idiv split is bcc's own optimisation.
'  * `iVar4 = iVar4 + ((X) Mod 2 + 1)` -- the extra parentheses are load-bearing. Without them
'    `iVar4 + (X Mod 2) + 1` still parses correctly but bcc emits it as TWO separate additions
'    (`ebx=ebx+eax` then `ebx=ebx+1`, one extra `mov`) instead of the original's ONE addition
'    of the pre-summed `(mod_result + 1)`.
'  * Comparison operand order is significant and NOT symmetric with the written boolean sense:
'    `ball.y < g_pitch_int18 - 60` loads ball.y first either way (it's a cheap register-
'    relative field), but the "upper bound" checks (`ball.y > pitch+60`,
'    `g_player_tplayer01.y > pitch+60`) needed the FIELD READ written as the LEFT operand to
'    reproduce the original's load order (field first, then the additive constant) -- writing
'    `pitch + 60 < field` (constant first) cost extra bytes once the surrounding code was
'    otherwise exact.
'  * `If bVar1 And g_player_tplayer01 <> Null` -- a bare truthy test on the flag Local, NOT
'    `bVar1 <> 0 And ...`; the latter adds a redundant `setne`/`movzx` pair bcc does not need
'    for a plain Int truth test.
'  * The SECOND boss's inner "close to a controlled player" re-check still compares against
'    `g_pitch_int18` (not `g_pitch_int19`, which the outer bound check for this boss uses) --
'    reproduced exactly, not normalised; this looks like an original copy-paste artefact.
'  * The final AddDrawOb's X offset is `g_pitch_int19 + -2`, not `g_pitch_int19 - 2` -- same
'    value, but bcc emits `add eax,-2` for the former and `sub eax,2` for the latter; only the
'    first matches.
	'!Global g_player_int01:Int
	'!Global g_engine_int26:Int
	'!Global g_pitch_int18:Int
	'!Global g_pitch_int19:Int
	'!Global g_pitch_int17:Int
	'!Global g_player_tplayer01:TPlayer
	'!Global g_engine_int13:Int
	'!Global g_engine_int52:Int
	'!Global g_pitch_int02:Int
	'!Global g_player_int50:Int
	'!Global g_pitch_arr06:TImage[]
	Function DrawBosses:Int()
		Local ball:TBall = TBall.GetActiveBall()
		Local iVar4:Int = 3
		Local bVar1:Int = 0
		If g_player_int01 = 8 And g_engine_int26 = 1 Then bVar1 = 1
		If ball <> Null
			If ball.y < g_pitch_int18 - 60 Then iVar4 = 0
			If ball.y > g_pitch_int18 + 60 Then iVar4 = 6
			If bVar1 And g_player_tplayer01 <> Null
				iVar4 = 3
				If g_player_tplayer01.y < g_pitch_int18 - 60 Then iVar4 = 0
				If g_player_tplayer01.y > g_pitch_int18 + 60 Then iVar4 = 6
			EndIf
		EndIf
		If bVar1
			If g_engine_int13 = 3
				iVar4 = iVar4 + ((g_engine_int52 / 8) Mod 2 + 1)
			ElseIf g_engine_int13 = 1
				iVar4 = iVar4 + ((g_pitch_int02 / 200) Mod 2 + 1)
			Else
				iVar4 = iVar4 + ((g_player_int50 / 200) Mod 2 + 1)
			EndIf
		EndIf
		TDrawOb.AddDrawOb(g_pitch_arr06[0], Float(g_pitch_int17), Float(g_pitch_int18), 0, iVar4, 3, 1.0, 0, "FFFFFF", 0.25, 0.25, 3, 0, "", 0, 0)
		iVar4 = 3
		bVar1 = 0
		If g_player_int01 = 8 And g_engine_int26 = 2 Then bVar1 = 1
		If ball <> Null
			If ball.y < g_pitch_int19 - 60 Then iVar4 = 0
			If ball.y > g_pitch_int19 + 60 Then iVar4 = 6
			If bVar1 And g_player_tplayer01 <> Null
				iVar4 = 3
				If g_player_tplayer01.y < g_pitch_int18 - 60 Then iVar4 = 0
				If g_player_tplayer01.y > g_pitch_int18 + 60 Then iVar4 = 6
			EndIf
		EndIf
		If bVar1
			If g_engine_int13 = 3
				iVar4 = iVar4 + ((g_engine_int52 / 8) Mod 2 + 1)
			ElseIf g_engine_int13 = 1
				iVar4 = iVar4 + ((g_pitch_int02 / 200) Mod 2 + 1)
			Else
				iVar4 = iVar4 + ((g_player_int50 / 200) Mod 2 + 1)
			EndIf
		EndIf
		TDrawOb.AddDrawOb(g_pitch_arr06[1], Float(g_pitch_int17), Float(g_pitch_int19), 0, iVar4, 3, 1.0, 0, "FFFFFF", 0.25, 0.25, 3, 0, "", 0, 0)
		TDrawOb.AddDrawOb(g_pitch_arr06[1], Float(g_pitch_int17 + 1), Float(g_pitch_int19 + -2), 0, iVar4, 2, 0.35, 20, "000000", 0.25, 0.2, 3, 0, "", 0, 0)
		Return 0
	End Function
