' TTraining.StartChallenge
' VA 0x0057fd35   95 bytes   vtable slot 0x54   sig ()i
' byte-identical vs NSS5.exe (95/95, original length from Ghidra's inventory, mode=reloc)
' assumes module Globals (names ours, types load-bearing):
'   Global g_tr_screen:Int      (0x00C6EFD4)  -- globals_final types this TScreen from its
'   Global g_tr_prevscreen:Int  (0x00C6CFA0)     construction site, but the original copies
'                                                it with a bare `mov`, with NO refcount
'                                                inc/dec, so at THIS use it is an Int.
'                                                Declared TScreen the body is 121 bytes.
'   Global g_tr_challenge:Int   (0x00C6CF98)
'   Global g_tr_snd:TSound      (0x00C5B34C, BRL.Audio)
'   Global g_tr_chan:TChannel   (0x00C5B33C, BRL.Audio)
' PTR_FUN_00C5BAA0 = TEngine class table + 0x70 -> TEngine.SetUpSetPiece(i,i,i,i)
' PTR_FUN_00C5FAB0 = TPlayer class table + 0x164 -> TPlayer.GetHumanPlayer():TPlayer
' FUN_005071C3 = the recovered module Function FlushAllInput; FUN_0059B25E = PlaySound.
' HARNESS: needs harness.MODULE_TYPES patched with TSound/TChannel -> BRL.Audio (see report).
'!Global g_tr_screen:Int
'!Global g_tr_prevscreen:Int
'!Global g_tr_challenge:Int
'!Global g_tr_snd:TSound
'!Global g_tr_chan:TChannel

	Function StartChallenge:Int()
		g_tr_prevscreen = g_tr_screen
		g_tr_challenge = 1
		TEngine.SetUpSetPiece(0,1,0,0)
		FlushAllInput()
		TPlayer.GetHumanPlayer().joy.kickenabled = 0
		PlaySound(g_tr_snd, g_tr_chan)
	End Function
