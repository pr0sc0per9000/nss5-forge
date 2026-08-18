' TTeamPool.LoadData
' VA 0x005264d7   102 bytes   sig (:TStream)i
' byte-identical vs NSS5.exe (102/102, original length from Ghidra's inventory, mode=reloc)
'
' Correct when first reconstructed, but not verifiable then: the call to Eof could not
' be masked. 0x005B80B9 was named _brl_gnet_GNetObjectState, because four BRL functions --
' gnet.GNetObjectState, stream.Eof, timer.TimerTicks and freeprocess.ProcessStatus -- have
' byte-identical 21-byte bodies, and name_brl.py silently kept whichever it saw first.
' It now records all byte-identical candidates as an alias set and the mask accepts any
' member, which is the honest answer: the address genuinely cannot be narrowed further.
	Method LoadData:Int(a0:TStream)
		While Not Eof(a0)
			Local s:String = ReadLine(a0)
			If s = "//" Then Return 0
			list.AddLast(TTableData.LoadTableData(s))
		Wend
	End Method
