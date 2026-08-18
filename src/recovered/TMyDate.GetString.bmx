' TMyDate.GetString
' VA 0x005375d6   947 bytes   vtable slot 0x5c   sig ($)$   (a0 = the format string)
' byte-identical vs NSS5.exe (947/947, harness mode=reloc)
'
' A date formatter: the format is split on "-" and each token replaced.
' RESOLVED CALLS
'   TMyDate slots 0x4c GetDay, 0x50 GetWeek, 0x54 GetYear, 0x58 GetStringDay(i)$
'   0x005062B7 SplitString2($,$)[]$   0x004C5549 GetText($)$   (both recovered_module)
'   _bbStringFromInt / _bbStringConcat / _bbStringSlice / _bbStringCompare are implicit.
' string literals all read out of NSS5.exe with harness.read_string:
'   "-" "" " " "YYYY" "YYY" "YY" "Y" "WWWW" "WWW" "WW" "W" "DDDD" "DDD" "DD" "D"
'   "Year" "tla_Year" "Week" "tla_Week"
'
' TWO SOURCE FORMS THAT LOOK IDENTICAL AND ARE NOT (both 947 bytes, diff at +89):
'   the collection is a NAMED Local, not the call written inline in the For header.
'     Local parts:String[] = SplitString2(a0, "-")   ->  call ; mov [i],0 ; mov [parts],eax
'     For ... EachIn SplitString2(a0, "-")           ->  mov [i],0 ; call ; mov [temp],eax
'   i.e. binding the array to a Local lets `Local i:Int = 0` be emitted between the call and
'   the store. `Local i:Int` with no initialiser emits the same store, so that is not it.
' The token dispatch is a SELECT (10.2) -- twelve back-to-back _bbStringCompare tests, then
' a `jmp` for the no-match path, then the twelve bodies.
' Each body is `s :+ ...` (16.1): _bbStringConcat(acc, <rhs>) is emitted LAST in every case.
	Method GetString:String(a0:String)
		Local s:String = ""
		Local sy:String = Self.GetYear()
		Local sw:String = Self.GetWeek()
		Local sd:String = Self.GetDay()
		Local parts:String[] = SplitString2(a0, "-")
		Local i:Int = 0
		For Local f:String = EachIn parts
			If i > 0
				s :+ " "
			EndIf
			Select f
			Case "YYYY"
				s :+ GetText("Year") + " " + sy
			Case "YYY"
				s :+ GetText("tla_Year") + " " + sy
			Case "YY"
				s :+ GetText("Year")[0..1] + sy
			Case "Y"
				s :+ sy
			Case "WWWW"
				s :+ GetText("Week") + " " + sw
			Case "WWW"
				s :+ GetText("tla_Week") + " " + sw
			Case "WW"
				s :+ GetText("Week")[0..1] + sw
			Case "W"
				s :+ sw
			Case "DDDD"
				s :+ Self.GetStringDay(0)
			Case "DDD"
				s :+ Self.GetStringDay(3)
			Case "DD"
				s :+ Self.GetStringDay(2)
			Case "D"
				s :+ sd
			End Select
			i :+ 1
		Next
		Return s
	End Method
