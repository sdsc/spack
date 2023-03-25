files=`ls *.sh`
for file in $files;do
if [ $file != "change_cuda.sh" ]; then
   sed -i s/cuda_arch=70,80/cuda_arch=60/g $file
   sed -i s/cuda_arch=60,80/cuda_arch=60/g $file
   sed -i s/cuda_arch=70/cuda_arch=60/g $file
   sed -i s/cuda_arch=80/cuda_arch=60/g $file
fi
done
