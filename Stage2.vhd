

----------------------------------------


----------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--  Uncomment the following lines to use the declarations that are
--  provided for instantiating Xilinx primitive components.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Stage2 is
    Port (
    		DebugCURaddreg: out std_logic;

		DebugInternalCNT: out std_logic_vector(23 downto 0);


		-- Standard synchronous inputs
    		clk : in std_logic;
          Reset_L : in std_logic;

		-- STANDARD SRAM interface
          ADDR : in std_logic_vector(11 downto 0);
          ST2outDATA : out std_logic_vector(7 downto 0);
          ST2inDATA : in std_logic_vector(7 downto 0);
          CE_L : in std_logic;
          WE_L : in std_logic;
          OE_L : in std_logic;
          INT : out std_logic;
          RB_L : out std_logic;

		-- NAND or NAND ecc module interface
          nandCE_L : out std_logic;
          nandCLE_H : out std_logic;
          nandALE_H : out std_logic;
          nandWE_L : out std_logic;
          nandRE_L : out std_logic;
          nandWP_L : out std_logic;
          nandPRE : out std_logic;
          nandDATA : inout std_logic_vector(7 downto 0);
          nandRB_L : in std_logic;
          errINT : in std_logic;
		
		-- disabling ECC module signal
		enableECCmodule: out std_logic
		);
end Stage2;

architecture syn of Stage2 is
	component BRgenericByte
		generic( 

			AddressWIDTH : natural := 12;
			addressability : natural := 8;
			NumElements : natural := 2112);

		port (
			clk : in std_logic; 
			we  : in std_logic; 
			ADDR   : in std_logic_vector(AddressWIDTH - 1 downto 0); 
	 		di  : in std_logic_vector(addressability - 1 downto 0); 
	 		do  : out std_logic_vector(addressability - 1 downto 0)); 
	end component; 

	-- REGfile signals
	--signal WE_regfile_H: std_logic;
	--signal REGnum: std_logic_vector(3 downto 0);
	--signal REGfile_DATA, REGfile_DATAout: std_logic_vector(7 downto 0);

	-- BUFFER1 signals
	signal WE_buffer1_H: std_logic;
	signal buffer1_ADDR: std_logic_vector(11 downto 0);
	signal buffer1_DATA, buffer1_DATAout: std_logic_vector(7 downto 0);

	-- BUFFER2 signals
	signal WE_buffer2_H: std_logic;
	signal buffer2_ADDR: std_logic_vector(11 downto 0);
	signal buffer2_DATA, buffer2_DATAout: std_logic_vector(7 downto 0);

	component FSM_MNvcS2
		generic(
			nandBUSwidth: natural := 8;

			ErrorFetchCommand: std_logic_vector(7 downto 0) := x"23"
		);
		port(
	
			DebugCURaddreg: out std_logic;

			DebugInternalCNT: out std_logic_vector(23 downto 0);

			-- Standard synchronous inputs
	    		clk : in std_logic;
	          Reset_L : in std_logic;

			-- STANDARD SRAM interface
	          ADDR : in std_logic_vector(11 downto 0);
	          ST2outDATA : out std_logic_vector(7 downto 0);
	          ST2inDATA : in std_logic_vector(7 downto 0);
	          CE_L : in std_logic;
	          WE_L : in std_logic;
	          OE_L : in std_logic;
	          INT : out std_logic;
	          RB_L : out std_logic;

			-- NAND or NAND ecc module interface
	          nandCE_L : out std_logic;
	          nandCLE_H : out std_logic;
	          nandALE_H : out std_logic;
	          nandWE_L : out std_logic;
	          nandRE_L : out std_logic;
	          nandWP_L : out std_logic;
	          nandPRE : out std_logic;
	          nandDATA : inout std_logic_vector(7 downto 0);
	          nandRB_L : in std_logic;
	          errINT : in std_logic;

			-- Control signals

			-- REGfile signals
			--WE_regfile_H: out std_logic;
			--REGnum: out std_logic_vector(3 downto 0);
			--REGfile_DATA: out std_logic_vector(7 downto 0);
			--REGfile_DATAout: in std_logic_vector(7 downto 0);

			-- BUFFER1 signals
			WE_buffer1_H: out std_logic;
			buffer1_ADDR: out std_logic_vector(11 downto 0);
			buffer1_DATA: out std_logic_vector(7 downto 0);
			buffer1_DATAout: in std_logic_vector(7 downto 0);

			-- BUFFER2 signals
			WE_buffer2_H: out std_logic;
			buffer2_ADDR: out std_logic_vector(11 downto 0);
			buffer2_DATA: out std_logic_vector(7 downto 0);
			buffer2_DATAout: in std_logic_vector(7 downto 0);

			-- disabling ECC module signal
			enableECCmodule: out std_logic

			);
	end component;
	signal FSMdbgcnt: std_logic_vector(23 downto 0);
begin
--DebugInternalCNT <= x"0" & "000" & FSMdbgcnt(11 downto 9) & WE_buffer1_H & WE_buffer2_H;
DebugInternalCNT <= FSMdbgcnt;

statemachineMNvcs2: FSM_MNvcS2
--		generic map(
--			nandBUSwidth => 8,
--			ErrorFetchCommand => x"23"
--		)
		port map(
			DebugCURaddreg => DebugCURaddreg,

			--DebugInternalCNT => DebugInternalCNT,
			DebugInternalCNT => FSMdbgcnt,

			-- Standard synchronous inputs
	    		clk => clk,
	          Reset_L => Reset_L,

			-- STANDARD SRAM interface
	          ADDR => ADDR,
	          --DATA => DATA,
	          ST2outDATA => ST2outDATA,
     	     ST2inDATA => ST2inDATA,
	          CE_L => CE_L,
	          WE_L => WE_L,
	          OE_L => OE_L,
	          INT => INT,
	          RB_L => RB_L,

			-- NAND or NAND ecc module interface
	          nandCE_L => nandCE_L,
	          nandCLE_H => nandCLE_H,
	          nandALE_H => nandALE_H,
	          nandWE_L => nandWE_L,
	          nandRE_L => nandRE_L,
	          nandWP_L => nandWP_L,
	          nandPRE => nandPRE,
	          nandDATA => nandDATA,
	          nandRB_L => nandRB_L,
	          errINT => errINT,

			-- Control signals

			-- REGfile signals
			--WE_regfile_H => WE_regfile_H,
			--REGnum => REGnum,
			--REGfile_DATA => REGfile_DATA,
			--REGfile_DATAout => REGfile_DATAout,

			-- BUFFER1 signals
			WE_buffer1_H => WE_buffer1_H,
			buffer1_ADDR => buffer1_ADDR,
			buffer1_DATA => buffer1_DATA,
			buffer1_DATAout => buffer1_DATAout,

			-- BUFFER2 signals
			WE_buffer2_H => WE_buffer2_H,
			buffer2_ADDR => buffer2_ADDR,
			buffer2_DATA => buffer2_DATA,
			buffer2_DATAout => buffer2_DATAout,

			-- disabling ECC module signal
			enableECCmodule => enableECCmodule
			);



Buffer1: BRgenericByte
	generic map( 

		AddressWIDTH => 12,
		addressability => 8,
		NumElements => 2113)
	port map(
		clk => clk, 
		we  => WE_buffer1_H, 
		ADDR   => buffer1_ADDR,
	 	di => buffer1_DATA,
	 	do  => buffer1_DATAout); 

Buffer2: BRgenericByte
	generic map( 

		AddressWIDTH => 12,
		addressability => 8,
		NumElements => 2113)
	port map(
		clk => clk, 
		we  => WE_buffer2_H, 
		ADDR   => buffer2_ADDR,
	 	di => buffer2_DATA,
	 	do  => buffer2_DATAout); 


end syn;





