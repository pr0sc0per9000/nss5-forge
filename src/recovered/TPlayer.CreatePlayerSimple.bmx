' TPlayer.CreatePlayerSimple
' VA 0x004ED58D   2496 bytes   vtable slot 0x38   sig (i,i,i,i,i,i):TPlayer
' byte-identical vs NSS5.exe (2496/2496, original length from Ghidra's inventory, mode=full
' naming -- every E8 operand already resolves to the same symbol on both sides)
'
' Parameters (call-site evidence from TTeam.CreateSquadSimple / TEngine.DoYourSubstitutionOn
' and .../Off, both already in src/recovered/):
'   a0 = selno (-> Self.selectionno @0xbc)      a1 = teamid (-> Self.teamid @0x14)
'   a2 = rating (seeds the 7 Rand(10)+rating stat rolls, and v_goalkeeping = a2 verbatim)
'   a3 = newstar flag (-> Self.newstar @8; gates the g_profile-derived override block)
'   a4 = skin1, a5 = skin2 (Rand(5) roll: value 1 or 2 -> skin2, else skin1)
'
' Dependency: GetBootBonus(bootIdx, statCategory), a pure lookup, independently verified
' 592/592 at src/recovered_module/GetBootBonus.bmx.
'
' ============================== GHIDRA / CODEGEN TRAPS FOUND HERE ==============================
' 1. The 8 "raw stat" Float Locals sit at ebp-4/-8/-0xc/-0x10/-0x14/-0x18/-0x1c/-0x20, NOT at
'    the offsets Ghidra's own C variable names (local_8..local_24) imply -- Ghidra's naming is
'    off by one slot; ebp-0x24 is a throwaway int scratch for fild/fstp, never one of the eight.
'    Confirmed two ways: the "mypace:"/.../"mygoalkeeping:" LogLine block and the preceding 8
'    ClampFloat calls both touch the 8 slots in that exact order.
' 2. TProfile.boots[] loop is "first OWNED boot 1..10, else -1", not what a literal reading of
'    Ghidra's comma-operator `while` suggests.
' 3. GetBootBonus's own two arguments are one call ahead in Ghidra's merged argument list (the
'    standard "Ghidra merges a callee's args with the following call's pushes" CALL trap).
' 4. The "Player:"+id+" Sel:"+selno+" Name:"+name LogLine was traced by hand through the literal
'    push/pop sequence. Along the way, the contract-offer stat block's local_18/local_20 both
'    turn out to read TProfile.flair (+0xbc), confirmed twice in the disassembly (0x004EDAC4 and
'    0x004EDAFC both `mov eax,[eax+0xbc]`).
'    ORIGINAL BUG (VA 0x004EDAC4/0x004EDAFC): heading is seeded from TProfile.flair, not from
'    TProfile.heading@0xb4. Reproduced faithfully, not fixed.
' 5. THE HAPPINESS GUARD (a3<>0 And GetStat(...)>3.0). The original stores happiness=100 with a
'    SINGLE instruction reached from two different paths: the a3==0 test ("mov eax,a3; cmp
'    eax,0; je L") falls straight into the shared "cmp eax,0/je" that also serves the
'    GetStat>3.0 boolean, because eax is already 0 in that case -- no dedicated flag storage.
'    A literal `If a3<>0 And GetStat(...)>3.0` does NOT reproduce this: bcc materialises a raw
'    "<>0" test on a loaded parameter via setne+movzx when it is the first operand of a literal
'    And expression (+9 bytes, verified by direct trial). What DOES reproduce it is two
'    statements that let the SAME storage (here, the Local `happy`, initialised from a3 and
'    reassigned only inside the guarded block) serve as both a3's own truthiness and the
'    GetStat boolean -- see the source below. `g_training_int03 > 0 And a0 = 0` two statements
'    later, by contrast, DOES match as a literal And, because neither operand is a bare "<>0"
'    test on an already-loaded value (both need setg/sete to normalise to 0/1 regardless).
' 6. FPU-STACK-RESIDENT LOCALS (the pace/dribbling/tackling formulas). `baseline` and the
'    tackling ratio are never spilled to a memory slot -- they live purely on the x87 stack
'    across several statements (no intervening call disturbs it), consumed via fld st(n)/fxch
'    rather than reload-from-memory. Two consequences that cost real bytes if missed:
'      * Addition order matters even though it "shouldn't" mathematically: `p.pace = baseline *
'        v_pace + g_player_float03` and `g_player_float03 + baseline * v_pace` are NOT the same
'        bytes. The original evaluates the Global-load operand FIRST (push it), then multiplies
'        a *duplicate* of the resident `baseline` (fld st(1)) by v_pace, then faddp folds the
'        two -- leaving the original `baseline` still resident for the next statement. Getting
'        the operand order backwards forces a plain `fadd [mem]` instead of `fld+faddp`, which
'        is 2 bytes shorter per site (3 sites: pace, the g_training override, and dribbling).
'      * `baseline * 0.75` and the tackling ratio `(g_player_float07*0.25)/20.0` are each their
'        OWN prior statement (mutating `baseline` in place / a fresh `baseline2` Local), not an
'        inline sub-expression of the dribbling/tackling statement. Inlining them re-orders the
'        x87 instruction stream (fmul-by-constant moves to a different position, same length
'        overall for dribbling but wrong bytes; genuinely 2 bytes short for tackling, since the
'        divide-then-reload sequence collapses).
' 7. CONSTANT CORRECTED: `v_dribbling = ??? - v_dribbling` was written 75.0 (copied
'    from the neighbouring slide_delay formula's 75.0); the original loads 21.0 there (fld
'    [0x00C79548] at code offset +2283), the same value used for passing/heading/shooting three
'    lines later. The oracle masks the .rdata ADDRESS so both values matched equally. Found by
'    scripts/check_floats.py. Re-verified MATCH 2496/2496.

	Function CreatePlayerSimple:TPlayer(a0:Int, a1:Int, a2:Int, a3:Int, a4:Int, a5:Int)
		'!Global g_profile:TProfile
		'!Global g_players:TList
		'!Global g_training_int03:Int
		'!Global g_player_float03:Float
		'!Global g_player_float07:Float
		Local p:TPlayer = New TPlayer
		p.newstar = a3
		Local happy:Int = a3
		If happy <> 0 Then happy = g_profile.GetStat(12, 3, 0, 0) > 3.0
		If happy <> 0
			p.happiness = g_profile.GetHappiness()
		Else
			p.happiness = 100
		EndIf
		p.id = g_players.Count()
		LogLine("CreatePlayerSimple:" + p.id)
		p.teamid = a1
		p.selectionno = a0
		p.joy = TJoy.CreateJoy()
		p.replayframes = CreateList()
		Select Rand(5)
			Case 1
				p.skincol = a5
			Case 2
				p.skincol = a5
			Default
				p.skincol = a4
		End Select
		p.haircol = Rand(7)
		If p.haircol = 4 Or p.haircol = 5
			p.haircol = Rand(7)
		EndIf
		If p.skincol > 1 And p.haircol <> 1 And p.haircol <> 2
			p.haircol = Rand(2)
		EndIf
		If p.skincol = 5 And p.haircol <> 1
			p.haircol = 1
		EndIf
		LogLine(TKit.GetStringSkinCol(p.skincol))
		LogLine(TKit.GetStringHairCol(p.haircol))
		p.bootcolint = 1
		p.bootcol = TKit.GetBootColour(p.bootcolint)
		p.glovecolint = Rand(4)
		p.glovecol = TKit.GetGloveColour(p.glovecolint)
		If a3 <> 0
			p.name = g_profile.GetOriginalName()
			p.initials = g_profile.GetOriginalName()
			p.age = g_profile.GetAge()
			p.value = FormatMoney(g_profile.GetValue(), 1)
			p.skincol = g_profile.playercols.skin
			p.haircol = g_profile.playercols.hair
			p.bootcol = g_profile.playercols.boots
			p.bootcolint = TKit.GetBootColourInt(p.bootcol)
		EndIf
		Local v_pace:Float = a2 + Rand(10)
		Local v_dribbling:Float = a2 + Rand(10)
		Local v_tackling:Float = a2 + Rand(10)
		Local v_passing:Float = a2 + Rand(10)
		Local v_heading:Float = a2 + Rand(10)
		Local v_shooting:Float = a2 + Rand(10)
		Local v_flair:Float = a2 + Rand(10)
		Local v_goalkeeping:Float = a2
		If a3 <> 0
			Local idx:Int = -1
			For Local i:Int = 1 To 10
				If g_profile.boots[i - 1] > 0
					idx = i
					Exit
				EndIf
			Next
			v_pace = g_profile.pace
			v_dribbling = g_profile.dribbling + GetBootBonus(idx, 2) * 10
			v_tackling = g_profile.tackling + (g_profile.shinpads > 0) * 10
			v_passing = g_profile.passing + GetBootBonus(idx, 4) * 10
			v_heading = g_profile.flair
			v_shooting = g_profile.shooting + GetBootBonus(idx, 6) * 10
			v_flair = g_profile.flair
			If g_profile.NRG > 0 Then v_pace = v_pace + 10.0
			If g_profile.NRG > 50 Then v_pace = v_pace + 10.0
			If g_profile.booze > 0 Then v_flair = v_flair + 10.0
			If g_profile.booze > 50 Then v_flair = v_flair + 10.0
		EndIf
		v_pace = v_pace * 0.2
		v_dribbling = v_dribbling * 0.2
		v_tackling = v_tackling * 0.2
		v_passing = v_passing * 0.2
		v_heading = v_heading * 0.2
		v_shooting = v_shooting * 0.2
		v_flair = v_flair * 0.1
		v_goalkeeping = v_goalkeeping * 0.2
		ClampFloat(Varptr v_pace, 1.0, 20.0)
		ClampFloat(Varptr v_dribbling, 1.0, 20.0)
		ClampFloat(Varptr v_tackling, 1.0, 20.0)
		ClampFloat(Varptr v_passing, 1.0, 20.0)
		ClampFloat(Varptr v_heading, 1.0, 20.0)
		ClampFloat(Varptr v_shooting, 1.0, 20.0)
		ClampFloat(Varptr v_flair, 3.0, 10.0)
		ClampFloat(Varptr v_goalkeeping, 1.0, 10.0)
		LogLine("Player:" + p.id + " Sel:" + p.selectionno + " Name:" + p.name)
		LogLine("mypace:" + v_pace)
		LogLine("mydribbling:" + v_dribbling)
		LogLine("mytackling:" + v_tackling)
		LogLine("mypassing:" + v_passing)
		LogLine("myheading:" + v_heading)
		LogLine("myshooting:" + v_shooting)
		LogLine("myflair:" + v_flair)
		LogLine("mygoalkeeping:" + v_goalkeeping)
		p.slide_delay = Int(2250.0 - v_tackling * 75.0)
		Local baseline:Float = (g_player_float03 * 0.15) / 20.0
		p.pace = g_player_float03 + baseline * v_pace
		If g_training_int03 > 0 And a0 = 0
			p.pace = g_player_float03 + baseline * v_goalkeeping
		EndIf
		v_dribbling = 21.0 - v_dribbling
		baseline = baseline * 0.75
		p.dribbling = p.pace - baseline * v_dribbling
		Local baseline2:Float = (g_player_float07 * 0.25) / 20.0
		p.tackling = g_player_float07 * 0.75 + baseline2 * v_tackling
		p.passing = 21.0 - v_passing
		p.heading = 21.0 - v_heading
		p.shooting = 21.0 - v_shooting
		p.flair = v_flair
		If g_training_int03 > 0
			p.passing = 1.0
			p.heading = 1.0
			p.shooting = 1.0
		EndIf
		p.matchstats = TStats_Match.Create()
		Return p
	End Function
