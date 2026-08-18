' ============================================================================
'  NSS5 reconstruction - team data types
'
'  Field names, field ORDER and the inheritance relationship below are taken
'  verbatim from the BlitzMax reflection metadata inside NSS5.exe.
'  TBase_Team occupies offsets +8..+92; TClub and TNation both begin their own
'  fields at +96, which is what proves they Extend TBase_Team.
'  Do not reorder fields.
'
'  NOTE: this file is Include'd, not Import'ed. An included file inherits
'  SuperStrict and the Framework/Import set from its parent and must NOT
'  repeat them, or bcc reports "Expecting expression but encountered
'  'superstrict'".
' ============================================================================

Const KIT_HOME:Int   = 0
Const KIT_AWAY:Int   = 1
Const KIT_THIRD:Int  = 2
Const KIT_KEEPER:Int = 3

' ----------------------------------------------------------------------------
'  TKitStrings - one kit definition (style + four colours)
' ----------------------------------------------------------------------------
Type TKitStrings
	Field style:String
	Field shirtcol1:String
	Field shirtcol2:String
	Field shortscol:String
	Field sockscol:String

	Function Create:TKitStrings(style:String, c1:String, c2:String, sh:String, so:String)
		Local k:TKitStrings = New TKitStrings
		k.style     = style
		k.shirtcol1 = c1
		k.shirtcol2 = c2
		k.shortscol = sh
		k.sockscol  = so
		Return k
	End Function

	Method ToString:String()
		Return "style=" + style + " shirt=" + shirtcol1 + "/" + shirtcol2 + ..
			" shorts=" + shortscol + " socks=" + sockscol
	End Method
End Type

' ----------------------------------------------------------------------------
'  TBase_Team - shared base of TClub and TNation   (object offsets +8 .. +92)
' ----------------------------------------------------------------------------
Type TBase_Team
	Field randno:Int                        ' +8
	Field id:Int                            ' +12
	Field name:String                       ' +16
	Field shortname:String                  ' +20
	Field tla:String                        ' +24
	Field labelname:String                  ' +28
	Field labelshortname:String             ' +32
	Field strength:Int                      ' +36
	Field rivalid1:Int                      ' +40
	Field rivalid2:Int                      ' +44
	Field rivalid3:Int                      ' +48
	Field stadiumname:String                ' +52
	Field stadiumcapacity:Int               ' +56
	Field stadiumlongitude:Float            ' +60
	Field stadiumlatitude:Float             ' +64
	Field kitcolsHome:TKitStrings           ' +68
	Field kitcolsAway:TKitStrings           ' +72
	Field kitcolsThird:TKitStrings          ' +76
	Field kitcolsKeeper:TKitStrings         ' +80
	Field formation:Int                     ' +84
	' +88 imgFlag:TImage and +92 imgFlagSmall:TImage are render-time only

	Method GetPrimaryColour:String()
		If kitcolsHome Then Return kitcolsHome.shirtcol1
		Return "FFFFFF"
	End Method
End Type

' ----------------------------------------------------------------------------
'  TClub - own fields begin at +96
' ----------------------------------------------------------------------------
Type TClub Extends TBase_Team
	Field nickname:String                   ' +96
	Field nationid:Int                      ' +100
	Field leagueid:Int                      ' +104
	Field continentalcompid:Int             ' +108
	Field bteamofid:Int                     ' +112

	Global list:TList = CreateList()

	Function SelectById:TClub(searchid:Int)
		For Local c:TClub = EachIn list
			If c.id = searchid Then Return c
		Next
		Return Null
	End Function

	Function SelectListByLeagueId:TList(lid:Int)
		Local r:TList = CreateList()
		For Local c:TClub = EachIn list
			If c.leagueid = lid Then ListAddLast(r, c)
		Next
		Return r
	End Function

	Function CountTeamsInDivision:Int(lid:Int)
		Local n:Int = 0
		For Local c:TClub = EachIn list
			If c.leagueid = lid Then n :+ 1
		Next
		Return n
	End Function

	Function LoadData:Int(path:String)
		Local rows:TList = LoadTsv(path)
		If Not rows Then Return 0
		Local n:Int = 0
		For Local f:String[] = EachIn rows
			If f.length < 38 Then Continue
			Local c:TClub = New TClub
			c.id                = Int(f[0])
			c.name              = f[1]
			c.shortname         = f[2]
			c.tla               = f[3]
			c.strength          = Int(f[4])
			c.rivalid1          = Int(f[5])
			c.rivalid2          = Int(f[6])
			c.rivalid3          = Int(f[7])
			c.stadiumname       = f[8]
			c.stadiumcapacity   = Int(f[9])
			c.stadiumlongitude  = Float(f[10])
			c.stadiumlatitude   = Float(f[11])
			c.kitcolsHome       = TKitStrings.Create(f[12], f[13], f[14], f[15], f[16])
			c.kitcolsAway       = TKitStrings.Create(f[17], f[18], f[19], f[20], f[21])
			c.kitcolsThird      = TKitStrings.Create(f[22], f[23], f[24], f[25], f[26])
			c.kitcolsKeeper     = TKitStrings.Create(f[27], f[28], f[29], f[30], f[31])
			c.formation         = Int(f[32])
			c.nickname          = f[33]
			c.nationid          = Int(f[34])
			c.leagueid          = Int(f[35])
			c.continentalcompid = Int(f[36])
			c.bteamofid         = Int(f[37])
			ListAddLast(list, c)
			n :+ 1
		Next
		Return n
	End Function
End Type

' ----------------------------------------------------------------------------
'  TNation - own fields begin at +96
' ----------------------------------------------------------------------------
Type TNation Extends TBase_Team
	Field nationality:String                ' +96
	Field continent:Int                     ' +100
	Field climate:Int                       ' +104
	Field primaryskin:Int                   ' +108
	Field secondaryskin:Int                 ' +112

	Global list:TList = CreateList()

	Function SelectById:TNation(searchid:Int)
		For Local n:TNation = EachIn list
			If n.id = searchid Then Return n
		Next
		Return Null
	End Function

	Function SelectByTLA:TNation(t:String)
		For Local n:TNation = EachIn list
			If n.tla = t Then Return n
		Next
		Return Null
	End Function

	Function SelectListByContinent:TList(cid:Int)
		Local r:TList = CreateList()
		For Local n:TNation = EachIn list
			If n.continent = cid Then ListAddLast(r, n)
		Next
		Return r
	End Function

	Function LoadData:Int(path:String)
		Local rows:TList = LoadTsv(path)
		If Not rows Then Return 0
		Local cnt:Int = 0
		For Local f:String[] = EachIn rows
			If f.length < 38 Then Continue
			Local n:TNation = New TNation
			n.id               = Int(f[0])
			n.name             = f[1]
			n.shortname        = f[2]
			n.tla              = f[3]
			n.strength         = Int(f[4])
			n.rivalid1         = Int(f[5])
			n.rivalid2         = Int(f[6])
			n.rivalid3         = Int(f[7])
			n.stadiumname      = f[8]
			n.stadiumcapacity  = Int(f[9])
			n.stadiumlongitude = Float(f[10])
			n.stadiumlatitude  = Float(f[11])
			n.kitcolsHome      = TKitStrings.Create(f[12], f[13], f[14], f[15], f[16])
			n.kitcolsAway      = TKitStrings.Create(f[17], f[18], f[19], f[20], f[21])
			n.kitcolsThird     = TKitStrings.Create(f[22], f[23], f[24], f[25], f[26])
			n.kitcolsKeeper    = TKitStrings.Create(f[27], f[28], f[29], f[30], f[31])
			n.formation        = Int(f[32])
			n.nationality      = f[33]
			n.continent        = Int(f[34])
			n.climate          = Int(f[35])
			n.primaryskin      = Int(f[36])
			n.secondaryskin    = Int(f[37])
			ListAddLast(list, n)
			cnt :+ 1
		Next
		Return cnt
	End Function
End Type

' ----------------------------------------------------------------------------
'  Shared TAB-separated loader.
'  NSS5 data files are TAB separated, may carry a UTF-8 BOM, and are terminated
'  by a line consisting of "//".
' ----------------------------------------------------------------------------
Function LoadTsv:TList(path:String)
	' The shipped data files are UTF-8. Reading them with plain ReadLine gives
	' Latin-1 mojibake ("Bayern MUnchen"), so pull the whole file in as bytes
	' and decode it explicitly.
	Local s:TStream = ReadFile(path)
	If Not s Then
		Print "Could not load " + path
		Return Null
	End If

	Local size:Int = Int(StreamSize(s))
	Local buf:Byte[] = New Byte[size]
	s.Read(Varptr buf[0], size)
	CloseStream s

	Local start:Int = 0
	' skip UTF-8 BOM (EF BB BF)
	If size >= 3 And buf[0] = $EF And buf[1] = $BB And buf[2] = $BF Then start = 3

	Local text:String = String.FromUTF8Bytes(Varptr buf[start], size - start)

	Local rows:TList = CreateList()
	Local first:Int = True
	For Local line:String = EachIn text.Replace("~r", "").Split("~n")
		If first Then
			first = False
			Continue        ' header row
		End If
		If line = "" Then Continue
		If line.StartsWith("//") Then Exit
		ListAddLast(rows, line.Split("~t"))
	Next

	Return rows
End Function
