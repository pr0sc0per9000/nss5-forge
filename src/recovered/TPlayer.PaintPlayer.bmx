' TPlayer.PaintPlayer
' VA 0x004EE011   161 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Method, SIG=(:TKit)i, class-table slot 0x40
' ORACLE 161/161 reloc_masked=8, re-run under NSS5_NO_LEARN=1 (learned_helpers
'   empty, so no call operand was masked by a name this body taught the table).
' Assumptions: FUN_005AE2BC = _brl_max2d_LoadAnimImage, FUN_005AE336 =
' _brl_max2d_SetImageHandle. TKit slot 0x3C = GetPaintedPlayer($,i,i,$):TPixmap.
' Globals 0x00C5DE30/34/38/3C/40 are all Int in globals_final.tsv and are used here as the
' cell width, cell height, frame count and the two image-handle coordinates.
'
' The intermediate TPixmap MUST be a Local: the original evaluates GetPaintedPlayer first
' and only then pushes LoadAnimImage's remaining arguments. Inlining the call into the
' argument list reverses the push order (diverges at byte 14).
'
' The '!Field pragma re-types imgPlayer as BRL.Max2D's TImage. The harness emits a game
' stub Type called TImage (it is in class_tables.tsv) which collides with the module one,
' and without the qualification bcc reports "Unable to convert from 'TImage' to 'TImage'".
	Method PaintPlayer:Int(a0:TKit)
		'!Field imgPlayer:brl.max2d.TImage
		'!Global g_player_int27:Int
		'!Global g_player_int28:Int
		'!Global g_player_int29:Int
		'!Global g_player_int30:Int
		'!Global g_player_int31:Int
		Local p:TPixmap = a0.GetPaintedPlayer(bootcol, skincol, haircol, glovecol)
		imgPlayer = LoadAnimImage(p, g_player_int27, g_player_int28, 0, g_player_int29, -1)
		SetImageHandle(imgPlayer, g_player_int30, g_player_int31)
	End Method
