public class DFS_Solving {
	int _VAZIO_ = -1;
	int _VISITADO_ = 1;
	int _NAO_VISITADO_ = 0;
	
	int INFINITO = 999999;
	int ZERO = 0;
	int ONE = 1;
	
	int nivelPreFixos, nivelDesejado;
	DFS_intermediario dfs_intermediario;
	int[] math_h;
	int N;
	
	DFS_Solving(int N, int[] mat_h, int nivelfixos, int desejado){
		this.N=N;
		this.mat_h = mat_h;
		this.nivelPreFixos = nivelfixos;
		this.nivelDesejado = desejado;		
	}
	
	public void getQTSol(){
		return dfs_intermediario.getQTSolutions();
	}

	public void getMLSol(){
		return dfs_intermediario.getMLSolutions();
	}
	
	class DFS_intermediario{
		
		int nPreFixos;
		int qtd_prefixos_segundo_dfs;
		int qtd_prefixos_locais;
		int[] path_second_dfs_d;
		int[] qtd_sols_h, melhor_sol_h;
		int[] qtd_sols_d; 
		int[] melhor_sol_d;
		int[] path_d;
		int[] mat_d;
		
		int i, nivel; //para dizer que 0-1 ja foi visitado e a busca comeca de 1, bote 2
		int cont = 0;
		int N_l;
		
		int block_size;
		int n_blocks;
		
		DFS_intermediario(int[] qtd_sols,int melhor_sol){
		    qtd_sols_h=qtd_sols;
		    melhor_sol_h=melhor_sol;
		}
		
		device int mat (int i, int j){
		    return mat_d[i*N_l+j];
		}
		
		device boolean vflag(int i){
		  if(i==0) return false;
		  return true;
		}
		
		public void setData(int[] path_h, int nPreFixos, int qtd_prefixos_segundo_dfs, 
				int qtd_prefixos_locais ) {
			//são necessárias no kernel
			this.nPreFixos=nPreFixos;
			this.qtd_prefixos_segundo_dfs=qtd_prefixos_segundo_dfs;
			this.qtd_prefixos_locais=qtd_prefixos_locais;
			this.path_second_dfs_d = new int [qtd_prefixos_segundo_dfs*nivelDesejado];
			
			//cuda memcpys
			this.path_d=path_h;
			this.mat_d = mat_h;
			
			//native method
			block_size =192; //number threads in a block
			n_blocks = nPreFixos / block_size + (nPreFixos % block_size == 0 ? 0 : 1); // # of blocks
			
		}
		
		public kernel void solDFS_intermediario() grid<<n_blocks>> block<<block_size>>{
			int idx = blockIdxX() * blockDimxX() + threadIdxX();
			int[] flag = new int[16];
			int[] vertice = new int[16]; //representa o ciclo
			
			nivel=nivelPreFixos;
			if (idx < nPreFixos) { //(@)botar algo com vflag aqui, pois do jeito que esta algumas threads tentarao descer.
				for (i = 0; i < N_l; ++i) {
					vertice[i] = _VAZIO_;
					flag[i] = _NAO_VISITADO_;
				}
				
				vertice[0] = 0;
				flag[0] = _VISITADO_;
				
				for (i = 1; i < nivel; ++i) {
					vertice[i] = path_d[idx * nivelPreFixos + i];
					flag[vertice[i]] = _VISITADO_;
				}

				while (nivel >= nivelPreFixos) { // modificar aqui se quiser comecar a busca de determinado nivel
					if (vertice[nivel] != _VAZIO_) {
						flag[vertice[nivel]] = _NAO_VISITADO_;
					}

					do {
						vertice[nivel]++;
					} while (vertice[nivel] < N_l && vflag(flag[vertice[nivel]])); //

					if (vertice[nivel] < N_l) { //vertice[x] vertice no nivel x
						flag[vertice[nivel]] = _VISITADO_;
						nivel++;
						if (nivel == nivelDesejado) { //se o vértice do nível for == N, entao formou o ciclo e vc soma peso + vertice anterior -> inicio
							for (i = 0; i < nivelDesejado; ++i) {
								path_second_dfs_d[(idx*qtd_prefixos_locais*nivelDesejado) + (cont*nivelDesejado)+i] = vertice[i];
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
			synchronized(threads);
			if(threadIdxX() == 0){
			    int block_size = 64;
				int n_blocks = (blockDimX()*qtd_prefixos_locais) / block_size + (blockDimX() % block_size == 0 ? 0 : 1);
				int saltoPrefixos = n_blocks*block_size*nivelDesejado*blockIdxX();
				int saltoSolucoes = n_blocks*block_size*blockIdxX();
				int saltoMelhorSol = n_blocks*block_size*blockIdxX(); 
				int salto = 	n_blocks*block_size*blockIdxX();
	
				dfs_final(N, mat_d, path_second_dfs_d, qtd_prefixos_segundo_dfs,  nivelDesejado , qtd_sols_d, melhor_sol_d,salto);
			}
		}//kernelintermediario
		
		public kernel void dfs_final(int N, int[] mat_d, int[] preFixos_d, int nPrefixosNivelDesejado, 
				int nivelDesejado, int[] sols_d,  int[] melhorSol_d, int salto) grid<<n_blocks>> block<<block_size>>{
			int idx = blockIdxX() * blockDimxX() + threadIdxX();
			int[] flag = new int[16];
			int[] vertice = new int[16]; //representa o ciclo
					
			int N_l = N;
			
			int i, nivel; //para dizer que 0-1 ja foi visitado e a busca comeca de 1, bote 2
			int custo;
			int qtd_solucoes_thread = 0;
			int UB_local = INFINITO;
			int nivelGlobal = nivelDesejado;

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
					custo += mat(vertice[i-1],vertice[i]);
				}
				
				nivel=nivelGlobal;

				while (nivel >= nivelGlobal ) { // modificar aqui se quiser comecar a busca de determinado nivel
					if (vertice[nivel] != _VAZIO_) {
						flag[vertice[nivel]] = _NAO_VISITADO_;
						custo -= mat(vertice[nivel-1],vertice[nivel]);
					}

					do {
						vertice[nivel]++;
					} while (vertice[nivel] < N_l && vflag(flag[vertice[nivel]])); //


					if (vertice[nivel] < N_l) { //vertice[x] vertice no nivel x
						custo += mat(vertice[nivel-1],vertice[nivel]);
						flag[vertice[nivel]] = _VISITADO_;
						nivel++;

						if (nivel == N_l) { //se o vértice do nível for == N, entao formou o ciclo e vc soma peso + vertice anterior -> inicio
							++qtd_solucoes_thread;
							if (custo + mat(vertice[nivel-1],0) < UB_local) {
								UB_local = custo + mat(vertice[nivel-1],0);
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

		}//kernelfinal
		
		
		public int[] getQTSolutions(){
			synchronized(device);
			qtd_sol_h = qtd_sols_d;
			return qtd_sol_h;
		}
		public int[] getMLSolutions(){
			synchronized(device);
			qtd_sol_h = qtd_sols_d;
			return qtd_sol_h;
		}
		
	}	
}
