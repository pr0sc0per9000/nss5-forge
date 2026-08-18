' Rotr (name OURS -- module-level Function, no reflection record)
' VA 0x0058D072   34 bytes   KIND=Function, no Self.   sig (i,i)i
' byte-identical vs NSS5.exe (34/34, original length from Ghidra's inventory)
'
' Rotate-right, the SHA-256 primitive. Called TEN times from the 1,776-byte hash body at
' 0x0058C960, which is the single largest consumer of it in the game.
'
' `Shr` is BlitzMax's LOGICAL right shift (`Sar` is the arithmetic one) and that is what the
' original emits -- `shr eax,cl`, not `sar`. Getting that wrong would silently corrupt every
' digest for any input whose high bit is set.
'
' TWO SPELLINGS BOTH REACH 34/34, recorded so the next person does not re-run the
' experiment:
'     Return (a0 Shr a1) | (a0 Shl (32 - a1))                     <- this file
'     Local r:Int = a0 Shr a1 ; Local l:Int = a0 Shl (32 - a1) ; Return r | l
' bcc coalesces the two Locals into the same registers the one-liner uses, so they are
' indistinguishable in the output. The one-liner is kept because it is the smaller
' assumption, not because it is proven to be what Simon Read wrote.
'
' `Or` is NOT interchangeable with `|` here: `Return (a0 Shr a1) Or (a0 Shl (32 - a1))`
' compiles to 37 bytes, because BlitzMax's `Or` is the LOGICAL operator (it short-circuits
' and yields 0/1) while `|` is bitwise. Measured, not assumed.
	Function Rotr:Int(a0:Int, a1:Int)
		Return (a0 Shr a1) | (a0 Shl (32 - a1))
	End Function
