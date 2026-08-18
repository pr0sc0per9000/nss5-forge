' TClub.GetStringArray
' VA 0x004C1C15   942 bytes   vtable slot 0x84   sig ()[]$
' byte-identical vs NSS5.exe (942/942, original length from Ghidra's inventory, mode=reloc)
'
' 17 String slots (bbArrayNew1D with 0x11); array data starts at +0x18, so [eax+0x18+4*i]
' is element i. 0x00C5D288 is the literal ""'s refcount word -- its increments are the
' retain half of `s[i] = ""`, not code.
' Related-record fields taken from the resolved objects: TClub + 0x20 = labelshortname,
' TNation + 0x18 = tla, TCompetition + 0x14 = labelname.
' 0x0050640C = module FormatDecimals(f,i)$.
	Method GetStringArray:String[]()
		Local s:String[] = New String[17]
		s[0] = Self.id
		s[1] = Self.name
		s[2] = Self.shortname
		s[3] = Self.tla
		s[4] = Self.nickname
		s[5] = Self.strength
		s[6] = ""
		If Self.rivalid1 <> 0 Then
			Local c:TClub = TClub.SelectById(Self.rivalid1)
			If c <> Null Then s[6] = c.labelshortname
		End If
		s[7] = ""
		If Self.rivalid2 <> 0 Then
			Local c:TClub = TClub.SelectById(Self.rivalid2)
			If c <> Null Then s[7] = c.labelshortname
		End If
		s[8] = ""
		If Self.rivalid3 <> 0 Then
			Local c:TClub = TClub.SelectById(Self.rivalid3)
			If c <> Null Then s[8] = c.labelshortname
		End If
		s[9] = ""
		If Self.nationid <> 0 Then
			Local n:TNation = TNation.SelectById(Self.nationid)
			If n <> Null Then s[9] = n.tla
		End If
		s[10] = ""
		If Self.leagueid <> 0 Then
			Local c:TCompetition = TCompetition.SelectById(Self.leagueid)
			If c <> Null Then s[10] = c.labelname
		End If
		s[11] = ""
		If Self.continentalcompid <> 0 Then
			Local c:TCompetition = TCompetition.SelectById(Self.continentalcompid)
			If c <> Null Then s[11] = c.labelname
		End If
		s[12] = ""
		If Self.bteamofid <> 0 Then
			Local c:TClub = TClub.SelectById(Self.bteamofid)
			If c <> Null Then s[12] = c.labelshortname
		End If
		s[13] = Self.stadiumname
		s[14] = Self.stadiumcapacity
		s[15] = FormatDecimals(Self.stadiumlongitude, 2)
		s[16] = FormatDecimals(Self.stadiumlatitude, 2)
		Return s
	End Method
