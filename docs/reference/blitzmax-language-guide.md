# BlitzMax Language Guide for Contributors

**Audience:** a contributor who has never written BlitzMax and will pattern-match from
C / Python / JavaScript unless stopped. This file is the antidote.

**Toolchain this document was verified against:**

| Item | Value |
|---|---|
| Compiler | BlitzMax **NG** 0.154.3.58 |
| Root | `<repo>/tools/blitzmax/BlitzMax` |
| Docs on disk | `.../BlitzMax/docs/src/Language/*.bbdoc` |
| Module sources on disk | `.../BlitzMax/mod/**/*.bmx` |
| Build command | `tools/blitzmax/BlitzMax/bin/bmk.exe makeapp -r -t console -g x86 <file.bmx>` |

Everything marked **(verified)** below was compiled and executed on this toolchain during the
writing of this guide. Everything marked **UNCERTAIN:** was not.

> **Legacy vs NG.** `NSS5.exe` was built with **legacy BlitzMax 1.x**; we reconstruct with **NG**.
> The core language is the same. NG *adds* things legacy lacked (`Override`, `Struct`, `UInt`,
> `Size_T`, `Select` on strings, operator overloading, generics). Original NSS5 source could not
> have used those. Prefer the legacy-compatible subset when transcribing recovered logic; use NG
> extras only where they do not change behaviour.

---

## 1. Program skeleton

```blitzmax
SuperStrict                     ' must be the FIRST statement in the MAIN file

Framework BRL.StandardIO        ' optional: opt out of "import the world"
Import BRL.LinkedList           ' all Imports grouped here, before anything else
Import BRL.Stream

Include "nss5/teams.bmx"        ' textual inclusion of another .bmx

Const GAME:String = "C:/Program Files (x86)/Steam/steamapps/common/New Star Soccer 5"

Global gTickCount:Int = 0

Print "hello"                   ' top-level code IS the entry point - no main()

Function Helper:Int(x:Int)      ' declarations may appear AFTER the code that calls them
	Return x * 2
End Function

Type TThing
	Field id:Int
End Type
```

Key facts (verified):

- There is **no `main`**. Top-level statements execute in file order.
- `Type` and `Function` declarations are **hoisted** - you may call them before their textual
  position in the file.
- Statement order at the top is enforced: `SuperStrict` → `Framework` → `Import` → `Incbin` →
  everything else. Putting an `Import` after an `Incbin` is a compile error (verified).

### 1.1 Strict vs SuperStrict

| Mode | Variables must be declared | Types may be omitted | Function return type may be omitted |
|---|---|---|---|
| *(neither)* | No | Yes (defaults `Int`) | Yes (defaults `Int`) |
| `Strict` | **Yes** | Yes (defaults `Int`) | Yes (defaults `Int`) |
| `SuperStrict` | **Yes** | **No** | **No** |

**Always use `SuperStrict` in this project.** It forces explicit types, which is exactly what we
want when transcribing exact field layouts from recovered metadata.

Under `Strict`, the legacy *type sigils* are legal (verified compiling and running):

```blitzmax
Strict
Local a  = 5        ' Int by default
Local b% = 6        ' % = Int
Local c# = 1.5      ' # = Float
Local d$ = "str"    ' $ = String
Local e! = 2.5      ' ! = Double
```

Under `SuperStrict` every declaration needs `:Type`. Sigils still parse but do not exempt you.
BlitzMax module sources you read in `mod/` are mostly `Strict`, which is why you will see
`Method Count()` with no return type there - it means `Method Count:Int()`.

---

## 2. Primitive types and the `:Type` suffix

The type always comes **after** the identifier, separated by a colon. This is the single biggest
syntactic difference from C-family languages.

```blitzmax
Local count:Int = 0             ' NOT  int count = 0;
Field name:String               ' NOT  String name;
Function Area:Float(r:Float)    ' return type attaches to the FUNCTION NAME
	Return Float(Pi) * r * r
End Function
```

| Type | Size | Signed | Range / notes |
|---|---|---|---|
| `Byte` | 8-bit | unsigned | 0 … 255 |
| `Short` | 16-bit | unsigned | 0 … 65535 |
| `Int` | 32-bit | signed | −2^31 … 2^31−1. The default numeric type. |
| `UInt` | 32-bit | unsigned | **NG only** |
| `Long` | 64-bit | signed | −2^63 … 2^63−1 |
| `ULong` | 64-bit | unsigned | **NG only** |
| `Float` | 32-bit | - | IEEE single |
| `Double` | 64-bit | - | IEEE double |
| `Size_T` | pointer-sized | unsigned | **NG only**; 32-bit in our x86 builds |
| `String` | object | - | immutable, UTF-16 code units |
| `Object` | object | - | root of all types |
| `T Ptr` | pointer | - | e.g. `Byte Ptr`, `Int Ptr` |
| `T Var` | by-reference param | - | only in parameter lists |
| `T[]` | array | - | object, 0-based |

Note `Byte` and `Short` are **unsigned** - unlike C's `char`/`short`. A recovered field of C type
`signed char` is not a BlitzMax `Byte`.

### 2.1 Literals

| Form | Meaning |
|---|---|
| `100` | decimal Int |
| `$CAFEBABE` | hexadecimal (**`$`**, not `0x`) |
| `%10101010` | binary (**`%`**, not `0b`) |
| `1.5`, `.5`, `1e6`, `1.5e-6` | floating point |
| `"text"` | String |
| `9000000000:Long`, `10:Double` | literal with an explicit type suffix |

`$` and `%` as literal prefixes are a constant source of confusion because `%` is *not* modulo in
BlitzMax (see Gotchas).

### 2.2 Conversion and casting

```blitzmax
Local n:Int = 10
Local t:String = "20"

Print Int(t)              ' String -> Int   : 20
Print Float("2.5")        ' String -> Float : 2.5
Print String(n)           ' Int -> String   : "10"
Print t.ToInt()           ' method form
Print t.ToFloat()
Print String.FromInt(7)   ' function form
```

Int↔Float and numeric→String conversions happen implicitly. String→numeric requires an explicit
cast or a `.ToXxx()` call.

**Type balancing** for arithmetic: if either operand is `Double` the result is `Double`; else if
either is `Float` the result is `Float`; else if either is `Long` the result is `Long`; else `Int`.

> **(verified)** `7 / 2` yields `3` - integer division truncates. Write `7.0 / 2` or
> `7 / Float(2)` to get `3.5`.

> **(verified)** Converting a `Float` to a `String` prints ~9 significant digits:
> `Float(1)/Float(3)` → `0.333333343`, and `1.5` → `1.50000000`. **Never build user-facing or
> file-format output by concatenating a raw Float.** Format it yourself.

---

## 3. Variables: `Local`, `Global`, `Const`, `Field`

| Keyword | Lifetime | Scope | Where legal |
|---|---|---|---|
| `Local` | until block exits | the enclosing block | functions, methods, top level, loop bodies |
| `Global` | whole program | file, or the enclosing `Type` | top level, or inside a `Type` |
| `Const` | compile-time | file, or the enclosing `Type` | top level, or inside a `Type` |
| `Field` | lifetime of the object | the instance | **only** inside a `Type` |

```blitzmax
Local a:Int = 1, b:String = "x"      ' comma-separated multiple declarations
Global gFrame:Int
Const KIT_HOME:Int = 0

Type TClub
	Const MAX_PLAYERS:Int = 40       ' per-TYPE constant, reached as TClub.MAX_PLAYERS
	Global list:TList = New TList    ' per-TYPE (static) variable
	Field id:Int                     ' per-INSTANCE
	Field name:String
End Type
```

`Const` must be initialised with a compile-time constant expression. `Global` inside a `Type` is
what other languages call a *static member*; it is reached via the type name, not an instance.

**Field declaration order is load-bearing in this project.** The recovered object model gives exact
byte offsets; declaring fields in metadata order keeps the reconstruction faithful. Do not reorder
or interleave fields.

### 3.1 Compound assignment

There is **no `++` or `--`**. Use the `:`-prefixed compound operators:

| Op | Meaning | | Op | Meaning |
|---|---|---|---|---|
| `:+` | add | | `:&` | bitwise AND |
| `:-` | subtract | | `:\|` | bitwise OR |
| `:*` | multiply | | `:~` | bitwise XOR |
| `:/` | divide | | `:Shl` | shift left |
| `:Mod` | remainder | | `:Shr` | shift right (logical) |
| | | | `:Sar` | shift right (arithmetic) |

```blitzmax
Local n:Int = 5
n :+ 3        ' 8      (NOT n += 3, and definitely NOT n++)
n :* 2        ' 16
n :- 1        ' 15
n :/ 3        ' 5
```

---

## 4. Operators

| Category | BlitzMax | **NOT** |
|---|---|---|
| Assignment | `=` | - |
| Equality | `=` | `==` |
| Inequality | `<>` | `!=` |
| Relational | `<  >  <=  >=` | - |
| Logical | `And  Or  Not` | `&&  \|\|  !` |
| Bitwise AND / OR | `&` / `\|` | - |
| Bitwise XOR (binary) | `~` | `^` |
| Bitwise NOT (unary) | `~` | - |
| Shifts | `Shl  Shr  Sar` | `<<  >>  >>>` |
| Remainder | `Mod` | `%` |
| Power | `^` | `**` |
| Concatenation | `+` | - |
| Address-of | `Varptr` | `&` |

**(verified)** `~` is overloaded by arity: binary `6 ~ 3` → `5` (XOR); unary `~0` → `-1`
(bitwise complement). Both spellings are the tilde.

**(verified)** `Shr` is a *logical* shift - `-16 Shr 1` → `2147483640`. `Sar` is the *arithmetic*
shift - `-16 Sar 1` → `-8`. C's `>>` on a signed int behaves like `Sar`; if you are transcribing
C-like decompiler output for signed values, use `Sar`.

`^` is exponentiation, **not** XOR. This is the most dangerous single-character trap when porting
decompiled C.

### 4.1 Operator precedence pitfall with `+`

**(verified)** `+` is left-associative and string concatenation shares it with addition:

```blitzmax
Print "n=" + 1 + 2      ' prints  n=12    <-- concatenation, then concatenation
Print "n=" + (1 + 2)    ' prints  n=3     <-- parenthesise arithmetic
```

Always parenthesise arithmetic inside a concatenation.

### 4.2 Booleans

`True` is `1` and `False` is `0` - they are `Int` values (verified: printing `True` gives `1`).
NG has a real `Bool`/`Byte`-backed truth for some APIs, but classic BlitzMax code treats truth as
integer non-zero. Any non-zero value is true. `Null` is false.

---

## 5. Strings

Strings are **immutable objects** of UTF-16 code units. They can go anywhere an `Object` is
expected, and comparison operators work on their contents (verified: `"apple" < "banana"` → `1`).

### 5.1 Methods and functions

| Member | Returns | Notes |
|---|---|---|
| `.Length` | `Int` | a **field**, not a method - no parentheses |
| `.Find(sub:String, start:Int=0)` | `Int` | index, or `-1` |
| `.FindLast(sub:String, start:Int=0)` | `Int` | index, or `-1` |
| `.Trim()` | `String` | strips leading/trailing non-printables |
| `.Replace(old:String, new:String)` | `String` | replaces **all** occurrences |
| `.StartsWith(sub:String)` | `Int` | |
| `.EndsWith(sub:String)` | `Int` | |
| `.Contains(sub:String)` | `Int` | |
| `.Split(sep:String)` | `String[]` | called on the **subject** |
| `.Join(bits:String[])` | `String` | called on the **separator** |
| `.ToLower()` / `.ToUpper()` | `String` | |
| `.ToInt()` / `.ToLong()` / `.ToFloat()` / `.ToDouble()` | numeric | |
| `.ToCString()` / `.ToWString()` | `Byte Ptr` / `Short Ptr` | **must be `MemFree`d** |
| `String.FromInt/FromLong/FromFloat/FromDouble(v)` | `String` | static functions |
| `String.FromCString(p:Byte Ptr)` | `String` | NUL-terminated 8-bit |
| `String.FromWString(p:Short Ptr)` | `String` | NUL-terminated 16-bit |
| `String.FromBytes(p:Byte Ptr, n:Int)` | `String` | raw bytes, one char per byte |
| `String.FromUTF8Bytes(p:Byte Ptr, n:Int)` | `String` | **decodes UTF-8** |
| `String.FromUTF8String(p:Byte Ptr)` | `String` | NUL-terminated UTF-8 |

```blitzmax
Local t:String = "  ***Hello,World***  "
Print t.Length                     ' 21   (field, no parens)
Print t.Trim()                     ' ***Hello,World***
Print t.Find("Hello")              ' 5
Print t.Replace("*", "!")
Print t.ToLower()
Print "|".Join(["a", "b", "c"])    ' a|b|c   - Join is on the SEPARATOR
```

`Left`, `Right`, `Mid`, `LSet`, `RSet`, `Chr`, `Asc`, `Replace` (function form) live in
**`BRL.Retro`** - you must `Import BRL.Retro` to get them (verified):

```blitzmax
Import BRL.Retro
Print Left("abcdef", 3)      ' abc
Print Right("abcdef", 2)     ' ef
Print Mid("abcdef", 2, 3)    ' bcd   - Mid is 1-BASED
Print LSet("ab", 5)          ' "ab   "
Print RSet("ab", 5)          ' "   ab"
Print Chr(65)                ' A
Print Asc("A")               ' 65
```

> **`Mid` is 1-based** while slicing and indexing are 0-based. Verified: `Mid("abcdef",2,3)`→`"bcd"`.

### 5.2 Splitting and slicing

```blitzmax
Local parts:String[] = "a,b,,c".Split(",")   ' length 4, parts[2] is ""
Local cells:String[] = line.Split("~t")      ' TAB split - escape is ~t, NOT \t
Print "abcdefg"[2..5]                        ' "cde"  - slice, 0-based, end-exclusive
```

> **(verified) Indexing a String with a single index yields an `Int` character code, not a
> 1-character String.** `"A"[0]` is `65`. To get a one-character string use the slice form
> `s[i..i+1]`, or `Chr(s[i])`.

### 5.3 Escape sequences - `~`, never backslash

**(verified - the compiler rejects anything else with `Compile Error: Bad escape sequence in string`.)**

| Escape | Character |
|---|---|
| `~0` | NUL (code 0) |
| `~t` | tab (9) |
| `~n` | newline (10) |
| `~r` | carriage return (13) |
| `~q` | double quote (34) |
| `~~` | a literal tilde (126) |

That is the **complete** list. There is **no `~u`/`\u` unicode escape**, no `~\``, no `~b`, no
`~f`, no `~xNN` (verified: `"~u00e9"` fails to compile). For a non-ASCII literal use
`Chr(233)` or read it from a UTF-8 data file.

A backslash in a BlitzMax string is just a backslash - which makes Windows paths pleasant:
`"C:\Program Files\game"` needs no escaping. (Forward slashes also work throughout the BlitzMax
file APIs and are what this project uses.)

### 5.4 UTF-8 data files

Project data files are UTF-8. A plain `ReadLine` on a byte stream produces mojibake. Two fixes,
both verified:

```blitzmax
' (a) explicit decode of a byte buffer
Local raw:Byte[] = [Byte(195), Byte(169)]          ' U+00E9 in UTF-8
Local s:String = String.FromUTF8Bytes(raw, raw.Length)
Print s.Length                                      ' 1

' (b) let the stream do it - the "utf8::" protocol prefix
Local rs:TStream = ReadStream("utf8::data/Clubs.csv")
Local line:String = rs.ReadLine()                   ' correctly decoded
rs.Close()
```

`ReadLine(stream, asUTF8)` and `stream.ReadLine(asUTF8:Int)` overloads also exist in NG.

---

## 6. Arrays

Arrays are **objects**, **0-based**, and carry their length.

```blitzmax
Local a:Int[] = New Int[5]          ' 5 elements, zero-initialised
Local b:Int[] = [3, 1, 2]           ' "auto array" literal - all elements same type
Local empty:Int[]                   ' Null / 0 elements
Local grid:Int[,] = New Int[3, 4]   ' 2-D: note the COMMA inside the brackets

a[0] = 10
grid[2, 3] = 99                     ' single bracket pair, comma-separated indices

Print a.Length                      ' 5     - field, no parens
Print grid.Length                   ' 12    - TOTAL elements, not rows
Local d:Int[] = grid.Dimensions()   ' [3, 4]
b.Sort()                            ' ascending; b.Sort(False) for descending
```

Object arrays are initialised to `Null`; numeric arrays to `0`; String arrays to `Null`.

### 6.1 Slices - also the idiomatic resize

`arr[start..end]` returns a **new** array of exactly `end - start` elements. Out-of-range indices
are permitted; the missing elements are filled with `Null`/`0`. Either bound may be omitted.

```blitzmax
Local a:Int[] = New Int[200]
a = a[50..150]     ' middle 100
a = a[..50]        ' first 50
a = a[25..]        ' from index 25 to the end
a = a[..]          ' full copy
a = a[..200]       ' GROW back to 200 - verified
```

This is how you resize an array in BlitzMax; there is no `Redim`, no `.push()`, no `append`.
Growing element-by-element with `arr = arr[..arr.Length+1]` is O(n²) - build into a `TList` and
call `ToArray()` instead, or size once up front.

### 6.2 Multi-dimensional vs jagged

`Int[,]` is a true rectangular array. `Int[][]` is an array of arrays (jagged) and each row must be
allocated separately. The recovered object model signature `[]i` means a one-dimensional `Int[]`.

---

## 7. Types (`Type` … `End Type`)

```blitzmax
Type TBase_Team
	Const KIT_HOME:Int = 0        ' per-type constant
	Global list:TList = New TList ' per-type (static) variable
	Field id:Int                  ' per-instance
	Field name:String
	Field strength:Int

	Method New()                  ' constructor - runs automatically on New
		list.AddLast(Self)
	End Method

	Method Delete()               ' finalizer - runs at GC time, NOT deterministic
	End Method

	Method Describe:String()
		Return name + " (" + strength + ")"
	End Method

	Function SelectById:TBase_Team(wanted:Int)    ' static - no instance needed
		For Local t:TBase_Team = EachIn list
			If t.id = wanted Then Return t
		Next
		Return Null
	End Function
End Type
```

| Member | Bound to | Called as | Sees `Self`? |
|---|---|---|---|
| `Field` | instance | `obj.field` | - |
| `Method` | instance | `obj.Method()` | yes |
| `Function` | the type | `TType.Func()` | **no** |
| `Global` | the type | `TType.g` | - |
| `Const` | the type | `TType.C` | - |

`Self` is `this`. `Super.Method()` calls the base implementation.

### 7.1 Inheritance, `Abstract`, `Final`, `Override`

```blitzmax
Type TShape Abstract
	Field id:Int
	Method Area:Float() Abstract          ' no body; subclasses MUST implement
	Method Describe:String()
		Return "shape#" + id
	End Method
End Type

Type TCircle Extends TShape
	Field r:Float = 1.0

	Method Area:Float() Override          ' Override is NG-only, optional, recommended
		Return Float(Pi) * r * r
	End Method

	Method Describe:String() Override
		Return "circle(" + Super.Describe() + ")"
	End Method

	Function Create:TCircle(radius:Float)  ' factory pattern - very common in BlitzMax
		Local c:TCircle = New TCircle
		c.r = radius
		Return c
	End Function
End Type

Type TSquare Extends TShape Final          ' Final = cannot be extended further
	Method Area:Float() Override
		Return 1.0
	End Method
End Type
```

- Single inheritance only. Omitting `Extends` means `Extends Object`.
- An overriding method **must** have an identical signature to the base method.
- Dispatch is virtual: a `TShape` variable holding a `TCircle` calls `TCircle.Area()` (verified).
- `Abstract` on the *type* prevents instantiation; `Abstract` on a *method* omits the body.
- Calling an unimplemented abstract method throws `TNullMethodException`.
- Legacy BlitzMax had **no `Override` keyword** - omit it if you are matching legacy source exactly.

### 7.2 `New`, casting, and identity

```blitzmax
Local sh:TShape = New TCircle
Local c:TCircle = TCircle(sh)      ' downcast: TypeName(expr)
Local bad:TSquare = TSquare(sh)    ' FAILED cast -> Null, NO exception thrown
If bad = Null Then Print "not a square"
```

> **(verified) A failed downcast silently yields `Null`.** There is no `ClassCastException`.
> Always test the result before dereferencing. This is the BlitzMax equivalent of C++
> `dynamic_cast` returning `nullptr`, not Java's throwing cast.

`Null` is the null literal - not `null`, `nil`, `None`, or `0`.

### 7.3 The two overridable `Object` methods

Every object inherits these, and the standard library calls them:

| Method | Used by | Contract |
|---|---|---|
| `Method Compare:Int(o:Object)` | `TList.Sort`, `arr.Sort`, `TMap` keys, `ListContains`, `FindLink` | `<0`, `0`, `>0` |
| `Method ToString:String()` | `Print`, exception reporting | display text |

Implement `Compare` on any type you intend to sort or store in a `TMap`. Handle a failed cast:

```blitzmax
Method Compare:Int(o:Object) Override
	Local other:TCircle = TCircle(o)
	If Not other Then Return 1          ' not comparable - push to the end
	If r < other.r Then Return -1
	If r > other.r Then Return 1
	Return 0
End Method
```

### 7.4 Memory management / GC

BlitzMax is **garbage collected** (reference counting plus a cycle collector in NG). You call
`New`; you do **not** call `Delete` to free.

- `Method Delete()` is a **finalizer** invoked by the GC at an unspecified time. It is *not* a
  destructor and *not* a `Dispose`. Do not rely on it for ordering, and never call it manually.
- To release an object, drop all references to it (`obj = Null`, remove it from its list).
- Reference cycles are collected in NG.
- Objects are **reference types** - assignment aliases, it does not copy (verified: mutating `b`
  after `Local b:TCircle = a` changes what `a` sees). Write an explicit `Copy()` method if you need
  value semantics.
- Raw memory from `MemAlloc`/`ToCString`/`ToWString` is **not** GC-managed and must be `MemFree`d.

---

## 8. Collections

### 8.1 `TList` (`BRL.LinkedList`)

A doubly-linked list of `Object`. Because it stores `Object`, retrieving requires a cast.

| Method | Function equivalent | Notes |
|---|---|---|
| `New TList` | `CreateList()` | |
| `.AddLast(v:Object):TLink` | `ListAddLast(l, v)` | returns the link |
| `.AddFirst(v:Object):TLink` | `ListAddFirst(l, v)` | |
| `.First():Object` / `.Last():Object` | `ListGetFirst/Last` | `Null` if empty |
| `.RemoveFirst():Object` / `.RemoveLast():Object` | | |
| `.Remove(v:Object):Int` | `ListRemove(l, v)` | finds by `Compare`, **maintains count** |
| `.Contains(v:Object):Int` | `ListContains` | uses `Compare` |
| `.FindLink(v:Object):TLink` | `ListFindLink` | |
| `.Count():Int` | `CountList` | **caches** - see below |
| `.IsEmpty():Int` | `ListIsEmpty` | |
| `.Clear()` | `ClearList` | |
| `.Sort(ascending:Int=True, cmp=CompareObjects)` | `SortList` | uses `Compare` |
| `.Reverse()` / `.Reversed():TList` | `ReverseList` | |
| `.Copy():TList` | `CopyMap`-analogue | shallow |
| `.ToArray():Object[]` | `ListToArray` | |
| `TList.FromArray(arr:Object[])` | `ListFromArray` | |
| `.FirstLink():TLink` / `.LastLink():TLink` | | for manual walking |

`TLink`: `.Value():Object`, `.NextLink():TLink`, `.PrevLink():TLink`, `.Remove()`.

```blitzmax
Local list:TList = New TList
list.AddLast("beta")
list.AddLast("alpha")
list.Sort()

For Local v:String = EachIn list      ' EachIn casts for you
	Print v
Next

Print list.Count()
```

> ### ⚠ `TList.Count()` caches, and `TLink.Remove()` does not invalidate the cache
>
> **(verified, with reproduction.)** `TList` holds a `_count` field initialised to `-1`.
> `Count()` computes and memoises it. `TList.Remove(value)`, `RemoveFirst()` and `RemoveLast()`
> decrement the cache - but **`TLink.Remove()` does not touch it**.
>
> ```blitzmax
> Local l:TList = New TList
> l.AddLast("a") ; l.AddLast("b") ; l.AddLast("c")
> Print l.Count()                 ' 3  <- materialises the cache
> l.FindLink("b").Remove()        ' link-level removal
> Print l.Count()                 ' 3  <- WRONG, the list holds 2
> Local arr:Object[] = l.ToArray()
> Print arr.Length                ' 3  <- ToArray sizes from Count()
> Print (arr[2] = Null)           ' 1  <- trailing Null element
> ```
>
> **Rules:** prefer `list.Remove(value)`. If you must remove via links, either accept that
> `Count()`/`ToArray()` are unreliable afterwards, or never call `Count()` before the removals
> (an unmaterialised cache is recomputed correctly - verified).

**Removing while iterating.** Mutating a list inside `For EachIn` is unsafe. The safe idiom walks
links and captures the successor first (verified):

```blitzmax
Local link:TLink = list.FirstLink()
While link
	Local nxt:TLink = link.NextLink()    ' capture BEFORE removing
	If ShouldDrop(link.Value()) Then link.Remove()
	link = nxt
Wend
```

### 8.2 `TMap` (`BRL.Map`)

A red-black tree keyed by `Object`, ordered by the key's `Compare`. **Not** a hash map, and keys
are objects - to key by `Int` you must box it (e.g. `String(id)`).

| Method | Function equivalent |
|---|---|
| `New TMap` | `CreateMap()` |
| `.Insert(key:Object, value:Object)` | `MapInsert` |
| `.ValueForKey(key:Object):Object` | `MapValueForKey` |
| `.Contains(key:Object):Int` | `MapContains` |
| `.Remove(key:Object):Int` | `MapRemove` |
| `.Keys():TMapEnumerator` | `MapKeys` |
| `.Values():TMapEnumerator` | `MapValues` |
| `.Clear()` / `.IsEmpty():Int` / `.Copy():TMap` | `ClearMap` / `MapIsEmpty` / `CopyMap` |

```blitzmax
Local m:TMap = New TMap
m.Insert("one", "1")
m.Insert("two", "2")

Print String(m.ValueForKey("one"))       ' cast required

For Local k:String = EachIn m.Keys()
	Print k
Next

For Local kv:TKeyValue = EachIn m        ' iterating the map itself gives key/value pairs
	Print String(kv.Key()) + "=" + String(kv.Value())
Next
```

`TMap` has no `Count()`. NG adds `Operator[]` so `m["k"]` works, but legacy code will not use it.

---

## 9. Control flow

Blocks are **line-based and keyword-delimited**. There are no braces and no semicolon-terminated
statements. (A `;` may *separate* two statements on one line, but never ends one.)

```blitzmax
' --- If ---------------------------------------------------------------
If a > 10 Then Print "one-liner"          ' single-line form needs Then

If a > 10                                  ' multi-line form: Then is optional
	Print "big"
ElseIf a = 10
	Print "exactly ten"
Else
	Print "small"
End If                                     ' "EndIf" also accepted

' --- Select (this is the switch) --------------------------------------
Select kitStyle
	Case "PLAIN"
		Print "plain"
	Case "STRIPE_RL", "TRIM"               ' comma = multiple matches
		Print "striped or trimmed"
	Default
		Print "unknown"
End Select
```

> **No fall-through.** A `Case` body ends at the next `Case`. There is no `break`, and writing one
> is a syntax error. Multiple values go on one `Case`, comma-separated.
> **(verified)** `Select` works on `String` in NG. Legacy BlitzMax only allowed numeric `Select`;
> if you are matching legacy source, an `If/ElseIf` chain is the period-correct form.

```blitzmax
' --- For --------------------------------------------------------------
For Local i:Int = 0 To 9          ' INCLUSIVE upper bound: 0..9
Next

For Local i:Int = 0 Until 10      ' EXCLUSIVE upper bound: 0..9  (prefer this)
Next

For Local i:Int = 10 To 1 Step -1 ' countdown
Next

For Local c:TClub = EachIn TClub.list   ' iterate a TList / TMap / array
Next

' --- While / Repeat ---------------------------------------------------
While n < 10
	n :+ 1
Wend                               ' NOT "End While"

Repeat
	n :+ 1
Until n >= 20                      ' post-test, loops while the condition is FALSE
```

| Loop | Closing keyword | Test |
|---|---|---|
| `For` | `Next` | pre-test |
| `While` | `Wend` | pre-test |
| `Repeat` | `Until <cond>` / `Forever` | **post**-test, exits when cond is **true** |

`Repeat…Until` is the inverse of C's `do…while` - it exits when the condition becomes true.

`Exit` breaks the innermost loop; `Continue` jumps to the next iteration (verified: `Exit` from a
nested `For` leaves only the inner loop). BlitzMax has no labelled break - use a flag or extract a
function and `Return`.

`Next` optionally names the loop variable: `Next i`.

---

## 10. Functions and function pointers

```blitzmax
Function AddTwo:Int(x:Int, y:Int)
	Return x + y
End Function

Function Greet(name:String)          ' no return type = returns nothing usable
	Print "hi " + name
End Function

Function Bump(v:Int Var, by:Int = 1) ' Var = by reference; default argument
	v :+ by
End Function

Local n:Int = 10
Bump(n, 5)                            ' n is now 15 (verified)
```

- `Var` parameters are by-reference; the caller passes a variable, not an expression.
- Default arguments are supported and must be trailing.
- NG supports function **overloading** by signature; legacy BlitzMax did not.
- A call with no arguments still needs `()` in an expression, but statement-position calls may omit
  parentheses entirely: `Cls` and `Cls()` are both valid; `DrawText "hi", 0, 0` is valid.

### 10.1 Function pointers

The type of a function is written `ReturnType(ParamTypes)`:

```blitzmax
Local fp:Int(x:Int, y:Int) = AddTwo    ' no & needed - just name the function
Print fp(2, 3)                          ' 5   (verified)
If fp = Null Then Print "unset"
```

Used heavily by `SortList(list, True, MyCompare)`. Calling a `Null` function pointer throws
`TNullFunctionException`.

---

## 11. Exceptions

Any object - including a `String` - can be thrown.

```blitzmax
Try
	Throw "boom"
Catch ex:String
	Print "caught: " + ex
End Try

Try
	RiskyLoad()
Catch ex:TMyError          ' most specific catch first
	Print ex.ToString()
Catch ex:Object            ' catch-all
	Print "other: " + ex.ToString()
End Try

Type TMyError Extends TBlitzException
	Method ToString:String() Override
		Return "TMyError!"
	End Method
End Type
```

`Catch` clauses are tried in order and matched by type. There is **no `Finally`**. If nothing
catches, the program terminates.

Built-in exceptions, all extending `TBlitzException`:

| Exception | Cause |
|---|---|
| `TNullObjectException` | field/method access on `Null` - **debug builds only** |
| `TArrayBoundsException` | index outside the array - **debug builds only** |
| `TNullMethodException` | calling an unimplemented `Abstract` method |
| `TNullFunctionException` | calling a `Null` function pointer |
| `TRuntimeException` | raised by `RuntimeError` and failed `Assert` |

### 11.1 ⚠ Debug vs release changes runtime semantics

**(verified by building the same source both ways.)**

| Situation | `bmk makeapp -d` (debug) | `bmk makeapp -r` (release) |
|---|---|---|
| Read past end of array | throws `TArrayBoundsException` | **returns 0 silently** |
| Read a field of `Null` | throws `TNullObjectException` | **returns 0 silently** |
| `Assert` | evaluated | compiled out |

A release build will happily read out of bounds and dereference `Null` without complaint, so a
logic bug can silently produce zeros instead of crashing. **Develop and test reconstruction code
with `-d`; only use `-r` for timing runs and shipping.**

---

## 12. File I/O

`Import BRL.Stream`, `BRL.FileSystem`, and (for `utf8::`) `BRL.TextStream`.

### 12.1 Opening and closing

| Function | Purpose |
|---|---|
| `OpenStream:TStream(url:Object, readable:Int=True, writeMode:Int=WRITE_MODE_OVERWRITE)` | general |
| `ReadFile:TStream(url:Object)` / `WriteFile:TStream(url:Object)` | file, read / write |
| `ReadStream` / `WriteStream` / `AppendStream` | protocol-aware (`utf8::`, `incbin::`) |
| `CloseStream(s)` / `CloseFile(s)` / `s.Close()` | close |

`url` is an `Object` so a `String` path works directly. A `Null` return means the open failed - 
**always test it.** Protocol prefixes select a decoder: `"utf8::path"`, `"incbin::path"`.

### 12.2 Reading and writing

| Free function | Method | Notes |
|---|---|---|
| `ReadLine:String(s)` | `s.ReadLine()` | strips the line terminator |
| `WriteLine(s, str)` | `s.WriteLine(str)` | |
| `ReadString:String(s, length)` | `s.ReadString(len)` | fixed count of characters |
| `WriteString(s, str)` | `s.WriteString(str)` | no terminator |
| `ReadByte/Short/Int/Long/Float/Double(s)` | `s.ReadInt()` etc. | little-endian |
| `WriteByte/Short/Int/Long/Float/Double(s, n)` | `s.WriteInt(n)` etc. | |
| `StreamSize:Long(s)` | `s.Size()` | |
| `StreamPos:Long(s)` | `s.Pos()` | |
| `SeekStream:Long(s, pos)` | `s.Seek(pos)` | |
| `Eof:Int(s)` | `s.Eof()` | |
| `FlushStream(s)` | `s.Flush()` | |
| `LoadString:String(url)` / `SaveString(str, url)` | | whole file in one call |
| `LoadByteArray:Byte[](url)` / `SaveByteArray(arr, url)` | | whole file as bytes |
| `CopyStream(from, to, bufSize:Int=4096)` | | |

> ### ⚠ There is no `ReadBytes()` free function
>
> **(verified.)** To read raw bytes into a buffer use the **method** `Read`, passing a pointer:
>
> ```blitzmax
> Local buf:Byte[] = New Byte[8]
> Local got:Long = stream.Read(Varptr buf[0], 8)   ' returns bytes actually read
> ```
>
> `stream.Write(Varptr buf[0], n)` is the mirror image. NG *does* also expose the methods
> `stream.ReadBytes(buf:Byte Ptr, count:Long)` / `stream.WriteBytes(...)`, which throw on a short
> read rather than returning a count - but **`ReadBytes` as a bare free function does not exist**,
> which is the mistake to avoid.

Worked example (verified end to end):

```blitzmax
Local ws:TStream = WriteFile("out.txt")
If Not ws Then Throw "cannot open out.txt"
ws.WriteLine("line one")
ws.WriteInt(1234)
CloseStream(ws)

Local rs:TStream = ReadFile("out.txt")
If Not rs Then Throw "cannot read out.txt"
Print StreamSize(rs)
Print rs.ReadLine()
Print rs.ReadInt()
Print Eof(rs)
rs.Close()
```

### 12.3 Filesystem functions (`BRL.FileSystem`)

| Function | Returns |
|---|---|
| `FileExists(path:String):Int` | |
| `FileType(path:String):Int` | `0` none, `1` file, `2` dir |
| `FileSize(path:String):Long` | `-1` if absent |
| `FileTime(path:String):Long` | |
| `CreateDir(path:String, recurse:Int=False):Int` | |
| `CreateFile(path:String):Int` | |
| `DeleteFile(path:String):Int` | |
| `RenameFile(old:String, new:String):Int` | |
| `CopyFile(src:String, dst:String):Int` | |
| `CopyDir(src:String, dst:String):Int` | |
| `DeleteDir(path:String, recurse:Int=False):Int` | |
| `LoadDir(dir:String, skipDots:Int=True):String[]` | directory listing |
| `ReadDir` / `NextFile` / `CloseDir` | manual iteration |
| `CurrentDir():String` / `ChangeDir(path):Int` | |
| `RealPath(path:String):String` | absolute |
| `StripDir` / `StripExt` / `StripAll` / `StripSlash` | path surgery |
| `ExtractDir(path):String` / `ExtractExt(path):String` | |

---

## 13. Max2D graphics

`Framework BRL.GLMax2D` (OpenGL) or `BRL.D3D9Max2D` (Direct3D 9). Add loaders explicitly when using
a `Framework`: `Import BRL.PNGLoader`, `Import BRL.JPGLoader`, `Import BRL.OGGLoader`.

All of the following compiled successfully as one program (verified).

### 13.1 Display

| Function | Signature |
|---|---|
| `Graphics` | `Graphics:TGraphics(width:Int, height:Int, depth:Int=0, hertz:Int=60, flags:Long=0, x:Int=-1, y:Int=-1)` |
| `EndGraphics` | `EndGraphics()` |
| `Flip` | `Flip(sync:Int=-1)` - `1` vsync, `0` no wait, `-1` driver default |
| `Cls` | `Cls()` |
| `SetClsColor` | `SetClsColor(r:Int, g:Int, b:Int)` |
| `GraphicsWidth` / `GraphicsHeight` | `:Int()` |

`depth = 0` means windowed; a non-zero bit depth requests fullscreen.

### 13.2 Render state

| Function | Signature | Notes |
|---|---|---|
| `SetColor` | `(r:Int, g:Int, b:Int)` | 0-255; tints images too |
| `SetAlpha` | `(alpha:Float)` | 0.0-1.0 |
| `SetBlend` | `(blend:Int)` | see table below |
| `SetScale` | `(sx:Float, sy:Float)` | |
| `SetRotation` | `(degrees:Float)` | degrees, clockwise |
| `SetHandle` | `(x:Float, y:Float)` | rotation/scale pivot for drawing |
| `SetOrigin` | `(x:Float, y:Float)` | translates all drawing |
| `SetViewport` | `(x:Int, y:Int, w:Int, h:Int)` | clipping rectangle |
| `SetLineWidth` | `(w:Float)` | |
| `SetMaskColor` | `(r:Int, g:Int, b:Int)` | colour key for `MASKEDIMAGE` |
| `SetVirtualResolution` | `(w:Float, h:Float)` | logical resolution |

Each has a `GetXxx` counterpart, most using `Var` out-parameters:
`GetColor(r:Int Var, g:Int Var, b:Int Var)`.

Blend modes (`brl.mod/max2d.mod/driver.bmx`, verified):

| Constant | Value | Effect |
|---|---|---|
| `MASKBLEND` | 1 | draw only where alpha > 0.5 |
| `SOLIDBLEND` | 2 | overwrite |
| `ALPHABLEND` | 3 | standard alpha blending |
| `LIGHTBLEND` | 4 | additive |
| `SHADEBLEND` | 5 | multiplicative |

Image flags:

| Constant | Value |
|---|---|
| `MASKEDIMAGE` | `$1` |
| `FILTEREDIMAGE` | `$2` |
| `MIPMAPPEDIMAGE` | `$4` |
| `DYNAMICIMAGE` | `$8` |

### 13.3 Drawing

| Function | Signature |
|---|---|
| `DrawImage` | `(image:TImage, x:Float, y:Float, frame:Int=0)` |
| `DrawImageRect` | `(image:TImage, x:Float, y:Float, w:Float, h:Float, frame:Int=0)` |
| `DrawSubImageRect` | `(image, x, y, w, h, sx, sy, sw, sh, hx=0, hy=0, frame=0)` |
| `TileImage` | `(image:TImage, x:Float=0, y:Float=0, frame:Int=0)` |
| `DrawText` | `(t:String, x:Float, y:Float)` |
| `DrawRect` | `(x:Float, y:Float, w:Float, h:Float)` - **filled** |
| `DrawLine` | `(x:Float, y:Float, x2:Float, y2:Float, drawLastPixel:Int=True)` |
| `DrawOval` | `(x:Float, y:Float, w:Float, h:Float)` |
| `DrawPoly` | `(xy:Float[], indices:Int[]=Null)` |
| `Plot` | `(x:Float, y:Float)` |

`DrawRect` fills. There is no built-in outlined-rectangle call - draw four `DrawLine`s.

### 13.4 Images and fonts

| Function | Signature |
|---|---|
| `LoadImage` | `:TImage(url:Object, flags:Int=-1)` |
| `LoadAnimImage` | `:TImage(url:Object, cellW:Int, cellH:Int, firstCell:Int, cellCount:Int, flags:Int=-1)` |
| `CreateImage` | `:TImage(w:Int, h:Int, frames:Int=1, flags:Int=-1)` |
| `GrabImage` | `(image:TImage, x:Int, y:Int, frame:Int=0)` |
| `SetImageHandle` | `(image:TImage, x:Float, y:Float)` |
| `MidHandleImage` | `(image:TImage)` |
| `AutoMidHandle` | `(enable:Int)` |
| `LoadImageFont` | `:TImageFont(url:Object, size:Int, style:Int=SMOOTHFONT)` |
| `SetImageFont` | `(font:TImageFont)` |
| `GetImageFont` | `:TImageFont()` |
| `TextWidth` / `TextHeight` | `:Int(text:String)` |

`LoadImage` returns `Null` on failure - check it. `SetImageFont(Null)` restores the built-in font.

### 13.5 Canonical render loop

```blitzmax
SuperStrict
Framework BRL.GLMax2D
Import BRL.PNGLoader

Graphics 800, 600, 0
SetClsColor 0, 0, 40

Local pitch:TImage = LoadImage("pitch.png")
If Not pitch Then Throw "missing pitch.png"

While Not KeyDown(KEY_ESCAPE) And Not AppTerminate()
	Cls

	SetBlend ALPHABLEND
	SetColor 255, 255, 255
	SetAlpha 1.0
	DrawImage pitch, 0, 0

	SetRotation 0 ; SetScale 1, 1 ; SetHandle 0, 0   ' state is GLOBAL - reset it
	DrawText "score", 10, 570

	Flip
Wend

EndGraphics
```

> **Max2D state is global and sticky.** `SetColor`, `SetAlpha`, `SetRotation`, `SetScale`,
> `SetHandle`, `SetViewport` and `SetBlend` persist until changed - including into the next frame.
> Forgetting to reset `SetRotation`/`SetScale`/`SetColor` after drawing one sprite is the most
> common Max2D rendering bug.

---

## 14. Input

`Framework BRL.GLMax2D` pulls in `BRL.PolledInput`; otherwise `Import BRL.PolledInput`.

| Function | Returns |
|---|---|
| `KeyDown(key:Int):Int` | held right now |
| `KeyHit(key:Int):Int` | press count since the last check (consumes it) |
| `GetChar():Int` | next buffered character, `0` if none |
| `FlushKeys()` | |
| `MouseX():Int` / `MouseY():Int` / `MouseZ():Int` | `Z` is the wheel |
| `MouseXSpeed()` / `MouseYSpeed()` / `MouseZSpeed()` | delta since last poll |
| `MouseDown(button:Int):Int` | held; `1` left, `2` right, `3` middle |
| `MouseHit(button:Int):Int` | click count since the last check |
| `FlushMouse()` | |
| `WaitKey()` / `WaitChar()` / `WaitMouse()` | blocking |
| `AppTerminate():Int` | user closed the window |
| `AppSuspended():Int` | app lost focus |

Key constants (`KEY_ESCAPE`, `KEY_SPACE`, `KEY_A`, `KEY_LEFT`, …) come from `BRL.KeyCodes`.

`KeyHit`/`MouseHit` are **consuming counters** - calling twice in one frame gives `0` the second
time. Read once per frame into a local.

### 14.1 Event queue

For window/system events, `Import BRL.EventQueue`:

```blitzmax
While PollEvent()                 ' non-blocking; returns 0 when the queue is empty
	Select EventID()
		Case EVENT_KEYDOWN
			Print "key " + EventData()
		Case EVENT_MOUSEDOWN
			Print "click " + EventX() + "," + EventY()
		Case EVENT_APPTERMINATE
			End
	End Select
Wend
```

| Accessor | Meaning |
|---|---|
| `EventID():Int` | the `EVENT_*` constant |
| `EventData():Int` | key code / button |
| `EventX():Int` / `EventY():Int` | position |
| `EventMods():Int` | shift/ctrl/alt mask |
| `EventSource():Object` / `EventText():String` / `EventExtra():Object` | |

`WaitEvent():Int` blocks until an event arrives - right for a GUI, wrong for a game loop.
`PeekEvent()` inspects without removing. `PostEvent`/`EmitEvent` inject events.

Common `EVENT_*` values (from `brl.mod/event.mod/event.bmx`): `EVENT_APPTERMINATE` `$103`,
`EVENT_KEYDOWN` `$201`, `EVENT_KEYUP` `$202`, `EVENT_KEYCHAR` `$203`, `EVENT_MOUSEDOWN` `$401`,
`EVENT_MOUSEUP` `$402`, `EVENT_MOUSEMOVE` `$403`, `EVENT_MOUSEWHEEL` `$404`,
`EVENT_WINDOWCLOSE` `$4003`.

---

## 15. Audio

`Import BRL.Audio` plus a driver (`BRL.FreeAudioAudio` or `BRL.OpenALAudio`) and a loader
(`BRL.OGGLoader`, `BRL.WAVLoader`).

| Function | Signature |
|---|---|
| `LoadSound` | `:TSound(url:Object, flags:Int=0)` |
| `PlaySound` | `:TChannel(sound:TSound, channel:TChannel=Null)` - starts immediately |
| `CueSound` | `:TChannel(sound:TSound, channel:TChannel=Null)` - loads **paused** |
| `AllocChannel` | `:TChannel()` |
| `StopChannel` | `(channel:TChannel)` |
| `PauseChannel` / `ResumeChannel` | `(channel:TChannel)` |
| `ChannelPlaying` | `:Int(channel:TChannel)` |
| `SetChannelVolume` | `(channel:TChannel, volume:Float)` - 0.0-1.0 |
| `SetChannelPan` | `(channel:TChannel, pan:Float)` - −1.0 … 1.0 |
| `SetChannelDepth` | `(channel:TChannel, depth:Float)` |
| `SetChannelRate` | `(channel:TChannel, rate:Float)` - 1.0 is normal pitch |
| `LoadAudioSample` | `:TAudioSample(url:Object)` - raw PCM, not playable directly |
| `CreateAudioSample` | `:TAudioSample(length:Int, hertz:Int, format:Int)` |

`TSound` flags: `SOUND_LOOP` (1), `SOUND_HARDWARE` (2), `SOUND_STREAM` (4) - combine with `|`.

`TChannel` methods mirror the functions: `.Play()`, `.Cue()`, `.Stop()`, `.SetPaused(p)`,
`.SetVolume(v)`, `.SetPan(p)`, `.SetRate(r)`, `.Playing():Int`.

```blitzmax
Local whistle:TSound = LoadSound("whistle.ogg")
Local theme:TSound   = LoadSound("theme.ogg", SOUND_LOOP | SOUND_STREAM)

Local music:TChannel = AllocChannel()
CueSound(theme, music)          ' loaded but paused
SetChannelVolume music, 0.5
ResumeChannel music

If MouseHit(1) Then PlaySound whistle    ' fire-and-forget on an auto channel
```

`PlaySound` with no channel allocates one automatically and you lose the handle - use
`AllocChannel` for anything you need to stop or adjust later.

---

## 16. Program structure: `Framework`, `Import`, `Include`, `Module`, `Incbin`

| Directive | Effect |
|---|---|
| `Framework a.b` | Import **only** `a.b` and its dependencies instead of all of `brl`/`pub`. Smaller exe. Main file only. |
| `Import a.b` | Import a module (recursive: its imports come too). |
| `Import "file.bmx"` | Import another source file as a compilation unit. |
| `Import "file.c"` / `"file.cpp"` / `"file.o"` | Compile and link a C/C++/object file. |
| `Include "file.bmx"` | **Textual** inclusion into the current unit. |
| `Module scope.name` | Declares this file to *be* a module. Not used for app code. |
| `Incbin "file"` | Embed a file in the exe; open it with `"incbin::file"`. |

`IncbinPtr("file"):Byte Ptr` and `IncbinLen("file"):Int` reach the embedded bytes directly.

> ### ⚠ `Include` vs `Import` - the rule that bites everyone
>
> **(verified.)** An `Include`d file is pasted into the parent compilation unit. It therefore
> **must not repeat `SuperStrict`, `Framework`, or any `Import`**. Doing so produces:
>
> ```
> Compile Error: Expecting expression but encountered 'superstrict'
> ```
>
> An **`Import`**ed `.bmx` file is a separate unit and **must** declare its own `SuperStrict` and
> its own `Import`s.
>
> | | `Include "x.bmx"` | `Import "x.bmx"` |
> |---|---|---|
> | `SuperStrict` in the child | ❌ forbidden | ✅ required |
> | `Import` in the child | ❌ forbidden | ✅ required |
> | Circular references | not allowed | allowed |
> | Compilation unit | shared with parent | its own |
>
> This project uses `Include` (see `src/datatest.bmx` → `src/nss5/teams.bmx`), so **child files
> carry no header at all** - they start straight in with `Const`/`Type` declarations.

Ordering is enforced (verified): `SuperStrict` → `Framework` → all `Import`s → `Incbin` → code.
An `Import` after an `Incbin` fails with `Expecting expression but encountered 'import'`.

---

## 17. Pointers and interfacing with C

```blitzmax
Local v:Int = 1234
Local p:Int Ptr = Varptr v      ' Varptr is address-of; there is no & operator
Print p[0]                       ' 1234   - deref by indexing; there is no * operator
p[0] = 4321                      ' writes through the pointer
Print v                          ' 4321

Local buf:Byte[] = New Byte[16]
Local bp:Byte Ptr = Varptr buf[0]   ' pointer to the first element of an array
```

| BlitzMax | C |
|---|---|
| `Varptr x` | `&x` |
| `p[0]` | `*p` |
| `Byte Ptr` | `unsigned char *` |
| `MemAlloc(n:Size_T):Byte Ptr` | `malloc` |
| `MemFree(p:Byte Ptr)` | `free` |
| `MemCopy(dst:Byte Ptr, src:Byte Ptr, n:Size_T)` | `memcpy` |
| `MemClear(p:Byte Ptr, n:Size_T)` | `memset(p,0,n)` |
| `SizeOf(x)` | `sizeof` |

There is no unary `*` dereference operator - always index with `[0]`.

### 17.1 `Extern`

```blitzmax
Extern                                   ' plain C, cdecl
	Function nss_add:Int(a:Int, b:Int)
	Function c_puts:Int(s:Byte Ptr) = "puts"     ' = "name" gives the C symbol
End Extern

Extern "win32"                           ' __stdcall
	Function SomeWinApi:Int(h:Int)
End Extern
```

> ### ⚠ Do not `Extern` a symbol the C headers already declare
>
> **(verified.)** BlitzMax NG emits your declaration into the generated C. `blitz.h` pulls in
> `windows.h`, `stdlib.h`, `string.h` and `stdio.h`, so redeclaring `GetTickCount`, `MessageBeep`,
> `GetCurrentProcessId`, `atoi`, `strlen`… produces:
>
> ```
> error: conflicting types for 'atoi'; have 'BBINT(BBBYTE *)'
> note: previous declaration of 'atoi' with type 'int(const char *)'
> ```
>
> Aliasing to a different BlitzMax name does **not** help - the alias is the emitted C name.
> Matching the signature usually cannot help either, because Win32 `DWORD` is `unsigned long`
> and BlitzMax has no way to spell that distinctly from `UInt`.
> Name-decoration tricks fail too: `= "GetTickCount@0"` emits a stray `@` and will not compile.
>
> **The reliable pattern is a companion C file (verified working):**
>
> ```c
> /* glue.c */
> #include <windows.h>
> int nss_tick_count(void) { return (int)GetTickCount(); }
> ```
>
> ```blitzmax
> Import "glue.c"           ' must sit with the other Imports, before Incbin/code
> Extern
> 	Function nss_tick_count:Int()
> End Extern
> Print nss_tick_count()
> ```

---

## 18. LOUD GOTCHAS

Read this section before writing a single line. Each item is a mistake a pass will otherwise make
by reflex.

### Syntax

1. **`'` starts a comment. Not `//`, not `#`.** Block comments are `Rem` … `EndRem`.
   ```blitzmax
   ' a line comment
   Rem
     a block comment
   EndRem
   ```
2. **`=` is BOTH assignment and equality. There is no `==`.**
   `If a = 1 Then a = 2` is legal and means what it looks like.
3. **`<>` is not-equal. There is no `!=`.**
4. **`And` / `Or` / `Not` - not `&&` / `||` / `!`.**
5. **`Mod` is remainder. `%` is the *binary literal prefix*.** `%1011` is 11, not a modulo.
6. **`^` is exponentiation, not XOR.** XOR is binary `~`. This silently produces wrong numbers when
   porting C - the highest-risk single character in the language.
7. **`~` is unary bitwise-NOT *and* binary XOR** (verified: `~0` → `-1`, `6 ~ 3` → `5`).
8. **No `++` or `--`.** Use `:+ 1` / `:- 1`.
9. **Compound assignment is `:+ :- :* :/ :Mod :& :| :~ :Shl :Shr :Sar`** - colon first, no `=`.
10. **`Null`, `True`, `False`** - not `null`/`nil`/`None`, not `true`/`false`.
11. **No braces.** Blocks close with `End If`, `Next`, `Wend`, `Until`, `End Select`, `End Type`,
    `End Method`, `End Function`, `End Try`, `End Extern`, `End Rem`.
12. **Statements are line-based.** No terminating semicolon. `;` only *separates* two statements
    written on one line.
13. **Line continuation is `..` at the end of the line**, not `\`:
    ```blitzmax
    Print "a very " + ..
          "long string"
    ```
14. **String escapes use `~`:** `~t` `~n` `~r` `~q` `~0` `~~`. **That is the whole list** - no
    `~u`, no `\n`, no `\t`. A tab split is `line.Split("~t")`.
15. **Backslashes in strings are literal**, so Windows paths need no escaping.
16. **Hex is `$FF`, binary is `%1011`** - not `0xFF`, not `0b1011`.
17. **The type goes after the name:** `Local x:Int`, `Function F:Int(a:Int)`.
18. **`Next` closes a `For`; `Wend` closes a `While`.** Not `End For` / `End While`.
19. **`Repeat … Until c` exits when `c` becomes TRUE** - the inverse of C's `do…while(c)`.
20. **`For i = 0 To 9` is inclusive.** Use `For i = 0 Until 10` for C-style bounds.
21. **`Select` has no fall-through and no `break`.** Multiple matches go on one `Case`, comma-separated.
22. **Parenthesise arithmetic inside concatenation** - `"n=" + 1 + 2` yields `"n=12"` (verified).

### Semantics

23. **⚠ An `Include`d file must NOT repeat `SuperStrict` and must NOT carry `Import`s** - verified
    compile error. `Import`ed files must have both. See §16.
24. **⚠ `Import` statements must precede `Incbin` and all code** - verified compile error otherwise.
25. **⚠ There is no `ReadBytes()` free function.** Use `stream.Read(Varptr buf[0], size)` (verified).
26. **⚠ Release builds silently swallow null-derefs and array overruns** (returning `0`); only
    `-d` debug builds throw (verified). Develop with `-d`.
27. **⚠ `TList.Count()` caches and `TLink.Remove()` does not invalidate it** - stale counts and
    trailing `Null`s from `ToArray()` (verified). Prefer `list.Remove(value)`. See §8.1.
28. **A failed downcast returns `Null` rather than throwing** (verified). Always check.
29. **Integer division truncates:** `7 / 2` is `3` (verified).
30. **`Float` → `String` yields ~9 significant digits** (`1.5` → `"1.50000000"`, verified). Never
    concatenate a raw Float into output or a file format.
31. **Indexing a String gives an `Int` char code, not a String** (verified: `"A"[0]` is `65`).
32. **`Byte` and `Short` are unsigned.** A signed 8-bit value is not a `Byte`.
33. **`Shr` is logical, `Sar` is arithmetic** (verified). C's `>>` on signed ints is `Sar`.
34. **`.Length` on strings and arrays is a field** - no parentheses. `.Count()` on a `TList` is a
    method - parentheses required.
35. **`Mid()` is 1-based** while indexing and slicing are 0-based (verified).
36. **Objects are references.** Assignment aliases; it does not copy.
37. **`Method Delete()` is a GC finalizer, not a destructor.** Never call it; never rely on when it runs.
38. **Max2D render state is global and persists across frames.** Reset `SetColor`, `SetAlpha`,
    `SetRotation`, `SetScale`, `SetHandle`, `SetBlend` explicitly.
39. **`KeyHit` / `MouseHit` consume their counter.** Read once per frame.
40. **`Left`/`Right`/`Mid`/`LSet`/`RSet`/`Chr`/`Asc` need `Import BRL.Retro`.**
41. **`TMap` is an ordered tree keyed by `Object`, not a hash map.** Box `Int` keys as `String`.
      It has no `Count()`.
42. **Growing an array via `arr = arr[..n+1]` in a loop is O(n²).** Use a `TList`, then `ToArray()`.
43. **Never `Extern` a C symbol the standard headers already declare** - use a companion C file (§17.1).
44. **Data files here are UTF-8.** Use `ReadStream("utf8::path")` or `String.FromUTF8Bytes`.
45. **`Print` adds a newline; there is no `printf`.** Build the string yourself.

---

## 19. Quick reference: translating from C-family

| You want | C / Python / JS | BlitzMax |
|---|---|---|
| comment | `// x` | `' x` |
| block comment | `/* x */` | `Rem` … `EndRem` |
| equality | `a == b` | `a = b` |
| inequality | `a != b` | `a <> b` |
| logical and/or/not | `&& \|\| !` | `And Or Not` |
| xor | `a ^ b` | `a ~ b` |
| bitwise not | `~a` | `~a` |
| modulo | `a % b` | `a Mod b` |
| power | `pow(a,b)` | `a ^ b` |
| increment | `i++` | `i :+ 1` |
| declare | `int x = 1;` | `Local x:Int = 1` |
| null | `NULL` / `None` | `Null` |
| if | `if (c) { }` | `If c` … `End If` |
| switch | `switch/case/break` | `Select/Case/End Select` (no break) |
| for | `for(i=0;i<10;i++)` | `For Local i:Int = 0 Until 10` … `Next` |
| foreach | `for (x : xs)` | `For Local x:T = EachIn xs` … `Next` |
| while | `while (c) { }` | `While c` … `Wend` |
| do-while | `do { } while (c)` | `Repeat` … `Until Not c` |
| break / continue | `break` / `continue` | `Exit` / `Continue` |
| function | `int f(int a){}` | `Function f:Int(a:Int)` … `End Function` |
| class | `class C {}` | `Type TC` … `End Type` |
| this | `this` | `Self` |
| base call | `super.m()` | `Super.m()` |
| static member | `static int n;` | `Global n:Int` inside the `Type` |
| instance field | `int n;` | `Field n:Int` |
| new | `new C()` | `New TC` |
| cast | `(C*)p` / `dynamic_cast` | `TC(p)` - `Null` on failure |
| address-of | `&x` | `Varptr x` |
| dereference | `*p` | `p[0]` |
| array length | `n` / `len(a)` | `a.Length` |
| append to list | `push_back` / `.append` | `list.AddLast(v)` |
| string length | `strlen(s)` / `len(s)` | `s.Length` |
| substring | `s.substr(a,b)` | `s[a..b]` |
| split | `s.split(",")` | `s.Split(",")` |
| join | `",".join(xs)` | `",".Join(xs)` |
| line continuation | `\` | `..` |
| tab escape | `"\t"` | `"~t"` |
| hex literal | `0xFF` | `$FF` |
| throw | `throw e;` | `Throw e` |
| try/catch | `try/catch` | `Try` / `Catch e:T` / `End Try` (no `Finally`) |
| print | `printf` / `print` | `Print` |

---

## 20. Project conventions for NSS5-Forge

- `SuperStrict` at the top of every **main** file. Never in an `Include`d file.
- 32-bit x86 builds only: `bmk makeapp -r -t console -g x86 file.bmx`. Use `-d` while developing.
- Field order inside a `Type` mirrors the recovered metadata offsets - never reorder.
- Recovered signature encoding → BlitzMax types:

  | Sig | Type | | Sig | Type |
  |---|---|---|---|---|
  | `b` | `Byte` | | `$` | `String` |
  | `s` | `Short` | | `:TFoo` | `TFoo` (object) |
  | `i` | `Int` | | `[]X` | array of `X` |
  | `l` | `Long` | | `*X` | `X Ptr` |
  | `f` | `Float` | | `(args)ret` | function |
  | `d` | `Double` | | | |

- Read game data with `ReadStream("utf8::" + path)`; the shipped CSVs are UTF-8.
- Prefer `Include` for reconstruction modules (matching `src/datatest.bmx` → `src/nss5/teams.bmx`),
  so child files carry **no** `SuperStrict` and **no** `Import`.

---

## 21. Where to look things up on disk

| Question | File |
|---|---|
| Language semantics | `tools/blitzmax/BlitzMax/docs/src/Language/*.bbdoc` |
| Exact API signature | `tools/blitzmax/BlitzMax/mod/<scope>.mod/<name>.mod/<name>.bmx` |
| `TList` / `TLink` | `mod/brl.mod/linkedlist.mod/linkedlist.bmx` |
| `TMap` | `mod/brl.mod/map.mod/map.bmx` |
| Streams | `mod/brl.mod/stream.mod/stream.bmx` |
| Filesystem | `mod/brl.mod/filesystem.mod/filesystem.bmx` |
| Max2D | `mod/brl.mod/max2d.mod/max2d.bmx` |
| Blend / image constants | `mod/brl.mod/max2d.mod/driver.bmx` |
| Input | `mod/brl.mod/polledinput.mod/polledinput.bmx` |
| Events + `EVENT_*` | `mod/brl.mod/event.mod/event.bmx`, `eventqueue.mod/eventqueue.bmx` |
| Audio | `mod/brl.mod/audio.mod/audio.bmx` |
| Key codes | `mod/brl.mod/keycodes.mod/keycodes.bmx` |
| Working example | `src/datatest.bmx`, `src/nss5/teams.bmx` |

Module sources are `Strict`, not `SuperStrict` - a member written `Method Count()` there returns
`Int`. When in doubt, **read the module source**; it is the authoritative signature.
