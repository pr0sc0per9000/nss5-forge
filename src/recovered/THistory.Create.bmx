' THistory.Create
' VA 0x0056f62b   88 bytes   vtable slot 0x38   sig (i,i,i,$,i,i):THistory
' byte-identical vs NSS5.exe (88/88, original length from Ghidra's inventory)
' local name 'h' is invented
	Function Create:THistory(a0:Int, a1:Int, a2:Int, a3:String, a4:Int, a5:Int)
		Local h:THistory = New THistory
		h.year = a0
		h.clubid = a1
		h.nationid = a2
		h.text = a3
		h.compid = a4
		h.winner = a5
		Return h
	End Function
