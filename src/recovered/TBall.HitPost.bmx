' TBall.HitPost  -- KIND=Method, sig (f)i, slot 0x7C
' VA 0x004CAC9B   467 bytes
' byte-identical vs NSS5.exe (467/467, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=26)
'
' ASSUMPTIONS
'   Globals declared (names ours). globals_final.tsv types four of these only as
'   "Object ... init=bbNullObject, no call-site typing"; they are the sound/channel pair
'   arguments of _brl_audio_PlaySound (0x0059B25E), so TSound/TChannel is inferred from
'   that call, not from the table. The declared types are load-bearing only in that they
'   must be objects; no method is dispatched through them.
'     '!Global g_ball_postsound:TSound      = 0x00C5A51C
'     '!Global g_ball_postchannel:TChannel  = 0x00C5A510
'     '!Global g_crowd_oohsound:TSound      = 0x00C5B368
'     '!Global g_crowd_oohchannel:TChannel  = 0x00C5B348
'     '!Global g_matchmode:Int              = 0x00C5B1FC  (globals_final 'verified' Int)
'     '!Global g_trainingmode:Int           = 0x00C6CF90  (globals_final Int, 53 writes)
'   Fields from object_model.json: active @0xC, x @0x18, y @0x1C, oldx @0x24, oldy @0x28,
'     velocity @0x54, direction @0x5C, controlledby:TPlayer @0x70, posthit @0x90,
'     curlamount @0x98.
'   Slot 0xD0 = TBall.CheckLongShotRating()i (vtable_map.tsv).
'   Runtime/BRL: 0x00505B91 LogLine (module Function, argument is this function's own
'     name, read from .rdata as "HitPost"), 0x0059B25E _brl_audio_PlaySound,
'     0x004A1F10 _bbCos, 0x004A1F00 _bbSin, 0x004A1F90 ATan2, 0x0059F048 _brl_random_Rnd.
'   Float literals read out of .rdata: 0.2 / 0.4 / 0.6 / 0.8 thresholds, +-60 and +-30
'     direction deltas, and Rnd's two DOUBLE operands -10.0 and 10.0.
'   CORRECTED: the multiplier applied to velocity (`fmul dword [0x00C5A4D8]`) was
'     written as the literal placeholder 0.5. 0x00C5A4D8 is g_ball_float04 -- already named
'     in globals_final.tsv and already used the identical way (bounce damping on hitting an
'     obstacle) in the sibling TBall.CheckAdHoardings.bmx ("Self.velocity = Self.velocity *
'     g_ball_float04"). This is not a numeric constant at all; it is the module Global. Fixed
'     to read the Global instead of a hardcoded literal. Re-verified MATCH 467/467.
'   Cascade shape: bcc emits the INVERTED setcc for a float `<` -- `fld const / fld a0 /
'     fucompp / sahf / setae / jne <next test>` is the lowering of `If a0 < 0.2`, with the
'     fall-through being the taken body. The 0.6..0.8 band deliberately has an EMPTY
'     ElseIf arm; that is what the original does.
'
' CODEGEN NOTE (cost 3 probe rounds): the two trig results must be written as two Float
' Locals, with the negation applied inside the SECOND Local's initialiser.
'   ATan2(-Sin(d), Cos(d))                        -> 461 bytes (no spill at all)
'   Local c = Cos(d) ; ATan2(-Sin(d), c)          -> 461 bytes (one Local still stays in x87)
'   Local c = Cos(d) ; Local sn = Sin(d) ; ATan2(-sn, c)
'                                                 -> 467 bytes, but `fchs` lands AFTER the
'                                                    `fld [ebp-0xc]` instead of before it
'   Local c = Cos(d) ; Local sn = -Sin(d) ; ATan2(sn, c)   -> exact
' This is guide 10.5 ("the LAST Float Local stays on the x87 stack; earlier ones spill")
' plus a corollary: a unary minus in a Float Local's initialiser is emitted at the point
' the value is produced, so it fixes the position of `fchs` relative to the reload.
'!Global g_ball_postsound:TSound
'!Global g_ball_postchannel:TChannel
'!Global g_crowd_oohsound:TSound
'!Global g_crowd_oohchannel:TChannel
'!Global g_matchmode:Int
'!Global g_trainingmode:Int
'!Global g_ball_float04:Float
	LogLine("HitPost")
	If Self.controlledby <> Null Then Return 0
	PlaySound(g_ball_postsound, g_ball_postchannel)
	If Self.active And g_matchmode = 1 And g_trainingmode = 0
		PlaySound(g_crowd_oohsound, g_crowd_oohchannel)
		Self.CheckLongShotRating()
	EndIf
	Self.x = Self.oldx
	Self.y = Self.oldy
	Self.velocity = Self.velocity * g_ball_float04
	Self.curlamount = 0
	Self.posthit = 1
	Local c:Float = Cos(Self.direction)
	Local sn:Float = -Sin(Self.direction)
	Self.direction = ATan2(sn, c)
	If a0 < 0.2
		Self.direction :+ 60
	ElseIf a0 < 0.4
		Self.direction :+ 30
	ElseIf a0 < 0.6
	ElseIf a0 < 0.8
		Self.direction :- 30
	Else
		Self.direction :- 60
	EndIf
	Self.direction = Self.direction + Rnd(-10, 10)
	Return 0
