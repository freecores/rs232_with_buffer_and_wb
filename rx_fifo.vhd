library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity rx_fifo is
	generic(fifo_entries_pow2 : integer := 3);
	port(	clk, reset		: in std_logic;

			read_rx_data	: in  std_logic;
			rx_data 		: out std_logic_vector(7 downto 0);
			rx_fifo_full 	: out std_logic;
			rx_fifo_empty 	: out std_logic;
			rx_fifo_entries_free : out std_logic_vector(7 downto 0);

			rx_func_data		: in std_logic_vector(7 downto 0);
			rx_func_data_ready 	: in std_logic);
end entity rx_fifo;

architecture behaviour of rx_fifo is
	type ram_type is array ((2**fifo_entries_pow2)-1 downto 0) of std_logic_vector(7 downto 0);
	signal rx_ram : ram_type;
	constant max_fifo_entries : std_logic_vector(fifo_entries_pow2 downto 0) := conv_std_logic_vector(2**fifo_entries_pow2, fifo_entries_pow2+1); --(fifo_entries_pow2=>'1' ,others => '0');
	signal rx_entries_back : std_logic_vector(fifo_entries_pow2 downto 0) := max_fifo_entries ;
	signal rx_in_addr, rx_out_addr : std_logic_vector(fifo_entries_pow2-1 downto 0) := (others => '0');
	
begin
	rx_fifo_control : process(clk, reset)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				rx_in_addr <= (others => '0');
				rx_out_addr <= (others => '0');
				rx_entries_back <= max_fifo_entries;
			else
				--Adda data to FIFO
				if rx_func_data_ready = '1' and rx_entries_back /= conv_std_logic_vector(0, fifo_entries_pow2+1) then
					rx_ram(conv_integer(unsigned(rx_in_addr))) <= rx_func_data;
					rx_in_addr <= rx_in_addr + 1;
				else
					rx_in_addr <= rx_in_addr;
				end if;
				
				--Read data from FIFO
				if read_rx_data = '1' and rx_entries_back /= max_fifo_entries then
					rx_out_addr <= rx_out_addr + 1;
				else
					rx_out_addr <= rx_out_addr;
				end if;
				
				if rx_func_data_ready = '1' and rx_entries_back /= conv_std_logic_vector(0, fifo_entries_pow2+1) and not (read_rx_data = '1' and rx_entries_back /= max_fifo_entries) then
					rx_entries_back <= rx_entries_back - 1;
				elsif read_rx_data = '1' and rx_entries_back /= max_fifo_entries and not (rx_func_data_ready = '1' and rx_entries_back /= conv_std_logic_vector(0, fifo_entries_pow2+1)) then
					rx_entries_back <= rx_entries_back + 1;
				else
					rx_entries_back <= rx_entries_back;
				end if;
			end if;
			
		end if;
	end process rx_fifo_control;
	
	rx_data <= rx_ram(conv_integer(unsigned(rx_out_addr)));
	rx_fifo_entries_free <= conv_std_logic_vector(0, 7 - fifo_entries_pow2) & rx_entries_back;
	rx_fifo_empty <= '1' when rx_entries_back = max_fifo_entries else '0';
	rx_fifo_full <= '1' when rx_entries_back < conv_std_logic_vector(3, fifo_entries_pow2-1) else '0';
end architecture behaviour;	