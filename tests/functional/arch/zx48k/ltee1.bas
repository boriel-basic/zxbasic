    'function prototypes
    declare function addWibble(msg as String) as String

    'call addWibble even though it's declared down there vvvv
    dim newMsg as String
    newMsg = addWibble("Hello")
    POKE len(newMsg), 0

    'return a string suffixed with 'wibble'
    function addWibble(msg as String) as String
       dim newString as String
       newString = msg
       newString = newString + "wibble"
       return newString
    end function
