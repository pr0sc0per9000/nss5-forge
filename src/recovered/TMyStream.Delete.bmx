' TMyStream.Delete
' VA 0x0050831C   32 bytes   vtable slot 0x14
' byte-identical vs NSS5.exe (32/32, original length from Ghidra's inventory)
' mode=reloc, reloc_masked=2, one of them the compiler-emitted tail call into
' TStreamWrapper.Delete (0x005B78F9). brl_functions.tsv named that address
' __brl_socketstream_TSocketStream_Delete -- a single WRONG name, the dangerous shape of
' section 3b. extracted/brl_type_methods.tsv corrects it from reflection.
'
' Body EMPTY -- entirely compiler-generated teardown chaining to the BRL Super
' (section 10.4).

	'!Field oldversion = -1

	Method Delete()
	End Method
