' TScreen.New
' VA 0x0051005a   195 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (195/195, original length from Ghidra's inventory, mode=reloc)
' assumptions: TScreen field +0x1c = lHelp:TList; module Global 0x00c616fc is :TList
'              (the registry of all screens); FUN_005b40bf = CreateList (alias set
'              CreateList|CreateMap|TGNetHost.Create -- CreateList, because the result is
'              used with TList.AddLast at slot 0x44).
'
' Ghidra's stores of 0x005c7d40 (the empty string) into +0x8, of bbNullObject into
' +0xc/+0x10/+0x1c and of FUN_005b95d0 (the empty function) into +0x14/+0x18 are bcc's
' compiler-generated default field initialisation, not source.
'
' `If Not g` rather than `If g = Null` -- see TContinent.New for the 9-byte reason.
	Method New:Int()
		'!Global g_screens:TList
		Self.lHelp = CreateList()
		If Not g_screens Then g_screens = CreateList()
		g_screens.AddLast(Self)
	End Method
