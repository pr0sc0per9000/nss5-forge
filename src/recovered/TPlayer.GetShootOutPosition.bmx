' TPlayer.GetShootOutPosition  -- KIND=Method (Self = param_1)
' VA 0x004FA2A3   461 bytes   sig ()i   slot 0x14C
' byte-identical vs NSS5.exe (461/461, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=17)
'
' ASSUMPTIONS
'   Globals (names ours):
'     0x00C5DEA4 -> g_shootout_ball:TBall   (globals_final type_source=verified, TBall;
'                   the earlier TPlayer guess is recorded there as unsound)
'     0x00C5B218 -> g_shootout_team:TTeam   (globals_final says TKit with a flagged
'                   TKit=2/TTeam=1 construction conflict.  It must be TTeam here: the
'                   code reads field +8 and compares it with Self.teamid:Int, and
'                   TTeam+8 = id:Int whereas TKit+8 = pixmap:TPixmap.)
'     0x00C7A0F0 -> g_shootout_xoff:Float   } both read back 180.0 from
'     0x00C7A0F4 -> g_shootout_yoff:Float   } NSS5.exe's data section, confirming they ARE
'                   module Globals (not literals folded into the operand) -- a Float Global
'                   and a Float literal emit the same `fadd dword [addr]` instruction, so
'                   the oracle alone could not distinguish them, but a baked non-zero value
'                   at that address settles it. Never stored to anywhere in the corpus, so
'                   the bare pragma this file used to carry defaulted the assembled build's
'                   copy to 0 -- see codegen-patterns 21.1. 180.0 = a half-turn, i.e. the
'                   run-up direction offset points the AWAY team's shootout takers back
'                   toward their own goal.
'   Calls resolved:
'     slot 0x144 = TPlayer.GetTunnelPosition(i), slot 0xB4 = TPlayer.UpdateKeeperPosition
'     0x00C5D998 = TPitch+0x6C = YardsToPixels (f)f  -> TPitch.YardsToPixels(...)
'     0x004A1F10 = _bbCos, 0x004A1F00 = _bbSin (runtime_helpers.tsv)
'     0x005B9690 = _bbFloatToInt, emitted by Int(...)
'   Fields: TPlayer +0x14 teamid, +0x7C desx:Float, +0x80 desy:Float, +0xBC selectionno,
'           +0x158 joy:TJoy (+0x14 direction:Float); TBall +0x48 setpiecex,
'           +0x4C setpiecey, +0x80 setpiecetaker:TPlayer.
'
' Shape notes: the first two tests are genuine early returns (`mov eax,0 / jmp epilogue`),
' not an If/ElseIf cascade.  The ball test is the bare-truth form `If g_shootout_ball`
' (setne al / movzx / cmp 0), not `<> Null`.  The sign flip is `px * -1` (imul ebx,ebx,-1),
' not `-px` (which would be `neg`).
'!Global g_ball:TBall
'!Global g_shootout_team:TTeam
'!Global g_shootout_xoff:Float = 180.0
'!Global g_shootout_yoff:Float = 180.0
	Method GetShootOutPosition()
		If Self.selectionno > 10
			Self.GetTunnelPosition(1)
			Return 0
		End If
		If Self.selectionno = 0
			Self.UpdateKeeperPosition()
			Return 0
		End If
		If g_ball And g_ball.setpiecetaker = Self
			Self.desx = g_ball.setpiecex + Cos(Self.joy.direction + g_shootout_xoff) * TPitch.YardsToPixels(0.5)
			Self.desy = g_ball.setpiecey + Sin(Self.joy.direction + g_shootout_yoff) * TPitch.YardsToPixels(0.5)
			Return 0
		End If
		Local px:Int = Int(TPitch.YardsToPixels(5.0) + TPitch.YardsToPixels(Self.selectionno))
		Local py:Int = Int(-TPitch.YardsToPixels(10.0))
		If Self.teamid = g_shootout_team.id Then px = px * -1
		Self.desx = px
		Self.desy = py
	End Method
