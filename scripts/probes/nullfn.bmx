Strict
Global g_fn:Int()
Print "ptr as int = " + Int(Byte Ptr(g_fn))
Print "about to call"
g_fn()
Print "returned (no fault)"
