' TFixture.CreateReplayFixture
' VA 0x004c50ad   163 bytes   vtable slot 0x78   sig ()i
' byte-identical vs NSS5.exe (163/163, original length from Ghidra's inventory)
' Slots: 0x00c6160c = TCompetition+0x4c = SelectById; 0x00c6632c = TMyDate+0x30 = Create
	Method CreateReplayFixture:Int()
		Local c:TCompetition = TCompetition.SelectById(Self.compid)
		Local d:TMyDate = TMyDate.Create(Self.sdate + 1,1,1)
		While c.CheckFixtureClash(d)
			d.AddDays(1)
		Wend
		Local f:TFixture = CreateFixture(d.sdate,3,2,Self.groupno,0,Self.awayteam,Self.hometeam,Self.level,Self.compid)
		LogLine("CreateReplayFixture: " + c.labelname)
		c.lfixturelist.AddLast(f)
	End Method
