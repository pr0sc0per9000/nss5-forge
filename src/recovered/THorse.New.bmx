' THorse.New
' VA 0x0058A19B   377 bytes   vtable slot 0x10   sig ()i   KIND=Method
' byte-identical vs NSS5.exe (377/377, original length from Ghidra's inventory, mode=reloc)
' Assumptions: 0x00C6E294 g_allhorses:TList (slot 0x44 = TList.AddLast) and 0x00C6E298 a
' second TList that is created here but not appended to.
' Only the six NON-default field initialisers are declared; every zero / "" / Null store in
' the original is bcc's own default init and must not be written.
' 8000.0 read from .rdata at 0x00C93DE8 and 0x00C93DEC; the array type descriptor at
' 0x00C93DF0 begins with 'i', so form is Int[] and not String[].
	Method New()
		'!Global g_allhorses:TList
		'!Global g_horselist2:TList
		'!Field x :Float = 8000.0
		'!Field oldx :Float = 8000.0
		'!Field randno :Int = Rand(1000,1)
		'!Field form :Int[] = New Int[5]
		'!Field lastran :Int = -1000
		'!Field racenum :Int = -1
		If Not g_allhorses Then g_allhorses = CreateList()
		If Not g_horselist2 Then g_horselist2 = CreateList()
		g_allhorses.AddLast(Self)
	End Method
