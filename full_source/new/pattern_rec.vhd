----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/21/2019 06:25:23 PM
-- Design Name: 
-- Module Name: oled_ctrl - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pattern_rec is
  Port 
  (
    clk: in std_logic;
    reset: in std_logic; --center button
    start: in std_logic; --up button
    adv: in std_logic;
    prev: in std_logic;
    --onboard OLED display
    oled_sdin   : out std_logic;
    oled_sclk   : out std_logic;
    oled_dc     : out std_logic;
    oled_res    : out std_logic;
    oled_vbat   : out std_logic;
    oled_vdd    : out std_logic
  );
end pattern_rec;


architecture Behavioral of pattern_rec is
type ram_type is array(0 to 20) of integer;
signal ram: ram_type;

type state_type is (s0, s1, s2, s3,done, fail, displaywrong, displaycorrect, dxfer, dxfer2, displayed, penultimate, final, left, right);
signal state: state_type;

type oled_row is array(0 to 15) of std_logic_vector(7 downto 0);
type oled_page is array (0 to 3) of oled_row;
        
signal oled_screen : oled_page := ( 
                                         (x"40", x"41", x"42",  x"43", x"44", x"45", x"46",x"47", x"48", x"49", x"4A", x"4B", x"4C", x"4D", x"4E", x"4F"),
                                         (x"40", x"41", x"42",  x"43", x"44", x"45", x"46",x"47", x"48", x"49", x"4A", x"4B", x"4C", x"4D", x"4E", x"4F"),
                                         (x"40", x"41", x"42",  x"43", x"44", x"45", x"46",x"47", x"48", x"49", x"4A", x"4B", x"4C", x"4D", x"4E", x"4F"),
                                         (x"40", x"41", x"42",  x"43", x"44", x"45", x"46",x"47", x"48", x"49", x"4A", x"4B", x"4C", x"4D", x"4E", x"4F")
                                         );
signal go, ready, oled_ready, valid, refresh, idle, rfs_done, rfs_start: std_logic;
signal din: std_logic_vector(7 downto 0);
signal req, res, savedres: std_logic_vector(31 downto 0); 

begin
    oled: entity work.oled_ctrl(behavioral)
    port map (  clk =>clk,
                rst => reset,
                oled_sdin => oled_sdin,
                oled_sclk => oled_sclk,
                oled_dc => oled_dc,
                oled_res => oled_res,
                oled_vbat => oled_vbat,
                oled_vdd => oled_vdd,
                start => go,
                ready => oled_ready,
                din => din,
                valid => valid,
                refresh => refresh
              );
    rfs: entity work.read_from_string(behav)
    port map( ap_clk => clk,
              ap_rst => reset,
              ap_start=> rfs_start,
              ap_done => rfs_done,
              ap_idle=> idle,
              ap_ready => ready,
              req => req,
              ap_return=>res);
    process(clk)
    variable index : integer:= 0;
    variable row, position, temp: integer := 0;
    variable Z: integer range 0 to 24 := 0;
    begin
        if(reset = '1') then
            state <= s3;
            go <= '0';
            valid <= '0';
            req <= x"00000000";
        else
            case state is
                when s0=>
                    if(start = '1' and rfs_done ='1') then
                        state <= s1;
                        index := 0;
                        req <= std_logic_vector(to_unsigned(index, req'length));
                        go <= '1';
                    end if;
                when s2=>
                    if(index = 21) then
                        index := 0;
                        state <= done;
                        rfs_start <= '0';
                    else
                        if (ready = '1') then
                            ram(index) <= to_integer(unsigned(savedres));
                            index := index+1;
                            req <= std_logic_vector(to_unsigned(index, req'length));
                        end if;
                    end if;
                when s1=>
                    if(ready ='1') then
                        savedres <= res;
                        state <= s2;
                    end if;
                when s3=>
                    rfs_start <= '1';
                    state <= s0;
                when done=>
                    if(ram(0) = 256) then
                        state <= displaywrong;
                    else
                        state <= displaycorrect;
                    end if;
                when displaycorrect =>
                    if(Z <= 23 and row < 4) then
                        if(oled_ready = '1') then  --possible error
                            case(position) is
                                when 0=>
                                    if(Z > 20) then
                                        oled_screen(row)(position) <= x"20"; --' '
                                        position := position + 1;
                                    else
                                        oled_screen(row)(position) <= x"50"; --'P'
                                        position := position + 1;
                                    end if;
                                when 1=>
                                    if(Z > 20) then
                                        oled_screen(row)(position) <= x"20"; --' '
                                        position := position + 1;
                                    else
                                        temp := Z + 48; --pattern index
                                        oled_screen(row)(position) <= std_logic_vector(to_unsigned(temp, 8));
                                        position := position + 1;
                                    end if;
                                when 2=>
                                    if( Z > 20) then
                                        oled_screen(row)(position) <= x"20"; --' '
                                        position := position + 1;
                                    else
                                        oled_screen(row)(position) <= x"3A"; --':'
                                        position := position + 1;
                                    end if;
                                when 3=>
                                    if(Z > 20) then
                                        oled_screen(row)(position) <= x"20"; --' '
                                        position := position + 1;
                                    else
                                    oled_screen(row)(position) <= x"20"; --' '
                                    position := position + 1;
                                    end if;
                                when 4=>
                                    if (Z> 20) then
                                        oled_screen(row)(position) <= x"20"; --' '
                                        position := position + 1;
                                    else
                                        temp := (ram(Z) / 100) + 48; --hundreds
                                        oled_screen(row)(position) <= std_logic_vector(to_unsigned(temp, 8));
                                        position := position + 1;
                                    end if;
                                when 5=>
                                    if ( Z > 20) then
                                        oled_screen(row)(position) <= x"20"; --' '
                                        position := position + 1;
                                    else
                                        temp := ((ram(Z) mod 100 ) / 10) + 48; -- tens
                                        oled_screen(row)(position) <= std_logic_vector(to_unsigned(temp, 8));
                                        position := position + 1;
                                    end if;
                                when 6=>
                                    if(Z > 20) then
                                        oled_screen(row)(position) <= x"20"; --' '
                                        position := position + 1;
                                    else
                                        temp := (ram(Z) mod 10 ) +48; --ones
                                        oled_screen(row)(position) <= std_logic_vector(to_unsigned(temp, 8));
                                        position := position + 1;
                                    end if;
                                when 7=>
                                    oled_screen(row)(position) <= x"20"; --' '
                                    position := position + 1;
                                    Z := Z + 1;
                                when 8=>
                                    if(Z > 20) then
                                        oled_screen(row)(position) <= x"20"; --' '
                                        position := position + 1;
                                    else
                                        oled_screen(row)(position) <= x"50"; --'P'
                                        position := position + 1;
                                    end if;
                                when 9=>
                                    if(Z > 20) then
                                        oled_screen(row)(position) <= x"20"; --' '
                                        position := position + 1;
                                    else
                                        temp := Z + 48; --pattern index
                                        oled_screen(row)(position) <= std_logic_vector(to_unsigned(temp, 8));
                                        position := position + 1;
                                    end if;
                                when 10=>
                                    if(Z >20) then
                                        oled_screen(row)(position) <= x"20"; --' '
                                        position := position + 1;
                                    else
                                        oled_screen(row)(position) <= x"3A"; --':'
                                        position := position + 1;
                                    end if;
                                when 11=>
                                    if(Z >20) then
                                        oled_screen(row)(position) <= x"20"; --' '
                                        position := position + 1;
                                    else
                                        oled_screen(row)(position) <= x"20"; --' '
                                        position := position + 1;
                                    end if;
                                when 12=>
                                    if(Z >20) then
                                        oled_screen(row)(position) <= x"20"; --' '
                                        position := position + 1;
                                    else
                                        temp := (ram(Z) / 100) + 48; --hundreds
                                        oled_screen(row)(position) <= std_logic_vector(to_unsigned(temp, 8));
                                        position := position + 1;
                                    end if;
                                when 13=>
                                    if(Z > 20) then
                                        oled_screen(row)(position) <= x"20"; --' '
                                        position := position + 1;
                                    else
                                        temp := ((ram(Z) mod 100 ) / 10) + 48; -- tens
                                        oled_screen(row)(position) <= std_logic_vector(to_unsigned(temp, 8));
                                        position := position + 1;
                                    end if;
                                when 14=>
                                    if(Z >20) then
                                        oled_screen(row)(position) <= x"20"; --' '
                                        position := position + 1;
                                    else
                                        temp := (ram(Z) mod 10 ) +48; --ones
                                        oled_screen(row)(position) <= std_logic_vector(to_unsigned(temp, 8));
                                        position := position + 1;
                                    end if;
                                when 15=>
                                    oled_screen(row)(position) <= x"20"; --' '
                                    position := position + 1;
                                    Z := Z + 1;
                                    if(position >= 15) then
                                        if(row = 3) then
                                            state <= dxfer;
											position := 0;
											row := 0;
										else
											row := row + 1;
											position := 0;
                                        end if;
                                    end if;
                                when others=>
                                    null;
                            end case;
                        end if;
                    end if;
				when dxfer =>
					if (oled_ready = '1') then
						--din <= oled_screen(row)(position);
						--valid <= '1';
						if(position = 15) then
							if(row = 3) then
								state <= displayed;
								din <= oled_screen(row)(position);
								valid <= '1';
							else 
								din <= oled_screen(row)(position);
								valid <= '1';
								row := row + 1;
								position := 0;
								state <= dxfer2;
							end if;
						else 
							din <= oled_screen(row)(position);
							valid <= '1';
							position := position + 1;
							state <= dxfer2;
						end if;
					end if;
			    when dxfer2 =>
			         if(oled_ready = '1') then
			             state <= dxfer;
			         else
			             valid <= '0';
			         end if;
				when displayed =>
				    if (oled_ready = '1') then 
				        refresh <= '1';
                        state <= penultimate; 
                    end if;
					valid <= '0'; --might need to change
                when final =>
					valid<= '0';
					refresh <= '0';
                    if(prev = '1' and Z > 7) then
                        state <= left;
                    elsif (adv = '1' and Z  < 24) then
                        state <= right;
                    end if;
                when penultimate =>
                        state<= final;
                when left =>
                    if(prev ='0') then
                        Z:= Z - 8;
                        state <= displaycorrect;
                    end if;
                when right =>
                    if(adv = '0') then
                        state <= displaycorrect;
                    end if;
                when others=>
                    null;
            end case;
        end if;
    --if(refresh ='1') then refresh <= '0'; end if;
    end process;
    

end Behavioral;
