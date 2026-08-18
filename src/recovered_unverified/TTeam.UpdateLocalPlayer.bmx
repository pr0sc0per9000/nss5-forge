' TTeam.UpdateLocalPlayer
' VA 0x004DE0C7   937 bytes   vtable slot 0x68   sig ()i   KIND=Method
' Ghidra source: extracted/decomp/TTeam.UpdateLocalPlayer@004de0c7.c
'                extracted/decomp_annotated/TTeam.UpdateLocalPlayer@004de0c7.c (symbol layer)
'
' TOP-LEVEL SHAPE -- Ghidra's brace nesting (one big If/Else tree with a single trailing
' `return 0`) is MISLEADING here: a decompiler freely merges any number of physically
' distinct `mov eax,0 / jmp epilogue` return sites into one logical `return 0` whenever
' they're all just returning the same constant, so it cannot tell "shared implicit
' trailing return" apart from "many separate explicit `Return 0` statements". Direct
' disassembly (scripts/disasm.py 0x004de0c7) shows the latter: this body is a CASCADE of
' independent early-return guards, matching codegen-patterns.md guide 3f's worked example
' ("cmp [g],0 / jne body / mov eax,0 / jmp end is an early return, not an If-block. As an
' If-block it comes out 109 bytes instead of 116"). Evidence: at least 6 DISTINCT `B8
' 00000000 E9 xxxxxxxx` (mov eax,0;jmp 0x4de469) sequences appear at different addresses
' throughout the function body (0x4de0d9, 0x4de1df, 0x4de232, 0x4de25e, 0x4de2dd,
' 0x4de313, 0x4de39b) -- each is its OWN copy, not a shared jump target, which only
' happens when the source contains an explicit `Return 0` at that point (a plain "skip
' past sibling Else" jump would target a shared label instead, as seen at 0x4de462 for
' the handful of guards that really are the last statement in the function with nothing
' to preserve).
'   cmp [edi+0x18],0 / jne short / mov eax,0 / jmp epilogue   -- `If controller = 0 Then Return 0`
'   cmp [edi+0x3c],0 / jle (skip)                              -- `If newstarselno > 0` (immediate
'     is 0 with jle, not 1 with jl -- matches TPlayer.DoTacklingAI.bmx / TScreen_Formation.
'     RefreshButtons.bmx's own verified `newstarselno > 0` idiom, not `>= 1`)
'   squad loop, then its own explicit `Return 0`, THEN (only reached via the guard's skip
'     jump) the ball logic -- ball logic is NOT the Else of the newstarselno guard, it is
'     simply "whatever comes after the guard's EndIf", textually identical byte-wise but a
'     different source shape (no Else keyword at all).
'
' FIELDS (extracted/object_model.json):
'   TTeam    id +0x08, controller +0x18, squad:TList +0x1C, lastchangeplayer +0x20,
'            newstarselno +0x3C
'   TBall    x +0x18(f), y +0x1C(f), metax +0x30(f), metay +0x34(f), teaminpossession +0x60,
'            kicktime +0x64, controlledby:TPlayer +0x70, lastkickedby:TPlayer +0x74,
'            setpiecetaker:TPlayer +0x80, passtoid +0x9C
'   TPlayer  newstar +0x08, teamid +0x14, controller +0x18, goalside +0x8C,
'            distancetoball(f) +0xD0, selectionno +0xBC, matchstats:TStats_Match +0x188
'   TStats_Match reds +0x10
'
' CLASS-TABLE CALLS (classtable+slot, static -- must be TYPE-QUALIFIED so bcc emits the
' classtable call and not a Self-vtable dispatch, per TPlayer.PassAI.bmx's note):
'   0x00C5AEDC = TBall+0x44    = GetActiveBall():TBall           (called ONCE -> Local ball)
'   0x00C5BAA4 = TEngine+0x74  = SetPiece():i                    (result used once, inline)
'   0x00C5FAB0 = TPlayer+0x164 = GetHumanPlayer():TPlayer        (called ONCE -> Local human)
'   0x00C5FAB4 = TPlayer+0x168 = GetPlayerById(i):TPlayer        (called ONCE -> Local recv)
'   0x00C5D998 = TPitch+0x6C   = YardsToPixels(f)f
'   downcast class table 0x00C5F94C = TPlayer (the squad-loop EachIn)
' Self's own methods reached at vtable+0x6C = NewLocalPlayer(:TPlayer)i and vtable+0x90 =
' GetPlayerNearestToXY(i,i,i,:TPlayer,i):TPlayer (signature/Locals per
' src/recovered/TTeam.GetPlayerNearestToXY.bmx).
'
' bcc has no CSE (guide 6), and the annotated call table shows exactly ONE call site each
' for GetActiveBall, GetHumanPlayer and GetPlayerById in this body, so each result is
' captured in a Local and reused rather than re-called (ball / human / recv below). `recv`
' is declared INSIDE the `ball.passtoid > 0` guard, not before it -- raw bytes show the
' GetPlayerById call itself is skipped (never executed) when passtoid <= 0, so the guard
' must enclose the Local's declaration, not just its use.
'
' The YardsToPixels() call at VA 0x004de37f decompiles with NO visible argument (Ghidra drops
' it); confirmed by direct disassembly at 0x004de37a: `push 0x40a00000` immediately before the
' `call [0xc5d998]` -- 0x40A00000 = 5.0f. So the call is YardsToPixels(5.0).
'
' `If closeToBall Then Return 0` (bare-truthy, direct `cmp eax,0` on the Int local -- no
' setne/movzx, since closeToBall is already 0/1) immediately precedes the px/py/nearest
' code, which runs unconditionally afterward with no EndIf/Else machinery of its own --
' i.e. NOT `If Not closeToBall Then <px,py,nearest> EndIf`. Both source forms are logically
' identical but (per guide 3f) compile to different bytes; the guard form is what matches.
'
' Globals -- names/types are the ones scripts/explain_global.py reports for each address
' (checked against extracted/global_alias_unified.tsv's adjudicated canonical name, and
' confirmed already in live use in src/assembled/nss5_assembled.bmx):
'   g_player_b:Int        0x00C5B1FC  match-state marker (8 = "just scored" per
'                          TTeam.UpdatePlayerDestinations' own g_matchstate=8/g_newstar use;
'                          canonical alias target for g_matchstate/g_player_int01/etc, 176
'                          uses already in the assembled source)
'   g_newstar:TPlayer     0x00C5B248  the story-mode tracked player (canonical over
'                          g_player_tplayer01/g_scorer/g_myprofile, 9 uses already assembled)
'   g_matchtime:Int       0x00C6EFD4  running match clock in ms (canonical over
'                          g_player_int50/g_matchtimer/g_millis/etc, 189 uses already assembled)
'   g_ball_float14:Float  0x00C5A500  small time-window constant added to ball.kicktime
	Method UpdateLocalPlayer:Int()
		'!Global g_player_b:Int
		'!Global g_newstar:TPlayer
		'!Global g_matchtime:Int
		'!Global g_ball_float14:Float
		If controller = 0 Then Return 0
		If newstarselno > 0
			For Local p:TPlayer = EachIn squad
				If p.newstar <> 0 And p.matchstats.reds = 0 And p.selectionno < 11
					p.controller = 1
				Else
					p.controller = 0
				EndIf
			Next
			Return 0
		EndIf
		Local ball:TBall = TBall.GetActiveBall()
		If ball <> Null
			If g_player_b = 8 And g_newstar <> Null And g_newstar.teamid = id
				NewLocalPlayer(g_newstar)
				Return 0
			EndIf
			If TEngine.SetPiece() <> 0
				If ball.setpiecetaker <> Null And ball.setpiecetaker.teamid = id
					NewLocalPlayer(ball.setpiecetaker)
				EndIf
				Return 0
			EndIf
			If ball.controlledby <> Null And ball.controlledby.teamid = id
				NewLocalPlayer(ball.controlledby)
				Return 0
			EndIf
			If ball.passtoid = 0 And ball.lastkickedby <> Null And ball.lastkickedby.teamid = id And g_matchtime < ball.kicktime + g_ball_float14
				NewLocalPlayer(ball.lastkickedby)
				Return 0
			EndIf
			If ball.passtoid > 0
				Local recv:TPlayer = TPlayer.GetPlayerById(ball.passtoid)
				If recv.teamid = id
					NewLocalPlayer(recv)
					Return 0
				EndIf
			EndIf
			If lastchangeplayer = 0 Or lastchangeplayer + 500 < g_matchtime
				Local human:TPlayer = TPlayer.GetHumanPlayer()
				Local hgs:Int = 0
				If human <> Null Then hgs = human.goalside
				Local closeToBall:Int = False
				If hgs <> 0 Then closeToBall = human.distancetoball < TPitch.YardsToPixels(5.0)
				If closeToBall Then Return 0
				Local px:Int = Int(ball.x)
				Local py:Int = Int(ball.y)
				If ball.controlledby = Null And ball.lastkickedby <> Null And ball.lastkickedby.teamid = id
					px = Int(ball.metax)
					py = Int(ball.metay)
				EndIf
				Local nearest:TPlayer = GetPlayerNearestToXY(px, py, 0, Null, ball.teaminpossession <> id)
				If nearest <> Null Then NewLocalPlayer(nearest)
			EndIf
		EndIf
	End Method
