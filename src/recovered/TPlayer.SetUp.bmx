' TPlayer.SetUp
' VA 0x004EC179   4821 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, class-table slot 0x30
' 4821/4821, original length from Ghidra's inventory. reloc_masked=401, learned_helpers=none.
' Re-verified with NSS5_NO_LEARN=1: still 4821/4821, so nothing here was masked by a name
' this probe taught the table.
'
' Every string literal below was read out of NSS5.exe with harness.read_string() -- all 46
' of them. A MATCH does not certify literal CONTENT (the oracle masks the literal's
' ADDRESS), so this was done by hand rather than trusted to the oracle.
'
' SEGMENTATION, for anyone extending this. Six blocks, in source order:
'   1. sprite metrics from Engine.ini            (1 String + 5 Int + 1 Float)
'   2. 32 Int[] animation-frame tables written as array literals
'   3. 3 x  read a CSV setting -> SplitString2 -> resize the target array -> parse each field
'   4. 5 image loads with SetImageHandle / MidHandleImage
'   5. 29 physics/tuning constants from Engine.ini
'   6. 6 lazily-initialised channels and sounds
'
' THREE THINGS DECIDED THE MATCH, all of them byte-observable and none of them visible in
' the decompilation:
'
'   (a) The six lazy-init guards in block 6 are `If Not g` (21 bytes: mov/cmp/setne/movzx/
'       cmp/jne), NOT `If g = Null` (12 bytes) -- pattern 10.3. Ghidra prints both as
'       `if (g == Null)`. This alone was the whole 54-byte length deficit: 6 x 9.
'
'   (b) ONE loop counter is reused across the three CSV loops, not three counters. The
'       original's frame is `sub esp,0x14`; three counters give `sub esp,0x1c`. Ghidra
'       agrees -- it prints a single `local_c` -- but it is easy to miss.
'
'   (c) The ReadSettingString result in block 3 is a String LOCAL, not a nested argument:
'         Local ln:String = ReadSettingString(...)
'         Local jf:String[] = SplitString2(ln, ",")
'       Written nested, `SplitString2(ReadSettingString(...), ",")` is the SAME LENGTH but
'       orders the pushes differently, so it never converges by length alone. bcc pushes
'       arguments right-to-left and evaluates a nested first-arg call LAST -- confirmed
'       against the verified TEngine.RenderGameEngine at 0x004CF9F7, where
'       `DrawText(TEngine.GetStringMatchState(), x, y)` pushes x and y and only then calls
'       GetStringMatchState. The original here calls ReadSettingString FIRST and pushes ","
'       afterwards, which is the two-statement form. The String Local costs no bytes: it
'       stays in eax and takes no refcount traffic and no stack slot.
'
' ASSUMPTIONS -- every Global this body touches. NAMES ARE OURS; module Globals carry no
' debug record. Types are read off the code (refcount traffic decides object-vs-Int,
' patterns 10.7/11.2), not off globals_final.tsv, which types most of this block as bare
' `Object` / `Object[]` with confidence=low.
'
'   0x00C5DE2C g_player_spritename  :String  -- full retain/release around the store, so it
'              is a reference, not the Int that globals_final.tsv claims.
'   0x00C5DE30/34/38/3C/40  spritewidth, spriteheight, spritecount, handlex, handley :Int
'              -- each is Int(ReadSettingFloat(...)), i.e. a bbFloatToInt result.
'   0x00C5DE44 g_player_spritescale :Float  -- bare `fstp dword`, no bbFloatToInt.
'
'   0x00C5DEAC..0x00C5DF28  g_player_arr01..arr32  :Int[]
'              -- the element-type descriptor passed to bbArrayNew1D/bbArraySlice is
'                 0x00C59097, whose first byte is 0x69 = 'i' = Int. That is direct
'                 evidence, not inference, and it makes arr01-arr32 uniformly Int[].
'                 globals_final.tsv types most of them Object[]; it is wrong (11.2).
'              -- arr30/arr31/arr32 are the jumpframes / fallframes / holdballframes
'                 tables; the other 29 are literal-initialised animation frame sequences.
'              -- the assignment order is NOT address order: arr24 and arr25 are written
'                 before arr22 and arr23. That is what the original does.
'
'   0x00C5DE18 g_player_highlightimg      0x00C5DE1C g_player_arrowgreenimg
'   0x00C5DE20 g_player_arrowyellowimg    0x00C5DE24 g_player_offsideflagimg
'   0x00C5DE28 g_player_speechimg                                            :TImage
'   0x00C5DF2C g_player_slidechannel      0x00C5DF30 g_player_oofchannel     :TChannel
'   0x00C5DF34 g_player_slidesnd          0x00C5DF38 g_player_oofsnd
'   0x00C5DF3C g_player_boozedupsnd       0x00C5DF40 g_player_trainingerrorsnd :TSound
'              -- typed from what is stored into them: LoadImageChecked/
'                 LoadAnimImageChecked return TImage, AllocChannel returns TChannel,
'                 LoadSoundChecked returns TSound.
'
'   0x00C5DE48..0x00C5DEA0 and 0x00C5DEA8  the 29 tuning constants. Float where the store
'              is `fstp dword`, Int where the value goes through bbFloatToInt:
'                Int   framelength(0x..EA8) jumpspotradius(0x..E6C) playerheight(0x..E70)
'                      playerradius(0x..E74) highlightpass(0x..E80)
'                Float everything else.
'              -- the NAMES of all 29 are the Engine.ini keys, which are real content read
'                 out of the exe, not invented.
'
' OTHER NOTES
'   * The clamp ranges passed to ReadSettingFloat vary per key and are read off the pushed
'     immediates: 1280.0 for the sprite block, 10000.0 nowhere here (unlike TPitch.SetUp),
'     0.001/0.005 for energydrain, 0.01/10.0 for the four kickdistratio keys.
'   * The three CSV loops are `For ... EachIn` over the SplitString2 result. EachIn emits
'     its own null-skip (pattern 10.6); the `if (puVar2 != Null)` Ghidra prints is that,
'     not source. Only the third loop also calls LogLine("Adding:" + s) -- the first two
'     do not, which looks like an original-source inconsistency but is what the bytes say.
'   * `g_player_arr30 = g_player_arr30[..jf.Length]` is the bbArraySlice at 0x004ECC77.
'     `.Length` reads scales[0] at +0x14, which is what the original pushes (pattern 11.1).
'   * CAVEAT ON THREE CALLEES: LoadImageChecked / LoadAnimImageChecked / LoadSoundChecked
'     carry "NOT CERTIFIED" headers in src/recovered_module/. Their E8 operands
'     here mask by name on both sides, and their VAs are established independently by the
'     callgraph (240 / 29 / 57 agreeing call sites), but if one of those three bodies is
'     ever found to be the wrong function, the corresponding calls here inherit that doubt.
'     Nothing else in this body depends on them.
'!Global g_player_spritename:String
'!Global g_player_spritewidth:Int
'!Global g_player_spriteheight:Int
'!Global g_player_spritecount:Int
'!Global g_player_handlex:Int
'!Global g_player_handley:Int
'!Global g_player_spritescale:Float
'!Global g_player_arr01:Int[]
'!Global g_player_arr02:Int[]
'!Global g_player_arr03:Int[]
'!Global g_player_arr04:Int[]
'!Global g_player_arr05:Int[]
'!Global g_player_arr06:Int[]
'!Global g_player_arr07:Int[]
'!Global g_player_arr08:Int[]
'!Global g_player_arr09:Int[]
'!Global g_player_arr10:Int[]
'!Global g_player_arr11:Int[]
'!Global g_player_arr12:Int[]
'!Global g_player_arr13:Int[]
'!Global g_player_arr14:Int[]
'!Global g_player_arr15:Int[]
'!Global g_player_arr16:Int[]
'!Global g_player_arr17:Int[]
'!Global g_player_arr18:Int[]
'!Global g_player_arr19:Int[]
'!Global g_player_arr20:Int[]
'!Global g_player_arr21:Int[]
'!Global g_player_arr22:Int[]
'!Global g_player_arr23:Int[]
'!Global g_player_arr24:Int[]
'!Global g_player_arr25:Int[]
'!Global g_player_arr26:Int[]
'!Global g_player_arr27:Int[]
'!Global g_player_arr28:Int[]
'!Global g_player_arr29:Int[]
'!Global g_player_arr30:Int[]
'!Global g_player_arr31:Int[]
'!Global g_player_arr32:Int[]
'!Global g_player_arrowgreenimg:TImage
'!Global g_player_arrowyellowimg:TImage
'!Global g_player_highlightimg:TImage
'!Global g_player_offsideflagimg:TImage
'!Global g_player_speechimg:TImage
'!Global g_player_accel:Float
'!Global g_player_keeperaccel:Float
'!Global g_player_friction:Float
'!Global g_player_slidefriction:Float
'!Global g_player_slidevelocity:Float
'!Global g_player_jumpvelocity:Float
'!Global g_player_joggingspeed:Float
'!Global g_player_walkingspeed:Float
'!Global g_player_framelength:Int
'!Global g_player_touchdistball:Float
'!Global g_player_jumpspotradius:Int
'!Global g_player_height:Int
'!Global g_player_radius:Int
'!Global g_player_turningcircle:Float
'!Global g_player_powerbarspeed:Float
'!Global g_player_highlightpass:Int
'!Global g_player_shotpowerparry:Float
'!Global g_player_shotdistanceparry:Float
'!Global g_player_injuryfrequency:Float
'!Global g_player_energydrain:Float
'!Global g_player_kickratioshoot:Float
'!Global g_player_kickratiolob:Float
'!Global g_player_kickratiopass:Float
'!Global g_player_kickratiocross:Float
'!Global g_player_slidechannel:TChannel
'!Global g_player_oofchannel:TChannel
'!Global g_player_slidesnd:TSound
'!Global g_player_oofsnd:TSound
'!Global g_player_boozedupsnd:TSound
'!Global g_player_trainingerrorsnd:TSound
	Function SetUp()
		g_player_spritename = ReadSettingString("incbin::Inc/Engine.ini", "spritename_player")
		g_player_spritewidth = Int(ReadSettingFloat("incbin::Inc/Engine.ini", "spritewidth_player", 0, 1280.0))
		g_player_spriteheight = Int(ReadSettingFloat("incbin::Inc/Engine.ini", "spriteheight_player", 0, 1280.0))
		g_player_spritecount = Int(ReadSettingFloat("incbin::Inc/Engine.ini", "spritecount_player", 0, 1280.0))
		g_player_handlex = Int(ReadSettingFloat("incbin::Inc/Engine.ini", "handlex_player", 0, 1280.0))
		g_player_handley = Int(ReadSettingFloat("incbin::Inc/Engine.ini", "handley_player", 0, 1280.0))
		g_player_spritescale = ReadSettingFloat("incbin::Inc/Engine.ini", "spritescale", 0.1, 10.0)
		g_player_arr01 = [0,0,0,0,0,1,1,1,1,1]
		g_player_arr02 = [2,3,4,5,6,7]
		g_player_arr03 = [34,34,-1]
		g_player_arr04 = [18,18,18,19,19,19,-1]
		g_player_arr05 = [8,9,10,10,10,10,10,-1]
		g_player_arr06 = [11,12,12,12,12,12,12,12,-1]
		g_player_arr07 = [13,14,14,14,14,14,14,14,14,-1]
		g_player_arr08 = [16,-1]
		g_player_arr09 = [17,17,17,-1]
		g_player_arr10 = [15]
		g_player_arr11 = [20,21,22,23,22,21,20,24,25,26,27,26,25,24]
		g_player_arr12 = [20,21,21]
		g_player_arr13 = [24,25,26,27,28,29]
		g_player_arr14 = [15]
		g_player_arr15 = [20,21,21]
		g_player_arr16 = [30]
		g_player_arr17 = [22]
		g_player_arr18 = [23]
		g_player_arr19 = [48,48,48,48,48,49,49,49,49,49]
		g_player_arr20 = [50]
		g_player_arr21 = [51,52,50,53,54,50]
		g_player_arr24 = [55,56,57,57,57,57,56,-1]
		g_player_arr25 = [58,-1]
		g_player_arr22 = [59,60,60,61,61,61,61,61,61,61,-1]
		g_player_arr23 = [59,59,59,61,61,61,61,-1]
		g_player_arr26 = [56,56,56,56,56,56,-1]
		g_player_arr27 = [50,50,50,50,50,50,-1]
		g_player_arr28 = [62,62,62,62,62,62,-1]
		g_player_arr29 = [63,63,63,63,63,63,-1]
		Local ln:String = ReadSettingString("incbin::Inc/Engine.ini", "jumpframes")
		Local jf:String[] = SplitString2(ln, ",")
		g_player_arr30 = g_player_arr30[..jf.Length]
		Local n:Int = 0
		For Local s:String = EachIn jf
			g_player_arr30[n] = Int(s)
			n = n + 1
		Next
		ln = ReadSettingString("incbin::Inc/Engine.ini", "fallframes")
		Local ff:String[] = SplitString2(ln, ",")
		g_player_arr31 = g_player_arr31[..ff.Length]
		n = 0
		For Local s2:String = EachIn ff
			g_player_arr31[n] = Int(s2)
			n = n + 1
		Next
		ln = ReadSettingString("incbin::Inc/Engine.ini", "holdballframes")
		Local hf:String[] = SplitString2(ln, ",")
		g_player_arr32 = g_player_arr32[..hf.Length]
		n = 0
		For Local s3:String = EachIn hf
			g_player_arr32[n] = Int(s3)
			LogLine("Adding:" + s3)
			n = n + 1
		Next
		g_player_arrowgreenimg = LoadAnimImageChecked("EngineMedia/Match/Player/ArrowGreen.png", 84, 61, 0, 20, -1)
		SetImageHandle(g_player_arrowgreenimg, 14, 31)
		g_player_arrowyellowimg = LoadAnimImageChecked("EngineMedia/Match/Player/ArrowYellow.png", 84, 61, 0, 20, -1)
		SetImageHandle(g_player_arrowyellowimg, 14, 31)
		g_player_highlightimg = LoadImageChecked("EngineMedia/Match/Player/Highlight.png", -1)
		MidHandleImage(g_player_highlightimg)
		g_player_offsideflagimg = LoadImageChecked("EngineMedia/Match/Player/OffsideFlag.png", -1)
		MidHandleImage(g_player_offsideflagimg)
		g_player_speechimg = LoadImageChecked("EngineMedia/Match/Player/Speech.png", -1)
		MidHandleImage(g_player_speechimg)
		g_player_accel = ReadSettingFloat("incbin::Inc/Engine.ini", "acceleration", 0, 100.0)
		g_player_keeperaccel = ReadSettingFloat("incbin::Inc/Engine.ini", "keeperaccel", 0.5, 1.0)
		g_player_friction = ReadSettingFloat("incbin::Inc/Engine.ini", "playerfriction", 0, 1.0)
		g_player_slidefriction = ReadSettingFloat("incbin::Inc/Engine.ini", "slidefriction", 0, 1.0)
		g_player_slidevelocity = ReadSettingFloat("incbin::Inc/Engine.ini", "slidevelocity", 0, 10.0)
		g_player_jumpvelocity = ReadSettingFloat("incbin::Inc/Engine.ini", "jumpvelocity", 0, 10.0)
		g_player_joggingspeed = ReadSettingFloat("incbin::Inc/Engine.ini", "joggingspeed", 0, 1.0)
		g_player_walkingspeed = ReadSettingFloat("incbin::Inc/Engine.ini", "walkingspeed", 0, 1.0)
		g_player_framelength = Int(ReadSettingFloat("incbin::Inc/Engine.ini", "framelength", 0, 1000.0))
		g_player_touchdistball = ReadSettingFloat("incbin::Inc/Engine.ini", "touchdist_ball", 0, 1000.0)
		g_player_jumpspotradius = Int(ReadSettingFloat("incbin::Inc/Engine.ini", "jumpspotradius", 0, 1000.0))
		g_player_height = Int(ReadSettingFloat("incbin::Inc/Engine.ini", "playerheight", 0, 1000.0))
		g_player_radius = Int(ReadSettingFloat("incbin::Inc/Engine.ini", "playerradius", 0, 1000.0))
		g_player_turningcircle = ReadSettingFloat("incbin::Inc/Engine.ini", "turningcircle", 0, 1.0)
		g_player_powerbarspeed = ReadSettingFloat("incbin::Inc/Engine.ini", "powerbarspeed", 0, 10.0)
		g_player_highlightpass = Int(ReadSettingFloat("incbin::Inc/Engine.ini", "highlightpass", 0, 1.0))
		g_player_shotpowerparry = ReadSettingFloat("incbin::Inc/Engine.ini", "shotpowerparry", 1.0, 100.0)
		g_player_shotdistanceparry = ReadSettingFloat("incbin::Inc/Engine.ini", "shotdistanceparry", 1.0, 100.0)
		g_player_injuryfrequency = ReadSettingFloat("incbin::Inc/Engine.ini", "injuryfrequency", 1.0, 100.0)
		g_player_energydrain = ReadSettingFloat("incbin::Inc/Engine.ini", "energydrain", 0.001, 0.005)
		g_player_kickratioshoot = ReadSettingFloat("incbin::Inc/Engine.ini", "kickdistratio_shoot", 0.01, 10.0)
		g_player_kickratiolob = ReadSettingFloat("incbin::Inc/Engine.ini", "kickdistratio_lob", 0.01, 10.0)
		g_player_kickratiopass = ReadSettingFloat("incbin::Inc/Engine.ini", "kickdistratio_pass", 0.01, 10.0)
		g_player_kickratiocross = ReadSettingFloat("incbin::Inc/Engine.ini", "kickdistratio_cross", 0.01, 10.0)
		If Not g_player_slidechannel Then g_player_slidechannel = AllocChannel()
		If Not g_player_oofchannel Then g_player_oofchannel = AllocChannel()
		If Not g_player_slidesnd Then g_player_slidesnd = LoadSoundChecked("EngineMedia/Match/Sounds/Slide.ogg", 0)
		If Not g_player_oofsnd Then g_player_oofsnd = LoadSoundChecked("EngineMedia/Match/Sounds/Oof.ogg", 0)
		If Not g_player_boozedupsnd Then g_player_boozedupsnd = LoadSoundChecked("EngineMedia/Match/Sounds/BoozedUp.ogg", 0)
		If Not g_player_trainingerrorsnd Then g_player_trainingerrorsnd = LoadSoundChecked("EngineMedia/Match/Sounds/TrainingError.ogg", 0)
	End Function
