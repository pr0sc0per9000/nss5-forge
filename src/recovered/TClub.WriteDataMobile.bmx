' TClub.WriteDataMobile
' VA 0x004c1080   699 bytes   vtable slot 0x58   sig (:TStream)i
' byte-identical vs NSS5.exe (699/699, original length from Ghidra's inventory)
' VA        0x004C1080   slot 0x58   KIND=Function (static)   SIG=(:TStream)i
' ORACLE    MATCH mode=reloc  699/699 bytes  reloc_masked=64
'
' MODULE GLOBALS DECLARED (name is ours; the declared TYPE is load-bearing)
'   0x00C59A44 g_clubs:TList  -- globals_final says Object/low ("init=bbNullObject, no
'                                call-site typing"); TList is forced by the call through
'                                slot 0x8C (TList.ObjectEnumerator) that opens the loop.
'
' CALL TARGETS RESOLVED
'   0x005B8307        -> brl.stream WriteLine. This VA is an ALIAS SET
'                        (__maxgui_maxgui_TGadget_ItemState | _brl_stream_WriteLine); the
'                        first argument is this function's TStream parameter, so WriteLine
'                        is the member that fits (guide 3h).
'   call [0x00C59E40] -> TClub+0x94 = SortListBy(i,i)i. That is THIS Type's own class table,
'                        so it is written as the bare sibling call `SortListBy(1,1)`.
'   0x004A7AC0 _bbStringFromInt, 0x004A79D0 _bbStringFromFloat, 0x004A7C20 _bbStringConcat,
'   0x004A8F60 _bbObjectDowncast -- all emitted implicitly, never written in source.
'   Downcast class table = TClub, which types the loop variable.
'
' FIELD OFFSETS  (TClub extends TBase_Team; everything below 0x60 is inherited)
'   TBase_Team +0x0C id:Int  +0x14 shortname:$  +0x18 tla:$  +0x24 strength:Int
'              +0x3C stadiumlongitude:Float  +0x40 stadiumlatitude:Float
'              +0x44 kitcolsHome:TKitStrings  +0x48 kitcolsAway:TKitStrings
'   TClub      +0x64 nationid  +0x68 leagueid  +0x6C continentalcompid  +0x70 bteamofid
'   TKitStrings +0x0C shirt1:$  +0x10 shirt2:$  +0x14 shorts:$ ; slot 0x44 = GetStyleId_Mobile()i
'
' STRING LITERALS -- all read out of NSS5.exe with harness.read_string, not invented:
'   0x00C70AF8 the tab-separated header line, 0x00C702D4 = "~t#", 0x00C6FE94 = "//".
'
' SOURCE FORM
'   The accumulator is a real String Local built with `:+`, not one giant expression: the
'   original emits _bbStringConcat(acc, _bbStringConcat("~t", field)) for every column, i.e.
'   the separator groups with the FIELD (right operand), which is what `s :+ "~t" + x`
'   produces. A single left-associative `a + "~t" + b + "~t" + c ...` expression would nest
'   the other way. The Int/Float fields rely on BlitzMax's implicit numeric-to-String
'   conversion inside a concatenation -- no explicit String() cast is written, and the
'   conversion helper is called before the concat, matching the original's ordering.

Function WriteDataMobile(a0:TStream)
	'!Global g_clubs:TList
	WriteLine(a0, "id~tshortname~ttla~tstrength~tstadiumlongitude~tstadiumlatitude~thomestyle~thomekitshirtcol1~thomekitshirtcol2~thomekitshortscol~tawaykitshirtcol1~tawaykitshortscol~tnationid~tleagueid~tcontinentalcompid~tbteamof")
	SortListBy(1, 1)
	For Local c:TClub = EachIn g_clubs
		Local s:String = c.id
		s :+ "~t" + c.shortname
		s :+ "~t" + c.tla
		s :+ "~t" + c.strength
		s :+ "~t" + c.stadiumlongitude
		s :+ "~t" + c.stadiumlatitude
		s :+ "~t" + c.kitcolsHome.GetStyleId_Mobile()
		s :+ "~t#" + c.kitcolsHome.shirt1
		s :+ "~t#" + c.kitcolsHome.shirt2
		s :+ "~t#" + c.kitcolsHome.shorts
		s :+ "~t#" + c.kitcolsAway.shirt1
		s :+ "~t#" + c.kitcolsAway.shorts
		s :+ "~t" + c.nationid
		s :+ "~t" + c.leagueid
		s :+ "~t" + c.continentalcompid
		s :+ "~t" + c.bteamofid
		WriteLine(a0, s)
	Next
	WriteLine(a0, "//")
End Function
