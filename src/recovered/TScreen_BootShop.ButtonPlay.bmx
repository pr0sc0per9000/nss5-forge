' TScreen_BootShop.ButtonPlay
' VA 0x00544481   30 bytes   mode=reloc   byte-identical vs NSS5.exe (30/30)
' KIND=Function (static, no implicit Self), SIG ()i, class-table slot 0x3C.
' Verified under NSS5_NO_LEARN=1, so no call operand was named by this body's own probe.
' Body-only format: statements only.
'
' ASSUMPTIONS
'   0x00C687A0 = TScreen_MatchPrep class table + 0x34 = Function SetUpScreen()i
'                (class_tables.tsv + vtable_map.tsv). Emitted as `call dword ptr [abs]`,
'                which is how bcc makes a static call on a Type.
'   0x004BCB98 = PlayTrack (src/recovered_module/PlayTrack.bmx, already verified). The
'                argument 2 is pushed as `6A 02` and cleaned with `add esp,4`, so the
'                signature takes one Int.
'   The trailing `mov eax,0 / jmp +0` is bcc's standard Int return of an ()i Function whose
'   source has no explicit Return -- not a statement in the source.
TScreen_MatchPrep.SetUpScreen()
PlayTrack(2)
