' TScreen_SeasonReview.SetUpScreen -- NOT VERIFIED candidate.
' VA 0x0055F8E6   Ghidra-authoritative length 2276 bytes   slot 0x34   KIND=Function   SIG=()i
'
' CURRENT STATE: ours is 2273 of 2276 bytes -- delta -3, mode=len (does not yet MATCH).
' `scripts/localise_diff.py` reports the delta as COMPLETELY accounted for by 3 tiny
' length-changing gaps (-1 byte each) plus 6 same-length SUBs, and states the whole
' divergence traces to ONE root cause (see below). Verify with:
'   NSS5_WORKER=x NSS5_NO_LEARN=1 python -c "
'   import sys; sys.path.insert(0,'scripts'); import localise_diff as L
'   body = open('src/recovered_unverified/TScreen_SeasonReview.SetUpScreen.bmx',
'                encoding='utf-8').read()
'   # strip this header block down to the '!Global lines + body before calling localise_body
'   "
' (or just feed the body-only text below to `harness.try_method('TScreen_SeasonReview',
' 'SetUpScreen', body)` -- first_diff 23, matched 704/2276 raw, reloc_masked 34, `our_len`
' 2273 vs `orig_len` 2276.)
'
' THE WHOLE FUNCTION'S SEMANTICS ARE SOLVED AND STABLE. Every field offset, class-table
' slot, string literal and float constant below was independently resolved (object_model.json
' + class_tables.tsv + harness.read_string()/raw-float dump) and NONE of it is in question --
' every gap/sub the oracle reports from ORIGINAL +660 onward is a pure REGISTER-IDENTITY
' difference (same instruction shape, same length almost everywhere, wrong physical register
' or a value not promoted to a register at all), never a wrong call, wrong field, wrong
' literal or wrong branch.
'
' ROOT CAUSE (traced, not fixed): `Local goals:Int = Int(g_profile.GetStat(12, 3,
' g_profile.clubid, year))` colours to ESI in our build; the original's `mov ??,eax` at
' ORIGINAL +660 (VA 0x0055FB7A) is `89 C7` = EDI, ours is `89 C6` = ESI (SUB 1/6). This is
' bcc's Chaitin/Briggs allocator (`tools/blitzmax-legacy-src/_src/codegen/cgallocregs.cpp`,
' guide section 18) picking a different member of the {ebx,esi,edi} colour set -- the guide
' explicitly states physical identity within that set was "deliberately not predicted" even
' in its own controlled probe (section 18.2), and that is exactly the wall hit here.
' Everything downstream is a MECHANICAL CONSEQUENCE of this one choice: with `goals` holding
' ESI across the whole "If flag<>0" block (both the young-player and league-player checks,
' ORIGINAL +728 and +970, SUB 2/6 and SUB 4/6 -- `cmp edi,0xf` vs `cmp esi,0xf`), ESI is
' UNAVAILABLE when the young/league/world "text2/3/4" concat temporaries need a register, so
' bcc leaves each of them sitting in EAX instead of moving them out (GAP 1-3/3, all "replace
' -1 bytes", ORIGINAL +807/+1049/+1721: original does `mov esi,eax` [dedicating ESI to the
' concat result, freeing EAX] then reloads `comp` into EAX for the next call's argument setup
' [SUB 3/6, 5/6, 6/6: `mov eax,[ebp-0x18]` + `push esi`]; ours never frees EAX, so `comp`
' gets reloaded into EDX instead and the concat result is pushed straight from EAX). Get
' `goals` onto EDI and (per this trace) all 3 gaps and the remaining SUBs should resolve
' together, because the ONLY thing keeping ESI busy in our build is `goals`.
'
' RULED OUT THIS PASS:
'  (1) Swapping the declaration order of `statval`/`goals` -- WRONG, this also reverses
'      which GetStat() call bcc emits first, which the original's byte order forbids
'      (statval's GetStat(18,...) call is unambiguously first at ORIGINAL +577..+624,
'      goals' Int(GetStat(12,...)) second at +625..+660; swapping produced a much WORSE
'      36-byte gap starting at +596, confirming the call order is load-bearing and is not
'      the lever).
'  (2) Merging the three concat temporaries (`text2`/`text3`/`text4`) into a single reused
'      Local -- NEUTRAL, byte-identical to the 3 separately-named Locals in every respect
'      (same 3 gaps, same delta). Rules out "extra Local node count" as the lever; the
'      allocator treats the 3 non-overlapping short-lived uses the same either way.
'  (3) Read `cgallocregs.cpp` directly (iterated-coalescing graph colouring, `_simplify`/
'      `_spill`/`_freeze`/`_coalesce` worklists, `selectRegs()` at line 479) to look for a
'      hand-derivable ordering rule beyond "lowest free colour among what's not already
'      claimed by an interfering node" -- the actual SIMPLIFY/SELECT stack order depends on
'      the full interference graph and move-coalescing decisions built from IR emission
'      order; not hand-simulatable in the time available. NOT a slot-depth question (section
'      22 -- this function's frame is `sub esp,0x20` on BOTH sides, confirmed identical), so
'      section 22's slot-depth-is-spill-order rule does not directly apply; this is the
'      companion "which physical colour" question section 18.2 flags as unpredicted.
'
' NEXT LEVER TO TRY (untried this pass): section 18.4's remedy for exactly this symptom --
' `scripts/w14S0_live.py`-style per-storage touch census on a probe modelling just the
' `goals`/`best`/text2-4 liveness shape, to find whichever OTHER value is occupying ESI (or
' failing to occupy it) at ORIGINAL +660 in a way this trace has not yet located. Do not
' re-try reordering the Local declarations blindly -- ruled out above, and section 18.2's own
' probe shows declaration order is only a tie-break when reference counts are already tied
' (`goals`=3 references, `best`=5), which is not the situation here.
'
' ADDENDUM (re-verified unchanged: still 2273/2276, delta -3, gaps/subs
' identical byte-for-byte to the trace above -- re-ran `localise_diff.py` fresh,
' same 3 GAPs at +807/+1049/+1721 and same 6 SUBs at +660/+728/+822/+970/+1064/+1736).
' Read `cgallocregs.cpp` end-to-end (not just `spill()`/`allocLocal()` as prior passes did):
' `selectRegs()` pops `_selected` from the TAIL (`node=_selected->pred`) and `Node::insert()`
' APPENDS to the list it is given (inserts just before the sentinel, i.e. at the old tail) --
' so `_selected` is a genuine LIFO stack: nodes get COLORED in the exact REVERSE order they
' were pushed during `simplify()`/`spill()`. A node''s color is `avail &= ~(1<<t->color)` over
' only its EDGES that are ALREADY colored, lowest surviving bit wins -- so which of
' {ebx=3,esi=4,edi=5} a node gets depends on (a) its push order relative to every OTHER node
' it interferes with and (b) which of those neighbours are colored FIRST because they were
' pushed LATER. This is not a per-Local property; it is a global fact about the whole
' interference graph''s simplify/coalesce/freeze/spill worklist order, which itself depends
' on `createGraph()`''s per-block, per-instruction walk over ALL of `flow->assem`. Confirms
' (not just repeats) the earlier conclusion: there is no partial/local computation of this that
' a human can carry out for a body this size; a full run of the algorithm is required, and
' the only way to run it is `bmk`/`bcc` itself -- which means the lever has to be a SOURCE
' change whose EFFECT can be tested empirically, not a hand-derivation of the answer.
'
' Also did the touch census the "next lever" above asked for -- at the SOURCE POINT where
' `goals` is defined (right after ORIGINAL +660, immediately before `If flag<>0`), the
' Int/object-bank Locals whose value is still needed LATER (live-out of this point) are:
' `year` (read in ~13 later GetStat/CheckAchievement-adjacent calls), `comp` (read at least
' 6 more times through +~1750, including inside the EachIn loop), `pos` (read at +172-equiv
' and again in the Else arm), `msg` (String, first read at the very end, offset +227-equiv),
' `nation` (read twice, both inside the immediately-following block), and `flag` itself
' (read ONE more time, the very next statement, then dead). That is SIX candidates plus
' `goals` = seven competing for 3 non-eax/edx/ecx colours (a call precedes this point, so
' colours 0-2 are unavailable per `selectRegs`), meaning at least four of the seven are
' ALREADY on the stack by construction -- `goals` landing on the stack instead of a register
' would not even be surprising; the actual defect is narrower than "wrong register", it is
' "wrong MEMBER of the winning trio", which per section 18.2 is the one axis the project''s
' own controlled probe called unpredictable by design. Not attempted: building a 7-Local
' synthetic probe that reproduces this exact liveness shape and iterating source order on
' IT (cheap, ~1.5s/build) rather than on the 2276-byte body directly -- that is the
' concrete, bounded next step, not another hand-derivation.
'
' RE-REVIEW (this pass, no build access): the live status/score/TScreen_SeasonReview.
' SetUpScreen.txt report now shows the RAW first difference at byte 10 -- inside the
' very FIRST global load (`mov eax,[g_seasonreview_screen]`), not ORIGINAL +660 as the
' notes above describe. Read scripts/bytematch.py end to end to check why: it is a
' straight, unmasked byte compare (no relocation normalisation at all), unlike the
' reloc-aware check that certified this Type's byte-perfect siblings (see e.g.
' TScreen_SeasonReview.CreateScreen.bmx's own header: "mode=reloc, reloc_masked=96").
' Confirmed via `python scripts/explain_global.py`: this function's OWN two operand
' addresses in the "ours" hex (0x00C9D210 for the global load, 0x00CBA10C for the
' "SetUpScreen:" literal) resolve to NOTHING in the global catalogue, while
' `g_seasonreview_screen` is CERTAIN at 0x00C687C4 and is exactly what this body already
' references (line 1 below) -- the SAME slot the byte-perfect CreateScreen.bmx uses. That
' points at current whole-program address-layout drift in the shared assembled build
' (outside a single file's control), not a defect in this body's global reference. Did a
' fresh full statement-by-statement re-walk of the decompile against the body below anyway
' (LogLine's FUN_004a7c20+FUN_00505b91 merge shape, both THistory.Create call sites' 6-arg
' order, both DoNews call sites' 5-arg order, the GetText+" "+labelname concat's 2-call
' merge shape, the 5-clause promotion-place And-chain, the young/league/world nested
' If-ElseIf-ElseIf shape, every GetStat(statid,period,clubid,year) call's argument order) --
' found no new semantic defect; everything still matches the decompilation and the
' ASSUMPTIONS catalogue below. Per law 4: made NO changes this pass. This confirms, rather
' than repeats, the earlier conclusion that the outstanding gap is the documented
' register-colour-selection question, answerable only by an actual bmk/bcc run this task
' has no access to -- not a hand-fixable statement-level bug.
'
' ASSUMPTIONS (all independently verified, none in question):
'  Globals: g_seasonreview_screen:TScreen 0x00C687C4 (TScreen.name +8, established name from
'    TScreen_SeasonReview.CreateScreen.bmx); g_profile:TProfile 0x00C6F028 (TProfile fields:
'    +0x10 date:TMyDate, +0x20 clubid, +0x1C0 history:TList, +0x1D0 myclub:TClub -- offsets
'    from object_model.json, address+usage established in TScreen_Formation.SetUpScreen.bmx);
'    g_screen_leagues_comp:TCompetition 0x00C66F5C, g_screen_leagues_table:TTable 0x00C66F20
'    (both established names/addresses from TScreen_Leagues.SetUpLeagueTable.bmx, confirming
'    the Season Review screen reuses the League screen's league-table gadget pair, same
'    pattern as CreateScreen.bmx's g_shared_panel1).
'  Class-table slots (all resolved via class_tables.tsv base + offset arithmetic, verified
'    against vtable_map.tsv): TMyDate+0x54 GetYear; TScreen_Leagues+0x34 SetUpScreen(i)i;
'    TCompetition+0xF0 PaintPromotedClubs(:TTable)i, +0x4C SelectById(i):TCompetition;
'    TNation+0x58 SelectById(i):TNation; TTeamPool+0x54 GetStringTeamPosition(i)$, +0x50
'    GetTeamPosition(i)i; THistory+0x38 Create(i,i,i,$,i,i):THistory (fields year+8,clubid+0xc,
'    nationid+0x10,text+0x14,compid+0x18,winner+0x1c); TList+0x44 AddLast, +0x8C
'    ObjectEnumerator, +0x30 HasNext, +0x34 NextObject (codegen-patterns.md section 5's
'    EachIn shape, twice -- once over TCompetition.lpromotionplaces:TList of TPromotionPlace
'    [class table 0x00C64754, fields parentid+8/place+0xc/promotiontoid+0x10], once over
'    g_profile.history:TList of THistory); TProfile+0xA0 GetAge, +0x88 GetStat(i,i,i,i)f,
'    +0x150 CheckAchievement(i)i, +0x80 DoNews($,:TBase_Team,:TBase_Team,i,i)$; TScreen+0x5C
'    SetActive($,$):TScreen, TScreen_SeasonReview+0x38 UpdateSeasonStats, +0x3C
'    UpdateSeasonTournaments (both own-Type, unprefixed); TScreen_WebPage+0x34
'    SetUpScreen($,$)i (class table 0x00C689B8, confirmed by offset arithmetic, NOT the more
'    "obvious" TProfile guess -- 0x00C689EC is +0x34 past TScreen_WebPage's base, not inside
'    TProfile's).
'  Fields: TCompetition based+0x20, comptype+0x24, teampool+0x6C ([]:TTeamPool), labelname
'    +0x14, id+8, lpromotionplaces+0x64; TBase_Team labelname+0x1c (TNation inherits it);
'    TTeamPool.list+8 unused here (only the array-index-0 element is read directly via
'    BBArray +0x18); TCompetition level+0x1c, locale+0x18 (read on the SelectById() result
'    inside the history loop with NO Null guard -- confirmed absent in the original bytes,
'    reproduced faithfully as a probable ORIGINAL BUG rather than "fixed" with an added
'    Null check, per law 3).
'  Strings (harness.read_string, all confirmed): 0xC8CE70 "SetUpScreen:", 0xC8CE98 "Young
'    Player Of The Year", 0xC8CF08 "League Player Of The Year", 0xC8CF88 "World Player Of The
'    Year", 0xC8CED4 "CNEWS_YOUNGPLAYER", 0xC8CF48 "CNEWS_LEAGUEPLAYER", 0xC8CFC4
'    "CNEWS_WORLDPLAYER", 0xC8CCE8 "seasonreview", 0xC6EF28 " " (single space, a real string
'    literal, not a Global), 0xC5D284 pooled "" (refcount 0x7FFFFFFF), 0x5C7D40 a SECOND,
'    per-compilation-unit pooled "" (refcount 0x40000000, same String class table) -- this
'    file's own empty-string literal, used for `Local msg:String = ""`.
'  Floats (raw bytes at each fld address, confirmed, not guessed): 0xC8CE94/0xC8CF04 8.0,
'    0xC8CF78 8.5, 0xC8CF7C/0xC8CF80/0xC8CF84 7.0, 0xC8CFF4/0xC8D000/0xC8D004 20.0, 0xC8CFF8
'    150.0, 0xC8CFFC 300.0.
'  Achievement ids (all raw literals, no Const table entry found, reproduced as plain
'    integers per house style elsewhere in the corpus): 99, 100 (year=10/20 milestones), 26
'    (young player), 77/27 (league player: unconditional pos=1 one, then guarded one), 28
'    (world player, same id used by all 3 ElseIf branches), 78 (pos=1 else-branch), 94-98
'    (5 independent end-of-function GetStat thresholds).
'  GetStat(statid, period, clubid_or_0, year) argument mapping read directly off push order:
'    (18,3,clubid,year)=statval, (12,3,clubid,year)=goals [Int() truncation via the confirmed
'    0x5B9690 Double->Int helper], (18,4,0,year) x2 + (18,2,0,year) in the world-player
'    history loop, (5,3,0,year)/(17,3,0,year)/(3,3,0,year)/(4,3,0,year)/(15,3,0,year) for the
'    5 trailing checks. Semantics of the statid/period codes are NOT recovered (no Const
'    table hit); UNCERTAIN what game concept each id maps to, but the call arguments
'    themselves are byte-verified.
'
' Body-only format: statements only (this Function takes no parameters, KIND=Function).
'!Global g_seasonreview_screen:TScreen
'!Global g_profile:TProfile
'!Global g_screen_leagues_comp:TCompetition
'!Global g_screen_leagues_table:TTable
LogLine("SetUpScreen:" + g_seasonreview_screen.name)
Local msg:String = ""
Local year:Int = g_profile.date.GetYear() - 1
If year = 10
	g_profile.CheckAchievement(99)
End If
If year = 20
	g_profile.CheckAchievement(100)
End If
TScreen_Leagues.SetUpScreen(0)
g_screen_leagues_comp.PaintPromotedClubs(g_screen_leagues_table)
Local comp:TCompetition = g_screen_leagues_comp
Local nation:TNation = TNation.SelectById(comp.based)
Local postxt:String = comp.teampool[0].GetStringTeamPosition(g_profile.clubid)
Local text:String = postxt + " " + comp.labelname
Local pos:Int = comp.teampool[0].GetTeamPosition(g_profile.clubid)
If pos = 1
	g_profile.history.AddLast(THistory.Create(year, g_profile.clubid, 0, text, comp.id, 1))
Else
	g_profile.history.AddLast(THistory.Create(year, g_profile.clubid, 0, text, comp.id, 0))
End If
Local flag:Int = 1
For Local pp:TPromotionPlace = EachIn comp.lpromotionplaces
	Local otherComp:TCompetition = TCompetition.SelectById(pp.promotiontoid)
	If pp.place = 1 And otherComp <> Null And otherComp.comptype = 0 And otherComp.locale = 0 And otherComp.based = comp.based
		flag = 0
		Exit
	End If
Next
Local statval:Float = g_profile.GetStat(18, 3, g_profile.clubid, year)
Local goals:Int = Int(g_profile.GetStat(12, 3, g_profile.clubid, year))
If flag <> 0
	If g_profile.GetAge() < 22 And statval > 8.0 And goals > 15
		g_profile.CheckAchievement(26)
		Local text2:String = nation.labelname + " " + GetText("Young Player Of The Year")
		g_profile.history.AddLast(THistory.Create(year, g_profile.clubid, 0, text2, comp.id, 0))
		msg = g_profile.DoNews(GetText("CNEWS_YOUNGPLAYER"), g_profile.myclub, Null, 0, 0)
	End If
	If pos = 1
		g_profile.CheckAchievement(77)
		If statval > 8.0 And goals > 15
			g_profile.CheckAchievement(27)
			Local text3:String = nation.labelname + " " + GetText("League Player Of The Year")
			g_profile.history.AddLast(THistory.Create(year, g_profile.clubid, 0, text3, comp.id, 0))
			msg = g_profile.DoNews(GetText("CNEWS_LEAGUEPLAYER"), g_profile.myclub, Null, 0, 0)
		End If
	End If
	If statval > 8.5
		Local best:Int = 0
		For Local h:THistory = EachIn g_profile.history
			If h.year = year And h.winner = 1
				Local otherComp2:TCompetition = TCompetition.SelectById(h.compid)
				If otherComp2.level = 1 And otherComp2.locale = 2 And g_profile.GetStat(18, 4, 0, year) > 7.0
					g_profile.CheckAchievement(28)
					best = 1
				ElseIf otherComp2.level = 1 And otherComp2.locale = 1 And pos = 1 And g_profile.GetStat(18, 4, 0, year) > 7.0
					g_profile.CheckAchievement(28)
					best = 1
				ElseIf otherComp2.level = 0 And otherComp2.locale = 1 And pos = 1 And g_profile.GetStat(18, 2, 0, year) > 7.0
					g_profile.CheckAchievement(28)
					best = 1
				End If
			End If
		Next
		If best <> 0
			Local text4:String = GetText("World Player Of The Year")
			g_profile.history.AddLast(THistory.Create(year, g_profile.clubid, 0, text4, comp.id, 0))
			msg = g_profile.DoNews(GetText("CNEWS_WORLDPLAYER"), g_profile.myclub, Null, 0, 0)
		End If
	End If
Else
	If pos = 1
		g_profile.CheckAchievement(78)
	End If
End If
If g_profile.GetStat(5, 3, 0, year) > 20.0
	g_profile.CheckAchievement(94)
End If
If g_profile.GetStat(17, 3, 0, year) > 150.0
	g_profile.CheckAchievement(95)
End If
If g_profile.GetStat(3, 3, 0, year) > 300.0
	g_profile.CheckAchievement(96)
End If
If g_profile.GetStat(4, 3, 0, year) > 20.0
	g_profile.CheckAchievement(97)
End If
If g_profile.GetStat(15, 3, 0, year) > 20.0
	g_profile.CheckAchievement(98)
End If
TScreen.SetActive("seasonreview", "")
UpdateSeasonStats()
UpdateSeasonTournaments()
If msg.Length <> 0
	TScreen_WebPage.SetUpScreen(g_seasonreview_screen.name, msg)
End If
Return 0
