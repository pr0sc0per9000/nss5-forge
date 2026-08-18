' TPitch.DrawFans
' VA 0x004E8468   4664 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG (i,f,f,f,i)i, class-table slot 0x4C
' ASSUMPTIONS
'   0x00C5D66C declared g_pitch_int15:Int   -- stand-segment width step  (same slot as TPitch.DrawStadium)
'   0x00C5D670 declared g_pitch_int16:Int   -- stand-segment height step (same slot as TPitch.DrawStadium)
'   0x00C5D624 declared g_pitch_int05:Int   -- stand-mirroring flag, 0 or 1
'   0x00C5B1D0 declared g_pitch_int02:Int   -- free-running ms counter, divided by 200 for the flash phase
'   0x00C5D614 declared g_pitch_arr05:Int[,,]  -- [plane, col, row]; plane 0 = fan image index (-1 = empty),
'                                                 plane 1 = per-fan x jitter, plane 2 = per-fan y jitter.
'                                                 3-D is forced by the header: data at +0x20 means dims=3,
'                                                 and the index is i0*scales[1] + i1*scales[2] + i2.
'   0x00C5D60C declared g_pitch_arr04:TImage[] -- fan sprite sheets; [8] and [9] are the away-colours pair
'   0x00C5B1FC declared g_player_int01:Int  -- match/replay state; 8 = goal celebration, 2 = pre-match
'   0x00C6EFD4 declared g_player_int50:Int  -- second ms counter used for the default flash phase
'   0x00C5B1CC declared g_engine_int13:Int  -- which clock drives the crowd flash (3, 1, else)
'   0x00C5B210 declared g_engine_int20:Int  -- 0 while the pre-match crowd is animating
'   0x00C5B24C declared g_engine_int26:Int  -- which end celebrates (1 = home, 2 = away)
'   0x00C5B2C8 declared g_engine_int52:Int  -- frame counter, shifted right 3 for the flash phase
'   0x00C6EFE4 declared g_engine_int162:Int -- viewport width;  x is culled against it + 128
'   0x00C6EFE8 declared g_engine_int163:Int -- viewport height; y is culled against it + 128
' NOTES
'   No string literals in the body.  Every float constant was read from .data
'   0x00C78754..0x00C78850; they are plain decimals (10.0, 10.5, 0.25, 233.5, -128.0, ...).
'   bcc emits FLOAT comparisons with the NEGATED setcc and an inverted branch:
'   `If yy < -64.0` becomes fucom + setae + `jne past-block`.  Read the setcc as the
'   negation of the source operator (setae => `<`, setbe => `>`).
'   The four viewport guards are real early `Return 0`s (each emits its own mov eax,0/jmp
'   epilogue); the fifth `Return 0` at the end is explicit (mov eax,0 + EB 00).
'   `a2 :+ 15.0 * a1` (compound) evaluates the rhs FIRST, then loads a2 -- that is what
'   distinguishes it from `a2 = a2 + 15.0 * a1`, which loads a2 first.  Every parameter
'   adjustment in the ten Cases is the compound form.
'   The two Float Locals xx/yy live on the x87 stack for the whole loop body; the fxch/fstp
'   pairs at each inner Case entry are bcc dropping the operand a Case is about to reassign.
'   DrawImage's x and y addends are pre-added into xx/yy (`xx :+ arr05[1,j,i]`), NOT written
'   inline in the call -- inline gives strict right-to-left argument evaluation and diverges
'   at offset 4508.
'   TOOLCHAIN NONDETERMINISM -- measured over 26 builds.  From BYTE-IDENTICAL probe source (build_source
'   hashed constant over 5 generations) bcc emits FOUR distinct outputs.  There are TWO
'   INDEPENDENT flip sites, both the no-match path of a `Select j Mod 2`:
'     site A  VA 0x004E9060  (Case 5)      site B  VA 0x004E90CD  (Case 6)
'   Each site independently lands in one of two forms of equal length:
'     original -- `D9 C9 fxch st(1)` sits ON the Select's no-match path, the Case 0
'                 `If i = rows Then Continue` false-tail is a bare `jmp`, and the join
'                 after End Select carries a zero-displacement `EB 00`;
'     alt      -- the no-match path is a bare `jmp` and the fxch is pushed down into the
'                 Case 0 false-tail and the Case 1 join instead.
'   Total length is INVARIANT at 4664 in every build; only placement moves.  The three
'   MISMATCH signatures identify which site flipped:
'     matched=4046 -> A only   matched=3982 -> B only   matched=3940 -> both
'   All FOUR outputs predicted by the two-site model were observed, and no fifth ever was:
'     fcd3481746aa MATCH 4664 | 637899b2ab89 A 4046 | 433539b03163 B 3982 | b8e2a75a31ad AB 3940
'   Measured MATCH rate 10 of 35 builds (28.6%), consistent with two independent ~55% coins.
'   Verified MATCH 4664/4664 mode=reloc reloc_masked=192 under NSS5_NO_LEARN=1 on ten
'   separate builds; the matching output hashes identically (fcd3481746aa) every time.
'   This is a bcc defect, not a body defect: a 314-byte function using the same
'   Select/Float/Continue shape (scripts/w14L11_repro.py) is deterministic 6 of 6, so the
'   trigger is scale-dependent.  RE-RUN THE ORACLE UNTIL IT MATCHES; a single MISMATCH on
'   this body is not evidence against it.
	Function DrawFans:Int(a0:Int, a1:Float, a2:Float, a3:Float, a4:Int)
		'!Global g_pitch_int02:Int
		'!Global g_pitch_int05:Int
		'!Global g_pitch_int15:Int
		'!Global g_pitch_int16:Int
		'!Global g_pitch_arr04:TImage[]
		'!Global g_pitch_arr05:Int[,,]
		'!Global g_player_int01:Int
		'!Global g_player_int50:Int
		'!Global g_engine_int13:Int
		'!Global g_engine_int20:Int
		'!Global g_engine_int26:Int
		'!Global g_engine_int52:Int
		'!Global g_engine_int162:Int
		'!Global g_engine_int163:Int
		Local fw:Float = 10.0 * a1
		Local fh:Float = 10.5 * a1
		Local rows:Int = 25
		Local cols:Int = 26
		SetRotation 0
		SetScale a1 * 0.25, a1 * 0.25
		Local img:TImage = Null
		Local frame:Int = 0
		Local flash:Int = 0
		Select a0
		Case 1
			a2 :+ 15.0 * a1
			a3 :- g_pitch_int16 * a1
			a3 :+ 58.0 * a1
			If g_player_int01 = 8 And g_engine_int26 = 1 Then flash = 1
		Case 2
			rows = 3
			fw = 10.25 * a1
			fh = 8.5 * a1
			a2 :- g_pitch_int15 * a1
			a2 :+ 12.0 * a1
			a3 :+ 233.5 * a1
			Select g_pitch_int05
			Case 1
				If g_player_int01 = 8 And g_engine_int26 = 2 Then flash = 1
			Case 0
				If g_player_int01 = 8 And g_engine_int26 = 1 Then flash = 1
			End Select
		Case 3
			cols = 17
			rows = 43
			fw = 14.0 * a1
			fh = 8.0 * a1
			a2 :- g_pitch_int16 * a1
			a2 :+ 50.0 * a1
			a3 :- 1.0 * a1
			If g_player_int01 = 8 And g_engine_int26 = 1 Then flash = 1
		Case 4
			cols = 17
			rows = 43
			fw = 14.0 * a1
			fh = 8.0 * a1
			a2 :+ 97.5 * a1
			a3 :+ 20.0 * a1
			Select g_pitch_int05
			Case 1
				If g_player_int01 = 8 And g_engine_int26 = 2 Then flash = 1
			Case 0
				If g_player_int01 = 8 And g_engine_int26 = 1 Then flash = 1
			End Select
			SetScale -a1 * 0.25, a1 * 0.25
		Case 5
			cols = 44
			rows = 31
			fw = 7.0 * a1
			fh = 10.0 * a1
			a2 :- g_pitch_int16 * a1
			a2 :+ 49.0 * a1
			a3 :- g_pitch_int16 * a1
			a3 :+ 66.0 * a1
			If g_player_int01 = 8 And g_engine_int26 = 1 Then flash = 1
		Case 6
			cols = 44
			rows = 31
			fw = 7.0 * a1
			fh = 10.0 * a1
			a2 :+ 30.0 * a1
			a3 :- g_pitch_int16 * a1
			a3 :+ 66.0 * a1
			SetScale -a1 * 0.25, a1 * 0.25
			Select g_pitch_int05
			Case 1
				If g_player_int01 = 8 And g_engine_int26 = 2 Then flash = 1
			Case 0
				If g_player_int01 = 8 And g_engine_int26 = 1 Then flash = 1
			End Select
		Case 7
			cols = 17
			rows = 17
			fw = 14.0 * a1
			fh = 8.0 * a1
			a2 :- g_pitch_int16 * a1
			a2 :+ 50.0 * a1
			a3 :+ 3.5 * a1
			Select g_pitch_int05
			Case 1
				If g_player_int01 = 8 And g_engine_int26 = 1 Then flash = 1
			Case 0
				If g_player_int01 = 8 And g_engine_int26 = 2 Then flash = 1
			End Select
		Case 8
			cols = 17
			rows = 17
			fw = 14.0 * a1
			fh = 8.0 * a1
			a2 :+ 97.5 * a1
			a3 :+ 24.5 * a1
			Select g_pitch_int05
			Case 1
				If g_player_int01 = 8 And g_engine_int26 = 2 Then flash = 1
			Case 0
				If g_player_int01 = 8 And g_engine_int26 = 1 Then flash = 1
			End Select
			SetScale -a1 * 0.25, a1 * 0.25
		Case 9
			cols = 10
			rows = 12
			fw = 15.5 * a1
			fh = 5.25 * a1
			a2 :- g_pitch_int16 * a1
			a2 :+ 138.5 * a1
			a3 :+ 188.5 * a1
			Select g_pitch_int05
			Case 1
				If g_player_int01 = 8 And g_engine_int26 = 1 Then flash = 1
			Case 0
				If g_player_int01 = 8 And g_engine_int26 = 2 Then flash = 1
			End Select
		Case 10
			cols = 10
			rows = 12
			fw = 15.5 * a1
			fh = 5.25 * a1
			a2 :- 10.0 * a1
			a3 :+ 259.0 * a1
			Select g_pitch_int05
			Case 1
				If g_player_int01 = 8 And g_engine_int26 = 2 Then flash = 1
			Case 0
				If g_player_int01 = 8 And g_engine_int26 = 1 Then flash = 1
			End Select
			SetScale -a1 * 0.25, a1 * 0.25
		End Select
		If g_player_int01 = 2 And g_engine_int20 = 0 Then flash = 1
		If a2 + cols * fw < -128.0 Then Return 0
		If a2 > g_engine_int162 + 128 Then Return 0
		If a3 + rows * fh < -128.0 Then Return 0
		If a3 > g_engine_int163 + 128 Then Return 0
		Local count:Int = 0
		For Local i:Int = 0 To rows
			For Local j:Int = 0 To cols
				count :+ 1
				Local yy:Float = a3 + i * fh
				Local xx:Float = a2 + j * fw
				If g_pitch_arr05[0, j, i] > -1 Then img = g_pitch_arr04[g_pitch_arr05[0, j, i]]
				Select a0
				Case 1
					frame = 6
					If i = 25 Then frame = 9
				Case 2
					If g_pitch_int05 <> 0
						If g_pitch_arr05[0, j, i] = 6 Then img = g_pitch_arr04[8]
						If g_pitch_arr05[0, j, i] = 7 Then img = g_pitch_arr04[9]
					EndIf
					frame = 24
				Case 3
					If a4 And i > 26 And i < 38 And j > 8 Then Continue
					yy = a3 + i * fh + j * 1.25 * a1
					frame = 15
				Case 4
					yy = a3 + i * fh - j * 1.25 * a1
					If g_pitch_int05 <> 0
						If g_pitch_arr05[0, j, i] = 6 Then img = g_pitch_arr04[8]
						If g_pitch_arr05[0, j, i] = 7 Then img = g_pitch_arr04[9]
					EndIf
					frame = 15
				Case 5
					Select j Mod 2
					Case 0
						yy = a3 + i * fh
						If i = rows Then Continue
					Case 1
						yy = a3 + i * fh - 4.0 * a1
					End Select
					frame = 3
				Case 6
					Select j Mod 2
					Case 0
						yy = a3 + i * fh
						If i = rows Then Continue
					Case 1
						yy = a3 + i * fh - 4.0 * a1
					End Select
					frame = 3
					If g_pitch_int05 <> 0
						If g_pitch_arr05[0, j, i] = 6 Then img = g_pitch_arr04[8]
						If g_pitch_arr05[0, j, i] = 7 Then img = g_pitch_arr04[9]
					EndIf
				Case 7
					yy = a3 + i * fh + j * 1.25 * a1
					If g_pitch_int05 = 0
						If g_pitch_arr05[0, j, i] = 6 Then img = g_pitch_arr04[8]
						If g_pitch_arr05[0, j, i] = 7 Then img = g_pitch_arr04[9]
					EndIf
					frame = 15
					If a4 And i = 14 And j > 8 Then frame = 12
				Case 8
					yy = a3 + i * fh - j * 1.25 * a1
					If g_pitch_int05 <> 0
						If g_pitch_arr05[0, j, i] = 6 Then img = g_pitch_arr04[8]
						If g_pitch_arr05[0, j, i] = 7 Then img = g_pitch_arr04[9]
					EndIf
					frame = 15
				Case 9
					xx = a2 + j * fw + i * 8.5 * a1
					yy = a3 + i * fh + j * 0.75 * a1
					Select i
					Case 7
						If j > 9 Then Continue
					Case 8
						If j > 9 Then Continue
					Case 9
						If j > 8 Then Continue
					Case 10
						If j > 8 Then Continue
					Case 11
						If j > 7 Then Continue
					Case 12
						If j > 7 Then Continue
					End Select
					If g_pitch_int05 = 0
						If g_pitch_arr05[0, j, i] = 6 Then img = g_pitch_arr04[8]
						If g_pitch_arr05[0, j, i] = 7 Then img = g_pitch_arr04[9]
					EndIf
					frame = 18
				Case 10
					xx = a2 + j * fw + i * 8.5 * a1
					yy = a3 - i * fh - j * 0.75 * a1
					frame = 18
					If g_pitch_int05 <> 0
						If g_pitch_arr05[0, j, i] = 6 Then img = g_pitch_arr04[8]
						If g_pitch_arr05[0, j, i] = 7 Then img = g_pitch_arr04[9]
					EndIf
					Select i
					Case 0
						If j < 3 Then Continue
					Case 1
						If j < 3 Then Continue
					Case 2
						If j < 2 Then Continue
					Case 3
						If j < 2 Then Continue
					Case 4
						If j < 1 Then Continue
					Case 5
						If j < 1 Then Continue
					End Select
				End Select
				If yy < -64.0 Then Continue
				If yy > g_engine_int163 + 128 Then Continue
				If xx < -128.0 Then Continue
				If xx > g_engine_int162 + 128 Then Exit
				If flash
					If g_engine_int13 = 3
						frame :+ (g_engine_int52 / 8 + count) Mod 2 + 1
					ElseIf g_engine_int13 = 1
						frame :+ (g_pitch_int02 / 200 + count) Mod 2 + 1
					Else
						frame :+ (g_player_int50 / 200 + count) Mod 2 + 1
					EndIf
				EndIf
				xx :+ g_pitch_arr05[1, j, i]
				yy :+ g_pitch_arr05[2, j, i]
				DrawImage img, xx, yy, frame
			Next
		Next
		Return 0
	End Function
