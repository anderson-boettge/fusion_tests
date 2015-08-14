
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

unsigned int finalDFS(const int N, const short *preFixos, const int idx, int *melhor_sol, const int nPreFixos, const int nivelPrefixo){
	
	int flag[16];
	int vertice[16]; //representa o ciclo
	
	int i, nivel; //para dizer que 0-1 ja foi visitado e a busca comeca de 1, bote 2
	int custo=0;
	unsigned int qtd_solucoes_thread = 0;
	int UB_local = INFINITO;
	int nivelGlobal = nivelPrefixo;

	if (idx < nPreFixos) { //(@)botar algo com vflag aqui, pois do jeito que esta algumas threads tentarao descer.
			
		for (i = 0; i < N; ++i) {
			vertice[i] = _VAZIO_;
			flag[i] = _NAO_VISITADO_;
		}
		
		vertice[0] = 0;
		flag[0] = _VISITADO_;
		custo= ZERO;
		
		for (i = 1; i < nivelGlobal; ++i) {
			vertice[i] = preFixos[idx * nivelGlobal + i];
			flag[vertice[i]] = _VISITADO_;
			custo += mat_h(vertice[i-1],vertice[i]);
		}
		
		nivel=nivelPrefixo;


		while (nivel >= nivelGlobal ) { // modificar aqui se quiser comecar a busca de determinado nivel

			if (vertice[nivel] != _VAZIO_) {
				flag[vertice[nivel]] = _NAO_VISITADO_;
				custo -= mat_h(vertice[anterior(nivel)],vertice[nivel]);
			}

			do {
				vertice[nivel]++;
			} while (vertice[nivel] < N && flag[vertice[nivel]]); //


			if (vertice[nivel] < N) { //vertice[x] vertice no nivel x
				custo += mat_h(vertice[anterior(nivel)],vertice[nivel]);
				flag[vertice[nivel]] = _VISITADO_;
				nivel++;

				if (nivel == N) { //se o vértice do nível for == N, entao formou o ciclo e vc soma peso + vertice anterior -> inicio
						
					++qtd_solucoes_thread;

					if (custo + mat_h(vertice[anterior(nivel)],0) < UB_local) {
						UB_local = custo + mat_h(vertice[anterior(nivel)],0);
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

		// sols_d[idx] = qtd_solucoes_thread;
		// melhorSol_d[idx] = UB_local;

	}//dfs

	if(UB_local < (*melhor_sol)){
		*melhor_sol = UB_local;
	}
	return qtd_solucoes_thread;
}

int dfs2(const short *preFixos, const int idx, const int nivelInicial, const int nivelDesejado, int *otimo_global) {

	//pode tirar o idx

	register int flag[16];
	register int vertice[16]; //representa o ciclo
	register int i, nivel; //para dizer que 0-1 ja foi visitado e a busca comeca de 1, bote 2
	
	unsigned int qtd_solucoes_local = 0;
	unsigned int qtd_solucoes_filho = 0;

	int cont = 0;

	unsigned int qtd_prefixos_locais =  calculaNPrefixosNivelDesejado(nivelInicial,nivelDesejado,N);

	int melhor_sol = INFINITO;

	short *path_local;

	path_local = (short*)malloc(sizeof(short) * nivelDesejado *  qtd_prefixos_locais);
		

		for (i = 0; i < N; ++i) {
			vertice[i] = _VAZIO_;
			flag[i] = _NAO_VISITADO_;
		}
		
		vertice[0] = 0;
		flag[0] = _VISITADO_;
		custo= ZERO;
		
		for (i = 1; i < nivelInicial; ++i) {
			vertice[i] = preFixos[idx * nivelInicial + i];
			flag[vertice[i]] = _VISITADO_;
		}
		
		nivel=nivelInicial;

		while (nivel >= nivelInicial ) { // modificar aqui se quiser comecar a busca de determinado nivel

			if (vertice[nivel] != _VAZIO_) {
				flag[vertice[nivel]] = _NAO_VISITADO_;
			}

			do {
				vertice[nivel]++;
			} while (vertice[nivel] < N && flag[vertice[nivel]]); //


			if (vertice[nivel] < N) { //vertice[x] vertice no nivel x
			
				flag[vertice[nivel]] = _VISITADO_;
				nivel++;

				if (nivel == nivelDesejado) { //se o vértice do nível for == N, entao formou o ciclo e vc soma peso + vertice anterior -> inicio
						
					for (i = 0; i < nivelDesejado; ++i) {
						path_local[cont * nivelDesejado + i] = vertice[i];
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

	
	// for(int pref = 0; pref < qtd_prefixos_locais; ++pref){
	// 	for(int j = 0; j<nivelDesejado;++j){

	// 		printf(" %d ", path_local[pref*nivelDesejado + j]);
	// 	}
	// 	printf("\n");
	// }

	for(int pref = 0; pref < qtd_prefixos_locais; ++pref){
		qtd_solucoes_filho = finalDFS(N, path_local,pref, &melhor_sol, qtd_prefixos_locais,nivelDesejado);
		
		// printf("\nQtd de sols encontrada pelo prefixo %d: %d.\n",pref,qtd_solucoes_filho);

		qtd_solucoes_local+=qtd_solucoes_filho;
	
	}

	if(melhor_sol < (*otimo_global)){
		*otimo_global = melhor_sol;
	}

	free(path_local);

	return qtd_solucoes_local;

}//dfs2




int main() {

	read();

	
	int otimo_global = INFINITO;
	int qtd_sols_global = ZERO;

    
	int nivelPreFixos = 5;//Numero de niveis prefixados; o que nos permite utilizar mais threads. 
	int nivelDesejado = 8;

	unsigned int nPreFixos = calculaNPrefixos(nivelPreFixos,N);


	short * path_h = (short*) malloc(sizeof(short) * nPreFixos * nivelPreFixos);
	

	
	fillFixedPaths(path_h, nivelPreFixos);

	printf("\nNivel inicial: %d.", nivelPreFixos);
	printf("\nQuantidade de prefixos no nivel inicial: %d\n", nPreFixos);

	// for(int i = 0; i<nPreFixos;++i){
	// 	for(int j = 0; j<nivelPreFixos;++j )
	// 		printf(" %d ", path_h[i*nivelPreFixos+j]);
	// 	printf("\n");
	// }


	printf("\n Nivel desejado: %d.", nivelDesejado);
	printf("\n Prefixos individuais por pai no nivel desejado: %d .", calculaNPrefixosNivelDesejado(nivelPreFixos,nivelDesejado,N));
	printf("\n Prefixos totais no nivel desejado: %d .\n", calculaNPrefixosNivelDesejado(nivelPreFixos,nivelDesejado,N)*nPreFixos);


	//para nprefixos nivel inicial, imprimir as raizes de dfs descendentes criados
	for(int vertex = 0; vertex < nPreFixos; ++vertex){
		qtd_sols_global += dfs2(path_h, vertex, nivelPreFixos,nivelDesejado, &otimo_global) ;
	}

	printf("\n Quantidade de solucoes Global: %d.\n", qtd_sols_global);
	printf("\nOtimo global: %d. \n", otimo_global);
	


	return 0;
}
