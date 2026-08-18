' TPole.New
' VA 0x00583867   52 bytes   vtable slot 0x10   sig ()i   KIND=Method, class-table slot 0x10
' byte-identical vs NSS5.exe (52/52, original length from Ghidra's inventory, mode=reloc)
' ASSUMPTIONS
'   body is EMPTY -- Super.New (TTrainingObject.New) and every field store are compiler-emitted
'   field default Field colour:String = "FFFF00"; literal READ OUT OF THE EXE at 0x00C725B8
'     (the byte match masks the address, so the text is proved by check_literals.py,
'      not by the oracle)
	Method New()
		'!Field colour = "FFFF00"
	End Method
