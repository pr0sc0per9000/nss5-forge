' MOD LOADER FUNCTION. Not in the original binary. Added for the loader's Mods button.
' Module-level (not a Type method) so the assembler emits it: a new Type method would be
' dropped, since methods come from the binary's reflection. Opens the Mods folder, which is
' AppDir's parent because our build runs from Mods\core.
	Function ButtonMods:Int()
		OpenURL(ExtractDir(AppDir))
		Return 0
	End Function
