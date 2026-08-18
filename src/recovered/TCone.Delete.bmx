' TCone.Delete
' VA 0x00582EC4   32 bytes   vtable slot 0x14   sig ()i
' byte-identical vs NSS5.exe (32/32, original length from Ghidra's inventory)
' Body is empty; the 32 bytes are the compiler-generated super-Delete chain (class-table store + call TTrainingObject.Delete).
' harness mode=reloc.

	Method Delete:Int()
		' empty -- bcc emits only the destructor chain to TTrainingObject.Delete
	End Method
