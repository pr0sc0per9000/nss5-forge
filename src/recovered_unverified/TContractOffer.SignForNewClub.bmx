' TContractOffer.SignForNewClub
' VA 0x00572F47   1453 bytes   KIND=Method, SIG=()i, slot 0x6c
' byte-identical vs NSS5.exe
' Body-only format: statements only; Self is implicit (this is a Method, param_1 = Self).
' NOT YET byte-verified against NSS5.exe (recovered_pending -- assemble.py not run).
' Reconstructed from extracted/decomp/TContractOffer.SignForNewClub@00572f47.c PLUS
' a fresh capstone disassembly of the original bytes (scripts/bytematch.B.read_va + capstone),
' because Ghidra's decompile merges/attributes several call argument lists in ways that read
' misleadingly (see SHAPE NOTES below) -- the raw push/call/add-esp sequence resolves them
' unambiguously.
'
' ASSUMPTIONS
'   TContractOffer's own fields (established by TContractOffer.CreateContract.bmx / GetOffer.bmx,
'     object_model.json): +8 club:TClub, +0xC wage, +0x10 length, +0x14 goalbonus,
'     +0x18 assistbonus, +0x1C cleanbonus, +0x20 signingfee, +0x24 newbossrel.
'   0x00C6F028 g_profile:TProfile -- established by every other TContractOffer body in this
'     file (CheckPromoteFromBTeam.bmx, DoNegotiation.bmx, GetOffer.bmx, DoTransferRumour.bmx,
'     etc.); EraseInterestedClubs.bmx's header records g_profile as the name for this slot,
'     in place of the TContractOffer-local alias g_contractoffer_tplayer.
'     Fields used (object_model.json): contractwage +0x78, bossreport +0x54, physioreport +0x58,
'     coachreport +0x5C, webheadline +0x50, playbuttontype +0x130, relationboss +0x104,
'     relationteam +0x108, relationfans +0x10C, captain +0x120, myclub :TClub +0x1D0,
'     clubid +0x20, date :TMyDate +0x10, contractexpires +0x74, contractgoalbonus +0x7C,
'     contractassistbonus +0x80, contractcleanbonus +0x84, transferlisted +0x134,
'     lasttransferdate +0x1A8. Slots (vtable_map.tsv): GetStat(i,i,i,i)f=0x88,
'     CheckAchievement(i)i=0x150, GetValue()i=0xB8, SetPlayButtonIcon()i=0x70,
'     DoNews($,:TBase_Team,:TBase_Team,i,i)$=0x80, UpdateBank(i)i=0xFC.
'   0x00C6B424 g_signaturesound:TSound, 0x00C6B428 g_contractoffers:TList (both established in
'     TContractOffer.CreateContract.bmx / GetOffer.bmx). TList slot 0x34 = Clear()i
'     (vtable_map.tsv).
'   0x00C6F090 g_channel:TChannel -- the generic/shared sound channel Global at this address
'     (globals census: CERTAIN, unanimous where forced across TBlackJack.Update /
'     TScreen_BootShop.ButtonBuy / TScreen_Shop.ButtonBuy / TScreen_Interview.Success); used
'     here only as PlaySound's 2nd argument, not tied to any one screen.
'   TClub/TBase_Team: id:Int +0xC, labelname:String +0x1C (object_model.json, same fields
'     TContractOffer.GetOffer.bmx / CheckPromoteFromBTeam.bmx already use).
'   TMyDate (object_model.json / vtable_map.tsv): sdate:Int +8, Function Create(i,i,i):TMyDate
'     slot 0x30 (fixed class-table address 0x00C6632C), Method AddYears(i)i slot 0x44.
'   TScreen_GameMenu.UpdateTitlePanel()i (fixed address 0x00C66914) and .UpdateNavPanel()i
'     (fixed address 0x00C66918) -- both established in TProfile.UpdateBank.bmx /
'     TProfile.FixturePlayed.bmx, called unconditionally with zero args.
'   Module Functions / runtime helpers (matched against sibling bodies, not guessed fresh):
'     FUN_004C5549 = GetText($)$ -- ALWAYS exactly one argument (TProfile.UpdateBank.bmx,
'       TScreen_Clubs.ButtonDelete.bmx); every further operand Ghidra folds into a GetText(...)
'       call site belongs to the call that follows it.
'     FUN_004A75B0 = _bbStringReplace, i.e. String.Replace($,$)$ (TScreen_Clubs.ButtonDelete.bmx,
'       TContractOffer.CheckPromoteFromBTeam.bmx: identical "GetText(key).Replace(needle,val)"
'       shape, both calls consuming exactly the args their own signature needs).
'     FUN_0059F089 = Rand(i,i)i (TPitch.RandomPitchType.bmx).
'     FUN_004A7AC0 = _bbStringFromInt, FUN_004A7C20 = _bbStringConcat
'       (TScreen_ContinentalComps.ButtonEditPlaceComp.bmx: "literal" + intExpr idiom).
'     FUN_00505F6D = ClampInt(*i,i,i)i, argument order (Varptr, lo, hi)
'       (TCompetition.CreateCompetition.bmx, TBall.SetUpSetPieceBall.bmx).
'     FUN_005B9690 = Int(d):i, the Double-to-Int cast helper (matches TContractOffer.
'       CheckPromoteFromBTeam.bmx's identical `Int(g_profile.GetStat(...))` idiom).
'     FUN_0050720B = FormatMoney(i,i)$ (TProfile.DoNews.bmx: `a0.Replace("$value",
'       FormatMoney(v, 1))`, the exact same "$value"/FormatMoney(_,1) pairing used here).
'     FUN_0059B25E = PlaySound(:TSound,:TChannel) (TBlackJack.Deal.bmx / TBlackJack.Hit.bmx --
'       same two-Global calling shape).
'     [0x00C61CC0] = TScreen.DoMessage($,i,i)i, fixed class-table address (TContractOffer.
'       CheckPromoteFromBTeam.bmx / DoNegotiation.bmx).
'     &DAT_005C9C80 / the raw pointer value 0x5C9C80 = the compiled form of the literal `Null`
'       for a typed Object argument -- confirmed by dozens of sibling bodies' `<> Null` / `= Null`
'       tests compiling to `cmp eax,0x5c9c80` (TTeam.CreateSquadSimple.bmx's shape note; also
'       TSlotMachine.SetUp.bmx). NOT a real object -- passed here as DoNews's "no opposing club"
'       argument.
'   String literals (harness.read_string against the original exe):
'     0x00C8FC44 CMESSAGE_TRANSFERFIRSTCLUB, 0x00C81798 $clubname, 0x00C8FC84
'     CNEWS_FIRSTCONTRACT, 0x00C8FCB8 CMESSAGE_TRANSFERSAMECLUB, 0x00C8FCF8 CNEWS_RENEWCONTRACT,
'     0x00C8FD2C CNEWS_TRANSFER, 0x00C8FD54 CMESSAGE_TRANSFERNEWCLUB, 0x00C8E870 $value,
'     0x00C8FD90 CMESSAGE_TRANSFERNEWCLUBFREE.
'   Float literal 0x00C8FC40 = 2.0 (read as f32 from the exe).
'
' SHAPE NOTES (established from a fresh capstone disassembly of the original bytes, not just
' the Ghidra decompile -- this function's 4C5549/4A75B0 pairs are exactly the trap the project
' notes warn about)
'   * `msg` is ONE Local (register edi, callee-saved: pushed at entry, popped at the single
'     exit), assigned exactly once inside whichever branch of the If/ElseIf/Else runs, and
'     consumed exactly once by the shared tail's `TScreen.DoMessage(msg, 0, 0)` AFTER the
'     EndIf. Ghidra's decompile makes each branch's `GetText(...).Replace(...)` call LOOK like
'     a dead/unused result (no visible consumer inside that branch) -- it is not dead; the
'     consumer is the shared epilogue every branch jumps into. Confirmed directly: `add esp,0xc`
'     after every one of these `_bbStringReplace` calls (3 dwords: self, needle, replacement),
'     and `push edi` immediately before the final DoMessage call at the very end.
'   * Self.club is RELOADED from Self at every use (`mov eax,[ebx+8]` repeated at each call
'     site), never cached into a Local -- matches the no-CSE behaviour already documented in
'     TContractOffer.GetOffer.bmx / GetPlayerValueStatus.bmx.
'   * The `value >= 1000000 / 5000000 / 10000000 / 20000000` achievement-tier guards are written
'     with `>=` against the round number, matching `cmp imm,jl`; writing them as `> N-1` gives
'     the same runtime behaviour but the wrong immediate/jle bytes (same rule documented in
'     TProfile.UpdateBank.bmx for its cash thresholds).
'   * `Rand(10, 1)` is transcribed exactly as pushed (min=10, max=1, i.e. backwards) -- an
'     original-bug preserved as found, not "corrected" to `Rand(1, 10)`.
'   * The DoNews team1/team2 arguments differ per branch: first-contract passes
'     (Self.club, Null); same-club renewal passes (Self.club, Null); the genuine transfer
'     passes (g_profile.myclub, Self.club) -- i.e. (from-club, to-club) -- read BEFORE
'     g_profile.myclub is overwritten later in that same branch.
'   * `g_profile.contractwage = Self.wage` is written by the same-club and new-club branches
'     AND AGAIN, unconditionally, by the shared tail -- a genuine duplicate store in the
'     original for those two branches, kept exactly as found (not deduplicated).
'!Global g_profile:TProfile
'!Global g_signaturesound:TSound
'!Global g_channel:TChannel
'!Global g_contractoffers:TList
Local msg:String

Self.EraseInterestedClubs()
Local fans:Int = Int(g_profile.GetStat(12, 3, g_profile.clubid, 0) / 2.0)
ClampInt(Varptr fans, 20, 80)

If g_profile.contractwage = 0 Then
	g_profile.CheckAchievement(81)
	msg = GetText("CMESSAGE_TRANSFERFIRSTCLUB").Replace("$clubname", Self.club.labelname)
	g_profile.myclub = Self.club
	g_profile.clubid = Self.club.id
	g_profile.CreateNewClubStats(Self.club.id)
	g_profile.webheadline = g_profile.DoNews(GetText("CNEWS_FIRSTCONTRACT"), Self.club, Null, Self.length, 0)
ElseIf Self.club.id = g_profile.clubid Then
	msg = GetText("CMESSAGE_TRANSFERSAMECLUB").Replace("$clubname", Self.club.labelname)
	g_profile.contractwage = Self.wage
	g_profile.webheadline = g_profile.DoNews(GetText("CNEWS_RENEWCONTRACT"), Self.club, Null, Self.length, 0)
	g_profile.relationboss = Self.newbossrel
Else
	Local value:Int = g_profile.GetValue()
	g_profile.bossreport = ""
	g_profile.physioreport = ""
	g_profile.coachreport = ""
	g_profile.webheadline = ""
	g_profile.playbuttontype = 4
	g_profile.SetPlayButtonIcon()
	g_profile.contractwage = Self.wage
	g_profile.webheadline = g_profile.DoNews(GetText("CNEWS_TRANSFER" + Rand(10, 1)), g_profile.myclub, Self.club, Self.length, 0)
	g_profile.myclub = Self.club
	g_profile.clubid = Self.club.id
	g_profile.CreateNewClubStats(Self.club.id)
	g_profile.relationboss = Self.newbossrel
	g_profile.relationteam = 50
	g_profile.relationfans = fans
	g_profile.captain = 0
	If g_profile.date.sdate < g_profile.contractexpires Then
		msg = GetText("CMESSAGE_TRANSFERNEWCLUB").Replace("$clubname", Self.club.labelname)
		msg = msg.Replace("$value", FormatMoney(value, 1))
		g_profile.CheckAchievement(40)
		If value >= 1000000 Then g_profile.CheckAchievement(41)
		If value >= 5000000 Then g_profile.CheckAchievement(42)
		If value >= 10000000 Then g_profile.CheckAchievement(43)
		If value >= 20000000 Then g_profile.CheckAchievement(44)
	Else
		msg = GetText("CMESSAGE_TRANSFERNEWCLUBFREE").Replace("$clubname", Self.club.labelname)
	EndIf
EndIf

Local d:TMyDate = TMyDate.Create(g_profile.date.sdate, 1, 1)
d.AddYears(Self.length)
g_profile.contractexpires = d.sdate
g_profile.contractwage = Self.wage
g_profile.contractgoalbonus = Self.goalbonus
g_profile.contractassistbonus = Self.assistbonus
g_profile.contractcleanbonus = Self.cleanbonus
g_profile.UpdateBank(Self.signingfee)
g_profile.transferlisted = 0
g_profile.lasttransferdate = g_profile.date.sdate
TScreen_GameMenu.UpdateTitlePanel()
TScreen_GameMenu.UpdateNavPanel()
PlaySound(g_signaturesound, g_channel)
TScreen.DoMessage(msg, 0, 0)
g_contractoffers.Clear()
Return 0
