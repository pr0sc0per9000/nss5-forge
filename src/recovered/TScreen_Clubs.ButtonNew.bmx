' TScreen_Clubs.ButtonNew
' VA 0x0052cebd   37 bytes   vtable slot 0x4c   sig ()i
' byte-identical vs NSS5.exe (37/37, original length from Ghidra's inventory)
' the intermediate Local is load-bearing: inlining the call as
' TScreen_EditClubs.SetUpScreen(TClub.NewClub().id, "...") pushes the string constant
' BEFORE calling NewClub and diverges at byte 3.
' the string argument is an inline literal (push imm32 of the string object at
' 0x00c5d284), not a Global; its text is not recoverable from codegen.

	Function ButtonNew:Int()
		Local c:TClub = TClub.NewClub()
		TScreen_EditClubs.SetUpScreen(c.id, "")
	End Function
