' TScreen_Kits.CreateKits
' VA 0x0054A065   1115 bytes   class-table slot 0x40   sig ($)i
' byte-identical vs NSS5.exe (1115/1115, original length from Ghidra's inventory, mode=reloc)
'
' Builds the four kits for a match: two outfield kits (a0 is the outfield player-image
' template path, e.g. "GameMedia/Images/Interface/Player.png" / "EngineMedia/Match/
' Player/Player.png" from the two call sites already in the corpus -- RefreshKits,
' ButtonPlay) plus two fixed goalkeeper kits.
'
' g_kits_int05 (0..8) is a hand-written 9-entry clash table choosing which of each club's
' three kit colour sets (Home/Away/Third) each side wears -- NOT a computed formula; the
' Case order is (H,H) (H,A) (A,H) (A,A) (H,T) (A,T) (T,H) (T,A) (T,T), confirmed as a
' Select (codegen-patterns 10.2: 9 back-to-back `cmp/je` against ONE load of the Global,
' ending in a single no-Default `jmp`) -- as If/ElseIf the body is short.
'
' GLOBALS -- names already established by TScreen_Kits.RefreshKits / .ButtonPlay, same
' addresses: g_kits_int05 0x00C674C4, g_kits_club1/2 0x00C674D4/D8 (:TClub, home/away),
' g_kits_kit1/2 0x00C674DC/E0 (:TKit, outfield), g_kits_kit3/4 0x00C674E4/E8 (:TKit,
' goalkeeper). kitcolsHome/Away/Third/Keeper are TBase_Team fields (+0x44/0x48/0x4c/0x50).
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_kits_int05:Int
'!Global g_kits_club1:TClub
'!Global g_kits_club2:TClub
'!Global g_kits_kit1:TKit
'!Global g_kits_kit2:TKit
'!Global g_kits_kit3:TKit
'!Global g_kits_kit4:TKit
Select g_kits_int05
	Case 0
		g_kits_kit1 = TKit.CreateKit(g_kits_club1.kitcolsHome, a0)
		g_kits_kit2 = TKit.CreateKit(g_kits_club2.kitcolsHome, a0)
	Case 1
		g_kits_kit1 = TKit.CreateKit(g_kits_club1.kitcolsHome, a0)
		g_kits_kit2 = TKit.CreateKit(g_kits_club2.kitcolsAway, a0)
	Case 2
		g_kits_kit1 = TKit.CreateKit(g_kits_club1.kitcolsAway, a0)
		g_kits_kit2 = TKit.CreateKit(g_kits_club2.kitcolsHome, a0)
	Case 3
		g_kits_kit1 = TKit.CreateKit(g_kits_club1.kitcolsAway, a0)
		g_kits_kit2 = TKit.CreateKit(g_kits_club2.kitcolsAway, a0)
	Case 4
		g_kits_kit1 = TKit.CreateKit(g_kits_club1.kitcolsHome, a0)
		g_kits_kit2 = TKit.CreateKit(g_kits_club2.kitcolsThird, a0)
	Case 5
		g_kits_kit1 = TKit.CreateKit(g_kits_club1.kitcolsAway, a0)
		g_kits_kit2 = TKit.CreateKit(g_kits_club2.kitcolsThird, a0)
	Case 6
		g_kits_kit1 = TKit.CreateKit(g_kits_club1.kitcolsThird, a0)
		g_kits_kit2 = TKit.CreateKit(g_kits_club2.kitcolsHome, a0)
	Case 7
		g_kits_kit1 = TKit.CreateKit(g_kits_club1.kitcolsThird, a0)
		g_kits_kit2 = TKit.CreateKit(g_kits_club2.kitcolsAway, a0)
	Case 8
		g_kits_kit1 = TKit.CreateKit(g_kits_club1.kitcolsThird, a0)
		g_kits_kit2 = TKit.CreateKit(g_kits_club2.kitcolsThird, a0)
End Select
g_kits_kit3 = TKit.CreateKit(g_kits_club1.kitcolsKeeper, "EngineMedia/Match/Player/Keeper.png")
g_kits_kit4 = TKit.CreateKit(g_kits_club2.kitcolsKeeper, "EngineMedia/Match/Player/Keeper.png")
Return 0
