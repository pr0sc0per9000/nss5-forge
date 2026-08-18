' TStat.Create
' VA 0x0056e8bf   64 bytes   vtable slot 0x30   sig (i,i,i,i,f,f):TStat
' byte-identical vs NSS5.exe (64/64, original length from Ghidra's inventory)

	Function Create:TStat(a0:Int, a1:Int, a2:Int, a3:Int, a4:Float, a5:Float)
		Local s:TStat = New TStat
		s.stype = a0
		s.minute = a1
		s.x = a2
		s.y = a3
		s.direction = a4
		s.distance = a5
		Return s
	End Function
