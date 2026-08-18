' TBlackJack.SetUp
' VA 0x00576bc9   173 bytes   vtable slot 0x30   sig ()i   KIND=Function
' byte-identical vs NSS5.exe (173/173, original length from Ghidra's inventory)
'
' GLOBAL NAMES ARE OURS; the DECLARED TYPES are load-bearing (they pick the vtable slot).
' The `If Not g_bj_cardflip` form is required: the original tests with setne/movzx/cmp
' (21 bytes, codegen-patterns 10.3), not the 12-byte `= Null` compare.
' 0x004bc564 is the already-verified module Function LoadSoundChecked, and 0x00C90DF4
' decodes to 'GameMedia/Sounds/Casino/CardFlip.ogg'. `call [0x00C6C480]` is TCard+0x30.
'!Global g_bj_cardflip:TSound
'!Global g_bj_deck:TList
'!Global g_bj_hand:TList
'!Global g_mediaprefix:String
	Function SetUp:Int()
		If Not g_bj_cardflip
			g_bj_cardflip = LoadSoundChecked(g_mediaprefix + "GameMedia/Sounds/Casino/CardFlip.ogg", 0)
		EndIf
		TCard.SetUp()
		g_bj_deck = CreateList()
		g_bj_hand = CreateList()
	End Function
