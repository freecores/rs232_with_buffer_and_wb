library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--SVN ting tjek

entity tx_func is
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
end entity tx_func;

architecture behaviour of tx_func is
	type states is (idle, start_bit, data_bit0, data_bit1, data_bit2, data_bit3, data_bit4, data_bit5, data_bit6, data_bit7, parity_bit, stop_bit1, stop_bit2);
	signal current_state, next_state : states;
	signal baud_tick : std_logic;
	signal data_bits : std_logic_vector(7 downto 0) := "00000000";
	signal count_down : std_logic_vector(15 downto 0) := "0000000000000000";
	signal parity : std_logic;

begin

	baud_tick <= '1' when count_down = "0000000000000001" or (current_state = idle and new_data = '1') else '0';
	parity <= ((data_bits(7) xor data_bits(6)) xor (data_bits(5) xor data_bits(4))) xor ((data_bits(3) xor data_bits(2)) xor (data_bits(1) xor data_bits(0))) xor parity_type;

	period : process(clk, reset, count_down, full_cycle, current_state)
	begin
		if rising_edge(clk) then
			if reset = '1' or current_state = idle then
				count_down <= full_cycle;
			else
				if count_down = "0000000000000001" then
					count_down <= full_cycle;
				else
					count_down <= count_down - 1;
				end if;	
			end if;
		end if;
	end process period;

	output : process(current_state)
	begin
		case current_state is
			when idle =>		tx <= '0' xor idle_line_lvl;
			when start_bit =>	tx <= not idle_line_lvl;--'1' xor idle_line_lvl;
			when data_bit0 =>	tx <= data_bits(7);
			when data_bit1 =>	tx <= data_bits(6);
			when data_bit2 =>	tx <= data_bits(5);
			when data_bit3 =>	tx <= data_bits(4);
			when data_bit4 =>	tx <= data_bits(3);
			when data_bit5 =>	tx <= data_bits(2);
			when data_bit6 =>	tx <= data_bits(1);
			when data_bit7 =>	tx <= data_bits(0);
			when parity_bit =>	tx <= parity;
			when stop_bit1 =>	tx <= idle_line_lvl;--'0' xor idle_line_lvl;
			when stop_bit2 =>	tx <= idle_line_lvl;--'0' xor idle_line_lvl;
			when others =>		tx <= idle_line_lvl;--'0' xor idle_line_lvl;
		end case;
	end process output;
	sending <= '0' when current_state = idle and new_data = '0' else '1';

	next_state_decision : process(current_state, new_data, use_parity_bit, parity_type, stop_bits)
	begin
		case current_state is
			when idle =>		next_state <= start_bit;
			when start_bit =>	next_state <= data_bit0;
			when data_bit0 =>	next_state <= data_bit1;
			when data_bit1 =>	next_state <= data_bit2;
			when data_bit2 =>	next_state <= data_bit3;
			when data_bit3 =>	next_state <= data_bit4;

			when data_bit4 =>
				if word_width = "101" then
					if use_parity_bit = '1' then
						next_state <= parity_bit;
					else
						next_state <= stop_bit1;
					end if;
				else
					next_state <= data_bit5;
				end if;
			when data_bit5 =>
				if word_width = "110" then
					if use_parity_bit = '1' then
						next_state <= parity_bit;
					else
						next_state <= stop_bit1;
					end if;
				else
					next_state <= data_bit6;
				end if;
			when data_bit6 =>
				if word_width = "111" then
					if use_parity_bit = '1' then
						next_state <= parity_bit;
					else
						next_state <= stop_bit1;
					end if;
				else
					next_state <= data_bit7;
				end if;

			when data_bit7 =>
				if use_parity_bit = '1' then
					next_state <= parity_bit;
				else
					next_state <= stop_bit1;
				end if;

			when parity_bit =>
				next_state <= stop_bit1;

			when stop_bit1 =>
				if stop_bits = "10" then
					next_state <= stop_bit2;
				else
					next_state <= idle;
				end if;
 
			when stop_bit2 =>	next_state <= idle;
			when others => 		next_state <= idle;
		end case;
	end process next_state_decision;

	state_reg : process (clk, reset, next_state, baud_tick)
	begin
		if rising_edge(clk)	then
			if reset = '1' then
				current_state <= idle;
			elsif baud_tick = '1' then
				current_state <= next_state;
			end if;
			
			if current_state = idle and new_data = '1' then 
				data_bits <= data;
			end if;
		end if;
	end process state_reg;

end architecture behaviour;	