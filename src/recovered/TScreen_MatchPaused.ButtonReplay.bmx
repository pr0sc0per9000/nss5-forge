' TScreen_MatchPaused.ButtonReplay
' VA 0x0054AE56   67 bytes   vtable slot 0x3C   sig ()i
' byte-identical vs NSS5.exe (67/67, original length from Ghidra's inventory, mode=reloc)
' Assumes two module Globals (original names unrecoverable):
'   g_replaybg:TImage    (0x00C61714) -- typed by the assignment into TScreen.bg
'   g_matchpaused:TScreen (0x00C6764C) -- TScreen.bg is the field at +0x10
' 0x00C5BB30 = TEngine class table + 0x100 = TEngine.PauseEngine()
' 0x00C5BACC = TEngine class table + 0x9C  = TEngine.StartReplay()
	Function ButtonReplay:Int()
		'!Global g_replaybg:TImage
		'!Global g_matchpaused:TScreen
		g_matchpaused.bg = g_replaybg
		TEngine.PauseEngine()
		TEngine.StartReplay()
	End Function
