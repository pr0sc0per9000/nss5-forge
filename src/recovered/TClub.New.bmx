' TClub.New
' VA 0x004bfdbd   146 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (146/146, original length from Ghidra's inventory)
' Assumes one module Global g_clubs:TList (0x00c59a44); original name unrecoverable.
' The Super (TBase_Team) constructor, the class-table store and the Null/""/0 field
' initialisations are all compiler-emitted. Same "If Not <global>" form as TMyGfxModes.New.
	Method New()
		'!Global g_clubs:TList
		If Not g_clubs Then g_clubs = CreateList()
		g_clubs.AddLast(Self)
	End Method
