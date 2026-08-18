' TPrivateBitmapFont.New
' VA 0x0059127E   174 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (174/174)
' THIRD-PARTY MODULE (fontmachine) -- this body must NOT be moved into src/recovered/.
'
' Resolves the UNCERTAIN flag on the offset-0 write. It is NOT an interface-vtable
' install: `push Self; call 0x4A8E50; mov [Self], &classtable` is the ORDINARY compiler
' New() prologue documented at codegen-patterns.md sec 3d ("New, 34 bytes: FUN_004A8E50
' (param_1); *param_1 = &classtable" -- confirmed 63/63 in the main module too). 0x4A8E50
' is bbObjectCtor (the implicit Super.New()); the class-table restamp after it is emitted
' for every Type with a New() method, empty or not. iTextRendererFXBase has no inheritance
' relationship with TPrivateBitmapFont in object_model.json -- the two are unrelated Types
' that both happen to be referenced from TBitmapFont; there is no multi-inheritance here.
'
' All ELEVEN field stores in the body -- three object-array fields, six Ints, and the
' TRenderStatus field -- are FIELD DEFAULTS, not body statements, even though five of them
' are non-Null/non-zero values (DrawShadow=1, DrawBorder=1, ShadowBlend=3, FaceBlend=3,
' BorderBlend=3). Confirmed by elimination: writing RenderStatus as a body assignment
' (`RenderStatus = New TRenderStatus`, with or without a `'!Field RenderStatus = Null`
' pragma) makes bmk NG emit the CONSERVATIVE retain-new/release-old sequence (extra saved
' register esi, +74 bytes) documented for object fields set mid-body --
' the original has no such check (a flat push-classtable/call bbObjectNew/inc-refcount/
' store, 19 bytes, matching a field default exactly). Declaring RenderStatus's default too
' fixes the WEIGHT but reorders it: bmk emits all '!Field pragma defaults together, in field
' order, ahead of any literal body text, so a probe mixing pragmas (for the arrays) with
' plain-text Int body statements (for DrawShadow..BorderBlend) puts RenderStatus's init
' right after the arrays instead of last. Declaring EVERY field (including the six Ints) as
' a '!Field default and leaving the body empty gives bmk full control of emission order --
' offset order, i.e. declaration order -- which reproduces the original's Shadow/Border/
' Face/[Progress-implicit]/DrawShadow/DrawBorder/FontLoaded/ShadowBlend/FaceBlend/
' BorderBlend/RenderStatus sequence exactly.
'
' The Progress:(f)i field (offset 0x14, between Face and DrawShadow) needs NO pragma at
' all. Its store (`mov [ebx+0x14], 0x5B95D0`) is the compiler's IMPLICIT default for an
' uninitialised Function-typed field -- 0x5B95D0 is `_brl_blitz_NullFunctionError` /
' `_brl_blitz_NullMethodError` (confirmed: extracted/brl_functions.tsv), the stock BRL
' thrower a call through a never-assigned (f)i/(...)r field lands on. This differs from an
' un-defaulted OBJECT field, which is the "literally zero code" case -- a function-
' pointer field's implicit default is NOT a no-op, it is one store, and NG emits the
' equivalent automatically with no source line needed.
'
' Shadow/Border/Face are TBitMapChar[256] (one slot per byte value, 0..255).
' Parameter list is empty (Method New() takes no args); Self at [ebp+8] per KIND=Method.

	Method New()
		'!Field Shadow:TBitMapChar[] = New TBitMapChar[256]
		'!Field Border:TBitMapChar[] = New TBitMapChar[256]
		'!Field Face:TBitMapChar[] = New TBitMapChar[256]
		'!Field DrawShadow:Int = 1
		'!Field DrawBorder:Int = 1
		'!Field FontLoaded:Int = 0
		'!Field ShadowBlend:Int = 3
		'!Field FaceBlend:Int = 3
		'!Field BorderBlend:Int = 3
		'!Field RenderStatus:TRenderStatus = New TRenderStatus
	End Method
