' TProfile.GetStringStat
' VA 0x0056962D   741 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Method, SIG (i,i,i,i,i)$, slot 0x8c
' ASSUMPTIONS
'  * No module Globals are touched.
'  * The outer test is `a0 <> 16` -- the `je` at 0x0056964B jumps FORWARD to the
'    stat-16 handler, so that arm is the ELSE.
'  * The `push edi` at 0x00569652 belongs to FormatDecimals, not to GetStat:
'    `add esp,0x14` after the GetStat call pops only its own five slots.
'  * 0x00C8E8CC is the BBArray element descriptor for String (`New String[5]`);
'    0x00C8E8D0 is the Float constant 10.0.
'  * `arr[4] = v` relies on BlitzMax's implicit Int->String conversion; that is what
'    emits _bbStringFromInt at 0x005697A3.
'  * `s[1..s.Length]` is _bbStringSlice(s, 1, s.Length); the trailing loop strips
'    leading "-" separators left by empty slots.
'  * The "-" literal read out of NSS5.exe.

Method GetStringStat:String(a0:Int, a1:Int, a2:Int, a3:Int, a4:Int)
	If a0 <> 16
		If a4 > 0
			Return FormatDecimals(Self.GetStat(a0, a1, a2, a3), a4)
		Else
			Return GroupDigits(Int(Self.GetStat(a0, a1, a2, a3)))
		End If
	Else
		Local lst:TList = Self.GetStats(a1, a2, a3)
		Local arr:String[] = New String[5]
		For Local st:TStats_Team = EachIn lst
			For Local v:Int = EachIn st.form
				arr[0] = arr[1]
				arr[1] = arr[2]
				arr[2] = arr[3]
				arr[3] = arr[4]
				arr[4] = v
			Next
		Next
		For Local i:Int = 0 To 4
			If arr[i].ToFloat() > 0
				arr[i] = FormatDecimals(arr[i].ToFloat() / 10.0, 0)
			End If
		Next
		Local s:String = arr[0] + "-" + arr[1] + "-" + arr[2] + "-" + arr[3] + "-" + arr[4]
		While s.Length > 0 And Left(s, 1) = "-"
			s = s[1..s.Length]
		Wend
		Return s
	End If
End Method
