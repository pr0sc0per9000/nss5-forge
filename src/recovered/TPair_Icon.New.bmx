' TPair_Icon.New
' VA 0x00579842   99 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (99/99, original length from Ghidra's inventory)
' ASSUMPTION: module Global at 0x00c6c9e0 declared :TList (selects slot 0x44 = TList.AddLast).
' The zeroing of id/imgId/randno/picked and the bbNullObject increfs for back/front are
' compiler-generated field initialisation.
	Method New()
		'!Global g_pairIcons:TList
		g_pairIcons.AddLast(Self)
	End Method
