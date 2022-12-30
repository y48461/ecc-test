library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--  Uncomment the following lines to use the declarations that are
--  provided for instantiating Xilinx primitive components.
--library UNISIM;
--use UNISIM.VComponents.all;

entity HAMMINGenc4Sets512Byte is
    Port ( 
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
end HAMMINGenc4Sets512Byte;

architecture RTL of HAMMINGenc4Sets512Byte is
	type hammingMATRIXtype is array (3 downto 0) of std_logic_vector(23 downto 0);
	signal internal_hammingCODE : hammingMATRIXtype;
begin

ParityGEN: process(enable, Reset_L, BUFnum, clk, DATAin)
	variable temp_rowparity: std_logic;
	variable intBUFnum: integer;
begin
	intBUFnum := conv_integer(BUFnum);
	temp_rowparity := DATAin(0) xor DATAin(1) xor DATAin(2) xor DATAin(3) xor DATAin(4) xor DATAin(5) xor DATAin(6) xor DATAin(7);
	if(rising_edge(clk)) then
		if(Reset_L = '0') then
			internal_hammingCODE(0) <= x"FFFFFF";
			internal_hammingCODE(1) <= x"FFFFFF";
			internal_hammingCODE(2) <= x"FFFFFF";
			internal_hammingCODE(3) <= x"FFFFFF";
		else
			if(enable = '1') then
				internal_hammingCODE(intBUFnum)(0) <= internal_hammingCODE(intBUFnum)(0) xor DATAin(0) xor DATAin(2) xor DATAin(4) xor DATAin(6);
				internal_hammingCODE(intBUFnum)(1) <= internal_hammingCODE(intBUFnum)(1) xor DATAin(1) xor DATAin(3) xor DATAin(5) xor DATAin(7);
				internal_hammingCODE(intBUFnum)(2) <= internal_hammingCODE(intBUFnum)(2) xor DATAin(0) xor DATAin(1) xor DATAin(4) xor DATAin(5);
				internal_hammingCODE(intBUFnum)(3) <= internal_hammingCODE(intBUFnum)(3) xor DATAin(2) xor DATAin(3) xor DATAin(6) xor DATAin(7);
				internal_hammingCODE(intBUFnum)(4) <= internal_hammingCODE(intBUFnum)(4) xor DATAin(0) xor DATAin(1) xor DATAin(2) xor DATAin(3);
				internal_hammingCODE(intBUFnum)(5) <= internal_hammingCODE(intBUFnum)(5) xor DATAin(4) xor DATAin(5) xor DATAin(6) xor DATAin(7);


				internal_hammingCODE(intBUFnum)(6) <= internal_hammingCODE(intBUFnum)(6) xor ( temp_rowparity and not(COUNTin(0)) );
				internal_hammingCODE(intBUFnum)(7) <= internal_hammingCODE(intBUFnum)(7) xor ( temp_rowparity and COUNTin(0) );

				internal_hammingCODE(intBUFnum)(8) <= internal_hammingCODE(intBUFnum)(8) xor ( temp_rowparity and not(COUNTin(1)) );
				internal_hammingCODE(intBUFnum)(9) <= internal_hammingCODE(intBUFnum)(9) xor ( temp_rowparity and COUNTin(1) );

				internal_hammingCODE(intBUFnum)(10) <= internal_hammingCODE(intBUFnum)(10) xor ( temp_rowparity and not(COUNTin(2)) );
				internal_hammingCODE(intBUFnum)(11) <= internal_hammingCODE(intBUFnum)(11) xor ( temp_rowparity and COUNTin(2) );

				internal_hammingCODE(intBUFnum)(12) <= internal_hammingCODE(intBUFnum)(12) xor ( temp_rowparity and not(COUNTin(3)) );
				internal_hammingCODE(intBUFnum)(13) <= internal_hammingCODE(intBUFnum)(13) xor ( temp_rowparity and COUNTin(3) );

				internal_hammingCODE(intBUFnum)(14) <= internal_hammingCODE(intBUFnum)(14) xor ( temp_rowparity and not(COUNTin(4)) );
				internal_hammingCODE(intBUFnum)(15) <= internal_hammingCODE(intBUFnum)(15) xor ( temp_rowparity and COUNTin(4) );

				internal_hammingCODE(intBUFnum)(16) <= internal_hammingCODE(intBUFnum)(16) xor ( temp_rowparity and not(COUNTin(5)) );
				internal_hammingCODE(intBUFnum)(17) <= internal_hammingCODE(intBUFnum)(17) xor ( temp_rowparity and COUNTin(5) );

				internal_hammingCODE(intBUFnum)(18) <= internal_hammingCODE(intBUFnum)(18) xor ( temp_rowparity and not(COUNTin(6)) );
				internal_hammingCODE(intBUFnum)(19) <= internal_hammingCODE(intBUFnum)(19) xor ( temp_rowparity and COUNTin(6) );

				internal_hammingCODE(intBUFnum)(20) <= internal_hammingCODE(intBUFnum)(20) xor ( temp_rowparity and not(COUNTin(7)) );
				internal_hammingCODE(intBUFnum)(21) <= internal_hammingCODE(intBUFnum)(21) xor ( temp_rowparity and COUNTin(7) );

				internal_hammingCODE(intBUFnum)(22) <= internal_hammingCODE(intBUFnum)(22) xor ( temp_rowparity and not(COUNTin(8)) );
				internal_hammingCODE(intBUFnum)(23) <= internal_hammingCODE(intBUFnum)(23) xor ( temp_rowparity and COUNTin(8) );
			end if;
		end if;
	end if;
end process ParityGEN;

MUXhammingout: process(BUFnum, internal_hammingCODE, COUNTin)
	variable varHAMMINGout: std_logic_vector(23 downto 0);
begin
	varHAMMINGout := internal_hammingCODE(conv_integer(BUFnum));
	HAMMINGout <= varHAMMINGout;
	case COUNTin(1 downto 0) is
		when "00" =>
			HammingtoWRITE <= varHAMMINGout(7 downto 0);
		when "01" =>
			HammingtoWRITE <= varHAMMINGout(15 downto 8);
		when "10" =>
			HammingtoWRITE <= varHAMMINGout(23 downto 16);
		when others =>
			HammingtoWRITE <= varHAMMINGout(7 downto 0);
	end case;

end process MUXhammingout;

end RTL;
