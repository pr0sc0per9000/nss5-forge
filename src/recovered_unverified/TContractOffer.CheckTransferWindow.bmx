' TContractOffer.CheckTransferWindow
' VA 0x00571E91   1647 bytes   KIND=Function, SIG=()i, slot 0x54
' Body-only format: statements only.
'
' ASSUMPTIONS
'   0x00C6F028 g_profile:TProfile (globals_final; established by every other TContractOffer
'     body in this file -- see TContractOffer.CheckPromoteFromBTeam.bmx / GetOffer.bmx).
'     Fields used: date :TMyDate at +0x10, clubid at +0x20, contractexpires at +0x74,
'     relationboss at +0x104, transferlisted at +0x134, lasttransferdate at +0x1A8,
'     myclub :TClub at +0x1D0 (all object_model.json).
'   0x00C6B428 g_contractoffers:TList (established by CreateContract.bmx / GetOffer.bmx /
'     New.bmx in this file). TList slot 0x34 = Clear, 0x74 = Remove, 0x8C = ObjectEnumerator,
'     0x30/0x34 (TListEnum) = HasNext/NextObject (vtable_map.tsv).
'   TMyDate slot 0x4C = GetDay, 0x50 = GetWeek (TContractOffer.TransferWindowOpen.bmx);
'     .sdate:Int is at +8 (object_model.json, same field TContractOffer.GetOffer.bmx uses).
'   TProfile slot 0x88 = GetStat(i,i,i,i)f, 0xA4 = GetSkillRating()i, 0x144 = CancelLoan()i
'     (vtable_map.tsv / object_model.json member list).
'   TClub/TBase_Team: labelname:String at +0x1C, id:Int at +0xC (inherited), exactly as used
'     in TContractOffer.GetOffer.bmx and TContractOffer.CheckPromoteFromBTeam.bmx.
'   TContractOffer's own class table is at 0x00C6B7B8 (class_tables.tsv). The four no-arg
'   PTR_FUN_ calls in the decompilation resolve against THIS type's own class table (base +
'   slot) and are written unqualified, exactly the "this Type's own table, so written
'   unqualified as a sibling Function" convention documented in
'   TContractOffer.GetClubsInterestedInLoan.bmx:
'     0x00C6B808 = base+0x50 -> TransferWindowOpen()i
'     0x00C6B814 = base+0x5C -> UpdateInterestedClubs()i
'     0x00C6B828 = base+0x70 -> CheckPromoteFromBTeam()i
'     0x00C6B82C = base+0x74 -> DoTransferRumour()i
'   0x00505B91 = LogLine (module Function, entry trace argument, per every other
'     TContractOffer body). 0x004C5549 = module Function GetText -- takes exactly ONE
'     argument; every extra operand Ghidra folds into a GetText(...) call site belongs to
'     the FOLLOWING call (codegen-patterns 3a; TProfile.StartCareer.bmx / GetOffer.bmx-style
'     bodies document this the same way). 0x004A75B0 = _bbStringReplace (String.Replace).
'     [0x00C61CC0] = TScreen+0x94 -> TScreen.DoMessage($,i,i)i (TProfile.StartCareer.bmx).
'     0x004A8F60 = _bbObjectDowncast, used for `For Local o:TContractOffer = EachIn
'     g_contractoffers`, downcasting against TContractOffer's own class table 0x00C6B7B8 --
'     the same EachIn shape as TContractOffer.GetOffer.bmx.
'   String literals read with harness.read_string: 0x00C8F8C0 "CheckTransferWindow",
'     0x00C8F8F4 "CMESSAGE_TRANSFERWINDOWOPEN", 0x00C8F938 "CMESSAGE_TRANSFERLISTEDBOSSUNHAPPY",
'     0x00C8F988 "CMESSAGE_TRANSFERWINDOWCLOSED", 0x00C8F9D0 "CMESSAGE_CONTRACTEXPIRED",
'     0x00C8FA0C "Clear contract offer list", 0x00C8FA4C "CMESSAGE_CONTRACTNEWOFFER",
'     0x00C81798 "$clubname".
'   The six-way lasttransferdate/contractexpires day-window Or-chain (each arm an
'     `X < sdate And sdate <= Y` pair) is transcribed arm-for-arm from the decompilation's
'     nested reset-and-retest bVar6/bVar7 shape -- the same shape this file's other And/Or
'     chains (the week/day window checks above) use. Offsets used, all against
'     g_profile.lasttransferdate except the last two (against g_profile.contractexpires):
'     +364/+371, +728/+735, +1092/+1099, +1456/+1463, -182/-175, -84/-77.
'   ORIGINAL BUG (not fixed): both week-window checks OR in a week value that the leading
'     `GetWeek() > N` guard already makes impossible (week=1 while week>10; week=11 while
'     week>32) -- left exactly as the decompilation computes it.
'   UNCERTAIN: the closing `if (!bVar6)` guard (sdate > 84 And sdate < lasttransferdate + 84,
'     negated) is written below as a literal `Not (A And B)`; the decompiled shape is
'     identical to this file's other And-chains but wrapped in one negation, and which
'     source-level idiom bcc actually used for that negation is not independently confirmed.
'   BYTE-CONFIRMED (bytematch): `If found` alone does not match -- bcc compiles a direct
'     `If found = 1` (a plain int cmp against the literal 1, "cmp edx,1 / jne", carried in a
'     register across the six-arm chain) rather than a truthy zero-test ("cmp edx,0 / je").
'     Written as `If found = 1` below.
'   BYTE-CONFIRMED (bytematch): the closing skill-rating test is NOT `skillrating/3 < rating`
'     as Ghidra normalizes it -- the x87 codegen (fild skillrating/3 pushed first, fld rating
'     pushed second, so rating is naturally on top of the FP stack) only matches with no
'     `fxch` when bcc's comparison node has rating as the LEFT operand, i.e. the actual source
'     is `If rating > p.GetSkillRating() / 3` (Ghidra silently canonicalizes `A > B` to
'     `B < A` for display). Written with rating first below.
'   RESIDUAL (unresolved): the original loads g_profile into eax for GetStat's self BEFORE
'     loading g_profile into esi for `p` -- both loads sit back to back, immediately after
'     UpdateInterestedClubs() and before either push sequence, with esi surviving the GetStat
'     call for reuse by p.GetSkillRating(). `p` declared ahead of `rating` (as below) reproduces
'     this exact shape but with the two loads in the opposite order (esi then eax); `rating`
'     declared ahead of `p` instead defers p's load until after the GetStat call. Neither
'     ordering of two plain `Local` statements reproduces eax-then-esi; tracing bcc's own
'     sources (block.cpp Block::eval, stm.cpp LocalDeclStm::eval, exp.cpp CmpExp::_eval) confirms
'     statements and comparison operands lower strictly in program order with no cross-statement
'     instruction hoisting, so this exact ordering was not reached. Every other byte in the
'     function matches; this is a length-neutral 11-byte reorder (first_diff +1549 of 1647).
'!Global g_profile:TProfile
'!Global g_contractoffers:TList
LogLine("CheckTransferWindow")
CheckPromoteFromBTeam()
If g_profile.date.GetWeek() > 10 And g_profile.date.GetDay() = 1 And (g_profile.date.GetWeek() = 1 Or g_profile.date.GetWeek() = 26)
	TScreen.DoMessage(GetText("CMESSAGE_TRANSFERWINDOWOPEN"), 0, 0)
	If g_profile.transferlisted = 0 And g_profile.relationboss < 30
		TScreen.DoMessage(GetText("CMESSAGE_TRANSFERLISTEDBOSSUNHAPPY"), 0, 0)
		g_profile.transferlisted = 2
	EndIf
ElseIf g_profile.date.GetWeek() > 32 And g_profile.date.GetDay() = 1 And (g_profile.date.GetWeek() = 11 Or g_profile.date.GetWeek() = 33)
	TScreen.DoMessage(GetText("CMESSAGE_TRANSFERWINDOWCLOSED"), 0, 0)
	If g_contractoffers <> Null Then g_contractoffers.Clear()
EndIf

If g_profile.date.GetDay() = 1
	If g_profile.date.sdate > g_profile.contractexpires And g_profile.date.sdate <= g_profile.contractexpires + 7
		TScreen.DoMessage(GetText("CMESSAGE_CONTRACTEXPIRED").Replace("$clubname", g_profile.myclub.labelname), 0, 0)
		If g_profile.transferlisted = 4 Then g_profile.CancelLoan()
		g_profile.transferlisted = 2
	ElseIf g_profile.relationboss > 50
		Local found:Int = 0
		If g_profile.date.sdate > g_profile.lasttransferdate + 364 And g_profile.date.sdate <= g_profile.lasttransferdate + 364 + 7
			found = 1
		ElseIf g_profile.date.sdate > g_profile.lasttransferdate + 728 And g_profile.date.sdate <= g_profile.lasttransferdate + 728 + 7
			found = 1
		ElseIf g_profile.date.sdate > g_profile.lasttransferdate + 1092 And g_profile.date.sdate <= g_profile.lasttransferdate + 1092 + 7
			found = 1
		ElseIf g_profile.date.sdate > g_profile.lasttransferdate + 1456 And g_profile.date.sdate <= g_profile.lasttransferdate + 1456 + 7
			found = 1
		ElseIf g_profile.date.sdate > g_profile.contractexpires - 182 And g_profile.date.sdate <= g_profile.contractexpires - 182 + 7
			found = 1
		ElseIf g_profile.date.sdate > g_profile.contractexpires - 84 And g_profile.date.sdate <= g_profile.contractexpires - 84 + 7
			found = 1
		EndIf
		If found = 1
			If g_contractoffers <> Null
				LogLine("Clear contract offer list")
				For Local o:TContractOffer = EachIn g_contractoffers
					If o.club.id = g_profile.clubid Then g_contractoffers.Remove(o)
				Next
			EndIf
			TScreen.DoMessage(GetText("CMESSAGE_CONTRACTNEWOFFER").Replace("$clubname", g_profile.myclub.labelname), 0, 0)
		EndIf
	EndIf
EndIf

If g_profile.date.sdate < 28 Then Return 0
If g_profile.date.sdate Mod 14 <> 0 Then Return 0
If TransferWindowOpen() <> 0 Then Return 0
If g_profile.date.sdate > 84 And g_profile.date.sdate < g_profile.lasttransferdate + 84 Then Return 0
UpdateInterestedClubs()
Local p:TProfile = g_profile
Local rating:Float = g_profile.GetStat(12, 3, 0, 0)
If rating > p.GetSkillRating() / 3
	DoTransferRumour()
EndIf
