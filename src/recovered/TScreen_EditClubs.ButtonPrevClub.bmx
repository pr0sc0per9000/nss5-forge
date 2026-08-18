' TScreen_EditClubs.ButtonPrevClub
' VA 0x0052E86C   141 bytes   vtable slot 0x3c   sig ()i
' byte-identical vs NSS5.exe (141/141, original length from Ghidra's inventory)
' ASSUMPTIONS: module Global 0x00C59A44 :TList, 0x00C653C4 :TClub.
' UpdateClub() and SetUpScreen() are TScreen_EditClubs' own Functions, called unqualified -- bcc emits call [classtable+slot] either way here because the caller is itself a Function.
' TClub.SortListBy resolved to TClub+0x94 on both sides. harness mode=reloc.

	Function ButtonPrevClub:Int()
		'!Global g_clubs:TList
		'!Global g_editclub:TClub
		UpdateClub()
		TClub.SortListBy(1, 0)
		For Local c:TClub = EachIn g_clubs
			If c.id < g_editclub.id Then
				SetUpScreen(c.id, "")
				Return 0
			EndIf
		Next
	End Function
