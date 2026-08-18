' TPitch.SetUp
' VA 0x004e4a73   5312 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, class-table slot 0x30
' 5312/5312, original length from Ghidra's inventory. reloc_masked=504, learned_helpers=none.
' Re-verified with NSS5_NO_LEARN=1: still 5312/5312, so nothing here was masked by a name
' this probe taught the table.
'
' Match-boat / segmentation notes for anyone extending this: the body is nine repeated
' units and the whole thing came out length-exact on the first build. The only thing that
' blocked it was the 11 calls to the Engine.ini reader at 0x004BBFC1 (ReadSettingFloat),
' whose E8 operand is unmaskable until that module Function is itself recovered.
'
' ASSUMPTIONS -- every Global this body touches, with the reasoning
'   NAMES ARE OURS. Module Globals carry no debug record. All types below are read off the
'   code, not off globals_final.tsv, which types this whole block as bare `Object` /
'   `Object[]` with confidence=low.
'   0x00C5D5A4/A8/AC/B0/B4/B8/BC  g_pitchimg1/2/1b/2b/3/4, g_nsgimg        :TImage
'   0x00C5D5E4 g_dugoutimg  0x00C5D594 g_grassimg  0x00C5D5A0 g_mowsimg    :TImage
'   0x00C5D598 g_mow0img    0x00C5D59C g_mow1img                           :TImage
'   0x00C5D5C0/C4/C8/CC/D0  g_goal1img, g_goal1netimg, g_goal1shadowimg,
'                           g_goal2img, g_goal2shadowimg                   :TImage
'   0x00C5D5D4 g_flagimg                                                   :TImage
'   0x00C5D5E0 g_adboardimg[9]   0x00C5D5F4 g_stadiumimg[16]
'   0x00C5D600 g_stadiumgimg[6]  0x00C5D60C g_fansimg[6]                   :TImage[]
'     -- all four are element-assigned from LoadImageChecked/LoadAnimImage (:TImage) with
'        full retain/release traffic, and read at [base+idx*4+0x18] (BBArray data at +0x18).
'   0x00C5D628 g_pitchscale:Float   -- stored with a bare `fstp dword`, no bbFloatToInt.
'     original data-section value is 10.0 (the shipped Engine.ini pitchscale
'     default), read directly from NSS5.exe -- same address TPitch.PixelsToYards.bmx etc
'     use as the hardcoded literal 10.0, and TPlayer.DoDribbling/DoRepulsion.bmx read as
'     g_pitch_float01. See codegen-patterns 21.1/21.3.
'   0x00C5D634/38/3C/40/44/48/4C/50/58/5C  g_sideline, g_goalline, g_goalpost, g_postwidth,
'     g_crossbar, g_netline, g_penboxside, g_penboxd, g_penspoty, g_sixyardside  :Int
'     -- each is `Int(ReadSettingFloat(...))`; the names are the Engine.ini keys, which are
'        real content read out of the exe, not invented.
'   0x00C5D660 g_netliney:Int  0x00C5D674 g_dugouty:Int
'   0x00C5D66C g_pitchhalfwidth  0x00C5D670 g_pitchheight
'   0x00C5D664 g_pitchwidth      0x00C5D668 g_stadiumheight                :Int
'     -- all six are plain dword stores with no refcount traffic (patterns 10.7/11.2).
'
' OTHER ASSUMPTIONS
'   * 0x00C5D960 and 0x00C5D998 are TPitch's OWN class table + slots 0x34 / 0x6C, so they
'     are sibling Function calls written without a `TPitch.` prefix (patterns 3d).
'     0x00C5DDF0 = TCameraMan.SetUp, 0x00C5DC88 = TPhotographer.SetUp,
'     0x00C6B410 = TBossMessage.SetUp -- all slot 0x30, resolved via class_tables.tsv.
'   * 0x00C5C6AC = TKitStrings.CreateKitStrings slot 0x30, 0x00C5C4B8 = TKit.CreateKit
'     slot 0x38, and TKit slot 0x40 = GetPaintedFan(i,i):TPixmap -- from vtable_map.tsv.
'   * 0x005AE3C5 / 0x005AE3D4 are ImageWidth / ImageHeight. Those two names come from
'     brl_functions_inferred.tsv, not the exact table, so they are the weakest link here;
'     they are used 40+ times in this body and the whole thing is byte-exact with them.
'   * The five results of TKit.CreateKit after the first are genuinely DISCARDED -- there
'     is no store of eax anywhere after those calls, and `kit` stays live in esi across
'     all six GetPaintedFan calls. Written as bare expression statements because that is
'     what the code does; it looks like an original-source bug (five kits built and thrown
'     away) but it is not a reconstruction artefact.
'   * g_goal1shadowimg and g_goal2shadowimg take their x-handle from the GOAL image, not
'     from themselves (ImageWidth(g_goal1img) / ImageWidth(g_goal2img)). Confirmed against
'     the operands at 0x004E4E27 and 0x004E4F15 -- another original-source quirk.
'   * ReadSettingFloat (0x004BBFC1) is called with clamp range [0, 10000] every time.
'!Global g_pitchimg1:TImage
'!Global g_pitchimg2:TImage
'!Global g_pitchimg1b:TImage
'!Global g_pitchimg2b:TImage
'!Global g_pitchimg3:TImage
'!Global g_pitchimg4:TImage
'!Global g_nsgimg:TImage
'!Global g_dugoutimg:TImage
'!Global g_grassimg:TImage
'!Global g_mowsimg:TImage
'!Global g_mow0img:TImage
'!Global g_mow1img:TImage
'!Global g_goal1img:TImage
'!Global g_goal1netimg:TImage
'!Global g_goal1shadowimg:TImage
'!Global g_goal2img:TImage
'!Global g_goal2shadowimg:TImage
'!Global g_flagimg:TImage
'!Global g_adboardimg:TImage[]
'!Global g_pitchscale:Float = 10.0
'!Global g_sideline:Int
'!Global g_goalline:Int
'!Global g_goalpost:Int
'!Global g_postwidth:Int
'!Global g_crossbar:Int
'!Global g_netline:Int
'!Global g_penboxside:Int
'!Global g_penboxd:Int
'!Global g_penspoty:Int
'!Global g_sixyardside:Int
'!Global g_netliney:Int
'!Global g_dugouty:Int
'!Global g_stadiumimg:TImage[]
'!Global g_stadiumgimg:TImage[]
'!Global g_pitchhalfwidth:Int
'!Global g_pitchheight:Int
'!Global g_pitchwidth:Int
'!Global g_stadiumheight:Int
'!Global g_fansimg:TImage[]
	Function SetUp()
		RandomPitchType()
		g_pitchimg1 = LoadImageChecked("EngineMedia/Match/Pitch/Pitch1.png", -1)
		g_pitchimg2 = LoadImageChecked("EngineMedia/Match/Pitch/Pitch2.png", -1)
		g_pitchimg1b = LoadImageChecked("EngineMedia/Match/Pitch/Pitch1b.png", -1)
		g_pitchimg2b = LoadImageChecked("EngineMedia/Match/Pitch/Pitch2b.png", -1)
		g_pitchimg3 = LoadImageChecked("EngineMedia/Match/Pitch/Pitch3.png", -1)
		g_pitchimg4 = LoadImageChecked("EngineMedia/Match/Pitch/Pitch4.png", -1)
		g_nsgimg = LoadImageChecked("EngineMedia/Match/Pitch/NSG.png", -1)
		MidHandleImage(g_nsgimg)
		g_dugoutimg = LoadImageChecked("EngineMedia/Match/Pitch/Dugout.png", -1)
		MidHandleImage(g_dugoutimg)
		g_grassimg = LoadAnimImageChecked("EngineMedia/Match/Pitch/Grass.png", 256, 256, 0, 4, -1)
		g_mowsimg = LoadAnimImageChecked("EngineMedia/Match/Pitch/Mows.png", 128, 128, 0, 4, -1)
		g_mow0img = LoadImageChecked("EngineMedia/Match/Pitch/Mow0.png", -1)
		MidHandleImage(g_mow0img)
		g_mow1img = LoadImageChecked("EngineMedia/Match/Pitch/Mow1.png", -1)
		MidHandleImage(g_mow1img)
		g_goal1img = LoadImageChecked("EngineMedia/Match/Pitch/Goal1.png", -1)
		SetImageHandle(g_goal1img, ImageWidth(g_goal1img)/2, ImageHeight(g_goal1img))
		g_goal1netimg = LoadImageChecked("EngineMedia/Match/Pitch/Goal1_Net.png", -1)
		SetImageHandle(g_goal1netimg, ImageWidth(g_goal1netimg)/2, ImageHeight(g_goal1netimg))
		g_goal1shadowimg = LoadImageChecked("EngineMedia/Match/Pitch/Goal1_Shadow.png", -1)
		SetImageHandle(g_goal1shadowimg, ImageWidth(g_goal1img)/2, ImageHeight(g_goal1shadowimg))
		g_goal2img = LoadImageChecked("EngineMedia/Match/Pitch/Goal2.png", -1)
		SetImageHandle(g_goal2img, ImageWidth(g_goal2img)/2, ImageHeight(g_goal2img))
		g_goal2shadowimg = LoadImageChecked("EngineMedia/Match/Pitch/Goal2_Shadow.png", -1)
		SetImageHandle(g_goal2shadowimg, ImageWidth(g_goal2img)/2, ImageHeight(g_goal2shadowimg))
		g_flagimg = LoadAnimImageChecked("EngineMedia/Match/Pitch/Flag.png", 22, 64, 0, 2, -1)
		SetImageHandle(g_flagimg, 1, 63)
		For Local i:Int = 1 To 9
			g_adboardimg[i-1] = LoadImageChecked("EngineMedia/Match/Pitch/Ads/AdBoard_" + i + ".png", -1)
			SetImageHandle(g_adboardimg[i-1], 0, 31)
		Next
		g_pitchscale = ReadSettingFloat("incbin::Inc/Engine.ini", "pitchscale", 0, 10000.0)
		g_sideline = Int(ReadSettingFloat("incbin::Inc/Engine.ini", "sideline", 0, 10000.0))
		g_goalline = Int(ReadSettingFloat("incbin::Inc/Engine.ini", "goalline", 0, 10000.0))
		g_goalpost = Int(ReadSettingFloat("incbin::Inc/Engine.ini", "goalpost", 0, 10000.0))
		g_postwidth = Int(ReadSettingFloat("incbin::Inc/Engine.ini", "postwidth", 0, 10000.0))
		g_crossbar = Int(ReadSettingFloat("incbin::Inc/Engine.ini", "crossbar", 0, 10000.0))
		g_netline = Int(ReadSettingFloat("incbin::Inc/Engine.ini", "netline", 0, 10000.0))
		g_penboxside = Int(ReadSettingFloat("incbin::Inc/Engine.ini", "penboxside", 0, 10000.0))
		g_penboxd = Int(ReadSettingFloat("incbin::Inc/Engine.ini", "penboxd", 0, 10000.0))
		g_penspoty = Int(ReadSettingFloat("incbin::Inc/Engine.ini", "penspoty", 0, 10000.0))
		g_sixyardside = Int(ReadSettingFloat("incbin::Inc/Engine.ini", "sixyardside", 0, 10000.0))
		g_netliney = Int(g_goalline + YardsToPixels(9.5))
		g_dugouty = -g_sideline - 60
		g_stadiumimg[0] = LoadImageChecked("EngineMedia/Match/Pitch/StadiumTop.png", -1)
		g_stadiumimg[1] = LoadImageChecked("EngineMedia/Match/Pitch/StadiumBottom.png", -1)
		g_stadiumimg[2] = LoadImageChecked("EngineMedia/Match/Pitch/StadiumSide.png", -1)
		g_stadiumimg[3] = LoadImageChecked("EngineMedia/Match/Pitch/StadiumTunnel.png", -1)
		g_stadiumimg[4] = LoadImageChecked("EngineMedia/Match/Pitch/StadiumCornerTop.png", -1)
		g_stadiumimg[5] = LoadImageChecked("EngineMedia/Match/Pitch/StadiumCornerBottom.png", -1)
		g_stadiumimg[6] = LoadImageChecked("EngineMedia/Match/Pitch/StadiumRoofTop.png", -1)
		g_stadiumimg[7] = LoadImageChecked("EngineMedia/Match/Pitch/StadiumRoofBottom.png", -1)
		g_stadiumimg[8] = LoadImageChecked("EngineMedia/Match/Pitch/StadiumTunnelBarrier.png", -1)
		g_stadiumimg[9] = LoadImageChecked("EngineMedia/Match/Pitch/StadiumCornerTopGrass.png", -1)
		g_stadiumimg[10] = LoadImageChecked("EngineMedia/Match/Pitch/StadiumCornerBottomGrass.png", -1)
		g_stadiumimg[11] = LoadImageChecked("EngineMedia/Match/Pitch/StadiumTopGrass.png", -1)
		g_stadiumimg[12] = LoadImageChecked("EngineMedia/Match/Pitch/StadiumBottomGrass.png", -1)
		g_stadiumimg[13] = LoadImageChecked("EngineMedia/Match/Pitch/StadiumCornerTopGrass2.png", -1)
		g_stadiumimg[14] = LoadImageChecked("EngineMedia/Match/Pitch/StadiumSideGrass.png", -1)
		g_stadiumimg[15] = LoadImageChecked("EngineMedia/Match/Pitch/StadiumCornerBottomGrass2.png", -1)
		SetImageHandle(g_stadiumimg[0], 0, ImageHeight(g_stadiumimg[0])-1)
		SetImageHandle(g_stadiumimg[1], 0, 0)
		SetImageHandle(g_stadiumimg[2], ImageWidth(g_stadiumimg[2])-1, 0)
		SetImageHandle(g_stadiumimg[3], ImageWidth(g_stadiumimg[3])-1, 0)
		SetImageHandle(g_stadiumimg[4], ImageWidth(g_stadiumimg[4])-1, ImageHeight(g_stadiumimg[4])-1)
		SetImageHandle(g_stadiumimg[5], ImageWidth(g_stadiumimg[5])-1, 0)
		SetImageHandle(g_stadiumimg[6], ImageWidth(g_stadiumimg[6])-1, ImageHeight(g_stadiumimg[6])-1)
		SetImageHandle(g_stadiumimg[7], ImageWidth(g_stadiumimg[7])-1, 0)
		SetImageHandle(g_stadiumimg[8], ImageWidth(g_stadiumimg[8])-1, 0)
		SetImageHandle(g_stadiumimg[9], ImageWidth(g_stadiumimg[9])-1, ImageHeight(g_stadiumimg[9])-1)
		SetImageHandle(g_stadiumimg[10], ImageWidth(g_stadiumimg[10])-1, 0)
		SetImageHandle(g_stadiumimg[11], 0, ImageHeight(g_stadiumimg[11])-1)
		SetImageHandle(g_stadiumimg[12], 0, 0)
		SetImageHandle(g_stadiumimg[13], ImageWidth(g_stadiumimg[13])-1, ImageHeight(g_stadiumimg[13])-1)
		SetImageHandle(g_stadiumimg[14], ImageWidth(g_stadiumimg[14])-1, 0)
		SetImageHandle(g_stadiumimg[15], ImageWidth(g_stadiumimg[15])-1, 0)
		g_stadiumgimg[0] = LoadImageChecked("EngineMedia/Match/Pitch/StadiumTopG.png", -1)
		g_stadiumgimg[1] = LoadImageChecked("EngineMedia/Match/Pitch/StadiumBottomG.png", -1)
		g_stadiumgimg[2] = LoadImageChecked("EngineMedia/Match/Pitch/StadiumSideG.png", -1)
		g_stadiumgimg[3] = LoadImageChecked("EngineMedia/Match/Pitch/StadiumTunnelG.png", -1)
		g_stadiumgimg[4] = LoadImageChecked("EngineMedia/Match/Pitch/StadiumCornerTopG.png", -1)
		g_stadiumgimg[5] = LoadImageChecked("EngineMedia/Match/Pitch/StadiumCornerBottomG.png", -1)
		SetImageHandle(g_stadiumgimg[0], 0, ImageHeight(g_stadiumgimg[0])-1)
		SetImageHandle(g_stadiumgimg[1], 0, 0)
		SetImageHandle(g_stadiumgimg[2], ImageWidth(g_stadiumgimg[2])-1, 0)
		SetImageHandle(g_stadiumgimg[3], ImageWidth(g_stadiumgimg[3])-1, 0)
		SetImageHandle(g_stadiumgimg[4], ImageWidth(g_stadiumgimg[4])-1, ImageHeight(g_stadiumgimg[4])-1)
		SetImageHandle(g_stadiumgimg[5], ImageWidth(g_stadiumgimg[5])-1, 0)
		g_pitchhalfwidth = Int(ImageWidth(g_stadiumimg[0]) * 0.5)
		g_pitchheight = Int(ImageHeight(g_stadiumimg[0]) * 0.5)
		g_pitchwidth = g_pitchhalfwidth * 2
		g_stadiumheight = Int(g_pitchheight * 1.5)
		Local fanfile:String = "EngineMedia/Match/Pitch/Fans.png"
		Local kit:TKit = TKit.CreateKit(TKitStrings.CreateKitStrings("000000", "FFFFFF", "0000C0", "000000", "PLAIN"), fanfile)
		Local f0:TPixmap = kit.GetPaintedFan(Rand(0, 4), Rand(0, 2))
		Local f1:TPixmap = kit.GetPaintedFan(Rand(0, 4), Rand(0, 2))
		Local f2:TPixmap = kit.GetPaintedFan(Rand(0, 4), Rand(0, 2))
		Local f3:TPixmap = kit.GetPaintedFan(Rand(0, 4), Rand(0, 2))
		Local f4:TPixmap = kit.GetPaintedFan(Rand(0, 4), Rand(0, 2))
		Local f5:TPixmap = kit.GetPaintedFan(Rand(0, 4), Rand(0, 2))
		g_fansimg[0] = LoadAnimImage(f0, 64, 128, 0, 30, -1)
		TKit.CreateKit(TKitStrings.CreateKitStrings("FFFFFF", "000000", "0000C0", "000000", "PLAIN"), fanfile)
		g_fansimg[1] = LoadAnimImage(f1, 64, 128, 0, 30, -1)
		TKit.CreateKit(TKitStrings.CreateKitStrings("FF0000", "0000FF", "808000", "000000", "PLAIN"), fanfile)
		g_fansimg[2] = LoadAnimImage(f2, 64, 128, 0, 30, -1)
		TKit.CreateKit(TKitStrings.CreateKitStrings("00FF00", "FFFFFF", "8080FF", "000000", "PLAIN"), fanfile)
		g_fansimg[3] = LoadAnimImage(f3, 64, 128, 0, 30, -1)
		TKit.CreateKit(TKitStrings.CreateKitStrings("0000FF", "FFFF00", "C00000", "000000", "PLAIN"), fanfile)
		g_fansimg[4] = LoadAnimImage(f4, 64, 128, 0, 30, -1)
		TKit.CreateKit(TKitStrings.CreateKitStrings("FFFF00", "00FF00", "8080FF", "000000", "PLAIN"), fanfile)
		g_fansimg[5] = LoadAnimImage(f5, 64, 128, 0, 30, -1)
		For Local i:Int = 0 To 5
			MidHandleImage(g_fansimg[i])
		Next
		TCameraMan.SetUp()
		TPhotographer.SetUp()
		TBossMessage.SetUp()
	End Function
