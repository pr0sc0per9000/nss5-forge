' DEVMODE.New
' VA 0x005AC15C   374 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Method, SIG ()i, slot 0x10
' ASSUMPTIONS
'  * The body is EMPTY. All 374 bytes are compiler-generated: the runtime ctor helper
'    (FUN_004A8E50), the store of this Type's class-table pointer into +0, and one
'    zero-store per declared field. DEVMODE is the Win32 display-settings record, a
'    plain sequence of Int / Short / Byte fields, so bcc's implicit New zero-initialises
'    each of them in offset order and there is no source statement.
'  * No module Globals are touched.
	Method New()

	End Method
