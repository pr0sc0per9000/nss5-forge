' TScreen_Calendar.SetUpScreen
' VA 0x00536660   423 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, class-table slot 0x34   (reloc_masked=15)
' ASSUMPTIONS
'   '!Global g_curscreen:TScreen -- 0x00C61700 (globals_final: Object, no call-site
'     typing). Only its +0x08 field is touched, which is TScreen.name:String.
'   '!Global g_calendar_prevname:String -- 0x00C65E30. globals_final says Int; the store
'     is a full retain/release pair, so it holds a reference (11.2).
'   '!Global g_calendar_table:TTable -- 0x00C65E34, flagged CONFLICT TButton=1;TTable=1.
'     Slots 0x9C = ClearItems and 0x94 = AddItem([]$,$,$) are TTable's.
'   TDate: gDate +0x08 i, slot 0x30 Create(i,i,i), slot 0x48 GetString(i,i)$.
'   String literals: 0x00C84C84 "calendar", 0x005C7D40 / 0x00C5D284 "".
' SHAPE NOTES
'   * the eight cells are String LOCALS, not inline expressions: the original stores each
'     GetString result into a stack slot with NO retain and only retains at the array
'     store, and the `add [esi+8],1` statements interleave between them -- which a single
'     array-literal expression could not contain.
'   * the row itself IS an array literal: bbArrayNew1D(8) followed by eight bare
'     `mov [ebx+0x18+4n]` with no bounds check.
'   * `To 52` -- cmp 0x35 / jl is what `Until 53` would give; the original's is the
'     Ghidra-normalised `< 0x35`, and To/jle is what matched.
	Function SetUpScreen:Int()
		'!Global g_curscreen:TScreen
		'!Global g_calendar_prevname:String
		'!Global g_calendar_table:TTable
		g_calendar_prevname = g_curscreen.name
		TScreen.SetActive("calendar", "")
		g_calendar_table.ClearItems()
		Local d:TDate = TDate.Create(8, 7, 2001)
		For Local i:Int = 1 To 52
			Local s0:String = String(i)
			Local s1:String = d.GetString(5, 0)
			d.gDate = d.gDate + 1
			Local s2:String = d.GetString(5, 0)
			d.gDate = d.gDate + 1
			Local s3:String = d.GetString(5, 0)
			d.gDate = d.gDate + 1
			Local s4:String = d.GetString(5, 0)
			d.gDate = d.gDate + 1
			Local s5:String = d.GetString(5, 0)
			d.gDate = d.gDate + 1
			Local s6:String = d.GetString(5, 0)
			d.gDate = d.gDate + 1
			Local s7:String = d.GetString(5, 0)
			d.gDate = d.gDate + 1
			g_calendar_table.AddItem([s0, s1, s2, s3, s4, s5, s6, s7], "", "")
		Next
	End Function
