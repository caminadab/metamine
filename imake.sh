while [ 1 ]
do
	make > /dev/null 2> /tmp/out
	sleep 1
	clear
	cat /tmp/out
	./satis
done
