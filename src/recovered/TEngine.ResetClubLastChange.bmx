' TEngine.ResetClubLastChange
' VA 0x004d3998   62 bytes   vtable slot 0x80   sig ()i
' byte-identical vs NSS5.exe (62/62, original length from Ghidra's inventory)
' assumes module global:  Global g_Object17:TTeam
' assumes module global:  Global g_Object18:TTeam
' globals 0x00c5b218/0x00c5b21c typed TTeam from the +0x20 field access

	Function ResetClubLastChange:Int()
		'!Global g_Object17:TTeam
		'!Global g_Object18:TTeam
		If g_Object17 <> Null Then g_Object17.lastchangeplayer = 0
		If g_Object18 <> Null Then g_Object18.lastchangeplayer = 0
	End Function
