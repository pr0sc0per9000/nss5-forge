' TMyGfxModes.New
' VA 0x00506c11   121 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (121/121, original length from Ghidra's inventory)
' Assumes one module Global g_gfxmodes:TList (0x00c60500); original name unrecoverable.
' CreateList is BRL.LinkedList (0x005B40BF, from brl_functions_inferred).
' "If Not g_gfxmodes" is required: "If g_gfxmodes = Null" emits a 10-byte
' cmp dword [mem],imm32 instead of the original's mov eax,[mem] and is 9 bytes short.
	Method New()
		'!Global g_gfxmodes:TList
		If Not g_gfxmodes Then g_gfxmodes = CreateList()
		g_gfxmodes.AddLast(Self)
	End Method
