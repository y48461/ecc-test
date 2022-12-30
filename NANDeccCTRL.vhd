library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--  Uncomment the following lines to use the declarations that are
--  provided for instantiating Xilinx primitive components.
--library UNISIM;
--use UNISIM.VComponents.all;

entity NANDeccCTRL is
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
		--nandDriveBuffer: out std_logic;
          nandIO     : inout std_logic_vector (7 downto 0);
		STATEvec: out std_logic_vector(3 downto 0)

		);
end NANDeccCTRL;

architecture syn of NANDeccCTRL is
	component HAMMINGenc4Sets512Byte is
	Port( 
    		clk : in std_logic;
          DATAin : in std_logic_vector(7 downto 0);
          Reset_L : in std_logic;
		enable : in std_logic;
          COUNTin : in std_logic_vector(8 downto 0);
		BUFnum : in std_logic_vector(1 downto 0);

          HAMMINGout : out std_logic_vector(23 downto 0);

		-- MUX out HAMMMING to be written to the NAND
		HammingtoWRITE: out std_logic_vector(7 downto 0)
		);
	end component;
	
	component HammingERRloc
	Port ( 
    		DBGlocation: out std_logic_vector(11 downto 0);
		clk : in std_logic;
		Reset_L: in std_logic;
		SHIFTdata: in std_logic_vector(7 downto 0);
		SHIFTinnandECC: in std_logic;

          HammingCALC : in std_logic_vector(23 downto 0);
		ADDR: in std_logic_vector(2 downto 0);
		
		NeedINT: out std_logic;
		ERRORlocation8bit: out std_logic_vector(7 downto 0);
		ERRORloading: in std_logic

		);
	end component;

	component LITEnandFSM
	generic(
		ErrorFetchCommand: std_logic_vector(7 downto 0) := x"23"
		);
	Port(
		DEBUGvector : out std_logic_vector (3 downto 0);

		-- disabling ECC
		enableECCmodule: in std_logic;
		-- The basics of synchronous design
    		clkDIVx3 : in std_logic;
    		clk : in std_logic;
		Reset_L : in std_logic;

    		-- Output interface
          hostIOin     : in std_logic_vector (7 downto 0); 
          hostIOout     : out std_logic_vector (7 downto 0); 
          hostIOdrv    : out std_logic; 
		-- hostIO : inout std_logic_vector(7 downto 0);
    		hostCE_L : in std_logic;
          hostCLE_H : in std_logic;
          hostALE_H : in std_logic;
          hostWE_L : in std_logic;
          hostRE_L : in std_logic;
          hostWP_L : in std_logic;
         	intPRE : in std_logic;
          hostRB_L : out std_logic;
          interrINT_H : out std_logic;
		
		-- NAND flash Interface
          nandCE_L : out std_logic;
          nandCLE_H : out std_logic;
          nandALE_H : out std_logic;
          nandWE_L : out std_logic;
          nandRE_L : out std_logic;
          nandWP_L : out std_logic;
          nandPRE : out std_logic;
          nandRB_L : in std_logic;
		--nandDriveBuffer: out std_logic;
    		nandIO : inout std_logic_vector(7 downto 0);
		 
		-- ECC state machine control
		ResetECCgen : out std_logic;
		EnableECCgen: out std_logic;
		ECCgenCNT: out std_logic_vector(8 downto 0);

		-- CounterCONTROL
		count12BIT : out std_logic_vector(11 downto 0);

		-- Interrupt required or not
		NeedINT : in std_logic;

		REen_OUT : out std_logic;

		-- Address output for internal 56 bit signal
		ADDR : out std_logic_vector(2 downto 0);

		-- For outputting to the tristate
		HAMMING8bitin: in std_logic_vector(7 downto 0);
		ErrorLOCations: in std_logic_vector(7 downto 0);

		loadERRlocERRORS: out std_logic;

		dataFORecc: out std_logic_vector(7 downto 0);
		STATEvec: out std_logic_vector(3 downto 0)

		 );
	end component;
	signal ResetECCgen, EnableECCgen: std_logic;
	signal count12BIT, DBGlocation : std_logic_vector(11 downto 0);
	signal NeedINT, ShiftOUTPUTin : std_logic;
	signal ADDR : std_logic_vector(2 downto 0);
	signal HAMMING8bitin, ERRORlocation8bit, dataFORecc
			: std_logic_vector(7 downto 0);
	signal ERRORloading : std_logic;
	signal CalculatedHAMMING : std_logic_vector(23 downto 0);
	signal BUFnum: std_logic_vector(1 downto 0);
	
	-- Tristate buf signals
	signal hostIOin, hostIOout: std_logic_vector(7 downto 0);
	signal hostIOdrv: std_logic;
	signal DEBUGvector: std_logic_vector(3 downto 0);
	signal STATEvectemp: std_logic_vector(3 downto 0);
	signal ECCgenCNT: std_logic_vector(8 downto 0);
begin

--DebugCount12bit <= DEBUGvector & STATEvectemp & count12BIT(11 downto 8);

--DebugCount12bit <=  NeedINT & ShiftOUTPUTin & ERRORloading & BUFnum 
--				& ADDR & DEBUGvector;
DebugCount12bit <= count12BIT;

--DEBUGHAMMINGout <= '0' & BUFnum & EnableECCgen & ECCgenCNT(3 downto 0) & CalculatedHAMMING(15 downto 0);
DEBUGHAMMINGout <= '0' & ECCgenCNT(0) & DBGlocation & ShiftOUTPUTin & 
				ERRORloading &	CalculatedHAMMING(7 downto 0);

LOGICimplementation: process(count12BIT, ERRORloading, ADDR, hostIOdrv,
						hostIOout, clk)
begin
	if(rising_edge(clk)) then	
		if(count12BIT <= x"1FF") then
			BUFnum <= "00";
		elsif(count12BIT <= x"3FF") then
			BUFnum <= "01";
		elsif(count12BIT <= x"5FF") then
			BUFnum <= "10";
		elsif(count12BIT <= x"7FF") then
			BUFnum <= "11";
		else
			BUFnum <= ADDR(2 downto 1);
		end if;
	end if;
	if(hostIOdrv = '1') then
		hostIO <= hostIOout;
	else
		hostIO <= "ZZZZZZZZ";
	end if;
end process LOGICimplementation;

hostIOin <= hostIO;

GenerateECC: HAMMINGenc4Sets512Byte
	Port map( 
    		clk => clk,
          DATAin => dataFORecc,
          Reset_L => ResetECCgen,
		enable => EnableECCgen,
          COUNTin => ECCgenCNT,
		BUFnum => BUFnum,

          HAMMINGout => CalculatedHAMMING,

		-- MUX out HAMMMING to be written to the NAND
		HammingtoWRITE => HAMMING8bitin
		);
	
errorLOCATIONblock: HammingERRloc
	Port map( 
    		DBGlocation => DBGlocation,
		clk => clk,
		Reset_L => Reset_L,

		SHIFTdata => nandIO,
		SHIFTinnandECC => ShiftOUTPUTin,

          HammingCALC => CalculatedHAMMING,
		ADDR => ADDR,
		
		NeedINT => NeedINT,
		ERRORlocation8bit => ERRORlocation8bit,
		ERRORloading => ERRORloading

		);


CTRLfsm: LITEnandFSM
	Port map(
		DEBUGvector => DEBUGvector,

		-- disabling ECC
		enableECCmodule => enableECCmodule,
		-- The basics of synchronous design
    		clk => clk,
    		clkDIVx3 => clkDIVx3,
		Reset_L => Reset_L,

    		-- Output interface
          hostIOin => hostIOin,
          hostIOout => hostIOout,
          hostIOdrv => hostIOdrv,
    		-- hostIO => hostIO,
    		hostCE_L => CE_L,
          hostCLE_H => CLE_H,
          hostALE_H => ALE_H,
          hostWE_L => WE_L,
          hostRE_L => RE_L,
          hostWP_L => WP_L,
          intPRE => PRE,
          hostRB_L => RB_L,
          interrINT_H => errINT_H,
		--hostDriveBuffer => hostDriveBuffer,

		-- NAND flash Interface
          nandCE_L => nandCE_L,
          nandCLE_H => nandCLE_H,
          nandALE_H => nandALE_H,
          nandWE_L => nandWE_L,
          nandRE_L => nandRE_L,
          nandWP_L => nandWP_L,
          nandPRE => nandPRE,
          nandRB_L => nandRB_L,
		--nandDriveBuffer => nandDriveBuffer,
    		nandIO => nandIO,
		 
		-- ECC state machine control
		ResetECCgen => ResetECCgen,
		EnableECCgen => EnableECCgen,
		ECCgenCNT => ECCgenCNT,

		-- CounterCONTROL
		count12BIT => count12BIT,

		-- Interrupt required or not
		NeedINT => NeedINT,

		REen_OUT => ShiftOUTPUTin,

		-- Address output for internal 56 bit signal
		ADDR => ADDR,

		-- For outputting to the tristate
		HAMMING8bitin => HAMMING8bitin,
		ErrorLOCations => ERRORlocation8bit,

		loadERRlocERRORS => ERRORloading,

		dataFORecc => dataFORecc,
		STATEvec => STATEvectemp

		 );

STATEvec <= STATEvectemp;

end syn;
