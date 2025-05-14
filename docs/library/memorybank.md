# MemoryBank

The MemoryBank library allows you to manage paged memory on 128K and later/compatible models.

This library includes three commands:

* [SetBank](memorybank/setbank.md): Sets the specified bank to memory location $c000
* [GetBank](memorybank/getbank.md): Returns the memory bank that is located at memory location $c000
* [SetCodeBank](memorybank/setcodebank.md): Copies the specified memory bank to location $8000

Only works on 128K and later/compatible models.

**Danger:** If our program exceeds the address $c000 it may cause problems, use this library at your own risk.


## Memory banks

 - $c000 > Bank 0 to Bank 7
 - $8000 > Bank 2 (fixed)
 - $4000 > Bank 5 (screen)
 - $0000 > ROM

Banks 2 and 5 are permanently fixed at addresses $8000 and $4000, so it is not common to use them.

Banks 1, 3, 5 and 7 are banks in contention with the ULA, their use is not recommended in processes requiring maximum speed.

## See also

- [SetBank](memorybank/setbank.md)
- [GetBank](memorybank/getbank.md)
- [SetCodeBank](memorybank/setcodebank.md)
