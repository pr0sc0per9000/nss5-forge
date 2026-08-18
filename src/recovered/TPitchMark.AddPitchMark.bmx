' TPitchMark.AddPitchMark
' VA 0x004ea22e   123 bytes   vtable slot 0x38   sig (i,i,i,i,f)i
' byte-identical vs NSS5.exe (123/123, original length from Ghidra's inventory)
' ASSUMPTIONS: module Global at 0x00c5d9ac declared :TList (slots 0x44 AddLast, 0x70 Count,
' 0x50 RemoveFirst); module Global at 0x00c5b2bc declared :Int (stored into frametime).
' FUN_004a8f20 = _bbObjectNew with TPitchMark's class table -> `New TPitchMark`.
	Function AddPitchMark(a0:Int,a1:Int,a2:Int,a3:Int,a4:Float)
		'!Global g_pitchMarks:TList
		'!Global g_frameTime:Int
		Local p:TPitchMark = New TPitchMark
		p.x = a0
		p.y = a1
		p.a = a4
		p.rot = a2
		p.frm = a3
		p.frametime = g_frameTime
		g_pitchMarks.AddLast(p)
		If g_pitchMarks.Count() > 200 Then g_pitchMarks.RemoveFirst()
	End Function
