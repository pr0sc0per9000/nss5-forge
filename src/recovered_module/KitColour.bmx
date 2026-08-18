' KitColour  -- module-level Function (name ours; module Functions have no debug record)
' VA 0x00506DE2   240 bytes   sig (i)$   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG (i)$
' (240/240, original length from Ghidra's inventory, reloc_masked=19; verified with
'  NSS5_NO_LEARN=1 so no call operand was masked by a name this run itself taught.)
'
' ASSUMPTIONS
'   Name is ours.  It maps a small integer to a kit-colour hex string; the -1 sentinel
'   picks a random one from the first thirteen.  Five call sites; four of them are in
'   TScreen_EditKits.CreateScreen, which feeds the result straight into TCombo.AddItem's
'   "colour" argument for indices 0..16 of the shirt/shorts/socks colour combos.
'   The parameter is NOT written back: the original does `mov eax,[ebp+8]`, conditionally
'   overwrites eax with the Rand result, and Selects on eax with no store to [ebp+8] and
'   no `sub esp` at all.  That is a Local held entirely in eax (codegen-patterns 16.2),
'   which is also what fixes the `Local c:Int = a0` spelling here.
'   0x0059F089 = _brl_random_Rand: `push 0xc / push 0` is Rand(0, 12), pushes being
'   right-to-left.  The trailing "" is reached by the compare block's fall-through jump,
'   so it is the no-match path; Default and a statement after End Select emit the same
'   bytes here because every Case body Returns.
'
' Literals were read out of NSS5.exe with harness.read_string -- the oracle masks a
' literal's ADDRESS, so their CONTENT is certified by that read, not by the MATCH.
'   0x00C6FC58 '000000'  0x00C5D680 'FFFFFF'  0x00C725EC 'FF0000'  0x00C6E904 '00FF00'
'   0x00C72868 '0000FF'  0x00C725B8 'FFFF00'  0x00C75434 '00FFFF'  0x00C7BC58 '800080'
'   0x00C7BC70 'FF6600'  0x00C7532C '999999'  0x00C7BC88 '970045'  0x00C79720 'FF00FF'
'   0x00C7BCA0 'FCDB00'  0x00C78528 '8080FF'  0x00C785A4 '000080'  0x00C7BCB8 '008000'
'   0x00C785BC '800000'  0x005C7D40 ''
	Function KitColour:String(idx:Int)
		Local c:Int = idx
		If c = -1 Then c = Rand(0, 12)
		Select c
		Case 0
			Return "000000"
		Case 1
			Return "FFFFFF"
		Case 2
			Return "FF0000"
		Case 3
			Return "00FF00"
		Case 4
			Return "0000FF"
		Case 5
			Return "FFFF00"
		Case 6
			Return "00FFFF"
		Case 7
			Return "800080"
		Case 8
			Return "FF6600"
		Case 9
			Return "999999"
		Case 10
			Return "970045"
		Case 11
			Return "FF00FF"
		Case 12
			Return "FCDB00"
		Case 13
			Return "8080FF"
		Case 14
			Return "000080"
		Case 15
			Return "008000"
		Case 16
			Return "800000"
		End Select
		Return ""
	End Function
