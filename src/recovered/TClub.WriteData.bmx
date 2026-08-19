' TClub.WriteData
' VA 0x004C0B16   1386 bytes   mode=reloc   MATCH 1386/1386
' byte-identical vs NSS5.exe
' KIND=Function (static method on TClub), SIG=(:TStream)i, SLOT=0x54
' Body-only format: statements only, parameters are a0, a1, ...
'
' ASSUMPTIONS
'   Global declared here (name is ours; the original is unrecoverable):
'     0x00C59A44 -> g_clubs:TList
'         globals_final says Object/usage/low. Typed TList from the code: slot 0x8C
'         (TList.ObjectEnumerator) is called on it and the loop downcasts to
'         ClassTable_TClub.
'   Slot resolved: [0xC59E40] = TClub+0x94 -> SortListBy(i,i)i, this Type's own class
'     table, so it is written unprefixed (guide 3d).
'   Fields: TClub extends TBase_Team, so +0x0C..+0x54 come from TBase_Team
'     (id, name, shortname, tla, strength, rivalid1..3, stadiumname, stadiumcapacity,
'      stadiumlongitude:Float, stadiumlatitude:Float, kitcolsHome/Away/Third/Keeper:
'      TKitStrings, formation) and +0x60..+0x70 from TClub itself (nickname, nationid,
'      leagueid, continentalcompid, bteamofid). TKitStrings is +0x08 style, +0x0C shirt1,
'      +0x10 shirt2, +0x14 shorts, +0x18 socks -- all String, which is why those terms use
'      no _bbStringFrom* helper.
'   Helpers: 0x004A7AC0 _bbStringFromInt, 0x004A79D0 _bbStringFromFloat (only the two
'     Float fields use it), 0x004A7C20 _bbStringConcat, 0x005B8307 WriteLine.
'   Literals read with harness.read_string: 0x00C706F0 is the full tab-separated header
'     row reproduced verbatim below (note it really does end "bteamof", not "bteamofid");
'     0x00C6FCC0 = TAB, 0x00C702D4 = TAB followed by '#', 0x00C6FE94 = "//".
'   SOURCE FORM: same finding as TFixture.WriteData -- a single '+' chain compiles
'   right-to-left and comes out short. The original keeps the running string in a
'   register-allocated String Local and appends one statement at a time; here the
'   separator is the LEFT operand of each append (`s :+ "~t" + field`), which is what
'   makes each step Concat(sep, value) followed by Concat(s, that).
'!Global g_clubs:TList
WriteLine(a0, "id~tname~tshortname~ttla~tstrength~trivalclub1~trivalclub2~trivalclub3~tstadiumname~tstadiumcapacity~tstadiumlongitude~tstadiumlatitude~thomestyle~thomekitshirtcol1~thomekitshirtcol2~thomekitshortscol~thomekitsockscol~tawaystyle~tawaykitshirtcol1~tawaykitshirtcol2~tawaykitshortscol~tawaykitsockscol~tthirdstyle~tthirdkitshirtcol1~tthirdkitshirtcol2~tthirdkitshortscol~tthirdkitsockscol~tkeeperstyle~tkeeperkitshirtcol1~tkeeperkitshirtcol2~tkeeperkitshortscol~tkeeperkitsockscol~tformation~tnickname~tnationid~tleagueid~tcontinentalcompid~tbteamof")
SortListBy(1,1)
For Local c:TClub = EachIn g_clubs
	Local s:String = c.id
	s :+ "~t" + c.name
	s :+ "~t" + c.shortname
	s :+ "~t" + c.tla
	s :+ "~t" + c.strength
	s :+ "~t" + c.rivalid1
	s :+ "~t" + c.rivalid2
	s :+ "~t" + c.rivalid3
	s :+ "~t" + c.stadiumname
	s :+ "~t" + c.stadiumcapacity
	s :+ "~t" + c.stadiumlongitude
	s :+ "~t" + c.stadiumlatitude
	s :+ "~t" + c.kitcolsHome.style
	s :+ "~t#" + c.kitcolsHome.shirt1
	s :+ "~t#" + c.kitcolsHome.shirt2
	s :+ "~t#" + c.kitcolsHome.shorts
	s :+ "~t#" + c.kitcolsHome.socks
	s :+ "~t" + c.kitcolsAway.style
	s :+ "~t#" + c.kitcolsAway.shirt1
	s :+ "~t#" + c.kitcolsAway.shirt2
	s :+ "~t#" + c.kitcolsAway.shorts
	s :+ "~t#" + c.kitcolsAway.socks
	s :+ "~t" + c.kitcolsThird.style
	s :+ "~t#" + c.kitcolsThird.shirt1
	s :+ "~t#" + c.kitcolsThird.shirt2
	s :+ "~t#" + c.kitcolsThird.shorts
	s :+ "~t#" + c.kitcolsThird.socks
	s :+ "~t" + c.kitcolsKeeper.style
	s :+ "~t#" + c.kitcolsKeeper.shirt1
	s :+ "~t#" + c.kitcolsKeeper.shirt2
	s :+ "~t#" + c.kitcolsKeeper.shorts
	s :+ "~t#" + c.kitcolsKeeper.socks
	s :+ "~t" + c.formation
	s :+ "~t" + c.nickname
	s :+ "~t" + c.nationid
	s :+ "~t" + c.leagueid
	s :+ "~t" + c.continentalcompid
	s :+ "~t" + c.bteamofid
	WriteLine(a0, s)
Next
WriteLine(a0, "//")
