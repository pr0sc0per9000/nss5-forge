' TTarget.Clear
' VA 0x005846b6   32 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (32/32, original length from Ghidra's inventory)
' assumes module global:  Global g_Object813:TList   (0x00c6d568, globals_named.tsv; the
' declared TList type is load-bearing -- slot 0x74 is TList.Remove(:Object)i)
	Method Clear:Int()
		'!Global g_Object813:TList
		g_Object813.Remove(Self)
	End Method
