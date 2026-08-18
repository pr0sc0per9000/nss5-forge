' TTableData.New
' VA 0x00526a76   145 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (145/145, original length from Ghidra's inventory)
' Everything before the Rand is bcc's own field zero-init; field [0xd] = +0x34 = randno.
' FUN_0059F089 is _brl_random_Rand; the (9999,1) in the decompilation is Rand's
' defaulted second argument, so the source is Rand(9999).
	Method New()
		randno = Rand(9999)
	End Method
