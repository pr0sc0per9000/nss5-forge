' TProfile.SaveProfile
' VA 0x00564813   4574 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Method, SIG (:TStream)i, class-table slot 0x38
' ASSUMPTIONS
'   0x00C6E900 g_version:String  -- passed straight into _bbStringConcat with no Int->String
'     conversion; globals_final says Int and is wrong (corpus already corrected this:
'     TScreen_MainMenu.CreateScreen / .UpdateVersionInfo). Name is ours.
'   0x00C68BCC g_profile_int27:Int   -- same Global TProfile.LoadProfile reads back here
'   0x00C68BD0 g_profile_int28:Int   -- same Global TProfile.LoadProfile reads back here
'   0x00C5D230 g_options_int03:Int   -- same Global TProfile.LoadProfile reads back here
'   TStats_Team class-table slot 0x38 = WriteData(:TStream)i  (careerstats loop)
'   THistory    class-table slot 0x30 = WriteData(:TStream)i  (history loop)
'   TList slot 0x8C = ObjectEnumerator, TListEnum 0x30/0x34 -- the two For EachIn loops
'   FUN_005B8307 = _brl_stream_WriteLine -> WriteLine(stream,text)
'   FUN_004A7C20 = _bbStringConcat, FUN_004A7AC0 = Int->String, FUN_004A79D0 = Float->String
'   FUN_00505B91 = LogLine (recovered module Function; the name is ours)
'   Field order mirrors the already-verified TProfile.LoadProfile, including its two
'     oddities: playercols.hair before .skin, and heading before tackling.
'   Literals read out of NSS5.exe with harness.read_string:
'     0x00C7EDEC "#VERSION:"   0x00C6FCC0 tab   0x00C6FE94 "//"
'     0x00C8D8FC "Saving play button type: "  (note the trailing space)
'   Every accumulation is ':+' -- 's = s + "~t" + X' groups left and emits
'     concat(s,tab) first, which is the wrong shape; ':+' evaluates "~t"+X first.
'   Self.tipcount goes through the accumulator ('s = Self.tipcount' then WriteLine(a0,s));
'     writing it inline is 2 bytes short. Self.skillshash is genuinely written inline.
'   Verified with NSS5_NO_LEARN=1 (no in-run helper-name learning).
'!Global g_version:String
'!Global g_profile_int27:Int
'!Global g_profile_int28:Int
'!Global g_options_int03:Int
	Method SaveProfile:Int(a0:TStream)
	WriteLine(a0, "#VERSION:" + g_version)
	Local s:String = Self.date.sdate
	s :+ "~t" + Self.name
	s :+ "~t" + Self.nationid
	s :+ "~t" + Self.clubid
	s :+ "~t" + Self.playercols.hair
	s :+ "~t" + Self.playercols.skin
	s :+ "~t" + Self.playercols.boots
	s :+ "~t" + Self.bank
	s :+ "~t" + Self.newstarselno
	s :+ "~t" + Self.position
	s :+ "~t" + Self.side
	s :+ "~t" + g_profile_int27
	s :+ "~t" + g_profile_int28
	s :+ "~t" + Self.internationalselno
	s :+ "~t" + Self.retired
	s :+ "~t" + g_options_int03
	WriteLine(a0, s)
	For Local st:TStats_Team = EachIn Self.careerstats
		st.WriteData(a0)
	Next
	WriteLine(a0, "//")
	s = Self.newsrating
	s :+ "~t" + Self.newsmotm
	s :+ "~t" + Self.newsheadline
	WriteLine(a0, s)
	s = Self.webheadline
	s :+ "~t" + Self.bossreport
	s :+ "~t" + Self.physioreport
	s :+ "~t" + Self.coachreport
	s :+ "~t" + Self.coachrep_boss
	s :+ "~t" + Self.coachrep_team
	s :+ "~t" + Self.coachrep_fans
	s :+ "~t" + Self.coachrep_sponsors
	s :+ "~t" + Self.coachrep_fame
	WriteLine(a0, s)
	s = Self.contractexpires
	s :+ "~t" + Self.contractwage
	s :+ "~t" + Self.contractgoalbonus
	s :+ "~t" + Self.contractassistbonus
	s :+ "~t" + Self.contractcleanbonus
	s :+ "~t" + Self.lastweeksgoalbonus
	s :+ "~t" + Self.lastweeksassistbonus
	s :+ "~t" + Self.lastweekscleanbonus
	s :+ "~t" + Self.thisweeksgoalbonus
	s :+ "~t" + Self.thisweeksassistbonus
	s :+ "~t" + Self.thisweekscleanbonus
	s :+ "~t" + Self.lastweeksshirtsales
	WriteLine(a0, s)
	s = Self.pace
	s :+ "~t" + Self.shooting
	s :+ "~t" + Self.passing
	s :+ "~t" + Self.heading
	s :+ "~t" + Self.tackling
	s :+ "~t" + Self.dribbling
	s :+ "~t" + Self.flair
	s :+ "~t" + Self.interviewskill
	s :+ "~t" + Self.crossing
	s :+ "~t" + Self.freekicks
	s :+ "~t" + Self.corners
	s :+ "~t" + Self.positioning
	s :+ "~t" + Self.shortpassing
	s :+ "~t" + Self.longpassing
	s :+ "~t" + Self.aggression
	s :+ "~t" + Self.longshots
	s :+ "~t" + Self.finishing
	s :+ "~t" + Self.penalties
	WriteLine(a0, s)
	For Local i:Int = 0 To 9
		s = Self.boots[i]
		s :+ "~t" + Self.items[i]
		s :+ "~t" + Self.vehicles[i]
		s :+ "~t" + Self.property[i]
		WriteLine(a0, s)
	Next
	For Local i:Int = 0 To 8
		s = Self.sponsor_amount[i]
		s :+ "~t" + Self.sponsor_expires[i]
		WriteLine(a0, s)
	Next
	s = Self.relationboss
	s :+ "~t" + Self.relationteam
	s :+ "~t" + Self.relationfans
	s :+ "~t" + Self.relationfriends
	s :+ "~t" + Self.relationgirlfriend
	s :+ "~t" + Self.relationsponsors
	s :+ "~t" + Self.relationfame
	s :+ "~t" + Self.captain
	s :+ "~t" + Self.girlscandalrating
	s :+ "~t" + Self.lastspendtimefriends
	s :+ "~t" + Self.lastspendtimegirlfriend
	WriteLine(a0, s)
	s = Self.playbuttontype
	LogLine("Saving play button type: " + Self.playbuttontype)
	WriteLine(a0, s)
	s = Self.transferlisted
	s :+ "~t" + Self.desiredcontinentid
	s :+ "~t" + Self.desirednationid
	s :+ "~t" + Self.desiredleagueid
	s :+ "~t" + Self.desiredclubid
	s :+ "~t" + Self.onloanfrom
	s :+ "~t" + Self.loanexpires
	s :+ "~t" + Self.oldbossrel
	s :+ "~t" + Self.oldteamrel
	s :+ "~t" + Self.oldfansrel
	WriteLine(a0, s)
	s = Self.energy
	s :+ "~t" + Self.NRG
	s :+ "~t" + Self.booze
	s :+ "~t" + Self.gambling
	s :+ "~t" + Self.injury
	s :+ "~t" + Self.freetime
	s :+ "~t" + Self.takenpainkillers
	s :+ "~t" + Self.shinpads
	s :+ "~t" + Self.boughtmusic
	s :+ "~t" + Self.boughtgame
	s :+ "~t" + Self.boughtfilm
	s :+ "~t" + Self.drugs
	WriteLine(a0, s)
	s = Self.currentyellowsclub
	s :+ "~t" + Self.currentyellowscontinent
	s :+ "~t" + Self.currentyellowsinternational
	s :+ "~t" + Self.banclub
	s :+ "~t" + Self.bancontinent
	s :+ "~t" + Self.baninternational
	WriteLine(a0, s)
	s = Self.interestedclubs[0]
	For Local i:Int = 1 To 4
		s :+ "~t" + Self.interestedclubs[i]
	Next
	s :+ "~t" + Self.lasttransferdate
	WriteLine(a0, s)
	WriteLine(a0, Self.skillshash)
	s = Self.passhash
	s :+ "~t" + Self.premiumhash
	s :+ "~t" + Self.lastconnecthash
	WriteLine(a0, s)
	For Local h:THistory = EachIn Self.history
		h.WriteData(a0)
	Next
	WriteLine(a0, "//")
	s = Self.tipcount
	WriteLine(a0, s)
	s = Self.helppages[0]
	For Local i:Int = 1 To 29
		s :+ "~t" + Self.helppages[i]
	Next
	WriteLine(a0, s)
	End Method
