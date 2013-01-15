library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity tx_fifo is
	generic(fifo_entries_pow2 : integer := 3);
	port(	clk, reset		: in std_logic;

			write_tx_data	: in std_logic;
			tx_data 		: in std_logic_vector(7 downto 0);
			tx_fifo_full 	: out std_logic;
			tx_fifo_empty 	: out std_logic;
			tx_fifo_entries_free : out std_logic_vector(7 downto 0);

			tx_func_data		: out std_logic_vector(7 downto 0);
			tx_func_apply_data 	: out std_logic;
			tx_func_sending		: in std_logic);
end entity tx_fifo;

architecture behaviour of tx_fifo is
	type ram_type is array ((2**fifo_entries_pow2)-1 downto 0) of std_logic_vector(7 downto 0);
	signal tx_ram : ram_type;
	constant max_fifo_entries : std_logic_vector(fifo_entries_pow2 downto 0) := conv_std_logic_vector(2**fifo_entries_pow2, fifo_entries_pow2+1); --(fifo_entries_pow2=>'1' ,others => '0');
	signal tx_entries_back : std_logic_vector(fifo_entries_pow2 downto 0) := max_fifo_entries ;
	signal tx_in_addr, tx_out_addr : std_logic_vector(fifo_entries_pow2-1 downto 0) := (others => '0');
	
begin
	tx_fifo_control : process(clk, reset)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				tx_in_addr <= (others => '0');
				tx_out_addr <= (others => '0');
				tx_entries_back <= max_fifo_entries;
				tx_func_apply_data <= '0';
			else
				if write_tx_data = '1' then
					tx_ram(conv_integer(unsigned(tx_in_addr))) <= tx_data;
					tx_in_addr <= tx_in_addr + 1;
				end if;
				
				if tx_entries_back /= max_fifo_entries and tx_func_sending = '0' then
					tx_out_addr <= tx_out_addr + 1;
					tx_func_apply_data <= '1';
				else
					tx_func_apply_data <= '0';
				end if;
				
				if write_tx_data = '1' and (tx_in_addr = tx_out_addr or tx_func_sending = '1') then
					tx_entries_back <= tx_entries_back - 1;
				elsif write_tx_data = '0' and tx_entries_back /= max_fifo_entries and tx_func_sending = '0' then
					tx_entries_back <= tx_entries_back + 1;
				end if;
			end if;
			tx_func_data <= tx_ram(conv_integer(unsigned(tx_out_addr)));
		end if;
	end process tx_fifo_control;
	tx_fifo_entries_free <= conv_std_logic_vector(0, 7 - fifo_entries_pow2) & tx_entries_back;
	tx_fifo_empty <= '1' when tx_in_addr = tx_out_addr else '0';
	tx_fifo_full <= '1' when tx_entries_back < conv_std_logic_vector(3, fifo_entries_pow2-1) else '0';
end architecture behaviour;	