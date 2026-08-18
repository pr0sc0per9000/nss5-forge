' TCard.Compare
' VA 0x00577D3B   251 bytes   vtable slot 0x1c   sig (:Object)i
' byte-identical vs NSS5.exe (251/251, original length from Ghidra's inventory)
' mode 'reloc': absolute addresses masked, emitted code identical
' module global assumed: Global g_card_int01:Int

	Method Compare:Int(a0:Object)
		'!Global g_card_int01:Int
		Select g_card_int01
			Case 1
				If suit < TCard(a0).suit Then Return -1
				If suit > TCard(a0).suit Then Return 1
				If num < TCard(a0).num Then Return -1
				If num > TCard(a0).num Then Return 1
			Case 5
				If randno < TCard(a0).randno Then Return -1
				If randno > TCard(a0).randno Then Return 1
		End Select
		Return 0
	End Method
