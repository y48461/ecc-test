library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--  Uncomment the following lines to use the declarations that are
--  provided for instantiating Xilinx primitive components.
--library UNISIM;
--use UNISIM.VComponents.all;

entity LITEnandFSM is
	generic(
		ErrorFetchCommand: std_logic_vector(7 downto 0) := x"23"
		);
	Port(
		DEBUGvector : out std_logic_vector (3 downto 0);

		-- disabling ECC
		enableECCmodule: in std_logic;
		-- The basics of synchronous design
    		clk : in std_logic;
    		clkDIVx3 : in std_logic;
		Reset_L : in std_logic;

    		-- Output interface
          hostIOin     : in std_logic_vector (7 downto 0); 
          hostIOout     : out std_logic_vector (7 downto 0); 
          hostIOdrv    : out std_logic; 
    		--hostIO : inout std_logic_vector(7 downto 0);
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
end LITEnandFSM;

architecture syn of LITEnandFSM is
	type state is (Start, 
				ReadNAND, ReadNANDwaitforRB, ReadECCcalc, 
				ReadECCfromNAND,
				ProgramNAND, ProgramNANDaddr, ProgramNANDeccCALC,
				ProgramNANDeccwrite, ThrowINT,
				ProgramNANDfillinOther, ProgramNANDbufST0,
				ProgramNANDbufST1, ProgramNANDbufST2, ProgramNANDbufST3,
				ProgramNANDcmd10h, FetchERRORS, 
				FetchERRORS_waitforRE);
				--FetchERRORSread,
	signal cSTATE, nextSTATE: state;
	signal ResetCOUNTER_L, incCOUNT: std_logic;

	-- TUG the lines signals
	signal cntTUG: std_logic_vector(2 downto 0);
	signal ResetTUGthelines, TUGthelines: std_logic;

	signal Done2100Bytes: std_logic;

	signal firstVAL: std_logic;
	--ONEdelayedRE,, secondVAL: std_logic;
	-- Tristate buffer control
	signal nandIOtempVAL: std_logic_vector(7 downto 0);
	signal HammingINmuxSEL, triSTATEnandIO : std_logic;
	-- whtHOSTio, HAMMINGtoNANDsel, REstatus, 
	signal intIO : std_logic_vector(7 downto 0);
    	signal intCE_L, intCLE_H, intALE_H, intWE_L, intRE_L, intWP_L,
			intRB_L : std_logic;
	-- signal to make intIO 0xFF so that the extra writes can be done
	signal FFintIO, SELintIO10: std_logic;
	-- registers for double latching the signals
	signal hostIOin_tmp: std_logic_vector(7 downto 0);
	signal hostCE_L_tmp, hostCLE_H_tmp, hostALE_H_tmp, hostWE_L_tmp,
			hostRE_L_tmp, hostWP_L_tmp, hostRB_L_tmp:
				std_logic;
	signal internal_COUNT : std_logic_vector(11 downto 0);
	signal incrADDR_errLOC, errlocADDRsel, ECCgenCNTsel: std_logic;
	signal SHOOTenable, internal_REGeccgen : std_logic;

begin

count12BIT <= internal_COUNT;
nandPRE <= intPRE;

REen_OUT <= incrADDR_errLOC;

RisingEDGEdetctECCgen: process(clk, SHOOTenable)
	--variable internal_REGeccgen: std_logic;
begin
	if(rising_edge(clk)) then
		if(Reset_L = '0') then
			internal_REGeccgen <= '1';
		else
			internal_REGeccgen <= SHOOTenable;
		end if;

		if(Reset_L = '0') then
			EnableECCgen <= '0';
		else
			if(SHOOTenable = '1' and internal_REGeccgen = '0') then
				EnableECCgen <= '1';
			else
				EnableECCgen <= '0';
			end if;
		end if;

	end if;
end process RisingEDGEdetctECCgen;
CountUP: process(clk, ResetCOUNTER_L, incCOUNT, internal_COUNT, errlocADDRsel,
				ECCgenCNTsel)
	variable internal_REG: std_logic;
	variable refCNT: std_logic_vector(3 downto 0);
begin

	if(rising_edge(clk)) then
		if(ResetCOUNTER_L = '0') then
			internal_COUNT <= X"FFF";
			internal_REG := '0';
		elsif(incCOUNT = '1' and internal_REG = '0') then
			internal_COUNT <= internal_COUNT + '1';
			internal_REG := '1';
		elsif(incCOUNT = '0') then
			internal_REG := '0';
		end if;
	end if;

	if(rising_edge(clk)) then
		if(Done2100Bytes = '0') then
			refCNT := "0000";
		else
			if(incrADDR_errLOC = '1') then
				refCNT := refCNT + 1;
			end if;
			if(refCNT(1 downto 0) = "11" and TUGthelines = '0') then
				refCNT := refCNT + "0001";
			end if;
			loadERRlocERRORS <= incrADDR_errLOC;
			--if(refCNT(1 downto 0) = "10") then
			--	loadERRlocERRORS <= '1';
			--else
			--	loadERRlocERRORS <= '0';
			--end if;
		end if;
	end if;
	if(errlocADDRsel = '0') then
		ADDR <= refCNT(3 downto 2) & '0';
	else
		ADDR <= internal_COUNT(2 downto 0);
	end if;

	if(ECCgenCNTsel = '0') then
		ECCgenCNT <= internal_COUNT(8 downto 0);
	else
		ECCgenCNT <= "00000" & refCNT;
	end if;

	if(internal_COUNT >= x"833" and not(internal_COUNT = x"FFF")) then
		Done2100Bytes <= '1';
	else
		Done2100Bytes <= '0';
	end if;

end process CountUP;

SlowDOWNclk: process(clk, ResetTUGthelines, cntTUG)
	variable clkOUT : std_logic;
begin
	if(rising_edge(clk)) then
		if(ResetTUGthelines = '0') then
			cntTUG <= "000";
			clkOUT := '0';
		else
			cntTUG <= cntTUG + 1;
			if(cntTUG = "011") then
				clkOUT := '1';
			elsif(cntTUG = "101") then
				cntTUG <= "000";
				clkOUT := '0';
			end if;
		end if;
	end if;
	TUGthelines <= clkOUT;
	-- slowCLK <= clkOUT;
end process SlowDOWNclk;


SYNCfsmSYSTEM: process(clkDIVx3, Reset_L, cSTATE, nextSTATE, enableECCmodule)
begin
	if(rising_edge(clkDIVx3)) then
		if (Reset_L = '0') then
			cSTATE <= Start;
		else
			incrADDR_errLOC <= '0';
			triSTATEnandIO <= '1';
			case cSTATE is
				when Start =>
					triSTATEnandIO <= not(hostRE_L_tmp) or not(intRE_L)
							or(not(enableECCmodule) and not(hostRE_L));
				when ReadNAND =>
					triSTATEnandIO <= '0';
				when ReadNANDwaitforRB =>
					triSTATEnandIO <= '1';
				when ReadECCcalc =>
					triSTATEnandIO <= '1';
				when ReadECCfromNAND =>
					if(cntTUG = "011") then
						incrADDR_errLOC <= '1';
					else
						incrADDR_errLOC <= '0';
					end if;
					triSTATEnandIO <= '1';
				when ThrowINT =>
					triSTATEnandIO <= '1';
				when ProgramNAND =>
					triSTATEnandIO <= '0';
				when ProgramNANDaddr =>
					triSTATEnandIO <= '0';
				when ProgramNANDbufST2 =>
					triSTATEnandIO <= '0';
				when ProgramNANDeccCALC =>
					triSTATEnandIO <= '0';
				when ProgramNANDbufST0 =>
					triSTATEnandIO <= '0';
				when ProgramNANDfillinOther =>
					triSTATEnandIO <= '0';
				when ProgramNANDbufST1 =>
					triSTATEnandIO <= '0';
				when ProgramNANDeccwrite=>
					if(cntTUG = "011") then
						incrADDR_errLOC <= '1';
					else
						incrADDR_errLOC <= '0';
					end if;
					triSTATEnandIO <= '0';
				when ProgramNANDbufST3 =>
					triSTATEnandIO <= '0';
				when ProgramNANDcmd10h => -- this state writes the command
					triSTATEnandIO <= '0';
				when FetchERRORS =>
					triSTATEnandIO <= '1';
				when FetchERRORS_waitforRE =>
					triSTATEnandIO <= '1';
				when others =>
					triSTATEnandIO <= '1';
			end case;
			cSTATE <= nextSTATE;
		end if;
	end if;
end process SYNCfsmSYSTEM;

COMBfsmOUTPUTS: process(cSTATE, hostCLE_H_tmp, hostCE_L_tmp, hostWE_L_tmp, 
					hostIOin_tmp, hostRB_L_tmp, hostRE_L_tmp, 
					intRE_L, Done2100Bytes, TUGthelines, 
					NeedINT, intALE_H, intWE_L, cntTUG, hostALE_H_tmp, 
					internal_COUNT, intRB_L, intCE_L, intCLE_H, intWP_L,
					intIO, firstVAL, nandIO, HAMMING8bitin, ErrorLOCations,
					enableECCmodule, hostIOin, nandRB_L, hostCE_L,
					hostCLE_H, hostALE_H, hostWE_L, hostRE_L, hostWP_L)
	variable MUXselIO: std_logic := '0';
	variable fsmRB_L, fsmCE_L, fsmCLE_H, fsmALE_H, fsmWE_L,
			fsmRE_L, fsmWP_L :std_logic;
begin
	-- Variable outputs
	MUXselIO := '0'; --keep defaults
	-- FSM outputs
	fsmRB_L := '1';
	fsmCE_L := '1';
	fsmCLE_H := '0';
	fsmALE_H := '0';
	fsmWE_L := '1';
	fsmRE_L := '1';
	fsmWP_L := '1';

	interrINT_H <= '0';

	errlocADDRsel <= '0';
	-- WriteHAMMING to hostIO
	--whtHOSTio <= '0';
	--REstatus <= '0';
	--HAMMINGtoNANDsel <= '0';
 
	-- ECC state machine control
	ResetECCgen <= '1';
	SHOOTenable <= '1';
	ECCgenCNTsel <= '0';

	-- CounterCONTROL
	ResetCOUNTER_L <= '1';
	incCOUNT <= '0';

	-- MUX selects
	HammingINmuxSEL <= '0';
	
	-- TUG the lines
	ResetTUGthelines <= '0';
	--nandDriveBuffer <= hostDriveBuffer;
	STATEvec <= "1110";
	FFintIO <= '0';
	SELintIO10 <= '0';
	
	hostIOdrv <= '0';
	hostIOout <= x"BB";
	
	if(enableECCmodule = '0') then
		nandIOtempVAL <= hostIOin;
	else
		nandIOtempVAL <= intIO;
	end if;
	case cSTATE is
		when Start =>
			if(enableECCmodule = '0') then
				nandIOtempVAL <= hostIOin;
			else
				nandIOtempVAL <= intIO;
			end if;
			MUXselIO := '1';
			ResetCOUNTER_L <= '0';
			if (hostCLE_H_tmp = '1' and hostCE_L_tmp = '0' 
						and hostWE_L_tmp = '0' 
						and enableECCmodule = '1') then
				if(hostIOin_tmp = x"00") then
					nextSTATE <= ReadNAND;
				elsif(hostIOin_tmp = x"80") then
					nextSTATE <= ProgramNAND;
				elsif(hostIOin_tmp = ErrorFetchCommand) then
					nextSTATE <= FetchERRORS;
				end if;
			else
				nextSTATE <= Start;
			end if;
			STATEvec <= "0001";
			--STATEvec <= hostRB_L_tmp & "001";
			if(not(firstVAL) = '1' or not(intRE_L) = '1') then
				hostIOdrv <= '1';
				hostIOout <= nandIO;
			else
				hostIOdrv <= '0';
				hostIOout <= x"BB";
			end if;
-------------------- ERROR fetch States --------------------------
		when FetchERRORS =>
			errlocADDRsel <= '1';
			MUXselIO := '0';
			if(hostCLE_H_tmp = '0' and hostWE_L_tmp = '1') then
				nextSTATE <= FetchERRORS_waitforRE;
			else
				nextSTATE <= FetchERRORS;
			end if;		
		when FetchERRORS_waitforRE =>
			errlocADDRsel <= '1';
			MUXselIO := '0';
			hostIOdrv <= not(hostCE_L_tmp) and not(hostRE_L_tmp);
			hostIOout <= ErrorLOCations;

			incCOUNT <= not(intRE_L);
			if(hostCLE_H_tmp = '1' or hostALE_H_tmp = '1' or
				hostWE_L_tmp = '0' or (internal_COUNT = x"007" and intRE_L = '1')) then
				nextSTATE <= Start;
			else
				--if(hostCE_L_tmp = '0' and hostRE_L_tmp = '0') then
				--	nextSTATE <= FetchERRORSread;
				--else
				--	nextSTATE <= FetchERRORS_waitforRE;
				--end if;
				nextSTATE <= FetchERRORS_waitforRE;
			end if;
		--when FetchERRORSread => 
		--	errlocADDRsel <= '1';
		--	MUXselIO := '0';
		--	hostIOdrv <= '1';
		--	hostIOout <= ErrorLOCations;
		
		--	incCOUNT <= intRE_L;

		--	if(hostCLE_H_tmp = '1' or hostALE_H_tmp = '1' or
		--		hostWE_L_tmp = '0') then
		--		nextSTATE <= Start;
		--	else
		--		if(intRE_L = '1') then
		--			nextSTATE <= FetchERRORS_waitforRE;
		--		else
		--			nextSTATE <= FetchERRORSread;
		--		end if;
		--	end if;

-------------------- Read States --------------------------
		when ReadNAND =>
			
			nandIOtempVAL <= intIO;
			MUXselIO := '1';
			ResetECCgen <= '0';
			if(hostRB_L_tmp = '0') then
				nextSTATE <= ReadNANDwaitforRB;
			else
				nextSTATE <= ReadNAND;
			end if;
			STATEvec <= "0010";
			--STATEvec <= intRB_L & "010";
		when ReadNANDwaitforRB =>
			nandIOtempVAL <= x"FF";
			MUXselIO := '1';
			if(hostRB_L_tmp = '1' and hostRE_L_tmp = '0') then
				nextSTATE <= ReadECCcalc;
			else
				nextSTATE <= ReadNANDwaitforRB;
			end if;
			HammingINmuxSEL <= '1';
			STATEvec <= "0011";
		when ReadECCcalc =>
			hostIOdrv <= '1';
			hostIOout <= nandIO;
			-- pipe the inputs to the outputs
			MUXselIO := '1';
			-- ECC state machine control
			nandIOtempVAL <= x"CC";

			if (internal_COUNT <= x"7FF" or internal_COUNT = x"FFF") then
				SHOOTenable <= intRE_L;
			else
				SHOOTenable <= '1';
			end if;
			-- Increment Counter
			--incCOUNT <= not(intRE_L);
			incCOUNT <= not(hostRE_L_tmp);
		
			if (Done2100Bytes = '1' and intRE_L = '1') then
				nextSTATE <= ReadECCfromNAND;
			else
				nextSTATE <= ReadECCcalc;
			end if;
			HammingINmuxSEL <= '1';
			STATEvec <= "0100";
		when ReadECCfromNAND =>
			MUXselIO := '0';
			fsmCE_L := '0';
			fsmRB_L := '0';
			fsmRE_L := TUGthelines;
			hostIOdrv <= '0';
			-- 1 as we do not want to write to the lines
			--nandDriveBuffer <= '1';
			-- Increment Counter
			if(cntTUG = "100") then
				incCOUNT <= '1';
			else
				incCOUNT <= '0';
			end if;

			ResetTUGthelines <= '1';
			if (internal_COUNT >= x"83F") then
				nextSTATE <= ThrowINT;
			else
				nextSTATE <= ReadECCfromNAND;
			end if;
			STATEvec <= "0101";
		when ThrowINT =>
			MUXselIO := '1';
			interrINT_H <= NeedINT;
			nextSTATE <= Start;
			STATEvec <= "1100";
----------------------- Program NAND states -------------------------
		when ProgramNAND =>
			MUXselIO := '1';
			if(hostALE_H_tmp = '1') then
				nextSTATE <= ProgramNANDaddr;
			else
				nextSTATE <= ProgramNAND;
			end if;
			STATEvec <= "0110";
		when ProgramNANDaddr =>
			MUXselIO := '1';
			ResetECCgen <= '0';
			incCOUNT <= not(intWE_L);
			if(hostALE_H_tmp = '0' and internal_COUNT >= x"004" and
				not(internal_COUNT = x"FFF")) then
				nextSTATE <= ProgramNANDbufST2;
			else
				nextSTATE <= ProgramNANDaddr;
			end if;
			STATEvec <= "0111";

		when ProgramNANDbufST2 =>
			MUXselIO := '1';
			nextSTATE <= ProgramNANDeccCALC;
			ResetCOUNTER_L <= '0';
			STATEvec <= "0111";

		when ProgramNANDeccCALC =>
			-- pipe the inputs to the outputs
			MUXselIO := '1';
			
			-- ECC state machine control
			--ResetECCgen <= '1';
			if (internal_COUNT <= x"7FF" or internal_COUNT = x"FFF") then
				SHOOTenable <= intWE_L;
			else
				SHOOTenable <= '1';
			end if;
			-- Increment Counter
			--incCOUNT <= not(intWE_L);
			incCOUNT <= not(hostWE_L_tmp);

			-- internal_COUNT >= x"834" and 
			if ( (Done2100Bytes = '1' and intWE_L = '1') or (hostCLE_H_tmp = '1' and hostCE_L_tmp = '0'
					and hostWE_L_tmp = '0' and hostIOin_tmp = x"10") ) then
				nextSTATE <= ProgramNANDbufST0;
			else
				nextSTATE <= ProgramNANDeccCALC;
			end if;
			STATEvec <= "1000";
		when ProgramNANDbufST0 =>
			MUXselIO := '0';
			-- pipe the inputs to the outputs
			fsmCE_L := '0';
			fsmRB_L := '0';
			fsmWE_L := '1';

			FFintIO <= '1';
			if (internal_COUNT >= x"833") then
				nextSTATE <= ProgramNANDbufST1;
			else
				nextSTATE <= ProgramNANDfillinOther;
			end if;

		when ProgramNANDfillinOther =>
			MUXselIO := '0';
			-- pipe the inputs to the outputs
			fsmCE_L := '0';
			fsmRB_L := '0';
			fsmWE_L := TUGthelines;
					
			if(cntTUG = "100") then
				incCOUNT <= '1';
			else
				incCOUNT <= '0';
			end if;
			ResetTUGthelines <= '1';

			-- fire x"FF" into the intIO register
			FFintIO <= '1';
			if (internal_COUNT >= x"833") then
				nextSTATE <= ProgramNANDbufST1;
			else
				nextSTATE <= ProgramNANDfillinOther;
			end if;
		when ProgramNANDbufST1 =>
			MUXselIO := '0';
			-- pipe the inputs to the outputs
			fsmCE_L := '0';
			fsmRB_L := '0';
			fsmWE_L := '1';

			nextSTATE <= ProgramNANDeccwrite;
			ECCgenCNTsel <= '1';

		when ProgramNANDeccwrite =>
			ECCgenCNTsel <= '1';
			nandIOtempVAL <= HAMMING8bitin;

			MUXselIO := '0';
			-- pipe the inputs to the outputs
			fsmCE_L := '0';
			fsmRB_L := '0';
			fsmWE_L := TUGthelines;

			-- Increment Counter
			if(cntTUG = "100") then
				incCOUNT <= '1';
			else
				incCOUNT <= '0';
			end if;
			ResetTUGthelines <= '1';

			-- These 2 make sure the hamming is written
			-- to the NAND lines
			if (internal_COUNT >= x"83F") then
				nextSTATE <= ProgramNANDbufST3;
			else
				nextSTATE <= ProgramNANDeccwrite;
			end if;
			-- 1 as we do not want to write to the lines
			--nandDriveBuffer <= '0';
			STATEvec <= "1001";

		when ProgramNANDbufST3 =>
			MUXselIO := '0';
			-- pipe the inputs to the outputs
			fsmCE_L := '0';
			fsmRB_L := '0';
			fsmWE_L := '1';
			ResetTUGthelines <= '0';
			SELintIO10 <= '1';

			nextSTATE <= ProgramNANDcmd10h;
		when ProgramNANDcmd10h => -- this state writes the command
			MUXselIO := '0';
			fsmCE_L := '0';
			fsmRB_L := '0';
			fsmCLE_H := '1';
			fsmWE_L := TUGthelines;

			SELintIO10 <= '1';
			ResetTUGthelines <= '1';
			if(cntTUG = "100") then
				incCOUNT <= '1';
			else
				incCOUNT <= '0';
			end if;
			STATEvec <= "1010";
			if(internal_COUNT >= x"840") then
				nextSTATE <= Start;
			else
				nextSTATE <= ProgramNANDcmd10h;
			end if;
						
		when others =>
			MUXselIO := '0';
			nextSTATE <= Start;
			STATEvec <= "1011";
	end case;
	if(enableECCmodule = '0') then
		hostRB_L <= nandRB_L;
		nandCE_L <= hostCE_L;
		nandCLE_H <= hostCLE_H;
		nandALE_H <= hostALE_H;
		nandWE_L <= hostWE_L;
		nandRE_L <= hostRE_L;
		nandWP_L <= hostWP_L;
	elsif (MUXselIO = '0') then

		hostRB_L <= fsmRB_L;
		nandCE_L <= fsmCE_L;
		nandCLE_H <= fsmCLE_H;
		nandALE_H <= fsmALE_H;
		nandWE_L <= fsmWE_L;
		nandRE_L <= fsmRE_L;
		nandWP_L <= fsmWP_L;
	else
		hostRB_L <= intRB_L;
		nandCE_L <= intCE_L;
		nandCLE_H <= intCLE_H;
		nandALE_H <= intALE_H;
		nandWE_L <= intWE_L;
		nandRE_L <= intRE_L;
		nandWP_L <= intWP_L;
	end if;
end process COMBfsmOUTPUTS;

LATCHdata: process(clk, Reset_L, hostIOin, hostCE_L, hostCLE_H, hostALE_H,
				hostWE_L, hostRE_L, hostWP_L)
begin
	if(rising_edge(clk)) then
		if(Reset_L = '0') then
			intIO <= x"FF";
    			intCE_L <= '1';
			intCLE_H <= '0';
			intALE_H <= '0';
			intWE_L <= '1';
			intRE_L <= '1';
			intWP_L <= '1';
			intRB_L <= '1';
		else
			hostCE_L_tmp <= hostCE_L;
			hostCLE_H_tmp <= hostCLE_H;
			hostALE_H_tmp <= hostALE_H;
			hostWE_L_tmp <= hostWE_L;
			hostRE_L_tmp <= hostRE_L;
			hostWP_L_tmp <= hostWP_L;
			hostRB_L_tmp <= nandRB_L;
			
			hostIOin_tmp <= hostIOin;			
			--intIO <= hostIO;
			if(FFintIO = '1') then
				intIO <= x"FF";
			else
				if(SELintIO10 = '1') then
					intIO <= x"10";
				else
					intIO <= hostIOin_tmp;
				end if;
			end if;
    			intCE_L <= hostCE_L_tmp;
			intCLE_H <= hostCLE_H_tmp;
			intALE_H <= hostALE_H_tmp;
			intWE_L <= hostWE_L_tmp;
			intRE_L <= hostRE_L_tmp;
			intWP_L <= hostWP_L_tmp;
			intRB_L <= hostRB_L_tmp;
		end if;
	end if;
end process LATCHdata;

REorREdelayed: process(intRE_L, clk, Reset_L, firstVAL)
begin
	if(rising_edge(clk)) then
		if(Reset_L = '0') then
			firstVAL <= '0';
			--secondVAL <= '0';
		else
			firstVAL <= intRE_L;
			--secondVAL <= firstVAL;
		end if;
	end if;
	-- REstatus <= not(intRE_L) or secondVAL or firstVAL;
	--ONEdelayedRE <= not(intRE_L);
end process REorREdelayed;

--ONEdelayedRE <= not(intRE_L);

BUScontend: process(nandIO, intIO, HammingINmuxSEL, triSTATEnandIO, 
				nandIOtempVAL)
begin
	if (HammingINmuxSEL = '1') then
		dataFORecc <= nandIO;
	else
		dataFORecc <= intIO;
	end if;
	if(triSTATEnandIO = '0') then
		nandIO <= nandIOtempVAL;
	else
		nandIO <= "ZZZZZZZZ";
	end if;

end process BUScontend;

--DEBUGvector <= whtHOSTio & REstatus & HAMMINGtoNANDsel & '0';
--DEBUGvector <= triSTATEnandIO & nandIOtempVAL(2 downto 0);
DEBUGvector <= errlocADDRsel & internal_COUNT(2 downto 0);
end syn;
