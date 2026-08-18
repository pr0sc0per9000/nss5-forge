' GLOBAL RENAMED (2026-08-15): g_Object101 -> g_curscreen. Same slot, 0x00C61700 -- THE ACTIVE
' SCREEN. This one slot carried FOUR names across the corpus: g_curscreen (majority, 8
' declarers), g_currentscreen, g_screen, and the decoder auto-name g_Object101. In the
' assembled program those became four independent Globals, so TScreen.SetActive wrote
' the newly-activated screen into one while the main loop's TScreen.Update and
' TScreen.Render read others. The game booted, opened its window and ran the
' fixed-timestep loop -- and drew the boot 'loading' screen forever, because the screen
' the loop rendered was never the screen SetActive had set. Byte-neutral; confirmed
' with scripts/reverify.py.
' Scope check before renaming: g_Object101 resolves to 0x00C61700 and nothing else
' anywhere in src/recovered. g_screen was renamed ONLY in TScreen.Update.bmx, the one
' file that states the address -- the other 8 g_screen declarers record no VA, and the
' name->address map is many-to-many, so sweeping it would be a guess.
' TProfile.UpdateRelationship
' VA 0x0056a955   1155 bytes   vtable slot 0xc0   sig (i,i)i
' byte-identical vs NSS5.exe (1155/1155, original length from Ghidra's inventory)
' assumes module global:  Global g_curscreen:TScreen   (0x00c61700; +8 = TScreen.name)
' 0x00c8eadc = 50.0 (the GetFame() cutoff), 0x00c8ebc0 = 0.1, 0x00c8ebc4 = 100.0.
' Parameter names are not recoverable from the binary; a0/a1 as emitted by the harness.

	Method UpdateRelationship:Int(a0:Int,a1:Int)
		'!Global g_curscreen:TScreen
		Local amt:Int = a1
		Select a0
		Case 1
			LogLine("CRELATION_BOSS: " + amt)
			Self.relationboss = Self.relationboss + amt
			ClampInt(Varptr Self.relationboss,0,100)
			If Self.transferlisted = 4
				Self.oldbossrel = Self.oldbossrel + amt
				ClampInt(Varptr Self.oldbossrel,1,100)
			EndIf
		Case 2
			LogLine("CRELATION_TEAM: " + amt)
			Self.relationteam = Self.relationteam + amt
			ClampInt(Varptr Self.relationteam,0,100)
		Case 3
			LogLine("CRELATION_FANS: " + amt)
			Self.relationfans = Self.relationfans + amt
			ClampInt(Varptr Self.relationfans,0,100)
		Case 4
			LogLine("CRELATION_FRIENDS: " + amt)
			Self.relationfriends = Self.relationfriends + amt
			ClampInt(Varptr Self.relationfriends,0,100)
		Case 5
			If Self.relationgirlfriend = 0 Then Return 0
			LogLine("CRELATION_GIRLFRIEND: " + amt)
			If Self.relationgirlfriend > 0 And Self.relationgirlfriend + amt < 10
				If Self.GetFame() > 50.0
					TScreen_WebPage.SetUpScreen(g_curscreen.name,Self.DoNews(GetText("CNEWS_GIRLFRIENDDUMPSYOU"),Self.myclub,Null,0,0))
				Else
					TScreen.DoMessage(GetText("CMESSAGE_GIRLFRIENDDUMPSYOU"),0,0)
				EndIf
				Self.relationgirlfriend = 0
				Return amt
			EndIf
			Self.relationgirlfriend = Self.relationgirlfriend + amt
			ClampInt(Varptr Self.relationgirlfriend,1,100)
		Case 6
			If Self.GotSponsor() = 0
				Self.relationsponsors = 0
				Return 0
			EndIf
			LogLine("CRELATION_SPONSORS: " + amt)
			Self.relationsponsors = Self.relationsponsors + amt
			ClampInt(Varptr Self.relationsponsors,0,100)
		Case 7
			LogLine("CRELATION_FAME: " + amt)
			If amt > 0
				Local f:Float = Self.myclub.strength * 0.1
				ClampFloat(Varptr f,1.0,10.0)
				ClampInt(Varptr amt,1,Int(f))
				Self.relationfame = Self.relationfame + amt
			Else
				Self.relationfame = Self.relationfame + amt
			EndIf
			ClampInt(Varptr Self.relationfame,0,100)
		End Select
		If Self.relationboss >= 100 Then Self.CheckAchievement(45)
		If Self.relationteam >= 100 Then Self.CheckAchievement(46)
		If Self.relationfans >= 100 Then Self.CheckAchievement(47)
		If Self.relationsponsors >= 100 Then Self.CheckAchievement(48)
		If Self.relationfriends >= 100 Then Self.CheckAchievement(49)
		If Self.relationgirlfriend >= 100 Then Self.CheckAchievement(50)
		If Self.GetHappiness() >= 100 Then Self.CheckAchievement(51)
		If Self.GetFame() >= 100.0 Then Self.CheckAchievement(76)
		Return amt
	End Method
