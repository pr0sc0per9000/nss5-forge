' TTeamPool.New
' VA 0x00526468   77 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (77/77, original length from Ghidra's inventory)
' CreateList() is BRL.LinkedList at 0x005B40BF (extracted/brl_functions_inferred.tsv).
' harness mode=reloc.

	Method New:Int()
		list = CreateList()
	End Method
