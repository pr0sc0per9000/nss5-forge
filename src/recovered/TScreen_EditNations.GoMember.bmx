' TScreen_EditNations.GoMember
' VA 0x0052b289   76 bytes   vtable slot 0x4c   sig ()i
' byte-identical vs NSS5.exe (76/76, original length from Ghidra's inventory)
' ASSUMPTION: module Global 0x00c65090 declared TTable (slot 0xd8 = GetSelectedText(i)$).
' FUN_004a7130 is _bbStringToInt, i.e. the Int() around the String.
	Function GoMember:Int()
		' 0x00C65090, the members table, measured at 0x0052B28C `a19050c600 mov eax,[0xc65090]`;
' TScreen_EditNations.CreateScreen builds it as g_editnat_tblMembers. g_table is that
' same body's name for the DIFFERENT slot 0x00C65038, its tbl_details.
'!Global g_editnat_tblMembers:TTable
		Local c:TClub = TClub.SelectById(Int(g_editnat_tblMembers.GetSelectedText(0)))
		If c <> Null Then TScreen_EditClubs.SetUpScreen(c.id, "")
	End Function
