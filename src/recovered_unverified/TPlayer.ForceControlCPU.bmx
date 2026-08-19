' TPlayer.ForceControlCPU
' byte-identical vs NSS5.exe
' VA 0x004F1491   1305 bytes   KIND=Method, SIG ()i, class-table slot 0x84
' Reconstructed directly against harness.disasm_original(0x004F1491,1305) -- the FULL
' original disassembly, not just Ghidra's C -- because several branches here only read
' correctly from the raw setcc/jcc shapes. Every condition below cites the instruction
' that fixed it.
'
' GLOBALS (name/type from scripts/explain_global.py; g_player_tplayer02 confirmed the
' correct name+type for 0x00C5DEA4 via extracted/globals_final.tsv + globals_corrections.tsv
' -- despite several older TPlayer siblings using g_ball/g_activeball/g_player_selected for
' the very same slot, "TBall g_player_tplayer02" is the hand-verified, high-confidence row):
'   0x00C5DEA4 g_player_tplayer02:TBall  -- the match ball.
'   0x00C5B1FC g_player_int01:Int       -- match-state code (already established elsewhere).
'   0x00C5B248 g_player_tplayer01:TPlayer -- globals_final: vtable-call slots 0x44/0x6c/0x8c/
'     0x1ec, only TPlayer has all four; "the newstar/selected player".
'   0x00C6CF90 g_training_int03:Int     -- training-mode flag (already established).
'   0x00C6EFD4 g_player_int50:Int       -- match clock in ms (hand-verified elsewhere).
'   0x00C79748 g_player_int51:Int       -- a "last forced control" timestamp; only written
'     here (twice) as g_player_int51 = g_player_int50, then used for a 500ms debounce.
'   0x00C5D650 g_pitch_int11:Int        -- pitch half-height-ish Int (already established in
'     TPitch.InsidePenaltyBox.bmx / TPlayer.GetMatchOverPosition.bmx).
'   0x00C5A500 g_ball_float14:Float     -- globals_final: Float, high confidence, TBall
'     subsystem, x87 dword access.
'
' CLASS-TABLE CALLS (not Globals -- resolved via the indirect-call VAs, guide 3f):
'   0x00C5BAA4 = TEngine class table + 0x74 = SetPiece()i.
'   0x00C5D998 = TPitch  class table + 0x6C = YardsToPixels(f)f.
'   Self slot 0x1A0 = PlayerOnFeet()i; Self slot 0x174 = GetMyTeam():TTeam;
'   Self slot 0x128 = ChaseBall(f,f,:TPlayer)i (sig confirmed from TPlayer.ChaseBall.bmx).
'   TBall slot 0x88 = KeeperHolding()i (confirmed from TEngine.UpdateMatchTime.bmx /
'     TTraining.UpdateShooting2.bmx headers).
'   FUN_00505DA2 = the recovered module Function Dist2D(f,f,f,f)f.
'   FUN_004A7FE0 = _bbFloatAbs -> Abs(Float) (confirmed family-wide, e.g. TPlayer.
'     DoCelebrations.bmx, TPlayer.DoDribbling.bmx).
'
' FIELDS (object_model.json, TPlayer unless noted): controller +0x18, matchstats +0x188
'   (:TStats_Match; its reds is +0x10), selectionno +0xBC, id +0x8, teamid +0x14,
'   distancetoball +0xD0 (Float), joy +0x158 (:TJoy; kickbuttondown +0x1C, kickbuttonhits
'   +0x20), x/y +0x4C/+0x50. TBall: setpiecetaker +0x80, controlledby +0x70, lastkickedby
'   +0x74, teaminpossession +0x60, setpiecex/setpiecey +0x48/+0x4C (Int), jumpx/jumpy
'   +0x38/+0x3C, passtoid +0x9C, kicktime +0x64, x/y +0x18/+0x1C. TTeam: newstarselno +0x3C.
'
' CODEGEN NOTES, each read directly off the bytes rather than guessed:
'   * Top guard is a plain early-return (guide 3f: `cmp [ebx+0x18],1 / je body` with the
'     Return inline as the fall-through) -- `If Self.controller <> 1 Then Return 1`, NOT a
'     wrapping If/Else; the rest of the function is unindented after it.
'   * Every subsequent Return-1 guard is the SAME flat early-return shape (direct
'     `cmp/je-skip` with the Return physically first) -- none of them wrap the remainder of
'     the function in an Else.
'   * Some boolean terms are plain truthiness (raw value tested with a bare `cmp eax,0`, NO
'     setcc/movzx) and some are explicit relational comparisons (setg/sete/setne + movzx).
'     Matched exactly per term below: `Self.matchstats.reds > 0` and `Self.selectionno > 10`
'     are explicit (setg); `TEngine.SetPiece()` is plain truthy (no setne); ball<>Null and
'     setpiecetaker=Self/<>Null are explicit (setne/sete); `g_training_int03 And Self.id`
'     is plain truthy for BOTH terms (no setcc anywhere in that pair -- confirmed at
'     0x004F17A9-0x004F17BB); `g_player_tplayer02.KeeperHolding()` is plain truthy (no
'     setne at 0x004F178F) while the following `controlledby <> Self` IS explicit (setne);
'     `Self.joy.kickbuttondown` is plain truthy (no setne at 0x004F1868) while
'     `controlledby <> Self` and `g_player_int01 = 1` and the clock compare are explicit.
'   * The dispatch on g_player_int01 is a genuine 13-way Select (guide 10.2): all thirteen
'     `cmp eax,N / je` (N=0..12) run back to back before any Case body, with a single `jmp`
'     past all of them for the no-match/default path. Cases 1, 3 and 12 are empty (fall
'     straight through to the shared tail).
'   * The Case-6 (state 6) and the KeeperHolding-block's distance test share one idiom:
'     `g_player_int51 = g_player_int50 : Return 1` when too far, else a 500ms debounce
'     (`If g_player_int50 < g_player_int51 + 500 Then Return 1`) -- written out twice,
'     verbatim, not factored (bcc has no CSE, and neither did whoever wrote this).
'   * The ChaseBall If/Else (jumpx branch) is the two-armed "branch swap" shape (guide 21):
'     writing it the Ghidra-literal way (`If jumpx=0.0 Then <x,y> Else <jumpx,jumpy>`) gives
'     the WRONG physical order. The original's bytes are `sete`(jumpx==0.0) with the
'     jumpx/jumpy call as fall-through and the x/y call as the jne target -- reproduced by
'     writing the condition negated-and-swapped: `If jumpx <> 0.0 Then <jumpx,jumpy> Else
'     <x,y>`.
'   * Float constants read directly from the original's immediate operands, not guessed:
'     TPitch.YardsToPixels(10.0) at 0x004F166D (`push 0x41200000`) in Case 5, and
'     TPitch.YardsToPixels(20.0) at 0x004F17CE (`push 0x41A00000`) in the KeeperHolding
'     block. `g_pitch_int11 - 50` (0x32) in Case 6; `+100` (0x64) on kickbuttonhits;
'     `+500` (0x1F4) in both debounce checks.
'!Global g_player_tplayer02:TBall
'!Global g_player_int01:Int
'!Global g_player_tplayer01:TPlayer
'!Global g_training_int03:Int
'!Global g_player_int50:Int
'!Global g_player_int51:Int
'!Global g_pitch_int11:Int
'!Global g_ball_float14:Float
If Self.controller <> 1 Then Return 1
If Self.matchstats.reds > 0 Or Self.selectionno > 10 Then Return 1
If TEngine.SetPiece() And g_player_tplayer02 <> Null And g_player_tplayer02.setpiecetaker = Self Then Return 1
Select g_player_int01
Case 0
	Return 1
Case 1
Case 2
	Return 1
Case 3
Case 4
	If g_player_tplayer02 <> Null And g_player_tplayer02.setpiecetaker <> Null And g_player_tplayer02.setpiecetaker.selectionno = 0 Then Return 1
Case 5
	If g_player_tplayer02 <> Null And g_player_tplayer02.teaminpossession <> Self.teamid And Dist2D(Self.x, Self.y, g_player_tplayer02.setpiecex, g_player_tplayer02.setpiecey) < TPitch.YardsToPixels(10.0) Then Return 1
Case 6
	If Abs(Self.y) > g_pitch_int11 - 50
		g_player_int51 = g_player_int50
		Return 1
	End If
	If g_player_int50 < g_player_int51 + 500 Then Return 1
Case 7
	Return 1
Case 8
	If g_player_tplayer01 <> Self Then Return 1
Case 9
	Return 1
Case 10
	Return 1
Case 11
	Return 1
Case 12
End Select
If Not Self.PlayerOnFeet() Then Return 0
If g_player_tplayer02 <> Null
	If g_player_tplayer02 <> Null And g_player_tplayer02.KeeperHolding() And g_player_tplayer02.controlledby <> Self
		If g_training_int03 And Self.newstar Then Return 0
		If Self.distancetoball < TPitch.YardsToPixels(20.0)
			g_player_int51 = g_player_int50
			Return 1
		End If
		If g_player_int50 < g_player_int51 + 500 Then Return 1
	End If
	If g_player_tplayer02.passtoid = Self.id And Self.GetMyTeam().newstarselno = 0 Then Return 1
	If Self.joy.kickbuttondown And g_player_tplayer02.controlledby <> Self And g_player_int01 = 1 And g_player_int50 > Self.joy.kickbuttonhits + 100
		If g_player_tplayer02.jumpx <> 0.0
			Self.ChaseBall(g_player_tplayer02.jumpx, g_player_tplayer02.jumpy, g_player_tplayer02.controlledby)
		Else
			Self.ChaseBall(g_player_tplayer02.x, g_player_tplayer02.y, g_player_tplayer02.controlledby)
		End If
		Return 1
	End If
	If Self.selectionno = 0 And g_player_tplayer02.passtoid = 0 And g_player_tplayer02.lastkickedby = Self And g_player_int50 < g_player_tplayer02.kicktime + g_ball_float14 Then Return 1
End If
Return 0
