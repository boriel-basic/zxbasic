#include <string.bas>


sub show_isdigit_letter_for(byval s as string)
	print bright 1; "str: "; inverse 1; s + chr$( 13 )
	print bright 1; "dig: ";
	for i = 0 to len( s ) - 1
		print( isdigit( s( i ) ) );
	next
	print( chr( 13 ) )
	print bright 1; "ltr: ";
	for i = 0 to len( s ) - 1
		print( isletter( s( i ) ) );
	next
	print( chr( 13 ) )
end sub


dim a as string = "abc0123456789cba.-,[]()/=?:"
dim b as string = "0123abc456abc789.-,[]()/=?:"

cls
show_isdigit_letter_for( a )
show_isdigit_letter_for( b )
