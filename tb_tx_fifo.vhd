library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity fifo_tx_tb is
end fifo_tx_tb;

architecture behaviour of fifo_tx_tb is

	component tx_fifo is
	generic(address_width : integer := 3);
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
	
	
	signal tx_data : std_logic_vector(7 downto 0) := "11111111";	--fifo source data
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
	
	type expected_output_buf_type is array (0 to 500) of std_logic_vector(7 downto 0);
	signal expected_output : expected_output_buf_type;
	signal index_in, index_out : integer := 0;
	signal expected : std_logic_vector(7 downto 0);

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
		
		tx_data <= "00000000";
		write_tx_data <= '1';
		wait for 2 ns;
		
		tx_data <= "00000001";
		wait for 2 ns;
		
		tx_data <= "00000010";
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
		
		write_tx_data <= '0';
		
		while tx_fifo_full = '1' loop
			wait for 2 ns;
		end loop;
		wait for 2 ns;
		tx_data <= "00001000";
		write_tx_data <= '1';
		wait for 2 ns;
		write_tx_data <= '0';
		
		
		while tx_fifo_empty = '0' loop
			wait for 2 ns;
		end loop;
		wait for 2 ns;
		tx_data <= "00001001";
		write_tx_data <= '1';
		wait for 2 ns;
		write_tx_data <= '0';
		
		
		wait;
	end process;
	
	
	expected_output_buffer : process
	begin
		wait until reset = '1';
		wait until reset = '0';
		
		while true loop
			wait until write_tx_data = '1';
			wait for 0.1 ns;
			while write_tx_data = '1' loop
				expected_output(index_in) <= tx_data;
				index_in <= index_in + 1;
				wait for 2 ns;
			end loop;
		end loop; 
	end process;
	
	
	signal_intregrity_process : process
	begin
		wait until reset = '1';
		wait until reset = '0';
		
		--check each signal send
		while true loop
		
			--wait for start bit
			wait until tx = not idle_line_lvl;
			expected <= expected_output(index_out);
			index_out <= index_out + 1;
			
			wait for 3 ns;
			
			--bit 0
			wait for clk_period * conv_integer(full_cycle);	--wait a bit for next bits
			assert tx = expected(0) report "wrong data bit0" severity error;
			
			--bit 1
			wait for clk_period * conv_integer(full_cycle);	--wait a bit for next bits
			assert tx = expected(1) report "wrong data bit1" severity error;
			
			--bit 2
			wait for clk_period * conv_integer(full_cycle);	--wait a bit for next bits
			assert tx = expected(2) report "wrong data bit2" severity error;
	
			--bit 3
			wait for clk_period * conv_integer(full_cycle);	--wait a bit for next bits
			assert tx = expected(3) report "wrong data bit3" severity error;

			--bit 4
			wait for clk_period * conv_integer(full_cycle);	--wait a bit for next bits
			assert tx = expected(4) report "wrong data bit4" severity error;
			
			if word_width > "0101" then
				--bit 5
				wait for clk_period * conv_integer(full_cycle);	--wait a bit for next bits
				assert tx = expected(5) report "wrong data bit5" severity error;
				
				if word_width > "0110" then
					--bit 6
					wait for clk_period * conv_integer(full_cycle);	--wait a bit for next bits
					assert tx = expected(6) report "wrong data bit6" severity error;
				
					if word_width > "0111" then	
						--bit 7
						wait for clk_period * conv_integer(full_cycle);	--wait a bit for next bits
						assert tx = expected(7) report "wrong data bit7" severity error;
					end if;
				end if;
			end if;
			
			if use_parity_bit = '1' then
				--bit party_bit
				wait for clk_period * conv_integer(full_cycle);	--wait a bit for next bits
				assert tx = expected(1) report "wrong parity bit" severity error;
			end if;
			
			--stop bit 1
			wait for clk_period * conv_integer(full_cycle);	--wait a bit for next bits
			assert tx = idle_line_lvl report "wrong stop bit1" severity error;

			if stop_bits = "10" then
				--stop bit 2
				wait for clk_period * conv_integer(full_cycle);	--wait a bit for next bits
				assert tx = idle_line_lvl report "wrong stop bit2" severity error;
			end if;
		end loop;
	end process;
	
end behaviour;