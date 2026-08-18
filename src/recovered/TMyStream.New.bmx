' TMyStream.New
' VA 0x005082F3   41 bytes   vtable slot 0x10
' byte-identical vs NSS5.exe (41/41, original length from Ghidra's inventory)
' mode=reloc, reloc_masked=2: the classtable store, and the compiler-emitted Super call
' into TStreamWrapper.New (0x005B78CC). brl_functions.tsv names 0x005B78CC
' __brl_map_TMapEnumerator_New, which is wrong and prevents that call being masked;
' extracted/brl_type_methods.tsv names it from NSS5.exe's own reflection data.
'
' The body is EMPTY. Everything here is compiler-generated (section 3d). The only
' source-level fact is the field initialiser: oldversion defaults to -1, not 0, which is
' the `mov dword [ebx+0xc],0xffffffff` at +0x19.

	'!Field oldversion = -1

	Method New()
	End Method
