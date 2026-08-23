' Sha256Hex (name OURS -- module-level Function, no reflection record)
' VA 0x0058c960   1776 bytes   sig ($)$
' byte-identical vs NSS5.exe (1776/1776, original length from Ghidra's inventory)
' VA 0x0058C960   1,776 bytes   KIND=Function, no Self.   sig ($)$
' byte-identical vs NSS5.exe (1776/1776, mode=reloc -- every remaining difference is an
' in-image relocation or a named runtime-call operand, masked by the oracle)
'
' CASE DIRECTION CORRECTED 2026-08-22. The runtime-helper table used to name 0x004A7410
' `_brl_retro_Lower` and 0x004A74E0 `_brl_retro_Upper`; both were wrong and neither address
' is a brl.retro wrapper. 0x004A7410 is `_bbStringToUpper` and 0x004A74E0 is
' `_bbStringToLower` -- proved from the instructions (`and edi,0xFFFFFFDF` vs `or edi,0x20`),
' from blitz_string.c's 181/192 ASCII gates, and above all from NSS5.exe's own retro
' wrappers at 0x0059C8FD (Lower) and 0x0059C912 (Upper), which are 21 bytes each and CALL
' 0x004A74E0 and 0x004A7410 respectively. A wrapper cannot be the function it calls.
' See docs/reference/codegen-patterns.md 15.6.
' So the digest is hex-formatted and LOWERCASED, the usual SHA-256 convention.
' SHA-256 of the argument string, then hex-formatted and lowercased. Treats each UTF-16
' character as a single byte (its low 8 bits -- Latin-1/ASCII semantics: `a0[ci] & $ff`),
' not the character's full code point. This is what TProfile.CheckSkillHash /
' UpdateAbility / SetAbility call to hash "dontcheatatnss5" + seven player-stat digit
' strings into `skillshash`.
'
' STRUCTURE, in call/measurement order:
'   1. h0..h7 -- the eight SHA-256 IV words, eight separate Int Locals (NOT an array --
'      confirmed by eight direct `mov dword [ebp-N], imm32` stores, no array allocation
'      call ahead of them).
'   2. k -- the 64 SHA-256 round constants, written as a 64-element `Int[]` ARRAY LITERAL.
'      They appear in the exe as 64 literal `mov [eax+off],imm32` stores immediately after
'      one _bbArrayNew1D call, never as a `.data` table -- this is exactly how bcc compiles
'      `Local k:Int[] = [$428a2f98, ...]`, so the K constants are a literal, not a Global.
'   3. wordcount / w -- the message schedule buffer, `New Int[wordcount]`. `wordcount` is a
'      SEPARATE Local from `w`, even though `w.Length` would equal it: the original reads
'      `wordcount` for the block-loop bound but re-derives `w.Length` for the two length-
'      field stores below, and using `w.Length` for the bound instead costs a whole extra
'      spilled dword (frame `sub esp` was 4 bytes short until this was split out).
'   4. The byte-packing loop is `0 Until a0.Length` (EXCLUSIVE upper bound), not
'      `0 To a0.Length-1`: the original's loop test compares the counter against
'      `a0.Length` directly with `jl` (strict), never against a precomputed `Length-1` with
'      `jle`. Same for the block loop below (`0 Until wordcount Step 16`).
'   5. The padding-byte statement re-reads `w[a0.Length Shr 2]` and `a0.Length` TWICE (no
'      intermediate Local) -- bcc recompiles each occurrence of the index expression
'      independently, which is exactly what the disassembly shows (two separate
'      `mov eax,[..]; shr eax,2` sequences for what looks like one subexpression).
'   6. `a0.Length & 3`, not `a0.Length Mod 4`. This is the single largest source of the
'      first attempt's byte mismatch: BlitzMax's `Mod` always compiles to `idiv` (62 extra
'      bytes here) even against a power-of-two constant; the original uses the bitwise `&`
'      form, which is what `and ecx,3` in the disassembly actually is.
'   7. The two 64-bit length-field stores independently recompute `Long(a0.Length) * 8`
'      (no shared Local) -- confirmed by TWO separate `_bbIntToLong` + `_bbLongMul` call
'      pairs. `w[w.Length-1] = (Long(a0.Length)*8) & $ffffffff` is written exactly as shown:
'      `$ffffffff` is the Int literal -1, sign-extended to the Long -1 (both dwords 0xFF..),
'      so the AND is a numeric no-op -- the actual truncation to the low 32 bits happens
'      when the Long result is stored into the `Int` array element `w[...]`. Reproduced
'      faithfully rather than "fixed" to a real low-32-bit mask (rule: do not improve the
'      original).
'   8. Message-schedule extension (`t = 16 To 63`) and the compression round (`rnd = 0 To
'      63`) are each written as ONE flat expression per statement, not with intermediate
'      `s0`/`s1`/`ch`/`maj`/`t1`/`t2`-style sub-Locals beyond what is shown below. Splitting
'      them into more named Locals changes bcc's register pressure and reorders when values
'      are (re)loaded from the message-schedule array -- measured as an 85-byte swing on the
'      first, over-decomposed attempt.
'   9. The final `a = t2 + t1` (not `t1 + t2`): confirmed by the trailing 2-byte residual --
'      swapping the addition operand order flips which operand's register bcc reuses in
'      place versus copies through a scratch register, which is exactly the two/three
'      instruction difference (`add eax,edi` vs `mov edx,edi / add edx,eax`) that remained
'      after every other statement matched.
'  10. Digest assembly is the plain left-to-right chain
'      `(Hex(h0)+Hex(h1)+...+Hex(h7)).ToLower()`. bcc evaluates a flat `+` chain's operands in
'      REVERSE (h7 first ... h0 last) before folding the concatenations forward
'      (h0+h1, then +h2, ... then +h7) -- that reverse-then-forward call order in the
'      disassembly is what this single expression compiles to; nothing hand-tuned.
'
' The four unnamed runtime calls this body makes (0x004A7FC0, 0x004A81B0, 0x004A8370,
' 0x004A82E0) are BlitzMax's Long (64-bit) helpers -- Int-to-Long sign-extend, 64x64->64
' multiply, 64-bit variable logical shift-right, 64-bit AND. Named `_bbIntToLong`,
' `_bbLongMul`, `_bbLongShr`, `_bbLongAnd` in extracted/brl_functions_inferred.tsv, with the
' evidence there: our own toolchain's relocation records for the equivalent `Long`
' expressions, plus a direct byte comparison against each original body (`_bbLongShr` is
' byte-for-byte identical, 18/18; the other three are the same algorithm with GCC
' instruction-scheduling differences, the same divergence class already documented for
' `_bbObjectDowncast` in helper_map.py). Naming them is what let this 1,776-byte body verify
' at all -- every call into them was an unmaskable E8 until the table carried their names.
Function Sha256Hex:String(a0:String)
	Local h0:Int = $6a09e667
	Local h1:Int = $bb67ae85
	Local h2:Int = $3c6ef372
	Local h3:Int = $a54ff53a
	Local h4:Int = $510e527f
	Local h5:Int = $9b05688c
	Local h6:Int = $1f83d9ab
	Local h7:Int = $5be0cd19

	Local k:Int[] = [$428a2f98, $71374491, $b5c0fbcf, $e9b5dba5, $3956c25b, $59f111f1, $923f82a4, $ab1c5ed5, ..
		$d807aa98, $12835b01, $243185be, $550c7dc3, $72be5d74, $80deb1fe, $9bdc06a7, $c19bf174, ..
		$e49b69c1, $efbe4786, $0fc19dc6, $240ca1cc, $2de92c6f, $4a7484aa, $5cb0a9dc, $76f988da, ..
		$983e5152, $a831c66d, $b00327c8, $bf597fc7, $c6e00bf3, $d5a79147, $06ca6351, $14292967, ..
		$27b70a85, $2e1b2138, $4d2c6dfc, $53380d13, $650a7354, $766a0abb, $81c2c92e, $92722c85, ..
		$a2bfe8a1, $a81a664b, $c24b8b70, $c76c51a3, $d192e819, $d6990624, $f40e3585, $106aa070, ..
		$19a4c116, $1e376c08, $2748774c, $34b0bcb5, $391c0cb3, $4ed8aa4a, $5b9cca4f, $682e6ff3, ..
		$748f82ee, $78a5636f, $84c87814, $8cc70208, $90befffa, $a4506ceb, $bef9a3f7, $c67178f2]

	Local wordcount:Int = (((a0.Length + 8) Shr 6) + 1) Shl 4
	Local w:Int[] = New Int[wordcount]

	For Local ci:Int = 0 Until a0.Length
		w[ci Shr 2] = (w[ci Shr 2] Shl 8) | (a0[ci] & $ff)
	Next

	w[a0.Length Shr 2] = ((w[a0.Length Shr 2] Shl 8) | $80) Shl ((3 - (a0.Length & 3)) * 8)

	w[w.Length - 2] = (Long(a0.Length) * 8) Shr 32
	w[w.Length - 1] = (Long(a0.Length) * 8) & $ffffffff

	For Local bi:Int = 0 Until wordcount Step 16
		Local a:Int = h0
		Local b:Int = h1
		Local c:Int = h2
		Local d:Int = h3
		Local e:Int = h4
		Local f:Int = h5
		Local g:Int = h6
		Local h:Int = h7

		Local w2:Int[] = w[bi..bi + 16]
		w2 = w2[..64]

		For Local t:Int = 16 To 63
			w2[t] = w2[t-16] + (Rotr(w2[t-15], 7) ~ Rotr(w2[t-15], 18) ~ (w2[t-15] Shr 3)) + w2[t-7] + (Rotr(w2[t-2], 17) ~ Rotr(w2[t-2], 19) ~ (w2[t-2] Shr 10))
		Next

		For Local rnd:Int = 0 To 63
			Local t2:Int = (Rotr(a, 2) ~ Rotr(a, 13) ~ Rotr(a, 22)) + ((a & b) | (b & c) | (c & a))
			Local t1:Int = h + (Rotr(e, 6) ~ Rotr(e, 11) ~ Rotr(e, 25)) + ((e & f) | ((~e) & g)) + k[rnd] + w2[rnd]

			h = g
			g = f
			f = e
			e = d + t1
			d = c
			c = b
			b = a
			a = t2 + t1
		Next

		h0 = h0 + a
		h1 = h1 + b
		h2 = h2 + c
		h3 = h3 + d
		h4 = h4 + e
		h5 = h5 + f
		h6 = h6 + g
		h7 = h7 + h
	Next

	Return (Hex(h0) + Hex(h1) + Hex(h2) + Hex(h3) + Hex(h4) + Hex(h5) + Hex(h6) + Hex(h7)).ToLower()
End Function
