' TDate.GetString
' VA 0x00536aab   1219 bytes   class-table slot 0x48   sig (i,i)$   KIND=Method
' Formats the date into one of 6 styles (a0 = style 0..5), optionally weekday-prefixed
' (a1 <> 0). Ghidra's decompiled C repeatedly MERGES a callee's real args with the pushes
' of the following call (codegen-patterns.md header warning) -- `Self.GetWeekday(2," ")`
' and `Self.GetStringMonth(mo,style," ",yrStr)` in the decompiled text are NOT real call
' argument lists; the real shapes (confirmed on the raw disassembly, add-esp byte counts)
' are `Self.GetWeekday()` (0 args, sig ()i), `Self.GetStringWeekday(wd, 2)` (sig (i,i)$),
' and `Self.GetStringMonth(mo, style)` (sig (i,i)$) -- the trailing " "/yrStr operands
' belong to the OUTER string-concat chain the call sits inside, not to the callee.
'
' PARAMETERS (ours) a0:Int style, a1:Int showWeekday.
'
' SOURCE FORM
'   `result :+ A + B + C + ...` (codegen-patterns.md 16.1): every case computes the whole
'   RHS chain as one expression, THEN concats onto the accumulator -- confirmed by the
'   final `_bbStringConcat(result, chain)` call sitting AFTER the chain is fully built.
'   Day/month/year are pulled via `Self.GetDate(dy, mo, yr)` (Var Int params). `dayStr`
'   stays a register value (never spilled) and gets REASSIGNED (not re-declared) with a
'   "0" prefix or an ordinal suffix per case -- matching TStadium-family register reuse.
'   The ordinal-suffix block is a `Select dy Mod 10` with a Default ("th") that is the
'   compiled fallthrough immediately after the compares (codegen-patterns.md 10.2), Cases
'   1/2/3 ("st"/"nd"/"rd") as jump targets after it.
'   Case 3's short year is BlitzMax slice syntax `[2..]`, which is exactly what
'   `_bbStringSlice(s, 2, s.length)` compiles from -- but sliced off `yrStr` directly it
'   was 2 bytes long (a spilled Local reloaded twice, once for `.Length` and once for the
'   slice's own base pointer). A fresh one-shot `Local ys:String = yrStr` right before it
'   stays in a register (codegen-patterns.md 16.2, "a String Local consumed by the very
'   next statement costs ZERO bytes") and gets reused for both reads, matching the
'   original's single `mov eax,[...]` followed by a bare `push eax`.
'   The outer `Select a0` itself has no Default (codegen-patterns.md 10.2): an out-of-range
'   style falls straight through to `Return result` with result still "".
'
' ORACLE: mode=reloc  matched=1219/1219  STATUS=MATCH.
Method GetString:String(a0:Int, a1:Int)
	Local result:String = ""
	Local dy:Int = 0
	Local mo:Int = 0
	Local yr:Int = 0
	Self.GetDate(Varptr dy, Varptr mo, Varptr yr)
	Local dayStr:String = String(dy)
	Local moStr:String = String(mo)
	Local yrStr:String = String(yr)
	If mo < 10 Then moStr = "0" + moStr
	Select a0
		Case 0
			If a1 <> 0 Then result = Self.GetStringWeekday(Self.GetWeekday(), 2) + " "
			If dy < 10 Then dayStr = "0" + dayStr
			result :+ dayStr + "-" + moStr + "-" + yrStr
		Case 1
			If a1 <> 0 Then result = Self.GetStringWeekday(Self.GetWeekday(), 2) + " "
			If dy < 10 Then dayStr = "0" + dayStr
			result :+ dayStr + " " + Self.GetStringMonth(mo, 0) + " " + yrStr
		Case 2
			If a1 <> 0 Then result = Self.GetStringWeekday(Self.GetWeekday(), 2) + " "
			Select dy Mod 10
				Case 1
					dayStr :+ "st"
				Case 2
					dayStr :+ "nd"
				Case 3
					dayStr :+ "rd"
				Default
					dayStr :+ "th"
			End Select
			result :+ dayStr + " " + Self.GetStringMonth(mo, 1) + " " + yrStr
		Case 3
			If a1 <> 0 Then result = Self.GetStringWeekday(Self.GetWeekday(), 2) + " "
			If dy < 10 Then dayStr = "0" + dayStr
			Local ys:String = yrStr
			result :+ dayStr + "-" + moStr + "-" + ys[2..]
		Case 4
			If a1 <> 0 Then result = Self.GetStringWeekday(Self.GetWeekday(), 2) + " "
			Select dy Mod 10
				Case 1
					dayStr :+ "st"
				Case 2
					dayStr :+ "nd"
				Case 3
					dayStr :+ "rd"
				Default
					dayStr :+ "th"
			End Select
			result :+ dayStr + " " + Self.GetStringMonth(mo, 0)
		Case 5
			If a1 <> 0 Then result = Self.GetStringWeekday(Self.GetWeekday(), 2) + " "
			If dy < 10 Then dayStr = "0" + dayStr
			result :+ dayStr + " " + Self.GetStringMonth(mo, 0)
	End Select
	Return result
End Method
