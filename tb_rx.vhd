library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity rs232_rx_tb is
end rs232_rx_tb;

architecture behaviour of rs232_rx_tb is

	--component under test
	component rx_func is
	port(	clk, reset, rx_enable : in std_logic;
			rx : in std_logic;
			
			word_width : in std_logic_vector(3 downto 0);
			period : in std_logic_vector(15 downto 0);
			use_parity_bit, parity_type : in std_logic;	--0 = even, 1 = odd
			stop_bits : in std_logic_vector(1 downto 0);
			idle_line_lvl : in std_logic;
			
			start_samples : in std_logic_vector(3 downto 0);	--How many correct samples should give a start bit
			line_samples : in std_logic_vector(3 downto 0);		--How many samples should tip the internal rx value
			
			data 		: out std_logic_vector(7 downto 0);
			data_ready 	: out std_logic;
			parity_error :	out std_logic;
			stop_bit_error : out std_logic);
	end component;

	--tx_func is only used for generating signals
	component tx_func is
	port(	clk, reset : in std_logic;
			data : in std_logic_vector(7 downto 0);
			new_data : in std_logic;
			
			word_width : in std_logic_vector(3 downto 0);
			
			full_cycle : in std_logic_vector(15 downto 0);
			use_parity_bit, parity_type : in std_logic;
			stop_bits : in std_logic_vector(1 downto 0);
			idle_line_lvl : in std_logic;
			
			tx : out std_logic;
			sending : out std_logic);
	end component;
	
	
	signal clk : std_logic := '0';
	signal reset : std_logic := '0';	
	constant clk_period : time := 2 ns;	-- 50MHz
	
	signal new_data : std_logic := '0';
	signal word_width : std_logic_vector(3 downto 0) := "1000";
	signal full_cycle : std_logic_vector(15 downto 0) := "0000000000100000";
	signal use_parity_bit : std_logic := '1';
	signal parity_type : std_logic := '0';	--0 = even, 1 = odd
	signal stop_bits : std_logic_vector(1 downto 0) := "01";

	signal txrx, sending : std_logic;
	signal idle_line_lvl : std_logic := '1';
	
	signal tx_data : std_logic_vector(7 downto 0) := "10110010";
	signal rx_data : std_logic_vector(7 downto 0);

	--specific for rx_func
	signal rx_enable : std_logic := '1';
	signal start_samples : std_logic_vector(3 downto 0) := "1100";	--How many correct samples should give a start bit
	signal line_samples : std_logic_vector(3 downto 0) := "0100";	--How many samples should tip the internal rx value
	signal data_ready : std_logic;
	signal parity_error : std_logic;
	signal stop_bit_error : std_logic;


begin

	--unit under test
	uut0 : rx_func port map (clk, reset, rx_enable, txrx, word_width, full_cycle, use_parity_bit, parity_type, stop_bits, idle_line_lvl, start_samples, line_samples, rx_data, data_ready, parity_error, stop_bit_error);

	uut1 : tx_func port map (clk, reset, tx_data, new_data, word_width, full_cycle, use_parity_bit, parity_type, stop_bits, idle_line_lvl, txrx, sending);
	
	
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
		wait for 12 ns;
		new_data <= '1';
		wait for 2 ns;
		new_data <= '0';
		wait for 704 ns;
		tx_data <= "01001101";
		new_data <= '1';
		wait for 2 ns;
		new_data <= '0';
		wait;
	end process;


end behaviour;