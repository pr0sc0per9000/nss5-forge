' TEngine.MatchOver
' VA 0x004d67cc   692 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, class-table slot 0xd8   (reloc_masked=52)
' ASSUMPTIONS
'   '!Global g_fixture:TFixture  -- 0x00C5B22C. globals_final says TPlayer but flags the
'     claim UNSOUND (slots 0x58/0x68/0x70/0x74 are shared by 51 Types). The FIELDS decide
'     it: +0x0C matchtype, +0x28 resulttype, +0x2C score1, +0x30 score2 and slot 0x78 =
'     CreateReplayFixture are exactly TFixture; TPlayer has floats at those offsets.
'   '!Global g_engine_state:Int  -- 0x00C5B208, the match phase (3 = full time, 5 = extra
'     time over).
'   '!Global g_engine_int23:Int, g_engine_int24:Int -- 0x00C5B230 / 0x00C5B234, the
'     first-leg away/home goals carried into the aggregate tests.
' SHAPE NOTES
'   * the outer dispatch is a Select, not If/ElseIf: five cmp/je back to back with every
'     target past the last compare, then one jmp for the no-match path (10.2).
'   * Case 3 and Case 5 use a NESTED If for the =5 arm, not ;
'     folding the score test into the ElseIf condition costs 18 bytes.
'   * operand order in Case 5 is load-bearing (10.1): the original evaluates
'      FIRST and compares it against ,
'     emitting cmp ecx,edx / jle. Writing the sides the other way round keeps the length
'     but diverges at byte 326.

	Function MatchOver:Int()
		'!Global g_fixture:TFixture
		'!Global g_engine_state:Int
		'!Global g_engine_int23:Int
		'!Global g_engine_int24:Int
		Select g_fixture.matchtype
		Case 1
			If g_engine_state = 3
				g_fixture.resulttype = 1
				Return 1
			EndIf
		Case 2
			If g_engine_state = 3
				g_fixture.resulttype = 1
				If g_fixture.score1 = g_fixture.score2
					g_fixture.CreateReplayFixture()
				EndIf
				Return 1
			EndIf
		Case 3
			If g_engine_state = 3
				If g_fixture.score1 <> g_fixture.score2
					g_fixture.resulttype = 1
					Return 1
				EndIf
			ElseIf g_engine_state = 5
				If g_fixture.score1 <> g_fixture.score2
					g_fixture.resulttype = 2
					Return 1
				EndIf
			EndIf
			g_fixture.resulttype = 3
		Case 4
			If g_engine_state = 3
				g_fixture.resulttype = 1
				Return 1
			EndIf
		Case 5
			If g_engine_state = 3
				If g_engine_int23 + g_fixture.score2 > g_engine_int24 + g_fixture.score1
					g_fixture.resulttype = 5
					Return 1
				EndIf
				If g_engine_int23 + g_fixture.score2 < g_engine_int24 + g_fixture.score1
					g_fixture.resulttype = 5
					Return 1
				EndIf
				If g_engine_int23 + g_fixture.score2 * 2 > g_engine_int24 * 2 + g_fixture.score1
					g_fixture.resulttype = 4
					Return 1
				EndIf
				If g_engine_int23 + g_fixture.score2 * 2 < g_engine_int24 * 2 + g_fixture.score1
					g_fixture.resulttype = 4
					Return 1
				EndIf
			ElseIf g_engine_state = 5
				If g_engine_int23 + g_fixture.score2 > g_engine_int24 + g_fixture.score1
					g_fixture.resulttype = 2
					Return 1
				EndIf
				If g_engine_int23 + g_fixture.score2 < g_engine_int24 + g_fixture.score1
					g_fixture.resulttype = 2
					Return 1
				EndIf
				g_fixture.resulttype = 3
			EndIf
		End Select
	End Function
