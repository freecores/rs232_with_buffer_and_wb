library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity fifo_rx_tb is
end fifo_rx_tb;

architecture behaviour of fifo_rx_tb is

	component rx_fifo is
	generic(fifo_entries_pow2 : integer := 3);
	port(	clk, reset		: in std_logic;
			read_rx_data	: in  std_logic;
			rx_data 		: out std_logic_vector(7 downto 0);
			rx_fifo_full 	: out std_logic;
			rx_fifo_empty 	: out std_logic;
			rx_fifo_entries_free : out std_logic_vector(7 downto 0);
			rx_func_data		: in std_logic_vector(7 downto 0);
			rx_func_data_ready 	: in std_logic);
	end component;
	
	component rx_func is
	port(	clk, reset, rx_enable : in std_logic;
			rx : in std_logic;
			word_width : in std_logic_vector(3 downto 0);
			period : in std_logic_vector(15 downto 0);
			use_parity_bit, parity_type : in std_logic;
			stop_bits : in std_logic_vector(1 downto 0);
			idle_line_lvl : in std_logic;
			start_samples : in std_logic_vector(3 downto 0);	--How many correct samples should give a start bit
			line_samples : in std_logic_vector(3 downto 0);		--How many samples should tip the internal rx value
			data 		: out std_logic_vector(7 downto 0);
			data_ready 	: out std_logic;
			parity_error :	out std_logic;
			stop_bit_error : out std_logic);
	end component;

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

	constant clk_period : time := 2 ns;	-- 50MHz

	signal clk : std_logic := '0';
	signal reset : std_logic := '0';	
	
	--General signals for setup of rx_func and tx_func
	signal word_width : std_logic_vector(3 downto 0) := "1000";
	signal period : std_logic_vector(15 downto 0) := "0000000000100000";
	signal use_parity_bit : std_logic := '0';
	signal parity_type : std_logic := '0';
	signal stop_bits : std_logic_vector(1 downto 0) := "01";
	signal idle_line_lvl : std_logic := '1';
	
	signal txrx : std_logic;
	
	--rx_fifo signals
	signal rx_fifo_full, rx_fifo_empty : std_logic;
	signal rx_fifo_entries_free : std_logic_vector(7 downto 0);
	signal rx_data : std_logic_vector(7 downto 0) := "00000000";	--fifo source data
	signal read_rx_data : std_logic := '0';
	
	--rx_func
	signal rx_enable : std_logic := '1';
	signal start_samples : std_logic_vector(3 downto 0) := "0110";
	signal line_samples : std_logic_vector(3 downto 0) := "0100";
	signal parity_error : std_logic;
	signal stop_bit_error : std_logic;
	
	--signals between rx_func and rx_fifo
	signal rx_func_data : std_logic_vector(7 downto 0);
	signal rx_func_data_ready : std_logic;
	
	--tx_fifo signals
	signal tx_fifo_full, tx_fifo_empty : std_logic;
	signal tx_fifo_entries_free : std_logic_vector(7 downto 0);
	signal tx_data : std_logic_vector(7 downto 0);
	signal write_tx_data : std_logic := '0';

	--signals between tx_fifo and tx_func
	signal tx_func_data : std_logic_vector(7 downto 0);	--bus between fifo and tx_func, fifo being source, tx_fun being sink
	signal tx_func_apply_data : std_logic;
	signal tx_func_sending : std_logic;

begin

	--Device under test
	uut0 : rx_fifo generic map (3) port map (clk, reset, read_rx_data, rx_data, rx_fifo_full, rx_fifo_empty, rx_fifo_entries_free, rx_func_data, rx_func_data_ready);

	--only use to exercise rx_fifo
	uut1 : rx_func port map (clk, reset, rx_enable, txrx, word_width, period, use_parity_bit, parity_type, stop_bits, idle_line_lvl, start_samples, line_samples, rx_func_data, rx_func_data_ready, parity_error, stop_bit_error);

	--only use to exercise rx_fifo
	uut2 : tx_fifo generic map (3) port map (clk, reset, write_tx_data, tx_data, tx_fifo_full, tx_fifo_empty, tx_fifo_entries_free, tx_func_data, tx_func_apply_data, tx_func_sending);

	--only use to exercise rx_fifo
	uut3 : tx_func port map (clk, reset, tx_func_data, tx_func_apply_data, word_width, period, use_parity_bit, parity_type, stop_bits, idle_line_lvl, txrx, tx_func_sending);

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
		tx_data <= "00000001";
		write_tx_data <= '1';
		wait for 2 ns;
		write_tx_data <= '0';
		wait for 2 ns;
		tx_data <= "00000010";
		write_tx_data <= '1';
		wait for 2 ns;
		tx_data <= "00000011";
		wait for 2 ns;
		tx_data <= "00000100";
		wait for 2 ns;
		tx_data <= "00000101";
		wait for 2 ns;
		tx_data <= "00000110";
		wait for 2 ns;
		tx_data <= "00000111";
		wait for 2 ns;
		tx_data <= "00001000";
		wait for 2 ns;
		tx_data <= "00001001";
		wait for 2 ns;
		write_tx_data <= '0';
		wait for 2000 ns;
		read_rx_data <= '1';
		wait for 2 ns;
		read_rx_data <= '0';
		wait for 2 ns;
		read_rx_data <= '1';
		wait for 2 ns;
		read_rx_data <= '0';
		wait for 2 ns;
		read_rx_data <= '1';
		wait for 2 ns;
		read_rx_data <= '0';
		wait for 2 ns;
		read_rx_data <= '1';
		wait for 2 ns;
		read_rx_data <= '0';
		wait;
	end process;
	
end behaviour;