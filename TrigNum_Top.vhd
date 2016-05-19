--  Author:  Hai Dong
--  Filename: TrigNum_Top.vhd 
--  Date: 5/5/04
--


library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_unsigned.all; 
  use IEEE.std_logic_arith.all;
  
--library work;
    --use work.package_host.all; 
--    use work.package_oneshot.all; 

entity TrigNum_Top is
        port
         (
           CLK                  : in std_logic;  --
           RESET_N              : in  std_logic;
           SYNC                 : in std_logic;

           ---- Ports for testing
           CountEn                  : in std_logic;

           --- To Host
           TrigNum_REG      : out std_logic_vector(15 downto 0) --- 1 indicate there a trigger ready for process
        );
end TrigNum_Top;

architecture RTL of TrigNum_Top is
    
  component TriggerNumber
  port (
    a : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    b : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    clk : IN STD_LOGIC;
    sclr : IN STD_LOGIC;
    s : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
  end component;
  
  signal Reset : std_logic;
  signal PCountEn_D : std_logic_vector(0 DOWNTO 0);
  signal PCountEn_Q : std_logic_vector(0 DOWNTO 0);
  signal CountEn_D : std_logic;
  signal CountEn_Q : std_logic;
  signal s :  STD_LOGIC_VECTOR(15 DOWNTO 0) := X"0000";
  
    
begin

  CountEn_D <= CountEn;
  PCountEn_D(0) <= CountEn_D and not CountEn_Q;
  Reset <= '1' when RESET_N = '0' or SYNC = '1' else '0';

  UTriggerNumber : TriggerNumber
  port map
   (
     a => s,
     b => PCountEn_Q,
     clk => CLK,
     sclr => Reset,
     s => s
  );

    process (CLK, RESET_N)
      begin
        if RESET_N = '0' then
	   PCountEn_Q <= (others => '0');
	   CountEn_Q <= '0';
	  
        elsif rising_edge(CLK) then
	   PCountEn_Q <= PCountEn_D;
	   CountEn_Q  <= CountEn_D;

         end if;
      end process;
      
    process (CLK, RESET_N)
      begin
        if rising_edge(CLK) then
              TrigNum_REG <= s;
         end if;
      end process;
          
end RTL;
