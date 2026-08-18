' TPlayer.HeadBallAdvanced
' VA 0x004F8F5D   505 bytes   vtable slot 0x11c   sig ()i
' byte-identical vs NSS5.exe (505/505, original length from Ghidra's inventory)
' harness mode=reloc, reloc_masked=25.  MATCHED ON THE FIRST ATTEMPT.
' Body-only format: statements only, parameters are a0, a1, ...
' CALL TARGETS RESOLVED
'   FUN_00505b91 = the recovered module Function LogLine ($) -- function-entry trace
'   FUN_004a79d0 = _bbStringFromFloat  (kickdirection is a Float, hence String(f))
'   FUN_004a7c20 = _bbStringConcat
'   FUN_005b9690 = _bbFloatToInt, i.e. Int(x)
'   FUN_0059f089 = _brl_random_Rand ; Rand(x) compiles to Rand(x,1), which is the
'                  stray `1` Ghidra shows merged into the _bbFloatToInt call
'   slot 0x84 on 0x00c5dea4 = TBall.NewController(:TPlayer)
'   slot 0x68 on 0x00c5dea4 = TBall.Kick(:TPlayer,f,f,i,i)
'   slot 0x228 on Self      = TPlayer.AddStat(i,f,f,f,f); the four Float zeros are
'                             emitted as `push 0` immediates, not fld/fstp.
' TPlayer fields: kickpower +0xc0 (f), kickdirection +0xc4 (f), teammateid +0xf0 (i),
'   distancetoteammate +0xfc (f), joy +0x158 (:TJoy), heading +0x174 (f).
'   TJoy.direction +0x14 (f), TJoy.activebutton +0x24 (i).
' SHAPE NOTES
'   * the dispatch is a Select, not If/ElseIf: three cmp/je back to back followed by
'     `E9 rel32` for the no-match path, exactly the tell in codegen-patterns 10.2.
'   * `Local n:Int = 5` is set BEFORE the Select (mov edi,5 precedes the subject load)
'     and re-set inside each Case.
'   * FLOAT CONSTANTS ARE REAL, NOT PLACEHOLDERS. The four are `fld [rdata]` operands
'     whose ADDRESSES are reloc-masked, which does not make their VALUES unobservable:
'     the address is masked, but the value sits AT that address in the exe and reads
'     out directly.
'       0x00C79F78 = 15.0    0x00C79FAC = 50.0
'       0x00C79FE0 = 0.07    0x00C7A010 = 0.08
'     Found by scripts/check_floats.py, which exists precisely because a MATCH does not
'     certify a masked constant: all four sites read 12.34 and the body still matched.
'   * the three log strings are pushed by address only; "A"/"B"/"C" stand for
'     0x00c79f7c / 0x00c79fb0 / 0x00c79fe4, and 0x00c79f4c is the function-name trace.
' module Globals assumed by this body (names ours, types load-bearing):
'   Global g_ball:TBall   ' 0x00c5dea4 -- globals_final.tsv type_source=verified,
'                         '   confidence=high (hand-verified in globals_corrections.tsv);
'                         '   the row carries a warning that the TPlayer usage guess
'                         '   is unsound.  Slots 0x68/0x84 resolve
'                         '   to TBall.Kick / TBall.NewController, which is what the
'                         '   argument lists here fit, so TBall it is.
'!Global g_ball:TBall
LogLine("HeadBallAdvanced")
Local ab:Int = Self.joy.activebutton
g_ball.NewController(Self)
Self.kickdirection = Self.joy.direction
Self.kickpower = 15.0
Local n:Int = 5
Select ab
	Case 1
		LogLine("CBUTTON_SHOOT dir:" + String(Self.kickdirection))
		Self.kickpower = 50.0
		n = 5
	Case 2
		LogLine("CBUTTON_PASS dir:" + String(Self.kickdirection))
		Self.kickpower = Self.distancetoteammate * 0.07
		n = 4
	Case 3
		LogLine("CBUTTON_LOB dir:" + String(Self.kickdirection))
		Self.kickpower = Self.distancetoteammate * 0.08
		n = 6
End Select
Self.kickpower = Self.kickpower - Rand(Int(Self.heading))
Self.kickdirection = Self.kickdirection + Rand(Int(-Self.heading), Int(Self.heading))
g_ball.Kick(Self, Self.kickdirection, Self.kickpower, n, Self.teammateid)
Self.AddStat(6,0,0,0,0)
