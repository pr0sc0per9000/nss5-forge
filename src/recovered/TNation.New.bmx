' TNation.New
' VA 0x004BD584   146 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (146/146, original length from Ghidra's inventory, mode=reloc)
'
' The class-pointer store, the Super New call and the field initialisers at +0x60..+0x70 are all
' compiler-generated -- they come from TNation's own Field declarations, not from source.
' 0x00C596F0 is the master TNation TList. The allocation is `CreateList()`
' (E8 to 0x005B40BF = _brl_linkedlist_CreateList in the alias set), NOT `New TList`.
' The guard is `If Not g` (setne/movzx/cmp 0), not the fused `If g = Null`.
' TList + 0x44 = AddLast(:Object):TLink.
' Module Globals declared by this body (names are ours; the TYPES are load-bearing):
'   Global g_nations:TList
	Method New()
		'!Global g_nations:TList
		If Not g_nations Then g_nations = CreateList()
		g_nations.AddLast(Self)
	End Method
