' TPlayerColours.New
' VA 0x004DD10A   59 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (59/59, original length from Ghidra's inventory)
' An empty body scores 48/59: bcc emits field initialisers inside the Type declaration,
' so no body statement can produce them. Expressed with the '!Field pragma it is 59/59.
' Field defaults: skin:Int = 2, hair:Int = 1, boots:String = "444444"
' (string constant at 0x00C752AC; its address is a relocation, so the literal text is
'  not pinned by the byte match -- it is read out of the PE's BBString header).
	Method New()
		'!Field skin = 2
		'!Field hair = 1
		'!Field boots = "444444"
	End Method
