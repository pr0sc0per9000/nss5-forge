' TScreen_Negotiate.Fail
' VA 0x0057AB00   212 bytes   class-table slot 0x48   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (212/212, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=20)
'
' ASSUMPTIONS
'  Module Globals -- NAMES ARE OURS, declared TYPES are load-bearing (they pick the slot):
'    0x00C6CC40 Int            g_neg_stage      (globals_final: Int, usage/medium)
'    0x00C6CC3C TContractOffer g_neg_offer      (globals_final says Object/low; typed
'                                                TContractOffer to agree with the already
'                                                verified TScreen_Negotiate.Success /
'                                                .ButtonAccept / .UpdateInstrucs)
'    0x00C6B850 TSound         g_snd_fail       (arg1 of _brl_audio_PlaySound)
'    0x00C6F090 TChannel       g_chan_negotiate (arg2 of _brl_audio_PlaySound)
'    0x00C5B1C8 TBitmapFont    g_bigfont        (globals_final: construction/medium)
'    0x00C6EFE4 Int            g_screen_w
'    0x00C6EFE8 Int            g_screen_h
'    0x00C6CC10 TButton        g_neg_okbutton   (globals_final: construction/medium)
'    0x00C6F1B8 TImage         g_img_negcross   (arg of TButton.SetIcon(:TImage))
'  Field: TContractOffer +0x24 = newbossrel:Int (object_model.json).
'  Slots resolved:
'    [0x00C67D60] = TScreen_ContractOffer class table + 0x3C = UpdateOfferDetails(i,i)i
'    [0x00C6CDC4] = TScreen_Negotiate     class table + 0x4C = UpdateInstrucs()i
'                   -> sibling Function of THIS Type, written WITHOUT the `TScreen_Negotiate.` prefix
'    [0x00C6B264] = TScreenMessage        class table + 0x30 = Create(i,i,$,i,:TBitmapFont,:TImage,f,$)i
'    TButton slot 0x90 = TButton.SetIcon(:TImage)
'    TButton slot 0x58 = TGadget.Show()      (INHERITED -- TButton has no 0x58 of its own)
'  BRL: 0x0059F089 = Rand, 0x0059B25E = PlaySound, 0x004C5549 = GetText (module Function,
'       ONE argument -- `add esp,4` after the call; the other five pushes at 0x0057AB55
'       belong to the following TScreenMessage.Create).
'  Literals: 0x00C91604 = "Fail!", 0x00C5D680 = "FFFFFF" (decoded from the BBString
'       structures in NSS5.exe .data).
'  0x00C6CC3C is loaded TWICE (esi then eax) before the subtract, and the store is
'  `sub ebx,eax / mov [esi+0x24],ebx` -- i.e. the plain `a = a - b` form, not `:-`.
	'!Global g_neg_stage:Int
	'!Global g_neg_offer:TContractOffer
	'!Global g_snd_fail:TSound
	'!Global g_chan_negotiate:TChannel
	'!Global g_bigfont:TBitmapFont
	'!Global g_screen_w:Int
	'!Global g_screen_h:Int
	'!Global g_neg_okbutton:TButton
	'!Global g_img_negcross:TImage
	Function Fail:Int()
		g_neg_stage = 99
		g_neg_offer.newbossrel = g_neg_offer.newbossrel - Rand(10, 20)
		TScreen_ContractOffer.UpdateOfferDetails(0, 0)
		UpdateInstrucs()
		PlaySound(g_snd_fail, g_chan_negotiate)
		TScreenMessage.Create(g_screen_w / 2, g_screen_h / 2, GetText("Fail!"), 1000, g_bigfont, Null, 1.0, "FFFFFF")
		g_neg_okbutton.SetIcon(g_img_negcross)
		g_neg_okbutton.Show()
	End Function
