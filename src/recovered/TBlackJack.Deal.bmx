' TBlackJack.Deal
' VA 0x00576d5c   146 bytes   vtable slot 0x3c   sig ()i
' byte-identical vs NSS5.exe (146/146, original length from Ghidra's inventory, mode=reloc)
' assumes module Globals (names ours, types load-bearing):
'   Global g_bj_playerhand:TList  (0x00C6C16C, slot 0x44 = TList.AddLast)
'   Global g_bj_dealerhand:TList  (0x00C6C170)
'   Global g_bj_state:Int         (0x00C6C174)
'   Global g_bj_snd:TSound        (0x00C6C168, BRL.Audio)
'   Global g_bj_chan:TChannel     (0x00C6F090, BRL.Audio)
' PTR_FUN_00C6C320 / 00C6C32C are TBlackJack's own class table + 0x38 / + 0x44, i.e. the
'   sibling Functions Reset() and CheckPlayerScore(), so they are written unqualified.
' PTR_FUN_00C6C48C = TCard class table + 0x3C -> TCard.Pull():TCard (cross-Type, qualified).
' HARNESS: needs harness.MODULE_TYPES patched with TSound/TChannel -> BRL.Audio (see report).
'!Global g_bj_playerhand:TList
'!Global g_bj_dealerhand:TList
'!Global g_bj_state:Int
'!Global g_bj_snd:TSound
'!Global g_bj_chan:TChannel

	Function Deal:Int()
		Reset()
		g_bj_playerhand.AddLast(TCard.Pull())
		g_bj_playerhand.AddLast(TCard.Pull())
		g_bj_dealerhand.AddLast(TCard.Pull())
		g_bj_dealerhand.AddLast(TCard.Pull())
		g_bj_state = 1
		PlaySound(g_bj_snd, g_bj_chan)
		CheckPlayerScore()
	End Function
