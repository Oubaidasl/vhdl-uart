--------------------------------------------------------------------------------
-- Project: Wireless Door Detection System
-- Module:  UART Transmitter (with Start/Stop bits)
-- Description: UART-compliant transmitter with standard framing
-- Author:  Door Detection Team
-- Date:    2025-11-26
--------------------------------------------------------------------------------
-- UART Frame: [START(0)] [8 DATA BITS] [STOP(1)]
-- Configuration: 8-N-1 (8 data bits, No parity, 1 stop bit)
-- Baud Rate: Configurable via generic
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_transmitter is
    generic (
        CLK_FREQ    : integer := 50_000_000;    -- System clock (Hz)
        BAUD_RATE   : integer := 9600           -- Baud rate (bps)
    );
    port (
        -- Clock and Reset
        clk         : in  std_logic;
        rst         : in  std_logic;
        
        -- Data Interface
        tx_start    : in  std_logic;            -- Start transmission
        tx_data     : in  std_logic_vector(7 downto 0);
        
        -- UART Serial Output
        tx_serial   : out std_logic;            -- UART TX line
        
        -- Status Signals
        tx_busy     : out std_logic;
        tx_done     : out std_logic
    );
end entity uart_transmitter;

architecture rtl of uart_transmitter is
    
    --=========================================================================
    -- Constants
    --=========================================================================
    constant CLOCKS_PER_BIT : integer := CLK_FREQ / BAUD_RATE;
    
    --=========================================================================
    -- State Machine
    --=========================================================================
    type state_type is (
        IDLE,           -- Waiting for tx_start, line HIGH
        START_BIT,      -- Transmit start bit (0)
        DATA_BITS,      -- Transmit 8 data bits
        STOP_BIT,       -- Transmit stop bit (1)
        CLEANUP         -- Signal done, return to idle
    );
    
    signal state : state_type := IDLE;
    
    --=========================================================================
    -- Signals
    --=========================================================================
    signal clock_counter : integer range 0 to CLOCKS_PER_BIT-1 := 0;
    signal bit_counter   : integer range 0 to 7 := 0;
    signal shift_reg     : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_serial_reg : std_logic := '1';  -- Idle HIGH
    signal tx_busy_reg   : std_logic := '0';
    signal tx_done_reg   : std_logic := '0';
    
begin

    --=========================================================================
    -- UART Transmitter State Machine
    --=========================================================================
    process(clk, rst)
    begin
        if rst = '1' then
            state         <= IDLE;
            clock_counter <= 0;
            bit_counter   <= 0;
            shift_reg     <= (others => '0');
            tx_serial_reg <= '1';  -- UART idle state is HIGH
            tx_busy_reg   <= '0';
            tx_done_reg   <= '0';
            
        elsif rising_edge(clk) then
            -- Default
            tx_done_reg <= '0';
            
            case state is
                
                --=============================================================
                -- IDLE State: Wait for trigger, keep line HIGH
                --=============================================================
                when IDLE =>
                    tx_serial_reg <= '1';  -- UART idle = HIGH
                    tx_busy_reg   <= '0';
                    clock_counter <= 0;
                    bit_counter   <= 0;
                    
                    if tx_start = '1' then
                        shift_reg   <= tx_data;  -- Load data
                        tx_busy_reg <= '1';
                        state       <= START_BIT;
                    end if;
                
                --=============================================================
                -- START_BIT State: Send START bit (0)
                --=============================================================
                when START_BIT =>
                    tx_serial_reg <= '0';  -- START bit is always 0
                    
                    if clock_counter < CLOCKS_PER_BIT - 1 then
                        clock_counter <= clock_counter + 1;
                    else
                        clock_counter <= 0;
                        state         <= DATA_BITS;
                    end if;
                
                --=============================================================
                -- DATA_BITS State: Send 8 data bits (LSB first)
                --=============================================================
                when DATA_BITS =>
                    tx_serial_reg <= shift_reg(0);  -- Output LSB
                    
                    if clock_counter < CLOCKS_PER_BIT - 1 then
                        clock_counter <= clock_counter + 1;
                    else
                        clock_counter <= 0;
                        
                        -- Shift to next bit
                        shift_reg <= '0' & shift_reg(7 downto 1);
                        
                        if bit_counter < 7 then
                            bit_counter <= bit_counter + 1;
                        else
                            bit_counter <= 0;
                            state       <= STOP_BIT;
                        end if;
                    end if;
                
                --=============================================================
                -- STOP_BIT State: Send STOP bit (1)
                --=============================================================
                when STOP_BIT =>
                    tx_serial_reg <= '1';  -- STOP bit is always 1
                    
                    if clock_counter < CLOCKS_PER_BIT - 1 then
                        clock_counter <= clock_counter + 1;
                    else
                        clock_counter <= 0;
                        state         <= CLEANUP;
                    end if;
                
                --=============================================================
                -- CLEANUP State: Signal completion
                --=============================================================
                when CLEANUP =>
                    tx_serial_reg <= '1';  -- Return to idle HIGH
                    tx_busy_reg   <= '0';
                    tx_done_reg   <= '1';
                    state         <= IDLE;
                    
            end case;
        end if;
    end process;
    
    --=========================================================================
    -- Output Assignments
    --=========================================================================
    tx_serial <= tx_serial_reg;
    tx_busy   <= tx_busy_reg;
    tx_done   <= tx_done_reg;
    
end architecture rtl;
