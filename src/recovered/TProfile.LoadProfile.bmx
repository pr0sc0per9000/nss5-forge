' TProfile.LoadProfile
' VA 0x00562EC2   6481 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Method, SIG (:TStream)i, class-table slot 0x34
' ASSUMPTIONS
'   0x00C68BCC g_profile_int27:Int  -- plain dword store, no refcount traffic (globals_final: Int)
'   0x00C68BD0 g_profile_int28:Int  -- plain dword store, no refcount traffic (globals_final: Int)
'   0x00C5D230 g_options_int03:Int  -- plain dword store, no refcount traffic (globals_final: Int)
'   PTR_FUN_00C6632C = TMyDate classtable + 0x30 = TMyDate.Create(i,i,i):TMyDate
'   PTR_FUN_00C6AC48 = TStats_Team classtable + 0x3C = TStats_Team.CreateFromString($):TStats_Team
'   PTR_FUN_00C6AD78 = THistory classtable + 0x34 = THistory.CreateFromString($):THistory
'   TProfile slot 0xB0 = CheckSkillHash()i ; TList slot 0x44 = AddLast(:Object)
'   FUN_005B82EF = _brl_stream_ReadLine (alias set; TStream context) -> ReadLine()
'   FUN_005B4C68 = _brl_system_Notify -> Notify(); the trailing push 0 is the default arg
'   FUN_0059C8E8 = _brl_retro_Trim (alias set; String context) -> Trim()
'   FUN_004A6BF0 = _bbStringStartsWith (39 witnesses) -> String.StartsWith
'   FUN_004A6A30 = _bbStringCompare, FUN_004A6E90 = _bbStringToFloat
'   NextField / NextFieldInt / LogLine are the recovered module Functions (names are ours)
'   Literals read out of NSS5.exe with harness.read_string:
'     0x00C8D890 "Could not load profile!"   0x00C8D8CC "TProfile.LoadData"
'     0x00C7EDEC "#VERSION:"   0x00C6FCC0 tab   0x00C6FE94 "//"
'   Locals s / n / i are register- or slot-allocated exactly as the original (sub esp,4:
'     one String slot at [ebp-4]; every other local lives in a register)
'   Self.freetime is read from the file and then unconditionally zeroed -- that is in the
'     original, not a transcription slip
'   Field order 0x2D (heading) before 0x2C (tackling) is likewise the original's order
'!Global g_profile_int27:Int
'!Global g_profile_int28:Int
' g_options_int03's original data-section value is 5 (read from NSS5.exe at
' 0x00C5D230 -- codegen-patterns 21.1/21.3).
'!Global g_options_int03:Int = 5
'   The predicate is .Contains, not .StartsWith. extracted/runtime_helpers.tsv names
'   0x004A6BF0 _bbStringStartsWith; it is _bbStringContains, and that row MASKS BY NAME
'   and would bless the wrong predicate here (codegen-patterns 3b). 0x004A6BF0 is
'   44 bytes and is exactly `return bbStringFind(x,y,0)!=-1` -- blitz_string.c:265 --
'   while bbStringStartsWith/EndsWith are call-free loops and cannot call anything.
'   With the row right, this body is MISMATCH as .StartsWith and MATCH as .Contains.
	Method LoadProfile:Int(a0:TStream)
		If Not a0
			Notify("Could not load profile!")
			Return 0
		End If
		LogLine("TProfile.LoadData")
		Local s:String = ReadLine(a0)
		Self.saveversion = s
		LogLine(Self.saveversion)
		If Self.saveversion.Contains("#VERSION:") Then s = ReadLine(a0)
		Self.date = TMyDate.Create(NextFieldInt(s,"~t"),1,1)
		Self.name = NextField(s,"~t")
		Self.nationid = NextFieldInt(s,"~t")
		Self.clubid = NextFieldInt(s,"~t")
		Self.playercols.hair = NextFieldInt(s,"~t")
		Self.playercols.skin = NextFieldInt(s,"~t")
		Self.playercols.boots = NextField(s,"~t")
		Self.bank = NextFieldInt(s,"~t")
		Self.newstarselno = NextFieldInt(s,"~t")
		Self.position = NextFieldInt(s,"~t")
		Self.side = NextFieldInt(s,"~t")
		g_profile_int27 = NextFieldInt(s,"~t")
		g_profile_int28 = NextFieldInt(s,"~t")
		Self.internationalselno = NextFieldInt(s,"~t")
		If Self.internationalselno = 0 Then Self.internationalselno = Self.newstarselno
		Self.retired = NextFieldInt(s,"~t")
		Local n:Int = NextFieldInt(s,"~t")
		If n <> 0 Then g_options_int03 = n
		Repeat
			s = ReadLine(a0)
			If s = "//" Then Exit
			Self.careerstats.AddLast(TStats_Team.CreateFromString(s))
		Forever
		s = ReadLine(a0)
		Self.newsrating = NextFieldInt(s,"~t")
		Self.newsmotm = NextFieldInt(s,"~t")
		Self.newsheadline = NextField(s,"~t")
		s = ReadLine(a0)
		Self.webheadline = NextField(s,"~t")
		Self.bossreport = NextField(s,"~t")
		Self.physioreport = NextField(s,"~t")
		Self.coachreport = NextField(s,"~t")
		Self.coachrep_boss = NextFieldInt(s,"~t")
		Self.coachrep_team = NextFieldInt(s,"~t")
		Self.coachrep_fans = NextFieldInt(s,"~t")
		Self.coachrep_sponsors = NextFieldInt(s,"~t")
		Self.coachrep_fame = NextFieldInt(s,"~t")
		s = ReadLine(a0)
		Self.contractexpires = NextFieldInt(s,"~t")
		Self.contractwage = NextFieldInt(s,"~t")
		Self.contractgoalbonus = NextFieldInt(s,"~t")
		Self.contractassistbonus = NextFieldInt(s,"~t")
		Self.contractcleanbonus = NextFieldInt(s,"~t")
		Self.lastweeksgoalbonus = NextFieldInt(s,"~t")
		Self.lastweeksassistbonus = NextFieldInt(s,"~t")
		Self.lastweekscleanbonus = NextFieldInt(s,"~t")
		Self.thisweeksgoalbonus = NextFieldInt(s,"~t")
		Self.thisweeksassistbonus = NextFieldInt(s,"~t")
		Self.thisweekscleanbonus = NextFieldInt(s,"~t")
		Self.lastweeksshirtsales = NextFieldInt(s,"~t")
		s = ReadLine(a0)
		Self.pace = NextFieldInt(s,"~t")
		Self.shooting = NextFieldInt(s,"~t")
		Self.passing = NextFieldInt(s,"~t")
		Self.heading = NextFieldInt(s,"~t")
		Self.tackling = NextFieldInt(s,"~t")
		Self.dribbling = NextFieldInt(s,"~t")
		Self.flair = NextFieldInt(s,"~t")
		Self.interviewskill = NextFieldInt(s,"~t")
		Self.crossing = NextFieldInt(s,"~t")
		Self.freekicks = NextFieldInt(s,"~t")
		Self.corners = NextFieldInt(s,"~t")
		Self.positioning = NextFieldInt(s,"~t")
		Self.shortpassing = NextFieldInt(s,"~t")
		Self.longpassing = NextFieldInt(s,"~t")
		Self.aggression = NextFieldInt(s,"~t")
		Self.longshots = NextFieldInt(s,"~t")
		Self.finishing = NextFieldInt(s,"~t")
		Self.penalties = NextFieldInt(s,"~t")
		For Local i:Int = 0 To 9
			s = ReadLine(a0)
			Self.boots[i] = NextFieldInt(s,"~t")
			Self.items[i] = NextFieldInt(s,"~t")
			Self.vehicles[i] = NextFieldInt(s,"~t")
			Self.property[i] = NextFieldInt(s,"~t")
		Next
		For Local i:Int = 0 To 8
			s = ReadLine(a0)
			Self.sponsor_amount[i] = NextFieldInt(s,"~t")
			Self.sponsor_expires[i] = NextFieldInt(s,"~t")
		Next
		s = ReadLine(a0)
		Self.relationboss = NextFieldInt(s,"~t")
		Self.relationteam = NextFieldInt(s,"~t")
		Self.relationfans = NextFieldInt(s,"~t")
		Self.relationfriends = NextFieldInt(s,"~t")
		Self.relationgirlfriend = NextFieldInt(s,"~t")
		Self.relationsponsors = NextFieldInt(s,"~t")
		Self.relationfame = NextFieldInt(s,"~t")
		Self.captain = NextFieldInt(s,"~t")
		Self.girlscandalrating = NextFieldInt(s,"~t")
		Self.lastspendtimefriends = NextFieldInt(s,"~t")
		Self.lastspendtimegirlfriend = NextFieldInt(s,"~t")
		s = ReadLine(a0)
		Self.playbuttontype = NextFieldInt(s,"~t")
		s = ReadLine(a0)
		Self.transferlisted = NextFieldInt(s,"~t")
		Self.desiredcontinentid = NextFieldInt(s,"~t")
		Self.desirednationid = NextFieldInt(s,"~t")
		Self.desiredleagueid = NextFieldInt(s,"~t")
		Self.desiredclubid = NextFieldInt(s,"~t")
		Self.onloanfrom = NextFieldInt(s,"~t")
		Self.loanexpires = NextFieldInt(s,"~t")
		Self.oldbossrel = NextFieldInt(s,"~t")
		Self.oldteamrel = NextFieldInt(s,"~t")
		Self.oldfansrel = NextFieldInt(s,"~t")
		s = ReadLine(a0)
		Self.energy = Float(NextField(s,"~t"))
		Self.NRG = NextFieldInt(s,"~t")
		Self.booze = NextFieldInt(s,"~t")
		Self.gambling = NextFieldInt(s,"~t")
		Self.injury = NextFieldInt(s,"~t")
		Self.freetime = NextFieldInt(s,"~t")
		Self.freetime = 0
		Self.takenpainkillers = NextFieldInt(s,"~t")
		Self.shinpads = NextFieldInt(s,"~t")
		Self.boughtmusic = NextFieldInt(s,"~t")
		Self.boughtgame = NextFieldInt(s,"~t")
		Self.boughtfilm = NextFieldInt(s,"~t")
		Self.drugs = NextFieldInt(s,"~t")
		s = ReadLine(a0)
		Self.currentyellowsclub = NextFieldInt(s,"~t")
		Self.currentyellowscontinent = NextFieldInt(s,"~t")
		Self.currentyellowsinternational = NextFieldInt(s,"~t")
		Self.banclub = NextFieldInt(s,"~t")
		Self.bancontinent = NextFieldInt(s,"~t")
		Self.baninternational = NextFieldInt(s,"~t")
		s = ReadLine(a0)
		For Local i:Int = 0 To 4
			Self.interestedclubs[i] = NextFieldInt(s,"~t")
		Next
		Self.lasttransferdate = NextFieldInt(s,"~t")
		Self.skillshash = Trim(ReadLine(a0))
		Self.CheckSkillHash()
		s = ReadLine(a0)
		Self.passhash = Trim(NextField(s,"~t"))
		Self.premiumhash = Trim(NextField(s,"~t"))
		Self.lastconnecthash = Trim(NextField(s,"~t"))
		Repeat
			s = ReadLine(a0)
			If s = "//" Then Exit
			LogLine(s)
			Self.history.AddLast(THistory.CreateFromString(s))
		Forever
		s = ReadLine(a0)
		Self.tipcount = NextFieldInt(s,"~t")
		s = ReadLine(a0)
		For Local i:Int = 0 To 29
			Self.helppages[i] = NextFieldInt(s,"~t")
		Next
	End Method
