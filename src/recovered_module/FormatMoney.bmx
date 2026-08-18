' FormatMoney  -- module-level Function (no Type)
' VA 0x0050720b   617 bytes   sig (i,i)$   ** gates 18 work-set functions, 44 callers **
'
' byte-identical vs NSS5.exe (617/617, original length from Ghidra's inventory)
' harness mode=reloc, reloc_masked=57, NSS5_NO_LEARN=1, no learned helpers.
' Re-certified after the table row below was corrected on disk.
'
' WORKED EXAMPLE for codegen-patterns 3b/15.5. With `s.Contains(".")` this body reports
' MISMATCH at exactly the 4-byte operand of the two `call 0x004A6BF0` sites (first_diff 303),
' byte-identical everywhere else and the same length, whenever
' `extracted/runtime_helpers.tsv` names 0x004A6BF0 `_bbStringStartsWith`. It is
' `_bbStringContains`. Proof, three ways:
'   1. 0x004A6BF0 is 44 bytes and makes exactly ONE call -- to 0x004A6B60 (_bbStringFind,
'      already in the table) with a third argument of 0 -- then `inc eax / setne al`.
'      That is literally bbStringContains: `return bbStringFind(x,y,0)!=-1;`
'      (tools/blitzmax-legacy-src/mod/brl.mod/blitz.mod/blitz_string.c:265).
'   2. bbStringStartsWith and bbStringEndsWith are call-free loops in that same file, so
'      neither can be a function that makes a call.
'   3. The real ones are at 0x004A6AA0 (StartsWith -- compares from x->buf) and 0x004A6B00
'      (EndsWith -- indexes x->buf + x->length - y->length), both call-free, both 4 callers.
' With the row right, this file certifies as written and the StartsWith spelling is
' correctly rejected. This is codegen-patterns 3b exactly: a wrong table entry masks by NAME
' and hides a real difference.
'
' Semantics settle it independently: `s` here is a rendered number like "1.5", so
' StartsWith(".") is never true and both While loops would be dead code. Contains(".") makes
' them do their job -- thousands are trimmed to a whole number, millions keep one decimal.
'
' NAME AND GLOBAL NAME ARE OURS. Builds the string with "$" as a PLACEHOLDER, repairs the
' sign position ("$-" -> "-$"), then substitutes the real symbol last -- which is why "$"
' appears in every arm regardless of currency. All six literals were read out of the exe
' with harness.read_string (codegen-patterns 13.2); 0x00C7BCD4 is U+00A3 POUND SIGN and
' 0x00C7BCE8 is U+20AC EURO SIGN. 0.62 / 0.70 / 1000.0 / 1000000.0 are float literals in
' this function's own literal pool, not Globals.
'
' `Case 1` really does have an empty body (0x00507235: EB 42, jumping where the no-match
' path goes) -- currency 1 is the base currency and needs no conversion. The Select has no
' Default. Locals are declared s-then-sym on purpose: that order is what puts sym in ebx and
' a1/s in esi, matching the original's allocation. Declared the other way round the body is
' still 617 bytes but every ebx/esi is swapped.
'
' ASSUMPTION: 0x00C5D274 g_currency:Int -- globals_final says Int, medium, 7 writes.
'!Global g_currency:Int
	Function FormatMoney:String(a0:Int, a1:Int)
		Local s:String
		Local sym:String = "$"
		Select g_currency
			Case 1
			Case 2
				sym = "£"
				a0 = Int(a0 * 0.62)
			Case 3
				sym = "€"
				a0 = Int(a0 * 0.70)
		End Select
		Local amt:Float = a0
		If a1 = 0
			s = "$" + GroupDigits(a0)
			Return s.Replace("$-", "-$").Replace("$", sym)
		ElseIf a0 < 1000
			Return ("$" + String(a0)).Replace("$", sym)
		ElseIf a0 < 1000000
			s = FormatDecimals(amt / 1000.0, 1)
			While s.Contains(".")
				s = s[..s.Length - 1]
			Wend
			s = "$" + s + GetText("sla_Thousand")
			Return s.Replace("$-", "-$").Replace("$", sym)
		Else
			s = FormatDecimals(amt / 1000000.0, 1)
			While s.Contains(".") And (Right(s, 1) = "0" Or Right(s, 1) = ".")
				s = s[..s.Length - 1]
			Wend
			s = "$" + s + GetText("sla_Million")
			Return s.Replace("$-", "-$").Replace("$", sym)
		End If
	End Function
