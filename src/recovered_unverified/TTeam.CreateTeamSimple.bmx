' TTeam.CreateTeamSimple
' VA 0x004DD418   1340 bytes   slot 0x44   sig (i,$,$,i,i,:TKit,:TKit,i,i,i,:TFixture):TTeam
' KIND=Function -- static, no implicit Self. param_1 is a real parameter (team id), not Self.
'
' REFINEMENT PASS (2026-08-17): no build/bmk access this pass (hard constraint), but
' scripts/localise_diff.py run with `--exe src/assembled/nss5_assembled.exe` (masked/
' relocation-aware, reads the already-assembled exe, does NOT build) gave a clean 7-gap/
' -15-byte report, delta_accounted COMPLETE. Gaps 1-4 (-10,-9,+9,-2 = -12 of the -15) all
' trace to ONE fix, applied this pass:
'   The old header asserted (without byte evidence) that `a10 = Null` must be the DIRECT
'   12-byte comparison form. The oracle says otherwise: the original emits the STAGED/
'   inverted form -- `mov eax,a10; cmp eax,bbNullObject; setne al; movzx eax,al; cmp eax,0;
'   jne <skip Null-body>` -- which is codegen-patterns.md 10.3's documented `If Not x` shape
'   (21 bytes, "branch sense inverted"), not the `If x = Null` shape (12 bytes, direct je).
'   Rewritten `If a10 = Null` -> `If Not a10` (identical Then-body, i.e. semantically a
'   no-op change, but it is the source text bcc actually compiled). Additionally, the
'   `a10.level` dispatch that follows has NO re-test of `level` inside either arm in the
'   original (a clean `cmp 0/je; cmp 1/je; jmp end` dispatch, case bodies reached with no
'   further compare) -- the positional tell for a `Select`, not an `ElseIf` cascade
'   (codegen-patterns 10.2); the old `Else If a10.level = 0 ... Else If a10.level = 1`
'   compiled an extra, redundant `cmp/jne` inside the second arm that the original does not
'   have (that is GAP3's extra +9 bytes). Rewritten as `Select a10.level / Case 0 / Case 1 /
'   End Select` nested inside the `Else` of `If Not a10`.
'
' REMAINING (not fixed, lower confidence, no build access to iterate): GAP5/6/7 (-1/-1/-1
' byte each, -3 total), all inside the "for each squad player, if newstar=0 and Rand(6)<2,
' replace the name" logic (both the initial squad walk and the per-year replacement walk).
' The original consistently pairs a short conditional jump to the inline body with a
' SEPARATE unconditional jump around it (e.g. `je BODY` / `jmp SKIP`, and `cmp eax,1;jle
' BODY` / `jmp SKIP`), where our build collapses each to a single inverted conditional jump
' (`jne SKIP`, `cmp eax,2;jge SKIP`) -- functionally identical, 1 byte shorter each. Could
' not identify a source-level rephrasing that reproduces the two-jump shape without a build
' loop to test against; flagging for whoever picks this up next with toolchain access.
'
' ASSUMPTIONS
'  * 0x00C6F028 g_contractoffer_tplayer:TProfile -- CERTAIN tier in explain_global (20
'    bodies, forced in 17, unanimous). `*(int*)(*(int*)(g + 0x1d0) + 100)` is the same
'    byte pattern as TClub.Compare's `g_contractoffer_tplayer.myclub.nationid` (0x1d0 =
'    TProfile.myclub per object_model.json, +100/0x64 = TClub.nationid). The later
'    `*(int**)(g + 0x10)` is TProfile.date (:TMyDate, offset 0x10), and vtable+0x54 on a
'    TMyDate is GetYear() (object_model.json: TMyDate methods list Year at offset 0x54) --
'    i.e. `g_contractoffer_tplayer.date.GetYear()`, a small career-year counter (grep
'    evidence elsewhere in the corpus compares this to 1, 2, 20 -- never a calendar year),
'    consistent with the loop below only running a handful of times.
'  * 0x00C6EFD4 resolves STRONG to g_player_int50:Int in explain_global (37 bodies, 13/16
'    agree) -- NOT the g_ticks name a different sibling used for the same address; the
'    solver's verdict wins per the project's naming-unification rule.
'  * g_team_arr01:String[] (0x00C5A430, firstnames) / g_team_arr02:String[] (0x00C5A434,
'    lastnames) -- named and typed by TNames.SetUp.bmx, which this Function calls.
'  * TNation.SelectById / TClub.SelectById / TFormation.Create are Functions (class-table
'    slots 0x58/0x60/0x34 on their respective Types); TNames.SetUp is a Function at
'    TNames+0x30. FUN_005b40bf is the CreateList|CreateMap|TGNetHost.Create alias, typed
'    CreateList here because the result lands in a :TList field (cornerformation).
'  * TTeam field layout (object_model.json): id 8, name 12, tla 16, rating 20, controller
'    24, squad 28, lastchangeplayer 32, formation 36, cornerformation 40, kitplayer 44,
'    kitkeeper 48, skin1 52, skin2 56, newstarselno 60 -- matches every piVar4[N] index
'    used below exactly (index = offset/4).
'  * TPlayer field layout: newstar 8, name 28, initials 32 -- puVar9[2]/[7]/[8] after the
'    `_bbObjectDowncast` in each squad walk.
'  * TNation field layout: id 12 (inherited TBase_Team.id), primaryskin 108, secondaryskin
'    112 -- puVar9[3]/[0x1b]/[0x1c] in the nation lookups.
'  * `For ... EachIn` already emits its own null-skip (codegen-patterns 10.6) -- the
'    `puVar9 != Null` guard on every squad walk below is NOT written as a separate `If`;
'    it is exactly what `For Local p:TPlayer = EachIn t.squad` already guarantees.
'  * The random-name picks in the first squad walk happen for EVERY player (their Rand
'    calls appear unconditionally once inside the loop), and are only USED when
'    `p.newstar = 0` -- a plain nested `If`, not folded into the walk's implicit guard.
'  * In the second (per-year) squad walk, the `Rand(6) < 2` call only appears in the
'    decompilation when `p.newstar = 0` already held, i.e. the RNG draw is genuinely
'    skipped for newstar players -- reproduced with a nested `If`, not a combined
'    `And`, so the skip is guaranteed regardless of BlitzMax And/Or evaluation rules.
'  * `If Not a10` (not `If a10 = Null`): the oracle shows the staged/inverted
'    21-byte form, not a direct 12-byte `cmp/je`.
'  * String concatenation and slicing calls are NOT CSE'd (bcc never does this): the same
'    `fn + " " + ln` is recomputed for both the LogLine and the field store, and fn/ln are
'    each sliced to their first character for `initials` without reusing prior temps --
'    reproduced as literal repeated expressions per codegen-patterns 10.6/"no CSE".
'!Global g_contractoffer_tplayer:TProfile
'!Global g_team_arr01:String[]
'!Global g_team_arr02:String[]
'!Global g_player_int50:Int
	Function CreateTeamSimple:TTeam(a0:Int, a1:String, a2:String, a3:Int, a4:Int, a5:TKit, a6:TKit, a7:Int, a8:Int, a9:Int, a10:TFixture)
		SeedRnd(a0)
		Local t:TTeam = New TTeam
		t.id = a0
		t.name = a1
		t.tla = a2
		t.rating = a3
		t.controller = a4
		t.kitplayer = a5
		t.kitkeeper = a6
		If a8 = -1
			t.controller = 0
		EndIf
		If t.controller = 1
			t.newstarselno = a8
		EndIf
		Local nationid:Int = g_contractoffer_tplayer.myclub.nationid
		If Not a10
			Local n:TNation = TNation.SelectById(g_contractoffer_tplayer.myclub.nationid)
			t.skin1 = n.primaryskin + 1
			t.skin2 = n.secondaryskin + 1
		Else
			Select a10.level
				Case 0
					Local c:TClub = TClub.SelectById(t.id)
					Local n:TNation = TNation.SelectById(c.nationid)
					If n <> Null
						nationid = n.id
						t.skin1 = n.primaryskin + 1
						t.skin2 = n.secondaryskin + 1
					EndIf
				Case 1
					Local n:TNation = TNation.SelectById(t.id)
					If n <> Null
						nationid = n.id
						t.skin1 = n.primaryskin + 1
						t.skin2 = n.secondaryskin + 1
					EndIf
			End Select
		EndIf
		t.formation = TFormation.Create(a7)
		t.cornerformation = CreateList()
		t.CreateSquadSimple()
		t.PaintSquad(a9)
		t.GetTunnelPositions(1)
		TNames.SetUp(nationid)
		For Local p:TPlayer = EachIn t.squad
			Local fn:String = g_team_arr01[Rand(g_team_arr01.Length) - 1]
			Local ln:String = g_team_arr02[Rand(g_team_arr02.Length) - 1]
			If p.newstar = 0
				LogLine(fn + " " + ln)
				p.name = fn + " " + ln
				p.initials = fn[..1] + ln[..1]
			EndIf
		Next
		Local yr:Int = g_contractoffer_tplayer.date.GetYear()
		While yr > 1
			yr = yr - 1
			For Local p:TPlayer = EachIn t.squad
				If p.newstar = 0
					If Rand(6) < 2
						Local fn:String = g_team_arr01[Rand(g_team_arr01.Length) - 1]
						Local ln:String = g_team_arr02[Rand(g_team_arr02.Length) - 1]
						LogLine(fn + " " + ln + " is replacing " + p.name)
						p.name = fn + " " + ln
						p.initials = fn[..1] + ln[..1]
					EndIf
				EndIf
			Next
		Wend
		SeedRnd(g_player_int50)
		Return t
	End Function
