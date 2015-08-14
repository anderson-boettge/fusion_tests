testmain : link.o
	nvcc -arch=sm_35 -G -g -lcudadevrt -shared -o libdfs.so proxy.o -L/usr/local/cuda/lib64 -lcudart

gpuCode.o : link.o
	nvcc -arch=sm_35 -dlink -lcudadevrt proxy.o dfs_final.o -o gpuCode.o
	
link.o : dfs_final.cu final.h
	nvcc -x cu -arch=sm_35 -I$(JAVA_HOME)/include -I$(JAVA_HOME)/include/linux -I. -dc proxy.cpp -o proxy.o
	
clean :
	rm -f *.o *.so
	
#nvcc -x cu -arch=sm_35 -I. -dc dfs_final.cu -o dfs_final.o


#nvcc -x cu -arch=sm_35 -I/usr/lib/jvm/java-7-openjdk-i386/include -I/usr/lib/jvm/java-7-openjdk-i386/include/linux -I. -dc proxy.cpp -o proxy.o
#nvcc -x cu -arch=sm_35 -I. -dc dfs_final.cu -o dfs_final.o
#nvcc -arch=sm_35 -dlink -lcudadevrt proxy.o dfs_final.o -o gpuCode.o
#g++ -shared -Wl,-soname,libdfs.so -o libdfs.so proxy.o dfs_final.o gpuCode.o -L/usr/local/cuda/lib -Wall -lcudart
#java -Djava.library.path=. DFS_main < 11.txt

#objdump -DR libdfs.so
