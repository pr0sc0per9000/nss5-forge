' DDCAPS_DX1.New
' VA 0x005aa359   374 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Method, SIG ()i, class-table slot 0x10
' ASSUMPTIONS
'  * The body is EMPTY. All 374 bytes are compiler-generated: the runtime ctor helper
'    (FUN_004A8E50), the store of this Type's class-table pointer into +0, and one
'    `mov dword [reg+off],0` per declared Int field. DDCAPS_DX1 is a plain DirectDraw
'    caps record of Int fields, so bcc's implicit New zero-initialises each of them in
'    offset order and there is no source statement at all.
'  * No module Globals are touched.
	Method New()

	End Method
