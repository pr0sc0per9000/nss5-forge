' TEngine.DoYourSubstitutionOff   (KIND=Function -- static, no Self)
' VA 0x004D648F   829 bytes   class-table slot 0xD4   sig (i)i
' byte-identical vs NSS5.exe (829/829, original length from Ghidra's inventory)
' ORACLE: mode=reloc  matched=829/829  reloc_masked=45  STATUS=MATCH
' Original length from Ghidra's inventory. NSS5_NO_LEARN=1.
'
' g_engine_int17's original data-section value is 1750 (0x00C5B1F8), read
' directly from NSS5.exe. Same address also declared as g_engine_int17 in
' TEngine.SkipMatchTime/DoHalfEnds/UpdateSetPieceReady.bmx and as g_msg_style in
' TPlayer.CheckOffside.bmx. See codegen-patterns 21.1/21.3.
'
' ASSUMPTIONS -- module Global NAMES are ours; the DECLARED TYPES are load-bearing.
'   0x00C5B2FC g_engine_ico_suboff:TImage    TEngine.SetUp assigns the "suboff" icon here
'   0x00C5B2EC g_engine_ico_injury:TImage    ... and the "injury" icon here
'   0x00C5B1C4 g_engine_fntmatch:TBitmapFont argument 5 of TScreenMessage.Create
'   0x00C5B1F8 g_engine_int17:Int            argument 4 (message lifetime), doubled
'   0x00C5B210 g_engine_clock:Int            match clock; bare dword, no refcount traffic
'   0x00C5B218 g_hometeam:TTeam  0x00C5B21C g_awayteam:TTeam
'                                 globals_final says TKit for 0x00C5B218 and flags the
'                                 construction conflict; TTeam is already established for
'                                 both by TEngine.Update / SetUpRadarColours / EndMatch.
'   0x00C5B22C g_fixture:TFixture            globals_final guesses TPlayer; +0x3C = level
'   0x00C6F028 g_profile:TProfile            +0x1C nationid, +0x20 clubid
'   0x00C5D634 g_player_int16:Int            pitch metric used as the off-pitch X offset
'   0x00C5DE10 g_players:TList               slot 0x70 = TList.Count
' Class-table static calls: TScreenMessage+0x30 Create, TPlayer+0x164 GetHumanPlayer,
'   TPlayer+0x38 CreatePlayerSimple, TBall+0x44 GetActiveBall.
' Module Functions: LogLine (0x00505B91), GetText (0x004C5549); 0x004A7410 = Lower.
' Literals read out of the exe with harness.read_string.
'
' NOTES
'   * `Select g_fixture.level` -- the subject is loaded into eax ONCE and both Case compares
'     are emitted back to back with a trailing jmp (codegen-patterns 10.2). As
'     If/ElseIf the body is 830 bytes.
'   * The six ball-reference flags are all `If <ref> = p Then cN = 1` (cmp/jne/mov 1), NOT
'     `cN = (<ref> = p)` (which emits sete/movzx and costs 21 bytes more overall).
'   * `np.x = -g_player_int16 - 50` in that operand order: the original emits
'     `neg eax / sub eax,0x32`. Writing `-50 - g_player_int16` costs one byte more.

'!Global g_engine_ico_suboff:TImage
'!Global g_engine_ico_injury:TImage
'!Global g_font_match_m:TBitmapFont
'!Global g_engine_int17:Int = 1750
'!Global g_engine_clock:Int
'!Global g_hometeam:TTeam
'!Global g_awayteam:TTeam
'!Global g_fixture:TFixture
'!Global g_profile:TProfile
'!Global g_player_int16:Int
'!Global g_players:TList
LogLine("DoYourSubstitutionOff")
Local ico:TImage = g_engine_ico_suboff
Local msg:String = Lower(GetText("Substitution"))
If a0 <> 0
	msg = Lower(GetText("Injury!"))
	ico = g_engine_ico_injury
EndIf
TScreenMessage.Create(0, 0, msg, g_engine_int17 * 2, g_font_match_m, ico, 1.0, "FFFFFF")
Local p:TPlayer = TPlayer.GetHumanPlayer()
p.matchstats.subbedofftime = g_engine_clock
Local t:TTeam = g_hometeam
Select g_fixture.level
	Case 0
		If g_hometeam.id <> g_profile.clubid Then t = g_awayteam
	Case 1
		If g_hometeam.id <> g_profile.nationid Then t = g_awayteam
End Select
Local c1:Int = 0
Local c2:Int = 0
Local c3:Int = 0
Local c4:Int = 0
Local c5:Int = 0
Local c6:Int = 0
Local b:TBall = TBall.GetActiveBall()
If b <> Null
	If b.controlledby = p Then c1 = 1
	If b.lastkickedby = p Then c2 = 1
	If b.lasttouchedby = p Then c3 = 1
	If b.assistedby = p Then c4 = 1
	If b.setpiecetaker = p Then c5 = 1
	If b.setpiecebuddy = p Then c6 = 1
EndIf
Local np:TPlayer = TPlayer.CreatePlayerSimple(p.selectionno, t.id, t.rating, 0, t.skin1, t.skin2)
p.selectionno = 99
np.PaintPlayer(t.kitplayer)
t.squad.AddLast(np)
np.x = -g_player_int16 - 50
np.y = 0
np.matchstats.subbedontime = g_engine_clock
t.newstarselno = 99
If b <> Null
	If c1 Then b.controlledby = np
	If c2 Then b.lastkickedby = np
	If c3 Then b.lasttouchedby = np
	If c4 Then b.assistedby = np
	If c5 Then b.setpiecetaker = np
	If c6 Then b.setpiecebuddy = np
EndIf
LogLine("MySquad:" + t.squad.Count())
LogLine("List:" + g_players.Count())
