library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity fifo_tx_tb is
end fifo_tx_tb;

architecture behaviour of fifo_tx_tb is

	component tx_fifo is
	generic(fifo_entries_pow2 : integer := 8);
	port(	clk, reset		: in std_logic;
	
			write_tx_data	: in std_logic;
			tx_data 		: in std_logic_vector(7 downto 0);
			tx_fifo_full 	: out std_logic;
			tx_fifo_empty 	: out std_logic;
			tx_fifo_entries_free : out std_logic_vector(7 downto 0);
			
			tx_func_data		: out std_logic_vector(7 downto 0);
			tx_func_apply_data 	: out std_logic;
			tx_func_sending		: in std_logic);
	end component;

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
	
	
	signal tx_data : std_logic_vector(7 downto 0) := "10101010";	--fifo source data
	signal write_tx_data : std_logic := '0';
	
	
	signal tx_func_data : std_logic_vector(7 downto 0);	--bus between fifo and tx_func, fifo being source, tx_fun being sink
	signal tx_func_apply_data : std_logic;
	signal tx_func_sending : std_logic;
	
	signal word_width : std_logic_vector(3 downto 0) := "1000";
	signal full_cycle : std_logic_vector(15 downto 0) := "0000000000001000";
	signal use_parity_bit : std_logic := '0';
	signal parity_type : std_logic := '0';
	signal idle_line_lvl : std_logic := '1';
	signal stop_bits : std_logic_vector(1 downto 0) := "01";

	signal tx : std_logic;
	signal tx_fifo_full, tx_fifo_empty : std_logic;
	signal tx_fifo_entries_free : std_logic_vector(7 downto 0);

begin

	--device under test
	uut0 : tx_fifo generic map (3) port map (clk, reset, write_tx_data, tx_data, tx_fifo_full, tx_fifo_empty, tx_fifo_entries_free, tx_func_data, tx_func_apply_data, tx_func_sending);

	--only use to simulate the fifo sink
	uut1 : tx_func port map (clk, reset, tx_func_data, tx_func_apply_data, word_width, full_cycle, use_parity_bit, parity_type, stop_bits, idle_line_lvl, tx, tx_func_sending);

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
		write_tx_data <= '1';
		wait for 2 ns;
		write_tx_data <= '0';
		wait for 2 ns;
		tx_data <= "00110011";
		write_tx_data <= '1';
		wait for 2 ns;
		tx_data <= "01010101";
		wait for 2 ns;
		tx_data <= "01010111";
		wait for 2 ns;
		tx_data <= "01011101";
		wait for 2 ns;
		tx_data <= "01110101";
		wait for 2 ns;
		tx_data <= "11010101";
		wait for 2 ns;
		tx_data <= "01011111";
		wait for 2 ns;
		tx_data <= "01111101";
		wait for 2 ns;
		write_tx_data <= '0';
		wait;
	end process;
	
end behaviour;