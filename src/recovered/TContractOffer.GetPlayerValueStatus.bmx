' TContractOffer.GetPlayerValueStatus  -- KIND=Function (static, no implicit Self)
' VA 0x00572C50   509 bytes   sig ()i   slot 0x64
' byte-identical vs NSS5.exe (509/509, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=35)
'
' ASSUMPTIONS
'   Global (name ours): 0x00C6F028 -> g_contractoffer_tplayer:TProfile. Offset arithmetic
'     against the Global is internally consistent (+0x10 date:TMyDate, +0x20 clubid) which
'     corroborates TProfile over the table's raw "construction" note.
'   TProfile.date is a TMyDate; slot 0x54 = GetYear(), slot 0x50 = GetWeek() (vtable_map.tsv).
'   TProfile.GetStat(i,i,i,i):f is slot 0x88; GetSkillRating()i is 0xa4; GetFame()f is 0xf8
'     (all vtable_map.tsv).
'   TClub+0x60 = SelectById(i):TClub (class-table interior slot, not a Global).
'   TClub extends TBase_Team; +0x24 = strength:Int (TBase_Team field, object_model.json).
'   TProfile fields used: +0x148 onloanfrom, +0x1d0 myclub:TClub (object_model.json).
'   String literals read from the exe at 0x00C8FB24/54/7C/A0 (">>> avgrating = " etc).
'   Float literals read from the exe: 0x00C8FB50=5.0, 0x00C8FBD4=0.5, 0x00C8FBD8=90.0,
'     0x00C8FBDC=90.0 (two separate constant slots holding the same value).
'
' Shape notes, established via localise_diff.py against the original:
'   - the week guard is written `<= 10`, not `< 11` (cmp imm 0x0A / jg, not 0x0B / jge).
'   - the onloanfrom guard is `> 0` with the SelectById branch as the If-body (fallthrough)
'     and the myclub branch as the Else (jump target) -- the reverse of the naive reading.
'   - clubstrength is assigned INLINE as a Float in each branch of that If (an Int->Float
'     conversion duplicated in both arms), not computed once from a shared Int temp after.
'   - ">>> avgrating = " logs `value` (the date/GetStat result), not clubstrength -- confirmed
'     by the push operand (`push [ebp-8]`), which contradicts Ghidra's decompiled C reusing
'     one variable name for two different frame slots.
'   - skills/fame are never stored to a named Local: `value = value + Self.GetSkillRating()`
'     accumulates directly, and the following LogLine calls the SAME getter a second time
'     (bcc does no CSE) purely for the log string.
'   - the final cap-at-90 result is a FRESH Float Local declared after `value`/`clubstrength`
'     (last-declared Float Local stays x87-resident, never spilled -- codegen-patterns.md
'     6/10.5) -- reusing `value` for the cap forces a spill/reload the original does not have.
'!Global g_contractoffer_tplayer:TProfile
Local year:Int = g_contractoffer_tplayer.date.GetYear()
Local week:Int = g_contractoffer_tplayer.date.GetWeek()
Local value:Float
If week <= 10
	If year = 1
		value = 0.5
	Else
		value = g_contractoffer_tplayer.GetStat(18, 3, g_contractoffer_tplayer.clubid, year - 1)
	EndIf
Else
	value = g_contractoffer_tplayer.GetStat(18, 3, 0, year)
EndIf

Local clubstrength:Float
If g_contractoffer_tplayer.onloanfrom > 0
	clubstrength = TClub.SelectById(g_contractoffer_tplayer.onloanfrom).strength
Else
	clubstrength = g_contractoffer_tplayer.myclub.strength
EndIf

LogLine(">>> avgrating = " + value)

value = value * 5.0

value = value + g_contractoffer_tplayer.GetSkillRating()
LogLine(">>> skills = " + g_contractoffer_tplayer.GetSkillRating())

value = value + g_contractoffer_tplayer.GetFame()
LogLine(">>> fame = " + g_contractoffer_tplayer.GetFame())

LogLine(">>> clubstrength = " + clubstrength)

Local valcap:Float = (value + clubstrength) * 0.5
If valcap > 90.0 Then valcap = 90.0
Return Int(valcap)
