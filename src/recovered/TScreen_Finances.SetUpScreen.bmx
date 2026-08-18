' TScreen_Finances.SetUpScreen
' VA 0x00558503   1783 bytes   vtable slot 0x34   sig ()i
' byte-identical vs NSS5.exe (1783/1783, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=145, NSS5_NO_LEARN=1, no learned helpers -- naming is FULL).
'
' ASSUMPTIONS
'   0x00C6F028 g_profile:TProfile -- SAME global ButtonSell.bmx already names g_profile
'     (slot 0xEC SellItemByName). All field offsets below are TProfile's from
'     object_model.json: contractwage +0x78, contractexpires +0x74, date +0x10 (:TMyDate,
'     sdate at TMyDate+0x8), lastweeksgoalbonus +0x88, lastweeksassistbonus +0x8C,
'     lastweekscleanbonus +0x90, lastweeksshirtsales +0xA0, items []i +0xF0, vehicles []i
'     +0xF4, property []i +0xF8, helppages []i +0x1C8 (index 5: (0x2C-0x18)/4).
'   0x00C68160 g_finances_summary_table:TTable -- the income/outgoings breakdown (Wage /
'     contract_Bonuses / Sponsorship / Shirt Sales / Property Costs / Vehicle Costs / Total).
'     Column layout is [description, income$, outgoings$]; a row with no income or no
'     outgoing puts a literal "-" in that column (globals_final.tsv names it
'     g_Object597, construction-typed TTable -- name is ours).
'   0x00C68164 g_finances_sponsors_table:TTable -- 9-row sponsor list built from
'     TProfile.GetStringArraySponsor(i) (globals_final g_Object598 -- name ours).
'   0x00C68168 g_finances_table:TTable -- SAME global ButtonSell.bmx already names
'     g_finances_table (slot 0xD8 GetSelectedText); this body is what populates it, from
'     the three GetStringArray*Owned(i) sellable-item lists (items/vehicles/property, each
'     gated on the matching TProfile array being > 0 at index i-1).
'   0x00C6816C g_finances_weeklybalance_label:TLabel, 0x00C68170
'     g_finances_totalperyear_label:TLabel, 0x00C68174 g_finances_lifestyle_bar:TProgressBar
'     (globals_final g_Object599/600/601, construction-typed -- names ours).
'   Class-table slots (TProfile, vtable_map.tsv): 0xC8 GetSponsorshipAmount, 0xCC
'     GetRentCosts, 0xD0 GetPropertyCosts, 0xD4 GetLastWeeksShirtSales, 0xD8
'     GetVehicleCosts, 0xDC GetTotalSponsorship, 0xE0 GetStringArraySponsor(i)[]$, 0xE4/E8/F0
'     GetStringArray{Items,Vehicles,Property}Owned(i)[]$, 0xF4 GetLifestyle. TTable: 0x94
'     AddItem([]$,$,$)i, 0x9C ClearItems, 0xDC SelectItemByRow(i)i. TLabel/TGadget: 0x64
'     SetText($,$,i,i)i, called `.SetText(text, "", -1, -1)` per the established corpus
'     pattern (TCombo/TButton/TEngine etc). TProgressBar: 0x8C SetPercent(f,i)i.
'     0x00C61C88 TScreen+0x5C SetActive($,$):TScreen; 0x00C61CE0 TScreen+0xB4 Tutorial()i.
'   `wage = wage / 2` is bcc's standard signed-int div-by-2 lowering
'     ((x + ((x>>31)&1))>>1) -- confirmed by exact byte match, not assumed.
'   The wage-halving guard is written `If g_profile.date.sdate > g_profile.contractexpires`
'     (date.sdate as the FIRST/left operand) -- the operand order is byte-observable
'     (codegen-patterns 10.1) and `contractexpires > date.sdate` / `date.sdate < ...` both
'     emit different bytes.
'   The rentcosts row is a genuine If/Else (two different rows), written
'     `If rentcosts > 0 Then <"Property Costs (Rent)", "-", FormatMoney(rentcosts)>
'     Else <"Property Costs", "-", FormatMoney(propertycosts)>` -- confirmed against the
'     original's `cmp edi,0 / jle` (fallthrough on rentcosts>0 builds the Rent-labelled row,
'     jump target on rentcosts<=0 builds the plain row); the naive `If rentcosts < 1 Then
'     plain Else rent-labelled` mismatched by a full reordered block (localise_diff GAP).
'   `balance:Int = totalincome - totaloutgoings` and `totalsponsorship:Int =
'     g_profile.GetTotalSponsorship()` are separately DECLARED Locals, computed at the point
'     the original computes them (balance right after totaloutgoings, before the "Total" row
'     is even built; totalsponsorship right before the "Total Per Year" label, after the
'     sponsors loop) -- both used only once downstream but the original still spills/holds
'     them from an earlier point, which is only reachable by giving them their own Local
'     rather than inlining the expression at the point of use (confirmed: inlining left the
'     original 9-dword frame one slot short of the reconstruction's 8, `sub esp,0x24` vs
'     `0x20`; extracting both closed it exactly, 8->9, with zero bytes left over).
'   All string literals read from the exe with harness.read_string, not guessed: "finances",
'     "Wage", "contract_Bonuses", "Sponsorship", "Shirt Sales", " (", ")", "Rent",
'     "Property Costs", "Vehicle Costs", "Total", "finances_WeeklyBalance", " = ",
'     "Total Per Year", "-".
'!Global g_profile:TProfile
'!Global g_finances_summary_table:TTable
'!Global g_finances_sponsors_table:TTable
'!Global g_finances_table:TTable
'!Global g_finances_weeklybalance_label:TLabel
'!Global g_finances_totalperyear_label:TLabel
'!Global g_finances_lifestyle_bar:TProgressBar
	Function SetUpScreen:Int()
		TScreen.SetActive("finances", "")
		g_finances_summary_table.ClearItems()
		Local wage:Int = g_profile.contractwage
		If g_profile.date.sdate > g_profile.contractexpires
			wage = wage / 2
		End If
		Local sponsorship:Int = g_profile.GetSponsorshipAmount()
		Local bonuses:Int = g_profile.lastweeksassistbonus + g_profile.lastweeksgoalbonus + g_profile.lastweekscleanbonus
		Local shirtsales:Int = g_profile.GetLastWeeksShirtSales()
		g_finances_summary_table.AddItem([GetText("Wage"), FormatMoney(wage, 0), "-"], "", "")
		g_finances_summary_table.AddItem([GetText("contract_Bonuses"), FormatMoney(bonuses, 0), "-"], "", "")
		g_finances_summary_table.AddItem([GetText("Sponsorship"), FormatMoney(sponsorship, 0), "-"], "", "")
		g_finances_summary_table.AddItem([GetText("Shirt Sales") + " (" + String(g_profile.lastweeksshirtsales) + ")", FormatMoney(shirtsales, 0), "-"], "", "")
		Local rentcosts:Int = g_profile.GetRentCosts()
		Local propertycosts:Int = g_profile.GetPropertyCosts()
		Local vehiclecosts:Int = g_profile.GetVehicleCosts()
		If rentcosts > 0
			g_finances_summary_table.AddItem([GetText("Property Costs") + " (" + GetText("Rent") + ")", "-", FormatMoney(rentcosts, 0)], "", "")
		Else
			g_finances_summary_table.AddItem([GetText("Property Costs"), "-", FormatMoney(propertycosts, 0)], "", "")
		End If
		g_finances_summary_table.AddItem([GetText("Vehicle Costs"), "-", FormatMoney(vehiclecosts, 0)], "", "")
		Local totalincome:Int = wage + sponsorship + bonuses + shirtsales
		Local totaloutgoings:Int = rentcosts + propertycosts + vehiclecosts
		Local balance:Int = totalincome - totaloutgoings
		g_finances_summary_table.AddItem([GetText("Total"), FormatMoney(totalincome, 0), FormatMoney(totaloutgoings, 0)], "", "")
		g_finances_weeklybalance_label.SetText(GetText("finances_WeeklyBalance") + " = " + FormatMoney(balance, 0), "", -1, -1)
		g_finances_sponsors_table.ClearItems()
		Local i:Int
		For i = 1 To 9
			g_finances_sponsors_table.AddItem(g_profile.GetStringArraySponsor(i), "", "")
		Next
		Local totalsponsorship:Int = g_profile.GetTotalSponsorship()
		g_finances_totalperyear_label.SetText(GetText("Total Per Year") + " = " + FormatMoney(totalsponsorship, 0), "", -1, -1)
		g_finances_table.ClearItems()
		For i = 1 To 10
			If g_profile.items[i - 1] > 0
				g_finances_table.AddItem(g_profile.GetStringArrayItemsOwned(i), "", "")
			End If
		Next
		For i = 1 To 10
			If g_profile.vehicles[i - 1] > 0
				g_finances_table.AddItem(g_profile.GetStringArrayVehiclesOwned(i), "", "")
			End If
		Next
		For i = 1 To 10
			If g_profile.property[i - 1] > 0
				g_finances_table.AddItem(g_profile.GetStringArrayPropertyOwned(i), "", "")
			End If
		Next
		g_finances_table.SelectItemByRow(0)
		g_finances_lifestyle_bar.SetPercent(Float(g_profile.GetLifestyle()), 1)
		If g_profile.helppages[5] = 0
			TScreen.Tutorial()
			g_profile.helppages[5] = 1
		End If
	End Function
