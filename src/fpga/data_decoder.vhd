-- ========================================
-- Module 5: Data Decoder
-- ========================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity data_decoder is
    Port ( 
        clk : in STD_LOGIC;
        reset : in STD_LOGIC;
        rx_data : in STD_LOGIC_VECTOR(7 downto 0);
        rx_valid : in STD_LOGIC;
        door_open : out STD_LOGIC;
        door_closed : out STD_LOGIC;
        invalid_data : out STD_LOGIC
    );
end data_decoder;

architecture Behavioral of data_decoder is
    constant DOOR_OPEN_CODE : STD_LOGIC_VECTOR(7 downto 0) := "10101010";
    constant DOOR_CLOSED_CODE : STD_LOGIC_VECTOR(7 downto 0) := "01010101";
begin
    process(clk, reset)
    begin
        if reset = '1' then
            door_open <= '0';
            door_closed <= '0';
            invalid_data <= '0';
        elsif rising_edge(clk) then
            door_open <= '0';
            door_closed <= '0';
            invalid_data <= '0';
            
            if rx_valid = '1' then
                if rx_data = DOOR_OPEN_CODE then
                    door_open <= '1';
                elsif rx_data = DOOR_CLOSED_CODE then
                    door_closed <= '1';
                else
                    invalid_data <= '1';
                end if;
            end if;
        end if;
    end process;
end Behavioral;
