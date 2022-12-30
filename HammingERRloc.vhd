library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--  Uncomment the following lines to use the declarations that are
--  provided for instantiating Xilinx primitive components.
--library UNISIM;
--use UNISIM.VComponents.all;

entity HammingERRloc is
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
end HammingERRloc;

architecture Behavioral of HammingERRloc is

	signal StoredHAMMING: std_logic_vector(23 downto 0);
	signal ERRloc : std_logic_vector(11 downto 0);
	signal errSTATUS: std_logic_vector(1 downto 0);
	signal internal_56bit: std_logic_vector(55 downto 0);

	signal errorXOR: std_logic_vector(23 downto 0);
	signal adjacency, LOCation: std_logic_vector(11 downto 0);
	signal internalERRstatus: std_logic_vector(1 downto 0);
begin

DBGlocation <= ERRloc;

	errorXOR <= (HammingCALC(23) xor StoredHAMMING(23)) &
			  (HammingCALC(22) xor StoredHAMMING(22)) &
			  (HammingCALC(21) xor StoredHAMMING(21)) &
			  (HammingCALC(20) xor StoredHAMMING(20)) &
			  (HammingCALC(19) xor StoredHAMMING(19)) &
			  (HammingCALC(18) xor StoredHAMMING(18)) &
			  (HammingCALC(17) xor StoredHAMMING(17)) &
			  (HammingCALC(16) xor StoredHAMMING(16)) &
			  (HammingCALC(15) xor StoredHAMMING(15)) &
			  (HammingCALC(14) xor StoredHAMMING(14)) &
			  (HammingCALC(13) xor StoredHAMMING(13)) &
			  (HammingCALC(12) xor StoredHAMMING(12)) &
			  (HammingCALC(11) xor StoredHAMMING(11)) &
			  (HammingCALC(10) xor StoredHAMMING(10)) &
			  (HammingCALC(9) xor StoredHAMMING(9)) &
			  (HammingCALC(8) xor StoredHAMMING(8)) &
			  (HammingCALC(7) xor StoredHAMMING(7)) &
			  (HammingCALC(6) xor StoredHAMMING(6)) &
			  (HammingCALC(5) xor StoredHAMMING(5)) &
			  (HammingCALC(4) xor StoredHAMMING(4)) &
			  (HammingCALC(3) xor StoredHAMMING(3)) &
			  (HammingCALC(2) xor StoredHAMMING(2)) &
			  (HammingCALC(1) xor StoredHAMMING(1)) &
			  (HammingCALC(0) xor StoredHAMMING(0));
	adjacency <= (errorXOR(0) xor errorXOR(1)) &
			   (errorXOR(2) xor errorXOR(3)) &
			   (errorXOR(4) xor errorXOR(5)) &
			   (errorXOR(6) xor errorXOR(7)) &
			   (errorXOR(8) xor errorXOR(9)) &
			   (errorXOR(10) xor errorXOR(11)) &
			   (errorXOR(12) xor errorXOR(13)) &
			   (errorXOR(14) xor errorXOR(15)) &
			   (errorXOR(16) xor errorXOR(17)) &
			   (errorXOR(18) xor errorXOR(19)) &
			   (errorXOR(20) xor errorXOR(21)) &
			   (errorXOR(22) xor errorXOR(23));
	LOCation <= (errorXOR(22) & errorXOR(20) & errorXOR(18) & errorXOR(16) & 
				errorXOR(14) & errorXOR(12) & errorXOR(10) & errorXOR(8) & 
				errorXOR(6) & errorXOR(4) & errorXOR(2) & errorXOR(0)) xor
				x"FFF";

ErrorLocation: process(HammingCALC ,StoredHAMMING, errorXOR, 
					adjacency, LOCation)
begin
	if(errorXOR = X"000000") then
		internalERRstatus <= "00";
	elsif(adjacency = "111111111111") then
		internalERRstatus <= "01";
	else
		internalERRstatus <= "10";
	end if;
	ERRloc <= LOCation;
	errSTATUS <= internalERRstatus;

end process ErrorLocation;


ShiftINcontent: process(clk, Reset_L, SHIFTinnandECC)
	variable REGcontents: std_logic_vector(23 downto 0);
begin
	if(Reset_L = '0') then
		REGcontents := x"000000";
	elsif(SHIFTinnandECC = '1') then
		if (rising_edge(clk)) then
			REGcontents := SHIFTdata & REGcontents(23 downto 8);
		end if;
	end if;

	StoredHAMMING <= REGcontents;
end process ShiftINcontent;



OpREG8byte: process(clk, Reset_L, ADDR, errSTATUS, ERRloc, ERRORloading)
	variable LoadERRORS: std_logic;
begin
	--ERRORloading <= LoadERRORS;
	LoadERRORS := ERRORloading;
	if(rising_edge(clk)) then
		if(Reset_L = '0') then
			internal_56bit <= X"00000000000000";
		elsif(LoadERRORS = '1') then
			case ADDR(2 downto 1) is
				when "00" =>
					internal_56bit(13 downto 0) <= errSTATUS & ERRloc;
				when "01" =>
					internal_56bit(27 downto 14) <= errSTATUS & ERRloc;
				when "10" =>
					internal_56bit(41 downto 28) <= errSTATUS & ERRloc;
				when "11" =>
					internal_56bit(55 downto 42) <= errSTATUS & ERRloc;
				when others =>
					internal_56bit <= internal_56bit;
			end case;
		end if;
	end if;
end process OpREG8byte;

NeedINT <= 	internal_56bit(13) or internal_56bit(12) or
			internal_56bit(27) or internal_56bit(26) or
			internal_56bit(41) or internal_56bit(40) or
			internal_56bit(55) or internal_56bit(54);

OUTPUTreg: process(ADDR, internal_56bit)
begin
	case ADDR is
		when "000" =>
			ERRORlocation8bit <= internal_56bit(7 downto 0); 
		when "001" =>
			ERRORlocation8bit <= "00" & internal_56bit(13 downto 8); 
		when "010" =>
			ERRORlocation8bit <= internal_56bit(21 downto 14); 
		when "011" =>
			ERRORlocation8bit <= "00" & internal_56bit(27 downto 22); 
		when "100" =>
			ERRORlocation8bit <= internal_56bit(35 downto 28); 
		when "101" =>
			ERRORlocation8bit <= "00" & internal_56bit(41 downto 36); 
		when "110" =>
			ERRORlocation8bit <= internal_56bit(49 downto 42); 
		when "111" =>
			ERRORlocation8bit <= "00" & internal_56bit(55 downto 50); 
		when others =>
			ERRORlocation8bit <= x"00";
	end case;
end process OUTPUTreg;

end Behavioral;
