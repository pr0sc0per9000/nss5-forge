' TTeam.New
' VA 0x004DD1B5   160 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (160/160, original length from Ghidra's inventory)
' The body is EMPTY: all 160 bytes are bcc's own field-default prologue. The ONLY
' non-zero default is newstarselno at +0x3c, where the original stores 0xFFFFFFFF
' rather than 0 -- i.e. the Type declares 'Field newstarselno:Int = -1'. bcc emits a
' field initialiser inside the Type declaration, ahead of every body statement, so no
' body statement can reproduce it; recovered via the '!Field harness pragma.
' harness mode=reloc: absolute addresses (class tables, bbNullObject, string and
' array constants) differ by construction between probe and NSS5.exe.
	Method New()
		'!Field newstarselno = -1
	End Method
