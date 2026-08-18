' DDCAPS_DX3.New
' VA 0x005aa4dd   734 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Method, SIG ()i, class-table slot 0x10
' ASSUMPTIONS
'  * The body is EMPTY. Every one of these 734 bytes is compiler-generated: the runtime
'    ctor helper (FUN_004A8E50), the store of this Type's class-table pointer into +0,
'    and one `mov dword [ebx+off],0` per declared Int field. DDCAPS_DX3 is a plain
'    DirectDraw/Direct3D caps record of Int fields, so bcc's implicit New zero-initialises
'    each of them in offset order and there is no source statement at all.
'  * No module Globals are touched.
	Method New()

	End Method
