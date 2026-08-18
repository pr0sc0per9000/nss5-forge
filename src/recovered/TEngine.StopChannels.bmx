' TEngine.StopChannels
' VA 0x004CE6C3   251 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (251/251, original length from Ghidra's inventory, mode=reloc)
' Assumes five module Globals of type TChannel (original names unrecoverable):
'   g_chn1 0x00C5B33C   g_chn2 0x00C5B340   g_chn3 0x00C5B344
'   g_chn4 0x00C5B348   g_chn5 0x00C600D4
' The declared type only has to be an Object for the codegen; TChannel is the
' semantically right one because 0x0059B2A7 = StopChannel (alias set member picked
' for an audio context: _brl_audio_StopChannel).
' All five StopChannel calls come first, then all five Null stores, in the order below.
	Function StopChannels:Int()
		'!Global g_chn1:TChannel
		'!Global g_chn2:TChannel
		'!Global g_chn3:TChannel
		'!Global g_chn4:TChannel
		'!Global g_chn5:TChannel
		StopChannel(g_chn2)
		StopChannel(g_chn3)
		StopChannel(g_chn4)
		StopChannel(g_chn1)
		StopChannel(g_chn5)
		g_chn2 = Null
		g_chn3 = Null
		g_chn4 = Null
		g_chn1 = Null
		g_chn5 = Null
	End Function
