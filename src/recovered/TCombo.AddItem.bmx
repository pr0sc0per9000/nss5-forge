' TCombo.AddItem
' VA 0x00518243   360 bytes   vtable slot 0x90   sig ($,$,$,i)i   KIND=Method
' byte-identical vs NSS5.exe (360/360, original length from Ghidra's inventory)
'
' TButton.CreateButton takes 15 arguments (add esp,0x3c). Argument 12 is a ()i function
' pointer and the original pushes 0x005B95D0, the empty function bcc uses for a null
' function pointer -- source is a plain `Null` (codegen-patterns 10.6).
	Method AddItem:Int(a0:String, a1:String, a2:String, a3:Int)
		Local n:Int = Self.buttons.Count() + 1
		Local ypos:Int = Int(Self.y + Self.h * n)
		If a3 <> 0 Then n = a3
		Local b:TButton = TButton.CreateButton(String(n), a0, Int(Self.x), ypos, Int(Self.w), Int(Self.h), 1, Self.fntSize, a1, a2, Null, Null, 1.0, 3, "")
		b.hidden = 1
		Self.buttons.AddLast(b)
		Local i:Int = 1
		For Local b2:TButton = EachIn Self.buttons
			If i = Self.buttons.Count() - 1 Then b2.SetButtonStyle(0)
			i = i + 1
		Next
	End Method
