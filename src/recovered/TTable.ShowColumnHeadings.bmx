' TTable.ShowColumnHeadings
' VA 0x00517d67   74 bytes   vtable slot 0xf4   sig ()i
' byte-identical vs NSS5.exe (74/74, original length from Ghidra's inventory)
' assumes module global:  Global g_table_int03:Int
' global 0x00c625f0; the second statement recomputes (ih+global) -- bcc does no CSE

	Method ShowColumnHeadings:Int()
		'!Global g_table_int03:Int
		showheadings = 1
		h = numdisplayitems * (ih + g_table_int03)
		h = h + (ih + g_table_int03)
	End Method
