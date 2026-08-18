' TTeam.CreateTeamSimple
' VA 0x004DD418   1340 bytes   slot 0x44   sig (i,$,$,i,i,:TKit,:TKit,i,i,i,:TFixture):TTeam
' KIND=Function -- static, no implicit Self. param_1 is a real parameter (team id), not Self.
'
' ASSUMPTIONS
'  * 0x00C6F028 is g_profile:TProfile, not a separate g_contractoffer_tplayer slot.
'    explain_global.py resolves 0x00C6F028 CERTAIN/forced for the name
'    "g_contractoffer_tplayer" (22 bodies) and STRONG for "g_profile" (158 bodies,
'    112/113 agree); addr_oracle.py's machine-code-order dump (extracted/addr_oracle.json)
'    lists 0x00C6F028 in the touched-address set of every body declaring either name. The
'    byte-identical (786/786) src/recovered/TScreen_NewPlayer.DoClubTrial.bmx documents
'    "0x00C6F028 TProfile g_profile" in its own header and writes it directly on the
'    career-creation path this Function is called from ("g_profile.myclub = c", line 60)
'    immediately before TTraining.SetUpTraining -> CreateTeamSimple runs. No recovered
'    body anywhere assigns a Global literally named g_contractoffer_tplayer, and
'    scripts/assemble.py's global_alias_map() carries no entry unifying that spelling
'    with g_profile, so writing this Function against that name would compile to a
'    second, permanently-Null Global at this address and crash the nationid read below on
'    every career start. Written here as g_profile directly instead, matching
'    DoClubTrial's own name for the slot it just filled in.
'    `*(int*)(*(int*)(g + 0x1d0) + 100)` is the same byte pattern as TClub.Compare's
'    `g_contractoffer_tplayer.myclub.nationid` (0x1d0 = TProfile.myclub per
'    object_model.json, +100/0x64 = TClub.nationid). The later `*(int**)(g + 0x10)` is
'    TProfile.date (:TMyDate, offset 0x10), and vtable+0x54 on a TMyDate is GetYear()
'    (object_model.json: TMyDate methods list Year at offset 0x54) -- i.e.
'    `g_profile.date.GetYear()`, a small career-year counter (grep evidence elsewhere in
'    the corpus compares this to 1, 2, 20 -- never a calendar year), consistent with the
'    loop below only running a handful of times.
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
'  * The `newstar`/`Rand` guards in both squad walks are written with the negated
'    condition and an empty `Then`, body in `Else` (`If p.newstar <> 0` / `Else` / body
'    / `EndIf`, and `If Rand(6) > 1` / `Else` / body / `EndIf`), not `If p.newstar = 0`
'    / `If Rand(6) < 2` with the body directly in `Then`. An `If`/`Else` with an empty
'    arm still emits that arm's branch and its unconditional jump around the other arm
'    (codegen-patterns 10.2's rule that `Select`/`If` emit every branch instruction they
'    are given generalises here); a plain `If cond Then body EndIf` with no `Else` instead
'    collapses to one inverted conditional jump, one byte shorter per guard. `Rand(6) > 1`
'    (not `Rand(6) >= 2`) matches codegen-patterns 10.1's relational-spelling rule: the
'    original's `cmp eax,1 / jle` sets the immediate to 1, not 2.
'  * String concatenation and slicing calls are NOT CSE'd (bcc never does this): the same
'    `fn + " " + ln` is recomputed for both the LogLine and the field store, and fn/ln are
'    each sliced to their first character for `initials` without reusing prior temps --
'    reproduced as literal repeated expressions per codegen-patterns 10.6/"no CSE".
'!Global g_profile:TProfile
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
		Local nationid:Int = g_profile.myclub.nationid
		If Not a10
			Local n:TNation = TNation.SelectById(g_profile.myclub.nationid)
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
			If p.newstar <> 0
			Else
				LogLine(fn + " " + ln)
				p.name = fn + " " + ln
				p.initials = fn[..1] + ln[..1]
			EndIf
		Next
		Local yr:Int = g_profile.date.GetYear()
		While yr > 1
			yr = yr - 1
			For Local p:TPlayer = EachIn t.squad
				If p.newstar <> 0
				Else
					If Rand(6) > 1
					Else
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
