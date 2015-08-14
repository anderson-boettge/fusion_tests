#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>

__global__ void mult_mat(float *matA, float *matB, float *matR, int ncol, int nRows, int stream) {
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	int idy = blockIdx.y * blockDim.y + threadIdx.y;
	float res=0;
	int nPr = stream*ncol*nRows;
	for(int i=0; i<ncol; i++){
	  res += matA[ncol*idy+i] * matB[i*ncol+idx];
	}
	matR[nPr+idy*ncol+idx] = res;
	if(stream==0)
	printf("[%d] %.2f ", nPr+idy*ncol+idx, matR[nPr+idy*ncol+idx]);
}

float *matA, *matR, *matB;
int numColA, numRowA, numColB, numRowB, nCore, nRows;
FILE *arq;

float* read(){
	int numCol, numRow;
	fscanf(arq,"%d",&numRow);
	fscanf(arq,"%d",&numCol);
	numColB = numCol;
	float *mat = (float*)malloc(sizeof(float)*numCol*numRow);
	for(int i=0;i<numCol*numRow;i++){
		fscanf(arq,"%f",&mat[i]);
	}
	fclose(arq);
	return mat;
}

void print(int rows){
	for(int i=0; i<numColB*rows; i++){
		if(i%(numColB) == 0)
			printf("\n");
		printf("%.2f ",matR[i]);
	}
}

void multiply(){
	/*Variaveis globais no dispositivo*/
	float *matA_d;
	cudaMalloc((void **) &matA_d, numColA*numRowA*sizeof(float));
	float *matR_d;
	cudaMalloc((void **) &matR_d, numColB*numRowA*sizeof(float));
	float *matB_d;
	cudaMalloc((void **) &matB_d, numColB*numRowA*sizeof(float));

	cudaStream_t vectorOfStreams[nCore];
	for(int stream_id=0; stream_id<nCore; stream_id++)
				cudaStreamCreate(&vectorOfStreams[stream_id]);

	/*transferencia das matrizes A e B para GPU*/
	for(int stream_id=0; stream_id<nCore; stream_id++)
			cudaMemcpyAsync(&matA_d[nRows*stream_id*numColA],&matA[nRows*stream_id*numColA],nRows*numColA*sizeof(float),
					cudaMemcpyHostToDevice,vectorOfStreams[stream_id]);

	cudaMemcpy(matB_d, matB, numColB*numRowB*sizeof(float),cudaMemcpyHostToDevice);

	dim3 block(32,32);
    dim3 grid(numColB/32,(numRowA/4)/32);

    for(int stream_id=0; stream_id<nCore; stream_id++){
    	mult_mat<<<grid,block,0,vectorOfStreams[stream_id]>>>
    			(&matA_d[nRows*stream_id],matB_d,matR_d,numColB,nRows,stream_id);
    }
    cudaDeviceSynchronize();
	/*copia da resultante para CPU*/
    for(int stream_id=0; stream_id<nCore; stream_id++){
    	cudaMemcpyAsync(&matR[nRows*stream_id*numColB], &matR_d[nRows*stream_id*numColB],
    			numColB*nRows*sizeof(float),cudaMemcpyDeviceToHost, vectorOfStreams[stream_id]);
    }
	cudaDeviceSynchronize();

	cudaFree(matA_d);
	cudaFree(matB_d);
	cudaFree(matR_d);
}

int main(int argc, char *argv[]) {
	printf("Aplicação -/- -/- -/- %s / %s",argv[1],argv[2]);
	arq = fopen(argv[1],"r");
	if (arq == NULL) {
		printf ("Houve um erro ao abrir o arquivo.\n");
		return 1;
	}
	matA = read();
	arq = fopen(argv[2],"r");
	if (arq == NULL) {
		printf ("Houve um erro ao abrir o arquivo.\n");
		return 1;
	}
	matB = read();
	numColA = numRowA = numRowB = numColB;
	arq = fopen("time.txt","a");
	struct timeval utime;
	double tstart, tend;

	gettimeofday(&utime, NULL);
	tstart = utime.tv_sec + ( utime.tv_usec / 1000000.0 );

	nCore = 4;
	nRows = numRowA/nCore;

	matR = (float*) malloc(sizeof(float)*numRowA*numColB);
	multiply();
	print(128);
	free(matA);
    free(matB);
    free(matR);

    gettimeofday(&utime, NULL);
    tend = utime.tv_sec + ( utime.tv_usec / 1000000.0 );

    printf("\n\nExecution time: %.4lf\n",tend-tstart);
    fprintf(arq, "%.4lf\n",tend-tstart);
    fclose(arq);
    return 0;
}
