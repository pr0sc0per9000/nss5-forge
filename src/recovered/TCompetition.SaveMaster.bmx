' TCompetition.SaveMaster
' VA 0x0050A4CD   322 bytes   vtable slot 0x3c   sig (i,i)i   KIND=Function (static)
' byte-identical vs NSS5.exe (322/322, original length from Ghidra's inventory, mode=reloc)
' assumptions: 0x00C61CC0 = TScreen+0x94 = TScreen.DoMessage($,i,i); 0x00C616DC / 0x00C61604
' / 0x00C61600 are TCompetition+0x11C / 0x44 / 0x40 = SortListBy / WriteDataMobile /
' WriteData -- own Type, so they are written without a prefix.
' BRL callees from brl_functions.tsv: FileType 0x005B5A99, StripDir 0x005B5578,
' WriteFile 0x005B65FC; 0x004A75B0 is _bbStringReplace, 0x004A7C20 _bbStringConcat.
' 0x004C5549 is module Function GetText.
'
' GLOBALS TABLE CORRECTION: globals_final.tsv calls 0x00C6E950 an Int ("read-only int
' slot"). It is a String -- it is the left operand of _bbStringConcat against
' "GameMedia/Data/Competitions.csv". Section 11.2's rule (trust the code) applies.
'
' The three-term guard is ONE statement: (a0 And FileType=1) And DoMessage=0 -> Return 0.
' `If Not s`, not `If s = Null` -- the setne/movzx pair is present (10.3).
	Function SaveMaster:Int(a0:Int, a1:Int)
		'!Global g_datapath:String
		Local path:String = g_datapath + "GameMedia/Data/Competitions.csv"
		If a1 Then path = g_datapath + "GameMedia/Data/Mobile/Competitions.txt"
		If a0 And FileType(path) = 1 And TScreen.DoMessage(GetText("CMESSAGE_OVERWRITEFILE").Replace("$filename", StripDir(path)), 1, 0) = 0 Then Return 0
		Local s:TStream = WriteFile("utf8::" + path)
		If Not s
			TScreen.DoMessage(GetText("CMESSAGE_FILENOTCREATED").Replace("$filename", StripDir(path)), 0, 0)
			Return 0
		EndIf
		SortListBy(1, 1)
		If a1
			WriteDataMobile(s, 1)
		Else
			WriteData(s, 1)
		EndIf
	End Function
