' TPlayer.Render
' VA 0x004EE340   3228 bytes   mode=reloc   byte-identical vs NSS5.exe
'   (3228/3228, original length from Ghidra's inventory, reloc_masked=177,
'    verified with NSS5_NO_LEARN=1 so no call operand was masked by a name this body taught)
' KIND=Method, SIG (f)i, slot 0x50.  Body-only format: Self implicit, parameter named a0
'   because harness.emit_type generates the declaration as `Method Render:Int(a0:Float)`.
'   a0 is the inter-frame tween factor (0..1) applied to the old/new positions.
'
' ASSUMPTIONS -- module Globals (names ours; the declared TYPE is load-bearing):
'   0x00C5D634 g_pitchleft:Int      -- negated then Int->Float; the left clip edge in pixels
'   0x00C5DEAC g_anim_default:Int[] -- spec 16.7: 0x00C5DEAC..0x00C5DF28 are Int[] on direct
'                                      evidence (the Int element descriptor 0x00C59097).
'                                      globals_final says Object[] and is wrong. TPlayer's
'                                      own field `currentanim` is `[]i`, which corroborates.
'   0x00C5DE44 g_playerscale:Float  -- base sprite scale
'   0x00C5DE80 g_marker_on:Int      -- bare truth test, no refcount traffic -> Int
'   0x00C5DEA4 g_ball:TBall         -- type_source=verified; also spec 11.2's correction of
'                                      the TPlayer row (TBall has 0x68/0x84/0x88/0x90 too)
'   0x00C5B1FC g_matchstate:Int     -- verified Int
'   0x00C5B204 g_setpiecepower:Int  -- plain dword compare, no refcounting -> Int (10.7)
'   0x00C6EFD4 g_timer:Int          -- verified Int; used with Mod 500
'   0x00C6F028 g_profile:TProfile   -- type_source=construction; reads +0x16C injury:Int and
'                                      +0x15C energy:Float, both of which are TProfile's
'   0x00C5D270 g_showhud:Int
'   0x00C6CF90 g_trainingmode:Int
'   0x00C795D4 g_arrowalpha:Float   -- passed by address to ClampFloat
'   TImage Globals, all reaching AddDrawOb's declared `:TImage` first argument:
'     0x00C5DE18 g_img_marker   0x00C5DE1C g_img_arrow1   0x00C5DE20 g_img_arrow2
'     0x00C5DE24 g_img_offside  0x00C5DE28 g_img_calling  0x00C5B2E8 g_img_red
'     0x00C5B2EC g_img_injury   0x00C5B2F0 g_img_sub      0x00C5B300 g_img_booze
'     0x00C5B304 g_img_unhappy  0x00C5B308 g_img_nrg      0x00C5B30C g_img_tired
'     0x00C5B310 g_img_energy1  0x00C5B314 g_img_energy2  0x00C5B318 g_img_energybar
'
' SLOTS / CALL TARGETS resolved on both sides:
'   0x00C5B1B4 = TDrawOb classtable + 0x34 = AddDrawOb(:TImage,f,f,f,i,i,f,i,$,f,f,i,f,$,i,i)i
'                -- 20 call sites in this body, every one `add esp,0x40` (16 args)
'   0x00C5D998 = TPitch + 0x6C = YardsToPixels(f)f
'   Self slots: 0x194 GetAnimFrame(i)i, 0x1C4 KeeperDiving()i, 0x1B0 PlayerSliding()i,
'               0x84 ForceControlCPU()i, 0x54 GetShadowOffsetAndRot(i,*i,*i)i
'   E8 helpers: 0x004A7AC0 _bbStringFromInt, 0x004A7C20 _bbStringConcat, 0x004A8590 _bbGCFree,
'               0x0059F089 _brl_random_Rand -> Rand(0,7), 0x005B9690 _bbFloatToInt -> Int(x),
'               0x00505F90 ClampFloat (recovered module Function, (*f,f,f)i)
'
' STRING LITERALS read out of .data with harness.read_string (a MATCH masks the literal's
'   ADDRESS, so content is not certified by the oracle -- these were read, not guessed):
'   0x00C5D680 "FFFFFF"   0x00C6FC58 "000000"   0x00C6E904 "00FF00"   0x00C725B8 "FFFF00"
'   0x00C79584 " Im:"     0x00C79598 "F:"       0x005C7D40 "" (the empty-string singleton)
'
' FIELDS: newstar +0x08, imgPlayer +0x0C, id +0x10, teamid +0x14, controller +0x18,
'   boozedup +0x34, nrgsickness +0x38, unhappiness +0x3C, tiredness +0x40, x +0x4C, y +0x50,
'   z +0x54, oldx +0x58, oldy +0x5C, oldz +0x60, xvel +0x64, direction +0x78, offside +0xAC,
'   offsidewhenkicked +0xB0, offsidealpha +0xB4, selectionno +0xBC, kickpower +0xC0,
'   kickdirection +0xC4, calling +0x114, facing +0x128, spriterotation +0x12C,
'   currentanim +0x130, frame +0x134, imageframenumber +0x13C, obtext +0x15C,
'   matchstats +0x188; TStats_Match.yellows +0x0C, .reds +0x10;
'   TBall.teaminpossession +0x60, .controlledby +0x70, .setpiecetaker +0x80;
'   TProfile.energy +0x15C, .injury +0x16C
'
' LOAD-BEARING SHAPE -- what the byte count actually pins down (`sub esp,0x24` = 9 dwords):
'   * Local slots are handed out in the order the STATEMENT STREAM needs them, temporaries
'     and declarations from the same descending counter, with one Int->Float conversion
'     scratch appended last:
'         -0x0C/-0x10 guard temps, -0x14 scale, -0x18 px, -0x1C py, -0x20 pz,
'         -0x04 shadowyoff, -0x08 shadowrot, -0x24 the fild scratch.
'     shadowyoff/shadowrot therefore come FIRST even though they are declared two thirds of
'     the way down -- an address-taken Int Local is given a slot from the top of the frame.
'     Declaring them at the top instead costs exactly 14 bytes: bcc emits `mov [slot],0` for
'     a bare `Local x:Int`, and the original has no such store. That was the whole delta of
'     the first draft (3242 vs 3228); everything else was right on the first pass.
'   * The opening test is an EARLY RETURN (`75 0A / B8 00.. / E9 rel32` -- spec 3f), not a
'     block enclosing the body.
'   * `Select g_matchstate` with FOUR separate `Case`s each holding its own `Return 0`: the
'     four `je`s go to four DIFFERENT `mov eax,0 / jmp end` blocks, so it is not
'     `Case 0,10,8,11` (which would share one target) and not an If/And chain (spec 10.2).
'   * `Select Self.facing` for the sliding rotation, likewise -- every compare precedes
'     every body and the last case's `jmp` is `EB 00`.
'   * `If Not Self.currentanim` tests `[eax+0x10]` (BBArray `size`), so it is the bare array
'     truth test, not `.Length` which would test +0x14 (spec 11.1).
'   * `fldz`/`fld1` mark INT literals promoted to Float (`< 1`, `> 0`, `< 0`, `= 0`); a
'     written `1.0`/`0.1`/`35.0` becomes a .data constant instead. The two `0.02`s and the
'     seven `35.0`s each get their own constant, i.e. each is a separate literal occurrence.
'   * A float comparison used directly as an If condition materialises the NEGATED predicate
'     (`setbe` for `>`, `setae` for `<`) and branches with `jne`; the same comparison inside
'     an And/Or chain materialises the POSITIVE predicate and the enclosing If uses `je`.
'     Both appear here -- `Self.xvel < 0` is the second form, `Self.kickpower > 15.0` the
'     first. Getting this backwards changes the setcc byte, not the length.
'   * The offside guard is an `If <chain>` with an EMPTY Then followed by `ElseIf`: the
'     tell is `74 05 / E9 rel32` (short inverted jump over a near jmp) where a plain far
'     conditional would have been `0F 85 rel32`, one byte shorter. Writing it as
'     `If Not (<chain>)` does not reproduce those seven bytes.
'   * `power` lives in EBX and `col` in EDX with no stack slot, and `dir` never leaves the
'     x87 stack (spec 6 / 10.5) -- which is why all three cost zero frame bytes.
'   * `Self.obtext = "F:" + ... + ...` is plain `=` with a left-associative `+` chain, NOT
'     `:+` -- the concats nest left-to-right (spec 16.1).
	Method Render:Int(a0:Float)
		'!Global g_pitchleft:Int
		'!Global g_anim_default:Int[]
		'!Global g_playerscale:Float
		'!Global g_marker_on:Int
		'!Global g_ball:TBall
		'!Global g_img_marker:TImage
		'!Global g_img_arrow1:TImage
		'!Global g_img_arrow2:TImage
		'!Global g_img_offside:TImage
		'!Global g_img_calling:TImage
		'!Global g_matchstate:Int
		'!Global g_setpiecepower:Int
		'!Global g_timer:Int
		'!Global g_profile:TProfile
		'!Global g_img_red:TImage
		'!Global g_img_injury:TImage
		'!Global g_img_sub:TImage
		'!Global g_img_booze:TImage
		'!Global g_img_unhappy:TImage
		'!Global g_img_nrg:TImage
		'!Global g_img_tired:TImage
		'!Global g_img_energy1:TImage
		'!Global g_img_energy2:TImage
		'!Global g_img_energybar:TImage
		'!Global g_showhud:Int
		'!Global g_arrowalpha:Float
		'!Global g_trainingmode:Int
		If Self.x < -g_pitchleft - TPitch.YardsToPixels(33.5) Then Return 0
		Local scale:Float
		Local px:Float = Self.x * a0 + Self.oldx * (1.0 - a0)
		Local py:Float = Self.y * a0 + Self.oldy * (1.0 - a0)
		Local pz:Float = Self.z * a0 + Self.oldz * (1.0 - a0)
		If Not Self.currentanim
			Self.currentanim = g_anim_default
			Self.frame = Rand(0, 7)
		EndIf
		Self.imageframenumber = Self.GetAnimFrame(1)
		scale = g_playerscale
		If Self.KeeperDiving() And Self.xvel < 0
			scale = -scale
		ElseIf Self.facing = 0
			scale = -scale
		EndIf
		Self.spriterotation = 0
		If Self.PlayerSliding()
			Select Self.facing
			Case 2
				Self.spriterotation = Self.direction - 270.0
			Case 3
				Self.spriterotation = Self.direction - 90.0
			Case 0
				Self.spriterotation = Self.direction - 180.0
			Case 1
				Self.spriterotation = Self.direction
			End Select
		EndIf
		Self.obtext = "F:" + Self.facing + " Im:" + Self.imageframenumber
		TDrawOb.AddDrawOb(Self.imgPlayer, px, py, pz, Self.imageframenumber, 3, 1.0, Int(Self.spriterotation), "FFFFFF", scale, g_playerscale, 3, 0, "", 0, 0)
		Local shadowyoff:Int = -2
		Local shadowrot:Int = Int(Self.spriterotation)
		Self.GetShadowOffsetAndRot(Self.imageframenumber, Varptr shadowyoff, Varptr shadowrot)
		TDrawOb.AddDrawOb(Self.imgPlayer, px + 1.0, py + shadowyoff, 0, Self.imageframenumber, 2, 0.35, shadowrot, "000000", scale * 1.0, g_playerscale * 0.8, 3, 0, "", 0, 0)
		If g_marker_on And g_ball <> Null And g_ball.controlledby <> Null And g_ball.controlledby.controller = 1 And g_ball.controlledby.teammateid = Self.id
			TDrawOb.AddDrawOb(g_img_marker, px, py, 0, 0, 2, 0.4, 0, "FFFFFF", 0.6, 0.4, 3, 0, "", 0, 0)
		EndIf
		Select g_matchstate
		Case 0
			Return 0
		Case 10
			Return 0
		Case 8
			Return 0
		Case 11
			Return 0
		End Select
		If Self.controller = 1
			If Self.ForceControlCPU() = 0 Or g_matchstate = 1 Or (g_setpiecepower > 0 And g_ball <> Null And g_ball.setpiecetaker = Self And g_timer > g_setpiecepower + 1000)
				Local power:Int = 0
				If Self.kickpower > 15.0
					power = Int((Self.kickpower - 15.0) / 1.65)
				EndIf
				If power > 19 Then power = 19
				Local dir:Float = Self.direction
				If Self.kickdirection <> -1.0
					dir = Self.kickdirection
				EndIf
				If Self.matchstats.yellows = 0
					TDrawOb.AddDrawOb(g_img_arrow1, px, py, 0, power, 1, 0.5, Int(dir), "FFFFFF", 0.4, 0.4, 3, 0, "", 0, 0)
				Else
					TDrawOb.AddDrawOb(g_img_arrow2, px, py, 0, power, 1, 0.5, Int(dir), "FFFFFF", 0.4, 0.4, 3, 0, "", 0, 0)
				EndIf
			Else
				Local col:String = "00FF00"
				If Self.matchstats.yellows > 0
					col = "FFFF00"
				EndIf
				TDrawOb.AddDrawOb(g_img_marker, px, py, 0, 0, 1, 0.5, 0, col, 0.4, 0.4, 3, 0, "", 0, 0)
			EndIf
		EndIf
		If g_ball <> Null And (g_matchstate = 1 Or g_matchstate = 4)
			If g_ball.controlledby = Null And g_ball.teaminpossession = Self.teamid And Self.offsidewhenkicked = 0
			ElseIf Self.offside <> 0
				If Self.offsidealpha < 1
					Self.offsidealpha = Self.offsidealpha + 0.1
				EndIf
				TDrawOb.AddDrawOb(g_img_offside, px - 8.0, py - 28.0, 0, 0, 5, Self.offsidealpha, 0, "FFFFFF", 0.5, 0.5, 3, 0, "", 0, 0)
			EndIf
		EndIf
		If Self.offsidealpha > 0
			Self.offsidealpha = Self.offsidealpha - 0.035
		EndIf
		If Self.newstar
			If Self.calling
				TDrawOb.AddDrawOb(g_img_calling, px + 8.0, py - 28.0, 0, 0, 5, 1.0, 0, "FFFFFF", 0.5, 0.5, 3, 0, "", 0, 0)
			EndIf
			Local shown:Int = 0
			If g_profile.injury <> 0
				TDrawOb.AddDrawOb(g_img_injury, px, py - 35.0, 0, 0, 5, 1.0, 0, "FFFFFF", 0.5, 0.5, 3, 0, "", 0, 0)
				shown = 1
			ElseIf Self.matchstats.reds <> 0
				TDrawOb.AddDrawOb(g_img_red, px, py - 35.0, 0, 0, 5, 1.0, 0, "FFFFFF", 0.25, 0.25, 3, 0, "", 0, 0)
				shown = 1
			ElseIf Self.selectionno > 10
				TDrawOb.AddDrawOb(g_img_sub, px, py - 35.0, 0, 0, 5, 1.0, 0, "FFFFFF", 0.5, 0.5, 3, 0, "", 0, 0)
				shown = 1
			ElseIf g_timer < Self.boozedup + 2500
				If g_timer Mod 500 < 350
					TDrawOb.AddDrawOb(g_img_booze, px, py - 35.0, 0, 0, 5, 1.0, 0, "FFFFFF", 0.5, 0.5, 3, 0, "", 0, 0)
				EndIf
				shown = 1
			ElseIf g_timer < Self.nrgsickness + 5000
				If g_timer Mod 500 < 350
					TDrawOb.AddDrawOb(g_img_nrg, px, py - 35.0, 0, 0, 5, 1.0, 0, "FFFFFF", 0.5, 0.5, 3, 0, "", 0, 0)
				EndIf
				shown = 1
			ElseIf g_timer < Self.unhappiness + 2000
				If g_timer Mod 500 < 350
					TDrawOb.AddDrawOb(g_img_unhappy, px, py - 35.0, 0, 0, 5, 1.0, 0, "FFFFFF", 0.5, 0.5, 3, 0, "", 0, 0)
				EndIf
				shown = 1
			ElseIf g_timer < Self.tiredness + 2000
				If g_timer Mod 500 < 350
					TDrawOb.AddDrawOb(g_img_tired, px, py - 35.0, 0, 0, 5, 1.0, 0, "FFFFFF", 0.5, 0.5, 3, 0, "", 0, 0)
				EndIf
				shown = 1
			EndIf
			If g_matchstate <> 1 Or g_showhud
				g_arrowalpha = g_arrowalpha + 0.02
			Else
				g_arrowalpha = g_arrowalpha - 0.02
			EndIf
			If g_trainingmode > 0 Or shown
				g_arrowalpha = 0
			EndIf
			ClampFloat(Varptr g_arrowalpha, 0, 1.0)
			If g_arrowalpha > 0.01
				If g_profile.energy > 30.0
					TDrawOb.AddDrawOb(g_img_energy1, px - 16.0, py - 50.0, 0, 0, 5, g_arrowalpha, 0, "FFFFFF", 0.5, 0.5, 3, 0, "", 0, 0)
				Else
					TDrawOb.AddDrawOb(g_img_energy2, px - 16.0, py - 50.0, 0, 0, 5, g_arrowalpha, 0, "FFFFFF", 0.5, 0.5, 3, 0, "", 0, 0)
				EndIf
				TDrawOb.AddDrawOb(g_img_energybar, px + 15.0, py - 49.0, 0, 0, 5, g_arrowalpha, 0, "FFFFFF", -(100.0 - g_profile.energy) / 200.0, 0.5, 3, 0, "", 0, 0)
			EndIf
		EndIf
	End Method
