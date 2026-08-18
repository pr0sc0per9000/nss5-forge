' TPromotionPlace.Compare
' VA 0x00526371   247 bytes   vtable slot 0x1c   sig (:Object)i
' byte-identical vs NSS5.exe (247/247, original length from Ghidra's inventory)
' mode 'reloc': absolute addresses masked, emitted code identical
' module global assumed: Global g_promotionplace_int02:Int

	Method Compare:Int(a0:Object)
		'!Global g_promotionplace_int02:Int
		If a0 = Self Then Return 0
		Select g_promotionplace_int02
			Case 18
				If place > TPromotionPlace(a0).place Then Return 1
				If place < TPromotionPlace(a0).place Then Return -1
			Case 19
				If parentid > TPromotionPlace(a0).parentid Then Return 1
				If parentid < TPromotionPlace(a0).parentid Then Return -1
				If place > TPromotionPlace(a0).place Then Return 1
				If place < TPromotionPlace(a0).place Then Return -1
		End Select
		Return Super.Compare(a0)
	End Method
