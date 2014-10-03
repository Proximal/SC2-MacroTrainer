OrderedArray()
{
    ; Define prototype object for ordered arrays:
    static base := Object("__Set", "oaSet", "_NewEnum", "oaNewEnum")
    ; Create and return new ordered array object:
    return Object("_keys", Object(), "base", base)
}
oaSet(obj, k, v)
{
    ; If this function is called, the key must not already exist.
    ; Just add this new key to the array:
    obj._keys.Insert(k)
    ; Since we don't return a value, the default behaviour takes effect.
    ; That is, a new key-value pair is created and stored in the object.
}
oaNewEnum(obj)
{
    ; Define prototype object for custom enumerator:
    static base := Object("Next", "oaEnumNext")
    ; Return an enumerator wrapping our _keys array's enumerator:
    return Object("obj", obj, "enum", obj._keys._NewEnum(), "base", base)
}
oaEnumNext(e, ByRef k, ByRef v="")
{
    ; If Enum.Next() returns a "true" value, it has stored a key and
    ; value in the provided variables. In this case, "i" receives the
    ; current index in the _keys array and "k" receives the value at
    ; that index, which is a key in the original object:
    if r := e.enum.Next(i,k)
        ; We want it to appear as though the user is simply enumerating
        ; the key-value pairs of the original object, so store the value
        ; associated with this key in the second output variable:
        v := e.obj[k]
    return r
}
