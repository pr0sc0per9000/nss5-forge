' TTable.HideColumnHeadings
' VA 0x00517db1   51 bytes   vtable slot 0xf8   sig ()i
' byte-identical vs NSS5.exe (51/51, original length from Ghidra's inventory)
' assumes module global:  Global g_table_int03:Int
' global 0x00c625f0

	Method HideColumnHeadings:Int()
		'!Global g_table_int03:Int
		showheadings = 0
		h = numdisplayitems * (ih + g_table_int03)
	End Method
