' GetText  -- module-level Function (no Type)
' VA 0x004c5549   22 bytes   sig ($)$
' byte-identical vs NSS5.exe (22/22, original length from Ghidra's inventory, mode=reloc)
'
' NAME IS OURS. Module-level Functions carry no BBDebugScope record, so the original
' name is unrecoverable -- exactly like module Globals. Names have no effect on codegen.
' Identified by its callers: 101 game functions call 0x004C5549, which forwards straight
' to TLocale.GetLocaleText (class table TLocale + 0x38). It is the global text-lookup
' every UI string passes through.
	Function GetText:String(a0:String)
		Return TLocale.GetLocaleText(a0)
	End Function
