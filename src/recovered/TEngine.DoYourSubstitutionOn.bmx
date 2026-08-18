' TEngine.DoYourSubstitutionOn   (KIND=Function -- static, no Self)
' VA 0x004D60F7   920 bytes   class-table slot 0xD0   sig ()i
' ORACLE: mode=reloc  matched=920/920  reloc_masked=42  STATUS=MATCH
' Original length from Ghidra's inventory. NSS5_NO_LEARN=1.
'
' The twin of TEngine.DoYourSubstitutionOff (0x004D648F); the
' two share the whole ball-reference / squad-swap tail, which is why both fell out together.
'
' ASSUMPTIONS -- module Global NAMES are ours; the DECLARED TYPES are load-bearing.
'   0x00C5B210 g_engine_clock:Int    0x00C5B228 g_engine_int22:Int  (bare dwords)
'   0x00C5B218 g_hometeam:TTeam      0x00C5B21C g_awayteam:TTeam
'                                    globals_final says TKit for 0x00C5B218 and flags the
'                                    construction conflict; TTeam is established for both
'                                    by TEngine.Update / SetUpRadarColours / EndMatch.
'   0x00C5B22C g_fixture:TFixture    globals_final guesses TPlayer; +0x3C = level
'   0x00C6F028 g_profile:TProfile    +0x1C nationid, +0x20 clubid, +0x24 playercols,
'                                    +0x2C newstarselno
'   0x00C5D634 g_player_int16:Int    pitch metric used as the off-pitch X offset
'   0x00C5DE10 g_players:TList       slot 0x70 = TList.Count
' Class-table static calls: TPlayer+0x38 CreatePlayerSimple, TBall+0x44 GetActiveBall.
' Module Function LogLine (0x00505B91). Literals read out of the exe.
'
' NOTES
'   * `Select g_fixture.level` (codegen-patterns 10.2) -- subject loaded once, both Case
'     compares emitted back to back.
'   * `If Not sub Then Return 0` is a real EARLY RETURN (setne/movzx/cmp/jne, then
'     `mov eax,0 / jmp end`). As an enclosing If-block the body is 904 bytes.
'   * The six ball-reference flags are `If <ref> = sub Then cN = 1`, not `cN = (<ref> = sub)`.
'   * `np.x = -g_player_int16` -- a bare `neg eax`, no constant (Off subtracts 50 as well).

'!Global g_engine_clock:Int
'!Global g_engine_int22:Int
'!Global g_hometeam:TTeam
'!Global g_awayteam:TTeam
'!Global g_fixture:TFixture
'!Global g_profile:TProfile
'!Global g_player_int16:Int
'!Global g_players:TList
LogLine("DoYourSubstitutionOn")
Local t:TTeam = g_hometeam
Select g_fixture.level
	Case 0
		If g_hometeam.id <> g_profile.clubid Then t = g_awayteam
	Case 1
		If g_hometeam.id <> g_profile.nationid Then t = g_awayteam
End Select
Local sub:TPlayer = Null
For Local pl:TPlayer = EachIn t.squad
	If pl.selectionno = g_profile.newstarselno And pl.matchstats.reds = 0 And pl.selectionno < 11
		sub = pl
		Exit
	EndIf
Next
If Not sub Then Return 0
Local c1:Int = 0
Local c2:Int = 0
Local c3:Int = 0
Local c4:Int = 0
Local c5:Int = 0
Local c6:Int = 0
Local b:TBall = TBall.GetActiveBall()
If b <> Null
	If b.controlledby = sub Then c1 = 1
	If b.lastkickedby = sub Then c2 = 1
	If b.lasttouchedby = sub Then c3 = 1
	If b.assistedby = sub Then c4 = 1
	If b.setpiecetaker = sub Then c5 = 1
	If b.setpiecebuddy = sub Then c6 = 1
EndIf
Local np:TPlayer = TPlayer.CreatePlayerSimple(g_profile.newstarselno, t.id, t.rating, 1, g_profile.playercols.skin, g_profile.playercols.skin)
sub.selectionno = 99
np.PaintPlayer(t.kitplayer)
t.squad.AddLast(np)
t.newstarselno = g_profile.newstarselno
np.x = -g_player_int16
np.y = 0
np.matchstats.subbedontime = g_engine_clock
g_engine_int22 = 0
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
