' TPitchMark.ResetPitchMarks
' VA 0x004ea1c6   104 bytes   vtable slot 0x34   sig ()i
' byte-identical vs NSS5.exe (104/104, original length from Ghidra's inventory, mode=reloc)
' assumes module Globals (names ours, types load-bearing):
'   Global g_pitchmarks:TList  (0x00C5D9AC, slot 0x34 = TList.Clear)
'   Global g_pm_x:Int          (0x00C5D658)
' PTR_FUN_00C5DB10 = TPitchMark class table + 0x38 -> sibling Function
'   AddPitchMark(i,i,i,i,f), so it is written unqualified. 0x3EB33333 = 0.35.
'!Global g_pitchmarks:TList
'!Global g_pm_x:Int

	Function ResetPitchMarks:Int()
		g_pitchmarks.Clear()
		AddPitchMark(0,0,0,0,0.35)
		AddPitchMark(0,g_pm_x,0,0,0.35)
		AddPitchMark(0,-g_pm_x,0,0,0.35)
	End Function
