' TReplay.ReadHeader
' VA 0x0050469C   1395 bytes   vtable slot 0x3c   sig (:TStream)i
' byte-identical vs NSS5.exe (1395/1395, original length from Ghidra's inventory)
' w16_S2. Mechanical stream-header reader: one ReadLine() per field, Int() around the
' numeric ones. `Self.kit1cols.style = ...` etc is a genuine double indirection --
' kit1cols/kit2cols/keeperkit1cols/keeperkit2cols are TKitStrings object fields, not
' inline structs -- and the dotted assignment compiles that correctly on its own.
' The trailing pair reuses NextFieldInt (src/recovered_module) on a shared Local `ln`;
' stadiumsize defaults to 3 when the fixlevel line has no second tab-separated field.
	Method ReadHeader:Int(a0:TStream)
		Self.name = a0.ReadLine()
		Self.teamid1 = Int(a0.ReadLine())
		Self.teamid2 = Int(a0.ReadLine())
		Self.teamname1 = a0.ReadLine()
		Self.teamname2 = a0.ReadLine()
		Self.score1 = Int(a0.ReadLine())
		Self.score2 = Int(a0.ReadLine())
		Self.pitchtype = Int(a0.ReadLine())
		Self.mowtype = Int(a0.ReadLine())
		Self.doingweather = Int(a0.ReadLine())
		Self.weathertype = Int(a0.ReadLine())
		Self.kit1cols.style = a0.ReadLine()
		Self.kit1cols.shirt1 = a0.ReadLine()
		Self.kit1cols.shirt2 = a0.ReadLine()
		Self.kit1cols.shorts = a0.ReadLine()
		Self.kit1cols.socks = a0.ReadLine()
		Self.kit2cols.style = a0.ReadLine()
		Self.kit2cols.shirt1 = a0.ReadLine()
		Self.kit2cols.shirt2 = a0.ReadLine()
		Self.kit2cols.shorts = a0.ReadLine()
		Self.kit2cols.socks = a0.ReadLine()
		Self.keeperkit1cols.style = a0.ReadLine()
		Self.keeperkit1cols.shirt1 = a0.ReadLine()
		Self.keeperkit1cols.shirt2 = a0.ReadLine()
		Self.keeperkit1cols.shorts = a0.ReadLine()
		Self.keeperkit1cols.socks = a0.ReadLine()
		Self.keeperkit2cols.style = a0.ReadLine()
		Self.keeperkit2cols.shirt1 = a0.ReadLine()
		Self.keeperkit2cols.shirt2 = a0.ReadLine()
		Self.keeperkit2cols.shorts = a0.ReadLine()
		Self.keeperkit2cols.socks = a0.ReadLine()
		Local ln:String = a0.ReadLine()
		Self.fixlevel = NextFieldInt(ln, "~t")
		If ln = ""
			Self.stadiumsize = 3
		Else
			Self.stadiumsize = NextFieldInt(ln, "~t")
		EndIf
		Return 0
	End Method
