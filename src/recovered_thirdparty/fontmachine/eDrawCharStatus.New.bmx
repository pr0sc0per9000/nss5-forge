' eDrawCharStatus.New
' VA 0x00592666   34 bytes   sig ()i
' byte-identical vs NSS5.exe (34/34, mode=reloc, reloc_masked=2, NSS5_NO_LEARN=1,
' verified via try_method with the ORIGINAL side located by VA)
' THIRD-PARTY MODULE (fontmachine) -- this body must NOT be moved into src/recovered/.
'
' The second Const-only Type, byte-for-byte EConstBlend.New with a different class
' pointer (`mov dword [ebx],0x00C973CC`). See EConstBlend.New.bmx for why the original
' side has to be located by VA and what exactly that changes; the VA here is
' object_model.json's own offset for the member, 5842534 = 0x00592666.

	Method New()
	End Method
