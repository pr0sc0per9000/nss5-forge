' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH never
' certifies the text -- see docs/reference/codegen-patterns.md 13.2.
' TScreen_EditMenu.ButtonSave
' VA 0x00528219   57 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (57/57, original length from Ghidra's inventory, mode=reloc)
' Assumptions: 0x00C61CC0 = TScreen class table + 0x94 = TScreen.DoMessage($,i,i)i;
' 0x00C64EBC = TScreen_EditMenu class table + 0x54 = SaveMasterFiles(i)i, a sibling
' Function of this same Type so it is written unqualified. FUN_004C5549 = GetText.
' Literals relocate; their contents do not affect the emitted code bytes.
	Function ButtonSave:Int()
		If TScreen.DoMessage(GetText("CMESSAGE_SAVEMASTERFILES"), 1, 0)
			SaveMasterFiles(0)
		EndIf
	End Function
