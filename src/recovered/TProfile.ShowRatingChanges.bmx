' TProfile.ShowRatingChanges
' VA 0x0056c628   1408 bytes   vtable slot 0x138   sig ()i
' byte-identical vs NSS5.exe (1408/1408, original length from Ghidra's inventory)
'
' Ten near-identical blocks, one per training-attribute delta accumulated during the
' match/week (temp_positioning, temp_shortpassing, temp_longpassing, temp_finishing,
' temp_longshots, temp_crossing, temp_freekicks, temp_corners, temp_penalties,
' temp_aggression -- this exact order, NOT field-declaration order, faithfully
' reproduced). Each block: if the delta is non-zero, pop up a TScreenMessage alert
' showing "<Attribute> +<n>" (or "<Attribute> -<n>" after the sign-fix Replace, since
' "+" concatenated with a negative Int's own leading "-" yields "+-3" -> "-3") in green
' (up arrow icon) or red (down arrow icon) depending on sign.
'
' load-bearing shape (all confirmed against the disassembly byte-for-byte):
'   * `dur:Int = 1500` is a real Local, declared once and referenced in all ten calls --
'     it lives in a register (edi) for the whole function, so every occurrence compiles
'     to a 1-byte `push edi` instead of a 5-byte `push 0x5dc` immediate. Writing 1500 as
'     a bare literal in each call instead costs +4 bytes x10 (tried and ruled out).
'   * the icon choice is a REAL If/Else (`If n>0 img=g_Object864 Else img=g_Object865
'     EndIf`), not "default to g_Object865, override to g_Object864 when positive" --
'     the latter is semantically identical but 8 bytes shorter per block (no `jmp` over
'     an else arm), so all ten blocks come up short (tried and ruled out).
'   * the rating-delta string is built as TWO separate statements before the alert call:
'     `delta = n` (Int -> String, calls _bbStringFromInt) computed first, THEN
'     `raw = GetText(label) + " +" + delta` (GetText + two _bbStringConcat calls).
'     `raw.Replace("+-","-")` is evaluated INLINE as CreateAlert's third argument,
'     between the literal-constant pushes (10 args of positions 4-12, pushed
'     right-to-left ahead of it) and the final `g_engine_int163-60` / `10` pushes --
'     matching the call order FromInt, GetText, Concat, Concat, [literal pushes],
'     Replace, [remaining pushes], CreateAlert seen in the original disassembly.
'     Folding the string build into one expression re-orders the calls and mismatches.
'
' names: 0x004A7AC0 _bbStringFromInt (Int->String, via `delta = n`), 0x004A7C20
'   _bbStringConcat (via "+"), 0x004A75B0 _bbStringReplace (via .Replace), 0x004C5549
'   the recovered module Function GetText(key$):String (ARGUMENT-COUNT WARNING per guide
'   10: Ghidra merges GetText's one real push with the following CreateAlert call's
'   literal-constant pushes; `add esp,4` after the GetText call proves one argument).
'   0x00c6b27c = TScreenMessage+0x48 = CreateAlert(i,i,$,i,$,$,:TImage,i,i,i,i,i)i,
'   called with (10, g_engine_int163-60, raw.Replace("+-","-"), dur, "666666", "FFFFFF",
'   img, 3, 0, 0, 0, 1).
' globals (module Globals, names ours -- auto-numbered since reflection carries none):
'   g_engine_int163 (0x00C6EFE8, TEngine, dword int access) -- vertical stacking offset
'   for these alerts; g_Object864 (0x00C6F1DC), g_Object865 (0x00C6F208) -- TProfile
'   Globals, init=bbNullObject at startup, the up/down rating-arrow TImages.
' fields: temp_positioning +0x200, temp_shortpassing +0x204, temp_longpassing +0x208,
'   temp_finishing +0x214, temp_longshots +0x210, temp_crossing +0x1F4, temp_freekicks
'   +0x1F8, temp_corners +0x1FC, temp_penalties +0x218, temp_aggression +0x20C.
	Method ShowRatingChanges:Int()
		'!Global g_engine_int163:Int
		'!Global g_Object864:TImage
		'!Global g_Object865:TImage
		Local dur:Int = 1500
		Local n:Int
		Local img:TImage
		Local delta:String
		Local raw:String
		n = Self.temp_positioning
		If n <> 0
			If n > 0
				img = g_Object864
			Else
				img = g_Object865
			EndIf
			delta = n
			raw = GetText("Positioning") + " +" + delta
			TScreenMessage.CreateAlert(10, g_engine_int163 - 60, raw.Replace("+-", "-"), dur, "666666", "FFFFFF", img, 3, 0, 0, 0, 1)
		EndIf
		n = Self.temp_shortpassing
		If n <> 0
			If n > 0
				img = g_Object864
			Else
				img = g_Object865
			EndIf
			delta = n
			raw = GetText("Short Passing") + " +" + delta
			TScreenMessage.CreateAlert(10, g_engine_int163 - 60, raw.Replace("+-", "-"), dur, "666666", "FFFFFF", img, 3, 0, 0, 0, 1)
		EndIf
		n = Self.temp_longpassing
		If n <> 0
			If n > 0
				img = g_Object864
			Else
				img = g_Object865
			EndIf
			delta = n
			raw = GetText("Long Passing") + " +" + delta
			TScreenMessage.CreateAlert(10, g_engine_int163 - 60, raw.Replace("+-", "-"), dur, "666666", "FFFFFF", img, 3, 0, 0, 0, 1)
		EndIf
		n = Self.temp_finishing
		If n <> 0
			If n > 0
				img = g_Object864
			Else
				img = g_Object865
			EndIf
			delta = n
			raw = GetText("Finishing") + " +" + delta
			TScreenMessage.CreateAlert(10, g_engine_int163 - 60, raw.Replace("+-", "-"), dur, "666666", "FFFFFF", img, 3, 0, 0, 0, 1)
		EndIf
		n = Self.temp_longshots
		If n <> 0
			If n > 0
				img = g_Object864
			Else
				img = g_Object865
			EndIf
			delta = n
			raw = GetText("Long Shots") + " +" + delta
			TScreenMessage.CreateAlert(10, g_engine_int163 - 60, raw.Replace("+-", "-"), dur, "666666", "FFFFFF", img, 3, 0, 0, 0, 1)
		EndIf
		n = Self.temp_crossing
		If n <> 0
			If n > 0
				img = g_Object864
			Else
				img = g_Object865
			EndIf
			delta = n
			raw = GetText("Crossing") + " +" + delta
			TScreenMessage.CreateAlert(10, g_engine_int163 - 60, raw.Replace("+-", "-"), dur, "666666", "FFFFFF", img, 3, 0, 0, 0, 1)
		EndIf
		n = Self.temp_freekicks
		If n <> 0
			If n > 0
				img = g_Object864
			Else
				img = g_Object865
			EndIf
			delta = n
			raw = GetText("Free Kicks") + " +" + delta
			TScreenMessage.CreateAlert(10, g_engine_int163 - 60, raw.Replace("+-", "-"), dur, "666666", "FFFFFF", img, 3, 0, 0, 0, 1)
		EndIf
		n = Self.temp_corners
		If n <> 0
			If n > 0
				img = g_Object864
			Else
				img = g_Object865
			EndIf
			delta = n
			raw = GetText("Corners") + " +" + delta
			TScreenMessage.CreateAlert(10, g_engine_int163 - 60, raw.Replace("+-", "-"), dur, "666666", "FFFFFF", img, 3, 0, 0, 0, 1)
		EndIf
		n = Self.temp_penalties
		If n <> 0
			If n > 0
				img = g_Object864
			Else
				img = g_Object865
			EndIf
			delta = n
			raw = GetText("Penalties") + " +" + delta
			TScreenMessage.CreateAlert(10, g_engine_int163 - 60, raw.Replace("+-", "-"), dur, "666666", "FFFFFF", img, 3, 0, 0, 0, 1)
		EndIf
		n = Self.temp_aggression
		If n <> 0
			If n > 0
				img = g_Object864
			Else
				img = g_Object865
			EndIf
			delta = n
			raw = GetText("Aggression") + " +" + delta
			TScreenMessage.CreateAlert(10, g_engine_int163 - 60, raw.Replace("+-", "-"), dur, "666666", "FFFFFF", img, 3, 0, 0, 0, 1)
		EndIf
	End Method
