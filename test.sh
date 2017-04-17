while true
do 
	lua test.lua > .out
	clear
	cat .out
	sleep 1
done
