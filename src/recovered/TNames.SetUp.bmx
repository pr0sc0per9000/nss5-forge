' TNames.SetUp
' VA 0x004C71DC   773 bytes   vtable slot 0x30   sig (i)i   KIND=Function
' byte-identical vs NSS5.exe (773/773, original length from Ghidra's inventory, mode=reloc)
'
' Globals: g_team_arr01:String[] (0x00C5A430, firstnames), g_team_arr02:String[]
'   (0x00C5A434, lastnames), g_datapath:String (0x00C6E950, install/data-path prefix --
'   same slot every asset-loader in the corpus uses; globals_final.tsv calls this row
'   "g_promotionplace_int05" but that name is wrong for this address, see e.g.
'   TClub.SaveMaster.bmx).
' Calls: 0x004A7D60 named _bbStringSplit here (learned via harness during this
'   reconstruction -- 6 call sites corpuswide). Internally it calls _bbStringFind
'   (0x004A6B60), _bbStringCompare (0x004A63D0) and _bbStringSlice (0x004A7C90), which is
'   exactly BBString::Split's shape, and it is invoked here with (String, String) returning
'   a value indexed with the +0x18 BBArray base -- matches `str.Split(sep)`.
'   NextField (module fn, 0x00505C64) supplies the header-row tab walk.
' CTSLOT: TNames+0x30 = SetUp (i)i -- the `nat_column < 0` branch calls back into this
'   same Function with a0=$3E (62), a class-table dispatch rather than a direct call, so
'   it is written as a plain same-Type call with no `TNames.` prefix.
' Field/offset notes: none -- this Function touches no TNames Fields, only the three
'   Globals above.
' Shape notes:
'   - `If Not a1` (NOT `If a1 = Null`) -- the 21-byte "If Not x" emission (setne/movzx),
'     not the 12-byte null-compare form (codegen-patterns 10.3).
'   - The header-row loop computes `Int(f[..f.Find("_")])` and compares it against a0
'     INLINE -- there is no separate `Local v:Int` holding the conversion result.
'   - `fnc`/`lnc` use the `:+ 1` idiom (`add [mem],1` then `push [mem]`), not
'     `x = x + 1` -- confirmed by the growth call being `arr[..fnc]` / `arr[fnc-1] = fn`
'     (fnc already incremented before the slice), not the more obvious `arr[..fnc+1]` /
'     `arr[fnc] = fn` / `fnc = fnc + 1`.
'   - `fn` (fields[nat_column]) is a genuine Local, read once and reused for both the
'     `.Length` check and the store. `ln` (fields[nat_column+1]) is ALSO declared as a
'     Local and used for the `.Length` check, but the store line re-reads
'     `fields[nat_column + 1]` from the array directly instead of reusing `ln` --
'     reproduced faithfully (bcc's "no CSE" rule, codegen-patterns 6), not "fixed".
'   - The `nat_column < 0` branch needs an explicit `Return 0` after the recursive
'     `SetUp($3e)` call to skip the following `Else`; without it the branch merges into
'     the Else and the body comes out 5 bytes short.
	Function SetUp:Int(a0:Int)
		'!Global g_team_arr01:String[]
		'!Global g_team_arr02:String[]
		'!Global g_datapath:String
		LogLine("TNames.SetUp: " + String(a0))
		Local a1:TStream = ReadFile("utf8::" + g_datapath + "GameMedia/Data/Names.csv")
		If Not a1
			Notify("Error TNames: Unable to load file!", True)
			End
		EndIf
		Local line:String = ReadLine(a1)
		Local nat_column:Int = -1
		Local i:Int = 0
		Repeat
			Local f:String = NextField(line, "~t")
			If Int(f[..f.Find("_")]) = a0 Then nat_column = i
			i = i + 1
		Until nat_column > 0 Or line.Length < 1
		LogLine("nat_column = " + String(nat_column))
		If nat_column < 0
			SetUp($3e)
			Return 0
		Else
			Local fnc:Int = 0
			Local lnc:Int = 0
			While Not Eof(a1)
				Local fields:String[] = ReadLine(a1).Split("~t")
				Local fn:String = fields[nat_column]
				Local ln:String = fields[nat_column + 1]
				If fn.Length <> 0
					fnc :+ 1
					g_team_arr01 = g_team_arr01[..fnc]
					g_team_arr01[fnc - 1] = fn
				EndIf
				If ln.Length <> 0
					lnc :+ 1
					g_team_arr02 = g_team_arr02[..lnc]
					g_team_arr02[lnc - 1] = fields[nat_column + 1]
				EndIf
			Wend
			LogLine("first names = " + String(g_team_arr01.Length))
			LogLine("last names = " + String(g_team_arr02.Length))
			CloseStream(a1)
		EndIf
	End Function
