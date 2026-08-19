' TNation.WriteDataMobile  (KIND=Function -- static, a0 = the TStream)
' VA 0x004be86d   603 bytes   vtable slot 0x50   sig (:TStream)i
' byte-identical vs NSS5.exe (603/603, original length from Ghidra's inventory)
' VA 0x004BE86D  LEN=603 bytes (full function, Ghidra-authoritative)
' ORACLE: mode=reloc  matched=603/603  reloc_masked=54  STATUS=MATCH
'
' ASSUMPTIONS / RESOLUTIONS
'   0x00C596F0 g_nations:TList -- globals_final only has "Object/usage/low"; typed TList
'     because slot 0x8C (TList.ObjectEnumerator) is called on it and the loop downcasts
'     to ClassTable_TNation.
'   TNation Extends TBase_Team (class_tables.tsv), so every field below 0x60 is inherited:
'     id +0xC, shortname +0x14, tla +0x18, strength +0x24, stadiumlongitude +0x3C,
'     stadiumlatitude +0x40, kitcolsHome +0x44, kitcolsAway +0x48.
'     nationality +0x60 and continent +0x64 are TNation's own.
'   kitcols* are :TKitStrings -- shirt1 +0xC, shirt2 +0x10, shorts +0x14; slot 0x44 on
'     that Type is TKitStrings.GetStyleId_Mobile()i, which is the "homekittype" column.
'   Helpers: 0x005B8307 WriteLine, 0x004A7AC0 bbStringFromInt, 0x004A79D0
'     bbStringFromFloat, 0x004A7C20 bbStringConcat, 0x004A8F60 bbObjectDowncast.
'   String literals read out of the exe: 0x00C702E4 = the header line, 0x00C6FCC0 = tab,
'     0x00C702D4 = tab followed by '#', 0x00C6FE94 = "//".
'   Row is built with a String Local accumulator (`:+`), same codegen rule as
'   TStadium.WriteData; here the separator is PREPENDED -- Concat(sep, field) -- so each
'   statement is `s :+ "<sep>" + field`, not `s :+ field + "<sep>"`.

'!Global g_nations:TList

WriteLine(a0, "id~tshortname~ttla~tstrength~tstadiumlongitude~tstadiumlatitude~thomekittype~thomekitshirtcol1~thomekitshirtcol2~thomekitshortscol~tawaykitshirtcol1~tawaykitshortscol~tnationality~tcontinent")
For Local n:TNation = EachIn g_nations
	Local s:String = String(n.id)
	s :+ "~t" + n.shortname
	s :+ "~t" + n.tla
	s :+ "~t" + String(n.strength)
	s :+ "~t" + String(n.stadiumlongitude)
	s :+ "~t" + String(n.stadiumlatitude)
	s :+ "~t" + String(n.kitcolsHome.GetStyleId_Mobile())
	s :+ "~t#" + n.kitcolsHome.shirt1
	s :+ "~t#" + n.kitcolsHome.shirt2
	s :+ "~t#" + n.kitcolsHome.shorts
	s :+ "~t#" + n.kitcolsAway.shirt1
	s :+ "~t#" + n.kitcolsAway.shorts
	s :+ "~t" + n.nationality
	s :+ "~t" + String(n.continent)
	WriteLine(a0, s)
Next
WriteLine(a0, "//")
