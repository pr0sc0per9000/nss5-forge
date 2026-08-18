' Fn_00595EF3 -- NOT VERIFIED (near miss, our_len=235 vs orig_len=210; delta +25)
' VA 0x00595EF3   orig 210 bytes (Ghidra inventory).  KIND=Function, module-level (no Self).
' Unattributed "code" function, not in vtable_map.tsv -- name is OURS, not a recovered
' original name (skill section 8). Verified via harness.try_function.
'
' CONTEXT: the "abandoned engine hook" pair. This is the callee of 0x00596AFF (the module
' body's dead branch, called
' directly from the real module program at body offset 6778). 0x00596AFF's byte-exact
' source cannot be written until this one MATCHes, per the same E8-name-mask rule as
' every other body in the project.
'
' SEMANTICS (Ghidra decompile, this session, headless read-only):
'   Parses a double-null-terminated list of null-terminated byte strings (classic Win32
'   REG_MULTI_SZ shape) into a String[], via an unassigned Function-typed module Global
'   (the "hook"). Confirmed structure:
'     Local p:Byte Ptr = g_hookFn(0, 0x1005)
'     If p is Null -> return the canonical empty String array (see THE GAP below)
'     Else: allocate String[100], for each null-terminated run (strlen via inline loop,
'       String.FromBytes(p, len), advance p past the run + its terminator, up to 100
'       entries or an empty run), then Return array[..count]
'
' CALL-TARGET IDENTIFICATION, new this session:
'   0x004A7910 = _bbStringFromBytes(p:Byte Ptr, n:Int) -- CONFIRMED by structural match
'     against tools/blitzmax-legacy-src/mod/brl.mod/blitz.mod/blitz_string.c:150
'     (`if(!n) return &bbEmptyString; str=bbStringNew(n); for(k..) str->buf[k]=p[k];`) --
'     the decompile of 0x004A7910 has the exact same 3-part shape: n==0 guard returning
'     &PTR_PTR_005c7d40 (the empty-string singleton), bbStringNew(n) allocation
'     (0x004A72D0), byte-widening copy loop. blitz_classes.i:47 gives the BlitzMax-level
'     spelling: `String.FromBytes(bytes:Byte Ptr, count:Int)`. This resolves spec 22's
'     "Open: what is 0x004A6E90/0x004A7910?" item for 0x004A7910 specifically (0x004A6E90,
'     the ReadSettingFloat string->float helper, is a separate address and NOT resolved
'     by this finding).
'   0x004A63D0 = _bbArrayNew1D (already known) -> `New String[100]`
'   0x004A6480 = _bbArraySlice (already known) -> `array[..count]`
'   PTR_FUN_00c999b8 = the module Global hook, CONFIRMED Byte Ptr(Int,Int) shaped:
'     the prologue through the call instruction is a BYTE-EXACT MATCH including operand
'     ORDER (`push 0x1005; push 0; call [g_hookFn]`), with only the call's data-relocation
'     operand masked -- this is real, checked evidence, not the "do not name it without
'     the learn path" guess earlier passes declined to make. It is already proven that this
'     Global is NEVER written anywhere in the shipped exe (always equals the
'     null-function-error stub), so it is legitimately just `'!Global g_hookFn:Byte
'     Ptr(a:Int, b:Int)` with no assignment anywhere in source.
'
' STATUS: try_function -> MISMATCH, our_len=235, orig_len=210 (matches the earlier figure
' below once these fixes below are folded in).
'
' WHAT IS NOW PROVEN RIGHT (matches byte-for-byte up to the point noted):
'   - The prologue, the hook call, and `If Not p` (NOT `If p = Null` or `If p <> Null /
'     Else`) for the null guard: `cmp edi,0 / setne al / movzx eax,al / cmp eax,0 / jne`
'     -- codegen-patterns.md section 10.3's documented "two distinct Null-test emissions"
'     table, confirmed a THIRD time (this is the "If Not x" row, 21 bytes, "branch sense
'     inverted" -- exactly reproduced by writing `If Not p Then Return ...`, NOT by a
'     literal `= Null` or `<> Null` comparison, both of which were tried first and gave
'     the WRONG (shorter, 5/6-byte) emission).
'   - `New String[100]` -> `_bbArrayNew1D(class, 100)` call shape, operand order and all.
'   - The inner strlen loop must be `Repeat / ln :+ 1 / Until p[ln] = 0`, NOT
'     `While p[ln] <> 0 / ln :+ 1 / Wend` -- the While form emits an extra 3-byte entry
'     jump (`EB 03`) that the original does not have, because the original's decompiled
'     C is a `do { } while(...)` (see section 6 of the skill guide's loop-form table
'     applied here first-hand). This matches the Ghidra C's `do {...} while(pcVar2[iVar6]
'     != 0)` shape exactly.
'
' THE GAP (25 bytes, unresolved this session): when p is Null, the original loads a
' LITERAL CONSTANT ADDRESS directly (`mov eax, 0x5C7C00`) and returns it -- it does NOT
' call `_bbArrayNew1D` at all. `Return New String[0]` in our source instead compiles to
' a real call (push 0; push class; call _bbArrayNew1D; add esp,8) -- structurally
' different, not just a register/spill difference. 0x005C7C00 is almost certainly a
' compile-time-baked EMPTY-ARRAY SINGLETON constant, the array-typed analogue of
' &PTR_PTR_005c7d40 (bbEmptyString, seen directly in the 0x004A7910 decompile above) --
' but no source form tried this session (`New String[0]`, bare `Return` variants) gets
' bcc to fold to a literal-address load instead of a call. NEXT PASS: this is worth its
' own small, focused probe -- try an empty array LITERAL (`[]`), an already-existing
' module Global initialised to `New String[0]` at top level (constant-folded at compile
' time rather than at the call site), or grep the legacy runtime source
' (tools/blitzmax-legacy-src/mod/brl.mod/blitz.mod/blitz_array.c) for a `bbEmptyArray`-
' shaped exported singleton before guessing further -- this note wasn't reached this
' session; time ran out on the module-body budget first.
'
' Blocks 0x00596AFF (the module body's provably-dead branch) and therefore
' blocks a full module-body MATCH regardless -- but per project convention (§Non-
' negotiable 3 in the skill guide, "the game's bugs are part of the game"), the dead
' branch's bytes must still be reproduced verbatim; it cannot be skipped.

'!Global g_hookFn:Byte Ptr(a:Int, b:Int)
Function Fn_00595EF3:String[]()
	Local p:Byte Ptr = g_hookFn(0, 4101)
	If Not p Then Return New String[0]
	Local a:String[] = New String[100]
	Local n:Int = 0
	While p[0] <> 0 And n < 100
		Local ln:Int = 0
		Repeat
			ln :+ 1
		Until p[ln] = 0
		a[n] = String.FromBytes(p, ln)
		p = p + ln + 2
		n :+ 1
	Wend
	Return a[..n]
End Function
