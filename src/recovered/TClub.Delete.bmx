' TClub.Delete
' VA 0x004BFE4F   51 bytes   vtable slot 0x14   sig ()i
' byte-identical vs NSS5.exe (51/51, original length from Ghidra's inventory)
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.
' The user body is EMPTY. All 51 bytes are bcc's generated Delete epilogue:
' release the single object field (nickname:$ at +96) then chain to TBase_Team.Delete.

	Method Delete:Int()
		' (empty -- the whole body is compiler-generated: release nickname, then Super.Delete)
	End Method
