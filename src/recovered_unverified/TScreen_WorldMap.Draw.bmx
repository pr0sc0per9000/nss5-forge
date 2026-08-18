' TScreen_WorldMap.Draw
' VA 0x0055B1A0   1706 bytes   KIND=Function (static, no Self)   SIG=()i   class-table slot 0x38
' Reconstructed from extracted/decomp/TScreen_WorldMap.Draw@0055b1a0.c CROSS-CHECKED against
' the raw disassembly (scripts/disasm.py 0x0055B1A0 .. 0x0055B849) because the Ghidra .c text
' drops several float arguments outright for this body -- see NOTES below. The harness oracle
' (scripts/harness.py try_method) reports MATCH 1706/1706 for this body against NSS5.exe.
'
' Two source-level points worth flagging for a reader comparing this against the decompilation:
' the py1/py2/flagY1/flagY2 block reuses py1 and py2 in place (:+ / :- ) rather than declaring
' fresh textY1/textY2 Locals, and its guard reads `If vy1 >= vy2` with the Then/Else content
' swapped relative to Ghidra's own `if (fVar3 < fVar4)` rendering -- Ghidra normalises
' comparison direction (see codegen-patterns.md 10.1) and does not preserve which physical
' branch the original placed first, so matching the bytes required writing the negated
' comparison with its branches swapped, not the natural reading of the decompiled C.
'
' WHAT IT DOES: draws the world map background (panned/zoomed toward the midpoint of the two
' fixture teams' stadiums), an optional "route" arrow stretched between the two stadium pins
' when they are far enough apart, a coloured pin (blob) at each stadium tinted with that team's
' home shirt colour, the two team-name labels (drop-shadowed) and each team's flag icon, then
' slowly zooms the map in over time (g_wm_zoom grows by 0.5% per Draw while below 2x).
'
' GLOBALS (names/types are the address-map's or an already-committed sibling's -- NOT invented)
'   0x00C68450 g_wm_zoom:Float          -- TScreen_WorldMap.SetUpScreen.bmx (writer, = 1.0)
'   0x00C683CC g_wm_bg:TImage           -- TScreen_WorldMap.SetUpScreen.bmx (writer)
'   0x00C68440 g_wm_lat1:Float          -- TScreen_WorldMap.SetUpScreen.bmx (writer)
'   0x00C68444 g_wm_long1:Float         -- TScreen_WorldMap.SetUpScreen.bmx (writer)
'   0x00C68448 g_wm_lat2:Float          -- TScreen_WorldMap.SetUpScreen.bmx (writer)
'   0x00C6844C g_wm_long2:Float         -- TScreen_WorldMap.SetUpScreen.bmx (writer)
'   0x00C68430 g_wm_team1:TBase_Team    -- TScreen_WorldMap.SetUpScreen.bmx (writer)
'   0x00C68434 g_wm_team2:TBase_Team    -- TScreen_WorldMap.SetUpScreen.bmx (writer)
'   0x00C683D0 g_img_arrow:TImage       -- TScreen_WorldMap.CreateScreen.bmx (writer; Arrow.png)
'   0x00C683D4 g_img_blob:TImage        -- TScreen_WorldMap.CreateScreen.bmx (writer; Blob.png)
'   0x00C6EFDC g_screenwidth:Int        -- TScreen.CreateScreen.bmx (writer, pragma "= 800");
'                                          same address also carries the fixed design width in
'                                          TScreen.UpdateOffset.bmx under the name g_screen_int21
'                                          -- merge_globals dedups by NAME not address (see that
'                                          file's own header), so g_screenwidth is used here to
'                                          match this Type's OWN sibling, TScreen_WorldMap.
'                                          CreateScreen.bmx, which already committed to it.
'   0x00C6EFE0 g_screenheight:Int       -- same reasoning, "= 600" in TScreen.CreateScreen.bmx.
'   0x00C6EFE8 g_engine_int163:Int      -- the ACTUAL/chosen screen height (can differ from the
'                                          800x600 design resolution above). Deliberately NOT
'                                          "g_screen_h" or "g_screenheight": neither of those is
'                                          ever assigned anywhere in the corpus for this address
'                                          (only read), whereas g_engine_int163 is the name
'                                          src/recovered_module/SetUpGraphics.bmx actually writes
'                                          (`g_engine_int163 = mode.h`) and TScreen.UpdateOffset.
'                                          bmx independently reads with the exact same "= 600"
'                                          comparison this body makes -- using an unwritten name
'                                          here would silently read 0 forever (18.26 / this
'                                          project's central defect class).
'   0x00C61710 g_fonts:TImageFont[]     -- CERTAIN in the address map (6 bodies, unanimous);
'                                          g_fonts[2] matches the +0x20 element offset (0x18
'                                          BBArray header + 2*4).
' object_model.json fields used: TBase_Team.labelname +0x1C, TBase_Team.kitcolsHome +0x44
'   (:TKitStrings), TKitStrings.shirt1 +0x0C, TBase_Team.imgFlag +0x58.
'
' CALL TARGETS (brl.max2d unless noted; addresses cross-checked against already-verified
' siblings, see the per-call comments below for which sibling proved which address)
'   0x00506456 SetDrawStateHex($,f,f,f,i)i  -- src/recovered_module (colour/scale/alpha/rot/blend)
'   0x00505DA2 Dist2D(f,f,f,f)f             -- src/recovered_module
'   0x0050639D AngleTo(f,f,f,f)f            -- src/recovered_module
'   0x00505F90 ClampFloat(*f,f,f)i          -- src/recovered_module
'   0x005AE3C5 ImageWidth   0x005AE3D4 ImageHeight   (TPitch.SetUp.bmx)
'   0x005AE0A8 SetScale     0x005AE079 SetRotation    0x005ADC28 SetAlpha
'   0x005ADB6F SetColor     0x005AD711 DrawImage       0x005AD7C8 DrawImageRect  (TDrawOb.RenderAll.bmx)
'   0x00505CEA SetColourHex($)i             -- src/recovered_module
'   0x005AE14F SetImageFont  0x005AE1AB TextWidth  0x005AE23C TextHeight  (TGadget.CreateToolTip.bmx)
'   0x005AD656 DrawText($,f,f)i             -- src/recovered_module/SetUpGraphics.bmx names it
'   0x005B9690 _bbFloatToInt == Int(f)      -- TButton.SetButtonStyle.bmx
'
' NOTES -- GHIDRA DROPPED ARGUMENTS (fixed against the raw disassembly, not the .c listing)
'   * `FUN_0050639d(fVar2,fVar3,local_20,fVar4);` (AngleTo) LOOKS like its return is discarded,
'     but the assembly stores it (`fstp [ebp-0x50]`) and reloads it ~15 instructions later as
'     the argument to the FIRST `FUN_005ae079()` (SetRotation) inside the arrow-draw block --
'     Ghidra just never materialised a named variable for the value in between. Captured here
'     as `ang`.
'   * `FUN_005ae3d4(PTR_DAT_00c683d0,0)` is shown taking 2 args, but ImageHeight only takes 1;
'     disassembly shows `push 0 / push image / call ImageHeight / add esp,4` -- the `add esp,4`
'     pops ONLY the image argument, so the leading `push 0` survives on the stack and becomes
'     DrawImageRect's trailing frame=0 argument on the very next call (classic argument-merge:
'     "6 pushes, add esp,0x18" for that DrawImageRect confirms 6, not 5, real arguments).
'   * The two bare `FUN_005adc28();` (SetAlpha) and two bare `FUN_005ae079();` (SetRotation)
'     calls, and both `FUN_00505cea();` (SetColourHex) calls, and the bare `FUN_005ae14f();`
'     (SetImageFont) call, all have the SAME issue for the same reason (an argument produced
'     several instructions earlier, held on the stack/x87 across intervening code, that Ghidra's
'     printer failed to attach) -- each is resolved below by reading the actual `push`
'     immediately preceding its `call` in the disassembly.
	Function Draw:Int()
		'!Global g_wm_zoom:Float
		'!Global g_wm_bg:TImage
		'!Global g_wm_lat1:Float
		'!Global g_wm_long1:Float
		'!Global g_wm_lat2:Float
		'!Global g_wm_long2:Float
		'!Global g_wm_team1:TBase_Team
		'!Global g_wm_team2:TBase_Team
		'!Global g_img_arrow:TImage
		'!Global g_img_blob:TImage
		'!Global g_screenwidth:Int
		'!Global g_screenheight:Int
		'!Global g_engine_int163:Int
		'!Global g_fonts:TImageFont[]

		SetDrawStateHex("FFFFFF", 1.0, 1.0, 0, 3)
		Local scale:Float = g_wm_zoom
		If g_engine_int163 = 600
			scale = g_wm_zoom * 2.0
		EndIf
		Local ix:Float = (g_screenwidth - 230) / 2 + 230
		Local iy:Float = g_screenheight / 2
		Local bgW:Float = Float(ImageWidth(g_wm_bg))
		Local bgH:Float = Float(ImageHeight(g_wm_bg))
		Local wRatio:Float = bgW / 360.0
		Local vx1:Float = g_wm_long1 * -wRatio
		Local vy1:Float = g_wm_lat1 * wRatio
		Local vx2:Float = g_wm_long2 * -wRatio
		Local vy2:Float = g_wm_lat2 * wRatio
		Local ang:Float = AngleTo(vx1, vy1, vx2, vy2)
		Local t:Float = scale - 1.0
		If t > 0.999
			t = 0.999
		EndIf
		Local dist:Float = Dist2D(vx1, vy1, vx2, vy2)
		If dist > 2000.0
			vx2 = (g_wm_long2 + 360.0) * -wRatio
		EndIf
		vx1 = vx1 * scale
		vy1 = vy1 * scale
		vx2 = vx2 * scale
		vy2 = vy2 * scale
		ix :+ (vx2 - (vx2 - vx1) * t)
		iy :+ (vy2 - (vy2 - vy1) * t)
		bgW :* 0.5
		bgH :* 0.5
		ClampFloat(Varptr ix, g_screenwidth - bgW * scale, bgW * scale)
		ClampFloat(Varptr iy, (g_screenheight - 60) - bgH * scale, 60.0 + bgH * scale)
		SetScale(scale, scale)
		DrawImage(g_wm_bg, ix, iy, 0)
		If dist * t > 2.5
			SetAlpha(0.25)
			SetRotation(ang)
			SetColor(255, 255, 255)
			DrawImageRect(g_img_arrow, ix - vx2, iy - vy2, dist * t, ImageHeight(g_img_arrow), 0)
			SetRotation(0)
		EndIf
		SetAlpha(1.0)
		SetScale(1.0, 1.0)
		SetColourHex(g_wm_team1.kitcolsHome.shirt1)
		DrawImage(g_img_blob, ix - vx1, iy - vy1, 0)
		SetColourHex(g_wm_team2.kitcolsHome.shirt1)
		DrawImage(g_img_blob, ix - vx2, iy - vy2, 0)
		SetImageFont(g_fonts[2])
		SetColor(0, 0, 0)
		Local px1:Int = Int((ix - vx1) + 10.0)
		Local py1:Int = Int((iy - vy1) - TextHeight(g_wm_team1.labelname) / 2)
		Local px2:Int = Int((ix - vx2) + 10.0)
		Local py2:Int = Int((iy - vy2) - TextHeight(g_wm_team2.labelname) / 2)
		Local flagX1:Int = px1 + TextWidth(g_wm_team1.labelname) / 2
		Local flagX2:Int = px2 + TextWidth(g_wm_team2.labelname) / 2
		Local flagY1:Int = py1
		Local flagY2:Int = py2
		If vy1 >= vy2
			py1 :- 8
			py2 :+ 8
			flagY1 :- 26
			flagY2 :+ 52
		Else
			py1 :+ 8
			py2 :- 8
			flagY1 :+ 52
			flagY2 :- 26
		EndIf
		DrawText(g_wm_team1.labelname, px1 + 1, py1 + 1)
		DrawText(g_wm_team2.labelname, px2 + 1, py2 + 1)
		SetColor(255, 255, 255)
		DrawText(g_wm_team1.labelname, px1, py1)
		DrawText(g_wm_team2.labelname, px2, py2)
		If g_wm_team1.imgFlag <> Null
			DrawImage(g_wm_team1.imgFlag, flagX1, flagY1, 0)
		EndIf
		If g_wm_team2.imgFlag <> Null
			DrawImage(g_wm_team2.imgFlag, flagX2, flagY2, 0)
		EndIf
		If g_wm_zoom < 2.0
			g_wm_zoom = g_wm_zoom * 1.005
		EndIf
		SetDrawStateHex("FFFFFF", 1.0, 1.0, 0, 3)
	End Function
