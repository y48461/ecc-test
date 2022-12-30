library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--  Uncomment the following lines to use the declarations that are
--  provided for instantiating Xilinx primitive components.
--library UNISIM;
--use UNISIM.VComponents.all;

entity GluelessInterfacewithECC is
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
end GluelessInterfacewithECC;

architecture syn of GluelessInterfacewithECC is

	Component Stage2
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
	end component;

	component NANDeccCTRL
   	port (
   		DebugCount12bit: out std_logic_vector(11 downto 0);
		DEBUGHAMMINGout: out std_logic_vector(23 downto 0);

		-- disabling ECC
		enableECCmodule: in std_logic;
   		-- synchronous design basics
    		clkDIVx3 : in std_logic;
          clk        : in    std_logic; 
          Reset_L    : in    std_logic; 

		-- Host IO signals
          ALE_H      : in    std_logic; 
		CE_L       : in    std_logic; 
          CLE_H      : in    std_logic; 
          PRE        : in    std_logic; 
          RE_L       : in    std_logic; 
          WE_L       : in    std_logic; 
          WP_L       : in    std_logic; 
          RB_L       : out   std_logic; 
          hostIO     : inout std_logic_vector (7 downto 0); 
          --hostIO     : inout std_logic_vector (7 downto 0); 
		
		-- Error interrupt output
          errINT_H   : out   std_logic; 

		-- NAND IO signals
          NANDale_H : out   std_logic; 
          NANDce_L  : out   std_logic; 
          NANDcle_H : out   std_logic; 
          NANDpre   : out   std_logic; 
          NANDre_L  : out   std_logic; 
          NANDwe_L  : out   std_logic; 
          NANDwp_L  : out   std_logic; 
          nandrb_L   : in    std_logic; 
          nandIO     : inout std_logic_vector (7 downto 0);
		STATEvec: out std_logic_vector(3 downto 0)

		);
	end component;
	-- Internal signals
	signal intCE_L, intCLE_H, intALE_H, intWE_L, intRE_L, intWP_L, intPRE,
			intRB_L, errINT: std_logic;
	signal intDATA: std_logic_vector(nandBUSwidth-1 downto 0);
	signal DebugCount12bit: std_logic_vector(11 downto 0);
	signal DebugInternalCNT_stage2: std_logic_vector(23 downto 0);
	signal enableECCmodule : std_logic;
begin

--DebugInternalCNT <= DebugCount12bit;

--DebugInternalCNT <= intWE_L & intRE_L & intCE_L & intCLE_H & intDATA;
--DebugInternalCNT <= intWE_L & intRE_L & DebugCount12bit(3) & intCLE_H & intDATA;

--DEBUGHAMMINGout <= '0' & intCLE_H & intWE_L & intRE_L & intDATA & DebugInternalCNT_stage2;
--DEBUGHAMMINGout <= '0' & DebugCount12bit & DebugInternalCNT_stage2(10 downto 0);
DEBUGHAMMINGout <= DebugInternalCNT_stage2;

NANDcontroller:Stage2
    	Port map(
    		DebugCURaddreg => DebugCURaddreg,

		DebugInternalCNT => DebugInternalCNT_stage2,


		-- Standard synchronous inputs
    		clk => clk,
          Reset_L => Reset_L,

		-- STANDARD SRAM interface
          ADDR => ADDR,
          ST2outDATA => ST2outDATA,
          ST2inDATA => ST2inDATA,
          CE_L => CE_L,
          WE_L => WE_L,
          OE_L => OE_L,
          INT => INT,
          RB_L => RB_L,

		-- NAND or NAND ecc module interface
          nandCE_L => intCE_L,
          nandCLE_H => intCLE_H,
          nandALE_H => intALE_H,
          nandWE_L => intWE_L,
          nandRE_L => intRE_L,
          nandWP_L => intWP_L,
          nandPRE => intPRE,
          nandDATA => intDATA,
          nandRB_L => intRB_L,
          errINT => errINT,
		enableECCmodule => enableECCmodule
		);

ECCmodule: NANDeccCTRL
   	port map(
		DebugCount12bit => DebugCount12bit,
		DEBUGHAMMINGout => open,
		
		enableECCmodule => enableECCmodule,
   		-- synchronous design basics
    		clkDIVx3 => clkDIVx3,
          clk        => 		clk2x,
          Reset_L    =>		Reset_L,

		-- Host IO signals
          ALE_H => intALE_H,
		CE_L => intCE_L, 
          CLE_H => intCLE_H,
          PRE => intPRE,
          RE_L => intRE_L,
          WE_L => intWE_L,
          WP_L => intWP_L,
          RB_L => intRB_L,
          --hostIOin => intDATA, 
          --hostIOout => open,
          --hostIOdrv => open,
          hostIO => intDATA,
		
		-- Error interrupt output
          errINT_H => errINT,

		-- NAND IO signals

          NANDce_L  => 		nandCE_L,
          NANDcle_H => 		nandCLE_H,
          NANDale_H => 		nandALE_H,
          NANDwe_L  => 		nandWE_L,
          NANDre_L  => 		nandRE_L,
          NANDwp_L  => 		nandWP_L,
          NANDpre   => 		nandPRE,
          nandrb_L   => 		nandRB_L,
          nandIO	=> 		nandDATA,
		STATEvec => open

		);

end syn;
