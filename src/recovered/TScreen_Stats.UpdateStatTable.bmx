' TScreen_Stats.UpdateStatTable
' VA 0x0054E16A   16301 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, class-table slot 0x3c   -- static: NO implicit Self
' ASSUMPTIONS
'   0x00C679C4 g_stats_table:TTable    -- slot 0x9c ClearItems, 0x94 AddItem,
'   0x00C679D4 g_stats_totals:TTable      0xa0 SetColumnHeading all resolve on TTable
'   0x00C679CC g_stats_combo_season:TCombo  -- slot 0xc0 = GetSelectedItemId
'   0x00C679C8 g_stats_combo_club:TCombo
'   0x00C679D8 g_stats_combo_comp:TCombo
'   0x00C6F028 g_profile:TProfile      -- slot 0x8c GetStringStat(i,i,i,i,i)$,
'     0x88 GetStat(i,i,i,i)f, and fields +0x198 banclub / +0x19c bancontinent /
'     +0x1a0 baninternational all land on real TProfile members. globals_final.tsv
'     types it TProfile but flags the derivation UNSOUND; six independent
'     resolutions here corroborate it.
'   0x00C5D254 g_options_units:Int     -- `cmp dword [0xc5d254],1`, bare dword,
'     no refcount traffic (pattern 11.2). Names are ours; Globals have no debug record.
'   TPitch class-table slot 0x74 = YardsToMetres  (PTR_FUN_00C5D9A0)
'   FUN_0050640C = FormatDecimals, FUN_00507474 = GroupDigits, FUN_004C5549 = GetText
'     -- all three are recovered module Functions in src/recovered_module/; names are ours
'   FUN_004A63D0 bbArrayNew1D (New String[6], tag "$"), 004A6A30 bbStringCompare,
'     004A6E90 bbStringToFloat, 004A7AC0 bbStringFromInt, 004A7C20 bbStringConcat
'   Row 17's label is a Select, not If/ElseIf -- subject loaded once, both cmp/je back to
'     back at 0x00551C9F, jmp past every body after the last compare (pattern 10.2).
'     As If/ElseIf the function is 16297, not 16301.
'   susp[0] and susp[1] are BOTH banclub. That is the original's behaviour, not a typo.
'   A[4] is computed for every array and never displayed.
'   All 30 string literals were read out of NSS5.exe with harness.read_string and checked
'     as a multiset against every literal the original body references: exact, including
'     multiplicities. (A MATCH masks a literal's ADDRESS, so content is not certified by
'     the oracle -- this check is separate.)
'   Verified with NSS5_NO_LEARN=1 (no in-run helper-name learning).
'   Required a fix to harness.compare: a false-positive call-opcode candidate.
'     `FF 75 E8 push dword [ebp-0x18]` ends in 0xE8, so the masking loop committed to the
'     push's displacement byte and never tried the real `E8 call FormatDecimals` one byte
'     later.
'!Global g_stats_table:TTable
'!Global g_stats_totals:TTable
'!Global g_stats_combo_season:TCombo
'!Global g_stats_combo_club:TCombo
'!Global g_stats_combo_comp:TCombo
'!Global g_profile:TProfile
'!Global g_options_units:Int
g_stats_table.ClearItems()
g_stats_totals.ClearItems()
Local season:Int = g_stats_combo_season.GetSelectedItemId()
Local club:Int = g_stats_combo_club.GetSelectedItemId()
Local comp:Int = g_stats_combo_comp.GetSelectedItemId()
Local a12:String[] = New String[6]
a12[0] = g_profile.GetStringStat(12,0,club,season,0)
a12[1] = g_profile.GetStringStat(12,1,club,season,0)
a12[2] = g_profile.GetStringStat(12,2,club,season,0)
a12[3] = g_profile.GetStringStat(12,3,club,season,0)
a12[4] = g_profile.GetStringStat(12,3,club,0,0)
a12[5] = g_profile.GetStringStat(12,4,0,comp,0)
Local a13:String[] = New String[6]
a13[0] = g_profile.GetStringStat(13,0,club,season,0)
a13[1] = g_profile.GetStringStat(13,1,club,season,0)
a13[2] = g_profile.GetStringStat(13,2,club,season,0)
a13[3] = g_profile.GetStringStat(13,3,club,season,0)
a13[4] = g_profile.GetStringStat(13,3,club,0,0)
a13[5] = g_profile.GetStringStat(13,4,0,comp,0)
Local a5:String[] = New String[6]
a5[0] = g_profile.GetStringStat(5,0,club,season,0)
a5[1] = g_profile.GetStringStat(5,1,club,season,0)
a5[2] = g_profile.GetStringStat(5,2,club,season,0)
a5[3] = g_profile.GetStringStat(5,3,club,season,0)
a5[4] = g_profile.GetStringStat(5,3,club,0,0)
a5[5] = g_profile.GetStringStat(5,4,0,comp,0)
Local r5:String[] = New String[6]
If a12[0] = "0"
	r5[0] = "0"
Else
	r5[0] = FormatDecimals(Float(a5[0]) / Float(a12[0]), 2)
End If
If a12[1] = "0"
	r5[1] = "0"
Else
	r5[1] = FormatDecimals(Float(a5[1]) / Float(a12[1]), 2)
End If
If a12[2] = "0"
	r5[2] = "0"
Else
	r5[2] = FormatDecimals(Float(a5[2]) / Float(a12[2]), 2)
End If
If a12[3] = "0"
	r5[3] = "0"
Else
	r5[3] = FormatDecimals(Float(a5[3]) / Float(a12[3]), 2)
End If
If a12[4] = "0"
	r5[4] = "0"
Else
	r5[4] = FormatDecimals(Float(a5[4]) / Float(a12[4]), 2)
End If
If a12[5] = "0"
	r5[5] = "0"
Else
	r5[5] = FormatDecimals(Float(a5[5]) / Float(a12[5]), 2)
End If
Local a2:String[] = New String[6]
a2[0] = g_profile.GetStringStat(2,0,club,season,0)
a2[1] = g_profile.GetStringStat(2,1,club,season,0)
a2[2] = g_profile.GetStringStat(2,2,club,season,0)
a2[3] = g_profile.GetStringStat(2,3,club,season,0)
a2[4] = g_profile.GetStringStat(2,3,club,0,0)
a2[5] = g_profile.GetStringStat(2,4,0,comp,0)
Local r2:String[] = New String[6]
If a5[0] = "0"
	r2[0] = "0"
Else
	r2[0] = FormatDecimals(Float(a2[0]) / Float(a5[0]), 2)
End If
If a5[1] = "0"
	r2[1] = "0"
Else
	r2[1] = FormatDecimals(Float(a2[1]) / Float(a5[1]), 2)
End If
If a5[2] = "0"
	r2[2] = "0"
Else
	r2[2] = FormatDecimals(Float(a2[2]) / Float(a5[2]), 2)
End If
If a5[3] = "0"
	r2[3] = "0"
Else
	r2[3] = FormatDecimals(Float(a2[3]) / Float(a5[3]), 2)
End If
If a5[4] = "0"
	r2[4] = "0"
Else
	r2[4] = FormatDecimals(Float(a2[4]) / Float(a5[4]), 2)
End If
If a5[5] = "0"
	r2[5] = "0"
Else
	r2[5] = FormatDecimals(Float(a2[5]) / Float(a5[5]), 2)
End If
Local a14:String[] = New String[6]
a14[0] = g_profile.GetStringStat(14,0,club,season,0)
a14[1] = g_profile.GetStringStat(14,1,club,season,0)
a14[2] = g_profile.GetStringStat(14,2,club,season,0)
a14[3] = g_profile.GetStringStat(14,3,club,season,0)
a14[4] = g_profile.GetStringStat(14,3,club,0,0)
a14[5] = g_profile.GetStringStat(14,4,0,comp,0)
Local a3:String[] = New String[6]
a3[0] = g_profile.GetStringStat(3,0,club,season,0)
a3[1] = g_profile.GetStringStat(3,1,club,season,0)
a3[2] = g_profile.GetStringStat(3,2,club,season,0)
a3[3] = g_profile.GetStringStat(3,3,club,season,0)
a3[4] = g_profile.GetStringStat(3,3,club,0,0)
a3[5] = g_profile.GetStringStat(3,4,0,comp,0)
Local r3:String[] = New String[6]
If a12[0] = "0"
	r3[0] = "0"
Else
	r3[0] = FormatDecimals(Float(a3[0]) / Float(a12[0]), 2)
End If
If a12[1] = "0"
	r3[1] = "0"
Else
	r3[1] = FormatDecimals(Float(a3[1]) / Float(a12[1]), 2)
End If
If a12[2] = "0"
	r3[2] = "0"
Else
	r3[2] = FormatDecimals(Float(a3[2]) / Float(a12[2]), 2)
End If
If a12[3] = "0"
	r3[3] = "0"
Else
	r3[3] = FormatDecimals(Float(a3[3]) / Float(a12[3]), 2)
End If
If a12[4] = "0"
	r3[4] = "0"
Else
	r3[4] = FormatDecimals(Float(a3[4]) / Float(a12[4]), 2)
End If
If a12[5] = "0"
	r3[5] = "0"
Else
	r3[5] = FormatDecimals(Float(a3[5]) / Float(a12[5]), 2)
End If
Local a4:String[] = New String[6]
a4[0] = g_profile.GetStringStat(4,0,club,season,0)
a4[1] = g_profile.GetStringStat(4,1,club,season,0)
a4[2] = g_profile.GetStringStat(4,2,club,season,0)
a4[3] = g_profile.GetStringStat(4,3,club,season,0)
a4[4] = g_profile.GetStringStat(4,3,club,0,0)
a4[5] = g_profile.GetStringStat(4,4,0,comp,0)
Local a6:String[] = New String[6]
a6[0] = g_profile.GetStringStat(6,0,club,season,0)
a6[1] = g_profile.GetStringStat(6,1,club,season,0)
a6[2] = g_profile.GetStringStat(6,2,club,season,0)
a6[3] = g_profile.GetStringStat(6,3,club,season,0)
a6[4] = g_profile.GetStringStat(6,3,club,0,0)
a6[5] = g_profile.GetStringStat(6,4,0,comp,0)
Local a17:String[] = New String[6]
a17[0] = g_profile.GetStringStat(17,0,club,season,0)
a17[1] = g_profile.GetStringStat(17,1,club,season,0)
a17[2] = g_profile.GetStringStat(17,2,club,season,0)
a17[3] = g_profile.GetStringStat(17,3,club,season,0)
a17[4] = g_profile.GetStringStat(17,3,club,0,0)
a17[5] = g_profile.GetStringStat(17,4,0,comp,0)
Local r17:String[] = New String[6]
If a12[0] = "0"
	r17[0] = "0"
Else
	r17[0] = FormatDecimals(Float(a17[0]) / Float(a12[0]), 2)
End If
If a12[1] = "0"
	r17[1] = "0"
Else
	r17[1] = FormatDecimals(Float(a17[1]) / Float(a12[1]), 2)
End If
If a12[2] = "0"
	r17[2] = "0"
Else
	r17[2] = FormatDecimals(Float(a17[2]) / Float(a12[2]), 2)
End If
If a12[3] = "0"
	r17[3] = "0"
Else
	r17[3] = FormatDecimals(Float(a17[3]) / Float(a12[3]), 2)
End If
If a12[4] = "0"
	r17[4] = "0"
Else
	r17[4] = FormatDecimals(Float(a17[4]) / Float(a12[4]), 2)
End If
If a12[5] = "0"
	r17[5] = "0"
Else
	r17[5] = FormatDecimals(Float(a17[5]) / Float(a12[5]), 2)
End If
Local a11:String[] = New String[6]
a11[0] = g_profile.GetStringStat(11,0,club,season,0)
a11[1] = g_profile.GetStringStat(11,1,club,season,0)
a11[2] = g_profile.GetStringStat(11,2,club,season,0)
a11[3] = g_profile.GetStringStat(11,3,club,season,0)
a11[4] = g_profile.GetStringStat(11,3,club,0,0)
a11[5] = g_profile.GetStringStat(11,4,0,comp,0)
Local a9:String[] = New String[6]
a9[0] = g_profile.GetStringStat(9,0,club,season,0)
a9[1] = g_profile.GetStringStat(9,1,club,season,0)
a9[2] = g_profile.GetStringStat(9,2,club,season,0)
a9[3] = g_profile.GetStringStat(9,3,club,season,0)
a9[4] = g_profile.GetStringStat(9,3,club,0,0)
a9[5] = g_profile.GetStringStat(9,4,0,comp,0)
Local a10:String[] = New String[6]
a10[0] = g_profile.GetStringStat(10,0,club,season,0)
a10[1] = g_profile.GetStringStat(10,1,club,season,0)
a10[2] = g_profile.GetStringStat(10,2,club,season,0)
a10[3] = g_profile.GetStringStat(10,3,club,season,0)
a10[4] = g_profile.GetStringStat(10,3,club,0,0)
a10[5] = g_profile.GetStringStat(10,4,0,comp,0)
Local a1:String[] = New String[6]
a1[0] = g_profile.GetStringStat(1,0,club,season,0)
a1[1] = g_profile.GetStringStat(1,1,club,season,0)
a1[2] = g_profile.GetStringStat(1,2,club,season,0)
a1[3] = g_profile.GetStringStat(1,3,club,season,0)
a1[4] = g_profile.GetStringStat(1,3,club,0,0)
a1[5] = g_profile.GetStringStat(1,4,0,comp,0)
If g_options_units = 1
	a1[0] = GroupDigits(Int(TPitch.YardsToMetres(g_profile.GetStat(1,0,club,season))))
	a1[1] = GroupDigits(Int(TPitch.YardsToMetres(g_profile.GetStat(1,1,club,season))))
	a1[2] = GroupDigits(Int(TPitch.YardsToMetres(g_profile.GetStat(1,2,club,season))))
	a1[3] = GroupDigits(Int(TPitch.YardsToMetres(g_profile.GetStat(1,3,club,season))))
	a1[4] = GroupDigits(Int(TPitch.YardsToMetres(g_profile.GetStat(1,3,club,0))))
	a1[5] = GroupDigits(Int(TPitch.YardsToMetres(g_profile.GetStat(1,4,0,comp))))
End If
Local a16:String[] = New String[6]
a16[0] = g_profile.GetStringStat(16,0,club,season,0)
a16[1] = g_profile.GetStringStat(16,1,club,season,0)
a16[2] = g_profile.GetStringStat(16,2,club,season,0)
a16[3] = g_profile.GetStringStat(16,3,club,season,0)
a16[4] = g_profile.GetStringStat(16,3,club,0,0)
a16[5] = g_profile.GetStringStat(16,4,0,comp,0)
Local a15:String[] = New String[6]
a15[0] = g_profile.GetStringStat(15,0,club,season,0)
a15[1] = g_profile.GetStringStat(15,1,club,season,0)
a15[2] = g_profile.GetStringStat(15,2,club,season,0)
a15[3] = g_profile.GetStringStat(15,3,club,season,0)
a15[4] = g_profile.GetStringStat(15,3,club,0,0)
a15[5] = g_profile.GetStringStat(15,4,0,comp,0)
Local a18:String[] = New String[6]
a18[0] = g_profile.GetStringStat(18,0,club,season,1)
a18[1] = g_profile.GetStringStat(18,1,club,season,1)
a18[2] = g_profile.GetStringStat(18,2,club,season,1)
a18[3] = g_profile.GetStringStat(18,3,club,season,1)
a18[4] = g_profile.GetStringStat(18,3,club,0,1)
a18[5] = g_profile.GetStringStat(18,4,0,comp,1)
Local susp:String[] = New String[6]
susp[0] = String(g_profile.banclub)
susp[1] = String(g_profile.banclub)
susp[2] = String(g_profile.bancontinent)
susp[3] = "-"
susp[4] = "-"
susp[5] = String(g_profile.baninternational)
Local comb:String[] = New String[6]
comb[0] = a12[0] + " (" + a13[0] + ")"
comb[1] = a12[1] + " (" + a13[1] + ")"
comb[2] = a12[2] + " (" + a13[2] + ")"
comb[3] = a12[3] + " (" + a13[3] + ")"
comb[4] = a12[4] + " (" + a13[4] + ")"
comb[5] = a12[5] + " (" + a13[5] + ")"
Local lbl:String
lbl = GetText("Appearances") + " (" + GetText("tla_Substitute") + ")"
g_stats_table.AddItem([lbl, comb[0], comb[1], comb[2], comb[3], ""], Null, Null)
g_stats_totals.AddItem([lbl, comb[5]], Null, Null)
lbl = GetText("Goals")
g_stats_table.AddItem([lbl, a5[0], a5[1], a5[2], a5[3], ""], Null, Null)
g_stats_totals.AddItem([lbl, a5[5]], Null, Null)
lbl = GetText("Goals per Game")
g_stats_table.AddItem([lbl, r5[0], r5[1], r5[2], r5[3], ""], Null, Null)
g_stats_totals.AddItem([lbl, r5[5]], Null, Null)
lbl = GetText("Hat Tricks")
g_stats_table.AddItem([lbl, a14[0], a14[1], a14[2], a14[3], ""], Null, Null)
g_stats_totals.AddItem([lbl, a14[5]], Null, Null)
lbl = GetText("Shots")
g_stats_table.AddItem([lbl, a2[0], a2[1], a2[2], a2[3], ""], Null, Null)
g_stats_totals.AddItem([lbl, a2[5]], Null, Null)
lbl = GetText("Shots per Goal")
g_stats_table.AddItem([lbl, r2[0], r2[1], r2[2], r2[3], ""], Null, Null)
g_stats_totals.AddItem([lbl, r2[5]], Null, Null)
lbl = GetText("Passes")
g_stats_table.AddItem([lbl, a3[0], a3[1], a3[2], a3[3], ""], Null, Null)
g_stats_totals.AddItem([lbl, a3[5]], Null, Null)
lbl = GetText("Passes per Game")
g_stats_table.AddItem([lbl, r3[0], r3[1], r3[2], r3[3], ""], Null, Null)
g_stats_totals.AddItem([lbl, r3[5]], Null, Null)
lbl = GetText("Assists")
g_stats_table.AddItem([lbl, a4[0], a4[1], a4[2], a4[3], ""], Null, Null)
g_stats_totals.AddItem([lbl, a4[5]], Null, Null)
lbl = GetText("Headers")
g_stats_table.AddItem([lbl, a6[0], a6[1], a6[2], a6[3], ""], Null, Null)
g_stats_totals.AddItem([lbl, a6[5]], Null, Null)
lbl = GetText("Tackles")
g_stats_table.AddItem([lbl, a17[0], a17[1], a17[2], a17[3], ""], Null, Null)
g_stats_totals.AddItem([lbl, a17[5]], Null, Null)
lbl = GetText("Tackles per Game")
g_stats_table.AddItem([lbl, r17[0], r17[1], r17[2], r17[3], ""], Null, Null)
g_stats_totals.AddItem([lbl, r17[5]], Null, Null)
lbl = GetText("Fouls")
g_stats_table.AddItem([lbl, a11[0], a11[1], a11[2], a11[3], ""], Null, Null)
g_stats_totals.AddItem([lbl, a11[5]], Null, Null)
lbl = GetText("Yellow Cards")
g_stats_table.AddItem([lbl, a9[0], a9[1], a9[2], a9[3], ""], Null, Null)
g_stats_totals.AddItem([lbl, a9[5]], Null, Null)
lbl = GetText("Red Cards")
g_stats_table.AddItem([lbl, a10[0], a10[1], a10[2], a10[3], ""], Null, Null)
g_stats_totals.AddItem([lbl, a10[5]], Null, Null)
lbl = GetText("Current Suspension")
g_stats_table.AddItem([lbl, susp[0], susp[1], susp[2], susp[3], ""], Null, Null)
g_stats_totals.AddItem([lbl, susp[5]], Null, Null)
Select g_options_units
Case 0
	lbl = GetText("Distance") + " (" + GetText("tla_Yards") + ")"
Case 1
	lbl = GetText("Distance") + " (" + GetText("tla_Metres") + ")"
End Select
g_stats_table.AddItem([lbl, a1[0], a1[1], a1[2], a1[3], ""], Null, Null)
g_stats_totals.AddItem([lbl, a1[5]], Null, Null)
lbl = GetText("Star Man")
g_stats_table.AddItem([lbl, a15[0], a15[1], a15[2], a15[3], ""], Null, Null)
g_stats_totals.AddItem([lbl, a15[5]], Null, Null)
lbl = GetText("Form")
g_stats_table.AddItem([lbl, a16[0], a16[1], a16[2], a16[3], ""], Null, Null)
g_stats_totals.AddItem([lbl, a16[5]], Null, Null)
lbl = GetText("Average Rating")
g_stats_table.AddItem([lbl, a18[0], a18[1], a18[2], a18[3], ""], Null, Null)
g_stats_totals.AddItem([lbl, a18[5]], Null, Null)
If season = 0
	g_stats_table.SetColumnHeading(4, GetText("All Time"))
Else
	g_stats_table.SetColumnHeading(4, GetText("Year") + " " + String(season))
End If
If comp = 0
	g_stats_totals.SetColumnHeading(1, GetText("All Time"))
Else
	g_stats_totals.SetColumnHeading(1, GetText("Year") + " " + String(comp))
End If
