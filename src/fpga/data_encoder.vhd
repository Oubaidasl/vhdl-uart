-- ========================================
-- Module 2: Data Encoder
-- ========================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity data_encoder is
    Port ( 
        clk : in STD_LOGIC;
        reset : in STD_LOGIC;
        door_state : in STD_LOGIC;
        door_changed : in STD_LOGIC;
        tx_enable : out STD_LOGIC;
        tx_data : out STD_LOGIC_VECTOR(7 downto 0)
    );
end data_encoder;

architecture Behavioral of data_encoder is
    constant DOOR_OPEN_CODE : STD_LOGIC_VECTOR(7 downto 0) := "10101010";
    constant DOOR_CLOSED_CODE : STD_LOGIC_VECTOR(7 downto 0) := "01010101";
begin
    process(clk, reset)
    begin
        if reset = '1' then
            tx_enable <= '0';
            tx_data <= (others => '0');
        elsif rising_edge(clk) then
            if door_changed = '1' then
                tx_enable <= '1';
                if door_state = '1' then
                    tx_data <= DOOR_OPEN_CODE;
                else
                    tx_data <= DOOR_CLOSED_CODE;
                end if;
            else
                tx_enable <= '0';
            end if;
        end if;
    end process;
end Behavioral;
