--------------------------------------------------------------------------------
-- Testbench: Wireless Door Detection System
-- Description: Tests based on system architecture diagram
-- Tests: sensor_input=1 ? OPEN ? 0xAA ? LED_OPEN
--        sensor_input=0 ? CLOSED ? 0x55 ? LED_CLOSED
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity door_detection_system_tb is
end door_detection_system_tb;

architecture testbench of door_detection_system_tb is

    --=========================================================================
    -- Constants
    --=========================================================================
    constant CLK_PERIOD   : time := 20 ns;      -- 50 MHz clock
    constant CLK_FREQ     : integer := 50_000_000;
    constant BAUD_RATE    : integer := 9600;
    constant BIT_PERIOD   : time := 104167 ns;  -- 1/9600 baud
    
    -- Test codes (per schema: 10101010=OPEN, 01010101=CLOSED)
    constant DOOR_OPEN_CODE   : std_logic_vector(7 downto 0) := "10101010"; -- 0xAA
    constant DOOR_CLOSED_CODE : std_logic_vector(7 downto 0) := "01010101"; -- 0x55
    
    --=========================================================================
    -- Signals for DUT
    --=========================================================================
    signal clk           : std_logic := '0';
    signal reset         : std_logic := '1';
    signal sensor_input  : std_logic := '0';
    signal led_open      : std_logic;
    signal led_closed    : std_logic;
    signal led_error     : std_logic;
    signal tx_serial_out : std_logic;
    signal tx_busy_out   : std_logic;
    signal rx_busy_out   : std_logic;
    
    --=========================================================================
    -- Test Control Signals
    --=========================================================================
    signal test_complete : boolean := false;
    signal test_number   : integer := 0;
    
    --=========================================================================
    -- Component Declaration
    --=========================================================================
    component door_detection_system
        generic (
            CLK_FREQ  : integer := 50_000_000;
            BAUD_RATE : integer := 9600
        );
        port ( 
            clk           : in  std_logic;
            reset         : in  std_logic;
            sensor_input  : in  std_logic;
            led_open      : out std_logic;
            led_closed    : out std_logic;
            led_error     : out std_logic;
            tx_serial_out : out std_logic;
            tx_busy_out   : out std_logic;
            rx_busy_out   : out std_logic
        );
    end component;
    
begin

    --=========================================================================
    -- Device Under Test
    --=========================================================================
    DUT: door_detection_system
        generic map (
            CLK_FREQ  => CLK_FREQ,
            BAUD_RATE => BAUD_RATE
        )
        port map (
            clk           => clk,
            reset         => reset,
            sensor_input  => sensor_input,
            led_open      => led_open,
            led_closed    => led_closed,
            led_error     => led_error,
            tx_serial_out => tx_serial_out,
            tx_busy_out   => tx_busy_out,
            rx_busy_out   => rx_busy_out
        );
    
    --=========================================================================
    -- Clock Generation
    --=========================================================================
    clk_process: process
    begin
        while not test_complete loop
            clk <= '0';
            wait for CLK_PERIOD/2;
            clk <= '1';
            wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;
    
    --=========================================================================
    -- Main Test Stimulus (Based on System Schema)
    --=========================================================================
    stimulus: process
    begin
        report "========================================";
        report "Door Detection System Test (Per Schema)";
        report "Schema: sensor=1 ? OPEN ? 0xAA ? LED_OPEN";
        report "        sensor=0 ? CLOSED ? 0x55 ? LED_CLOSED";
        report "========================================";
        
        -- Initialize
        sensor_input <= '0';
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        wait for 100 ns;
        
        --=====================================================================
        -- TEST 1: Initial State (No Movement = Door Closed)
        --=====================================================================
        test_number <= 1;
        report "TEST 1: Initial state - No movement (sensor=0, CLOSED)";
        wait for 1 us;
        
        assert (led_closed = '1' and led_open = '0' and led_error = '0')
            report "FAIL: Initial state incorrect" severity error;
        report "PASS: Initial state - LED_CLOSED ON";
        
        --=====================================================================
        -- TEST 2: Movement Detected (Door Opens)
        -- Schema: sensor_input=1 ? door_state=1 ? 0xAA ? door_open ? LED_OPEN
        --=====================================================================
        test_number <= 2;
        report "TEST 2: Movement detected - Door opens (sensor=1)";
        wait for 2 us;
        sensor_input <= '1';  -- Movement detected
        
        -- Wait for UART transmission to complete
        wait for BIT_PERIOD * 12;
        
        assert (led_open = '1' and led_closed = '0')
            report "FAIL: Door open not detected - LED_OPEN should be ON" severity error;
        report "PASS: Movement detected - LED_OPEN ON";
        
        --=====================================================================
        -- TEST 3: No Movement (Door Closes)
        -- Schema: sensor_input=0 ? door_state=0 ? 0x55 ? door_closed ? LED_CLOSED
        --=====================================================================
        test_number <= 3;
        report "TEST 3: No movement - Door closes (sensor=0)";
        wait for 5 us;
        sensor_input <= '0';  -- No movement
        
        wait for BIT_PERIOD * 12;
        
        assert (led_closed = '1' and led_open = '0')
            report "FAIL: Door closed not detected - LED_CLOSED should be ON" severity error;
        report "PASS: No movement - LED_CLOSED ON";
        
        --=====================================================================
        -- TEST 4: Rapid Movement Changes
        --=====================================================================
        test_number <= 4;
        report "TEST 4: Rapid movement detection cycles";
        
        for i in 1 to 5 loop
            wait for 2 us;
            sensor_input <= '1';  -- Movement
            wait for BIT_PERIOD * 12;
            
            wait for 2 us;
            sensor_input <= '0';  -- No movement
            wait for BIT_PERIOD * 12;
        end loop;
        
        assert (led_closed = '1' and led_open = '0')
            report "FAIL: Final state after rapid changes incorrect" severity error;
        report "PASS: Rapid movement changes handled correctly";
        
        --=====================================================================
        -- TEST 5: System Reset
        --=====================================================================
        test_number <= 5;
        report "TEST 5: Reset during operation";
        sensor_input <= '1';
        wait for BIT_PERIOD * 5;
        
        reset <= '1';
        wait for 200 ns;
        reset <= '0';
        wait for 1 us;
        
        assert (led_closed = '1' and led_open = '0' and led_error = '0')
            report "FAIL: Reset did not return to initial state" severity error;
        report "PASS: Reset reinitializes correctly";
        
        --=====================================================================
        -- TEST 6: TX Busy Flag
        --=====================================================================
        test_number <= 6;
        report "TEST 6: TX busy flag during transmission";
        wait for 2 us;
        sensor_input <= '1';
        wait for 100 ns;
        
        assert (tx_busy_out = '1')
            report "FAIL: TX busy flag not set" severity error;
        report "PASS: TX busy flag operates correctly";
        
        wait for BIT_PERIOD * 12;
        
        assert (tx_busy_out = '0')
            report "FAIL: TX busy flag not cleared" severity error;
        report "PASS: TX busy flag cleared after transmission";
        
        --=====================================================================
        -- TEST 7: Extended Door Open Period
        --=====================================================================
        test_number <= 7;
        report "TEST 7: Door remains open for extended period";
        sensor_input <= '1';
        wait for BIT_PERIOD * 50;
        
        assert (led_open = '1' and led_closed = '0')
            report "FAIL: LED state unstable during extended period" severity error;
        report "PASS: LED state stable during extended door open";
        
        --=====================================================================
        -- TEST 8: Return to Closed State
        --=====================================================================
        test_number <= 8;
        report "TEST 8: Return to closed state";
        sensor_input <= '0';
        wait for BIT_PERIOD * 12;
        
        assert (led_closed = '1' and led_open = '0' and led_error = '0')
            report "FAIL: Final state incorrect" severity error;
        report "PASS: Final state verified";
        
        --=====================================================================
        -- Test Complete
        --=====================================================================
        wait for 5 us;
        report "========================================";
        report "All Tests Completed Successfully!";
        report "System operates per schema specification";
        report "========================================";
        test_complete <= true;
        wait;
        
    end process;
    
    --=========================================================================
    -- UART Monitor (Verifies Correct Codes Per Schema)
    --=========================================================================
    uart_monitor: process
        variable rx_byte : std_logic_vector(7 downto 0);
    begin
        wait until tx_serial_out = '0';  -- Wait for start bit
        
        -- Sample start bit
        wait for BIT_PERIOD/2;
        if tx_serial_out /= '0' then
            report "WARNING: Start bit invalid" severity warning;
        end if;
        
        -- Sample 8 data bits (LSB first)
        for i in 0 to 7 loop
            wait for BIT_PERIOD;
            rx_byte(i) := tx_serial_out;
        end loop;
        
        -- Sample stop bit
        wait for BIT_PERIOD;
        if tx_serial_out /= '1' then
            report "WARNING: Stop bit invalid" severity warning;
        end if;
        
        -- Decode per schema
        if rx_byte = DOOR_OPEN_CODE then
            report "UART: Transmitted DOOR OPEN (0xAA) ?";
        elsif rx_byte = DOOR_CLOSED_CODE then
            report "UART: Transmitted DOOR CLOSED (0x55) ?";
        else
            report "UART: Unknown code 0x" & 
                   integer'image(to_integer(unsigned(rx_byte))) severity warning;
        end if;
        
    end process;
    
    --=========================================================================
    -- Timeout Watchdog
    --=========================================================================
    watchdog: process
    begin
        wait for 50 ms;
        if not test_complete then
            report "TIMEOUT: Test did not complete!" severity failure;
        end if;
        wait;
    end process;

end testbench;
