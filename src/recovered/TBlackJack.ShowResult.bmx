' TBlackJack.ShowResult
' VA 0x00577710   692 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, slot 0x60   (static -- no implicit Self)
' ASSUMPTIONS
'  * Globals (names ours; declared types are load-bearing):
'      0x00C6C178 g_bj_result:Int         0x00C6C16C g_bj_playerhand:TList
'      0x00C6C170 g_bj_dealerhand:TList   0x00C5B1C8 g_bj_font:TBitmapFont
'      0x00C6B834 g_bj_fntsize:Int        0x00C6B85C g_bj_bet:Int
'      0x00C6EFE4 g_engine_w:Int          0x00C6EFE8 g_engine_h:Int
'    The two hand Globals are `Object` in globals_final.tsv; TList comes from the
'    already-verified TBlackJack.Deal (same addresses, slot 0x44 = TList.AddLast) and
'    is corroborated here by slot 0x70 = TList.Count.
'  * GetPlayerScore / GetDealerScore are TBlackJack's own class-table slots 0x5C / 0x58,
'    so they are written unqualified. Their `(*i,*i)i` reflection signature lowers to
'    Int Ptr, hence Varptr at the call site.
'  * String literals read out of the exe with harness.read_string.
'  * Comparison operand order is byte-observable and was measured, not guessed:
'    `p2 > p1` emits `cmp [p2],[p1] / setg`, `p1 < p2` emits `setl` -- same length,
'    different bytes. Likewise `ps > ds` (cmp esi,ebx / jle) vs `ds < ps`.
'  * The final three-way dispatch is a Select, not If/ElseIf: the subject is loaded
'    once into eax and all three `cmp eax,N / je` sit back to back with every target
'    past the last compare (guide 10.2). As If/ElseIf it reloads the Global each time.
	'!Global g_bj_result:Int
	'!Global g_bj_playerhand:TList
	'!Global g_bj_dealerhand:TList
	'!Global g_bj_font:TBitmapFont
	'!Global g_bj_fntsize:Int
	' g_bj_bet is an alias (a different name choice) for the same 0x00C6B85C
	' address TScreen_BlackJack.ButtonPlay.bmx declares as g_screen_blackjack_int01 = 50.
	'!Global g_bj_bet:Int = 50
	'!Global g_engine_w:Int
	'!Global g_engine_h:Int
	If g_bj_result = 0
		Local p1:Int = 0
		Local p2:Int = 0
		GetPlayerScore(Varptr p1, Varptr p2)
		Local ps:Int = p1
		If p2 > p1 And p2 < 22
			ps = p2
		EndIf
		Local d1:Int = 0
		Local d2:Int = 0
		GetDealerScore(Varptr d1, Varptr d2)
		Local ds:Int = d1
		If d2 > d1 And d2 < 22
			ds = d2
		EndIf
		If g_bj_playerhand.Count() = 5 And g_bj_dealerhand.Count() <> 5
			g_bj_result = 1
		ElseIf g_bj_dealerhand.Count() = 5 And g_bj_playerhand.Count() <> 5
			g_bj_result = 2
		ElseIf ps > ds
			g_bj_result = 1
		ElseIf ds > ps
			g_bj_result = 2
		EndIf
	EndIf
	Select g_bj_result
		Case 0
			TScreenMessage.Create(g_engine_w / 2, g_engine_h / 2, Lower(GetText("blackjack_Tie")), g_bj_fntsize, g_bj_font, Null, 1.0, "FFFFFF")
			TScreen_BlackJack.Tie()
		Case 1
			TScreenMessage.Create(g_engine_w / 2, g_engine_h / 2, GetText("bet_YouWon") + " " + FormatMoney(g_bj_bet * 2, 1), g_bj_fntsize, g_bj_font, Null, 1.0, "FFFFFF")
			TScreen_BlackJack.Win()
		Case 2
			TScreenMessage.Create(g_engine_w / 2, g_engine_h / 2, Lower(GetText("blackjack_DealerWins")), g_bj_fntsize, g_bj_font, Null, 1.0, "FFFFFF")
			TScreen_BlackJack.Lose()
	End Select
