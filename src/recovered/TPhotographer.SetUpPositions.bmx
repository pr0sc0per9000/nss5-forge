' TPhotographer.SetUpPositions
' VA        0x004EA682   2652 bytes   slot 0x38   KIND=Function (static)   SIG=()i
' ORACLE    MATCH mode=reloc  2652/2652 bytes  reloc_masked=163
' byte-identical vs NSS5.exe
'
' GLOBALS DECLARED (names are ours, already established by TPhotographer.SetUp -- the
' TYPES are load-bearing)
'   g_photographer_int01:Int  = 0x00C5DB2C   (camerax1 setting)
'   g_photographer_int02:Int  = 0x00C5DB30   (cameray1 setting)
'   g_photographer_int03:Int  = 0x00C5DB34   (camerax2 setting)
'   g_photographer_int04:Int  = 0x00C5DB38   (cameray2 setting)
'   g_pitch_int21:Int         = 0x00C5D69C   (pitch size/level, same Global TCameraMan uses)
'   All five read with a bare `mov eax,[g]`, no refcount traffic -- Int.
'
' SLOT RESOLVED
'   0x00C5DC8C -> TPhotographer classtable + 0x34 = TPhotographer.Create(f,f,i,i)i
'   (already verified, src/recovered/TPhotographer.Create.bmx)
'
' SHAPE
'   Twenty-eight photographer placements, each `TPhotographer.Create(x, y, facing, Rand(0,2))`.
'   `Rand(0,2)` is the LAST call argument; bcc evaluates arguments right-to-left, so the
'   decompilation's `uVar1 = Rand(0,2)` immediately before each Create call is simply that
'   argument being evaluated first -- no Local needed, matching the already-verified
'   TCameraMan.SetUpPositions twin (16.2/16.6 family).
'
'   Six groups of the same four-stand gadget (mirrored corners at +-(int03 +/- offset),
'   +-(int04 + offset)), each gated by `If g_pitch_int21 > 0` / `> 2` around the second half
'   of the group -- this is the SAME `TCameraMan.SetUpPositions`-style guard, just with an
'   extra gate because a photographer pitch has more corner slots than a camera pitch. The
'   final block (goal-line photographers) is gated `If g_pitch_int21 > 1`, with one more
'   `> 2`-gated Create nested on each side.
'
'   Ghidra's decompiler prints the "left/mirrored" offsets as `int03 + -0x28` etc; these are
'   plain subtractions (`int03 - 40`) in source -- same immediate either way.
'
' NO STRING LITERALS in this function (harness.read_string N/A).

'!Global g_photographer_int01:Int
'!Global g_photographer_int02:Int
'!Global g_photographer_int03:Int
'!Global g_photographer_int04:Int
'!Global g_pitch_int21:Int

TPhotographer.Create(-(g_photographer_int03 + 40), -(g_photographer_int04 + 4), 2, Rand(0,2))
If g_pitch_int21 > 0
	TPhotographer.Create(-(g_photographer_int03 + 55), -(g_photographer_int04 + 5), 2, Rand(0,2))
	TPhotographer.Create(-(g_photographer_int03 + 70), -(g_photographer_int04 + 1), 2, Rand(0,2))
	TPhotographer.Create(-(g_photographer_int03 + 85), -(g_photographer_int04 + 2), 2, Rand(0,2))
EndIf
If g_pitch_int21 > 2
	TPhotographer.Create(-(g_photographer_int03 - 40), -(g_photographer_int04 + 4), 2, Rand(0,2))
	TPhotographer.Create(-(g_photographer_int03 - 55), -(g_photographer_int04 + 5), 2, Rand(0,2))
	TPhotographer.Create(-(g_photographer_int03 - 70), -(g_photographer_int04 + 1), 2, Rand(0,2))
	TPhotographer.Create(-(g_photographer_int03 - 85), -(g_photographer_int04 + 2), 2, Rand(0,2))
EndIf

TPhotographer.Create((g_photographer_int03 + 40), -(g_photographer_int04 + 3), 2, Rand(0,2))
If g_pitch_int21 > 0
	TPhotographer.Create((g_photographer_int03 + 55), -(g_photographer_int04 + 5), 2, Rand(0,2))
	TPhotographer.Create((g_photographer_int03 + 70), -(g_photographer_int04 + 4), 2, Rand(0,2))
	TPhotographer.Create((g_photographer_int03 + 85), -(g_photographer_int04 + 1), 2, Rand(0,2))
EndIf
If g_pitch_int21 > 2
	TPhotographer.Create((g_photographer_int03 - 40), -(g_photographer_int04 + 3), 2, Rand(0,2))
	TPhotographer.Create((g_photographer_int03 - 55), -(g_photographer_int04 + 5), 2, Rand(0,2))
	TPhotographer.Create((g_photographer_int03 - 70), -(g_photographer_int04 + 4), 2, Rand(0,2))
	TPhotographer.Create((g_photographer_int03 - 85), -(g_photographer_int04 + 1), 2, Rand(0,2))
EndIf

TPhotographer.Create(-(g_photographer_int03 + 40), (g_photographer_int04 + 4), 1, Rand(0,2))
If g_pitch_int21 > 0
	TPhotographer.Create(-(g_photographer_int03 + 55), (g_photographer_int04 + 5), 1, Rand(0,2))
	TPhotographer.Create(-(g_photographer_int03 + 70), (g_photographer_int04 + 1), 1, Rand(0,2))
	TPhotographer.Create(-(g_photographer_int03 + 85), (g_photographer_int04 + 2), 1, Rand(0,2))
EndIf
If g_pitch_int21 > 2
	TPhotographer.Create(-(g_photographer_int03 - 40), (g_photographer_int04 + 4), 1, Rand(0,2))
	TPhotographer.Create(-(g_photographer_int03 - 55), (g_photographer_int04 + 5), 1, Rand(0,2))
	TPhotographer.Create(-(g_photographer_int03 - 70), (g_photographer_int04 + 1), 1, Rand(0,2))
	TPhotographer.Create(-(g_photographer_int03 - 85), (g_photographer_int04 + 2), 1, Rand(0,2))
EndIf

TPhotographer.Create((g_photographer_int03 + 40), (g_photographer_int04 + 3), 1, Rand(0,2))
If g_pitch_int21 > 0
	TPhotographer.Create((g_photographer_int03 + 55), (g_photographer_int04 + 5), 1, Rand(0,2))
	TPhotographer.Create((g_photographer_int03 + 70), (g_photographer_int04 + 4), 1, Rand(0,2))
	TPhotographer.Create((g_photographer_int03 + 85), (g_photographer_int04 + 1), 1, Rand(0,2))
EndIf
If g_pitch_int21 > 2
	TPhotographer.Create((g_photographer_int03 - 40), (g_photographer_int04 + 3), 1, Rand(0,2))
	TPhotographer.Create((g_photographer_int03 - 55), (g_photographer_int04 + 5), 1, Rand(0,2))
	TPhotographer.Create((g_photographer_int03 - 70), (g_photographer_int04 + 4), 1, Rand(0,2))
	TPhotographer.Create((g_photographer_int03 - 85), (g_photographer_int04 + 1), 1, Rand(0,2))
EndIf

If g_pitch_int21 > 1
	TPhotographer.Create(-g_photographer_int01, -(g_photographer_int02 + 150), 4, Rand(0,2))
	TPhotographer.Create(g_photographer_int01, -(g_photographer_int02 + 150), 3, Rand(0,2))
	If g_pitch_int21 > 2
		TPhotographer.Create(g_photographer_int01, -(g_photographer_int02 - 160), 3, Rand(0,2))
	EndIf
	TPhotographer.Create(-g_photographer_int01, (g_photographer_int02 + 150), 4, Rand(0,2))
	TPhotographer.Create(g_photographer_int01, (g_photographer_int02 + 150), 3, Rand(0,2))
	If g_pitch_int21 > 2
		TPhotographer.Create(g_photographer_int01, (g_photographer_int02 - 160), 3, Rand(0,2))
	EndIf
EndIf
