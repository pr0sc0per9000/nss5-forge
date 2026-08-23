' ColourIndex  -- module-level Function (no Type). NAME IS OURS (no reflection record).
' VA 0x00506ed2   523 bytes   sig ($)i
' byte-identical vs NSS5.exe (523/523, original length from Ghidra's inventory), verified
' with harness.try_function under NSS5_NO_LEARN=1.
'
' Maps a six-digit hex colour string onto its slot in a seventeen-entry palette, returning
' 0 for anything it does not recognise (which is the same answer as black). Sits in the
' colour-handling run next to the already-verified SetColourHex, ParseColourHex, RGBToHex
' and ShiftColourHex.
'
' NOT CALLED FROM ANYWHERE in the shipped exe (brute scan of every E8/E9 rel32: zero call
' sites). Found by the unrecovered-function audit; see
' docs/reference/unrecovered-inventory.md.
'
' THE PALETTE, read from the exe's own string literals in the order the comparisons appear
' (each is a BBString at the listed address, checked with _bbStringCompare at 0x004A6A30):
'    0  000000
'    1  FFFFFF
'    2  FF0000
'    3  00FF00
'    4  0000FF
'    5  FFFF00
'    6  00FFFF
'    7  800080
'    8  FF6600
'    9  999999
'   10  970045
'   11  FF00FF
'   12  FCDB00
'   13  8080FF
'   14  000080
'   15  008000
'   16  800000
'
' Select, NOT If/ElseIf. Both spellings compile to the same chain of _bbStringCompare
' calls, but only Select puts every `mov eax,<n>` block together after the comparisons, in
' the order the original has them: the If/ElseIf form was measured and is 523 bytes but
' MISMATCHes, because it emits each return next to its own test.
'
' The trailing `Return 0` is a second, separate `mov eax,0` block in the original,
' distinct from the one Case "000000" jumps to -- so the default really is written out.
	Function ColourIndex:Int(a0:String)
		Select a0
			Case "000000"
				Return 0
			Case "FFFFFF"
				Return 1
			Case "FF0000"
				Return 2
			Case "00FF00"
				Return 3
			Case "0000FF"
				Return 4
			Case "FFFF00"
				Return 5
			Case "00FFFF"
				Return 6
			Case "800080"
				Return 7
			Case "FF6600"
				Return 8
			Case "999999"
				Return 9
			Case "970045"
				Return 10
			Case "FF00FF"
				Return 11
			Case "FCDB00"
				Return 12
			Case "8080FF"
				Return 13
			Case "000080"
				Return 14
			Case "008000"
				Return 15
			Case "800000"
				Return 16
		End Select
		Return 0
	End Function
