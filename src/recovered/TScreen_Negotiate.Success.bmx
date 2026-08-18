' TScreen_Negotiate.Success
' VA 0x0057aa30   208 bytes   class-table slot 0x44   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (208/208, original length from Ghidra's inventory, mode=reloc)
'
' GLOBAL NAMES ARE OURS. Types are load-bearing:
'   0x00C6CC40 Int, 0x00C6CC3C TContractOffer (assigned from the :TContractOffer parameter
'   of TScreen_Negotiate.SetUpScreen), 0x00C6C550 TSound, 0x00C6F090 TChannel,
'   0x00C5B1C8 TBitmapFont, 0x00C6EFE4/0x00C6EFE8 Int (screen w/h),
'   0x00C6CC10 TButton, 0x00C6F274 TImage.
'!Global g_neg_stage:Int
'!Global g_neg_offer:TContractOffer
'!Global g_snd_negotiate:TSound
'!Global g_chan_negotiate:TChannel
'!Global g_bigfont:TBitmapFont
'!Global g_screen_w:Int
'!Global g_screen_h:Int
'!Global g_neg_okbutton:TButton
'!Global g_img_negtick:TImage
	Function Success:Int()
		Local v:Int = (g_neg_stage - 1) * 10
		If v < 0 Or v > 40 Then v = 0
		g_neg_offer.IncreaseOffer(v)
		PlaySound(g_snd_negotiate, g_chan_negotiate)
		TScreenMessage.Create(g_screen_w / 2, g_screen_h / 2, GetText("Success!"), 1000, g_bigfont, Null, 1.0, "FFFFFF")
		g_neg_okbutton.SetIcon(g_img_negtick)
		g_neg_okbutton.Show()
	End Function
