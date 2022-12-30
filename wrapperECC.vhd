library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--  Uncomment the following lines to use the declarations that are
--  provided for instantiating Xilinx primitive components.
--library UNISIM;
--use UNISIM.VComponents.all;

entity wrapperECC is
  port (
  	-- orignal signals
    RS232_RX : in std_logic;
    RS232_TX : out std_logic;
    sys_clkBOARD : in std_logic;
    sys_rstBOARD : in std_logic;
	--Reset_LnonLATCHED: in std_logic;

	-- Stage 2 debug signals
    DBGst2ADDR : out std_logic_vector(11 downto 0);
    DBGst2CE_L : out std_logic_vector(0 downto 0);
    DBGst2OE_L : out std_logic_vector(0 downto 0);
    DBGst2WE_L : out std_logic;
    DBGst2DATA : out std_logic_vector(7 downto 0);

    -- Nand flash controller signals
     nandCE_L : out std_logic;
     nandCLE_H : out std_logic;
     nandALE_H : out std_logic;
     nandWE_L : out std_logic;
     nandRE_L : out std_logic;
     nandWP_L : out std_logic;
     nandPRE : out std_logic;
     nandDATA : inout std_logic_vector(7 downto 0);
     nandRB_L : in std_logic
);
end wrapperECC;

architecture syn of wrapperECC is

component system
  port (
    RS232_RX : in std_logic;
    RS232_TX : out std_logic;
    sys_clk : in std_logic;
    sys_rst : in std_logic;
    st2ADDR : out std_logic_vector(0 to 11);
    st2CEhigh : out std_logic_vector(0 to 0);
    st2OE_L : out std_logic_vector(0 to 0);
    st2WE_L : out std_logic;
    useless : out std_logic_vector(12 to 31);
    st2DATA_I : in std_logic_vector(0 to 7);
    st2DATA_O : out std_logic_vector(0 to 7);
    st2DATA_T : out std_logic_vector(0 to 7)
  );
end component;

component GluelessInterfacewithECC
	generic(
		nandBUSwidth: natural := 8
		);
    Port (
    		DebugCURaddreg: out std_logic;

		DebugInternalCNT: out std_logic_vector(11 downto 0);

		DEBUGHAMMINGout: out std_logic_vector(23 downto 0);

		-- Standard synchronous inputs
		clkDIVx3 : in std_logic;
    		clk2x : in std_logic;
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
          nandRB_L : in std_logic);
end component;
-- speeding up the clk
	COMPONENT clkSPEEDup
	PORT(
		RST_IN : IN std_logic;
		CLKIN_IN : IN std_logic;          
		LOCKED_OUT : OUT std_logic;
		CLK2X_OUT : OUT std_logic;
		CLKDV_OUT : OUT std_logic;
		CLKIN_IBUFG_OUT : OUT std_logic;
		CLK0_OUT : OUT std_logic
		);
	END COMPONENT;


	-- Stage 2 signals
	signal st2ADDR : std_logic_vector(11 downto 0);
	signal st2CE_L : std_logic_vector(0 to 0);
	signal st2CEhigh : std_logic_vector(0 to 0);
	signal st2OE_L : std_logic_vector(0 to 0);
	signal st2WE_L : std_logic;
	signal st2DATA_I : std_logic_vector(7 downto 0);
	signal st2DATA_O : std_logic_vector(7 downto 0);
	
	signal DebugInternalCNT: std_logic_vector(11 downto 0);
	signal DebugCURaddreg: std_logic;	
	-- Reset double buffering
	signal reset_Lst1, Reset_L: std_logic;
	signal lockedRST, sys_rst, sys_clk, clk2x: std_logic;
	--, clkDIVx3
	signal DEBUGHAMMINGout: std_logic_vector(23 downto 0);
begin

	Inst_clkSPEEDup: clkSPEEDup PORT MAP(
		RST_IN => sys_rstBOARD,
		CLKIN_IN => sys_clkBOARD,
		LOCKED_OUT => lockedRST,
		CLKDV_OUT => open,
		CLK2X_OUT => clk2x,
		CLKIN_IBUFG_OUT => open,
		CLK0_OUT => sys_clk 
	);

BufferRESET_L: process(sys_clk)
begin
	if(rising_edge(sys_clk)) then
		reset_Lst1 <= lockedRST and not(sys_rstBOARD);
		sys_rst <= not(reset_Lst1);
		Reset_L <= reset_Lst1;
	end if;
end process BufferRESET_L;

MicroBlazesystem: system
	  port map(
	    RS232_RX => RS232_RX,
	    RS232_TX => RS232_TX,
	    sys_clk => sys_clk,
	    sys_rst => sys_rst,

	    st2ADDR => st2ADDR,
	    st2CEhigh => st2CEhigh,
	    st2OE_L => st2OE_L,
	    st2WE_L => st2WE_L,
	    useless => open,
	    st2DATA_I => st2DATA_I,
		-- st2DATA_I => x"FF",

	    st2DATA_O => st2DATA_O,
	    st2DATA_T => open
	  );

--DBGst2ADDR <= st2ADDR(11 downto 0);
--DBGst2ADDR <= DebugInternalCNT;
--DBGst2ADDR <= DebugCURaddreg & DebugInternalCNT(10 downto 0);
--DBGst2CE_L <= st2CE_L;
--DBGst2OE_L <= st2OE_L;
--DBGst2WE_L <= st2WE_L;

DBGst2ADDR <= DEBUGHAMMINGout(11 downto 0);
DBGst2CE_L <= DEBUGHAMMINGout(12 downto 12);
DBGst2OE_L <= DEBUGHAMMINGout(13 downto 13);
DBGst2WE_L <= DEBUGHAMMINGout(14);
DBGst2DATA <= DEBUGHAMMINGout(22 downto 15);

--	OnnandINPUT: process(st2DATA_I, st2DATA_O, st2WE_L)
--	begin
--		if(st2WE_L = '0') then
--			DBGst2DATA <= st2DATA_O;
--		else
--			DBGst2DATA <= st2DATA_I;
--		end if;
--	end process OnnandINPUT;


st2CE_L <= not(st2CEhigh);

Stage2interconnect: GluelessInterfacewithECC
    	Port map(
    		DebugCURaddreg => DebugCURaddreg,
		DebugInternalCNT => DebugInternalCNT,
		DEBUGHAMMINGout => DEBUGHAMMINGout,

		-- Standard synchronous inputs
    		clkDIVx3 => clk2x,
    		clk2x => clk2x,
    		clk => sys_clk,
          Reset_L => Reset_L,

		-- STANDARD SRAM interface
          ADDR => st2ADDR,
          ST2outDATA => st2DATA_I,
          ST2inDATA => st2DATA_O,
          CE_L => st2CE_L(0),
          WE_L => st2WE_L,
          OE_L => st2OE_L(0),
          INT => open,
          RB_L => open,

		-- NAND or NAND ecc module interface
          nandCE_L => nandCE_L,
          nandCLE_H => nandCLE_H,
          nandALE_H => nandALE_H,
          nandWE_L => nandWE_L,
          nandRE_L => nandRE_L,
          nandWP_L => nandWP_L,
          nandPRE => nandPRE,
          nandDATA => nandDATA,
          nandRB_L => nandRB_L
		);


end syn;
