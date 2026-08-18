' TReplay.LoadReplayFile  -- KIND=Function (static), sig ($):TReplay, slot 0x34
' VA 0x0050420F   575 bytes
' byte-identical vs NSS5.exe (575/575, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=31)
'
' TABLE CORRECTION -- extracted/brl_functions.tsv row for 0x005B963C was WRONG.
'   It named the VA `_brl_blitz_NullMethodError` (0 args). The original call site here
'   pushes exactly 1 arg (`add esp,4` after) into it, and the callee's own bytes at
'   0x005B963C read `mov eax,[ebp+8] / push eax / call [TRuntimeException.Create] /
'   push eax / call bbExThrow` -- byte-for-byte the compiled body of
'   `tools/blitzmax-legacy-src/mod/brl.mod/blitz.mod/blitz.bmx`'s `RuntimeError(message$)`,
'   not the 0-arg `NullMethodError()` (which never reads a parameter at all). Both stubs
'   happen to compile to 36 bytes, which is almost certainly how name_brl.py's byte-match
'   picked the wrong one. Independently corroborated by extracted/callgraph_resolved.tsv
'   line "0x005b963c 0x005b9643 static ... TRuntimeException.Create ... high" already
'   present in the corpus. Corrected the row to `_brl_blitz_RuntimeError` (same VA, same
'   archive, same size) -- no currently-banked body referenced the old name (grepped
'   src/recovered* clean before editing), so this is a pure fix with no blast radius.
'
' ASSUMPTIONS
'   '!Global g_screen_mainmenu_int26:String  = 0x00C6E9A8
'     globals_final.tsv types this Int ("dword int access, 3 writes", medium confidence).
'     That is wrong for THIS call site: the value is pushed directly as a String operand
'     into 4 chained _bbStringConcat calls with no Int->String conversion call inserted
'     anywhere, so the declared type must be String here (guide 10.7 -- trust the code
'     over the table). Left the module name unchanged pending a full re-audit of its other
'     3 write sites elsewhere in the corpus.
'   Fields: TReplay.name @0x8, .ballframes @0x4c, .playerframes @0x50,
'     .matchstateframes @0x54 (object_model.json). TReplayFrame.obtype @0x10.
'   Calls: OpenStream (defaults readable/writeable=True), RuntimeError(msg$),
'     `New TReplay` (bcc inlines the trivial default constructor at a direct-typed `New`
'     site -- no call to TReplay.New (VA 0x00503A0A) appears in the original), TList
'     `.Clear()` (slot 0x34), `.AddLast()` (slot 0x44), module Function `CreateList()`
'     (BRL.LinkedList, an alias set with TGNetHost.Create/CreateMap -- 0-arg wrapper
'     around `New TList`; writing `New TList` directly costs 5 bytes/site because the
'     classtable literal is pushed by the CALLER instead of baked into the callee),
'     `TReplayFrame.LoadFrame(stream)` (ct call, static Function), `Eof(stream)` (the
'     free Function form, NOT `stream.Eof()` -- guide 3h/10.6, direct E8 not virtual
'     dispatch), `stream.Close()` (virtual, slot 0x44 on the concrete stream Type).
'   `If Not stream` / `If Not rep.ballframes` (etc.) use the LONG null-test emission
'     (`cmp/setne/movzx/cmp/jne`, guide 10.3) -- writing the equivalent `If stream = Null`
'     / `If rep.ballframes = Null` costs 9-10 bytes per test on the SHORT form instead;
'     confirmed by localise_diff.py isolating exactly these 4 gaps (1 at the open-check,
'     3 at the three list-recreate checks) before the fix, each closing to 0 after.
'   The url argument to OpenStream is built INLINE (not through an intermediate `Local
'     path:String =`) -- OpenStream's two default Int args (readable/writeable) are
'     pushed BEFORE the url expression evaluates (cdecl right-to-left argument order), so
'     hoisting the concat chain into its own statement moves those two pushes to the
'     wrong place in the byte stream even though the net argument values are identical.
'   ORIGINAL BUG: none noted. The frame classification is a genuinely symmetric map
'     (obtype -3/+1 -> ballframes, -2/+2 -> playerframes, -1/+3 -> matchstateframes is
'     NOT symmetric -- transcribed exactly as decompiled, not "fixed" into a cleaner
'     pattern).
'!Global g_screen_mainmenu_int26:String
Local stream:TStream = OpenStream("zipe::" + g_screen_mainmenu_int26 + "Replays/" + a0 + "::newstarsoccerfivereplayfile")
If Not stream
	RuntimeError("Could not load:" + a0)
	Return Null
Else
	Local rep:TReplay = New TReplay
	rep.name = a0
	rep.ReadHeader(stream)
	If rep.ballframes <> Null Then rep.ballframes.Clear()
	If rep.playerframes <> Null Then rep.playerframes.Clear()
	If rep.matchstateframes <> Null Then rep.matchstateframes.Clear()
	If Not rep.ballframes Then rep.ballframes = CreateList()
	If Not rep.playerframes Then rep.playerframes = CreateList()
	If Not rep.matchstateframes Then rep.matchstateframes = CreateList()
	While Not Eof(stream)
		Local frm:TReplayFrame = TReplayFrame.LoadFrame(stream)
		Select frm.obtype
			Case -3
				rep.matchstateframes.AddLast(frm)
			Case -2
				rep.playerframes.AddLast(frm)
			Case -1
				rep.ballframes.AddLast(frm)
			Case 1
				rep.ballframes.AddLast(frm)
			Case 2
				rep.playerframes.AddLast(frm)
			Case 3
				rep.matchstateframes.AddLast(frm)
		End Select
	Wend
	stream.Close()
	Return rep
EndIf
