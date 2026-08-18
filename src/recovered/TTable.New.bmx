' TTable.New
' VA 0x00515f5c   119 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (119/119, original length from Ghidra's inventory)
' assumptions: the body is EMPTY. Everything the decompilation shows is bcc's own
'              Super.New + class-table store + default field init, in field-declaration
'              order. The one non-default value is `showheadings = 1`, and that is a FIELD
'              INITIALISER (emitted inside the Type declaration, ahead of any body
'              statement), carried here by the '!Field pragma.
'              `highlightcol = &PTR_PTR_005c7d40` is the empty string -- ordinary String
'              default init, not source. `fRet = FUN_005b95d0` is bcc's default init for
'              a ()i function-pointer field.
	'!Field showheadings = 1
	Method New()
	End Method
