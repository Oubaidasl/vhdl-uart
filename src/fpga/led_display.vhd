-- ========================================
-- Module 6: LED Display Controller
-- ========================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity led_display is
    Port ( 
        clk : in STD_LOGIC;
        reset : in STD_LOGIC;
        door_open : in STD_LOGIC;
        door_closed : in STD_LOGIC;
        invalid_data : in STD_LOGIC;
        led_open : out STD_LOGIC;
        led_closed : out STD_LOGIC;
        led_error : out STD_LOGIC
    );
end led_display;

architecture Behavioral of led_display is
    signal current_state : STD_LOGIC := '0'; -- 0 = closed, 1 = open
begin
    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= '0';
            led_open <= '0';
            led_closed <= '1';
            led_error <= '0';
        elsif rising_edge(clk) then
            if door_open = '1' then
                current_state <= '1';
            elsif door_closed = '1' then
                current_state <= '0';
            end if;
            
            led_open <= current_state;
            led_closed <= not current_state;
            led_error <= invalid_data;
        end if;
    end process;
end Behavioral;                                                                                               

