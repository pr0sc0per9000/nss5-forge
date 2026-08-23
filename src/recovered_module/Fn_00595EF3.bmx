' Fn_00595EF3  -- module-level Function (no Type)
' VA 0x00595EF3   210 bytes   sig ()[]$
' byte-identical vs NSS5.exe (210/210, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=8, first_diff=None), verified with NSS5_NO_LEARN=1 via harness.try_function
' on worker tree 216.  MEASURED 2026-08-22, not inferred.
'
' NAME IS OURS. Unattributed "code" function, not in vtable_map.tsv (skill section 8).
' Callee of 0x00596AFF, which is called directly from the real module program at body
' offset 6778.  0x00596AFF's byte-exact source could not be written until this one
' MATCHed, per the E8-name-mask rule; that block is now gone.
'
' WHAT IT DOES.  Calls a Function-typed module Global with (0, 0x1005) and treats the
' returned Byte Ptr as a double-null-terminated list of null-terminated byte strings --
' the classic Win32 REG_MULTI_SZ shape.  Null result -> the empty String array.  Otherwise
' up to 100 entries are copied out into a String[100] and the array is sliced down to the
' number actually found.
'
' CORRECTION TO THE PREVIOUS HEADER, measured this pass.  It asserted that g_hookFn "is
' NEVER written anywhere in the shipped exe" and that this function is therefore dead
' code.  That is FALSE.  Scanning every executable section for the literal 0x00C999B8
' gives four references, and one of them is a WRITE:
'   0x00595F03  call  dword ptr [0xc999b8]     <- this function
'   0x00596B22  mov   eax, dword ptr [0xc999b8] / cmp eax,0x5b95d0 / setne al / ...
'   0x00596B7E  call  dword ptr [0xc999b8]
'   0x00596CBA  mov   dword ptr [0xc999b8], eax
' The write at 0x00596CBA takes the return of `call 0x00597EEE` and substitutes the empty
' function 0x005B95D0 when that return is 0 (`cmp eax,0 / jne / mov eax,0x5b95d0`), which
' is the function-pointer null idiom of guide 10.6; the read at 0x00596B22 is the matching
' `If g_hookFn` test, comparing against 0x005B95D0 rather than against zero for the same
' reason.  So the Global is assigned at runtime and whether this body ever executes is an
' OPEN question that depends on 0x00597EEE, not a settled one.  Nothing here rests on it
' either way -- the body is reproduced because it is in the binary.
'
' ADDRESSES (CONTRIBUTING "a byte match does not prove your Globals are right"):
'   g_hookFn            = 0x00C999B8   emitted as `call dword ptr [0xc999b8]`
'   String[] class desc = 0x00C99722   the _bbArrayNew1D argument
'   slice class desc    = 0x00C9939D   the _bbArraySlice argument
'   bbEmptyArray        = 0x005C7C00   loaded as a literal by `Return Null` (see below)
'
' TABLE CORRECTION (guide 16.7 / 10.7 shape: trust the code over the table).
' extracted/globals_final.tsv and globals_named.tsv both row 0x00C999B8 as
' `Int g_misc_int92`, "dword int access".  It is not an Int.  The exe calls THROUGH it
' twice (`FF 15 B8 99 C9 00`) with two arguments pushed, and stores a code address into it
' at 0x00596CBA.  It is a Function-typed Global, `Byte Ptr(a:Int, b:Int)`.
' explain_global.py resolves no name at this address, and no other file in src/ declares
' it, so `g_hookFn` is not competing with an existing name -- but it does disagree with
' those two tables, and this note is the record of which one the disassembly supports.
'
' ===================================================================================
' HOW THE LAST 25 BYTES CLOSED.  Prior state: our_len 235 vs 210, five length-changing
' gaps.  Four source-form errors, each fixed against bcc's OWN SOURCE in
' tools/blitzmax-legacy-src/_src/compiler, not against the Ghidra decompile.  Measured one
' at a time with scripts/localise_diff.py under NSS5_WORKER=216 NSS5_NO_LEARN=1:
'
'   +25 -> +15   `Return New String[0]`  ->  `Return Null`
'       The original loads a literal address (`B8 00 7C 5C 00  mov eax,0x5c7c00`) where we
'       emitted a real 15-byte `_bbArrayNew1D` call.  val.cpp:206 in Val::cast():
'           if( dst->arrayType() ) return new Val(dst,sym("bbEmptyArray",CG_IMPORT));
'       so a Null cast to an array type IS the bbEmptyArray singleton, resolved at compile
'       time.  The previous pass guessed at `[]` literals and top-level Globals and never
'       tried the one spelling the compiler actually special-cases.
'
'   +15 -> +4    `While p[0] <> 0 And n < 100`  ->  `While p[0] And n < 100`
'       Val::cond() (val.cpp:114) returns an int-typed value UNCHANGED -- no conversion
'       node -- and Byte is an intType.  ShortCircExp::_eval (exp.cpp:671) then emits
'       `mov r,<lhs> / bcc(CG_EQ,r,0,skip) / mov r,<rhs> / skip:`, which for a raw Byte
'       lhs is exactly the original's `movzx eax,byte[edi] / cmp eax,0 / je`.  Writing the
'       explicit `<> 0` builds a CmpExp instead, which balances Byte against the Int
'       literal and costs a cvt (`89 C0  mov eax,eax`) plus `setne al / movzx eax,al`.
'       11 bytes.
'
'   +4 -> +2     `Until p[ln] = 0`  ->  `Until Not p[ln]`
'       Same rule, 2 bytes.  NotExp::_eval (exp.cpp:688) is
'           Val *v=exp->eval(sc)->cond();  return new Val(int32,scc(CG_EQ,v->cg_exp,lit0));
'       -- it calls cond() FIRST, so the Byte reaches the comparison with no cvt, and
'       RepeatStm's `bcc(CG_EQ,cond,0,loop)` (stm.cpp:546) folds the whole thing into a
'       single `cmp eax,0 / jne loop`.  `= 0` re-introduces the cvt.
'       GENERAL RULE, worth adding to the guide: when a Byte or Short is used as a truth
'       value, spelling the comparison out costs a `mov eax,eax`.  bcc has no separate
'       "is nonzero" test -- `Not x` and a bare `x` ARE the idiom.
'
'   +2 -> 0      `p = p + ln + 2` then `n :+ 1`   ->   `n :+ 1` then `p :+ ln + 1`
'       Two independent errors in one statement pair.
'       (a) ORDER.  The original increments n BEFORE advancing p: `add [ebp-4],1` at +144
'           precedes the pointer arithmetic at +148.  We had it the other way round.
'       (b) FORM, and this is guide 16.1 holding for pointers as well as Strings.
'           `p :+ ln + 1` evaluates the RHS as a unit and compound-adds it:
'               89 F0  mov eax,esi / 83 C0 01  add eax,1 / 01 C7  add edi,eax     (7 bytes)
'           `p = p + ln + 2` is a left-associative chain reassigned from self:
'               mov eax,edi / add eax,esi / add eax,2 / mov edi,eax               (9 bytes)
'           Section 6 says `:+` and `= x +` are identical for a register-allocated local.
'           That is only true when the RHS is a single term.  With a compound RHS the two
'           forms differ by 2 bytes here, and this body is the counter-example.
'       The `+ 2` was ALSO a semantic bug of ours, not just a byte defect.  The strlen loop
'       leaves ln equal to the index of the terminator, so the next string begins at
'       p + ln + 1.  Our `+ 2` skipped a byte of every entry after the first.
'
' The three loop-form findings recorded by the previous pass all survived re-measurement
' and are unchanged: `If Not p` (not `= Null`/`<> Null`) for the null guard, guide 10.3's
' 21-byte inverted-sense row; `New String[100]` -> _bbArrayNew1D operand order; and the
' inner strlen loop as `Repeat / ln :+ 1 / Until ...`, never the `While` form, which adds
' a 3-byte entry jump.
'
' ===================================================================================
' THE LAST BLOCKER WAS NOT SOURCE.  With the four fixes in, the two bodies are
' instruction-for-instruction identical -- 73 instructions, 8 differing operands, every
' one of them a relocation.  The oracle still said MISMATCH at +98, the rel32 of
'   00595F54  E8 B7 19 F1 FF   call 0x004a7910
' because 0x004A7910 was absent from helper_map.full_table().  Under NSS5_NO_LEARN=1 an
' unnamed original-side callee cannot mask, and compare()'s byte-level fallback
' (_same_callee) can never work here: 0x004A7910 is C-runtime output and our GCC is not
' theirs (guide 15.4).
'
' 0x004A7910 = _bbStringFromBytes is now recorded in extracted/brl_functions_inferred.tsv
' with its evidence.  The identification uses NO game body, so there is no circularity
' (guide 15.1):
'   * Its own 69-byte body is blitz_string.c:150 three-for-three -- `mov eax,0x5c7d40`
'     (&bbEmptyString) guarded by `test ebx,ebx`, then `call 0x004a72d0` (bbStringNew),
'     then `xor ecx,ecx / mov cl,[esi+edx] / mov word [eax+edx*2+0xc],cx`.  That 8-bit
'     load widened into a 16-bit BBChar is `str->buf[k]=(unsigned char)p[k]`, and it is
'     what separates FromBytes from bbStringFromShorts (bbMemCopy) and bbStringFromInts
'     (dword load).
'   * Four callers whose source is in this tree and whose only string constructor is
'     String.FromBytes: 0x005B8323 _brl_stream_LoadString and 0x0059D7E1
'     _brl_textstream_LoadText, both BYTE-PROVEN in brl_functions.tsv against the shipped
'     archives; TStream.ReadLine 0x005B76C1 and TStream.ReadString 0x005B7811, named by
'     reflection in vtable_map.tsv.  stream.bmx lines 390, 416 and 998 are all
'     `Return String.FromBytes(...)`.
'   * 0x004A7960 _bbStringFromCString (already in the table) calls it, and
'     blitz_string.c:190 is `return p ? bbStringFromBytes(p,strlen(p)) : &bbEmptyString`.
' Blast radius checked before writing the row: extracted/call_sites.tsv shows only five
' game call sites for 0x004A7910 and four of them are BRL functions we do not reconstruct;
' no file in src/recovered, src/recovered_module, src/recovered_thirdparty or
' src/module_body emits String.FromBytes at all.  So the row can mask nothing that was
' previously being adjudicated.
'
' This resolves spec 22's "Open: what is 0x004A6E90/0x004A7910?" for 0x004A7910 only.
' 0x004A6E90 is a different address (_bbStringToFloat, already in full_table per guide
' 15.4) and is untouched by this.
'
' NOT DONE HERE, deliberately: assemble.py and smoke_boot.py were not run, because both
' write shared state (src/assembled) and other workers were building concurrently.  Run
' them, plus progress.py --write-status, before this is folded in.

'!Global g_hookFn:Byte Ptr(a:Int, b:Int)
	Function Fn_00595EF3:String[]()
		Local p:Byte Ptr = g_hookFn(0, 4101)
		If Not p Then Return Null
		Local a:String[] = New String[100]
		Local n:Int = 0
		While p[0] And n < 100
			Local ln:Int = 0
			Repeat
				ln :+ 1
			Until Not p[ln]
			a[n] = String.FromBytes(p, ln)
			n :+ 1
			p :+ ln + 1
		Wend
		Return a[..n]
	End Function
