' TScreen_EditCompetition.ButtonNextComp
' VA 0x0053247f   141 bytes   vtable slot 0x48   sig ()i
' byte-identical vs NSS5.exe (141/141, original length from Ghidra's inventory)
' assumptions / Globals declared:
'   0x00c6099c TList     (globals_final has g_Object99:Object with no call-site typing;
'                         slot 0x8c = TList.ObjectEnumerator fixes it)
'   0x00c65720 TCompetition (globals_final flags this VA CONFLICT TScreen=1;TCompetition=1 --
'                         it is read as `+8` = TCompetition.id here, so TCompetition)
' 0x00c658f0 = this Type's own classtable+0x4c -> UpdateComp(), unqualified.
' 0x00c616dc = TCompetition classtable+0x11c -> TCompetition.SortListBy(i,i)i.
' 0x00c658d8 = this Type's own classtable+0x34 -> SetUpScreen(i,$), unqualified.
' EachIn class table 0x00c615c0 = TCompetition; puVar3[2] = +8 = TCompetition.id.
	Function ButtonNextComp:Int()
		'!Global g_comps:TList
		'!Global g_curcomp:TCompetition
		UpdateComp()
		TCompetition.SortListBy(1, 1)
		For Local c:TCompetition = EachIn g_comps
			If c.id > g_curcomp.id
				SetUpScreen(c.id, "")
				Return 0
			EndIf
		Next
	End Function
