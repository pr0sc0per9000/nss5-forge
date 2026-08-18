' THorse.Render  (KIND=Method, Self implicit; a0,a1,a2 = the three Floats)
' VA 0x0058AE38  LEN=536 bytes (full function, Ghidra-authoritative)
' ORACLE: mode=reloc  matched=536/536  reloc_masked=25  STATUS=MATCH
'
' ASSUMPTIONS / RESOLUTIONS
'   0x00C5B1B4 = TDrawOb class table + slot 0x34
'     -> TDrawOb.AddDrawOb(:TImage,f,f,f,i,i,f,i,$,f,f,i,f,$,i,i)i  -- SIXTEEN args.
'     Ghidra shows 9 args for the fourth call and 8 for the THorse slot-0x74 call; that is
'     the arg-merging artefact -- the 7 "extra" args on the slot-0x74 call are really
'     AddDrawOb's args 10..16. Arg counts were taken from the reflection signature and
'     confirmed by the match.
'   Slot 0x74 on THorse = THorse.GetHorseColour(i)$ -- a Function on THorse itself, so it
'     is written unqualified (sibling call, no `THorse.` prefix).
'   Module Globals declared (names ours; types load-bearing):
'     0x00C6E2BC g_horse_shadow:TImage
'     0x00C6E2C0 g_horse_marker:TImage
'     0x00C6E2C4 g_horse_owned:TImage
'       -- globals_final only has "Object/usage/low" for all three; typed TImage because
'          each is passed as AddDrawOb's declared :TImage first parameter.
'     0x00C6DF6C g_stable_racenum:Int   (globals_final Int/usage/medium)
'     0x00C6EFD4 g_player_int50:Int     (globals_final Int, type_source=VERIFIED)
'   Constants read out of the exe's .rdata: 0x00C94348 and 0x00C9434C are both 1.0 (two
'     separate constants -- bcc emits one per literal occurrence), 0x00C94354 = 64.0,
'     0x00C94350 = 24.0, 0x00C9435C = 16.0, 0x00C94358 = 24.0.
'     String at 0x00C5D680 = "FFFFFF"; 0x005C7D40 is the runtime empty string -> "".
'     Immediates 0x3F800000 = 1.0, 0x3F000000 = 0.5, 0x3F333333 = 0.7.
'
' CODEGEN NOTE
'   The two interpolated coordinates are Float Locals that DO get memory slots
'   ([ebp-4], [ebp-8], `sub esp,8`) because each is used four times.
'   The racenum/timer test is a NESTED If, not `And`. With `And` bcc materialises the
'   first comparison as sete/movzx/cmp (555 bytes, first diff at 296); nested it emits
'   `mov eax,[g] / cmp [ebx+0x60],eax / jne` directly and the function is 536 exact.
'   Note the cmp operand order: `cmp [Self+0x60], eax` == `Self.racenum = g_...`.

'!Global g_horse_shadow:TImage
'!Global g_horse_marker:TImage
'!Global g_horse_owned:TImage
'!Global g_stable_racenum:Int
'!Global g_player_int50:Int

Local xx:Float = Self.x*a0 + Self.oldx*(1.0 - a0)
Local yy:Float = Self.y*a0 + Self.oldy*(1.0 - a0)
TDrawOb.AddDrawOb(Self.image, xx+a1, yy+a2, 0, Self.frame, 3, 1.0, 0, "FFFFFF", 1.0, 1.0, 3, 0, "", 0, 0)
TDrawOb.AddDrawOb(Self.img_myjockey, xx+a1, yy+a2, 0, Self.frame, 4, 1.0, 0, "FFFFFF", 1.0, 1.0, 3, 0, "", 0, 0)
TDrawOb.AddDrawOb(g_horse_shadow, xx+a1, yy+a2, 0, Self.frame, 2, 0.5, 0, "FFFFFF", 1.0, 1.0, 3, 0, "", 0, 0)
If Self.racenum = g_stable_racenum
	If g_player_int50 Mod 1000 > 500
		TDrawOb.AddDrawOb(g_horse_marker, (xx+a1)-64.0, (yy+a2)-24.0, 0, 0, 4, 0.7, 0, GetHorseColour(Self.racenum), 1.0, 1.0, 3, 0, "", 0, 0)
	EndIf
EndIf
If Self.owned <> 0
	TDrawOb.AddDrawOb(g_horse_owned, (xx+a1)-16.0, yy+a2+24.0, 0, 0, 4, 0.7, 0, "FFFFFF", 0.5, 0.5, 3, 0, "", 0, 0)
EndIf
