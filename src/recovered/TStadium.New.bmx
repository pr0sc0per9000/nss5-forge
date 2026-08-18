' TStadium.New
' VA 0x00527667   149 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (149/149, original length from Ghidra's inventory, mode=reloc)
' Assumptions: Global 0x00C64BC0 declared TList (globals_final.tsv says bare Object; the
'   call through slot 0x44 = TList.AddLast and the CreateList factory fix the type).
'   FUN_005B40BF is the CreateList|CreateMap|TGNetHost.Create alias set -- CreateList here,
'   confirmed by the following AddLast at slot 0x44 (codegen-patterns 10.8).
'   The six field stores Ghidra shows (id/name/nation/capacity/longitude/latitude) are
'   compiler default-init, not source. Guard is `If Not x`, not `If x = Null` (9 bytes).
'!Global g_stadiumlist:TList
	Method New()
		If Not g_stadiumlist
			g_stadiumlist = CreateList()
		End If
		g_stadiumlist.AddLast(Self)
	End Method
