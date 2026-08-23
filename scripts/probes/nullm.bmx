Strict
Type TA
	Field a:Int
	Method M1:Int() ; Return 1 ; End Method
	Method M2:Int() ; Return 2 ; End Method
	Method M3:Int() ; Return 3 ; End Method
	Method M4:Int() ; Return 4 ; End Method
	Method M5:Int() ; Return 5 ; End Method
	Method M6:Int() ; Return 6 ; End Method
	Method M7:Int() ; Return 7 ; End Method
	Method M8:Int() ; Return 8 ; End Method
End Type
Global g:TA = Null
Print "field read: " + g.a
Print "about to call M8 on Null"
Print "M8 = " + g.M8()
Print "survived"
