# generate sample files for testin#g

#for ((i=1; i<=1000; i++))
#do
#rname=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c8`
#name=${rname: 0 :8}
#echo $name
#filen=$name"-8ee4-11ec-9061-c400ad444284.req"
#echo "file: $filen"
#touch $filen
#done


for ((i=1; i<=1000; i++))
do
rname=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c8`
name=${rname: 0 :8}
echo $name
filen=$name"-99fc-11ec-97a4-c400ad1a1ce3.p7mb64"
echo "file: $filen"
touch $filen
done

