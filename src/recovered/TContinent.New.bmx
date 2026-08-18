' TContinent.New
' VA 0x0050887f   176 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (176/176, original length from Ghidra's inventory, mode=reloc)
' assumptions: module Global 0x00c6080c is :TList (the registry of all continents);
'              FUN_005b40bf is the alias set CreateList|CreateMap|TGNetHost.Create -- CreateList
'              here, since the result is used with TList.AddLast (slot 0x44).
'
' Everything Ghidra shows before the list code -- `param_1[2]=0`, five stores of the empty
' string constant 0x005c7d40 with refcount increments, `param_1[8]=0` -- is bcc's
' compiler-generated default field initialisation for TContinent's Int and String fields.
' None of it is written in source.
'
' The guard must be `If Not g` and not `If g = Null`: `= Null` folds into a single
' `cmp dword [g], bbNullObject` (10 bytes), while `Not <object>` coerces through
' setne/movzx first (19 bytes). That is the whole 9-byte gap.
	Method New:Int()
		'!Global g_continents:TList
		If Not g_continents Then g_continents = CreateList()
		g_continents.AddLast(Self)
	End Method
