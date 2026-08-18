' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH never
' certifies the text -- see docs/reference/codegen-patterns.md 13.2.
' TScreen_EditClubs.ButtonQuit
' VA 0x0052E836   54 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (54/54, original length from Ghidra's inventory)
' Assumptions:
'   module Global at 0x00C653C0 declared String (g_editclubs_caller here; the original
'   name is unrecoverable and does not affect codegen).
'   Only the string literal's address appears in the code, and that address is
'   relocation-masked; any literal emits the same bytes.
'   PTR_FUN_00C6539C = TScreen_Clubs classtable(0x00C65368) + 0x34   -> TScreen_Clubs.SetUpScreen
'   PTR_FUN_00C65C3C = TScreen_ContinentalComps classtable(0x00C65C08) + 0x34 -> SetUpScreen
'   Shape: a String SELECT, not If/Else. Select evaluates the subject into EAX up front
'   (A1 ..) and terminates EVERY case body with a jmp-to-end, including the last -- that
'   redundant `EB 00` is what an If/Else form cannot produce.

	Function ButtonQuit:Int()
		'!Global g_editclubs_caller:String
		Select g_editclubs_caller
			Case "continentalcomps"
				TScreen_ContinentalComps.SetUpScreen()
			Default
				TScreen_Clubs.SetUpScreen()
		End Select
	End Function
