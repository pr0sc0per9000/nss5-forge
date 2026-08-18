' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH never
' certifies the text -- see docs/reference/codegen-patterns.md 13.2.
' TScreen_EditMenu.ButtonQuit
' VA 0x0052828b   96 bytes   vtable slot 0x50   sig ()i
' byte-identical vs NSS5.exe (96/96, original length from Ghidra's inventory, mode=reloc)
' Assumptions: one module Global 0x00C64D1C declared :TButton (per globals_final.tsv
' construction site); field 0x3c is TGadget.hidden. PTR_FUN_00C61CC0 resolves to
' TScreen class table + 0x94 = TScreen.DoMessage($,i,i)i; PTR_FUN_00C64EBC resolves to
' TScreen_EditMenu + 0x54 = SaveMasterFiles(i)i, a sibling Function so it is written
' unqualified. FUN_004A4620 is End. String literal contents do not show up in the
' code bytes: their .rdata addresses relocate.
	Function ButtonQuit:Int()
		'!Global g_editmenu_btn:TButton
		If g_editmenu_btn.hidden = 0
			If TScreen.DoMessage(GetText("CMESSAGE_SAVEMASTERFILES"),1,0) Then SaveMasterFiles(0)
		EndIf
		If TScreen.DoMessage("Quit?",1,0) Then End
	End Function
