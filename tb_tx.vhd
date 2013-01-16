library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity rs232_tx_tb is
end rs232_tx_tb;

architecture behaviour of rs232_tx_tb is

	component tx_func is
	port(	clk, reset : in std_logic;
			data : in std_logic_vector(7 downto 0);
			transmit_data : in std_logic;
			
			word_width : in std_logic_vector(3 downto 0);
			baud_period : in std_logic_vector(15 downto 0);
			use_parity_bit, parity_type : in std_logic;
			stop_bits : in std_logic_vector(1 downto 0);
			idle_line_lvl : in std_logic;

			tx : out std_logic;
			sending : out std_logic);
	end component;

	signal clk : std_logic := '0';
	signal reset : std_logic := '0';	
	constant clk_period : time := 2 ns;	-- 50MHz
	
	signal transmit_data : std_logic := '0';
	signal word_width : std_logic_vector(3 downto 0) := "1000";
	signal baud_period : std_logic_vector(15 downto 0) := "0000000000001000";
	signal use_parity_bit : std_logic := '0';
	signal parity_type : std_logic := '0';
	signal stop_bits : std_logic_vector(1 downto 0) := "10";
	signal idle_line_lvl : std_logic := '1';

	signal tx, sending : std_logic;

begin

	uut : tx_func port map (clk, reset, "10100101", transmit_data, word_width, baud_period, use_parity_bit, parity_type, stop_bits, idle_line_lvl, tx, sending);
	
	clk_process : process
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2; 
	end process;
	
	reset_process : process
	begin
		reset <= '0';
		wait for 12 ns;
		reset <= '1';
		wait for 5 ns;
		reset <= '0';
		wait for 4 ns;
		transmit_data <= '1';
		wait for 2 ns;
		transmit_data <= '0';
		wait for 180 ns;
		transmit_data <= '1';
		wait for 2 ns;
		transmit_data <= '0';
		wait;
	end process;


end behaviour;