Function SNETopen(x as Ubyte, n$, a, b )
End function

Function SNETfopen(fname$, mode$) as Byte

    return SNETopen(SNETcurrMPoint(), fname$, flags, 666o) 
    
End Function

Function SNETcurrMPoint
End function



