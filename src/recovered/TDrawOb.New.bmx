' TDrawOb.New
' VA 0x004cd2bb   224 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (224/224, original length from Ghidra's inventory, mode=reloc)
' Global: 0x00C5AF6C g_drawobs:TList.
' All the field stores Ghidra shows (x/y/z/z2 = 0, img = Null, col/txt/txt2 = "") are bcc's
' automatic default init of the declared Fields and are NOT written in source; likewise the
' DAT_005C9C84 / DAT_005C7D44 increments, which are bbNullObject / empty-string refcounts.
' 0x005B40BF is the CreateList alias, confirmed by the TList.AddLast at slot 0x44 that follows.
' The Null test is the 21-byte `If Not` form; `= Null` gives 215.
	Method New:Int()
		'!Global g_drawobs:TList
		If Not g_drawobs Then g_drawobs = CreateList()
		g_drawobs.AddLast(Self)
	End Method
