import java.util.Scanner;

public class DFS_main {
	DFS_Solving solving_accel;
	
	int MAX = 512;
	int INFINITO = 999999;
	int ZERO = 0;
	int ONE = 1;
	
	int nivelPreFixos, nivelDesejado;
	int N;
	int[] mat_h;
	
	DFS_main(int nivelPreFixos, int nivelDesejado){
		read();
		this.nivelPreFixos = nivelPreFixos;
		this.nivelDesejado = nivelDesejado;
		int[] path_h;
		int nPreFixos = calculaNPrefixos();
		int qtd_prefixos_segundo_dfs;

		System.out.println("\nNivel inicial: " + nivelPreFixos);
		System.out.println("\nQuantidade de prefixos no nivel inicial: "+ nPreFixos);

		path_h = gerar_prefixos_iniciais(nPreFixos);

		qtd_prefixos_segundo_dfs = nPreFixos * calculaNPrefixosNivelDesejado();
		//qtd_prefixos_segundo_dfs = nPreFixos * calculaNPrefixosNivelDesejado(nivelPreFixos,nivelDesejado,N);
		call_DFSIntermediario(path_h, nPreFixos, qtd_prefixos_segundo_dfs);
	}
	
	void read(){
		Scanner entrada = new Scanner(System.in);
		int i , j ;
		N = entrada.nextInt();
		mat_h = new int [N*N];
		for( i = 0 ; i < (N*N) ; i++ ){
			mat_h[i]= entrada.nextInt();
		}
	}
	
	private int calculaNPrefixos() {
	  int x = N - 1;
	  int i;
	  for (i = 1; i < nivelPreFixos-1; ++i) {
		x *= (N - i-1);
	  }
	  return x;
	}
	
	int[] gerar_prefixos_iniciais(int nPreFixos){
	    int[] path_h = new int[nPreFixos * nivelPreFixos];
		fillFixedPaths(path_h);
		return path_h;
	}
	
	boolean flag(int i){
	  if(i==0) return false;
	  return true;
	}
	
	private void fillFixedPaths(int[] preFixo) {
		int vflag[]= new int[16];
		int vertice[] = new int [16]; //representa o ciclo
		int cont = 0;
		int i, nivel; //para dizer que 0-1 ja foi visitado e a busca comeca de 1, bote 2

		for (i = 0; i < N; ++i) {
			vflag[i] = 0;
			vertice[i] = -1;
		}

		vertice[0] = 0; //aqui!!!! vertice[nivel] = idx vflag[idx] = 1
		vflag[0] = 1;
		nivel = 1;
		while (nivel >= 1) { // modificar aqui se quiser comecar a busca de determinado nivel
			if (vertice[nivel] != -1) {
				vflag[vertice[nivel]] = 0;
			}
			do {
				vertice[nivel]++;
			} while (vertice[nivel] < N && flag(vflag[vertice[nivel]])); //

			if (vertice[nivel] < N) { //vertice[x] vertice no nivel x
				vflag[vertice[nivel]] = 1;
				nivel++;
				if (nivel == nivelPreFixos) {
					for (i = 0; i < nivelPreFixos; ++i) {
						preFixo[cont * nivelPreFixos + i] = vertice[i];
//						printf("%d ", vertice[i]);
					}
//					printf("\n");
					cont++;
					nivel--;
				}
			} else {
				vertice[nivel] = -1;
				nivel--;
			}//else
		}//while
	}
	
	short calculaNPrefixosNivelDesejado() {
		int nivelBusca = nivelPreFixos+1;
		int i;
		short nprefixos = 1;
		for (i = nivelBusca; i <=nivelDesejado; ++i) {
			nprefixos *= fatorBranchingNivelDesejado(i,N);
		}
		return nprefixos;
	}
	
	int fatorBranchingNivelDesejado(int nivelDesejado, int N){
		return N-nivelDesejado+1;
	}
	
	void call_DFSIntermediario(int[] path_h, int nPreFixos, int qtd_prefixos_segundo_dfs){
		int[] result = new int[2];
		int qtd_prefixos_locais = calculaNPrefixosNivelDesejado();
		int[] qtd_sols_h = new int[qtd_prefixos_segundo_dfs];
		int[] melhor_sol_h = new int [qtd_prefixos_segundo_dfs];
		
		int otimo_global = INFINITO;
		int qtd_sols_global = 0;
	
		System.out.println("\nQuantidade de prefixos por raiz: "+ qtd_prefixos_locais);
	   	System.out.println("\nQuantidade de prefixos no nivel desejado: "+ qtd_prefixos_segundo_dfs);
	
	   	solving_accel = new DFS_Solving(N,mat_h,nivelPreFixos,nivelDesejado);
	   	DFS_Solving.DFS_intermediario dfs_intermediario = solving_accel.new DFS_intermediario();
	   	
	   	dfs_intermediario.setData(path_h, nPreFixos, qtd_prefixos_segundo_dfs,qtd_prefixos_locais,qtd_sols_h,melhor_sol_h);
	        dfs_intermediario.solDFS_intermediario();
	   	
	        result = dfs_intermediario.getQTSolutions();
	   	
	   	System.out.println("\nQuantidade de solucoes global:  "+ result[0] +" Otimo global:  "+ result[1]+"\n");
	}
	
	
	
	
	
	public static void main (String args[]){
		int nivelPreFixos = 5;//Numero de niveis prefixados; o que nos permite utilizar mais threads. 
		int nivelDesejado = 7;
		DFS_main dfs = new DFS_main(nivelPreFixos,nivelDesejado);
	}
	
}
