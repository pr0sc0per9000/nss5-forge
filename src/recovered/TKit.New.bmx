' TKit.New
' VA 0x004DA693   77 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (77/77, original length from Ghidra's inventory)
' EMPTY body. The 10 bytes beyond a plain field-default prologue are
' 'push 0x18 / push <String classtable> / call bbArrayNew' -- the field newcol is
' declared 'Field newcol:String[24]', a sized-array field initialiser.
' Recovered via the '!Field harness pragma.
' harness mode=reloc: absolute addresses (class tables, bbNullObject, string and
' array constants) differ by construction between probe and NSS5.exe.
	Method New()
		'!Field newcol:String[24]
	End Method
