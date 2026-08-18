' TClub.NewClub
' VA 0x004c0980   121 bytes   vtable slot 0x4c   sig ():TClub
' byte-identical vs NSS5.exe (121/121, original length from Ghidra's inventory)
' assumes module global:  Global g_clubs:TList  (0x00c59a44)
' the comparison direction is load-bearing: `If c.id > maxid` emits cmp [eax+0xc],esi / jle,
' whereas `If maxid < c.id` emits the mirrored compare and diverges at byte 67

	Function NewClub:TClub()
		'!Global g_clubs:TList
		Local maxid:Int = 1
		For Local c:TClub = EachIn g_clubs
			If c.id > maxid Then maxid = c.id
		Next
		Local n:TClub = New TClub
		n.id = maxid + 1
		Return n
	End Function
