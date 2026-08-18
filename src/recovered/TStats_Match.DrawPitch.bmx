' TStats_Match.DrawPitch
' VA 0x0056d98d   2338 bytes   vtable slot 0x40   sig (i,i)i
' byte-identical vs NSS5.exe (2338/2338, original length from Ghidra's inventory, mode=reloc)
'
' Renders every TStat in Self.list onto the pitch background at screen origin (a0,a1).
' Screen coords per stat: sx = Int(a0 + s.x*0.4), sy = Int(a1 + s.y*0.4) -- 0.4 is the
' pixels-per-yard scale baked into three separate .rdata floats (0x00C8F398/39C/3A0), all
' 0.4; kept as three separate literals since bcc has no CSE and the original computed each
' inline. TStat fields (object_model.json): stype@8, minute@0xc, x@0x10, y@0x14,
' direction@0x18, distance@0x1c.
'
' STRUCTURE, the two things that cost the most iterations to recover:
'   1. The "is the user steering the camera" branch is `If moving = 0 Then <Select> Else
'      <marker-move block> EndIf`, NOT the mirror-image `If moving Then ... Else Select`.
'      Both are logically identical; bcc places the Select as the inline/fallthrough arm and
'      the marker block out-of-line only for THIS polarity (delta 143 bytes if swapped).
'   2. The yards/metres unit toggle is `Select g_options_units \ Case 0 \ Case 1 \ End
'      Select`, not `If g_options_units=0 Then.. ElseIf g_options_units=1 Then..` -- the
'      original loads g_options_units ONCE into eax and does a flat 3-way dispatch (cmp 0 /
'      cmp 1 / jmp-past); the ElseIf form re-loads and re-tests the Global for its own
'      branch, which costs the extra `mov eax,[g]` (13 bytes) codegen-patterns 10.2 predicts.
'   3. The final gate is `If g_stats_match_int01 And Not moving And ...` -- BARE Int
'      truthiness on the first term, not `g_stats_match_int01 <> 0`. The explicit `<> 0`
'      canonicalises the flag through `setne al / movzx eax,al` even though it is the first
'      (branch-tested, not stored) operand of an And-chain; the original just branches on the
'      raw dword (codegen-patterns 11.1's array-truth-test rule generalises to plain Ints).
'
' Globals (usage-typed: bare dword reads/writes, no refcount traffic -> Int; construction-
' site/consistent-usage-typed otherwise):
'   0x00C5D1C4 g_ctrlleft:Int[]    0x00C5D1CC g_ctrlright:Int[]   (TOptions.LoadOptions:
'     index 1 = joystick, +0x1C; established names from TOptions.LoadOptions / NewButtonLeft
'     / NewButtonRight / TEngine.RenderScoreboard.)
'   0x00C6EFEC g_joyenabled:Int    (TPlayer.DoKeeperDiveAI's name for this address)
'   0x00C5D254 g_options_units:Int (TScreen_Stats.UpdateStatTable's name; checked against 0
'     then 1 there too)
'   0x00C6A628 g_stats_match_int01:Int  (already named in TStats_Match.New.bmx/AddStat.bmx)
'   0x00C6EFD4 g_matchclock:Int    (majority name across TEngine.MatchLoop/PauseEngine/
'     RenderReplayGUI etc; blinks the movement-map hint every other second via Mod 2000<1000)
'   0x00C61710 g_fonts:TImageFont[] (TGadget.CreateToolTip's name; element 0 here, element 1
'     there -- the +0x18 load is element 0, +0x1c load elsewhere is element 1)
'   0x00C6A658/5C/60/64 g_Object711..714:TImage -- established in TStats_Match.New.bmx
'     (StatsPitch.png, Blob.png, Arrow.png, Heatmap.png respectively)
'
' Case order in both Selects is SOURCE order, not numeric: stype dispatches
' 5,2,3,4,6,7,8,11,9,10 -- reproduced verbatim (codegen-patterns 10.2, Select emits every
' Case compare back to back in declared order). Cases 7 and 8 push the identical colour
' literal "FF0099" (bcc/linker interned the identical string constant); they are still two
' separate Case bodies in the original, not a combined `Case 7,8` -- each has its own
' compare-and-jump target.
'
' Literals (all read with harness.read_string, values only certified this way -- a MATCH
' masks the literal's ADDRESS, never its content):
'   stype 5 header/highlight "00FF00", case2 "99FF99", case3 "0000FF", case4 "990099",
'   case6 "9999FF", case7/8 "FF0099", case9 "FFFF00", case10 "FF0000", case11 "FF9900",
'   "FFFFFF" (final SetDrawStateHex + DrawMyText colour), "tla_Yards", "tla_Metres",
'   " " (single space, joins value and unit label), "CMESSAGE_MOVEMENTMAP".
'
' TPitch.PixelsToYards/PixelsToMetres are TPitch Functions called through the class table
' (TPitch+0x64 / +0x68); TEngine.DrawMyText likewise through TEngine+0x104. FormatDecimals,
' GetText, SetColourHex, SetDrawStateHex are already-recovered module Functions.
'
' The distance/direction/sx/sy Locals are computed UNCONDITIONALLY once per stat, before the
' moving/Select branch, even though most Select cases use only a subset of them -- matching
' the original, which stores all four to their frame slots (sub esp,0x28, 10 slots) on every
' loop iteration regardless of which case fires.
	Method DrawPitch:Int(a0:Int, a1:Int)
		'!Global g_ctrlleft:Int[]
		'!Global g_ctrlright:Int[]
		'!Global g_joyenabled:Int
		'!Global g_options_units:Int
		'!Global g_stats_match_int01:Int
		'!Global g_matchclock:Int
		'!Global g_fonts:TImageFont[]
		'!Global g_Object711:TImage
		'!Global g_Object712:TImage
		'!Global g_Object713:TImage
		'!Global g_Object714:TImage
		Local lastx:Int = 0
		Local lasty:Int = 0
		Local moving:Int = 0
		If KeyDown(g_ctrlright[0]) <> 0 Then moving = 1
		If g_joyenabled <> 0
			If g_ctrlleft[1] = -1
				If JoyX(0) > 0.5 Then moving = 1
			Else
				If JoyDown(g_ctrlright[1], 0) <> 0 Then moving = 1
			EndIf
		EndIf
		DrawImage(g_Object711, a0, a1, 0)
		For Local s:TStat = EachIn Self.list
			SetAlpha(0.75)
			SetRotation(0)
			SetScale(1.0, 1.0)
			Local dir:Float = s.direction
			Local dist:Float = s.distance * 0.4
			Local sx:Int = Int(a0 + s.x * 0.4)
			Local sy:Int = Int(a1 + s.y * 0.4)
			If moving = 0
				Select s.stype
					Case 5
						SetColourHex("00FF00")
						SetRotation(0)
						SetColor(0, 0, 0)
						SetImageFont(g_fonts[0])
						Select g_options_units
							Case 0
								DrawText(FormatDecimals(TPitch.PixelsToYards(s.distance), 1) + " " + GetText("tla_Yards"), sx + 5, sy - 5)
								SetColourHex("00FF00")
								DrawText(FormatDecimals(TPitch.PixelsToYards(s.distance), 1) + " " + GetText("tla_Yards"), sx + 6, sy - 6)
							Case 1
								DrawText(FormatDecimals(TPitch.PixelsToMetres(s.distance), 1) + " " + GetText("tla_Metres"), sx + 5, sy - 5)
								SetColourHex("00FF00")
								DrawText(FormatDecimals(TPitch.PixelsToMetres(s.distance), 1) + " " + GetText("tla_Metres"), sx + 6, sy - 6)
						End Select
					Case 2
						SetAlpha(0.5)
						SetColourHex("99FF99")
						For Local s2:TStat = EachIn Self.list
							If s2.stype = 5 And s2.x = s.x And s2.y = s.y And s2.minute > s.minute - 1 And s2.minute < s.minute + 1
								SetColourHex("00FF00")
							EndIf
						Next
						SetRotation(dir)
						DrawImageRect(g_Object713, sx, sy, dist, ImageHeight(g_Object713), 0)
					Case 3
						SetAlpha(0.5)
						SetColourHex("0000FF")
						SetRotation(dir)
						DrawImageRect(g_Object713, sx, sy, dist, ImageHeight(g_Object713), 0)
					Case 4
						SetAlpha(0.5)
						SetColourHex("990099")
						SetRotation(dir)
						DrawImageRect(g_Object713, sx, sy, dist, ImageHeight(g_Object713), 0)
					Case 6
						SetColourHex("9999FF")
						DrawImage(g_Object712, sx, sy)
					Case 7
						SetColourHex("FF0099")
						DrawImage(g_Object712, sx, sy)
					Case 8
						SetColourHex("FF0099")
						DrawImage(g_Object712, sx, sy)
					Case 11
						SetColourHex("FF9900")
						DrawImage(g_Object712, sx, sy)
					Case 9
						SetColourHex("FFFF00")
						DrawImage(g_Object712, sx, sy)
					Case 10
						SetColourHex("FF0000")
						DrawImage(g_Object712, sx, sy)
				End Select
			Else
				g_stats_match_int01 = 0
				If s.stype = 1
					If sx <> lastx Or sy <> lasty
						SetColor(255, 0, 0)
						SetAlpha(0.5)
						DrawImage(g_Object714, sx, sy)
					EndIf
					lastx = sx
					lasty = sy
				EndIf
			EndIf
		Next
		If g_stats_match_int01 And Not moving And g_matchclock Mod 2000 < 1000
			TEngine.DrawMyText(GetText("CMESSAGE_MOVEMENTMAP"), a0, a1, 1, 1, 0.5, 1.0, "FFFFFF", 0)
		EndIf
		SetLineWidth(1.0)
		SetDrawStateHex("FFFFFF", 1.0, 1.0, 0, 3)
	End Method
