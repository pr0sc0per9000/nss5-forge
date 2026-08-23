' URLDecode  -- module-level Function (no Type). NAME IS OURS (no reflection record).
' VA 0x005085ff   227 bytes   sig ($)$
' byte-identical vs NSS5.exe (227/227, original length from Ghidra's inventory), verified
' with harness.try_function under NSS5_NO_LEARN=1.
'
' The inverse of the already-verified URLEncode (0x005084A8): turns "%XX" back into the
' character it encodes and "+" back into a space, copying everything else through.
'
' NOT CALLED FROM ANYWHERE in the shipped exe (brute scan of every E8/E9 rel32: zero call
' sites), and its own helper ParseHex (0x005086E2) has exactly one caller, this function.
' So the decode half of the web-page code was written and then never wired up, while the
' encode half is live (TScreen_WebPage.GetSocialMessage calls URLEncode). Found by the
' unrecovered-function audit; see docs/reference/unrecovered-inventory.md.
'
' THE STRAY MilliSecs() IS IN THE ORIGINAL. At 0x00508612, before the loop, there is a
' bare `call 0x004A4860` with nothing pushed and the result discarded. 0x004A4860 is
' _bbMilliSecs (a `jmp dword ptr [IAT]` thunk onto timeGetTime; named in
' extracted/brl_functions_inferred.tsv and used by 25 call sites across the exe including
' GameMain and SteamPostPlayerValue). A discarded MilliSecs() is a leftover timing line;
' it is reproduced, not tidied away, and removing it costs 5 bytes and shifts every
' branch displacement after it.
'
' REGISTER IDENTITY, as in URLEncode.bmx: the original keeps the accumulator in ebx and
' the index in esi, and the declaration order below is what assigns them that way.
' String literals used, read from the exe: "%" at 0x00C7C578, "+" at 0x00C79738,
' " " at 0x00C6EF28.
	Function URLDecode:String(a0:String)
		Local i:Int
		Local result:String = ""
		MilliSecs()
		While i < a0.length
			If a0[i..i+1] = "%"
				result :+ Chr(ParseHex(a0[i+1..i+3]))
				i :+ 3
			ElseIf a0[i..i+1] = "+"
				result :+ " "
				i :+ 1
			Else
				result :+ a0[i..i+1]
				i :+ 1
			EndIf
		Wend
		Return result
	End Function
