library ieee;
use ieee.std_logic_1164.all;

use work.Pack.all;

entity EXE_PHASE is
	port
	(
		mem_addr: out std_logic_vector(31 downto 0);
		mem_data: inout std_logic_vector(31 downto 0);
		clk, reset : in std_logic;
		instruction_in : in instruction_type;
		IRin : in std_logic_vector(31 downto 0);
		DP_I_flag_in, DP_R_flag_in, DP_flag_in : in std_logic;
		LS_flag_in, BBL_flag_in, S_flag_in : in std_logic;
		PC_in, PCnew_in : in std_logic_vector(31 downto 0);
		Rn_in, Rd_in, Rm_in, Rs_in : in std_logic_vector(31 downto 0);
		
		swap : out std_logic;
		dest_PCEXE : out std_logic;
		ALUout_out : out std_logic_vector(31 downto 0);
		brnc_cond_out : out std_logic;
		JMPaddr : out std_logic_vector(31 downto 0);
		BBL_flag_out : out std_logic;
		IRout : out std_logic_vector(31 downto 0);
		Load_data_out : out std_logic_vector(31 downto 0);
		mem_read: out std_logic;
		mem_write: out std_logic;
		req: out std_logic;
		ack: in std_logic;
		
		addrAtoBEXE, addrBtoAEXE : out std_logic_vector(3 downto 0);
		swapAtoB, swapBtoA : out std_logic_vector(31 downto 0);
		wait_mem: out std_logic
	);
end EXE_PHASE;



architecture structural of EXE_PHASE is

	component ALU
	
		port
		(
			s : in std_logic;
			f : in std_logic;
			cin, vin : in std_logic;
			IRin : in std_logic_vector(31 downto 0);
			Rn, Rm, Rs, Rd, Imm : in std_logic_vector(31 downto 0);
			
			DP_I_in, DP_R_in, DP_flag : in std_logic;
			instr_type : in instruction_type;
			
			swap : out std_logic;
			dest_PC : out std_logic;
			addrAtoB, addrBtoA : out std_logic_vector(3 downto 0);
			swapAtoB, swapBtoA : out std_logic_vector(31 downto 0);
			cout, vout : out std_logic;
			nout, zout : out std_logic;
			output : out std_logic_vector(31 downto 0)
		);
	
	end component;
	
	component CSR
	
		port
		(
			CLK, reset	: in  std_logic;
			
			N, Z, V, C : in std_logic;

			output : out std_logic_vector(31 downto 0)
		);
	
	end component;
	
	component ImmedOp
	
		port
		(
			IRin : in std_logic_vector(31 downto 0);
			s : in std_logic;
			Imm : out std_logic_vector(31 downto 0)
		);
		
	end component;
	
--	component LoadStore
--	
--		port
--		(
--			Rn, Rd : in std_logic_vector(31 downto 0);
--			l : in std_logic;
--			mem_address : out std_logic_vector(31 downto 0);
--			Rd_out : out std_logic_vector(31 downto 0)
--		);
--		
--	end component;
	
	component BBL
	
		port
		(
			clk, reset : in std_logic;
			BBL_flag : in std_logic;
			IRin : in std_logic_vector(31 downto 0);
			CSR : in std_logic_vector(31 downto 0);
			PCnew : in std_logic_vector(31 downto 0);
			cond : out std_logic;
			ADDRout : out std_logic_vector(31 downto 0)
		);
	
	end component;
	
	component EXE_MEM
	
		port
		(
			clk, reset : in std_logic;
			IRin : in std_logic_vector;
			ALUout, BBLaddr : in std_logic_vector(31 downto 0);
			brnc_cond : in std_logic;
			BBL_flag : in std_logic;
			Load_data_in : in std_logic_vector(31 downto 0);
			PCnew : in std_logic_vector(31 downto 0);
			dest_PC_in : in std_logic;
			swapAtoB_in, swapBtoA_in : in std_logic_vector(31 downto 0);
			addrAtoB_in, addrBtoA_in : in std_logic_vector(3 downto 0);		
			swap_in : in std_logic;
		
			swap_out : out std_logic;			
			swapAtoB_out, swapBtoA_out : out std_logic_vector(31 downto 0);
			addrAtoB_out, addrBtoA_out : out std_logic_vector(3 downto 0);
			dest_PC_out : out std_logic;			
			ALUout_out : out std_logic_vector(31 downto 0);
			brnc_cond_out : out std_logic;
			BBL_flag_out : out std_logic;
			JMPaddr : out std_logic_vector(31 downto 0);
			IRout : out std_logic_vector(31 downto 0);
			Load_data_out : out std_logic_vector(31 downto 0)
		
		);
	
	end component;
	
	component Data_Mem
		
		port
		(
		
		address: in std_logic_vector(31 downto 0); -- adresa u kesu
	   data_in: in std_logic_vector(31 downto 0); --podatak koji trebamo da upisemo u data
		data_out: out std_logic_vector(31 downto 0); --procitani podatak
		
		reset	: in  std_logic; 
		clk	: in  std_logic;
		
			
		rd: in std_logic;
		wr: in std_logic;
		stop: in std_logic;
		
		wait_mem: out std_logic;
	
		-- ABUS and DBUS
		mem_addr: out std_logic_vector(31 downto 0);
		mem_data: inout std_logic_vector(31 downto 0);
		
		-- memory read i write signal
	   mem_read: out std_logic;
		mem_write: out std_logic;
	
		-- request and acknowledgement for MEM access
		req: out std_logic;
		ack: in std_logic
		);
	end component;

	signal CSR_cout, CSR_vout : std_logic;
	signal CSR_cin, CSR_vin, CSR_nin, CSR_zin : std_logic;
	signal CSR_out : std_logic_vector(31 downto 0);
	signal Immed_OP : std_logic_vector(31 downto 0);
	signal BBLaddr : std_logic_vector(31 downto 0);
	signal Rd_out : std_logic_vector(31 downto 0);
	signal brnc_cond : std_logic;
	signal Aluout : std_logic_vector(31 downto 0);
	signal dest_PC : std_logic;
	signal swapAtoB_signal, swapBtoA_signal : std_logic_vector(31 downto 0);
	signal addrAtoBsignal, addrBtoAsignal : std_logic_vector(3 downto 0);
	signal swap_signal : std_logic;
	
	signal Data_signal : std_logic_vector(31 downto 0);				--data ulaz u data memoriju (cache)
	signal cache_wr : std_logic;
	signal Load_out_in_signal : std_logic_vector(31 downto 0);		--izlaz iz data memorije (cache), treba da se poveže

	
begin

	cache_wr <= not IRin(28); 
	Data_signal <= Rd_in when cache_wr = '1' else
						(others => 'Z');
	
	ALU_comp : component ALU
	
		port map
		(
			s => IRin(16),
			f => IRin(7),
			cin => CSR_out(29), vin => CSR_out(28),
			IRin => IRin,
			Rn => Rn_in, Rm => Rm_in, Rs => Rs_in, Rd => Rd_in, Imm => Immed_OP,
			
			DP_I_in => DP_I_flag_in, DP_R_in => DP_R_flag_in, DP_flag => DP_flag_in,
			instr_type => instruction_in,
			
			swap => swap_signal,
			dest_PC => dest_PC,
			swapAtoB => swapAtoB_signal, swapBtoA => swapBtoA_signal,
			addrAtoB => addrAtoBsignal, addrBtoA => addrBtoAsignal,
			cout => CSR_cin, vout => CSR_vin,
			nout => CSR_nin, zout => CSR_zin,
			output => ALUout	
		);
	
	CSR_comp : component CSR
	
		port map
		(
			CLK => clk, reset => reset,
			
			N => CSR_nin, Z => CSR_zin, V => CSR_vin, C => CSR_cin,

			output => CSR_out
		);
		
	ImmedOp_comp : component ImmedOp
	
		port map
		(
			IRin => IRin,
			s => IRin(16),
			Imm => Immed_OP
		);

--	LoadStore_comp : component LoadStore
--	
--		port map
--		(
--			Rn => Rn_in, Rd => Rd_in,
--			l => IRin(26)
--		);
		
	BBL_comp : component BBL
	
		port map
		(
			clk => clk, reset => reset,
			BBL_flag => BBL_flag_in,
			IRin => IRin,
			CSR => CSR_out,
			PCnew => PCnew_in,
			cond => brnc_cond,
			ADDRout => BBLaddr
		);
	
	EXE_MEM_stanglica : component EXE_MEM
	
		port map
		(
			clk => clk, reset => reset,
			IRin => IRin,
			ALUout => ALUout, BBLaddr => BBLaddr,
			brnc_cond => brnc_cond,
			BBL_flag => BBl_flag_in,
			Load_data_in => Load_out_in_signal,
			PCnew => PCnew_in,
			dest_PC_in => dest_PC,
			swapAtoB_in => swapAtoB_signal, swapBtoA_in => swapBtoA_signal,
			addrAtoB_in => addrAtoBsignal, addrBtoA_in => addrBtoAsignal,
			swap_in => swap_signal,
			
			swap_out => swap,
			swapAtoB_out => swapAtoB, swapBtoA_out => swapBtoA,
			addrAtoB_out => addrAtoBEXE, addrBtoA_out => addrBtoAEXE,		
			dest_PC_out => dest_PCEXE,			
			ALUout_out => ALUout_out,
			brnc_cond_out => brnc_cond_out,
			BBL_flag_out => BBL_flag_out,
			JMPaddr => JMPaddr,
			IRout => IRout,
			Load_data_out => Load_data_out

		);
		
		Data_comp : component Data_Mem
			
			port map (
			
				address => Rn_in,
				data_in => Data_signal,
				data_out => Load_out_in_signal,
		
				reset	=> reset,
				clk	=> clk,
		
			
				rd => not cache_wr,
				wr => cache_wr,
				stop => S_flag_in,
	
				wait_mem => wait_mem,
	
				mem_addr => mem_addr,
				mem_data => mem_data,
				
				mem_read => mem_read,
				mem_write => mem_write,
			
				
				req => req,
				ack => ack
			);
end structural;

