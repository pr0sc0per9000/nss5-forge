' TScreen_NewPlayer.SetUpScreen
' VA 0x00524521   610 bytes   matched 610/610
' KIND=Function (static method on the Type), SIG=()i, SLOT=0x34
' Body-only format: statements only, parameters are a0, a1, ...
'
' ASSUMPTIONS
'   Globals declared and typed (names ours; types from globals_final.tsv construction
'   sites, corroborated by the slots each one is called through):
'     0x00C64218 g_np_page:Int                (bare dword store of 0, no refcounting)
'     0x00C64220 g_np_combonation:TCombo      (slots 0xB8/0x90/0xB0/0xC0 all TCombo)
'     0x00C64224 g_np_btnflag:TButton         (slot 0x8C = TButton.SetImage(:TImage))
'     0x00C64228 g_np_comboclubnation:TCombo
'     0x00C64234 g_np_comboskin:TCombo
'     0x00C64238 g_np_combohair:TCombo
'     0x00C6423C g_np_comboskincol:TCombo     (slot 0xAC = SelectItem)
'     0x00C64240 g_np_combohaircol:TCombo     (slot 0xB0 = SelectItemById)
'     0x00C596F0 g_nations:TList              (table said Object/low; slot 0x8C
'                                              ObjectEnumerator proves TList)
'     0x00C6F028 g_profile_co:TProfile        (3 construction sites)
'   Slots resolved (each pointer verified to be classtable_va + slot exactly):
'     [0x00C61C88] = TScreen + 0x5C  = TScreen.SetActive($,$):TScreen
'     [0x00C59A40] = TNation + 0x78  = TNation.SortListBy(i,i)i
'     [0x00C59A20] = TNation + 0x58  = TNation.SelectById(i):TNation
'     [0x00C61CE0] = TScreen + 0xB4  = TScreen.Tutorial()i
'     [0x00C6440C] = TScreen_NewPlayer + 0x3C = ComboClubNation()  -- OWN class table,
'     [0x00C6441C] = TScreen_NewPlayer + 0x4C = ComboSkin()           so written with
'     [0x00C64420] = TScreen_NewPlayer + 0x50 = ComboHair()           no Type. prefix
'     [0x00C64424] = TScreen_NewPlayer + 0x54 = RefreshKit()
'     TNation 0x74 = HasLeagues()i
'   Fields: TBase_Team +0x0C id, +0x1C labelname, +0x5C imgFlagSmall (TNation inherits);
'     TProfile +0x24 playercols:TPlayerColours (+0x08 skin, +0x0C hair),
'     TProfile +0x1C8 helppages:Int[] -- `[eax+0x18]` is BBArray data[0], index 0.
'   String literals read from the image: 0x00C8124C "newplayer", 0x00C7F250 "BBBBBB",
'     0x00C5D680 "FFFFFF", 0x00C5D284 = the empty string "".
'!Global g_np_page:Int
'!Global g_np_combonation:TCombo
'!Global g_np_btnflag:TButton
'!Global g_np_comboclubnation:TCombo
'!Global g_np_comboskin:TCombo
'!Global g_np_combohair:TCombo
'!Global g_np_comboskincol:TCombo
'!Global g_np_combohaircol:TCombo
'!Global g_nations:TList
'!Global g_profile_co:TProfile
TScreen.SetActive("newplayer", "")
g_np_page = 0
If g_np_combonation.CountItems() = 0
	TNation.SortListBy(2, 1)
	For Local n:TNation = EachIn g_nations
		g_np_combonation.AddItem(n.labelname, "BBBBBB", "FFFFFF", n.id)
	Next
	g_np_combonation.SelectItemById(62)
	For Local n:TNation = EachIn g_nations
		If n.HasLeagues()
			g_np_comboclubnation.AddItem(n.labelname, "BBBBBB", "FFFFFF", n.id)
		EndIf
	Next
	g_np_comboclubnation.SelectItemById(62)
	ComboClubNation()
EndIf
Local nat:TNation = TNation.SelectById(g_np_combonation.GetSelectedItemId())
If nat <> Null
	g_np_btnflag.SetImage(nat.imgFlagSmall)
EndIf
If g_np_comboskin.GetSelectedItemId() = 0
	g_np_comboskin.SelectItemById(5)
EndIf
If g_np_combohair.GetSelectedItemId() = 0
	g_np_combohair.SelectItemById(2)
EndIf
g_np_comboskincol.SelectItem(g_profile_co.playercols.skin)
g_np_combohaircol.SelectItemById(g_profile_co.playercols.hair)
ComboSkin()
ComboHair()
RefreshKit()
If g_profile_co.helppages[0] = 0
	TScreen.Tutorial()
	g_profile_co.helppages[0] = 1
EndIf
