' TCard.CreateCard
' VA 0x00577b5e   216 bytes   vtable slot 0x34   sig (i,$):TCard
' byte-identical vs NSS5.exe (216/216, original length from Ghidra's inventory)
' Global: 0x00C6E950 :String, the install-path prefix -- the same g_pathPrefix that
' src/recovered_module/LoadImageChecked.bmx already declares. Literals read out of the
' image. Concat order is a0 then a1 (push order proves it: Str(a0) is pushed between
' "GameMedia/..." and "_"), and the trailing -1 is LoadImageChecked's flags argument.
	Function CreateCard:TCard(a0:Int, a1:String)
		'!Global g_pathPrefix:String
		Local c:TCard = New TCard
		c.randno = Rand(9999, 1)
		c.num = a0
		c.suit = a1
		c.img = LoadImageChecked(g_pathPrefix + "GameMedia/Images/Casino/BlackJack/" + a0 + "_" + a1 + ".png", -1)
		MidHandleImage(c.img)
		Return c
	End Function
