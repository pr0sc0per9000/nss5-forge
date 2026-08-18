' TReplay.New
' VA 0x00503A0A   368 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (368/368, original length from Ghidra's inventory)
' Everything else the original New does (name/teamname1/teamname2 = "", every
' Int field = 0, the four TKitStrings fields and the three TList fields = Null)
' is bcc's automatic field-default prologue, NOT source. Only these four stores
' carry the release-the-old-value sequence, which is what identifies them as
' written assignments rather than field initialisers.
	Method New()
		kit1cols = New TKitStrings
		kit2cols = New TKitStrings
		keeperkit1cols = New TKitStrings
		keeperkit2cols = New TKitStrings
	End Method
