' TEngine.SetUpChannels
' VA 0x004ce59b   296 bytes   class-table slot 0x34   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (296/296, original length from Ghidra's inventory, mode=reloc)
'
' GLOBAL NAMES ARE OURS. Five TChannel Globals, allocated once each:
'   0x00C5B340, 0x00C5B344, 0x00C5B348, 0x00C5B33C, 0x00C600D4 -- note the source order is
'   NOT address order (the fourth is below the first three).
'!Global g_chan_a:TChannel
'!Global g_chan_b:TChannel
'!Global g_chan_c:TChannel
'!Global g_chan_d:TChannel
'!Global g_chan_e:TChannel
	Function SetUpChannels:Int()
		If Not g_chan_a Then g_chan_a = AllocChannel()
		If Not g_chan_b Then g_chan_b = AllocChannel()
		If Not g_chan_c Then g_chan_c = AllocChannel()
		If Not g_chan_d Then g_chan_d = AllocChannel()
		If Not g_chan_e Then g_chan_e = AllocChannel()
	End Function
