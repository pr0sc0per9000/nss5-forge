' TBossMessage.Draw
' VA 0x00570B40   872 bytes original.
', re-verified this pass against a live probe (harness.try_method).
'
' STATUS: BYTE-EXACT MATCH (872/872, mode=reloc, 39 reloc-masked operands) confirmed via
' scripts/harness.try_method('TBossMessage','Draw', body) immediately before this write.
' Still filed under recovered_unverified per the task's instruction to only edit this file;
' promote to src/recovered/ in the normal pass if that's this project's next step.
'
' WHAT WAS WRONG (previous candidate was 856 bytes, 4.4% byte agreement) and what fixed it,
' found by iterating against the live oracle (scripts/harness.py / localise_diff.py), not by
' guessing:
'
' 1. ADDITION OPERAND ORDER (codegen-patterns 10.1/21 "left-to-right is not always the
'    English reading order"). The two alfa-timing guards were written
'    `fVar1 * K + Float(Self.starttime)`; the original's FPU push order (traced from the raw
'    disassembly: GT pushed, then starttime, THEN fVar1 duplicated+multiplied+added) proves
'    the source term order is the other way round:
'      `Float(Self.starttime) + fVar1 * 25.0`   /   `Float(Self.starttime) + fVar1 * 75.0`
'    The second guard is also `>` with g_player_int50 on the left (matches the original
'    always pushing g_player_int50 first, mirroring the first guard's `<`), not `<` with the
'    sum on the left as Ghidra's canonicalised C prints it (10.1: never trust Ghidra's
'    operand order).
'
' 2. `Select Self.flipit / Case 0 / Case 1` was written as `If flipit=0 ... ElseIf flipit=1`.
'    Same bug class as 10.2: the original dispatches with `mov eax,flipit; cmp 0; je; cmp 1;
'    je; jmp` (one dispatch, no Default) and each Case body ends with an unconditional jump
'    to after End Select -- If/ElseIf re-tests the second condition inline instead, costing
'    an extra `cmp/jne` exactly where GAP10 kept landing.
'
' 3. `If Float(g_engine_int163) < ly Then ly = Float(g_engine_int163)` needed the
'    solo-relational spelling flip (ANOTHER instance of 10.1, this time on a trivial
'    single-push RHS): writing GT-first forced bcc to emit an `fxch` the original doesn't
'    have. `If ly > Float(g_engine_int163) Then ly = Float(g_engine_int163)` (ly pushed
'    first) reproduces the original's fucompp/setbe with no swap.
'
' 4. The DrawImage/DrawText tail is a Then/Else PHYSICAL-LAYOUT swap (same pattern
'    documented in TLabel.Draw.bmx's header): the original falls straight through into the
'    flipit<>0 (GetScale/SetScale) block and JUMPS FORWARD to the flipit=0 DrawImage-only
'    block, i.e. the source is `If Self.flipit <> 0 Then <scale block> Else <plain
'    DrawImage> End If`, not `If flipit = 0 Then <plain> Else <scale block> End If` -- same
'    branches, negated test, Then/Else swapped, to match which block bcc places as the
'    fallthrough.
'
' 5. THE BIG ONE: `tx - Float(tw / 2)` and the flipit<>0 branch's y are NOT computed inline
'    at their point of use -- Ghidra inlines them because SSA can't see the original
'    statement boundaries, but the raw bytes show the original computes each into its own
'    Local (`dtx`, `dty`) right after TextWidth/TextHeight, stores it, and DrawText at the
'    end just reads the two finished Locals. Concretely:
'      Local tx:Float = lx + 76.0
'      Local tw:Int = TextWidth(Self.message)
'      tx = tx - Float(tw / 2)
'      Local dtx:Float = tx                    ' <- extra Local, copied out of tx
'      Local ty:Float = ly - 88.0
'      Local th:Int = TextHeight(Self.message)
'      ty = ty - Float(th / 2)
'      Local dty:Float = ty                    ' <- extra Local, copied out of ty
'    and inside the flipit<>0 branch the *second* y computation is ALSO its own fresh Local
'    (`ty2`, not a reassignment of the outer `ty`) copied into `dty` at the end -- that
'    fourth Local is what supplied the original's 10th (last) stack slot: without it the
'    frame came out `sub esp,0x24` (9 slots) against the original's `sub esp,0x28` (10), a
'    remainder that showed up as nothing but stack-offset SUBs everywhere downstream.
'    DrawText itself then just reads the two finished values: `DrawText(Self.message, dtx,
'    dty)`.
'
' Globals: g_player_int50:Int is g_matchtime/g_ticks/g_calltime's shared slot (0xC6EFD4);
' kept as-is, already the dominant name for this address across the corpus and irrelevant to
' the byte match either way. g_bossmessages:TList (0xC6B284) / g_boss_img:TImage (0xC6B288)
' renamed from this file's earlier g_Object719/g_Object720 placeholders to match the names
' already established by byte-identical siblings TBossMessage.DrawAll.bmx and
' TBossMessage.SetUp.bmx -- re-verified MATCH after the rename (global names are pure
' compile-time symbols, cannot change the emitted bytes).

'!Global g_player_int50:Int
'!Global g_bossmessages:TList
'!Global g_boss_img:TImage
'!Global g_engine_int163:Int
Method Draw:Int(a0:Float, a1:Float, a2:Float)
	If g_player_int50 < Self.starttime Then Return 0
	If g_player_int50 > Self.finishtime Then
		g_bossmessages.Remove(Self)
		Return 0
	End If
	Local fVar1:Float = Float((Self.finishtime - Self.starttime) / 100)
	If fVar1 = 0.0 Then fVar1 = 1.0
	If Float(g_player_int50) < Float(Self.starttime) + fVar1 * 25.0 Then
		Self.alfa = (Float(g_player_int50 - Self.starttime) / fVar1) / 25.0
	End If
	If Float(g_player_int50) > Float(Self.starttime) + fVar1 * 75.0 Then
		Self.alfa = (Float(Self.finishtime - g_player_int50) / fVar1) / 25.0
	End If
	ClampFloat(Varptr Self.alfa, 0.0, 1.0)
	If Self.message.Length <> 0 Then
		SetAlpha(Self.alfa)
		SetColourHex(Self.colour)
		Local lx:Float = Self.x * a0 - a1
		Local ly:Float = Self.y * a0 - a2
		If lx < 50.0 Then lx = 50.0
		If Self.flipit = -1 Then
			Self.flipit = 0
			If ly < 128.0 Then Self.flipit = 1
		End If
		Select Self.flipit
		Case 0
			If ly < 200.0 Then ly = 200.0
		Case 1
			If ly < 72.0 Then ly = 72.0
		End Select
		If ly > Float(g_engine_int163) Then ly = Float(g_engine_int163)
		Local tx:Float = lx + 76.0
		Local tw:Int = TextWidth(Self.message)
		tx = tx - Float(tw / 2)
		Local dtx:Float = tx
		Local ty:Float = ly - 88.0
		Local th:Int = TextHeight(Self.message)
		ty = ty - Float(th / 2)
		Local dty:Float = ty
		If Self.flipit <> 0 Then
			Local sx:Float
			Local sy:Float
			GetScale(sx, sy)
			SetScale(sx, -sy)
			DrawImage(g_boss_img, lx, ly, 0)
			Local ty2:Float = ly + 88.0
			th = TextHeight(Self.message)
			ty2 = ty2 - Float(th / 2)
			dty = ty2
			SetScale(sx, sy)
		Else
			DrawImage(g_boss_img, lx, ly, 0)
		End If
		SetColor(0, 0, 0)
		DrawText(Self.message, dtx, dty)
	End If
	Return 0
End Method
