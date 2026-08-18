' TNation.WriteData  (KIND=Function -- static, a0 = the TStream)
' VA 0x004BE310   1373 bytes   vtable slot 0x4c   sig (:TStream)i
' byte-identical vs NSS5.exe (1373/1373, original length from Ghidra's inventory, mode=reloc)
' harness mode=reloc, reloc_masked=133, NSS5_NO_LEARN=1, no learned helpers.
' Body-only format: statements only, parameters are a0, a1, ...
'
' Twin of the already-verified TNation.WriteDataMobile and TClub.WriteData -- same file
' family, same accumulator pattern (guide 16.4/16.1): `s :+ "<sep>" + field`, separator
' prepended so each step is Concat(sep, field) then Concat(s, that).
'
' ASSUMPTIONS
'   0x00C596F0 g_nations:TList (already used/typed by TNation.WriteDataMobile/LoadData).
'   TNation Extends TBase_Team (object_model.json / TNation.CreateNation header, already
'     in the corpus): id +0xC, name +0x10, shortname +0x14, tla +0x18, strength +0x24,
'     rivalid1..3 +0x28/0x2C/0x30, stadiumname +0x34, stadiumcapacity +0x38,
'     stadiumlongitude:Float +0x3C, stadiumlatitude:Float +0x40, kitcolsHome/Away/Third/
'     Keeper:TKitStrings +0x44/0x48/0x4C/0x50, formation +0x54; TNation's own nationality
'     +0x60, continent +0x64, climate +0x68, primaryskin +0x6C, secondaryskin +0x70.
'   TKitStrings: style +0x08 (String, no _bbStringFrom* needed), shirt1 +0x0C, shirt2
'     +0x10, shorts +0x14, socks +0x18 (all String).
'   Helpers: 0x004A7AC0 _bbStringFromInt, 0x004A79D0 _bbStringFromFloat (only the two
'     Float fields use it), 0x004A7C20 _bbStringConcat, 0x005B8307 WriteLine (alias set
'     with __maxgui_maxgui_TGadget_ItemState), 0x004A8F60 _bbObjectDowncast.
'   Header row and "//" literal read verbatim with harness.read_string from
'   0x00C6FEC0 / 0x00C6FE94; "~t" / "~t#" separators from 0x00C6FCC0 / 0x00C702D4.
'!Global g_nations:TList
WriteLine(a0, "id~tname~tshortname~ttla~tstrength~trivalid1~trivalid2~trivalid3~tstadiumname~tstadiumcapacity~tstadiumlongitude~tstadiumlatitude~thomekittype~thomekitshirtcol1~thomekitshirtcol2~thomekitshortscol~thomekitsockscol~tawaykittype~tawaykitshirtcol1~tawaykitshirtcol2~tawaykitshortscol~tawaykitsockscol~tthirdkittype~tthirdkitshirtcol1~tthirdkitshirtcol2~tthirdkitshortscol~tthirdkitsockscol~tkeeperkittype~tkeeperkitshirtcol1~tkeeperkitshirtcol2~tkeeperkitshortscol~tkeeperkitsockscol~tformation~tnationality~tcontinent~tclimate~tprimaryskin~tsecondaryskin")
For Local n:TNation = EachIn g_nations
	Local s:String = n.id
	s :+ "~t" + n.name
	s :+ "~t" + n.shortname
	s :+ "~t" + n.tla
	s :+ "~t" + n.strength
	s :+ "~t" + n.rivalid1
	s :+ "~t" + n.rivalid2
	s :+ "~t" + n.rivalid3
	s :+ "~t" + n.stadiumname
	s :+ "~t" + n.stadiumcapacity
	s :+ "~t" + n.stadiumlongitude
	s :+ "~t" + n.stadiumlatitude
	s :+ "~t" + n.kitcolsHome.style
	s :+ "~t#" + n.kitcolsHome.shirt1
	s :+ "~t#" + n.kitcolsHome.shirt2
	s :+ "~t#" + n.kitcolsHome.shorts
	s :+ "~t#" + n.kitcolsHome.socks
	s :+ "~t" + n.kitcolsAway.style
	s :+ "~t#" + n.kitcolsAway.shirt1
	s :+ "~t#" + n.kitcolsAway.shirt2
	s :+ "~t#" + n.kitcolsAway.shorts
	s :+ "~t#" + n.kitcolsAway.socks
	s :+ "~t" + n.kitcolsThird.style
	s :+ "~t#" + n.kitcolsThird.shirt1
	s :+ "~t#" + n.kitcolsThird.shirt2
	s :+ "~t#" + n.kitcolsThird.shorts
	s :+ "~t#" + n.kitcolsThird.socks
	s :+ "~t" + n.kitcolsKeeper.style
	s :+ "~t#" + n.kitcolsKeeper.shirt1
	s :+ "~t#" + n.kitcolsKeeper.shirt2
	s :+ "~t#" + n.kitcolsKeeper.shorts
	s :+ "~t#" + n.kitcolsKeeper.socks
	s :+ "~t" + n.formation
	s :+ "~t" + n.nationality
	s :+ "~t" + n.continent
	s :+ "~t" + n.climate
	s :+ "~t" + n.primaryskin
	s :+ "~t" + n.secondaryskin
	WriteLine(a0, s)
Next
WriteLine(a0, "//")
