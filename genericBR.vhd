
-----------------------------------------------------
--		Begin BlockRAM
-----------------------------------------------------

library IEEE;

use IEEE.STD_LOGIC_1164.ALL;

use IEEE.STD_LOGIC_ARITH.ALL;

use IEEE.STD_LOGIC_UNSIGNED.ALL;

 
 
-- Only XST supports RAM inference
-- Infers Single Port Block Ram 
 
entity BRgenericByte is

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
end BRgenericByte; 
 
architecture syn of BRgenericByte is 



	type ram_type is array (NumElements - 1 downto 0) of std_logic_vector (addressability - 1 downto 0);

	signal RAM : ram_type;

	signal read_a : std_logic_vector(AddressWIDTH - 1 downto 0); 
 
begin

	process (clk) 
	begin 
		if (clk'event and clk = '1') then  
			if (we = '1') then 
 				RAM(conv_integer(ADDR)) <= di; 
 			end if; 
 			read_a <= ADDR; 
 		end if; 
	end process; 
 
	do <= RAM(conv_integer(read_a));

 
end syn;
 
-----------------------------------------------------
--		 End BlockRAM
-----------------------------------------------------

