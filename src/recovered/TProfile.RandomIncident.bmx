' TProfile.RandomIncident
' VA 0x00567C79   5011 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Method, SIG ()i, class-table slot 0x74
' ASSUMPTIONS
'   Globals (names are ours; original module-Global names are unrecoverable):
'     0x00C8DED4 g_lastincident:Int  -- Int per globals_final.tsv; plain dword store, no refcount traffic.
'     0x00C66B80 g_rel_screen:TScreen  -- same name/type already used by TScreen_Relationships.ButtonGirlEnd.
'     0x00C66930 g_home_screen:TScreen -- globals_final.tsv: TScreen from 1 construction site, subsystem TScreen_Home.
'     0x00C59A44 g_clubs:TList -- typed TList across the corpus; slot 0x8C = ObjectEnumerator here.
'   Class-table slot calls resolved from globals_final.tsv classtable-slot rows:
'     0x00C66D04 = TScreen_Relationships+0x34 = SetUpScreen(i)i
'     0x00C61CC0 = TScreen+0x94             = DoMessage($,i,i)i
'     0x00C689EC = TScreen_WebPage+0x34     = SetUpScreen($,$)i
'     0x00C68144 = TScreen_Dilemma+0x34     = SetUpScreen()i
'     0x00C59E40 = TClub+0x94               = SortListBy(i,i)i
'   Module Functions (src/recovered_module): LogLine 0x00505B91, GetText 0x004C5549,
'     ItemName 0x0050799F, VehicleName 0x005077C5, FormatMoney 0x0050720B,
'     TierB 0x00507C04 (vehicle cost), TierC 0x00507C8F (item cost).
'   Runtime: 0x0059F089 Rand, 0x004A75B0 bbStringReplace, 0x004A7AC0 bbStringFromInt,
'     0x004A7C20 bbStringConcat, 0x004A8F60 bbObjectDowncast, 0x005B9690 bbFloatToInt (Int()).
'   Float constants read out of NSS5.exe: [0x00C8E4BC]=90.0, [0x00C8E4C0]=100.0,
'     [0x00C8E5C0]=15.0, and the immediate 0xC1700000 = -15.0.
'   Every string literal was read with harness.read_string, not guessed.
'   TProfile field offsets and TClub/TBase_Team offsets from object_model.json;
'     TClub.id=+0x0C, TClub.strength=+0x24, TClub.leagueid=+0x68.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_lastincident:Int
'!Global g_rel_screen:TScreen
'!Global g_home_screen:TScreen
'!Global g_clubs:TList
LogLine("RandomIncident")
Self.NextPlayButton()
Local r:Int = Rand(6, 1)
If r = g_lastincident
	g_lastincident = 0
Else
	g_lastincident = r
	Select r
	Case 1
		If Self.booze > 90
			TScreen_Relationships.SetUpScreen(1)
			Select Rand(5, 1)
			Case 1
				TScreen.DoMessage(GetText("CMESSAGE_BOOZINGBOSS"), 0, 0)
				Self.UpdateRelationship(1, -20)
				TScreen_Relationships.SetUpScreen(0)
				Return 0
			Case 2
				TScreen.DoMessage(GetText("CMESSAGE_BOOZINGGIRLFRIEND"), 0, 0)
				Self.UpdateRelationship(5, -20)
				TScreen_Relationships.SetUpScreen(0)
				Return 0
			Case 3
				If Self.injury = 0
					TScreen.DoMessage(GetText("CMESSAGE_BOOZINGFRIENDS"), 0, 0)
					Self.UpdateRelationship(4, -20)
					TScreen_Relationships.SetUpScreen(0)
					Return 0
				End If
			Case 4
				If Self.GotSponsor()
					TScreen.DoMessage(GetText("CMESSAGE_BOOZINGSPONSORS"), 0, 0)
					Self.UpdateRelationship(6, -20)
					TScreen_Relationships.SetUpScreen(0)
					Return 0
				End If
			Case 5
				TScreen.DoMessage(GetText("CMESSAGE_BOOZINGTEAM"), 0, 0)
				Self.UpdateRelationship(2, -20)
				TScreen_Relationships.SetUpScreen(0)
				Return 0
			End Select
		End If
	Case 2
		If Self.gambling > 90 And Self.contractwage > 5000
			TScreen_Relationships.SetUpScreen(1)
			TScreen_WebPage.SetUpScreen(g_rel_screen.name, Self.DoNews(GetText("CNEWS_GAMBLINGADDICT"), Self.myclub, Null, 0, 0))
			Self.UpdateRelationship(6, -20)
			Self.UpdateRelationship(5, -20)
			Self.UpdateRelationship(4, -20)
			Self.UpdateRelationship(3, -20)
			Self.UpdateRelationship(1, -20)
			Return 0
		End If
		If Self.gambling > 60
			TScreen_Relationships.SetUpScreen(1)
			Select Rand(5, 1)
			Case 1
				If Self.GotSponsor()
					TScreen.DoMessage(GetText("CMESSAGE_GAMBLINGADDICT1"), 0, 0)
					Self.UpdateRelationship(6, -20)
					TScreen_Relationships.SetUpScreen(0)
					Return 0
				End If
			Case 2
				If Self.relationgirlfriend > 0
					TScreen.DoMessage(GetText("CMESSAGE_GAMBLINGADDICT2"), 0, 0)
					Self.UpdateRelationship(5, -20)
					TScreen_Relationships.SetUpScreen(0)
					Return 0
				End If
			Case 3
				TScreen.DoMessage(GetText("CMESSAGE_GAMBLINGADDICT3"), 0, 0)
				Self.UpdateRelationship(4, -20)
				TScreen_Relationships.SetUpScreen(0)
				Return 0
			Case 4
				TScreen.DoMessage(GetText("CMESSAGE_GAMBLINGADDICT5"), 0, 0)
				Self.UpdateRelationship(1, -20)
				TScreen_Relationships.SetUpScreen(0)
				Return 0
			End Select
		End If
	Case 3
		For Local i:Int = 0 To 8
			If Self.sponsor_amount[i] = 0 And Self.GetFame() > i * 10 + 15
				Self.OfferSponsorship(i + 1)
				Return 0
			End If
		Next
	Case 4
		If Self.relationgirlfriend = 0
			If Self.date.sdate > 70
				If Self.relationfriends < Rand(40, 1) + 40
					TScreen.DoMessage(GetText("CMESSAGE_GIRLFRIENDNOTMET"), 0, 0)
					Return 0
				End If
				If Self.GetLifestyle() < Rand(30, 1) + 20
					TScreen.DoMessage(GetText("CMESSAGE_GIRLFRIENDNOTIMPRESSED"), 0, 0)
					Return 0
				End If
				Local sr:Int = Rand(100, 1)
				If TScreen.DoMessage(GetText("CMESSAGE_GIRLFRIENDMEET").Replace("$scandalrating", sr), 1, 0)
					TScreen.DoMessage(GetText("CMESSAGE_GIRLFRIENDGET"), 0, 0)
					Self.relationgirlfriend = 50
					Self.girlscandalrating = sr
					Self.lastspendtimegirlfriend = Self.date.sdate
					Self.CheckAchievement(79)
					TScreen_Relationships.SetUpScreen(1)
					Return 0
				End If
				Return 0
			End If
		Else
			If Self.girlscandalrating > Rand(100, 1)
				TScreen_Relationships.SetUpScreen(1)
				Local ns:String = ""
				If Self.girlscandalrating > 75
					ns = Self.DoNews(GetText("CNEWS_GIRLSCANDALHIGH" + Rand(10, 1)), Self.myclub, Null, 0, 0)
					Self.UpdateRelationship(1, -20)
					Self.UpdateRelationship(7, 7)
				ElseIf Self.girlscandalrating > 50
					Select Rand(2, 1)
					Case 1
						ns = Self.DoNews(GetText("CNEWS_GIRLSCANDALHIGH" + Rand(10, 1)), Self.myclub, Null, 0, 0)
						Self.UpdateRelationship(1, -15)
						Self.UpdateRelationship(7, 5)
					Case 2
						ns = Self.DoNews(GetText("CNEWS_GIRLSCANDALLOW" + Rand(10, 1)), Self.myclub, Null, 0, 0)
						Self.UpdateRelationship(1, -10)
						Self.UpdateRelationship(7, 3)
					End Select
				Else
					ns = Self.DoNews(GetText("CNEWS_GIRLSCANDALLOW" + Rand(10, 1)), Self.myclub, Null, 0, 0)
					Self.UpdateRelationship(1, -5)
					Self.UpdateRelationship(7, 2)
				End If
				TScreen_WebPage.SetUpScreen(g_rel_screen.name, ns)
				Return 0
			End If
			If Self.date.sdate > Self.lastspendtimegirlfriend + 28
				TScreen_Relationships.SetUpScreen(1)
				TScreen.DoMessage(GetText("CMESSAGE_LONGTIMEGIRLFRIEND"), 0, 1)
				Self.UpdateRelationship(5, -10)
				TScreen_Relationships.SetUpScreen(0)
				Return 0
			End If
		End If
	Case 5
		If Self.date.sdate > Self.lastspendtimefriends + 42
			TScreen_Relationships.SetUpScreen(1)
			TScreen.DoMessage(GetText("CMESSAGE_LONGTIMEFRIENDS"), 0, 1)
			Self.UpdateRelationship(4, -10)
			TScreen_Relationships.SetUpScreen(0)
			Return 0
		End If
	Case 6
		If Self.date.sdate > 180
			Select Rand(4, 1)
			Case 1
				Local it:Int = Rand(10, 1)
				If Self.items[it - 1] > 0 And Self.bank > TierC(it) * 2
					TScreen.DoMessage(GetText("CMESSAGE_LOSTITEM").Replace("$item", ItemName(it)), 0, 0)
					Self.items[it - 1] = Self.items[it - 1] - 1
					Return 0
				End If
			Case 2
				Local ve:Int = Rand(10, 1)
				If Self.vehicles[ve - 1] > 0 And Self.bank > TierB(ve)
					If TierB(ve) < 100000
						TScreen.DoMessage(GetText("CMESSAGE_LOSTVEHICLE" + Rand(2, 1)).Replace("$vehicle", VehicleName(ve)), 0, 0)
						Self.vehicles[ve - 1] = Self.vehicles[ve - 1] - 1
					Else
						Local half:Int = TierB(ve) / 2
						Local m:String = GetText("CMESSAGE_LOSTVEHICLE3")
						m = m.Replace("$vehicle", VehicleName(ve))
						m = m.Replace("$cost", FormatMoney(half, 0))
						If TScreen.DoMessage(m, 1, 0)
							Self.UpdateBank(-half)
						Else
							Self.vehicles[ve - 1] = Self.vehicles[ve - 1] - 1
						End If
					End If
					Return 0
				End If
			End Select
		End If
	End Select
End If
If Self.items[0] = 0
	TScreen.DoMessage(GetText("CMESSAGE_NEEDAPHONE"), 0, 0)
	Select Rand(2, 1)
	Case 1
		Self.UpdateRelationship(2, -2)
	Case 2
		Self.UpdateRelationship(4, -2)
	End Select
	Return 0
End If
If Rand(10, 1) = 1
	TClub.SortListBy(5, 1)
	Local c:TClub = Null
	For Local cl:TClub = EachIn g_clubs
		If cl.id <> Self.clubid And cl.leagueid = Self.myclub.leagueid
			c = cl
			Exit
		End If
	Next
	If c <> Null
		Select Rand(2, 1)
		Case 1
			c.strength :+ 3
			TScreen_WebPage.SetUpScreen(g_home_screen.name, Self.DoNews(GetText("CNEWS_RANDOMCLUBBOOST" + Rand(15, 1)), c, Null, 0, 0))
		Case 2
			c.strength :- 3
			TScreen_WebPage.SetUpScreen(g_home_screen.name, Self.DoNews(GetText("CNEWS_RANDOMCLUBCRISIS" + Rand(15, 1)), c, Null, 0, 0))
		End Select
		Return 0
	End If
Else
	If Rand(10, 1) = 1 And Self.energy < 90.0
		Local e:Int = Int(100.0 - Self.energy)
		If e > 50 Then e = 50
		Select Rand(4, 1)
		Case 1
			If Self.relationgirlfriend > 0
				Self.UpdateEnergy(e)
				TScreen.DoMessage(GetText("CMESSAGE_ENERGYBOOSTGIRL" + Rand(4, 1)).Replace("$energy", e), 0, 0)
				Return 0
			End If
		Case 2
			Self.UpdateEnergy(e)
			TScreen.DoMessage(GetText("CMESSAGE_ENERGYBOOSTPHYSIO" + Rand(4, 1)).Replace("$energy", e), 0, 0)
			Return 0
		Case 3
			Self.UpdateEnergy(e)
			TScreen.DoMessage(GetText("CMESSAGE_ENERGYBOOSTFRIENDS" + Rand(4, 1)).Replace("$energy", e), 0, 0)
			Return 0
		Case 4
			Self.UpdateEnergy(e)
			TScreen.DoMessage(GetText("CMESSAGE_ENERGYBOOSTTEAM" + Rand(4, 1)).Replace("$energy", e), 0, 0)
			Return 0
		End Select
	ElseIf Rand(5, 1) = 1 And Self.energy >= 15.0
		TScreen_Relationships.SetUpScreen(1)
		Local msg:String = ""
		Local k:Int = Rand(6, 1)
		While (k = 5 And Self.relationgirlfriend = 0) Or (k = 6 And Self.GotSponsor() = 0)
			k = Rand(6, 1)
		Wend
		Select k
		Case 1
			msg = GetText("CMESSAGE_BOSSREQUEST" + Rand(5, 1))
		Case 2
			msg = GetText("CMESSAGE_TEAMREQUEST" + Rand(5, 1))
		Case 3
			msg = GetText("CMESSAGE_FANSREQUEST" + Rand(5, 1))
		Case 4
			msg = GetText("CMESSAGE_FRIENDSREQUEST" + Rand(5, 1))
		Case 5
			msg = GetText("CMESSAGE_GIRLREQUEST" + Rand(5, 1))
		Case 6
			msg = GetText("CMESSAGE_SPONSORREQUEST" + Rand(10, 1))
		End Select
		msg = msg.Replace("$percent", "15")
		If TScreen.DoMessage(msg, 1, 1)
			Self.UpdateRelationship(k, 5)
			If k = 6 Then Self.UpdateRelationship(7, 5)
			Self.UpdateEnergy(-15.0)
		Else
			Self.UpdateRelationship(k, -5)
		End If
		TScreen_Relationships.SetUpScreen(0)
		Return 0
	End If
End If
TScreen_Dilemma.SetUpScreen()
