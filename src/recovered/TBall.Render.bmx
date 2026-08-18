' TBall.Render
' VA 0x004c828d   1032 bytes   class-table slot 0x54   sig (f)i   KIND=Method
' Draws the ball (position interpolated by a0 between old*/current fields), then its shadow
' marker for a set-piece indicator, then the "newstar spotlight" ring under the ball while
' the team in possession has a marked new star nearby, then a fading set-piece marker.
'
' PARAMETERS a0:Float t (interpolation fraction between oldx/oldy/oldz and x/y/z).
'
' ASSUMPTIONS -- module Globals (majority naming already established across this corpus --
' see TEngine.DoYourSubstitutionOn/Off, TBall.Kick, TBall.CheckSideLines, TEngine.EndMatch,
' all of which independently corrected globals_final.tsv's TKit label to TTeam for these
' two addresses from the same +8/+0x1c field evidence used here):
'   0x00C5A4B0 g_Object05:TImage   0x00C5A4B4 g_Object06:TImage   (both usage-only, kept
'     the reflection-table placeholder names -- read once each as AddDrawOb's TImage arg,
'     typed TImage from that call site, not TKit/Object as globals_final.tsv guesses)
'   0x00C5A4B8 g_Object07:TImage   0x00C5A4BC g_Object08:TImage   (same)
'   0x00C5B1FC g_player_int01:Int
'   0x00C5B218 g_hometeam:TTeam   0x00C5B21C g_awayteam:TTeam  (TTeam.id at +8,
'     TTeam.squad:TList at +0x1c, matching the field reads exactly)
'   0x00C5D26C g_screen_options_int03:Int
'   0x00C5DE18 g_Object80:TImage (same reasoning)   0x00C5DE44 g_player_float02:Float
'   0x00C725D0 g_ball_float17:Float   0x00C725E0 g_ball_float18:Float
'
' Class-table slots: TDrawOb+0x34 AddDrawOb (16-arg sig, see vtable_map) ; TBall+0xc0
' GetHeightScale(i)f ; TPitch+0x6c YardsToPixels(f)f ; TList+0x8c ObjectEnumerator.
'
' SOURCE FORM
'   `hideball<>0` is an EARLY RETURN, not a wrapping If -- the original has TWO independent
'   `mov eax,0 / jmp <shared epilogue>` sites (one per Return), not one; wrapping the whole
'   body in `If hideball=0 ... EndIf` merges them into a single site and costs 5 bytes.
'   drawx/drawy are `Self.x*a0 + Self.oldx*(1.0-a0)` -- the FIELD operand of the second
'   product must be on the right (`Self.oldx * (1.0-a0)`, not the reverse) for bcc to emit
'   the compact `fmul dword ptr[field]` form instead of an extra explicit `fld`.
'   Every `X And Y [And Z]` / `X Or Y` guard below reproduces bcc's short-circuit codegen
'   (confirmed pattern: the second test's `cmp`/`sete` is skipped by a `jne`/`je` over it
'   when the first already decided the boolean) -- this includes the THREE-way "z>20 And
'   controlledby=Null And g_player_int01=1" chain.
'   The height-scale expression `g_player_float02 * Self.GetHeightScale(Int(Self.z))` is
'   written out TWICE (bcc does no CSE, codegen-patterns.md 6) -- both AddDrawOb args
'   independently reload g_player_float02 and re-call GetHeightScale.
'   `ind` and `nearNewstar` are each seeded from the RAW FIELD/comparison whose falsy value
'   already equals the flag's default (`ind = Self.active`, `ind = (Self.controlledby <>
'   Null)`, `nearNewstar = p.newstar`), then conditionally overwritten -- NOT seeded with a
'   literal 0/False. A literal-0 seed makes bcc emit a bare `mov eax,0` where the original
'   loads the field/comparison result directly, 3-5 bytes shorter per site.
'   `If ind <> 0 Then g_ball_float17 :- 0.02 Else :+ 0.01` is the solo-relational If/Else
'   branch swap (codegen-patterns.md 21): the natural reading `If ind = 0 Then :+ Else :-`
'   compiles with the branches physically swapped and the comparison negated.
'   The possession-team pick (`If Self.teaminpossession = g_hometeam.id Then ... Else ...`)
'   selects which TTeam's `.squad` to walk for the nearest-newstar check.
'
' ORACLE: mode=reloc  matched=1032/1032  STATUS=MATCH.
'!Global g_Object05:TImage
'!Global g_Object06:TImage
'!Global g_Object07:TImage
'!Global g_Object08:TImage
'!Global g_player_int01:Int
'!Global g_hometeam:TTeam
'!Global g_awayteam:TTeam
'!Global g_screen_options_int03:Int
'!Global g_Object80:TImage
'!Global g_player_float02:Float
'!Global g_ball_float17:Float
'!Global g_ball_float18:Float
Method Render:Int(a0:Float)
	If Self.hideball <> 0 Then Return 0
	Local drawx:Float = Self.x * a0 + Self.oldx * (1.0 - a0)
	Local drawy:Float = Self.y * a0 + Self.oldy * (1.0 - a0)
		Local drawz:Float = Self.z * a0 + Self.oldz * (1.0 - a0)
		TDrawOb.AddDrawOb(g_Object06, drawx, drawy, 0, 0, 2, Self.alph * 0.35, 0, "FFFFFF", g_player_float02, g_player_float02, 3, 0, "", 0, 0)
		TDrawOb.AddDrawOb(g_Object05, drawx, drawy, drawz, Self.frame, 3, Self.alph, 0, Self.colour, g_player_float02 * Self.GetHeightScale(Int(Self.z)), g_player_float02 * Self.GetHeightScale(Int(Self.z)), 3, 0, "", 0, 0)
		If Self.z > 20.0 And Self.controlledby = Null And g_player_int01 = 1
			TDrawOb.AddDrawOb(g_Object07, Self.metax, Self.metay, 0, 0, 2, Self.alph, 0, "FFFF00", 1.0, 1.0, 3, 0, "", 0, 0)
		EndIf
		Local ind:Int = Self.active
		If ind <> 0 Then ind = g_screen_options_int03
		If ind <> 0
			ind = (Self.controlledby <> Null)
			If ind <> 0 Then ind = Self.controlledby.newstar
			If ind <> 0
				g_ball_float17 :- 0.02
			Else
				g_ball_float17 :+ 0.01
			EndIf
			ClampFloat(Varptr g_ball_float17, 0, 0.2)
			TDrawOb.AddDrawOb(g_Object80, drawx, drawy - 1.0, 0, 0, 1, g_ball_float17, 0, "FFFFFF", 0.5, 0.5, 3, 0, "", 0, 0)
		EndIf
		If Self.active <> 0
			If g_player_int01 = 4 Or g_player_int01 = 5
				Local possteam:TTeam = g_hometeam
				If Self.teaminpossession = g_hometeam.id Then possteam = g_awayteam
				For Local p:TPlayer = EachIn possteam.squad
					Local nearNewstar:Int = p.newstar
					If nearNewstar <> 0 Then nearNewstar = (p.distancetoball < TPitch.YardsToPixels(10.1))
					If nearNewstar <> 0 Then g_ball_float18 :+ 0.01
				Next
			EndIf
			g_ball_float18 :- 0.005
			ClampFloat(Varptr g_ball_float18, 0, 0.1)
			If g_ball_float18 > 0.0
				TDrawOb.AddDrawOb(g_Object08, Self.setpiecex, Self.setpiecey, 0, 0, 2, g_ball_float18, 0, "FF0000", 0.5, 0.5, 3, 0, "", 0, 0)
			EndIf
		EndIf
	Return 0
End Method
