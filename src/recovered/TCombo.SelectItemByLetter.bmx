' TCombo.SelectItemByLetter
' VA 0x005190E6   332 bytes   vtable slot 0xB4   sig (i)i
' byte-identical vs NSS5.exe (332/332, original length from Ghidra's inventory)

' CASE DIRECTION CORRECTED 2026-08-22: 1 call site -> .ToUpper(), 1 call site -> .ToLower().
' extracted/runtime_helpers.tsv named 0x004A7410 `_brl_retro_Lower` and 0x004A74E0
' `_brl_retro_Upper`. Both were wrong and neither address is a brl.retro wrapper:
' 0x004A7410 is `_bbStringToUpper` and 0x004A74E0 is `_bbStringToLower`. NSS5.exe's
' own 21-byte retro wrappers at 0x0059C8FD (Lower) and 0x0059C912 (Upper) CALL those
' two addresses, and a wrapper cannot be the function it calls. The wrong row masked
' by name, so this body certified with the case conversion running backwards. Full
' derivation and the discriminating 3x4 matrix: docs/reference/codegen-patterns.md
' 15.6. Re-verified under NSS5_NO_LEARN=1 on worker trees 380 and 380b.
LogLine("SelectItemByLetter" + a0)
itemoffset = 0
selecteditem = 0
For Local b:TButton = EachIn buttons
	ScrollDown()
	If Left(b.txt, 1).ToLower() = Chr(a0) Or Left(b.txt, 1).ToUpper() = Chr(a0) Then Return 0
Next
LogLine("Letter not in list")
itemoffset = 0
selecteditem = 1
