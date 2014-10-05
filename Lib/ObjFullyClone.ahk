ObjFullyClone(obj)
{
	nobj := ObjClone(obj)
	for k,v in nobj
		if IsObject(v)
			nobj[k] := ObjFullyClone(v)
	return nobj
}