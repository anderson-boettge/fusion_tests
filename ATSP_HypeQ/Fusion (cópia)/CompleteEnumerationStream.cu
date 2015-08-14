/*
 * main.c
 *
 *  Created on: 26/01/2011
 *      Author: einstein/carneiro
 */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <cuda.h>
#include <omp.h>

#define mat(i,j) mat_h[i*N+j]
#define mat_h(i,j) mat_h[i*N+j]
#define mat_d(i,j) mat_d[i*N_l+j]
#define mat_block(i,j) mat_block[i*N_l+j]
#define proximo(x) x+1
#define anterior(x) x-1
#define MAX 8192
#define INFINITO 999999
#define ZERO 0
#define ONE 1

#define _VAZIO_      -1
#define _VISITADO_    1
#define _NAO_VISITADO_ 0

int qtd = 0;
int custo = 0;
int N;
int melhor = INFINITO;
int upper_bound;



#define CUDA_CHECK_RETURN(value) {											\
	cudaError_t _m_cudaStat = value;										\
	if (_m_cudaStat != cudaSuccess) {										\
		fprintf(stderr, "Error %s at line %d in file %s\n",					\
				cudaGetErrorString(_m_cudaStat), __LINE__, __FILE__);		\
		exit(1);															\
	} }





#define HANDLE_NULL( a ) {if (a == NULL) { \
		printf( "Host memory failed in %s at line %d\n", \
				__FILE__, __LINE__ ); \
				exit( EXIT_FAILURE );}}

#ifndef _DFS_CUDA_UB_STREAM_H_
#define _DFS_CUDA_UB_STREAM_H_

#include <stdio.h>

#ifdef __cplusplus
extern "C"
{
#endif
__global__ void dfs_cuda_UB_stream(int N,int stream_size, int *mat_d, 
	short *preFixos_d, int nivelPrefixo, int upper_bound, int *sols_d,
	int *melhorSol_d)
	{

	register int idx = blockIdx.x * blockDim.x + threadIdx.x;
	register int flag[16];
	register int vertice[16]; 

	register int N_l = N;

	register int i, nivel;
	register int custo;
	register int qtd_solucoes_thread = 0;
	register int UB_local = upper_bound;
	register int nivelGlobal = nivelPrefixo;
	int stream_size_l = stream_size;

	if (idx < stream_size_l) {

		for (i = 0; i < N_l; ++i) {
			vertice[i] = _VAZIO_;
			flag[i] = _NAO_VISITADO_;
		}

		vertice[0] = 0;
		flag[0] = _VISITADO_;
		custo= ZERO;

		for (i = 1; i < nivelGlobal; ++i) {

			vertice[i] = preFixos_d[idx * nivelGlobal + i];

			flag[vertice[i]] = _VISITADO_;
			custo += mat_d(vertice[i-1],vertice[i]);
		}

		nivel=nivelGlobal;

		while (nivel >= nivelGlobal ) {
			if (vertice[nivel] != _VAZIO_) {
				flag[vertice[nivel]] = _NAO_VISITADO_;
				custo -= mat_d(vertice[anterior(nivel)],vertice[nivel]);
			}

			do {
				vertice[nivel]++;
			} while (vertice[nivel] < N_l && flag[vertice[nivel]]); 
			
			if (vertice[nivel] < N_l) {
				custo += mat_d(vertice[anterior(nivel)],vertice[nivel]);
				flag[vertice[nivel]] = _VISITADO_;
				nivel++;

				if (nivel == N_l) {
					++qtd_solucoes_thread;
					if (custo + mat_d(vertice[anterior(nivel)],0) < UB_local) {
						UB_local = custo + mat_d(vertice[anterior(nivel)],0);
					}
					nivel--;
				}
			}
			else {
				vertice[nivel] = _VAZIO_;
				nivel--;
			}
		}
		sols_d[idx] = qtd_solucoes_thread;
		melhorSol_d[idx] = UB_local;
	}
}
#ifdef __cplusplus
}
#endif
#endif

#ifdef __cplusplus
extern "C" {
#endif
  
int *mat_d, *mat_h;
int *qtd_threads_streams;

int block_size =192, nivelPreFixos;
int *sols_h, *sols_d; 
int *melhorSol_h, *melhorSol_d; 
short * path_h, * path_d;
int chunk;
int numStreams, nPreFixos;
cudaStream_t vectorOfStreams[4];
int qtd_sols_global=0, otimo_global=INFINITO;

static void HandleError( cudaError_t err,const char *file,int line ) {
	if (err != cudaSuccess) {
		printf( "%s in %s at line %d\n", cudaGetErrorString( err ),
				file, line );
		exit( EXIT_FAILURE );
	}
}


void checkCUDAError(const char *msg) {
	cudaError_t err = cudaGetLastError();
	if (cudaSuccess != err) {
		fprintf(stderr, "Cuda error: %s: %s.\n", msg, cudaGetErrorString(err));
		exit(EXIT_FAILURE);
	}
}

int completeEnum(int* mat, int nivelPreF, int nPre, int tam, short* path, int nStream){
  mat_h = mat;
  //int nPreFixos = calculaNPrefixos(nivelPreFixos,N);
  nivelPreFixos = nivelPreF;
  
  nPreFixos = nPre;
  N = tam;
//   printf("nivelPreFixos: %d\nnPreFIxos: %d\nN: %d",nivelPreFixos, nPreFixos,N);
  
  chunk = nPreFixos/nStream; 
  numStreams = nStream;
//   printf("chunk: %d\nnStreams: %d\n\n\n", chunk,numStreams);
  
  qtd_threads_streams = (int*)malloc(sizeof(int)*numStreams);
  
  if(numStreams>1){
    for(int i = 0; i<numStreams-1 / block_size;++i){
      qtd_threads_streams[i] = chunk;
    }
  }
  
  CUDA_CHECK_RETURN( cudaMalloc((void **) &path_d, nPreFixos*nivelPreFixos*sizeof(short)));
  
  sols_h = (int*)malloc(sizeof(int)*nPreFixos);
  melhorSol_h = (int*)malloc(sizeof(int)*nPreFixos); 
  
  CUDA_CHECK_RETURN( cudaMalloc((void **) &mat_d, N * N * sizeof(int)));
  
  path_h = path;
  
  CUDA_CHECK_RETURN( cudaMemcpy(mat_d, mat_h, N * N * sizeof(int), cudaMemcpyHostToDevice));
  
  //for(int i =0; i<N*N;i++) printf("[ %d ]",mat_h[i]);
  
  for(int i = 0; i<nPreFixos; ++i) melhorSol_h[i] = INFINITO;
  
  CUDA_CHECK_RETURN( cudaMalloc((void **) &melhorSol_d, sizeof(int)*nPreFixos));
  CUDA_CHECK_RETURN( cudaMalloc((void **) &sols_d, sizeof(int)*nPreFixos));
  
    
}

int createStream(int rank){
    //printf("createStream: %d",rank);
    cudaStreamCreate(&vectorOfStreams[rank]);
    
    cudaMemcpyAsync(&path_d[rank*chunk*nivelPreFixos],&path_h[rank*chunk*nivelPreFixos],qtd_threads_streams[rank]*sizeof(short)*nivelPreFixos,cudaMemcpyHostToDevice,vectorOfStreams[rank]);
    cudaMemcpyAsync(&melhorSol_d[rank*chunk], &melhorSol_h[rank*chunk],qtd_threads_streams[rank]*sizeof(int), cudaMemcpyHostToDevice, vectorOfStreams[rank]);
    cudaMemcpyAsync(&sols_d[rank*chunk], &sols_h[rank*chunk], qtd_threads_streams[rank]*sizeof(int),cudaMemcpyHostToDevice,vectorOfStreams[rank]);
    
    return rank;
}
int callCompleteEnumStreams(int rank){
	
	//int resto = 0;

	//resto = (nPreFixos % chunk);
	
	const int num_blocks = chunk/block_size + (chunk % block_size == 0 ? 0 : 1); //13: 16 blocos 
// 	printf("Kernel %d\nnumblocks: %d \nblocksize: %d\n",rank, num_blocks, block_size);
	
	dfs_cuda_UB_stream<<<num_blocks,block_size,0,vectorOfStreams[rank]>>>(N,qtd_threads_streams[rank],mat_d, &path_d[rank*chunk*nivelPreFixos],nivelPreFixos,999999, &sols_d[rank*chunk],&melhorSol_d[rank*chunk]);
	cudaMemcpyAsync(&sols_h[rank*chunk],&sols_d[rank*chunk], qtd_threads_streams[rank]*sizeof(int),cudaMemcpyDeviceToHost,vectorOfStreams[rank]);
	cudaMemcpyAsync(&melhorSol_h[rank*chunk],&melhorSol_d[rank*chunk], qtd_threads_streams[rank]*sizeof(int),cudaMemcpyDeviceToHost,vectorOfStreams[rank]);
	
	cudaDeviceSynchronize();
	
// 	cudaMemcpy(sols_h,sols_d, nPreFixos*sizeof(int),cudaMemcpyDeviceToHost);
// 	cudaMemcpy(melhorSol_h,melhorSol_d, nPreFixos*sizeof(int),cudaMemcpyDeviceToHost);
// 	
// 	
	//testandoooooooooo
	if(rank==0){
	  for(int i = 0; i<nPreFixos; ++i){
	    qtd_sols_global+=sols_h[i];
	    if(melhorSol_h[i]<otimo_global)
	      otimo_global = melhorSol_h[i];
	  }

// 	  printf("\n\n\n\t niveis preenchidos: %d.\n",nivelPreFixos);
// 
// 	  printf("\t Numero de streams: %d.\n",numStreams);
// 	  printf("\t Tamanho do stream: %d.\n",chunk);
// 	  printf("\nQuantidade de solucoes encontradas: %d.", qtd_sols_global);
// 	  printf("\n\tOtimo global: %d.\n\n", otimo_global);
	}
	return rank;
}

int getQT(){
  return qtd_sols_global;
}


int getSol(){
  return otimo_global;
}

int clearAll(){
  CUDA_CHECK_RETURN( cudaFree(mat_d));
  CUDA_CHECK_RETURN( cudaFree(sols_d));
  CUDA_CHECK_RETURN( cudaFree(path_d));
  CUDA_CHECK_RETURN( cudaFree(melhorSol_d));
  
  for(int i = 0; i < numStreams; i++)  cudaStreamDestroy(vectorOfStreams[i]);
  
  return 1;
}
#ifdef __cplusplus
}
#endif
