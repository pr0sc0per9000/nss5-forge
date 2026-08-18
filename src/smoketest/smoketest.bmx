SuperStrict
Framework BRL.StandardIO
Import BRL.LinkedList
Import BRL.Stream

Local l:TList = CreateList()
ListAddLast(l, "New Star")
ListAddLast(l, "Forge")
For Local s:String = EachIn l
	Print "item: " + s
Next
Print "BlitzMax NG smoke test OK"
