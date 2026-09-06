' EConstBlend.New
' VA 0x00592251   34 bytes   sig ()i
' byte-identical vs NSS5.exe (34/34, mode=reloc, reloc_masked=2, NSS5_NO_LEARN=1,
' verified via try_method with the ORIGINAL side located by VA -- see below)
' THIRD-PARTY MODULE (fontmachine) -- this body must NOT be moved into src/recovered/.
'
' HOW IT WAS VERIFIED, and why not by plain try_method. EConstBlend is one of the two
' Const-only "enum" Types with no row in extracted/class_tables.tsv (see
' EConstBlend.Delete.bmx for the full account), so object_model.json's Method offsets for
' it are raw VAs and bytematch.find_method cannot resolve the ORIGINAL side at all.
' Delete got round that through try_function's VA route, but that route cannot serve a
' `Method New()`: the body is the constructor prologue -- bbObjectCtor (0x004A8E50) then
' the class-pointer store `mov dword [ebx],0x00C96C74` -- and a bare Function emits none
' of it. So only the original-side LOCATE was replaced, by the VA object_model.json itself
' gives for the member (5841489 = 0x00592251, which is also a function start in Ghidra's
' inventory with length 34). The probe, our-side locate, Ghidra length and compare() are
' harness.try_method's own, unchanged, under NSS5_NO_LEARN=1.
'
' Body: the Type declares no Fields, so New() has nothing to zero and is the bare
' ctor-plus-class-pointer shape. Contrast TDrawingPoint.New (44 bytes), whose two Float
' fields add an `fldz`/`fstp` pair each.

	Method New()
	End Method
