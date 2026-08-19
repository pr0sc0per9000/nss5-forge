' TJoy.Update -- Method, vtable slot 0x34, sig (i,i,i)i
' VA 0x004D9CFA   2373 bytes
' MATCH, mode=reloc, 2373/2373, reloc_masked=137, NSS5_NO_LEARN=1.
' byte-identical vs NSS5.exe
'
' Two regions account for the +7 bytes a naive rendering costs; both are closed below.
'
' THREE FINDINGS THAT CLOSED THE GAP, ALL VERIFIED BY DIRECT MEASUREMENT (harness.try_method
' toggled one change at a time, not guessed):
'
' (1) THE DIRECTION-RECENTRING CASCADE (VA 0x004DA42F..0x004DA581, axis_x/axis_y have gone
'     slack -> ease `direction` back toward the nearest 90-degree compass bin). Ghidra's
'     rendering collapses this into `If (A And B) Then <nested> Else <assign>` via De Morgan,
'     and writing THAT form does not match. Reading the raw FPU trace
'     directly (harness.disasm_original, no Ghidra) shows two different things are going on:
'       * The OUTER test (`axis_y > -edge`, a SOLO relational guarding two really-different
'         nested blocks) DOES need codegen-patterns.md section 21's negate+swap rule: the
'         block placed nearest (fallthrough) in the machine code is the one reached when the
'         WRITTEN condition is true, i.e. write `If axis_y <= -edge Then <near> Else <far>`,
'         not `If axis_y > -edge Then <far> Else <near>`.
'       * The INNER compound conditions (`origDir > C1+mult*3 Or origDir < C2`) do NOT get
'         swapped -- section 21 explicitly exempts "a comparison used as one term of a
'         compound And/Or", and these compile as a plain short-circuit Or with the Then-body
'         placed nearest, matching source written exactly as observed (no De Morgan, no
'         negation). Confirmed on both cascade halves.
'     Once written this way the ENTIRE cascade matched except two `direction = mult*3.0 +
'     origDir` assignments, which needed their operand order reversed to `direction = origDir
'     + mult*3.0` -- bcc evaluates left-to-right, and the original's bytes push origDir FIRST
'     (fld origDir; fxch st(1); fmul 3.0; faddp), which only comes out of source that writes
'     origDir as the LEFT operand of the addition.
'
' (2) THE ANGLEDIFF BLEND (VA 0x004DA5FF..0x004DA625). `blend :+ g_ply_turnrate *
'     AngleDiff(origDir, direction, 0)` (turnrate as the literal left operand) forces bcc to
'     load turnrate BEFORE the call and spill it across AngleDiff's call (a real value can't
'     ride the x87 stack through a call), costing 9 bytes the original does not have --
'     the original loads turnrate strictly AFTER the call returns.
'
'     Reordering to `AngleDiff(...) * g_ply_turnrate` (call first, matching the original's
'     instruction order) fixes the pre-call spill but introduces a NEW, smaller mismatch: bcc
'     folds the Global straight into the multiply (`fmul dword ptr [turnrate]`, one
'     instruction), where the original spends two (`fld [turnrate]; fmulp st(1)`). This is the
'     same shape AngleDiff's OWN body uses for `Cos(a0) * 10.0` (see AngleDiff.bmx's own
'     header) -- call result first, `fld [const]; fmulp`, never a folded `fmul [mem]` -- so a
'     folded multiply straight off a call result is never what bcc emits; something about
'     using the call's return value in-place, rather than through its own Local, is what
'     triggers the fold in THIS reconstruction (not fully understood; not needed once routed
'     through a Local).
'
'     Precomputing the call into its own Local reproduces the exact original shape:
'         Local diff:Float = AngleDiff(origDir, direction, 0)
'         blend :+ g_ply_turnrate * diff
'     i.e. call first (matches original's call-before-load order), then `fld [turnrate];
'     fmulp` against the resident `diff` (matches the two-instruction, non-folded shape).
'     Confirmed by direct toggle: the call-first-fold-the-global form is MISMATCH (len 2371 vs
'     2373); precomputing `diff` first is MATCH at 2373/2373 mode=reloc.
'
' (3) the "solo relational If/Else branch-swap" rule
'     applies to a plain EQUALITY test too, twice in this function. `kickenabled = 0` must be
'     written `If kickenabled <> 0 Then <the <>0 body> Else <the =0 body>` (negated, branches
'     swapped) at both occurrences (VA 0x004D9D68 short body, VA 0x004D9FC3 long body).
'     Writing the natural `If kickenabled = 0 Then A Else B` gives the mirror-image layout.
'
' WHAT ELSE IS CONFIRMED: the g_opt_ctrlidx=3
' (mouse) branch and its kickenabled toggle; the g_opt_ctrlidx<>3 (key/joystick) branch, all
' four KeyDown movement tests, the analog-vs-digital joystick split, and the full kickenabled
' toggle including the nested g_opt_kickmode=1 block; both ClampFloat(axis_x/axis_y,-1,1)
' calls; the `a2<>0 And (g_joy_dragging=1 Or g_opt_ctrlleft[g_opt_ctrlidx]>-1)` gate and the
' Select a2 hard-turn block; the axis_x=0/axis_y=0 reset; the final WrapAngle(direction) tail.
' `g_joy_dragging <> 0 Or ...` (explicit boolean normalisation) is required at VA 0x004DA35B's
' joystick epsilon-threshold test but NOT at the top-of-function `a2<>0 And (g_joy_dragging=1
' Or ...)` gate, which is already a `=1` equality test, not a bare-truthy Or.
'
' LITERALS. Every float constant in the cascade was read directly out of NSS5.exe with
' bytematch.read_va (never taken from Ghidra's decompile, which cannot certify a masked
' constant -- codegen-patterns.md section 21): mult=2.0, edge=0.9 (0.1 when dragging or
' analog-joystick), and every cascade bound is one of 90.0, 270.0, 3.0.
'
' NAMES. g_opt_ctrlidx/g_opt_ctrlup/g_opt_ctrldown/g_opt_ctrlleft/g_opt_ctrlright/
' g_opt_ctrlbutton/g_opt_ctrlbutton2/g_opt_ctrlbutton3/g_opt_ctrlbutton4 are the
' already-established names from the independently verified src/recovered/TOptions.LoadOptions
' (0x00C5D1A8/B4/BC/C4/CC/D4/DC/E4/EC), reused verbatim. All other Globals and the Local
' `diff` are named here for the first time (no reflection record for module Globals or method
' Locals) and do not affect codegen.

Method Update:Int(a0:Int, a1:Int, a2:Int)
	'!Global g_opt_ctrlidx:Int
	'!Global g_opt_kickmode:Int
	'!Global g_opt_ctrlup:Int[]
	'!Global g_opt_ctrldown:Int[]
	'!Global g_opt_ctrlleft:Int[]
	'!Global g_opt_ctrlright:Int[]
	'!Global g_opt_ctrlbutton:Int[]
	'!Global g_opt_ctrlbutton2:Int[]
	'!Global g_opt_ctrlbutton3:Int[]
	'!Global g_opt_ctrlbutton4:Int[]
	'!Global g_ply_turnrate:Float
	'!Global g_time:Int
	'!Global g_eng_hasjoystick:Int
	'!Global g_joy_dragging:Int
	Local origDir:Float = direction
	Local joyIdx:Int = 0
	If g_opt_ctrlidx = 3
		axis_x = 0
		axis_y = 0
		If MouseDown(2)
			axis_x = Cos(a1)
			axis_y = Sin(a1)
		EndIf
		If kickenabled <> 0
			If MouseHit(1)
				kickbuttonhits = g_time
			EndIf
			If MouseDown(1)
				kickbuttondown = 1
			Else
				kickbuttondown = 0
			EndIf
		Else
			kickbuttonhits = 0
			kickbuttondown = 0
			If Not MouseDown(1)
				kickenabled = 1
			EndIf
		EndIf
	Else
		If KeyDown(g_opt_ctrlleft[0])
			axis_x = axis_x - 0.1
			g_joy_dragging = 1
		EndIf
		If KeyDown(g_opt_ctrlright[0])
			axis_x = axis_x + 0.1
			g_joy_dragging = 1
		EndIf
		If KeyDown(g_opt_ctrlup[0])
			axis_y = axis_y - 0.1
			g_joy_dragging = 1
		EndIf
		If KeyDown(g_opt_ctrldown[0])
			axis_y = axis_y + 0.1
			g_joy_dragging = 1
		EndIf
		If g_eng_hasjoystick <> 0
			If g_opt_ctrlidx = 2
				joyIdx = 1
			EndIf
			If g_opt_ctrlleft[1] = -1
				If g_joy_dragging = 0
					axis_x = JoyX(joyIdx)
					axis_y = JoyY(joyIdx)
				EndIf
				If JoyX(joyIdx) > 0.25 Or JoyY(joyIdx) > 0.25
					g_joy_dragging = 0
				EndIf
			Else
				If JoyDown(g_opt_ctrlleft[1], joyIdx)
					axis_x = axis_x - 0.1
					g_joy_dragging = 0
				EndIf
				If JoyDown(g_opt_ctrlright[1], joyIdx)
					axis_x = axis_x + 0.1
					g_joy_dragging = 0
				EndIf
				If JoyDown(g_opt_ctrlup[1], joyIdx)
					axis_y = axis_y - 0.1
					g_joy_dragging = 0
				EndIf
				If JoyDown(g_opt_ctrldown[1], joyIdx)
					axis_y = axis_y + 0.1
					g_joy_dragging = 0
				EndIf
			EndIf
		EndIf
		If kickenabled <> 0
			kickbuttondown = 0
			If KeyHit(g_opt_ctrlbutton[0])
				kickbuttonhits = g_time
				activebutton = 1
			EndIf
			If KeyDown(g_opt_ctrlbutton[0])
				kickbuttondown = 1
			EndIf
			If g_eng_hasjoystick <> 0
				If JoyHit(g_opt_ctrlbutton[1], joyIdx)
					kickbuttonhits = g_time
					activebutton = 1
				EndIf
				If JoyDown(g_opt_ctrlbutton[1], joyIdx)
					kickbuttondown = 1
				EndIf
			EndIf
			If g_opt_kickmode = 1
				If KeyHit(g_opt_ctrlbutton2[0])
					kickbuttonhits = g_time
					activebutton = 2
				EndIf
				If KeyHit(g_opt_ctrlbutton3[0])
					kickbuttonhits = g_time
					activebutton = 3
				EndIf
				If KeyDown(g_opt_ctrlbutton2[0])
					kickbuttondown = 1
				EndIf
				If KeyDown(g_opt_ctrlbutton3[0])
					kickbuttondown = 1
				EndIf
				If KeyDown(g_opt_ctrlbutton4[0])
					kickbuttondown = 1
				EndIf
				If g_eng_hasjoystick <> 0
					If JoyHit(g_opt_ctrlbutton2[1], joyIdx)
						kickbuttonhits = g_time
						activebutton = 2
					EndIf
					If JoyHit(g_opt_ctrlbutton3[1], joyIdx)
						kickbuttonhits = g_time
						activebutton = 3
					EndIf
					If JoyDown(g_opt_ctrlbutton2[1], joyIdx)
						kickbuttondown = 1
					EndIf
					If JoyDown(g_opt_ctrlbutton3[1], joyIdx)
						kickbuttondown = 1
					EndIf
					If JoyDown(g_opt_ctrlbutton4[1], joyIdx)
						kickbuttondown = 1
					EndIf
				EndIf
			EndIf
		Else
			kickbuttonhits = 0
			kickbuttondown = 0
			activebutton = 0
			If g_eng_hasjoystick = 0 Or (Not JoyDown(g_opt_ctrlbutton[1], joyIdx) And Not JoyDown(g_opt_ctrlbutton2[1], joyIdx) And Not JoyDown(g_opt_ctrlbutton3[1], joyIdx) And Not JoyDown(g_opt_ctrlbutton4[1], joyIdx))
				If Not KeyDown(g_opt_ctrlbutton[0]) And Not KeyDown(g_opt_ctrlbutton2[0]) And Not KeyDown(g_opt_ctrlbutton3[0]) And Not KeyDown(g_opt_ctrlbutton4[0])
					kickenabled = 1
				EndIf
			EndIf
		EndIf
	EndIf
	ClampFloat(Varptr axis_x, -1.0, 1.0)
	ClampFloat(Varptr axis_y, -1.0, 1.0)
	If a2 <> 0 And (g_joy_dragging = 1 Or g_opt_ctrlleft[g_opt_ctrlidx] > -1)
		Local mult:Float = 2.0
		Local edge:Float = 0.9
		If g_joy_dragging Or g_opt_ctrlleft[1] > -1
			edge = 0.1
		EndIf
		Select a2
			Case 1
				If axis_x <= -edge Then direction = origDir + mult
				If axis_x >= edge Then direction = origDir - mult
			Case -1
				If axis_x <= -edge Then direction = origDir - mult
				If axis_x >= edge Then direction = origDir + mult
		End Select
		If direction = origDir
			If axis_y <= -edge
				If origDir > 270.0 + mult * 3.0 Or origDir < 90.0
					direction = origDir - mult * 3.0
				Else
					If origDir < 270.0 - mult * 3.0
						direction = origDir + mult * 3.0
					EndIf
				EndIf
			Else
				If axis_y >= edge
					If origDir < 90.0 - mult * 3.0 Or origDir > 270.0
						direction = origDir + mult * 3.0
					Else
						If origDir > 90.0 + mult * 3.0
							direction = origDir - mult * 3.0
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
		axis_x = 0
		axis_y = 0
	Else
		axis_x = axis_x * 0.9
		axis_y = axis_y * 0.9
		force = Sqr(axis_x * axis_x + axis_y * axis_y)
		ClampFloat(Varptr force, 0.0, 0.9)
		If force > 0.2
			direction = GetActualDirection()
		EndIf
		Local blend:Double = origDir
		Local diff:Float = AngleDiff(origDir, direction, 0)
		blend :+ g_ply_turnrate * diff
		direction = blend
	EndIf
	WrapAngle(direction)
End Method
