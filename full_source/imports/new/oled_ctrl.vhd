--
-- Written by Ryan Kim, Digilent Inc.
-- Modified by Michael Mattioli
--
-- Description: Top level controller that controls the OLED display.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity oled_ctrl is
    port (  clk         : in std_logic;
            rst         : in std_logic;
            
            -- The following ports go to on-board OLED display
            oled_sdin   : out std_logic;
            oled_sclk   : out std_logic;
            oled_dc     : out std_logic;
            oled_res    : out std_logic;
            oled_vbat   : out std_logic;
            oled_vdd    : out std_logic;
            
            -- user interface ports
            start    : in std_logic;
			   ready		: out std_logic;
			   din		: in std_logic_vector(7 downto 0);
			   valid		: in std_logic;  -- '1' if din is valid
			   refresh  : in std_logic
			);
end oled_ctrl;

architecture behavioral of oled_ctrl is

    component oled_init is
        port (  clk         : in std_logic;
                rst         : in std_logic;
                en          : in std_logic;
                sdout       : out std_logic;
                oled_sclk   : out std_logic;
                oled_dc     : out std_logic;
                oled_res    : out std_logic;
                oled_vbat   : out std_logic;
                oled_vdd    : out std_logic;
                fin         : out std_logic);
    end component;

    type states is (Idle, OledInitialize, OledExample, Test1, Test2, Test3, Done);

    signal current_state : states := Idle;

    signal init_en          : std_logic := '0';
    signal init_done        : std_logic	:= '0';
    signal init_sdata       : std_logic;
    signal init_spi_clk     : std_logic;
    signal init_dc          : std_logic;

    signal example_en       : std_logic := '0';
    signal example_sdata    : std_logic;
    signal example_spi_clk  : std_logic;
    signal example_dc       : std_logic;
    signal oled_ready     : std_logic	:= '0';
	 signal oled_full     : std_logic;
    signal oled_empty     : std_logic;

	
      
begin

    Initialize: oled_init port map (clk => clk,
                                    rst => rst,
                                    en => init_en,
                                    sdout => init_sdata,
                                    oled_sclk => init_spi_clk,
                                    oled_dc => init_dc,
                                    oled_res => oled_res,
                                    oled_vbat => oled_vbat,
                                    oled_vdd =>oled_vdd,
                                    fin => init_done);

			
    Example: entity work.oled_ex(behavioral) 
                    port map ( clk => clk,
                                rst => rst,
                                en => example_en,
								ascii_in => din,
								ascii_in_val => valid,
								refresh => refresh,
                                sdout => example_sdata,
                                oled_sclk => example_spi_clk,
                                oled_dc => example_dc,
                                ready => ready,
                                full => oled_full,
                                empty => oled_empty);
								
            

								
    -- MUXes to indicate which outputs are routed out depending on which block is enabled
    oled_sdin <= init_sdata when current_state = OledInitialize else example_sdata;
    oled_sclk <= init_spi_clk when current_state = OledInitialize else example_spi_clk;
    oled_dc <= init_dc when current_state = OledInitialize else example_dc;
    -- End output MUXes

    -- MUXes that enable blocks when in the proper states
    init_en <= '1' when current_state = OledInitialize else '0';
    --example_en <= '1' when current_state = OledExample else '0';
    -- End enable MUXes

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                current_state <= Idle;
				     example_en <= '0';
            else
                case current_state is
                    when Idle =>
                        if start = '1' then 
                           current_state <= OledInitialize;
                        end if;
                    -- Go through the initialization sequence
                    when OledInitialize =>
                        if init_done = '1' then
                            current_state <= OledExample;
                        end if;
                    -- Do example and do nothing when finished
                    when OledExample =>
						      example_en <= '1';
                        if start = '0' then
                           current_state <= Idle;
                        end if; 
                    when others =>
                        current_state <= Idle;
                end case;
            end if;
        end if;
    end process;

end behavioral;
