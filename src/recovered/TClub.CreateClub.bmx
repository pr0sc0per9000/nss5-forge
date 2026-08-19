' TClub.CreateClub
' VA 0x004bfea2   2782 bytes   vtable slot 0x48   sig ($)i
' byte-identical vs NSS5.exe (2782/2782, original length from Ghidra's inventory)
' VA        0x004BFEA2   classtable slot 0x48   KIND=Function (static)   SIG=($)i
'
' MODULE GLOBAL
'   0x00C6EF74 -> g_club_int07:Int (name is ours -- annotate's placeholder). Selects
'   whether a club's label is its (lowercased) TLA or its full name/shortname.
'
' CALL TARGETS RESOLVED
'   0x00505BCB -> module Function NextFieldInt($ Var,$)i   (src/recovered_module)
'   0x00505C64 -> module Function NextField($ Var,$)$      (src/recovered_module)
'   0x004A8F20 -> `New TClub` (bbObjectNew on the TClub class table)
'   0x004A8590 -> inlined BBRELEASE's GC free; never written in source
'   0x004A6E90 -> _bbStringToFloat, i.e. the `Float(...)` cast of a String
'   0x004A75B0 -> _bbStringReplace  ->  .Replace("CKITTYPE_", "")
'   0x004A7410 -> _brl_retro_Lower  ->  Lower(...)
'   call [0x00C5C030] -> TFormation class table + 0x74 = PickRandomFormation()
'   call [eax+0x38] on a TKitStrings -> TKitStrings.CheckKitColours
'
' LITERALS -- read out of NSS5.exe with harness.read_string (a MATCH masks a literal's
' ADDRESS, never its text):
'   0x00C6FCC0 "~t"   0x00C6FCD0 "CKITTYPE_"
'   Same addresses TNation.CreateNation already certified for the identical text.
'
' FIELD OFFSETS (object_model.json; TClub Extends TBase_Team, instance size 116)
'   TBase_Team: +0x0C id  +0x10 name  +0x14 shortname  +0x18 tla
'     +0x1C labelname  +0x20 labelshortname  +0x24 strength  +0x28..0x30 rivalid1..3
'     +0x34 stadiumname  +0x38 stadiumcapacity  +0x3C stadiumlongitude:Float
'     +0x40 stadiumlatitude:Float  +0x44/0x48/0x4C/0x50 kitcolsHome/Away/Third/Keeper
'     :TKitStrings  +0x54 formation
'   TClub: +0x60 nickname  +0x64 nationid  +0x68 leagueid  +0x6C continentalcompid
'     +0x70 bteamofid
'   TKitStrings: +0x08 style  +0x0C shirt1  +0x10 shirt2  +0x14 shorts  +0x18 socks
'
' SOURCE FORM -- same family as TNation.CreateNation, TStadium.CreateStadium,
' TContinent.CreateContinent, TPromotionPlace.CreatePromotionPlace: one tab-separated
' line parsed field by field. `Local line:String = a0` holds the one dword frame slot;
' every other Local is register-resident. The id guard is the EARLY-RETURN spelling
' `< 1` (as in the two verified siblings above) -- Ghidra structures the shared tail
' `Return 0` as an enclosing `if (0 < id) { ... }`, which is exactly what the siblings'
' already-verified early-return source also decompiles to (checked against
' extracted/decomp/TStadium.CreateStadium@0052771e.c).
'
' No image/flag loading in this function (unlike TNation.CreateNation) -- TClub's own
' imgFlag/imgFlagSmall are populated elsewhere.

Function CreateClub(a0:String)
	'!Global g_club_int07:Int
	Local line:String = a0
	Local id:Int = NextFieldInt(line, "~t")
	If id < 1 Then Return 0
	Local c:TClub = New TClub
	c.id = id
	c.name = NextField(line, "~t")
	c.shortname = NextField(line, "~t")
	c.tla = Lower(NextField(line, "~t"))
	If g_club_int07 <> 0
		c.labelname = c.name
		c.labelshortname = c.shortname
	Else
		c.labelname = c.tla
		c.labelshortname = c.tla
	EndIf
	c.strength = NextFieldInt(line, "~t")
	c.rivalid1 = NextFieldInt(line, "~t")
	c.rivalid2 = NextFieldInt(line, "~t")
	c.rivalid3 = NextFieldInt(line, "~t")
	c.stadiumname = NextField(line, "~t")
	c.stadiumcapacity = NextFieldInt(line, "~t")
	c.stadiumlongitude = Float(NextField(line, "~t"))
	c.stadiumlatitude = Float(NextField(line, "~t"))
	c.kitcolsHome.style = NextField(line, "~t").Replace("CKITTYPE_", "")
	c.kitcolsHome.shirt1 = NextField(line, "~t")
	c.kitcolsHome.shirt2 = NextField(line, "~t")
	c.kitcolsHome.shorts = NextField(line, "~t")
	c.kitcolsHome.socks = NextField(line, "~t")
	c.kitcolsAway.style = NextField(line, "~t").Replace("CKITTYPE_", "")
	c.kitcolsAway.shirt1 = NextField(line, "~t")
	c.kitcolsAway.shirt2 = NextField(line, "~t")
	c.kitcolsAway.shorts = NextField(line, "~t")
	c.kitcolsAway.socks = NextField(line, "~t")
	c.kitcolsThird.style = NextField(line, "~t").Replace("CKITTYPE_", "")
	c.kitcolsThird.shirt1 = NextField(line, "~t")
	c.kitcolsThird.shirt2 = NextField(line, "~t")
	c.kitcolsThird.shorts = NextField(line, "~t")
	c.kitcolsThird.socks = NextField(line, "~t")
	c.kitcolsKeeper.style = NextField(line, "~t").Replace("CKITTYPE_", "")
	c.kitcolsKeeper.shirt1 = NextField(line, "~t")
	c.kitcolsKeeper.shirt2 = NextField(line, "~t")
	c.kitcolsKeeper.shorts = NextField(line, "~t")
	c.kitcolsKeeper.socks = NextField(line, "~t")
	c.kitcolsHome.CheckKitColours()
	c.kitcolsAway.CheckKitColours()
	c.kitcolsThird.CheckKitColours()
	c.kitcolsKeeper.CheckKitColours()
	c.formation = NextFieldInt(line, "~t")
	If c.formation = 0 Or c.formation > 10
		c.formation = TFormation.PickRandomFormation()
	EndIf
	c.nickname = NextField(line, "~t")
	c.nationid = NextFieldInt(line, "~t")
	c.leagueid = NextFieldInt(line, "~t")
	c.continentalcompid = NextFieldInt(line, "~t")
	c.bteamofid = NextFieldInt(line, "~t")
End Function
