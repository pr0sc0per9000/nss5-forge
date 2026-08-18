' TTrainingObject.New
' VA 0x00582c76   152 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (152/152, original length from Ghidra's inventory)
' assumptions: 0x00c6d568 declared TList (globals_final has g_Object813:Object, untyped;
'   FUN_005b40bf is the CreateList/CreateMap/TGNetHost.Create alias set and slot 0x44 on the
'   result is TList.AddLast, which picks CreateList).
' The non-zero field initialisers live in the Type declaration, not in New:
'   alive:Int = 1 (+0x18), alph:Float = 1.0 (+0x1c), scl:Float = 1.0 (+0x20).
'   The +0x8/+0xc/+0x10/+0x14 zero stores are the compiler's default field init.
' The guard is `If Not <object>` -- the object materialises through cmp/setne/movzx;
'   `If g = Null Then ...` measures 143 bytes, nine short.
	Method New()
		'!Field alive = 1
		'!Field alph = 1.0
		'!Field scl = 1.0
		'!Global g_trainobjs:TList
		If Not g_trainobjs Then g_trainobjs = CreateList()
		g_trainobjs.AddLast(Self)
	End Method
