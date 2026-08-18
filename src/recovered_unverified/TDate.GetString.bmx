' TDate.GetString  -- UPDATED: adopted the structure of the byte-perfect sibling
' src/recovered/TDate.GetString.bmx, which turns out to be this exact same function
' (same VA 0x00536AAB, same vtable slot 0x48, same sig (i,i)$, ORACLE matched=1219/1219
' STATUS=MATCH). Previous score for this file was 982/1219 (80.6%), first difference at
' byte 18 -- the very first emitted instruction, `mov [ebp-0x14],&PTR_PTR_005c7d40` (the
' vtable pointer stored when `Local result:String = ""` is initialised): our old body was
' emitting a different pointer, which means the local layout/initializer shape it produced
' diverged from the original from the first statement on.
'
' CHANGES MADE (bringing this body in line with the proven-correct sibling):
'   * `result = result + (...)` -> `result :+ ...` (compound assign, no extra Local reload
'     for the RHS-concat-then-full-reassign shape the old body used).
'   * Locals `day/month/year` now initialised `= 0` at declaration (matches source form
'     that yields the exact vtable-pointer immediate at function entry).
'   * Case 3's `yearStr[2..]` is preceded by a fresh one-shot `Local ys:String = yrStr`
'     right before the slice, which stays in a register and gets reused for both the
'     `.Length` read and the slice's base pointer -- this is what makes the final `push`
'     compile to a bare `push eax` (`50`) instead of reloading yrStr from its spilled slot
'     (`FF 75 E8`), the one gap a previous pass on this file identified but could not close
'     with an in-place rewrite of yrStr itself.
'   * Method calls qualified with `Self.` to match the sibling's exact source form.
'
' VA 0x00536aab   1219 bytes   class-table slot 0x48   sig (i,i)$   KIND=Method
' Formats the date into one of 6 styles (a0 = style 0..5), optionally weekday-prefixed
' (a1 <> 0). Ghidra's decompiled C repeatedly MERGES a callee's real args with the pushes
' of the following call -- `Self.GetStringWeekday(...)`/`Self.GetStringMonth(...)` in the
' decompiled text are NOT the real call argument lists; the real shapes are
' `Self.GetWeekday()` (0 args, sig ()i), `Self.GetStringWeekday(wd, 2)` (sig (i,i)$), and
' `Self.GetStringMonth(mo, style)` (sig (i,i)$) -- the trailing " "/yrStr operands belong to
' the OUTER string-concat chain the call sits inside, not to the callee.
'
' Globals: none. Callees, all already recovered and named:
'   Self.GetDate(day Var, month Var, year Var)  -- slot 0x44
'   Self.GetWeekday()                            -- slot 0x50
'   Self.GetStringWeekday(weekday, truncLen)      -- slot 0x58 (Function, same-Type call)
'   Self.GetStringMonth(month, fullName)          -- slot 0x5c (Function, same-Type call)
'
Method GetString:String(a0:Int, a1:Int)
	Local result:String = ""
	Local day:Int = 0
	Local month:Int = 0
	Local year:Int = 0
	Self.GetDate(Varptr day, Varptr month, Varptr year)
	Local dayStr:String = String(day)
	Local monthStr:String = String(month)
	Local yearStr:String = String(year)
	If month < 10 Then monthStr = "0" + monthStr
	Select a0
		Case 0
			If a1 <> 0 Then result = Self.GetStringWeekday(Self.GetWeekday(), 2) + " "
			If day < 10 Then dayStr = "0" + dayStr
			result :+ dayStr + "-" + monthStr + "-" + yearStr
		Case 1
			If a1 <> 0 Then result = Self.GetStringWeekday(Self.GetWeekday(), 2) + " "
			If day < 10 Then dayStr = "0" + dayStr
			result :+ dayStr + " " + Self.GetStringMonth(month, 0) + " " + yearStr
		Case 2
			If a1 <> 0 Then result = Self.GetStringWeekday(Self.GetWeekday(), 2) + " "
			Select day Mod 10
				Case 1
					dayStr :+ "st"
				Case 2
					dayStr :+ "nd"
				Case 3
					dayStr :+ "rd"
				Default
					dayStr :+ "th"
			End Select
			result :+ dayStr + " " + Self.GetStringMonth(month, 1) + " " + yearStr
		Case 3
			If a1 <> 0 Then result = Self.GetStringWeekday(Self.GetWeekday(), 2) + " "
			If day < 10 Then dayStr = "0" + dayStr
			Local ys:String = yearStr
			result :+ dayStr + "-" + monthStr + "-" + ys[2..]
		Case 4
			If a1 <> 0 Then result = Self.GetStringWeekday(Self.GetWeekday(), 2) + " "
			Select day Mod 10
				Case 1
					dayStr :+ "st"
				Case 2
					dayStr :+ "nd"
				Case 3
					dayStr :+ "rd"
				Default
					dayStr :+ "th"
			End Select
			result :+ dayStr + " " + Self.GetStringMonth(month, 0)
		Case 5
			If a1 <> 0 Then result = Self.GetStringWeekday(Self.GetWeekday(), 2) + " "
			If day < 10 Then dayStr = "0" + dayStr
			result :+ dayStr + " " + Self.GetStringMonth(month, 0)
	End Select
	Return result
End Method
