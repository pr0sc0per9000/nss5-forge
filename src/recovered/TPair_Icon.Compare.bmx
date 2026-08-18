' TPair_Icon.Compare
' VA 0x00579c31   112 bytes   vtable slot 0x1c   sig (:Object)i
' byte-identical vs NSS5.exe (112/112, original length from Ghidra's inventory)
' global 0x00c6c9e4 assumed Int; the downcast is recomputed for each comparison (bcc does no CSE). Super.Compare resolves to Object.Compare / bbObjectCompare.
' Parameter names are not recoverable from the binary; a0/a1/... as emitted by the harness.
	Method Compare:Int(a0:Object)
		'!Global g_pair_icon_int:Int
		If a0 = Self Then Return 0
		Select g_pair_icon_int
			Case 5
				If TPair_Icon(a0).randno < randno Then Return 1
				If TPair_Icon(a0).randno > randno Then Return -1
		End Select
		Return Super.Compare(a0)
	End Method
