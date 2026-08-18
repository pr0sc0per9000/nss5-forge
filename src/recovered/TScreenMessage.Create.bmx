' TScreenMessage.Create
' VA 0x0056fe5c   235 bytes   vtable slot 0x30   sig (i,i,$,i,:TBitmapFont,:TImage,f,$)i
' byte-identical vs NSS5.exe (235/235, original length from Ghidra's inventory)
' Globals: 0x00C6EFE4 Int screen width, 0x00C6EFE8 Int screen height, 0x00C6EFD4 Int
' match clock, 0x00C6EFD8 Int paused-ms offset. 0x005B9xxx timeGetTime is MilliSecs().
' The object is constructed and populated but never stored -- the original really does
' `Return 0` and drops it.
	Function Create:Int(a0:Int, a1:Int, a2:String, a3:Int, a4:TBitmapFont, a5:TImage, a6:Float, a7:String)
		'!Global g_scrw:Int
		'!Global g_scrh:Int
		'!Global g_matchtime:Int
		'!Global g_pausedms:Int
		If a0 + a1 = 0
			a0 = g_scrw / 2
			a1 = g_scrh / 5 * 4
		EndIf
		Local m:TScreenMessage = New TScreenMessage
		m.x = a0
		m.y = a1
		m.message = a2
		m.starttime = MilliSecs() - g_pausedms
		m.delaytime = a3
		m.finishtime = g_matchtime + a3
		m.alfa = 1.0
		m.bmfnt = a4
		m.img = a5
		m.imgScale = a6
		m.colour = a7
		Return 0
	End Function
