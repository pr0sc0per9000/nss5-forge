' TContractOffer.CheckPromoteFromBTeam
' VA 0x005734F4   488 bytes  mode=reloc  byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, slot 0x70
' ASSUMPTIONS
'   0x00C6F028 g_profile:TProfile -- globals_final (construction); .myclub :TClub at +0x1D0,
'              .transferlisted at +0x134, .date :TMyDate at +0x10, .clubid at +0x20,
'              .relationboss at +0x104, .relationteam at +0x108 (all object_model.json)
'   TProfile slot 0x88 = GetStat(i,i,i,i)f, slot 0x4C = CreateNewClubStats(i)i,
'   TMyDate slot 0x54 = GetYear()i, TScreen slot 0x94 = DoMessage($,i,i)i,
'   TClub slot 0x60 = SelectById(i):TClub -- all vtable_map.tsv.
'   TClub.bteamofid at +0x70, .labelname at +0x1C (TBase_Team), .id at +0xC (TBase_Team).
'   0x00C8FE0C is this function's float literal 7.5, not a Global.
'   `yr` is a Local: the original calls GetYear once and feeds both GetStat calls.
	Function CheckPromoteFromBTeam:Int()
		'!Global g_profile:TProfile
		LogLine("CheckPromoteFromBTeam")
		If g_profile.myclub.bteamofid > 0 And g_profile.transferlisted = 0
			Local yr:Int = g_profile.date.GetYear()
			Local apps:Int = Int(g_profile.GetStat(12, 3, g_profile.clubid, yr))
			Local rating:Float = g_profile.GetStat(18, 3, g_profile.clubid, yr)
			If rating > 7.5 And apps > 8 And apps Mod 8 = 0
				Local c:TClub = TClub.SelectById(g_profile.myclub.bteamofid)
				If TScreen.DoMessage(GetText("CMESSAGE_PROMOTEFROMBTEAM").Replace("$clubateam", c.labelname), 1, 0) = 1
					g_profile.myclub = c
					g_profile.clubid = c.id
					g_profile.CreateNewClubStats(c.id)
					g_profile.transferlisted = 0
					g_profile.relationboss = 50
					g_profile.relationteam = 50
					TScreen.DoMessage(GetText("CMESSAGE_PROMOTEDTOATEAM").Replace("$clubateam", c.labelname), 1, 0)
				End If
			End If
		End If
	End Function
