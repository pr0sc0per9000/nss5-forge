' TScreen_EditContinents.UpdateCont
' VA 0x00528FEB   336 bytes   vtable slot 0x38   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (336/336, original length from Ghidra's inventory, mode=reloc)
' assumptions: Globals 0x00C64ED8..0x00C64EEC are the six TInputBox gadgets
' (slot 0x94 = TInputBox.GetText()$). 0x00505F6D is module Function ClampInt.
'
' GLOBALS TABLE CORRECTION: globals_final.tsv types 0x00C64EC4 as TScreen with a flagged
' construction-site CONFLICT (TScreen=1;TContinent=1). It is TContinent -- the five String
' stores land on +0x0C/+0x10/+0x14/+0x18/+0x1C and the Int on +0x20, which is exactly
' TContinent's name / tla / continentality / federationname / federationshortname / strength.
	Function UpdateCont:Int()
		'!Global g_editcont_cont:TContinent
		'!Global g_editcont_in1:TInputBox
		'!Global g_editcont_in2:TInputBox
		'!Global g_editcont_in3:TInputBox
		'!Global g_editcont_in4:TInputBox
		'!Global g_editcont_in5:TInputBox
		'!Global g_editcont_in6:TInputBox
		g_editcont_cont.name = g_editcont_in1.GetText()
		g_editcont_cont.tla = g_editcont_in2.GetText()
		g_editcont_cont.continentality = g_editcont_in3.GetText()
		g_editcont_cont.federationname = g_editcont_in4.GetText()
		g_editcont_cont.federationshortname = g_editcont_in5.GetText()
		Local s:Int = Int(g_editcont_in6.GetText())
		ClampInt(Varptr s, 10, 100)
		g_editcont_cont.strength = s
	End Function
