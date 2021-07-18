
dim temp_wav_add, temp_ch_len as UInteger
dim temp_wav_len as Ubyte
dim cha_wave_len, chb_wave_len, chc_wave_len, chan_select as ubyte

adjustwavelength(1)

sub adjustwavelength(mode as ubyte)
	temp_wav_len=peek(temp_ch_len)

	if mode = 0
		temp_wav_len=temp_wav_len-1
	else
		temp_wav_len=temp_wav_len+1
	endif

	poke temp_wav_add,temp_wav_len
	poke temp_ch_len,temp_wav_len
end sub
