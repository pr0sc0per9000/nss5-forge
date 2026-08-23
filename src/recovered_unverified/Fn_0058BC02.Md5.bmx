' Md5  -- module-level Function (no Type). NAME IS OURS (no reflection record).
' VA 0x0058bc02   2848 bytes   sig ($)$
' UNVERIFIED, and deliberately so: 2848 of 2848 bytes long, every instruction in the right
' place, 73 of the 74 relocation sites masked, first_diff=+2832. The ONE outstanding site
' is the final call, and the reason it does not mask is a defect in
' extracted/runtime_helpers.tsv, not a defect in this body. Read section 8 of
' docs/reference/unrecovered-inventory.md before touching it.
'
' Found by the unrecovered-function audit: this is the largest of the 23 module-level
' Functions inside the game's own module object that had no body in any tree and no row in
' any table. It has ZERO callers anywhere in the exe (brute scan of every E8/E9 rel32), so
' closing it unblocks nothing; it is 2,848 bytes of denominator that nobody knew about.
'
' WHAT IT IS. A complete MD5, string in, 32 lowercase hex characters out. The canonical IV
' 0x67452301 / 0xEFCDAB89 / 0x98BADCFE / 0x10325476 is at 0x0058BC34..0x0058BC47, and all
' 64 step lines below were EXTRACTED FROM THE DISASSEMBLY, not written from memory of the
' algorithm: the message-word index comes from the `add edx, k` before each x push, the
' rotate from the second push, and the additive constant from the first. They happen to
' agree with RFC 1321 exactly, which is a check on the extraction rather than its source.
' Its ten callees (Md5F/G/H/I, Md5FF/GG/HH/II, Md5Rotl, Md5Hex) are all byte-identical and
' in src/recovered_module/.
'
' THE ONE OUTSTANDING SITE, in full, because it is the interesting part:
'     0058C711  E8 CA AD F1 FF    call 0x004A74E0
' 0x004A74E0 is a 190-byte C-runtime function whose character loop is
'     004A7511  8D 47 BF    lea eax, [edi - 0x41]     ; c - 'A'
'     004A7514  83 F8 19    cmp eax, 0x19             ; ... <= 25, i.e. 'A'..'Z'
'     004A7519  83 CF 20    or  edi, 0x20             ; set bit 5 -> lowercase
' which is bbStringToLower and cannot be anything else. Its 190-byte twin at 0x004A7410
' does `lea eax,[edi-0x61] / and edi,0xFFFFFFDF`, which is bbStringToUpper.
' extracted/runtime_helpers.tsv has the two THE WRONG WAY ROUND:
'     0x004a7410  _brl_retro_Lower   (205 witnesses)   <- is really the UPPER-caser
'     0x004a74e0  _brl_retro_Upper   (14 witnesses)    <- is really the LOWER-caser
' Writing `Upper(...)` on the last line instead of `Lower(...)` therefore reaches
' MATCH 2848/2848 under NSS5_NO_LEARN=1. That was measured, and it is NOT what this file
' does, because the mask would be supplied by a table row this file's own evidence
' disproves -- the assembled game would upper-case a digest the original lower-cases while
' the oracle reported success. Swap those two rows and this body matches as written, with
' no change to the source.
'
' RE-MEASURED 2026-08-22, worker 383, harness.try_function under NSS5_NO_LEARN=1, every
' number below reproduced on TWO separately created worker trees (383 and 383b):
'
'   body as written (`Lower`), shared extracted/runtime_helpers.tsv
'       MISMATCH  matched=2557/2848  mode=diff  first_diff=+2832  reloc_masked=73
'   body as written (`Lower`), against a CORRECTED COPY of the table in scratch/
'       MATCH     matched=2848/2848  mode=reloc                   reloc_masked=74
'   body with `Upper`, shared table  (the control -- NOT banked, see above)
'       MATCH     matched=2848/2848  mode=reloc                   reloc_masked=74
'
' So the direction is no longer a deduction: correcting the two rows and changing NOTHING
' in this source turns the one unmasked operand into the 74th masked one. +2832 is the
' first operand byte of the E8 at 0x0058C711, i.e. the residual is that call and only that
' call. The corrected copy was built with sed into scratch/ and the SHARED TABLE WAS NOT
' TOUCHED; the driver that points harness at a copy is scripts/workflow/w383_verify_patched.py.
'
' WHY THIS IS STILL NOT BANKED, and what the whole job is. Correcting the rows flips every
' already-banked body that calls either address. Measured by brute-scanning every E8 rel32
' in the exe against Ghidra's extents (scripts/workflow/w383_lowerupper_scan.py):
'
'   0x004A7410 (really UPPER)  142 call sites in 46 functions; 43 have a src file, all 43
'                              banked, and every one of them writes `Lower(`
'   0x004A74E0 (really LOWER)   34 call sites in 21 functions;  7 have a src file, 6 banked
'                              -- 5 write `Upper(`, and TScreen.CreateScreen already writes
'                              `Lower(` correctly and is currently MISMATCH because of it
'
' 47 distinct banked files (TCombo.SelectItemByLetter is in both lists and needs both
' edits), and the swap costs zero bytes, so the exercise must end at the same percentage it
' started at PLUS this body (2848 bytes) and TScreen.CreateScreen (381). That is a job for
' whoever can take src/recovered/ whole; RULES.md 5.3 forbids doing it piecemeal in a live
' tree, which is why worker 383 measured it and stopped.
'
' STRUCTURE NOTES read off the original rather than assumed:
'   * The `For i = 0 To blocks*16-1 : x[i] = 0 : Next` zeroing loop is REAL (0x0058BC53),
'     even though `New Int[]` already zeroes. Removing it changes the length.
'   * The packing loop's `x[i Shr 2]` appears twice per statement in the emitted code
'     because bcc spills the assignment target's index ([ebp-0xC]) before evaluating the
'     right-hand side. That is one source statement, not two.
'   * `i` survives the packing loop and is reused for the 0x80 pad byte, so it is a
'     function-level Local, not a For-scoped one. The block counter is a separate Local
'     (ebx in the original, `j` here).
' CASE DIRECTION CORRECTED 2026-08-22: 1 call site -> .ToLower().
' extracted/runtime_helpers.tsv named 0x004A7410 `_brl_retro_Lower` and 0x004A74E0
' `_brl_retro_Upper`. Both were wrong and neither address is a brl.retro wrapper:
' 0x004A7410 is `_bbStringToUpper` and 0x004A74E0 is `_bbStringToLower`. NSS5.exe's
' own 21-byte retro wrappers at 0x0059C8FD (Lower) and 0x0059C912 (Upper) CALL those
' two addresses, and a wrapper cannot be the function it calls. The wrong row masked
' by name, so this body certified with the case conversion running backwards. Full
' derivation and the discriminating 3x4 matrix: docs/reference/codegen-patterns.md
' 15.6. Re-verified under NSS5_NO_LEARN=1 on worker trees 380 and 380b.
	Function Md5:String(a0:String)
		Local blocks:Int = ((a0.length + 8) Shr 6) + 1
		Local x:Int[] = New Int[blocks * 16]
		Local a:Int = $67452301
		Local b:Int = $EFCDAB89
		Local c:Int = $98BADCFE
		Local d:Int = $10325476
		Local i:Int = 0
		For i = 0 To blocks * 16 - 1
			x[i] = 0
		Next
		i = 0
		For i = 0 To a0.length - 1
			x[i Shr 2] = x[i Shr 2] | (a0[i] Shl ((i Mod 4) * 8))
		Next
		x[i Shr 2] = x[i Shr 2] | ($80 Shl ((i Mod 4) * 8))
		x[blocks * 16 - 2] = a0.length Shl 3
		Local j:Int
		For j = 0 To blocks * 16 - 1 Step 16
			Local olda:Int = a
			Local oldb:Int = b
			Local oldc:Int = c
			Local oldd:Int = d
			a = Md5FF(a, b, c, d, x[j + 0], 7, $D76AA478)
			d = Md5FF(d, a, b, c, x[j + 1], 12, $E8C7B756)
			c = Md5FF(c, d, a, b, x[j + 2], 17, $242070DB)
			b = Md5FF(b, c, d, a, x[j + 3], 22, $C1BDCEEE)
			a = Md5FF(a, b, c, d, x[j + 4], 7, $F57C0FAF)
			d = Md5FF(d, a, b, c, x[j + 5], 12, $4787C62A)
			c = Md5FF(c, d, a, b, x[j + 6], 17, $A8304613)
			b = Md5FF(b, c, d, a, x[j + 7], 22, $FD469501)
			a = Md5FF(a, b, c, d, x[j + 8], 7, $698098D8)
			d = Md5FF(d, a, b, c, x[j + 9], 12, $8B44F7AF)
			c = Md5FF(c, d, a, b, x[j + 10], 17, $FFFF5BB1)
			b = Md5FF(b, c, d, a, x[j + 11], 22, $895CD7BE)
			a = Md5FF(a, b, c, d, x[j + 12], 7, $6B901122)
			d = Md5FF(d, a, b, c, x[j + 13], 12, $FD987193)
			c = Md5FF(c, d, a, b, x[j + 14], 17, $A679438E)
			b = Md5FF(b, c, d, a, x[j + 15], 22, $49B40821)
			a = Md5GG(a, b, c, d, x[j + 1], 5, $F61E2562)
			d = Md5GG(d, a, b, c, x[j + 6], 9, $C040B340)
			c = Md5GG(c, d, a, b, x[j + 11], 14, $265E5A51)
			b = Md5GG(b, c, d, a, x[j + 0], 20, $E9B6C7AA)
			a = Md5GG(a, b, c, d, x[j + 5], 5, $D62F105D)
			d = Md5GG(d, a, b, c, x[j + 10], 9, $2441453)
			c = Md5GG(c, d, a, b, x[j + 15], 14, $D8A1E681)
			b = Md5GG(b, c, d, a, x[j + 4], 20, $E7D3FBC8)
			a = Md5GG(a, b, c, d, x[j + 9], 5, $21E1CDE6)
			d = Md5GG(d, a, b, c, x[j + 14], 9, $C33707D6)
			c = Md5GG(c, d, a, b, x[j + 3], 14, $F4D50D87)
			b = Md5GG(b, c, d, a, x[j + 8], 20, $455A14ED)
			a = Md5GG(a, b, c, d, x[j + 13], 5, $A9E3E905)
			d = Md5GG(d, a, b, c, x[j + 2], 9, $FCEFA3F8)
			c = Md5GG(c, d, a, b, x[j + 7], 14, $676F02D9)
			b = Md5GG(b, c, d, a, x[j + 12], 20, $8D2A4C8A)
			a = Md5HH(a, b, c, d, x[j + 5], 4, $FFFA3942)
			d = Md5HH(d, a, b, c, x[j + 8], 11, $8771F681)
			c = Md5HH(c, d, a, b, x[j + 11], 16, $6D9D6122)
			b = Md5HH(b, c, d, a, x[j + 14], 23, $FDE5380C)
			a = Md5HH(a, b, c, d, x[j + 1], 4, $A4BEEA44)
			d = Md5HH(d, a, b, c, x[j + 4], 11, $4BDECFA9)
			c = Md5HH(c, d, a, b, x[j + 7], 16, $F6BB4B60)
			b = Md5HH(b, c, d, a, x[j + 10], 23, $BEBFBC70)
			a = Md5HH(a, b, c, d, x[j + 13], 4, $289B7EC6)
			d = Md5HH(d, a, b, c, x[j + 0], 11, $EAA127FA)
			c = Md5HH(c, d, a, b, x[j + 3], 16, $D4EF3085)
			b = Md5HH(b, c, d, a, x[j + 6], 23, $4881D05)
			a = Md5HH(a, b, c, d, x[j + 9], 4, $D9D4D039)
			d = Md5HH(d, a, b, c, x[j + 12], 11, $E6DB99E5)
			c = Md5HH(c, d, a, b, x[j + 15], 16, $1FA27CF8)
			b = Md5HH(b, c, d, a, x[j + 2], 23, $C4AC5665)
			a = Md5II(a, b, c, d, x[j + 0], 6, $F4292244)
			d = Md5II(d, a, b, c, x[j + 7], 10, $432AFF97)
			c = Md5II(c, d, a, b, x[j + 14], 15, $AB9423A7)
			b = Md5II(b, c, d, a, x[j + 5], 21, $FC93A039)
			a = Md5II(a, b, c, d, x[j + 12], 6, $655B59C3)
			d = Md5II(d, a, b, c, x[j + 3], 10, $8F0CCC92)
			c = Md5II(c, d, a, b, x[j + 10], 15, $FFEFF47D)
			b = Md5II(b, c, d, a, x[j + 1], 21, $85845DD1)
			a = Md5II(a, b, c, d, x[j + 8], 6, $6FA87E4F)
			d = Md5II(d, a, b, c, x[j + 15], 10, $FE2CE6E0)
			c = Md5II(c, d, a, b, x[j + 6], 15, $A3014314)
			b = Md5II(b, c, d, a, x[j + 13], 21, $4E0811A1)
			a = Md5II(a, b, c, d, x[j + 4], 6, $F7537E82)
			d = Md5II(d, a, b, c, x[j + 11], 10, $BD3AF235)
			c = Md5II(c, d, a, b, x[j + 2], 15, $2AD7D2BB)
			b = Md5II(b, c, d, a, x[j + 9], 21, $EB86D391)
			a :+ olda
			b :+ oldb
			c :+ oldc
			d :+ oldd
		Next
		Return (Md5Hex(a) + Md5Hex(b) + Md5Hex(c) + Md5Hex(d)).ToLower()
	End Function
