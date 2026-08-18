' TScreen.ResetScreens
' VA 0x00510A05   38 bytes   mode=reloc   byte-identical vs NSS5.exe (38/38, mode=reloc,
' reloc_masked=4, verified with NSS5_NO_LEARN=1)
' KIND=Function (static), SIG ()i, class-table slot 0x58
'
' Trivial three-statement wrapper: log, tear down every gadget, rebuild every screen.
' `ClearAll` is TScreen's own static Function (class-table slot 0x3C) so it is called
' bare, no `TScreen.` prefix, per codegen-patterns.md 3d -- a call through THIS type's
' own class table is a plain sibling call. `CreateAllScreens` is the module-level
' Function at 0x0051B986 (src/recovered_module/CreateAllScreens.bmx, name ours) that
' does the actual 53-screen construction; see that file for the full account.
	Function ResetScreens:Int()
		LogLine("ResetScreens")
		ClearAll()
		CreateAllScreens()
	End Function
