' TScreen_SeasonReview.SetUpScreen -- VERIFIED byte-identical vs NSS5.exe.
' VA 0x0055F8E6   2276 bytes   slot 0x34   KIND=Function   SIG=()i   (length Ghidra-authoritative)
'
' STATE: MATCH, mode=reloc, 2276/2276, reloc_masked=114, first_diff=None.
' Verified with `harness.try_method` under NSS5_NO_LEARN=1 (NSS5_WORKER=225), four
' independent process launches, all four MATCH -- checked because the only order-sensitive
' step in the allocation below is a two-node pop order, and walloc_report.py's header warns
' bcc is not deterministic across processes for near-ties. It is stable here.
' `scripts/localise_diff.py` agrees: "CLEAN -- byte-identical modulo the oracle's masks".
'
' WHAT CLOSED IT: ONE Local for all FOUR string temporaries, not four Locals.
' The four THistory.Create call sites each build a String and pass it. Writing them as four
' separate Locals (text/text2/text3/text4) left the last three in EAX and cost -3 bytes;
' writing them as ONE reused Local `text` puts all four in ESI and matches exactly.
'
' WHY, read out of the instrumented allocator (scripts/workflow/walloc_report.py, plus a
' one-off WALLOC_EDGES patch to a private worker tree printing each node's already-coloured
' neighbours at selectRegs time). This is measurement, not inference:
'
'   cgallocregs.cpp selectRegs() gives a node the LOWEST colour not held by an
'   already-coloured neighbour. The physical eax/edx/ecx nodes (regids 0/1/2) are
'   PRECOLOURED -- degree 0x7fffffff, colour fixed from graph construction -- so an edge to
'   them blocks colours 0/1/2 regardless of pop order. createGraph() creates that edge for
'   any value live across a call, because a call's def set is {eax,edx,ecx}.
'
'   FOUR-LOCAL FORM (the -3 byte version), measured:
'     text   regid=25 usage=3 degree=18/16 block_count=1  blockers 0:0 1:1 2:2 29:3 -> esi
'     text2  regid=50 usage=2 degree=8/5   block_count=1  blockers 45:4 51:3        -> EAX
'     text3  regid=56 usage=2 degree=6/4   block_count=1                            -> EAX
'     text4  regid=82 usage=2 degree=5/4   block_count=1                            -> EAX
'     goals  regid=45 usage=3 degree=38/36 block_count=9  blockers 0:0 1:1 2:2 52:3 -> esi
'   `text` is live across the GetTeamPosition() call between its definition and its use in
'   the If pos=1 / Else arms, so it carries edges to 0/1/2 and is forced up to esi.
'   text2/3/4 are each defined and consumed with NO call in between, carry no such edge,
'   and so take colour 0 = EAX -- which is CORRECT code for that source, just not the
'   original's. Cost: the original then loads g_profile with the 5-byte `A1` eax short form
'   where ours needs the 6-byte `8B 15` edx form, -1 byte at each of the three sites.
'
'   ONE-LOCAL FORM (this file), measured:
'     text   regid=25 usage=9 degree=25/26 block_count=1  blockers 0:0 1:1 2:2 50:3 -> esi
'     goals  regid=45 usage=3 degree=38/36 block_count=9  blockers 0:0 1:1 2:2 25:4 50:3 -> EDI
'   One source Local is one CGReg is one graph node, so the node's edge set is the UNION
'   over all four live ranges. The call edges the first range carries are thereby imported
'   into the other three, and the single node colours to esi everywhere. `goals` interferes
'   with it over +807..+828, now also sees colour 4 taken, and moves to edi -- which is the
'   original's `89 C7` at +660. usage/degree/block_count for `goals` are IDENTICAL in both
'   forms (3 / 38 / 9); nothing about goals was changed, its colour moved purely because a
'   neighbour's did. Pop order in pass 2 is regid 25 then 45; had it been the other way the
'   two would have swapped and the result would be length-exact with 6 subs remaining.
'
' CORRECTS THE PREVIOUS HEADER'S ROOT CAUSE, which read: "the ONLY thing keeping ESI busy
' in our build is goals; get goals onto EDI and all 3 gaps and the remaining SUBs should
' resolve together." That is false and the trace shows why: text2's blocker set in the
' four-Local form is {45:4, 51:3}, so recolouring goals to 5 leaves avail = 0b010111 and
' text2 STILL picks colour 0 = eax. goals was the consequence, not the cause. The causal
' direction is the reverse of what was recorded.
'
' ALSO CORRECTS: "Merging the three concat temporaries (text2/text3/text4) into a single
' reused Local -- NEUTRAL, byte-identical." That measurement was right and its conclusion
' was too narrow. Merging those THREE changes nothing because none of the three live ranges
' crosses a call, so their union still carries no edge to 0/1/2. `text` -- the one left out
' of that merge -- is the only one of the four that does. The merge has to include it.
'
' PREVIOUSLY RULED OUT, still true, do not retry:
'  (1) Swapping the declaration order of `statval`/`goals` -- reverses which GetStat() call
'      bcc emits first, which the original's byte order forbids (36-byte gap at +596).
'  (2) Reordering Local declarations generally -- section 18.2's declaration-order rule is
'      a tie-break on reference count, and this body was never on a tie.
'  (3) All six allocator knobs in docs/reference/allocator-knob-sweep.md.
'
' GENERAL LESSON for the remaining allocator-blocked bodies: "which of ebx/esi/edi" is
' byte-neutral (section 18.1) but "caller-saved vs callee-saved" is NOT: eax has a
' 1-byte-shorter absolute-load encoding, so a value landing in EAX instead of ESI is byte-visible.
' The source lever for that specific question is not declaration order and not reference
' count: it is whether the value's live range crosses a call, and MERGING two Locals into
' one is a way to give a call-free live range the call edges of a call-crossing one.
'
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
		text = nation.labelname + " " + GetText("Young Player Of The Year")
		g_profile.history.AddLast(THistory.Create(year, g_profile.clubid, 0, text, comp.id, 0))
		msg = g_profile.DoNews(GetText("CNEWS_YOUNGPLAYER"), g_profile.myclub, Null, 0, 0)
	End If
	If pos = 1
		g_profile.CheckAchievement(77)
		If statval > 8.0 And goals > 15
			g_profile.CheckAchievement(27)
			text = nation.labelname + " " + GetText("League Player Of The Year")
			g_profile.history.AddLast(THistory.Create(year, g_profile.clubid, 0, text, comp.id, 0))
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
			text = GetText("World Player Of The Year")
			g_profile.history.AddLast(THistory.Create(year, g_profile.clubid, 0, text, comp.id, 0))
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
