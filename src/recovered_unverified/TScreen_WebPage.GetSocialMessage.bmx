' TScreen_WebPage.GetSocialMessage
' VA 0x0056142A   173 bytes   vtable slot 0x44   sig (i)$   KIND=Function
' byte-identical vs NSS5.exe
' Body-only format: statements only; sole parameter is a0:Int (0 = Facebook, 1 = Twitter --
' TScreen_WebPage.ButtonFacebook/ButtonTwitter call this function through the shared
' function-pointer PTR_FUN_00c689fc with literal 0 / 1 respectively).
'
' Builds the text shared to Facebook/Twitter from the current webpage headline: strips any
' '"' characters from it, then either wraps it verbatim (Facebook) or truncates it at the
' first sentence (or 113 chars, whichever comes first) before wrapping with a different
' prefix (Twitter), then URL-encodes the whole thing before returning it.
'
' Verified statement-by-statement against harness.disasm_original(0x0056142a, n=173) (full
' raw disassembly), not just the Ghidra C -- this resolved the cdecl push order (source is
' pushed LAST/closest to `call`, i.e. is the FIRST call argument) and confirmed the
' "GHIDRA MERGES ARGUMENT LISTS" trap applies twice here: each 3-operand FUN_004a7c20 line
' in the decompilation is really two back-to-back 2-arg concat calls, the second one's
' trailing operand having been pushed early and left on the stack across the first call
' (`add esp,8` only pops the first call's own two operands). Same shape as
' TProfile.GetHashtaglessName's chained `.Replace().Replace()`.
'
' BRANCH ORDER (fixed this pass): the raw disassembly's `cmp esi,0 / je <label>` puts the
' TWITTER body (Find/Left) as the FALL-THROUGH and the FACEBOOK body (plain wrap) at the jump
' target reached only when a0=0. That is the compiled shape of `If a0 <> 0 Then <Twitter>
' Else <Facebook> End If`, NOT `If a0 = 0 Then <Facebook> Else <Twitter> End If` -- the two
' read the same truth table (their branches are also swapped) but compile to opposite
' fall-through/jump-target layouts, which is byte-visible even though behaviourally identical.
' A prior draft had the condition and branches inverted; this pass matches the disassembly's
' physical block order instead of just its logical outcome.
'
' ASSUMPTIONS
'  * g_webpage_headline:String (0x00C68904) -- STRONG/CERTAIN per explain_global.py, sole
'    declarer TScreen_WebPage.SetUpScreen (`push dword ptr [0xc68904]` loads the Global's
'    current value directly, not its address -- confirms String-holding-a-pointer, matching
'    explain_global.py's type). Older notes used g_webpage_socialtext or, per
'    globals_final.tsv, g_screen_webpage_int02:Int for this same address -- both are rejected;
'    per project convention explain_global.py's STRONG-tier name/type is authoritative.
'  * FUN_004a75b0 = _bbStringReplace(source, search, replace) -- runtime_helpers.tsv,
'    confirmed sibling TProfile.GetHashtaglessName.
'  * FUN_004a6b60 = _bbStringFind(source, search, start) -- runtime_helpers.tsv, 10+
'    witnesses.
'  * FUN_0059c843 = _brl_retro_Left(text, n) -- runtime_helpers.tsv; this exact call site's
'    literal argument (0x71 = 113) is in extracted/callgraph/callgraph_callargs.tsv.
'  * FUN_004a7c20 = _bbStringConcat(a, b) -- runtime_helpers.tsv, confirmed sibling
'    TProfile.GetCurrentTip / TScreen_ContinentalComps.ButtonEditPlaceComp.
'  * FUN_005084a8 -- module-level Function, NOT present in src/recovered_module (no
'    reflection record for an unexported module Function; confirmed blocked across
'    across the corpus). The project's working candidate for its identity
'    is src/recovered_module/URLEncode.bmx, sig ($,i,i)$: URLEncode(s, a1, a2) percent-
'    encodes s (a1<>0 forces every non-reserved char encoded; a2<>0 encodes space as "+"
'    instead of "%20"). Referenced here by that name, called URLEncode(msg, 0, 0) -- disasm
'    confirms args (msg, 0, 0) in that order (msg pushed last/closest to `call`). This call
'    is a TAIL CALL: eax from it is never touched again before the function's epilogue, so
'    its return value IS this function's return value -- hence `Return URLEncode(...)`
'    rather than an intermediate Local, matching TProfile.GetCurrentTip's
'    `Return GetText(...)` precedent.
'  * String literals read directly from the image with harness.read_string() (0x00C5D284 is
'    a zero-length BBString, i.e. "" -- read_string's `0 < ln` guard returns None for it, but
'    the raw header at that offset confirms length=0):
'      0x00C8D450 = ~q                       (search, the Replace call)
'      0x00C5D284 = ""                       (replace, the Replace call)
'      0x00C7BBC4 = "."                      (Find needle, Twitter branch)
'      0x00C8D4B0 = "NSS5 News! "            (Facebook prefix)
'      0x00C8D498 = "#NSS5 "                 (Twitter prefix)
'      0x00C8D460 = " http://bit.ly/jokTnJ"  (shared suffix, both branches)
'    Matches docs/game/career/achievements-and-news.md's independent read of this function.
'!Global g_webpage_headline:String
Local msg:String = g_webpage_headline.Replace("~q", "")
If a0 <> 0
	Local p:Int = msg.Find(".")
	If p < 113
		msg = Left(msg, p + 1)
	Else
		msg = Left(msg, 113)
	End If
	msg = "#NSS5 " + msg + " http://bit.ly/jokTnJ"
Else
	msg = "NSS5 News! " + msg + " http://bit.ly/jokTnJ"
End If
Return URLEncode(msg, 0, 0)
