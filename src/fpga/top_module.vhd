--------------------------------------------------------------------------------
-- Project: Wireless Door Detection System
-- Module:  Top Level (Complete System)
-- Description: Integrates all subsystems with UART communication
-- Date: 2025-11-26
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity door_detection_system is
    generic (
        CLK_FREQ  : integer := 50_000_000;      -- 50 MHz system clock
        BAUD_RATE : integer := 9600             -- UART baud rate
    );
    port ( 
        -- System Inputs
        clk          : in  STD_LOGIC;
        reset        : in  STD_LOGIC;
        
        -- Sensor Input
        sensor_input : in  STD_LOGIC;
        
        -- LED Outputs
        led_open     : out STD_LOGIC;           -- Red: Door open
        led_closed   : out STD_LOGIC;           -- Green: Door closed
        led_error    : out STD_LOGIC;           -- Yellow: Error/Invalid data
        
        -- Debug/Status Outputs (optional, can remove if not needed)
        tx_serial_out: out STD_LOGIC;           -- For hardware debugging
        tx_busy_out  : out STD_LOGIC;           -- TX status
        rx_busy_out  : out STD_LOGIC            -- RX status
    );
end door_detection_system;

architecture Structural of door_detection_system is

    ---------------------------------------------------------------------------
    -- Internal Signals - Transmission Path
    ---------------------------------------------------------------------------
    signal door_state       : STD_LOGIC;
    signal door_changed     : STD_LOGIC;
    signal tx_enable        : STD_LOGIC;
    signal tx_data          : STD_LOGIC_VECTOR(7 downto 0);
    signal tx_busy          : STD_LOGIC;
    signal tx_done          : STD_LOGIC;
    signal tx_serial        : STD_LOGIC;
    
    ---------------------------------------------------------------------------
    -- Internal Signals - Reception Path
    ---------------------------------------------------------------------------
    signal rx_data          : STD_LOGIC_VECTOR(7 downto 0);
    signal rx_valid         : STD_LOGIC;
    signal rx_error         : STD_LOGIC;
    signal rx_busy          : STD_LOGIC;
    
    ---------------------------------------------------------------------------
    -- Internal Signals - Decoded Data
    ---------------------------------------------------------------------------
    signal door_open_sig    : STD_LOGIC;
    signal door_closed_sig  : STD_LOGIC;
    signal invalid_data_sig : STD_LOGIC;

    ---------------------------------------------------------------------------
    -- Component Declarations
    ---------------------------------------------------------------------------

    -- Door Sensor Interface
    component door_sensor
        port ( 
            clk          : in  STD_LOGIC;
            reset        : in  STD_LOGIC;
            sensor_input : in  STD_LOGIC;
            door_state   : out STD_LOGIC;
            door_changed : out STD_LOGIC
        );
    end component;

    -- Data Encoder
    component data_encoder
        port ( 
            clk          : in  STD_LOGIC;
            reset        : in  STD_LOGIC;
            door_state   : in  STD_LOGIC;
            door_changed : in  STD_LOGIC;
            tx_enable    : out STD_LOGIC;
            tx_data      : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

    -- UART Transmitter
    component uart_transmitter
        generic (
            CLK_FREQ  : integer;
            BAUD_RATE : integer
        );
        port ( 
            clk       : in  STD_LOGIC;
            rst       : in  STD_LOGIC;
            tx_start  : in  STD_LOGIC;
            tx_data   : in  STD_LOGIC_VECTOR(7 downto 0);
            tx_serial : out STD_LOGIC;
            tx_busy   : out STD_LOGIC;
            tx_done   : out STD_LOGIC
        );
    end component;

    -- UART Receiver
    component uart_receiver
        generic (
            CLK_FREQ  : integer;
            BAUD_RATE : integer
        );
        port (
            clk       : in  STD_LOGIC;
            rst       : in  STD_LOGIC;
            rx_serial : in  STD_LOGIC;
            rx_data   : out STD_LOGIC_VECTOR(7 downto 0);
            rx_valid  : out STD_LOGIC;
            rx_error  : out STD_LOGIC;
            rx_busy   : out STD_LOGIC
        );
    end component;

    -- Data Decoder
    component data_decoder
        port ( 
            clk          : in  STD_LOGIC;
            reset        : in  STD_LOGIC;
            rx_data      : in  STD_LOGIC_VECTOR(7 downto 0);
            rx_valid     : in  STD_LOGIC;
            door_open    : out STD_LOGIC;
            door_closed  : out STD_LOGIC;
            invalid_data : out STD_LOGIC
        );
    end component;

    -- LED Display Controller
    component led_display
        port ( 
            clk          : in  STD_LOGIC;
            reset        : in  STD_LOGIC;
            door_open    : in  STD_LOGIC;
            door_closed  : in  STD_LOGIC;
            invalid_data : in  STD_LOGIC;
            led_open     : out STD_LOGIC;
            led_closed   : out STD_LOGIC;
            led_error    : out STD_LOGIC
        );
    end component;

begin

    ---------------------------------------------------------------------------
    -- Block 1: Door Sensor Interface
    -- Debounces sensor input and detects door state changes
    ---------------------------------------------------------------------------
    sensor_inst: door_sensor
        port map (
            clk          => clk,
            reset        => reset,
            sensor_input => sensor_input,
            door_state   => door_state,
            door_changed => door_changed
        );

    ---------------------------------------------------------------------------
    -- Block 2: Data Encoder
    -- Converts door state to 8-bit code (0xAA=open, 0x55=closed)
    ---------------------------------------------------------------------------
    encoder_inst: data_encoder
        port map (
            clk          => clk,
            reset        => reset,
            door_state   => door_state,
            door_changed => door_changed,
            tx_enable    => tx_enable,
            tx_data      => tx_data
        );

    ---------------------------------------------------------------------------
    -- Block 3: UART Transmitter
    -- Sends encoded data with UART framing (START + 8 data + STOP)
    ---------------------------------------------------------------------------
    uart_tx_inst: uart_transmitter
        generic map (
            CLK_FREQ  => CLK_FREQ,
            BAUD_RATE => BAUD_RATE
        )
        port map (
            clk       => clk,
            rst       => reset,
            tx_start  => tx_enable,
            tx_data   => tx_data,
            tx_serial => tx_serial,
            tx_busy   => tx_busy,
            tx_done   => tx_done
        );

    ---------------------------------------------------------------------------
    -- Block 4: UART Receiver
    -- Receives UART frames and validates them
    -- NOTE: In simulation, connected to tx_serial (loopback)
    --       In hardware, connect to actual wireless receiver module
    ---------------------------------------------------------------------------
    uart_rx_inst: uart_receiver
        generic map (
            CLK_FREQ  => CLK_FREQ,
            BAUD_RATE => BAUD_RATE
        )
        port map (
            clk       => clk,
            rst       => reset,
            rx_serial => tx_serial,     -- Loopback for testing
            rx_data   => rx_data,
            rx_valid  => rx_valid,
            rx_error  => rx_error,
            rx_busy   => rx_busy
        );

    ---------------------------------------------------------------------------
    -- Block 5: Data Decoder
    -- Interprets received codes (0xAA=open, 0x55=closed)
    ---------------------------------------------------------------------------
    decoder_inst: data_decoder
        port map (
            clk          => clk,
            reset        => reset,
            rx_data      => rx_data,
            rx_valid     => rx_valid,
            door_open    => door_open_sig,
            door_closed  => door_closed_sig,
            invalid_data => invalid_data_sig
        );

    ---------------------------------------------------------------------------
    -- Block 6: LED Display Controller
    -- Drives LEDs based on door state
    ---------------------------------------------------------------------------
    display_inst: led_display
        port map (
            clk          => clk,
            reset        => reset,
            door_open    => door_open_sig,
            door_closed  => door_closed_sig,
            invalid_data => invalid_data_sig,
            led_open     => led_open,
            led_closed   => led_closed,
            led_error    => led_error
        );

    ---------------------------------------------------------------------------
    -- Debug Outputs (optional - for hardware testing)
    ---------------------------------------------------------------------------
    tx_serial_out <= tx_serial;     -- Monitor with oscilloscope
    tx_busy_out   <= tx_busy;       -- Check transmitter status
    rx_busy_out   <= rx_busy;       -- Check receiver status

end Structural;
