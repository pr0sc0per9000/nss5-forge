' TPromotionPlace.NewPromotionPlace
' VA 0x00525edb   60 bytes   vtable slot 0x34   sig (i,i,i)i
' byte-identical vs NSS5.exe (60/60, original length from Ghidra's inventory)
' AddToParentLists is TPromotionPlace slot 0x44

	Function NewPromotionPlace:Int(a0:Int, a1:Int, a2:Int)
		Local p:TPromotionPlace = New TPromotionPlace
		p.parentid = a0
		p.place = a1
		p.promotiontoid = a2
		p.AddToParentLists()
	End Function
