' TReplay.CreateReplay
' VA 0x00503C37   1496 bytes   class-table slot 0x30   sig (:TTeam,:TTeam,i,i,i,i,i,i,i)$
' KIND=Function (static -- param_1/a0 is the first real TTeam parameter, not Self).
' byte-identical vs NSS5.exe (1496/1496).
'
' The `If Not bs` (bank stream creation failed) branch returns "" as ITS OWN last
' statement, and the success (Else) branch returns fn as ITS OWN last statement --
' there is no shared trailing `Return fn` after the If/Else. Both branches fall into the
' function's one shared epilogue, exactly the shape TReplay.LoadReplayFile.bmx uses for
' its `If Not stream ... Return Null / Else ... Return rep / EndIf`.
' `Local f:String` is declared before `Local dir:Int = ReadDir(...)` (not the field order
' TScreen_MainMenu.UpdateReplayTable.bmx happens to read in): register colouring for this
' function's larger live set puts dir in ebx and f in esi only with f declared first;
' declaring dir first swaps the pair into esi/ebx instead (codegen-patterns.md 18.2 --
' declaration order is a real tie-break lever once reference counts are equal).
' `Local bs:TStream = CreateBankStream(bank)` -- not `:TBankStream` -- because harness.py's
' generated probe has no MODULE_TYPES entry for TBankStream (only TBank, TStream, TList,
' etc. are redirected to their real BRL module types) and TBankStream is reflected out of
' NSS5.exe's own class table like a game Type, so an explicit `:TBankStream` local
' collides with the real BRL.BankStream TBankStream that CreateBankStream returns
' (`Compile Error: Unable to convert from 'TBankStream' to 'TBankStream'`, the same
' self-shadowing symptom harness.py documents for TImage/TSound/TChannel/TMap). `bs` is
' only ever passed as an argument (never itself the receiver of a method call), so typing
' the local as its real ancestor TStream -- which IS in MODULE_TYPES -- is not observable
' in the compiled bytes; the assignment from CreateBankStream's TBankStream result is a
' plain upcast.
' Builds a unique "<tla1>v<tla2>_NN.rep" filename, populates a new TReplay from the two
' teams plus the passed-in match settings, appends every recorded TReplayFrame (rep's own,
' every TBall's, every TPlayer's) to a bank stream via WriteHeader/SaveFrame, zips that
' stream into Replays/<name> under the entry "newstarsoccerfivereplayfile", and returns the
' filename (or "" if the bank stream could not be created).
'
' ASSUMPTIONS -- Globals (name/type chosen as the highest-tier, most-corroborated entry
' explain_global.py reports for the address; every one of these addresses has at least one
' competing lower-tier name from an earlier pass, listed for the record):
'   0x00C6E9A8  g_userpath:String   -- CERTAIN/5 bodies unanimous, beats STRONG g_datadir/
'     g_savedir (1 body each) and CERTAIN-but-smaller g_screen_mainmenu_int26 (2 bodies).
'     Confirmed String (not globals_final's Int) by TScreen_MainMenu.UpdateReplayTable.bmx
'     and .ButtonDeleteReplayFile.bmx, which push it straight into ReadDir/DeleteFile
'     string concatenation with the exact same "...+ ~qReplays/~q + f + ~q.rep~q" shape used
'     here.
'   0x00C5D69C  g_pitch_int21:Int   -- CERTAIN/4 bodies vs STRONG g_stadiumsize/2 bodies;
'     this is the stadium-size setting (TPitch.SetStadiumSize/.DrawStadium's g_stadiumsize
'     is the very same slot), just not yet renamed everywhere.
'   0x00C5A4C0  g_balls:TList       -- CERTAIN/13 bodies vs STRONG g_replayballs/1 body.
'   0x00C5A4C4  g_ball_sortmode:Int -- only name resolved (TBall.Compare's `Select`).
'   0x00C5DE10  g_players:TList     -- CERTAIN/28 bodies, far ahead of the other CERTAIN
'     aliases at this address (g_allplayers/2, g_object79/4, g_playerlist/3) and STRONG
'     g_replayplayers/1.
'   0x00C5DE14  g_team_int03:Int    -- CERTAIN/2 bodies vs STRONG g_sortkey/1 body.
'   0x00C5B2B0  g_replayframes:TList -- CERTAIN/4 bodies vs STRONG g_replay/1 body; this is
'     TReplay's own not-yet-classified frame buffer (TEngine.CreateReplayFrames/.SetUpMatch/
'     .UpdateReplayFrame all agree), recorded during the match and flushed here.
'
' OTHER ASSUMPTIONS
'   * TTeam fields (object_model.json): id 0x08, tla 0x10, kitplayer 0x2C, kitkeeper 0x30.
'     TReplay fields: name 0x08, teamid1 0x0C, teamid2 0x10, teamname1 0x14, teamname2 0x18,
'     score1 0x1C, score2 0x20, pitchtype 0x24, mowtype 0x28, doingweather 0x2C,
'     weathertype 0x30, kit1cols 0x34, kit2cols 0x38, keeperkit1cols 0x3C,
'     keeperkit2cols 0x40, fixlevel 0x44, stadiumsize 0x48. rep.teamname1/2 genuinely hold
'     the team's tla (three-letter code), not its full name -- misleading field name, not a
'     transcription error.
'   * TKit.newcol[] data starts at +0x18 (TKit.CreateKit.bmx), so the four field reads at
'     kitplayer/kitkeeper offsets +0x1C/+0x28/+0x34/+0x40 are newcol[1]/[4]/[7]/[10] -- the
'     base shirt1/shirt2/shorts/socks hex colours (indices 2/3, 5/6, 8/9, 11 are the two
'     darker ShiftColourHex shades CreateKit derives from each, not read here).
'   * TKitStrings.CreateKitStrings($,$,$,$,$):TKitStrings (class-table slot 0x30) takes its
'     five arguments in (shirt1, shirt2, shorts, socks, style) order, NOT the field
'     declaration order (style,shirt1,shirt2,shorts,socks) -- confirmed against the literal
'     call sites in TPitch.SetUp.bmx, e.g. CreateKitStrings("FF0000","0000FF","808000",
'     "000000","PLAIN"), where the final argument is a style name.
'   * No `New TReplay` field-init side effects (kit1cols/kit2cols/keeperkit1cols/
'     keeperkit2cols each = New TKitStrings, per TReplay.New.bmx) appear anywhere in this
'     body -- every one of those four fields is unconditionally overwritten later in this
'     same Function before being read, so bcc's inliner+DCE erases the whole inlined
'     constructor call. Writing plain `New TReplay` and trusting the real compiler to do the
'     same elimination (exactly the precedent TReplay.LoadReplayFile.bmx documents for its
'     own `New TReplay`) is what is written below.
'   * ZipWriter (no T-prefix -- object_model.json's real name) has no visible constructor
'     call either (bare _bbObjectNew), matching the identical New ZipWriter/OpenZip/
'     AddStream/CloseZip sequence already decompiled for TProfile.SaveGame (0x00565D99),
'     which is the strongest available precedent for this idiom.
'   * CloseStream(bs) is the free module Function (direct call, not virtual dispatch) --
'     same alias-set call already resolved this way at the end of TProfile.SaveGame.
'   * TReplayFrame.SaveFrame(:TStream)i is slot 0x30; TBall.replayframes is +0xAC;
'     TPlayer.replayframes is +0x160 (object_model.json).
'   * The three frame-saving loops (rep's own g_replayframes, then each TBall's, then each
'     TPlayer's replayframes) each show a DOUBLED null check in the decompilation
'     (`(x!=Null)&&(x!=Null)`), unlike the outer TBall/TPlayer EachIn loops which show only
'     ONE check. That means the original source itself wrote a redundant `If x<>Null Then
'     x.SaveFrame(bs)` on top of `For...EachIn`'s own implicit null-skip for these three
'     specifically (codegen-patterns.md 5 notes EachIn already emits its own null-skip, so
'     an extra one is a genuine, deliberate original quirk here, not something to add
'     speculatively elsewhere).
'   * g_replayframes is walked with NO `If g_replayframes<>Null` guard at all (unlike
'     g_balls/g_players, which both need one because Sort() and ObjectEnumerator() are
'     virtual dispatches that would fault on a truly null receiver) -- transcribed as-is.
'   * No CloseDir call appears anywhere in this body's call list; the ReadDir handle used to
'     scan for a free filename is never explicitly closed. Preserved, not "fixed".
'   * The inner directory-scan loop is written Repeat/If f=""Then Exit/Forever rather than
'     Repeat...Until f="" -- TScreen_MainMenu.UpdateReplayTable.bmx (the other body that
'     scans this exact Replays/ directory with ReadDir/NextFile) documents that `Until`
'     compiles to a strictly larger/different byte shape for this same comparison, and its
'     Repeat/If/Exit/Forever form is the one already confirmed byte-exact for the idiom.
'   * "Could not save replay!" is passed to TScreen.DoMessage as a raw literal, not through
'     GetText -- no GetText call appears anywhere in the decompiled call list for this
'     branch, unlike the CMESSAGE_* keys used elsewhere in the game.
'!Global g_userpath:String
'!Global g_pitch_int21:Int
'!Global g_balls:TList
'!Global g_ball_sortmode:Int
'!Global g_players:TList
'!Global g_team_int03:Int
'!Global g_replayframes:TList
Local n:Int = 1
Local fn:String
Local found:Int
Repeat
	found = False
	Local numstr:String = String(n)
	If n < 10 Then numstr = "0" + String(n)
	fn = a0.tla + "v" + a1.tla + "_" + numstr + ".rep"
	Local f:String
	Local dir:Int = ReadDir(g_userpath + "Replays/")
	Repeat
		f = NextFile(dir)
		If f = fn Then found = True
		If f = "" Then Exit
	Forever
	n = n + 1
Until Not found

Local bank:TBank = CreateBank(0)
Local bs:TStream = CreateBankStream(bank)
If Not bs
	TScreen.DoMessage("Could not save replay!", 0, 0)
	Return ""
Else
	Local rep:TReplay = New TReplay
	rep.name = fn
	rep.teamid1 = a0.id
	rep.teamid2 = a1.id
	rep.teamname1 = a0.tla
	rep.teamname2 = a1.tla
	rep.score1 = a2
	rep.score2 = a3
	rep.pitchtype = a4
	rep.mowtype = a5
	rep.doingweather = a6
	rep.weathertype = a7
	rep.kit1cols = TKitStrings.CreateKitStrings(a0.kitplayer.newcol[1], a0.kitplayer.newcol[4], a0.kitplayer.newcol[7], a0.kitplayer.newcol[10], a0.kitplayer.style)
	rep.kit2cols = TKitStrings.CreateKitStrings(a1.kitplayer.newcol[1], a1.kitplayer.newcol[4], a1.kitplayer.newcol[7], a1.kitplayer.newcol[10], a1.kitplayer.style)
	rep.keeperkit1cols = TKitStrings.CreateKitStrings(a0.kitkeeper.newcol[1], a0.kitkeeper.newcol[4], a0.kitkeeper.newcol[7], a0.kitkeeper.newcol[10], a0.kitkeeper.style)
	rep.keeperkit2cols = TKitStrings.CreateKitStrings(a1.kitkeeper.newcol[1], a1.kitkeeper.newcol[4], a1.kitkeeper.newcol[7], a1.kitkeeper.newcol[10], a1.kitkeeper.style)
	rep.fixlevel = a8
	rep.stadiumsize = g_pitch_int21
	rep.WriteHeader(bs)

	For Local rf:TReplayFrame = EachIn g_replayframes
		If rf <> Null Then rf.SaveFrame(bs)
	Next

	If g_balls <> Null
		g_ball_sortmode = 1
		g_balls.Sort(1)
		For Local b:TBall = EachIn g_balls
			For Local rf2:TReplayFrame = EachIn b.replayframes
				If rf2 <> Null Then rf2.SaveFrame(bs)
			Next
		Next
	EndIf

	If g_players <> Null
		g_team_int03 = 1
		g_players.Sort(1)
		For Local p:TPlayer = EachIn g_players
			For Local rf3:TReplayFrame = EachIn p.replayframes
				If rf3 <> Null Then rf3.SaveFrame(bs)
			Next
		Next
	EndIf

	Local zw:ZipWriter = New ZipWriter
	If zw.OpenZip(g_userpath + "Replays/" + fn, 0)
		zw.AddStream(bs, "newstarsoccerfivereplayfile", "")
	EndIf
	CloseStream(bs)
	zw.CloseZip("")
	Return fn
EndIf
