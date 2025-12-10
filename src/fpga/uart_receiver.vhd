--------------------------------------------------------------------------------
-- Project: Wireless Door Detection System
-- Module:  UART Receiver (with Start/Stop bit detection)
-- Description: UART-compliant receiver with frame validation
-- Author:  Door Detection Team
-- Date:    2025-11-26
--------------------------------------------------------------------------------
-- UART Frame: [START(0)] [8 DATA BITS] [STOP(1)]
-- Configuration: 8-N-1
-- Features: Start bit detection, Stop bit validation, Frame error detection
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE. NUMERIC_STD.ALL;

entity uart_receiver is
    generic (
        CLK_FREQ  : integer := 50_000_000;      -- System clock (Hz)
        BAUD_RATE : integer := 9600             -- Baud rate (bps)
    );
    port (
        -- Clock and Reset
        clk       : in  std_logic;
        rst       : in  std_logic;
        
        -- UART Serial Input
        rx_serial : in  std_logic;              -- UART RX line
        
        -- Data Output
        rx_data   : out std_logic_vector(7 downto 0);
        
        -- Status Signals
        rx_valid  : out std_logic;              -- Data valid pulse
        rx_error  : out std_logic;              -- Frame error
        rx_busy   : out std_logic
    );
end entity uart_receiver;

architecture rtl of uart_receiver is
    
    --=========================================================================
    -- Constants
    --=========================================================================
    constant CLOCKS_PER_BIT : integer := CLK_FREQ / BAUD_RATE;
    constant HALF_BIT       : integer := CLOCKS_PER_BIT / 2;
    
    --=========================================================================
    -- State Machine
    --=========================================================================
    type state_type is (
        IDLE,           -- Wait for start bit (falling edge)
        START_BIT,      -- Verify start bit in middle
        DATA_BITS,      -- Receive 8 data bits
        STOP_BIT,       -- Verify stop bit
        CLEANUP         -- Output data, check errors
    );
    
    signal state : state_type := IDLE;
    
    --=========================================================================
    -- Signals
    --=========================================================================
    -- Input synchronizer (prevent metastability)
    signal rx_sync      : std_logic_vector(1 downto 0) := "11";
    
    signal clock_counter : integer range 0 to CLOCKS_PER_BIT-1 := 0;
    signal bit_counter   : integer range 0 to 7 := 0;
    signal shift_reg     : std_logic_vector(7 downto 0) := (others => '0');
    
    signal rx_data_reg   : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_valid_reg  : std_logic := '0';
    signal rx_error_reg  : std_logic := '0';
    signal rx_busy_reg   : std_logic := '0';
    
begin

    --=========================================================================
    -- Input Synchronizer (2-stage flip-flop)
    --=========================================================================
    process(clk, rst)
    begin
        if rst = '1' then
            rx_sync <= "11";  -- Idle HIGH
        elsif rising_edge(clk) then
            rx_sync(0) <= rx_serial;
            rx_sync(1) <= rx_sync(0);
        end if;
    end process;
    
    --=========================================================================
    -- UART Receiver State Machine
    --=========================================================================
    process(clk, rst)
    begin
        if rst = '1' then
            state         <= IDLE;
            clock_counter <= 0;
            bit_counter   <= 0;
            shift_reg     <= (others => '0');
            rx_data_reg   <= (others => '0');
            rx_valid_reg  <= '0';
            rx_error_reg  <= '0';
            rx_busy_reg   <= '0';
            
        elsif rising_edge(clk) then
            -- Defaults
            rx_valid_reg <= '0';
            rx_error_reg <= '0';
            
            case state is
                
                --=============================================================
                -- IDLE State: Wait for START bit (HIGH ? LOW transition)
                --=============================================================
                when IDLE =>
                    rx_busy_reg   <= '0';
                    clock_counter <= 0;
                    bit_counter   <= 0;
                    
                    -- Detect falling edge (start bit)
                    if rx_sync(1) = '0' then  -- Line went LOW
                        rx_busy_reg <= '1';
                        state       <= START_BIT;
                    end if;
                
                --=============================================================
                -- START_BIT State: Verify START bit in middle
                --=============================================================
                when START_BIT =>
                    -- Wait until middle of start bit
                    if clock_counter < HALF_BIT - 1 then
                        clock_counter <= clock_counter + 1;
                    else
                        clock_counter <= 0;
                        
                        -- Check if still LOW (valid start bit)
                        if rx_sync(1) = '0' then
                            state <= DATA_BITS;  -- Valid, proceed
                        else
                            state <= IDLE;  -- False start, abort
                        end if;
                    end if;
                
                --=============================================================
                -- DATA_BITS State: Receive 8 data bits (LSB first)
                --=============================================================
                when DATA_BITS =>
                    -- Sample in middle of each bit period
                    if clock_counter < CLOCKS_PER_BIT - 1 then
                        clock_counter <= clock_counter + 1;
                    else
                        clock_counter <= 0;
                        
                        -- Sample and shift in data bit
                        shift_reg <= rx_sync(1) & shift_reg(7 downto 1);
                        
                        if bit_counter < 7 then
                            bit_counter <= bit_counter + 1;
                        else
                            bit_counter <= 0;
                            state       <= STOP_BIT;
                        end if;
                    end if;
                
                --=============================================================
                -- STOP_BIT State: Verify STOP bit (should be 1)
                --=============================================================
                when STOP_BIT =>
                    -- Sample in middle of stop bit
                    if clock_counter < CLOCKS_PER_BIT - 1 then
                        clock_counter <= clock_counter + 1;
                    else
                        clock_counter <= 0;
                        
                        -- Check stop bit
                        if rx_sync(1) = '1' then
                            -- Valid stop bit - frame OK
                            rx_data_reg  <= shift_reg;
                            rx_valid_reg <= '1';
                        else
                            -- Invalid stop bit - frame error
                            rx_error_reg <= '1';
                        end if;
                        
                        state <= CLEANUP;
                    end if;
                
                --=============================================================
                -- CLEANUP State: Reset and return to IDLE
                --=============================================================
                when CLEANUP =>
                    rx_busy_reg <= '0';
                    state       <= IDLE;
                    
            end case;
        end if;
    end process;
    
    --=========================================================================
    -- Output Assignments
    --=========================================================================
    rx_data  <= rx_data_reg;
    rx_valid <= rx_valid_reg;
    rx_error <= rx_error_reg;
    rx_busy  <= rx_busy_reg;
    
end architecture rtl;
