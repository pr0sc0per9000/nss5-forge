' TPlayer.RenderReplay
' VA 0x004fe75d   605 bytes   vtable slot 0x214   sig (f)i   KIND=Method
' byte-identical vs NSS5.exe (605/605, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=24), verified with NSS5_NO_LEARN=1.
'
' Global names are ours (types load-bearing): 0x00C5D634 Int, 0x00C5DE70 Int,
' 0x00C5DE44 Float, 0x00C5D240 Int.  Float constants read from NSS5.exe: 0x42060000 = 33.5,
' 0x00C7A6C4 = 0.8, 0x3EB33333 = 0.35, 0x3F400000 = 0.75.
'
' The 16 AddDrawOb arguments were taken from the push sequence, not from Ghidra's printed
' list -- Ghidra splits each call across the previous one.
' `lim :- TPitch.YardsToPixels(33.5)` (not `lim = lim - ...`): the call result is on the
' x87 stack BEFORE `fld [ebp-0xc]` (0x004FE78B), i.e. the RHS is evaluated first (16.1).
' The early guard is `If px < lim / Return 0 / Else ... End If`: bcc folds the negation into
' the setcc, so the original's `setae` is what the `<` spelling produces.
'!Global g_player_int16:Int
'!Global g_player_int33:Int
'!Global g_player_float02:Float
' g_options_int05's original data-section value is 1 (read from NSS5.exe at
' 0x00C5D240 -- codegen-patterns 21.1/21.3).
'!Global g_options_int05:Int = 1
Local px:Float = Self.x
Local lim:Float = -g_player_int16
lim :- TPitch.YardsToPixels(33.5)
If px < lim
	Return 0
Else
	Local xx:Float = Self.x * a0 + Self.oldx * (1.0 - a0)
	Local yy:Float = Self.y * a0 + Self.oldy * (1.0 - a0)
	Local zz:Float = Self.z * a0 + Self.oldz * (1.0 - a0)
	Local sc:Float = g_player_float02
	If Self.KeeperDiving() And Self.xvel < 0.0
		sc = -sc
	ElseIf Self.facing = 0
		sc = -sc
	End If
	TDrawOb.AddDrawOb(Self.imgPlayer, xx, yy, zz, Self.imageframenumber, 3, 1.0, Int(Self.spriterotation), "FFFFFF", sc, g_player_float02, 3, 0, "", 0, 0)
	If Self.obtext.length And g_options_int05
		TDrawOb.AddDrawOb(Null, xx, yy - g_player_int33, 0, 0, 3, 0.75, 0, "FFFFFF", 0.35, 0.35, 3, 0, Self.obtext, 0, 0)
	End If
	Local sy:Int = -2
	Local sr:Int = Int(Self.spriterotation)
	Self.GetShadowOffsetAndRot(Self.imageframenumber, Varptr sy, Varptr sr)
	TDrawOb.AddDrawOb(Self.imgPlayer, xx + 1.0, yy + sy, 0, Self.imageframenumber, 2, 0.35, sr, "000000", sc * 1.0, g_player_float02 * 0.8, 3, 0, "", 0, 0)
End If
