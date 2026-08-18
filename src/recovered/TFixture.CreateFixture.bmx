' TFixture.CreateFixture
' VA 0x004c2b38   82 bytes   vtable slot 0x30   sig (i,i,i,i,i,i,i,i,i):TFixture
' byte-identical vs NSS5.exe (82/82, original length from Ghidra's inventory)
' local name 'f' is invented; field names come from object_model.json
	Function CreateFixture:TFixture(a0:Int, a1:Int, a2:Int, a3:Int, a4:Int, a5:Int, a6:Int, a7:Int, a8:Int)
		Local f:TFixture = New TFixture
		f.sdate = a0
		f.matchtype = a1
		f.round = a2
		f.groupno = a3
		f.leg = a4
		f.hometeam = a5
		f.awayteam = a6
		f.level = a7
		f.compid = a8
		Return f
	End Function
