' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH on its own does
' not certify the text -- see docs/reference/codegen-patterns.md 13.2.
' TTraining.TimeUp
' VA 0x00581844   131 bytes   vtable slot 0x90   sig ()i
' byte-identical vs NSS5.exe (131/131, original length from Ghidra's inventory, mode=reloc)
' Assumptions: four module Globals, names ours. 0x00C6CF98 and 0x00C5B1FC are Ints
' (plain dword stores, no refcount traffic -- globals_final.tsv types 0x00C5B1FC as
' TPlayer, which the code contradicts). 0x00C6CFA4 and 0x00C6CFAC carry full retain/
' release traffic around the store, so they are Strings, not the Ints the table lists.
' FUN_004A7410 is _brl_retro_Lower; FUN_004C5549 is the verified module GetText.
' String literal contents are placeholders (their .rdata addresses relocate).
	Function TimeUp:Int()
		'!Global g_training_a:Int
		'!Global g_player_b:Int
		'!Global g_training_s1:String
		'!Global g_training_s2:String
		g_training_a = 2
		g_player_b = 11
		g_training_s1 = Lower(GetText("Time Up!"))
		g_training_s2 = GetText("CMESSAGE_TRAININGFAIL")
	End Function
