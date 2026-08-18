' TScreen_Clubs.ButtonDelete
' VA 0x0052ce45   120 bytes   vtable slot 0x48   sig ()i
' byte-identical vs NSS5.exe (120/120, original length from Ghidra's inventory)
' assumptions: Global 0x00c65240 declared TTable. globals_final flags this VA as a
'   CONFLICT (TButton=1 construction site, TTable=1); slot 0xd8 = TTable.GetSelectedText(i)$
'   resolves only on TTable, so TTable is the one used here.
' 0x00c59e0c = TClub classtable+0x60 -> TClub.SelectById(i):TClub
' FUN_004a7130 = _bbStringToInt, FUN_004a75b0 = _bbStringReplace (runtime_helpers.tsv)
' piVar2[4] = +0x10 = TBase_Team.name:$ (TClub extends TBase_Team)
' slot 0x44 on TClub = TClub.Destroy(); 0x00c6539c = this Type's own classtable+0x34.
' 0x00c83664 = "CMESSAGE_DELETECLUB", 0x00c8364c = "$club".
	Function ButtonDelete:Int()
		'!Global g_clubtable:TTable
		Local c:TClub = TClub.SelectById(Int(g_clubtable.GetSelectedText(0)))
		If TScreen.DoMessage(GetText("CMESSAGE_DELETECLUB").Replace("$club", c.name), 1, 0)
			c.Destroy()
			SetUpScreen()
		EndIf
	End Function
