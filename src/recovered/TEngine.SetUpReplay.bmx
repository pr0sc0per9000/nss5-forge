' TEngine.SetUpReplay
' VA 0x004CEEAE   623 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function (static, no implicit Self), SIG (:TReplay,()i)i, class-table slot 0x40
'
' g_engine_zoom/g_engine_zoomdefault (0x00C5B1D4/0x00C5D238) are the SAME
' addresses as g_engine_float01/g_engine_float09 in TEngine.EndReplay.bmx and
' TEngine.Render.bmx, and as g_opt_matchscale in TOptions.LoadOptions/SaveOptions.bmx --
' this file just names them differently (module Globals carry no debug record; names
' don't affect codegen, see codegen-patterns 4). Original data-section values read
' directly from NSS5.exe: 2.0 and 1.0. See codegen-patterns 21.1/21.3.
'
' ASSUMPTIONS  (module Global names are ours; the declared TYPES are load-bearing)
'   0x00C5B1C0 g_engine_fnend:Int()  -- a FUNCTION-POINTER Global (same one the corpus
'                                       already calls through); a1 is stored straight in
'   0x00C5B22C g_engine_fixture:TFixture  (set to Null -- the retain is on bbNullObject)
'   0x00C5DE10 g_players:TList            (slot 0x34 = TList.Clear)
'   0x00C5B218 g_hometeam:TTeam  0x00C5B21C g_awayteam:TTeam
'       (globals_final types both TKit with a flagged construction conflict; they are
'        TTeam here -- assigned from TTeam.CreateReplayTeam and passed to TPitch.SetUpFans
'        which is declared (:TTeam,:TTeam,i))
'   0x00C5B1D4 g_engine_zoom:Float  0x00C5D238 g_engine_zoomdefault:Float
'   0x00C5D62C g_pitch_pitchtype:Int  0x00C5D630 g_pitch_mowtype:Int
'   0x00C5B2B8 g_engine_isreplay:Int
'   Class-table slots: TScreen+0xAC DoProgressBar, TKit+0x38 CreateKit,
'   TTeam+0x4C CreateReplayTeam, TEngine+0x90/0x34/0x44/0x9C/0xCC/0x4C, TClub+0x60 and
'   TNation+0x58 SelectById, TPitch+0x38 SetStadiumSize / +0x3C SetUpFans,
'   TBall+0x3C CreateReplayBalls, TOptions+0x4C LoadOptions,
'   TPitchMark+0x34 ResetPitchMarks, TWeather+0x34 SetWeatherTimes.
'   stadiumcapacity is TBase_Team +0x38, shared by TClub and TNation.
'
' MEASURED SHAPE (three things were wrong on the first attempt, all byte-observable)
'   * fixlevel is a Select (cmp 0/je, cmp 1/je, jmp), not If/ElseIf -- 623 vs 565.
'   * the weather test is `If a0.doingweather` with (0,250,w) in the TRUE arm; Ghidra
'     prints the branches the other way round.
'   * the club/nation lookup is a separate Local.  Inline
'     `SetStadiumSize(TClub.SelectById(..).stadiumcapacity, 0)` pushes the constant 0
'     BEFORE the nested call; the original completes the nested call first, which is the
'     Local form.  Same length either way -- only the order differs (first_diff 366).
'!Global g_engine_fnend:Int()
'!Global g_engine_fixture:TFixture
'!Global g_players:TList
'!Global g_hometeam:TTeam
'!Global g_awayteam:TTeam
'!Global g_engine_zoom:Float = 2.0
'!Global g_engine_zoomdefault:Float = 1.0
'!Global g_pitch_pitchtype:Int
'!Global g_pitch_mowtype:Int
'!Global g_engine_isreplay:Int
g_engine_fnend = a1
TScreen.DoProgressBar(1.0, GetText("Loading"), "00FF00", 0)
g_engine_fixture = Null
If g_players <> Null Then g_players.Clear()
Local k1:TKit = TKit.CreateKit(a0.kit1cols, "EngineMedia/Match/Player/Player.png")
Local k2:TKit = TKit.CreateKit(a0.kit2cols, "EngineMedia/Match/Player/Player.png")
Local gk1:TKit = TKit.CreateKit(a0.keeperkit1cols, "EngineMedia/Match/Player/Keeper.png")
Local gk2:TKit = TKit.CreateKit(a0.keeperkit2cols, "EngineMedia/Match/Player/Keeper.png")
g_hometeam = TTeam.CreateReplayTeam(a0, a0.teamid1, a0.teamname1, a0.teamname2, k1, gk1, 1)
g_awayteam = TTeam.CreateReplayTeam(a0, a0.teamid2, a0.teamname2, a0.teamname2, k2, gk2, 2)
TEngine.CreateReplayFrames(a0)
TEngine.SetUpChannels()
Select a0.fixlevel
	Case 0
		Local c:TClub = TClub.SelectById(g_hometeam.id)
		TPitch.SetStadiumSize(c.stadiumcapacity, 0)
	Case 1
		Local n:TNation = TNation.SelectById(g_hometeam.id)
		TPitch.SetStadiumSize(n.stadiumcapacity, 0)
End Select
TPitch.SetUpFans(g_hometeam, g_awayteam, a0.fixlevel)
TEngine.SetUpRadarColours()
TBall.CreateReplayBalls(a0)
TOptions.LoadOptions()
g_engine_zoom = g_engine_zoomdefault
g_pitch_pitchtype = a0.pitchtype
g_pitch_mowtype = a0.mowtype
TPitchMark.ResetPitchMarks()
If a0.doingweather
	TWeather.SetWeatherTimes(0, 250, a0.weathertype)
Else
	TWeather.SetWeatherTimes(250, 250, a0.weathertype)
End If
TEngine.StartReplay()
g_engine_isreplay = 1
TEngine.ResumeSounds()
TEngine.MatchLoop()
