
' Builting macros

#define per(__FILE__) __FILE__ + 1
#define cline(dion)  __FILE__ + "a" __LINE__ + dion

cline(5)
cline(5)

per(5)

__FILE__
__LINE__

' Overwrite builtin macros
#define __FILE__ 0
#define __LINE__ "a"

__FILE__
__LINE__

per(5)

#define per1(__FILE__) __FILE__ + 1
per1(5)

cline(5)
