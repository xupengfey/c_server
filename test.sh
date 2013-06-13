chmod +x ./c_server
for (( i = 0; i < 500; i++)); do 
	echo $i;
	./c_server &
done;
