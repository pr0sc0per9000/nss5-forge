' NOT VERIFIED -- near miss, 212 of 218 bytes, gated by an x87 SCHEDULING ORDER
' problem in the `t` computation, not a semantic one.
'
' PointNearSegment (name OURS)  -- module-level Function (no Type), no reflection record
' VA 0x005061DD   218 bytes (Ghidra inventory)   sig (f,f,f,f,f,f,f)i
'
' THIS IS THE BLOCKER NAMED "FUN_005061DD" for TBall.CanSeePlayer (0x004CC489, 345 bytes).
' Earlier attempts on that caller never decompiled this function itself.
'
' SEMANTICS (certain -- matches Ghidra's decompile of 0x005061DD exactly, and the tail of
' the function, byte-for-byte from 0x00506216 onward, i.e. clamp+Dist2D+compare, is
' UNTESTED here because the divergence happens before that point on every attempt, but
' the Ghidra decompile for that tail is unambiguous once the args are named):
'   A = (a0,a1), B = (a2,a3), P = (a4,a5), r = a6.
'   t = Dot(P-A, B-A) / LenSq(B-A), clamped to [0,1]
'   closest = A + t*(B-A)
'   Return Dist2D(P, closest) < r
' i.e. "is point P within radius r of segment AB" -- exactly what TBall.CanSeePlayer needs
' twice: once against a blocking player's (x,y) with r = TPitch.YardsToPixels(g_seeRadius),
' once against the same player's (metax,metay) with r halved.
'
' THE GAP -- ours is 212 bytes, original is 218, diverging at offset 12 (first instruction
' after the third `fld`) on EVERY term-order permutation tried (6 permutations of which
' factor/operand is written first in the numerator and denominator all produce byte-
' identical 212-byte output, so source-level term order is NOT the lever -- ruled out).
'
' ORIGINAL's actual x87 trace (traced by hand from harness.disasm_original, confirmed by
' decoding the ModRM byte of every D8 Cx/Ex opcode against the Intel x87 register-form
' encoding table):
'   fld a0; fld a1; fld a2; fsub st(2)          -> D1 = a2-a0        (computed FIRST,
'                                                   immediately after only 3 loads)
'   fld a3; fsub st(2)                          -> D2 = a3-a1
'   fld a4; fsub st(4)                          -> (a4-a0)
'   fld a2 (RELOAD from [ebp+0x10], not a dup!) ; fsub st(5)  -> a2-a0 AGAIN, fresh
'   fmulp st(1)                                 -> (a4-a0)*(a2-a0)
'   fld a5; fsub st(4)                          -> (a5-a1)
'   fld a3 (RELOAD); fsub st(5)                 -> a3-a1 AGAIN, fresh
'   fmulp st(1); faddp st(1)                    -> numerator done
'   fxch st(2); fmul st(0),st(0)                -> D1^2   (the ORIGINAL D1, held all along)
'   fxch st(1); fmul st(0),st(0)                -> D2^2
'   faddp st(1); fdivp st(1)                    -> t = numerator / (D1^2+D2^2)
'
' So D1=(a2-a0) and D2=(a3-a1) are each computed EXACTLY TWICE: once held from the very
' start (used only for the denominator, at the end), once recomputed fresh partway
' through (used only for the numerator). That is 4 total subtractions, same as our
' best attempt -- but ours computes them in a DIFFERENT temporal order: we load a0,a1,a2,
' THEN either (a) load a3 before touching a2-a0 at all (giving D2 first, 212 bytes,
' diverges immediately), or (b) `fld st(0)` a DUP of a2 right after loading it (also
' 212 bytes) instead of the original's "subtract immediately, reload later" shape.
'
' RULED OUT: source-level term order (6 permutations, byte-identical result each time --
' bcc normalises commutative +/x operand order before scheduling loads, so this is not
' a Local-declaration-order style lever). RULED OUT: wrapping (a2-a0)/(a3-a1) in Local
' variables -- that produces TRUE reuse (fxch, no reload) and undershoots to 201 bytes,
' the opposite direction from the original's double-fresh-load shape.
'
' NOT RULED OUT / next step: whether the original's D1-first-then-D2 sequencing (as
' opposed to bcc's default within-a-single-expression scan order) comes from the
' function being built from TWO SEPARATE Local statements where the first Local's
' right-hand side is used again, unexpanded, later in a second Local's expression --
' i.e. not `Local t:Float = (huge single expression)` but something closer to
'   Local ab:TMyVector-shaped pair computed via two prior statements whose OWN
'   sub-expressions get re-typed textually rather than referenced by name.
' Nothing in src/recovered_module/ shows that shape yet; GetInterceptPoint.bmx and
' Cross2D.bmx both show ordinary Local reuse (no reload), which is the opposite of what
' this function does. Try: emitting D1 and D2 in two bare expression-statement lines
' that are otherwise DISCARDED (e.g. as dummy Local declarations never read again by
' name, only retyped) to see whether bcc's "hoist cheap leaves, defer their consumers"
' behaviour is a whole-basic-block property rather than an expression-tree property.
'
' CANDIDATE BODY (semantically right, NOT byte-exact -- do not promote to
' src/recovered_module/ until it is):
'   Local t:Float = ((a4-a0)*(a2-a0) + (a5-a1)*(a3-a1)) / ((a2-a0)*(a2-a0) + (a3-a1)*(a3-a1))
'   If t < 0.0 Then t = 0.0
'   If t > 1.0 Then t = 1.0
'   Return Dist2D(a4, a5, t*a2 + (1.0-t)*a0, t*a3 + (1.0-t)*a1) < a6
' verified constants: the two clamp bounds and the two blend coefficients are all
' 0.0 or 1.0, read directly from NSS5.exe at 0x00C7BBA4/A8/AC/B0 (all confirmed 0.0,
' 1.0, 1.0, 1.0 respectively).
