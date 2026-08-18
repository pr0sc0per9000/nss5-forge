' THorse.SetRaceOdds
' VA 0x0058b40d   221 bytes   vtable slot 0x?   sig ()i
' byte-identical vs NSS5.exe (221/221, original length from Ghidra's inventory, mode=reloc)
' Assumptions: 0x00C6E294 and 0x00C6E298 declared TList (globals_final.tsv says bare Object;
'   slot 0x88 = TList.Sort and slot 0x8C = TList.ObjectEnumerator fix the type).
'   0x00C6E29C declared Int. THorse field at +0x68 is `betprice`.
'   FUN_005B3516 = _brl_linkedlist_CompareObjects, the default comparator passed to Sort.
'   FUN_0059F089 = Rand.
'!Global g_stable_horselist:TList
'!Global g_stable_racelist:TList
'!Global g_stable_racedistance:Int
	Function SetRaceOdds()
		g_stable_racedistance = 11
		g_stable_horselist.Sort(0, CompareObjects)
		For Local h:THorse = EachIn g_stable_horselist
			h.betprice = 0
		Next
		Local price:Int = 2
		For Local h:THorse = EachIn g_stable_racelist
			h.betprice = price
			price = price + Rand(3, 1)
		Next
	End Function
