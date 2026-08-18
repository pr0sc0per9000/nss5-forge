' TScreen_MainMenu.UpdateReplayTable  -- KIND=Function (static), slot 0x5c, sig ()i
' VA 0x0051D6D9   287 bytes
' byte-identical vs NSS5.exe (287/287, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=25)
'
' ASSUMPTIONS
'  * Globals (names ours; declared types are load-bearing):
'      0x00C639E4 -> g_replaytable:TTable   -- slots 0x9C ClearItems, 0x94 AddItem,
'                                              0xEC CountItems, 0xDC SelectItemByRow all
'                                              resolve against TTable in vtable_map.tsv.
'                                              globals_final.tsv guesses TPlayer at 'low'
'                                              confidence with the note "one of
'                                              {TCompetition|TEngine|TPlayer|TProfile|
'                                              TTable}" -- TTable is the only member whose
'                                              four slots all exist with these arities.
'      0x00C6E9A8 -> g_userpath:String      -- pushed by value into _bbStringConcat, so it
'                                              is a reference, not the Int the table says.
'  * Runtime helpers: 0x004A7C20 _bbStringConcat, 0x004A6A30 _bbStringCompare,
'    0x004A63D0 _bbArrayNew1D, 0x004A75B0 _bbStringReplace.
'  * BRL: 0x005B63CC ReadDir, 0x005B6410 NextFile (alias set -- ReadDir/CloseDir either
'    side settle it), 0x005B6425 CloseDir (alias set), 0x0059C866 Right.
'  * `Right(f,4)` is a TWO-argument call: the third push Ghidra shows belongs to the
'    following _bbStringCompare (`add esp,8` after each proves the split).
'  * The two-element array is an ARRAY LITERAL, not a Local: the receiver is loaded into
'    esi *before* _bbArrayNew1D, which only happens when the whole AddItem call is one
'    expression.
'  * AddItem's trailing two String arguments are bbEmptyString (0x005C7D40) in the
'    original -- i.e. defaulted parameters. Written here as explicit "" literals; both are
'    in-image data addresses so the operand is relocation-masked either way.
'  * Loop form is Repeat/Forever with an explicit `Exit`, NOT `Until f = ""`.
'    `Until` emits a bare `0F 85 rel32` back-branch (284 bytes); the original has
'    `75 02 / EB 05 / E9 rel32`, which is a conditional Exit followed by the Forever jump.
'    That difference is exactly the missing 3 bytes.
	Function UpdateReplayTable:Int()
		'!Global g_replaytable:TTable
		'!Global g_userpath:String
		LogLine("UpdateReplayTable")
		g_replaytable.ClearItems()
		Local dir:Int = ReadDir(g_userpath + "Replays/")
		Local f:String
		Repeat
			f = NextFile(dir)
			If Right(f, 4) = ".rep"
				g_replaytable.AddItem([f.Replace(".rep", ""), ""], "", "")
			End If
			If f = "" Then Exit
		Forever
		CloseDir(dir)
		If g_replaytable.CountItems() <> 0
			g_replaytable.SelectItemByRow(1)
		End If
	End Function
