' TPlayer.TapKickAdvanced   (KIND=Method, SIG=()i, SLOT=0x100)
' VA 0x004F7C89   1232 bytes   (Ghidra-authoritative)
'
' Newstar-only counterpart to TapKick() -- TapKick() dispatches here directly
' (`If Self.newstar And g_player_int14 = 1 Then Self.TapKickAdvanced() ; Return 0`,
' see TPlayer.TapKick.bmx) whenever the tapping player is an AI-controlled newstar, so
' this body never re-checks Self.newstar itself.
'
' Structure (confirmed against a full disassembly of 0x004F7C89..0x004F8158, not just the
' Ghidra C -- see STRUCTURE NOTES below):
'   1. Select Self.joy.activebutton (1/2/3) sets an initial kicktype/kickdirection from
'      directiontogoal_opp or directiontoteammate (both genuine Int fields, widened to
'      Float on the assignment -- confirmed by `fild`, not `fld`, at each site).
'   2. Unconditionally computes incrosszone = TPitch.InsideCrossZone(...), reset to 0 if
'      the match state is 3.
'   3. A second, independent read of Self.joy.activebutton drives the kickpower/direction
'      calculation:
'        - activebutton = 1: "near post" jitter off distancetogoal_opp and Self.shooting.
'        - Self.teammateid = 0: Knock (joy-driven power/direction) unless in a valid
'          1-v-1 cross zone, in which case Cross (pick a teammate via
'          TTeam.GetPlayerNearestToXY and aim at them or at goal-centre).
'        - otherwise: distancetoteammate-based power (0.15x baseline, then activebutton
'          2/3 overrides) plus a passing-stat jitter.
'   4. Match-state / training overrides force kicktype = 1, then DoAnimKick + TBall.Kick.
'
' STRING LITERALS (read with harness.read_string() against NSS5.exe):
'   "TapKickAdvanced" @0x00C79DC8, "Knock" @0x00C79DF8, "Cross" @0x00C72880.
'
' FLOAT CONSTANTS (read directly out of the masked .rdata addresses -- codegen-patterns.md
' section 21, "masked != unknowable"): 0x00C79DF4=0.5, 0x00C79E10=30.0, 0x00C79E14=0.15,
' 0x00C79E18=1.5, 0x00C79E1C=1.5. All five are private to this function (explain_global.py
' returns nothing for them), so they are written as bare Float literals, not Globals. The
' YardsToPixels args 12.0/25.0 are immediate x87 pushes (`push 0x41400000` /
' `push 0x41c80000`), not masked memory constants.
'
' FIELD OFFSETS (cross-checked against extracted/object_model.json's TPlayer/TJoy member
' lists): newstar=8(i), id=0x10(i), controller=0x18(i), x=0x4c(f), y=0x50(f),
' direction=0x78(f), kickpower=0xc0(f), kickdirection=0xc4(f), directiontogoal_opp=0xe0(i),
' distancetogoal_opp=0xe8(i), teammateid=0xf0(i), directiontoteammate=0xf8(i),
' distancetoteammate=0xfc(f), joy=0x158(:TJoy), passing=0x170(f), shooting=0x178(f);
' TJoy.direction=0x14(f), TJoy.activebutton=0x24(i). directiontogoal_opp and
' directiontoteammate are genuine Ints (object_model sig 'i'), confirmed by `fild` (not
' `fld`) at their read sites -- the assignment to the Float field kickdirection is a plain
' numeric widening, no explicit Float()/Int() needed in source.
'
' CLASS-TABLE SLOTS used: TPlayer 0x160=GetShootingDirection, 0x174=GetMyTeam,
' 0x1e4=DoAnimKick; TTeam 0x90=GetPlayerNearestToXY(i,i,i,:TPlayer,i):TPlayer; TPitch
' [0x00C5D98C]=InsideCrossZone(i,i,i)i, [0x00C5D998]=YardsToPixels(f)f; TBall
' [0x00C5DEA4]+0x68=Kick(:TPlayer,f,f,i,i)i. MODULE FUNCTIONS: Dist2D, AngleTo, Rand (all
' already recovered elsewhere; 0x00505DA2=Dist2D, 0x0050639D=AngleTo, 0x0059F089=Rand,
' 0x005B9690=_bbFloatToInt, emitted implicitly for each Float->Int call argument -- nothing
' written for it in source).
'
' STRUCTURE NOTES (each verified against the raw disassembly, not just the decompiled C):
'   * The `Select Self.joy.activebutton` (Case 1/2/3) at the top is a genuine Select: all
'     three `cmp/je` compares run back to back (0x4F7CB2..0x4F7CBF) before any Case body,
'     with a single `jmp` for the no-Default fallthrough -- codegen-patterns.md 10.2.
'   * The later `If Self.joy.activebutton = 3 ... ElseIf ... = 2` pair is NOT a Select:
'     each compare is immediately followed by its own body (test, body, test, body), the
'     interleaved shape 10.2 attributes to If/ElseIf. It also only covers 2 of the 3
'     possible values (case 1 was already handled by the outer If), which a Select can't
'     express as cleanly.
'   * Inside the activebutton=3 arm, `If Self.distancetoteammate <= YardsToPixels(25.0)`
'     guards a SECOND, textually-redundant `If Self.joy.activebutton = 3` before the
'     float19 kickpower is applied. The disassembly confirms this literally: a fresh
'     `mov eax,[edi+0x158] / cmp [eax+0x24],3 / jne` sits inside the already-true
'     activebutton=3 arm (0x4F8000-0x4F800A). Reproduced as-is, not simplified away.
'   * The `Dist2D(...) < YardsToPixels(12.0)` cross-zone-target compare is written bare/
'     inline (no named Local for the Dist2D reload), matching TapKick.bmx's own
'     byte-verified precedent for the identical comparison shape (its header explains why:
'     the reload gets a spill slot as an anonymous compiler temp either way, and naming it
'     is what breaks the allocator's ordering there).
'   * Both jitter blocks (kickpower -= Rand(Int(f),1); kickdirection += Rand(Int(-f),...))
'     use their own fresh `Local kp:Float` / `Local kd:Float` pair per block (own stack
'     slots per the disassembly: ebp-4/ebp-8 for the activebutton=1 arm, ebp-0xC/ebp-0x10
'     for the final-else arm) -- BlitzMax Locals are block-scoped, so the repeated names
'     are legal.
'   * team/target reuse the same physical register (esi) after GetMyTeam()'s last use,
'     matching TapKick.bmx's `Local team:TTeam` / `Local target:TPlayer` idiom exactly.
'   * GetShootingDirection() is called fresh every time it's needed (never cached across
'     statements), matching TapKick.bmx's and ChaseBall.bmx's style.
'
' UNCERTAIN: the Select-vs-If/ElseIf calls above are inferred from the disassembly's
' instruction order per codegen-patterns.md 10.2, not proven by a byte-for-byte build here
' (no assemble.py run, per the task rules). The bare-vs-Local choice for the Dist2D compare
' similarly follows TapKick.bmx's precedent rather than being independently re-verified.
'
' REFINEMENT PASS (byte oracle) -- started at 38.3% (472/1232), first difference at byte 13
' (the "TapKickAdvanced" string-push immediate -- expected noise, see below). orig_len=1232,
' our_len=1240 (delta +8). Diagnosed by disassembling BOTH nss5_assembled.exe's compiled
' bytes and the original's raw machine code directly (scripts/bytematch.py's
' disasm_original() helper against both binaries, blanking absolute operands/branch
' displacements to align the two instruction streams -- codegen-patterns.md's
' localise_diff.py technique, applied by hand since localise_diff.py itself calls
' harness.try_method and would trigger a build).
'   * NOTE ON ADDRESSES: every FIRST-DIFFERENCE byte reported by bytematch.py in this
'     function is an absolute data/code address (string pool addr, global addr, relocated
'     call target) -- confirmed by running the SAME tool against TPlayer.CheckBallContact,
'     an already byte-verified sibling in src/recovered/, which ALSO reports a raw MISMATCH
'     against the current nss5_assembled.exe purely from address bytes (0xC5DEA4 vs
'     0xCA6844, etc), same length both sides. These are whole-program link-layout artifacts,
'     not statement bugs, and are not chased here.
'   * ROOT CAUSE (fixed): the Knock/Cross dispatch (`If incrosszone=0 Or g_player_int01<>1
'     Then Knock Else Cross`) compiled 5 bytes longer than the original's equivalent test at
'     VA 0x004F7E3D. The raw bytes prove WHY: original's first AND-operand is `incrosszone
'     <> 0` -- for short-circuit AND, the "operand false" exit can reuse the raw `cmp
'     eax,0/je` result directly as the whole expression's boolean, because incrosszone being
'     0 on that path already IS the canonical 0/false value; no `sete`/`movzx` needed (5
'     bytes saved right there: `cmp;je;mov;cmp;sete;movzx;cmp;je`=28 bytes total). Our OR-
'     form tested the EQUALITY case first (`incrosszone = 0`), whose true-exit needs an
'     explicit `sete`+`movzx` to turn "raw incrosszone is 0" into "boolean 1" (OR's early-out
'     value), which original's shape never pays for. Because AND(<>0, =1) is Cross-then-
'     Knock (De Morgan's negation of OR(=0,<>1)=Knock-then-Cross) with the branches swapped,
'     fixing the byte count ALSO requires swapping which LogLine/body is Then vs Else --
'     written that way below. This also explains original's use of a 6-byte far conditional
'     jump (`0F 84 ...`) to reach Knock, vs our short `74/75` form to reach Cross: Knock is
'     now placed AFTER the ~150-byte Cross block, same as the original's layout.
'   * REMAINING GAP (not fixed, ~3 bytes unaccounted for by the above alone; every other
'     content difference in the function is address-encoding noise per localise_diff-by-hand
'     above): the `Self.distancetoteammate <= TPitch.YardsToPixels(25.0)` If/Else (guarding
'     the g_player_float19/g_player_float20 kickpower pick, VA 0x004F7FD9) compiles in the
'     ORIGINAL as `setbe al` (tests "<=" directly) with the TRUE case reached by a forward
'     `jne` into the nested `If Self.joy.activebutton=3` block, and the FALSE case
'     (float20) as the immediate fallthrough -- our build produces `seta al` (tests ">",
'     the complement) with `jne` reaching float20 and the nested block as fallthrough. This
'     is NOT the same class of bug as the Knock/Cross one above: our current source text
'     (`If distancetoteammate<=25 Then <nested> Else float20`) is already the natural/
'     direct phrasing of the decompiled semantics, and there is no short-circuit-boolean
'     "avoid materialising a sete" trick available for a single bare relational compare --
'     both `setbe`/`jne-to-Then` and `seta`/`jne-to-Else` are equal-cost, semantically
'     identical lowerings of the identical source text, so which one a given compiler
'     invocation picks is not determined by anything expressible in BlitzMax source. (Ruled
'     out treating this as a TapKick.bmx-style ">" precedent: TapKick.bmx's own `>25.0`
'     comparisons at that idiom are single-armed `If ... Then float20` with no Else, a
'     different, simpler shape that doesn't bear on an If/Else's branch-placement choice.)
'     Same underlying class as CheckPlayerContactAll.bmx's documented "ball register vs
'     spill" gap: a compiler-internal choice (there, register colouring; here, branch
'     polarity) that both sides implement equally validly, most likely following from
'     register/FPU-stack state set up earlier in the SAME function rather than from this
'     statement in isolation. Left alone rather than guessed at, since guessing here has a
'     real chance of being a net-zero or negative change with no way to verify without a
'     build (forbidden this pass) -- unlike the Knock/Cross fix above, which was checked
'     mechanically instruction-by-instruction against the original bytes before writing.
'   * Checked for the project's "missing Global assignment" defect class per this pass's
'     brief: every DAT_00c5b1fc/DAT_00c6cf90/DAT_00c5d658 reference in the decompilation is
'     a READ; the original never writes any module Global in this function. Nothing to
'     restore here.

'!Global g_player_int01:Int
'!Global g_training_int03:Int
'!Global g_player_int19:Int
'!Global g_player_float19:Float
'!Global g_player_float20:Float
'!Global g_player_float21:Float
'!Global g_player_tplayer02:TBall

LogLine("TapKickAdvanced")
Local kicktype:Int = 0
Select Self.joy.activebutton
	Case 1
		kicktype = 2
		Self.kickdirection = Self.directiontogoal_opp
		If g_player_int01 = 4
			Self.kickdirection = Self.direction
		End If
	Case 2
		kicktype = 1
		Self.kickdirection = Self.directiontoteammate
	Case 3
		kicktype = 3
		Self.kickdirection = Self.directiontoteammate
End Select

Local dir:Int = Self.GetShootingDirection()
Local incrosszone:Int = TPitch.InsideCrossZone(Int(Self.x), Int(Self.y), dir)
If g_player_int01 = 3 Then incrosszone = 0

If Self.joy.activebutton = 1
	Self.kickpower = Self.distancetogoal_opp * 0.5
	Local kp:Float = Self.kickpower
	kp = kp - Rand(Int(Self.shooting), 1)
	Self.kickpower = kp
	Local kd:Float = Self.kickdirection
	kd = kd + Rand(Int(-Self.shooting), Int(Self.shooting))
	Self.kickdirection = kd
ElseIf Self.teammateid = 0
	If incrosszone <> 0 And g_player_int01 = 1
		LogLine("Cross")
		Local team:TTeam = Self.GetMyTeam()
		Local target:TPlayer = team.GetPlayerNearestToXY(0, g_player_int19 * Self.GetShootingDirection(), 0, Null, 0)
		Self.teammateid = target.id
		If Dist2D(target.x, target.y, 0, g_player_int19 * Self.GetShootingDirection()) < TPitch.YardsToPixels(12.0)
			Self.kickdirection = AngleTo(Self.x, Self.y, target.x, target.y)
		Else
			Self.kickdirection = AngleTo(Self.x, Self.y, 0, g_player_int19 * Self.GetShootingDirection())
		End If
		Self.kickpower = Self.distancetoteammate * g_player_float21
	Else
		LogLine("Knock")
		Self.kickdirection = Self.joy.direction
		Self.kickpower = 30.0
	End If
Else
	Self.kickpower = Self.distancetoteammate * 0.15
	If Self.joy.activebutton = 3
		kicktype = 3
		If Self.distancetoteammate <= TPitch.YardsToPixels(25.0)
			If Self.joy.activebutton = 3
				Self.kickpower = Self.distancetoteammate * g_player_float19
			End If
		Else
			Self.kickpower = Self.distancetoteammate * g_player_float20
		End If
	ElseIf Self.joy.activebutton = 2
		Self.kickpower = Self.distancetoteammate * g_player_float20
		kicktype = 1
	End If
	Local kp:Float = Self.kickpower
	kp = kp - Rand(Int(Self.passing), 1)
	Self.kickpower = kp
	Local kd:Float = Self.kickdirection
	kd = kd + Rand(Int(-Self.passing * 1.5), Int(Self.passing * 1.5))
	Self.kickdirection = kd
End If

If g_player_int01 = 2 Then kicktype = 1
If g_training_int03 = 4 Then kicktype = 1
Self.DoAnimKick(Int(Self.kickpower))
g_player_tplayer02.Kick(Self, Self.kickdirection, Self.kickpower, kicktype, Self.teammateid)
Return 0
