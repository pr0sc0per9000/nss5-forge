' TKitStrings.ConvertNSS4ColourIndexToHex
' VA        0x004DC75B   slot 0x3C   KIND=Function (static)   SIG=(i)$
' ORACLE    MATCH mode=reloc  1025/1025 bytes  reloc_masked=32
'
' NO module Globals are used by this function.
'
' CALL TARGETS RESOLVED
'   0x005065A5 -> module Function RGBToHex(i,i,i)$ (src/recovered_module)
'   0x005C7D40 -> the shared empty BBString; `Return ""` (guide 3d)
'
' SOURCE FORM -- this cost one iteration, and the lesson generalises
'   It is a SELECT, not If/ElseIf: 31 `cmp eax,<n> / je <far>` back to back at
'   0x004DC761-0x004DC877 with every target past the last compare (guide 10.2).
'
'   The fallback is a `Return ""` AFTER `End Select`, NOT a `Default` clause. Both forms
'   put the empty-string body last in the image, so the decompilation cannot tell them
'   apart, but they differ by 5 bytes in the DISPATCH block:
'     * `Default` emits two 5-byte jumps after the last compare (one to the default body,
'        one past it) -- dispatch 289 bytes, whole function 1020.
'     * fallthrough-after-End-Select emits ONE 5-byte `jmp` (E9 D4 02 00 00 at 0x004DC878)
'        -- dispatch 284 bytes, whole function 1025. This is the original.
'   This is the guide-10.2 note about a Default-less Select, confirmed on a 31-case body:
'   count the jumps between the last `cmp` and the first case body.
'
'   Every case body is `Return RGBToHex(r,g,b)`: three 5-byte immediate pushes, the call,
'   `add esp,0xC`, then a jump straight to the epilogue. bcc uses the 5-byte `68 imm32`
'   push form even for values under 128, so no argument can be read off the encoding width.

Function ConvertNSS4ColourIndexToHex:String(a0:Int)
	Select a0
		Case 0
			Return RGBToHex(255, 255, 255)
		Case 1
			Return RGBToHex(255, 0, 0)
		Case 2
			Return RGBToHex(0, 0, 255)
		Case 3
			Return RGBToHex(0, 255, 255)
		Case 4
			Return RGBToHex(128, 0, 255)
		Case 5
			Return RGBToHex(255, 255, 0)
		Case 6
			Return RGBToHex(255, 0, 255)
		Case 7
			Return RGBToHex(0, 235, 0)
		Case 8
			Return RGBToHex(255, 90, 0)
		Case 9
			Return RGBToHex(0, 0, 0)
		Case 10
			Return RGBToHex(230, 180, 0)
		Case 11
			Return RGBToHex(120, 70, 30)
		Case 12
			Return RGBToHex(64, 0, 0)
		Case 13
			Return RGBToHex(205, 205, 205)
		Case 14
			Return RGBToHex(0, 0, 128)
		Case 15
			Return RGBToHex(128, 128, 255)
		Case 16
			Return RGBToHex(0, 128, 0)
		Case 17
			Return RGBToHex(192, 0, 0)
		Case 18
			Return RGBToHex(240, 230, 140)
		Case 19
			Return RGBToHex(255, 255, 224)
		Case 20
			Return RGBToHex(5, 205, 50)
		Case 21
			Return RGBToHex(225, 215, 155)
		Case 22
			Return RGBToHex(240, 240, 240)
		Case 23
			Return RGBToHex(75, 75, 75)
		Case 24
			Return RGBToHex(240, 200, 80)
		Case 25
			Return RGBToHex(0, 128, 125)
		Case 26
			Return RGBToHex(70, 50, 150)
		Case 27
			Return RGBToHex(50, 18, 122)
		Case 28
			Return RGBToHex(200, 230, 75)
		Case 29
			Return RGBToHex(217, 149, 172)
		Case 30
			Return RGBToHex(200, 162, 200)
	End Select
	Return ""
End Function
