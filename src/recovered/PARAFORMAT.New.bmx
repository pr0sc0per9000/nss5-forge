' PARAFORMAT.New
' VA 0x005AC976   344 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Method, SIG ()i, slot 0x10
' ASSUMPTIONS
'  * The body is EMPTY. All 344 bytes are compiler-generated: the runtime ctor helper
'    (FUN_004A8E50), the store of this Type's class-table pointer into +0, and one
'    zero-store per declared field. PARAFORMAT is the Win32 RichEdit paragraph-format
'    record (Int / Short fields including the 8x4 rgxTabs block), so bcc's implicit New
'    zero-initialises every field in offset order and there is no source statement.
'  * No module Globals are touched.
	Method New()

	End Method
