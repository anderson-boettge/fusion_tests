#include<cuda.h>


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

__device__ void call_dfs_final(int n_blocks, int block_size, int N, int *mat_d, int *preFixos_d, int nPrefixosNivelDesejado, int nivelDesejado, int *sols_d,  int *melhorSol_d, int salto){
  
  
  dfs_final<<<n_blocks, block_size>>>(N, mat_d, preFixos_d, nPrefixosNivelDesejado,  nivelDesejado , sols_d,melhorSol_d,salto);
}