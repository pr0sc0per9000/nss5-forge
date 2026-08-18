' TPlayer.UpdateTeamMateId_Human
' VA 0x004EF619   735 bytes   vtable slot 0x6C   sig ()i   KIND=Method
' ORACLE: mode=reloc  matched=735/735  STATUS=MATCH
' Original length from Ghidra's inventory. NSS5_NO_LEARN=1.
'
' WHAT IT DOES. For the human-controlled player, periodically (rate-limited by
' g_player_int50, a frame/tick counter Global, against lastchangedteammateid) picks the
' nearest sensible teammate to receive a pass, favouring one close to the joystick/facing
' direction. Then re-checks the chosen teammate's angle against the current heading and
' drops the choice if it has drifted too far (g_player_double01, a threshold in degrees).
'
' ASSUMPTIONS -- module Global NAMES are ours; DECLARED TYPES are load-bearing.
'   0x00C6EFD4 g_player_int50:Int      (globals_final.tsv: verified)
'   0x00C5DE10 g_Object79:TList        (globals_final.tsv types it plain Object, low
'                                       confidence -- but it is walked via slot 0x8C
'                                       (ObjectEnumerator)/0x30(HasNext)/0x34(NextObject),
'                                       i.e. a For..EachIn target, so TList per guide 3f/10.7)
'   0x00C79638 g_player_double01:Double (globals_final.tsv: usage, x87 qword access)
' Module Functions (already recovered, src/recovered_module/): AngleDiff (0x00506049,
'   sig (f,f,i)f), AngleTo (0x0050639d, sig (f,f,f,f)f), Dist2D (0x00505da2).
' Self/other-object fields resolved from object_model.json (TPlayer, TJoy, TStats_Match):
'   joy:TJoy (+344), joy.direction (+20), joy.force (+16), direction (+120),
'   directiontogoal_opp (+224), distancetogoal_opp (+232), teammateid (+240),
'   lastchangedteammateid (+244), teamid (+20), id (+16), x (+76), y (+80),
'   selectionno (+188), matchstats:TStats_Match (+392), matchstats.reds (+16).
' Static call: TPlayer.GetPlayerById(i):TPlayer, class-table+0x168 (vtable_map.tsv).
' `0x00C79630` float constant read out of the exe = 0.2 (joy.force threshold).
'
' NOTE  The rate-limit guard is ONE compound condition, not nested Ifs: original evaluates
'       `g_player_int50 < lastchangedteammateid+100` via setl/movzx, and on FALSE jumps
'       DIRECTLY INTO the second comparison's own `cmp eax,0/je` (reusing the stale
'       zero/false in eax) rather than past the whole guard -- the tell that distinguishes
'       a short-circuit `A And B` from two separately-nested `If A Then If B`, which would
'       instead jump past the entire block on A false. Verified by disassembly diff after
'       an initial nested-If draft passed length but the branch displacement disagreed
'       (a nested-If nets 0 bytes different too, so ONLY the jump target proves it).
' NOTE  `If p.matchstats.reds Or p.selectionno > 10 Then Continue` is a genuine early
'       Continue (unconditional jmp to the loop bottom after a short test), distinct from
'       the very next guard `If p.teamid=Self.teamid And p.id<>Self.id And
'       p.selectionno<11` which is a plain (no-Else) If wrapping the rest of the loop body
'       -- the first has an extra unconditional jmp the second does not.
' NOTE  The final angle-drift test evaluates AngleTo(...) as its OWN statement
'       (`Local ato:Float = AngleTo(...)`) even though `ato` never gets a memory slot (it
'       stays on the x87 stack, guide 6/10.5) -- writing the call inline as
'       `AngleDiff(dir, AngleTo(...), 1) > g_player_double01` evaluates g_player_double01
'       too early and costs bytes; the named statement matches the original's evaluation
'       order (the call executes before the literal `1` is pushed for AngleDiff).
' NOTE  The final `If better` assignment block writes `baseang`, THEN `bestdist`, THEN
'       `Self.teammateid` (re-reading p.id fresh from the object rather than a cached
'       register) -- this exact order is load-bearing for the byte count.

'!Global g_player_int50:Int
'!Global g_Object79:TList
' g_player_double01's original data-section value is 45.0 (0x00C79638), read
' directly from NSS5.exe. See codegen-patterns 21.1/21.3.
'!Global g_player_double01:Double = 45.0

If g_player_int50 < Self.lastchangedteammateid + 100 And Self.teammateid <> 0 Then Return 0
Self.lastchangedteammateid = g_player_int50
Local dir:Float = Self.joy.direction
If Self.joy.force < 0.2
	dir = Self.direction
EndIf
Local baseang:Int = Int(AngleDiff(dir, Float(Self.directiontogoal_opp), 1))
Local bestdist:Int = Self.distancetogoal_opp
Self.teammateid = 0
For Local p:TPlayer = EachIn g_Object79
	If p.matchstats.reds Or p.selectionno > 10 Then Continue
	If p.teamid = Self.teamid And p.id <> Self.id And p.selectionno < 11
		Local ang:Int = Int(AngleTo(Self.x, Self.y, p.x, p.y))
		Local dist:Int = Int(Dist2D(Self.x, Self.y, p.x, p.y))
		Local angdiff:Int = Int(AngleDiff(dir, Float(ang), 1))
		Local better:Int = angdiff < baseang - 25
		If Not better
			better = angdiff < baseang + 25
			If better
				better = dist < bestdist
			EndIf
		EndIf
		If better
			baseang = angdiff
			bestdist = dist
			Self.teammateid = p.id
		EndIf
	EndIf
Next
Local target:TPlayer = TPlayer.GetPlayerById(Self.teammateid)
If target <> Null
	Local ato:Float = AngleTo(Self.x, Self.y, target.x, target.y)
	If AngleDiff(dir, ato, 1) > g_player_double01
		Self.teammateid = 0
	EndIf
EndIf
Return 0
