' TPhotographer.New
' VA 0x004ea41f   80 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (80/80, original length from Ghidra's inventory)
' assumes module global:  Global g_Object77:TList   (0x00c5db1c; TList is load-bearing --
' slot 0x44 is TList.AddLast(:Object):TLink)
' the five field stores in the decompilation are bcc's implicit field initialisation, not source.
	Method New:Int()
		'!Global g_Object77:TList
		g_Object77.AddLast(Self)
	End Method
