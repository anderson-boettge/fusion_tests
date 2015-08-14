
/*
 * main.c
 * SBLP 2014, special issue.
 * 
 *
 *  */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <cuda.h>

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

int mat_h[MAX];


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



void read() {
	int i;
	//scanf("%d", &upper_bound);
	scanf("%d", &N);
	for (i = 0; i < (N * N); i++) {
		scanf("%d", &mat_h[i]);
	}

}

int fatorBranchingNivelDesejado(int nivelDesejado, int N){

	return N-nivelDesejado+1;
}

unsigned int calculaNPrefixos(int nivelPrefixo, int nVertice) {
	unsigned int x = nVertice - 1;
	int i;
	for (i = 1; i < nivelPrefixo-1; ++i) {
		x *= nVertice - i-1;
	}
	return x;
}

unsigned int calculaNPrefixosNivelDesejado(int nivelInicial,int nivelDesejado, int nVertice) {

	int nivelBusca = nivelInicial+1;
	int i;
	unsigned int nprefixos = 1;

	for (i = nivelBusca; i <=nivelDesejado; ++i) {
		nprefixos *= fatorBranchingNivelDesejado(i,N);
	}
	return nprefixos;
	
}


void fillFixedPaths(short* preFixo, const int nivelPrefixo) {
	char flag[16];
	int vertice[16]; //representa o ciclo
	int cont = 0;
	int i, nivel; //para dizer que 0-1 ja foi visitado e a busca comeca de 1, bote 2


	for (i = 0; i < N; ++i) {
		flag[i] = 0;
		vertice[i] = -1;
	}

	vertice[0] = 0; //aqui!!!! vertice[nivel] = idx vflag[idx] = 1
	flag[0] = 1;
	nivel = 1;
	while (nivel >= 1) { // modificar aqui se quiser comecar a busca de determinado nivel

		if (vertice[nivel] != -1) {
			flag[vertice[nivel]] = 0;
		}

		do {
			vertice[nivel]++;
		} while (vertice[nivel] < N && flag[vertice[nivel]]); //


		if (vertice[nivel] < N) { //vertice[x] vertice no nivel x


			flag[vertice[nivel]] = 1;
			nivel++;

			if (nivel == nivelPrefixo) {
				for (i = 0; i < nivelPrefixo; ++i) {
					preFixo[cont * nivelPrefixo + i] = vertice[i];
//					printf("%d ", vertice[i]);
				}
//				printf("\n");
				cont++;
				nivel--;
			}
		} else {
			vertice[nivel] = -1;
			nivel--;
		}//else
	}//while
}

short * gerar_prefixos_iniciais(int nivelPreFixos, int nivelDesejado, int nPreFixos){
    	short * path_h = (short*) malloc(sizeof(short) * nPreFixos * nivelPreFixos);
	fillFixedPaths(path_h, nivelPreFixos);
	return path_h;
}

__global__ void dfs_final(int N, int *mat_d, short *preFixos_d, int nPrefixosNivelDesejado, int nivelDesejado, unsigned  int *sols_d,  int *melhorSol_d, int salto) {

	register int idx = blockIdx.x * blockDim.x + threadIdx.x;
	register int flag[16];
	register int vertice[16]; //representa o ciclo
	
	register int N_l = N;
	
	register int i, nivel; //para dizer que 0-1 ja foi visitado e a busca comeca de 1, bote 2
	register int custo;
	register int qtd_solucoes_thread = 0;
	register int UB_local = INFINITO;
	register int nivelGlobal = nivelDesejado;

	//int idxGlobal = idBlocoPai*blockDim.x+idx;

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
				//else {
					//if (custo > custoMin_d[0])
						//nivel--; //poda, LB maior que UB
				//}
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




__global__ void dfs_intermediario_cuda(int N, int *mat_d, short *preFixos_d,short *preFixos_novos_d,unsigned int nPreFixos,unsigned int qtd_prefixos_segundo_dfs,unsigned int qtd_prefixos_locais,int nivelInicial, int nivelDesejado, unsigned int *qtd_sols_d, int *melhor_sol_d) {
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
		

		// for (i = 0; i < N; ++i) {
		// 	vertice[i] = _VAZIO_;
		// 	flag[i] = _NAO_VISITADO_;
		// }
		
		// vertice[0] = 0;
		// flag[0] = _VISITADO_;
	
		
		// for (i = 1; i < nivelInicial; ++i) {
		// 	vertice[i] = preFixos[idx * nivelInicial + i];
		// 	flag[vertice[i]] = _VISITADO_;
		// }
		
	

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
				//else {
					//if (custo > custoMin_d[0])
						//nivel--; //poda, LB maior que UB
				//}
			}
			else {
				vertice[nivel] = _VAZIO_;
				nivel--;
			}//else
		}//while

	}//dfs
	
	__syncthreads();

	if(threadIdx.x == 0){
		

		//int qtd_prefixos_nivel_desejado = qtd_prefixos_locais * nPreFixos;
	    int block_size = 192;
		int n_blocks = (blockDim.x*qtd_prefixos_locais) / block_size + (blockDim.x % block_size == 0 ? 0 : 1);
//printf("\nSou a thread mestra do bloco %d criando %d blocks", blockIdx.x, n_blocks);
		// int saltoPrefixos = qtd_prefixos_locais*nivelDesejado*blockIdx.x*blockDim.x;
		// int saltoSolucoes = qtd_prefixos_locais * blockIdx.x*blockDim.x;
		// int saltoMelhorSol = qtd_prefixos_locais *blockIdx.x*blockDim.x; 
		
		 int saltoPrefixos = n_blocks*block_size*nivelDesejado*blockIdx.x;
		 int saltoSolucoes = n_blocks*block_size*blockIdx.x;
		 int saltoMelhorSol = n_blocks*block_size*blockIdx.x; 
		 int salto = n_blocks*block_size*blockIdx.x;

	    dfs_final<<<n_blocks,block_size>>>(N_l, mat_d, (preFixos_novos_d+saltoPrefixos), qtd_prefixos_segundo_dfs,  nivelDesejado , (qtd_sols_d+saltoSolucoes),(melhor_sol_d+saltoMelhorSol),salto);
//l__ void dfs_final(int N, int *mat_d, short *preFixos_d, int nPrefixosNivelDesejado, int nivelDesejado, unsigned  int *sols_d,  int *melhorSol_d) {

	
	}

}//kernel



/*
	Irei aqui alocar a matriz de custos, os prefixos do primeiro DFS e memoria suficiente pros prefixos do segundo DFS.
		NAO IREI FAZER MALLOCS EM TEMPO DE EXECUCAO, pos nao sei se o fusion possui isso
*/
void call_cuda_DFSIntermediario(short *path_h, unsigned int nPreFixos, unsigned int qtd_prefixos_segundo_dfs, int nivelPreFixos,int nivelDesejado){

	short *path_d;
	short *path_second_dfs_d;
	short *path_second_dfs_h = (short*)malloc(sizeof(short)*qtd_prefixos_segundo_dfs*nivelDesejado);

	unsigned int qtd_prefixos_locais = calculaNPrefixosNivelDesejado(nivelPreFixos,nivelDesejado,N);
	unsigned int qtd_sols_global = 0;

	int *mat_d;

	unsigned int *qtd_sols_h = (unsigned int*)malloc(sizeof(unsigned int)*qtd_prefixos_segundo_dfs);
	unsigned int *qtd_sols_d;

	int *melhor_sol_h = (int*)malloc(sizeof(int)*qtd_prefixos_segundo_dfs);
	int *melhor_sol_d;

	int block_size =192; //number threads in a block
	int n_blocks = nPreFixos / block_size + (nPreFixos % block_size == 0 ? 0 : 1); // # of blocks


	int otimo_global = INFINITO;
//	for(int i = 0; i<nPreFixos;++i){
//		for(int j = 0; j<nivelPreFixos;++j )
//			printf(" %d ", path_h[i*nivelPreFixos+j]);
//		printf("\n");
//	}

      	printf("\nQuantidade de prefixos por raiz: %d\n", qtd_prefixos_locais);


       	printf("\nQuantidade de prefixos no nivel desejado: %d\n", qtd_prefixos_segundo_dfs);


	HANDLE_ERROR( cudaMalloc((void **) &mat_d, N * N * sizeof(int)));
	HANDLE_ERROR( cudaMalloc((void **) &path_d, nPreFixos*nivelPreFixos*sizeof(short)));
	HANDLE_ERROR( cudaMalloc((void **) &path_second_dfs_d, qtd_prefixos_segundo_dfs*nivelDesejado*sizeof(short)));

	HANDLE_ERROR( cudaMalloc((void **) &qtd_sols_d, sizeof(int)*qtd_prefixos_segundo_dfs));
	HANDLE_ERROR( cudaMalloc((void **) &melhor_sol_d, sizeof(int)*qtd_prefixos_segundo_dfs));

	HANDLE_ERROR( cudaMemcpy(mat_d, mat_h, N * N * sizeof(int), cudaMemcpyHostToDevice));
	HANDLE_ERROR( cudaMemcpy(path_d, path_h, nPreFixos*nivelPreFixos*sizeof(short), cudaMemcpyHostToDevice));

	
	cudaDeviceSynchronize();
	dfs_intermediario_cuda<<< n_blocks,block_size >>>(N,mat_d,path_d, path_second_dfs_d, nPreFixos , qtd_prefixos_segundo_dfs,qtd_prefixos_locais,nivelPreFixos, nivelDesejado,qtd_sols_d,melhor_sol_d);

	cudaDeviceSynchronize();
	HANDLE_ERROR( cudaMemcpy(path_second_dfs_h, path_second_dfs_d, qtd_prefixos_segundo_dfs*nivelDesejado*sizeof(short), cudaMemcpyDeviceToHost));

        HANDLE_ERROR( cudaMemcpy(qtd_sols_h,qtd_sols_d, sizeof(unsigned int)*qtd_prefixos_segundo_dfs, cudaMemcpyDeviceToHost));
       HANDLE_ERROR( cudaMemcpy(melhor_sol_h, melhor_sol_d, sizeof(int)*qtd_prefixos_segundo_dfs, cudaMemcpyDeviceToHost));
	
	 for(int i = 0; i<qtd_prefixos_segundo_dfs; ++i){
	 	qtd_sols_global+=qtd_sols_h[i];
	 	if(melhor_sol_h[i]<otimo_global)
	 		otimo_global = melhor_sol_h[i];
	 	//printf("\nSolucoes encontradas pela thread %d: %d", i, sols_h[i]);	
	 	//printf("\n\tMelhor solucao encontrada pela thread %d: %d", i, melhorSol_h[i]);
	 }

	printf("\nQuantidade de solucoes global: %d. \n Otimo global: %d.\n", qtd_sols_global, otimo_global);

//	for(int i = 0; i<qtd_prefixos_segundo_dfs;++i){
//	 	for(int j = 0; j<nivelDesejado;++j )
//	 		printf(" %d ", path_second_dfs_h[i*nivelDesejado+j]);
//	 	printf("\n");
//	 }

}


int main() {

	read();

	int nivelPreFixos = 5;//Numero de niveis prefixados; o que nos permite utilizar mais threads. 
	int nivelDesejado = 7;

	short *path_h;

	//unsigned int qtd_sols_global = 0;

	//int otimo_global = INFINITO;

	unsigned int nPreFixos = calculaNPrefixos(nivelPreFixos,N);

	unsigned int qtd_prefixos_segundo_dfs;

	printf("\nNivel inicial: %d.", nivelPreFixos);
	printf("\nQuantidade de prefixos no nivel inicial: %d\n", nPreFixos);

	path_h = gerar_prefixos_iniciais(nivelPreFixos,nivelDesejado,nPreFixos);

	qtd_prefixos_segundo_dfs = nPreFixos * calculaNPrefixosNivelDesejado(nivelPreFixos,nivelDesejado,N);

	call_cuda_DFSIntermediario(path_h, nPreFixos, qtd_prefixos_segundo_dfs, nivelPreFixos, nivelDesejado);



	exit(1);

	return 0;
}
