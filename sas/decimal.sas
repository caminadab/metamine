cijfer = '0' + 0..10 ; ascii
decimaal = cijfer^int

parse(decimaal)
	cijfers = rev decimaal
	i = cijfers.i
	tiental = 10^i
	som tiental * cijfers

3 >> decimaal
