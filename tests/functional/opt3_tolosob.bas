DIM toloTimer as UInteger
DIM toloStatus as UInteger
DIM toloLongSec, toloNSec, toloDelayAnim as UInteger
DIM sobando as UByte
	
inicio:
		if toloTimer=0 then
                        sobando = 1
			if sobando=2 then
				if peek (toloTimer+1)=12 then
					sobando=3
					goto pontolosobando
				end if
			end if
		
			if sobando=0 then
				if toloTimer=10 then
					if peek(toloStatus) band %00000010=0 then
						sobando=1
pontolosobando:
					end if
				end if	
			end if	
		end if
goto inicio

