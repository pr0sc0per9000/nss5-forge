' TFontMachineVersion.Version
' VA 0x005928C7   14 bytes   vtable slot 0x30   sig ()$
' byte-identical vs NSS5.exe (14/14)
' THIRD-PARTY MODULE (fontmachine) -- this body must NOT be moved into src/recovered/.
' Parameter names are UNCERTAIN (not recoverable from the binary); a0.. as emitted
' THE VERSION STRING IS "Untitled 0.0.1". A guess of "Font Machine 1.5.1" by prose
' association ("the only Font Machine-prefixed literal in the exe") also scores MATCH 14/14,
' because the oracle masks the literal's address. scripts/check_literals.py decodes the
' BBString actually referenced at VA 0x005928C7 (mov eax, 0xC97EC4) and it is "Untitled
' 0.0.1" -- an unfinished/default version string, not "Font Machine 1.5.1".

	Function Version:String()
		Return "Untitled 0.0.1"
	End Function
