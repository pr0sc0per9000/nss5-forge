' TPlayer.CheckOffside
' VA 0x004FEEC4   678 bytes   vtable slot 0x224   sig ()i   KIND=Method
' byte-identical vs NSS5.exe (678/678, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=42)
' Body-only format: statements only, Self implicit.
' g_msg_style (0x00C5B1F8) original data-section value is 1750, read directly
' from NSS5.exe -- same address as g_engine_int17 in TEngine.DoYourSubstitutionOff.bmx
' etc. See codegen-patterns 21.1/21.3.
' assumptions (module Globals, names ours):
'   0x00C5B1F8 : Int         -- the on-screen-message style/duration selector
'   0x00C5B1C8 : TBitmapFont -- the message font (globals_final: construction, 1 site)
'   0x00C5B218 : TTeam       -- the home team. globals_final says TKit with a flagged
'                               CONFLICT (TKit=2; TTeam=1). The code reads +0x08 and compares
'                               it to TPlayer.teamid; TKit+0x08 is `pixmap:TPixmap` while
'                               TTeam+0x08 is `id:Int`, so it is TTeam. Trusting the code
'                               over the table (10.7 / 11.2).
'   0x00C5B28C, 0x00C5B290 : Int -- the per-side offside counters
'   0x00C5DEA4 : TBall       -- the match ball (type_source=verified; also 11.2's table)
' slots resolved: 0x00C6B264 = TScreenMessage classtable + 0x30 = TScreenMessage.Create
'   (i,i,$,i,:TBitmapFont,:TImage,f,$); 0x00C5BAA0 = TEngine + 0x70 = SetUpSetPiece(i,i,i,i);
'   0x00C5FAB0 = TPlayer + 0x164 = GetHumanPlayer():TPlayer -- written WITH the `TPlayer.`
'   prefix because 0x164 is a Function slot reached via the class table of this same Type but
'   the probe needs an explicit receiver-free static call; 0x00C5D998 = TPitch + 0x6C =
'   YardsToPixels(f)f. TPlayer 0x234 = AddPlayerRating(i,i,$), 0x174 = GetMyTeam():TTeam;
'   TFormation 0x5C = GetPosFromSelectionNo(i)i.
' ARGUMENT-COUNT WARNING (guide 10, "Ghidra merges args"): Ghidra prints
'   FUN_004c5549(&str,DAT_00c5b1f8,PTR_DAT_00c5b1c8,Null,0x3f800000,&str2) for GetText, which
'   takes ONE argument. Those five extra values are TScreenMessage.Create's own pushes.
'   Confirmed against the raw disassembly (`add esp,4` after the GetText call, `add esp,0x20`
'   after Create).
' runtime helpers named from runtime_helpers.tsv: 0x004A7410=_brl_retro_Lower -> Lower(),
'   0x004A7AC0=_bbStringFromInt and 0x004A7C20=_bbStringConcat -> the `"..." + Rand(4,1)`
'   concatenations. String literals read out of .data: 0x00C73E54="Offside",
'   0x00C5D680="FFFFFF", 0x00C7A734="CBOSSSHOUT_OFFSIDE", 0x00C7A764="CBOSSSHOUT_OFFSIDEPASS",
'   0x00C7A79C="CBOSSSHOUT_GOODBACKLINE".
' fields: offsidewhenkicked +0xB0, teamid +0x14, posxwhenkicked +0xA4, posywhenkicked +0xA8,
'   newstar +0x08, kickx +0x94, kicky +0x98, selectionno +0xBC, x +0x4C, y +0x50;
'   TBall.lastkickedby +0x74; TTeam.formation +0x24.
' load-bearing shape, and a correction to the decompilation:
'   * the distance test is `> ` with the (6,-2) call in the THEN branch. Ghidra renders it as
'     `<=` with the branches the other way round; written that way bcc emits `seta` where the
'     original has `setbe`. Same meaning, different bytes -- 10.1 again, this time on an x87
'     fucompp/setcc pair.
'   * the whole body is wrapped in `If Self.offsidewhenkicked <> 0 ... Return 1 EndIf` with
'     the implicit trailing 0; the opening `je` is a rel32 to the very end of the function,
'     which is what an enclosing block looks like (10.9).
'   * `Self.newstar` and `g_ball.lastkickedby.newstar` are bare truth values inside the And
'     chain; `<> 0` would add 9 bytes each.
	Method CheckOffside:Int()
		'!Global g_msg_style:Int = 1750
		'!Global g_font:TBitmapFont
		'!Global g_hometeam:TTeam
		'!Global g_offside_home:Int
		'!Global g_offside_away:Int
		'!Global g_ball:TBall
		If Self.offsidewhenkicked <> 0
			TScreenMessage.Create(0, 0, Lower(GetText("Offside")), g_msg_style, g_font, Null, 1.0, "FFFFFF")
			Local n:Int = 1
			If Self.teamid = g_hometeam.id
				n = 2
			EndIf
			TEngine.SetUpSetPiece(4, n, Self.posxwhenkicked, Self.posywhenkicked)
			If Self.teamid = g_hometeam.id
				g_offside_home = g_offside_home + 1
			Else
				g_offside_away = g_offside_away + 1
			EndIf
			If Self.newstar
				Self.AddPlayerRating(4, -2, "CBOSSSHOUT_OFFSIDE" + Rand(4, 1))
			ElseIf g_ball <> Null And g_ball.lastkickedby <> Null And g_ball.lastkickedby.newstar
				If Dist2D(g_ball.lastkickedby.kickx, g_ball.lastkickedby.kicky, Self.x, Self.y) > TPitch.YardsToPixels(15.0)
					g_ball.lastkickedby.AddPlayerRating(6, -2, "CBOSSSHOUT_OFFSIDEPASS" + Rand(4, 1))
				Else
					g_ball.lastkickedby.AddPlayerRating(5, -3, "CBOSSSHOUT_OFFSIDEPASS" + Rand(4, 1))
				EndIf
			Else
				Local hp:TPlayer = TPlayer.GetHumanPlayer()
				If hp <> Null And hp.teamid <> Self.teamid And hp.GetMyTeam().formation.GetPosFromSelectionNo(hp.selectionno) = 1
					hp.AddPlayerRating(4, 2, "CBOSSSHOUT_GOODBACKLINE" + Rand(4, 1))
				EndIf
			EndIf
			Return 1
		EndIf
	End Method
