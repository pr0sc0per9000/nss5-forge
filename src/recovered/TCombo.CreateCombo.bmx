' TCombo.CreateCombo  -- KIND=Function (static method on TCombo), slot 0x88
' VA 0x00517FBF   478 bytes   sig ($,$,i,i,i,i,i,i,$,$,f,()i,i):TCombo
' byte-identical vs NSS5.exe (478/478, original length from Ghidra's inventory,
' mode=reloc, reloc_masked=25)
'
' ASSUMPTIONS
'  Module Global declared (name is ours):
'    0x00C62D9C g_comboimg : TImage  -- globals_final says "Object" (usage/low). TImage is
'                proved by the use: LoadImageChecked's return type feeds it and it is
'                passed to SetImageHandle / ImageHeight.
'  Class-table slots resolved:
'    [0x00C630F8] = TCombo + 0xA0 = Activate()i  -- stored into the fHit function-pointer
'                   field, so the source is the bare Function name `Activate`.
'    [0x00C623CC] = TButton + 0x88 =
'                   CreateButton($,$,i,i,i,i,i,i,$,$,:TImage,()i,f,i,$):TButton
'  Direct calls resolved:
'    0x004BC372 -> LoadImageChecked (src/recovered_module/LoadImageChecked.bmx)
'    0x005AE3D4 -> _brl_max2d_ImageHeight (brl_functions_inferred.tsv)
'    0x005AE336 -> _brl_max2d_SetImageHandle
'    0x005B40BF -> CreateList (alias set; the following TList store confirms it)
'    0x005B95D0 -> the null-function stub bcc pushes for a Null ()i argument
'  The two string literals (image path, and the trailing "" argument to CreateButton) are
'  absolute data addresses, so their TEXT is not recoverable -- "gfx/combo.png" is a guess;
'  only "a string constant is pushed here" is proven.
'  The leading test emits cmp/setne/movzx/cmp/jne, i.e. the `If Not x` form (guide 10.3),
'  not `If x = Null`.
'  Fields name/txt/x/y/w/h/alive/fntSize/colour/txtcolour/alph/fHit/desx/desy are
'  inherited from TGadget; btn_head/buttons/fRet/bstyle are TCombo's own.

	Function CreateCombo:TCombo(a0:String, a1:String, a2:Int, a3:Int, a4:Int, a5:Int, ..
			a6:Int, a7:Int, a8:String, a9:String, a10:Float, a11:Int(), a12:Int)
		'!Global g_comboimg:TImage
		If Not g_comboimg
			g_comboimg = LoadImageChecked("GameMedia/Images/Interface/Combo.png", -1)
			SetImageHandle(g_comboimg, 0, ImageHeight(g_comboimg) / 2)
		End If
		Local c:TCombo = New TCombo
		c.name = a0
		c.SetText(a1, "", -1, -1)
		c.x = a2
		c.desx = a2
		c.y = a3
		c.desy = a3
		c.w = a4
		c.h = a5
		c.alive = a6
		c.fntSize = a7
		c.colour = a8
		c.txtcolour = a9
		c.alph = a10
		c.fHit = Activate
		c.fRet = a11
		c.bstyle = a12
		c.buttons = CreateList()
		c.btn_head = TButton.CreateButton(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, ..
			Null, Null, a10, a12, "")
		Return c
	End Function
