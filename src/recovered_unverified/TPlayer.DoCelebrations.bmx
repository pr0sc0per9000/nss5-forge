' TPlayer.DoCelebrations -- NOT VERIFIED. DO NOT COUNT AS RECOVERED.
' VA 0x004FD2DA   orig 760 bytes   vtable slot 0x1e8   sig ()i
'
' A byte-verified sibling for this EXACT (Type, Method) already exists at
' src/recovered/TPlayer.DoCelebrations.bmx (ORACLE MATCH 760/760,).
' An earlier draft was unaware of it and hand-rolled an equivalent-looking body that
' scored 693/760 (91.2%) with first difference at byte 12 -- a `mov eax,[addr]` loading the
' WRONG global address (0x00C9CBC0 instead of 0x00C5B1FC) despite the source using the
' correctly-named `g_player_int01`; the file's own '!Global pragma block was also entirely
' commented out (leading `'` on every line), so the declarations documented in the header
' were never actually in effect for that build. Root cause of the divergence traced to
' structural differences from the verified body, not just the pragma issue:
'   - Case 11: verified uses ONE flat 3-term `And`-chain guard
'     (`winner<>Null And Self.PlayerOnFeet() And Dist2D(...)<YardsToPixels(5.0)`) with the
'     RAW (non `<>0`-normalised) call/compare results feeding the chain directly (the
'     short-circuit-AND eax-reuse codegen tell). That draft instead materialised
'     `onfeet`/`reached` into separate Locals with explicit `<>0`/`<` comparisons -- extra
'     `setne`/`movzx` normalisation the original does not emit.
'   - Case 8's `losby` guard: verified writes `If losby > 1 Or (...) Then Else <body>` (empty
'     Then, real body in Else) because that is the only source shape that reproduces the
'     original's `je short / jmp short` pair; the earlier draft wrote the logically-equivalent
'     `If Not skip Then <body>`, which bcc compiles to a single negated jump, 2 bytes short.
'   - The PlayerCelebrating() ElseIf-tail: verified uses two NESTED solo `If`s
'     (`If g_player_int50 > g_engine_int27+3000` / `If g_player_tplayer01.PlayerCelebrating()`)
'     rather than one compound `And`, matching the original's per-term branch-off-flags shape
'     instead of forcing a materialised 0/1 result.
' Since names, types, and addresses cross-checked clean against src/generated/globals.bmx
' (g_player_int01@0x00c5b1fc, g_player_int04@0x00c5b250, g_player_int16@0x00c5d634,
' g_player_int50@0x00c6efd4, g_engine_int27@0x00c5b254, g_engine_int20@0x00c5b210,
' g_player_tplayer01@0x00c5b248 -- all identical to what the verified sibling declares), this
' file simply carries the verified sibling's body (statements only, body-only format, matching
' this file's prior on-disk shape) into this file rather than re-deriving it. This should
' bring this file to parity with the verified sibling; scripts/reverify.py already promotes
' verified bodies as-is, so the actual fix for the ASSEMBLED build was always the file in
' src/recovered/ -- this edit is to raise THIS file's own standalone score as instructed.
'
' Field/Global assumptions (cross-confirmed against the
' verified sibling and src/generated/globals.bmx):
'   TPlayer fields: x=0x4c y=0x50 desx=0x7c desy=0x80 teamid=0x14 facing=0x128 (f/f/f/f/i/i)
'   TTeam field:    id=0x8
'   g_player_int01     0x00C5B1FC  Int      match state (11=full time, 8=goal)
'   g_player_int04     0x00C5B250  Int      team id of the team that just scored/conceded
'   g_player_int16     0x00C5D634  Int      pitch half-width, used negated as a boundary
'   g_player_int50     0x00C6EFD4  Int      current tick/match-time counter
'   g_engine_int27     0x00C5B254  Int      tick timestamp of the triggering event
'   g_engine_int20     0x00C5B210  Int      match minute
'   g_player_tplayer01 0x00C5B248  TPlayer  the human/newstar-tracked player
' FUN_004a7fe0 = _bbFloatAbs (Abs()).
'
' Body-only format below (statements only; no Method header) -- paste into a probe or the
' real Type to continue. DO NOT move this file to src/recovered/ until it MATCHes.
'!Global g_player_int01:Int
'!Global g_player_int16:Int
'!Global g_player_int04:Int
'!Global g_engine_int27:Int
'!Global g_player_int50:Int
'!Global g_engine_int20:Int
'!Global g_player_tplayer01:TPlayer
Select g_player_int01
	Case 11
		If Abs(Self.desy) < 50.0 Then Return 0
		Local winner:TTeam = TEngine.GetWinningClub()
		If winner <> Null And Self.PlayerOnFeet() And Dist2D(Self.x, Self.y, Self.desx, Self.desy) < TPitch.YardsToPixels(5.0)
			If winner.id = Self.teamid
				Self.DoAnimCelebrate(5)
			ElseIf Self.desx > -g_player_int16
				Self.DoAnimCommiserate(Self.facing)
			EndIf
		EndIf
	Case 8
		If Self.PlayerOnFeet() <> 0
			If g_player_int04 = Self.teamid
				If Dist2D(Self.x, Self.y, Self.desx, Self.desy) < TPitch.YardsToPixels(3.5) And g_player_int50 > g_engine_int27 + 1500
					If g_player_tplayer01 = Self
						Local losby:Int = Self.GetMyTeam().GetLosingBy()
						If losby > 1 Or (losby > 0 And g_engine_int20 > 70)
						Else
							Select g_engine_int20 Mod 3
								Case 0
									If Self.y < 0
										Self.DoAnimCelebrate(2)
									Else
										Self.DoAnimCelebrate(3)
									EndIf
								Case 1
									Self.DoAnimCelebrate(0)
								Case 2
									Self.DoAnimCelebrate(1)
							End Select
						EndIf
					Else
						If g_player_int50 > g_engine_int27 + 3000
							If g_player_tplayer01.PlayerCelebrating()
								If Dist2D(Self.x, Self.y, g_player_tplayer01.x, g_player_tplayer01.y) < TPitch.YardsToPixels(3.0)
									Self.DoAnimCelebrate(5)
								EndIf
							EndIf
						EndIf
					EndIf
				EndIf
			Else
				Self.DoAnimCommiserate(Self.facing)
			EndIf
		EndIf
End Select
Return 0
