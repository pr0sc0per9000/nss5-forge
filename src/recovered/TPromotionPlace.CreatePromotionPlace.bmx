' TPromotionPlace.CreatePromotionPlace
' VA 0x00525e1b   192 bytes   vtable slot 0x30   sig ($)i
' byte-identical vs NSS5.exe (192/192, original length from Ghidra's inventory, mode=reloc)
' FUN_00505BCB is the recovered module Function NextFieldInt(String Var, String); the
'   separator literal at 0x00C6FCC0 is a single TAB, so "~t".
' slot 0x44 on TPromotionPlace = AddToParentLists().

	Function CreatePromotionPlace:Int(a0:String)
		Local p:TPromotionPlace = New TPromotionPlace
		p.parentid = NextFieldInt(a0, "~t")
		p.place = NextFieldInt(a0, "~t")
		p.promotiontoid = NextFieldInt(a0, "~t")
		p.AddToParentLists()
	End Function
