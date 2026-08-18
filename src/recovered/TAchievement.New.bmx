' TAchievement.New
' VA 0x0058d0ff   132 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (132/132, original length from Ghidra's inventory)
' assumes module global:  Global g_achievements:TList  (0x00c6e808)
' Super.New, the vtable store and the id/index/txt field defaults are compiler-emitted.
' `If Not g_achievements` is load-bearing -- see TContinent.SelectById.
' relies on the inferred BRL name _brl_linkedlist_CreateList at 0x005b40bf

	Method New:Int()
		'!Global g_achievements:TList
		If Not g_achievements Then g_achievements = CreateList()
		g_achievements.AddLast(Self)
	End Method
