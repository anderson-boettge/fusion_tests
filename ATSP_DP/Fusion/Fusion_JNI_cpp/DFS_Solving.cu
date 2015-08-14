#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <cuda.h>

//I need to check how to do this in the compiler
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

static void HandleError( cudaError_t err,
                         const char *file,
                         int line ) {
    if (err != cudaSuccess) {
        printf( "%s in %s at line %d\n", cudaGetErrorString( err ),
                file, line );
        exit( EXIT_FAILURE );
    }
}
#define HANDLE_ERROR( err ) (HandleError( err, __FILE__, __LINE__ ))


#define HANDLE_NULL( a ) {if (a == NULL) { \
                            printf( "Host memory failed in %s at line %d\n", \
                                    __FILE__, __LINE__ ); \
                            exit( EXIT_FAILURE );}}
                           
#ifdef __cplusplus
extern "C"
{
#endif
/**global variables accelerator obj**/
int nivelPreFixos, nivelDesejado;
int N;
  
__global__ void dfs_final(int N, int *mat_d, int *preFixos_d, int nPrefixosNivelDesejado, int nivelDesejado, int *sols_d,  int *melhorSol_d, int salto) {

	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	int flag[16];
	int vertice[16]; //representa o ciclo
	
	int N_l = N;
	
	int i, nivel; //para dizer que 0-1 ja foi visitado e a busca comeca de 1, bote 2
	int custo;
	int qtd_solucoes_thread = 0;
	int UB_local = INFINITO;
	int nivelGlobal = nivelDesejado;

	int idxGlobal = salto+idx;


	if (idxGlobal < nPrefixosNivelDesejado) {
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

		while (nivel >= nivelGlobal ) { // modificar aqui se quiser comecar a busca de determinado nivel

			if (vertice[nivel] != _VAZIO_) {
				flag[vertice[nivel]] = _NAO_VISITADO_;
				custo -= mat_d(vertice[anterior(nivel)],vertice[nivel]);
			}

			do {
				vertice[nivel]++;
			} while (vertice[nivel] < N_l && flag[vertice[nivel]]); //


			if (vertice[nivel] < N_l) { //vertice[x] vertice no nivel x
				custo += mat_d(vertice[anterior(nivel)],vertice[nivel]);
				flag[vertice[nivel]] = _VISITADO_;
				nivel++;

				if (nivel == N_l) { //se o vértice do nível for == N, entao formou o ciclo e vc soma peso + vertice anterior -> inicio
						
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
			}//else
		}//while

		sols_d[idx] = qtd_solucoes_thread;
		melhorSol_d[idx] = UB_local;

	}//dfs

}//kernel


__global__ void dfs_intermediario_cuda(int N, int *mat_d, int *preFixos_d, int *preFixos_novos_d, int nPreFixos, int qtd_prefixos_segundo_dfs, int qtd_prefixos_locais,int nivelInicial, int nivelDesejado, int *qtd_sols_d, int *melhor_sol_d) {
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	int flag[16];
	int vertice[16]; //representa o ciclo
	
	int N_l = N;
	
	int i, nivel; //para dizer que 0-1 ja foi visitado e a busca comeca de 1, bote 2
	int cont = 0;
	
	nivel=nivelInicial;

	if (idx < nPreFixos) { //(@)botar algo com vflag aqui, pois do jeito que esta algumas threads tentarao descer.
	
		for (i = 0; i < N_l; ++i) {
			vertice[i] = _VAZIO_;
			flag[i] = _NAO_VISITADO_;
		}
		
		vertice[0] = 0;
		flag[0] = _VISITADO_;

		for (i = 1; i < nivel; ++i) {
			vertice[i] = preFixos_d[idx * nivelInicial + i];
			flag[vertice[i]] = _VISITADO_;
		}

		while (nivel >= nivelInicial) { // modificar aqui se quiser comecar a busca de determinado nivel

			if (vertice[nivel] != _VAZIO_) {
				flag[vertice[nivel]] = _NAO_VISITADO_;
			}

			do {
				vertice[nivel]++;
			} while (vertice[nivel] < N_l && flag[vertice[nivel]]); //

			if (vertice[nivel] < N_l) { //vertice[x] vertice no nivel x
				flag[vertice[nivel]] = _VISITADO_;
				nivel++;
				if (nivel == nivelDesejado) { //se o vértice do nível for == N, entao formou o ciclo e vc soma peso + vertice anterior -> inicio
					for (i = 0; i < nivelDesejado; ++i) {
						preFixos_novos_d[(idx*qtd_prefixos_locais*nivelDesejado) + (cont*nivelDesejado)+i] = vertice[i];
					}
					++cont;
					nivel--;
				}
			}
			else {
				vertice[nivel] = _VAZIO_;
				nivel--;
			}//else
		}//while

	}//dfs
	
	__syncthreads();

	if(threadIdx.x == 0){
	    int block_size = 192;
	    int n_blocks = (blockDim.x*qtd_prefixos_locais) / block_size + (blockDim.x % block_size == 0 ? 0 : 1);
            int saltoPrefixos = n_blocks*block_size*nivelDesejado*blockIdx.x;
	    int saltoSolucoes = n_blocks*block_size*blockIdx.x;
	    int saltoMelhorSol = n_blocks*block_size*blockIdx.x; 
	    int salto = n_blocks*block_size*blockIdx.x;

	    dfs_final<<<n_blocks,block_size>>>(N_l, mat_d, (preFixos_novos_d+saltoPrefixos), qtd_prefixos_segundo_dfs,  nivelDesejado , (qtd_sols_d+saltoSolucoes),(melhor_sol_d+saltoMelhorSol),salto);
	}
}//kernel


//local variables unit DFS_intermediario
int nPreFixos;
int qtd_prefixos_segundo_dfs;
int qtd_prefixos_locais;

int *path_second_dfs_d;
int *qtd_sols_d;
int *melhor_sol_d;
int *path_d;
int *mat_d;


void setData_c(int Nh, int* mat_h, int nivelP, int nivelD, int* path_h, int nPreFix, int qtd_segundo_dfs, int qtd_locais, int* qtd_sols_h, int* melhor_sol_h){
printf("SETDATA entrou");
    N = Nh;
    nPreFixos = nPreFix;
    qtd_prefixos_segundo_dfs = qtd_segundo_dfs;
    nivelPreFixos = nivelP;
    nivelDesejado = nivelD;
    qtd_prefixos_locais = qtd_locais;
    
    HANDLE_ERROR( cudaMalloc((void **) &mat_d, N * N * sizeof(int)));
    HANDLE_ERROR( cudaMalloc((void **) &path_d, nPreFixos*nivelPreFixos*sizeof(int)));
    HANDLE_ERROR( cudaMalloc((void **) &path_second_dfs_d, qtd_prefixos_segundo_dfs*nivelDesejado*sizeof(int)));

    HANDLE_ERROR( cudaMalloc((void **) &qtd_sols_d, sizeof(int)*qtd_prefixos_segundo_dfs));
    HANDLE_ERROR( cudaMalloc((void **) &melhor_sol_d, sizeof(int)*qtd_prefixos_segundo_dfs));

    HANDLE_ERROR( cudaMemcpy(mat_d, mat_h, N * N * sizeof(int), cudaMemcpyHostToDevice));
    HANDLE_ERROR( cudaMemcpy(path_d, path_h, nPreFixos*nivelPreFixos*sizeof(int), cudaMemcpyHostToDevice));
    
    printf("SETDATA OK");
}

void k_dfs_intermediario(int n_blocks, int block_size){
  printf("SETDATA KERNEL ENTROU");
    cudaDeviceSynchronize();
    dfs_intermediario_cuda<<< n_blocks,block_size >>>(N,mat_d,path_d, path_second_dfs_d, nPreFixos , qtd_prefixos_segundo_dfs,qtd_prefixos_locais,nivelPreFixos, nivelDesejado,qtd_sols_d,melhor_sol_d);
}

int* getResult(int* result){
  int qtd_sols_global, otimo_global;
  int *qtd_sols_h = (int*)malloc(sizeof(int)*qtd_prefixos_segundo_dfs);
  int *melhor_sol_h = (int*)malloc(sizeof(int)*qtd_prefixos_segundo_dfs);
  
  cudaDeviceSynchronize();
  
  HANDLE_ERROR( cudaMemcpy(qtd_sols_h,qtd_sols_d, sizeof(int)*qtd_prefixos_segundo_dfs, cudaMemcpyDeviceToHost));
  HANDLE_ERROR( cudaMemcpy(melhor_sol_h, melhor_sol_d, sizeof(int)*qtd_prefixos_segundo_dfs, cudaMemcpyDeviceToHost));
	
  for(int i = 0; i<qtd_prefixos_segundo_dfs; ++i){
      qtd_sols_global+=qtd_sols_h[i];
      if(melhor_sol_h[i]<otimo_global)
	otimo_global = melhor_sol_h[i];
  }
  cudaFree(mat_d);
  cudaFree(path_d);
  cudaFree(path_second_dfs_d);
  cudaFree(qtd_sols_d);
  cudaFree(melhor_sol_d);
  
  result[0]=qtd_sols_global;
  result[1]=otimo_global;
  return result;
}

#ifdef __cplusplus
}
#endif

