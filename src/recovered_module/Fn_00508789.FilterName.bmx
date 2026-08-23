' FilterName  -- module-level Function (no Type). NAME IS OURS (no reflection record).
' VA 0x00508789   213 bytes   sig ($)$
' byte-identical vs NSS5.exe (213/213, original length from Ghidra's inventory), verified
' with harness.try_function under NSS5_NO_LEARN=1.
'
' Strips a string down to the characters allowed in a name: anything in the contiguous
' range 'A'(65) to 'z'(122), plus space(32), apostrophe(39), asterisk(42) and hyphen(45).
' Everything else is dropped.
'
' BUG (original), preserved: the range test is a single 65..122 span, so it also lets
' through the six punctuation characters that sit between 'Z' and 'a' in ASCII --
' [ \ ] ^ _ ` -- which a name filter plainly did not intend. The disassembly is a bare
' `cmp eax,0x41 / setge` followed by `cmp eax,0x7A / setle`, with no second range test.
'
' NOT CALLED FROM ANYWHERE in the shipped exe (brute scan of every E8/E9 rel32: zero call
' sites). Found by the unrecovered-function audit; see
' docs/reference/unrecovered-inventory.md.
'
' The four singleton characters are compared with `sete`, so they are equality tests
' against the literal codes, not membership in a string. The whole condition short-circuits
' left to right, which is what the chain of `cmp eax,0 / jne` between the tests encodes:
' `And` stops on the first false, `Or` on the first true.
	Function FilterName:String(a0:String)
		Local result:String = ""
		For Local i:Int = 0 To a0.length - 1
			If (a0[i] >= 65 And a0[i] <= 122) Or a0[i] = 32 Or a0[i] = 39 Or a0[i] = 42 Or a0[i] = 45
				result :+ Chr(a0[i])
			EndIf
		Next
		Return result
	End Function
