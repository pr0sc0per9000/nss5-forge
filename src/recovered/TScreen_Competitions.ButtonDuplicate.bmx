' TScreen_Competitions.ButtonDuplicate
' VA 0x0052fe25   69 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (69/69, original length from Ghidra's inventory)
' harness mode=reloc.
' The Local `c` is load-bearing: the nested one-liner form pushes the "" argument
'   before evaluating the chain and comes out with the pushes in the wrong order.
' FUN_004a7130 = _bbStringToInt, emitted by Int(<String>).
' slots: TTable+0xd8 = GetSelectedText(i)$, TCompetition+0x38 = NewCompetition(i),
'   TScreen_EditCompetition+0x34 = SetUpScreen(i,$).
' module Globals assumed by this body (names ours, types load-bearing):
'   Global g_screencomps_table:TTable   ' 0x00c65588 (globals_final flags a
'     TButton/TTable construction conflict here; slot 0xd8 settles it as TTable)
	Function ButtonDuplicate:Int()
		'!Global g_screencomps_table:TTable
		Local c:TCompetition = TCompetition.NewCompetition(Int(g_screencomps_table.GetSelectedText(0)))
		TScreen_EditCompetition.SetUpScreen(c.id,"")
	End Function
