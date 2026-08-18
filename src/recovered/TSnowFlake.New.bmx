' TSnowFlake.New
' VA 0x00505414   114 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (114/114, original length from Ghidra's inventory)
' The 12 field zero-stores are compiler-generated default init; only the AddLast is source.
' Globals: g_snowflakes:TList (0x00c60220 -- slot 0x44 is TList.AddLast)
	Method New()
		'!Global g_snowflakes:TList
		g_snowflakes.AddLast(Self)
	End Method
