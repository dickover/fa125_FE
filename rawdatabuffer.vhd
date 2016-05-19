--  Author:  Hai Dong
--  Filename: RawDataBuffer.vhd 
--  Date: 5/5/04
--
--  This code does the following:
--      1) When SYNC = 0, continously stores Adc_Data to RAMB36SDP 
--      2) On rising edge OrTrig, latches RawDataTrigAdr_Q.
--      3) RawDataRdAdr is the address location of RAM_ADC_Data_DO.

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_unsigned.all; 
  use IEEE.std_logic_arith.all;
  
library work;
    use work.package_EFACV2.all; 
--    use work.package_oneshot.all; 

-- synthesis translate_off
library UNISIM;
--use UNISIM.vcomponents.all;
use UNISIM.all;
-- synthesis translate_on

entity RawDataBuffer is
        port
         (
           CLK                  	: in std_logic;  --
           RESET_N              	: in  std_logic;
           SYNC                 	: in  std_logic;
           OrTrig               	: in  std_logic;
           RawDataRdAdr				: in std_logic_vector(9 downto 0);  --  RAMB36SDP address location of RAM_ADC_Data_DO
           RawDataRdEn        		: in std_logic;  -- one to read.  
--           Adc_Data              : in slv13_array(5 downto 0);  --- connect to ADC's sample data	-- CHANGE for 6 CH          
--           RAM_ADC_Data_DO_REG   : out slv13_array(5 downto 0); --- output of RAM 	 -- CHANGE for 6 CH
           Adc_Data              	: in std_logic_vector(11 downto 0);  --- connect to ADC's sample data	-- CHANGE for 6 CH          
           RAM_ADC_Data_DO_REG   	: out std_logic_vector(11 downto 0); --- output of RAM 	 -- CHANGE for 6 CH
			   
           RawDataTrigAdr_REG   	: out std_logic_vector(9 downto 0)  --- Address of RAM on rising edge of OrTrig 

        );
end RawDataBuffer;

architecture RTL of RawDataBuffer is

	component new_raw_buff 
	  PORT (
		 clka 	: IN STD_LOGIC;
		 ena 		: IN STD_LOGIC;
		 wea 		: IN STD_LOGIC_VECTOR(0 DOWNTO 0);
		 addra 	: IN STD_LOGIC_VECTOR(9 DOWNTO 0);
		 dina 	: IN STD_LOGIC_VECTOR(11 DOWNTO 0);
		 clkb 	: IN STD_LOGIC;
		 rstb 	: IN STD_LOGIC;
		 enb 		: IN STD_LOGIC;
		 addrb 	: IN STD_LOGIC_VECTOR(9 DOWNTO 0);
		 doutb 	: OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
	  );
	END component; 
	
--  component DpRam_13_1K
--	  PORT (
--		 clka 	: IN STD_LOGIC;
--		 wea 	: IN STD_LOGIC_VECTOR(0 DOWNTO 0);
--		 addra 	: IN STD_LOGIC_VECTOR(9 DOWNTO 0);
--		 dina 	: IN STD_LOGIC_VECTOR(12 DOWNTO 0);
--		 clkb 	: IN STD_LOGIC;
--		 addrb 	: IN STD_LOGIC_VECTOR(9 DOWNTO 0);
--		 doutb 	: OUT STD_LOGIC_VECTOR(12 DOWNTO 0)
--	);
--  end component;

	signal DIN1_Q	 : std_logic_vector(11 downto 0);
	signal DIN2_Q	 : std_logic_vector(11 downto 0);
	signal DIN3_Q	 : std_logic_vector(11 downto 0);
	signal DIN4_Q	 : std_logic_vector(11 downto 0);
	signal DIN5_Q	 : std_logic_vector(11 downto 0);
	signal DIN6_Q	 : std_logic_vector(11 downto 0);

	signal RAM1_DI  : std_logic_vector(11 downto 0);  
	signal RAM2_DI  : std_logic_vector(11 downto 0);  
	signal RAM3_DI  : std_logic_vector(11 downto 0);  
	signal RAM4_DI  : std_logic_vector(11 downto 0); 
	signal RAM5_DI  : std_logic_vector(11 downto 0);  
	signal RAM6_DI  : std_logic_vector(11 downto 0);
	
--  signal PSPMT1_DI_Q : std_logic_vector(51 downto 0);
--  signal PSPMT2_DI_Q : std_logic_vector(51 downto 0);
--  signal PSPMT3_DI_Q : std_logic_vector(51 downto 0);
--  signal PSPMT4_DI_Q : std_logic_vector(51 downto 0);
 
--  signal RAM1_DI  : std_logic_vector(63 downto 0);  
--  signal RAM2_DI  : std_logic_vector(63 downto 0);  
--  signal RAM3_DI  : std_logic_vector(63 downto 0);  
--  signal RAM4_DI  : std_logic_vector(63 downto 0); 

  signal WrAdr_D :  std_logic_vector(9 downto 0);
  signal WrAdr_Q :  std_logic_vector(9 downto 0);
--  signal WrAdrBuf_Q : slv10_array(5 downto 0); -- CHANGE for 6 CH 
  signal WrAdrBuf_Q : std_logic_vector(9 downto 0); -- CHANGE for 6 CH 

  signal RawDataTrigAdr_D : std_logic_vector(9 downto 0);  
  signal RawDataTrigAdr_Q : std_logic_vector(9 downto 0);  

  signal OrTrig_D  :   std_logic;
  signal OrTrig_Q  :   std_logic;
  signal POrTrig   :   std_logic;
  
  signal RAM1_WE_D : std_logic;
  signal RAM1_WE_Q : std_logic;

--  signal RAM2_WE_D : std_logic;
--  signal RAM2_WE_Q : std_logic;

  signal RawDataRdAdr_Q :  std_logic_vector(9 downto 0);
  signal RawDataRdEn_Q  :  std_logic;
  
  signal RAM1_RdEn_D : std_logic;
  signal RAM1_RdEn_Q : std_logic;
  
	signal RAM1A_DO : std_logic_vector(11 downto 0);
--	signal RAM2A_DO : std_logic_vector(12 downto 0);
--	signal RAM3A_DO : std_logic_vector(12 downto 0);
--	signal RAM4A_DO : std_logic_vector(12 downto 0);
--	signal RAM5A_DO : std_logic_vector(12 downto 0);
--	signal RAM6A_DO : std_logic_vector(12 downto 0);
  
--  signal RAM2_RdEn_D : std_logic;
 -- signal RAM2_RdEn_Q : std_logic;
--  signal RAM1A_DO : std_logic_vector(63 downto 0);
--  signal RAM1B_DO : std_logic_vector(63 downto 0);
--  signal RAM2A_DO : std_logic_vector(63 downto 0);
--  signal RAM2B_DO : std_logic_vector(63 downto 0);
--  signal RAM3A_DO : std_logic_vector(63 downto 0);
--  signal RAM3B_DO : std_logic_vector(63 downto 0);
--  signal RAM4A_DO : std_logic_vector(63 downto 0);
--  signal RAM4B_DO : std_logic_vector(63 downto 0);

--  signal RAM_ADC_Data_DO_D : slv13_array(5 downto 0); --- output of RAM -- CHANGE for 6 CH
--  signal RAM_ADC_Data_DO_Q : slv13_array(5 downto 0); --- output of RAM  -- CHANGE for 6 CH	
  signal RAM_ADC_Data_DO_D : std_logic_vector(11 downto 0); --- output of RAM -- CHANGE for 6 CH
  signal RAM_ADC_Data_DO_Q : std_logic_vector(11 downto 0); --- output of RAM  -- CHANGE for 6 CH
    
  signal RAM_SSR_D :  std_logic; 
  signal RAM_SSR_Q :  std_logic; 
    
begin

  ----- RAM input  
  OrTrig_D <= OrTrig;
  POrTrig <= OrTrig_D and not OrTrig_Q;
   
  WrAdr_D <=  (others => '0') when SYNC = '1' else
              WrAdr_Q + 1;

              
  RawDataTrigAdr_REG <= RawDataTrigAdr_Q;
  RawDataTrigAdr_D <= WrAdr_Q when POrTrig = '1' else RawDataTrigAdr_Q;
  
--  RAM1_DI <= x"000" & PSPMT1_DI_Q;
--  RAM2_DI <= x"000" & PSPMT2_DI_Q;
--  RAM3_DI <= x"000" & PSPMT3_DI_Q;
--  RAM4_DI <= x"000" & PSPMT4_DI_Q;

--  RAM1_DI <= DIN1_Q;
--  RAM2_DI <= DIN2_Q;
--  RAM3_DI <= DIN3_Q;
--  RAM4_DI <= DIN4_Q;
--  RAM5_DI <= DIN5_Q;
--  RAM6_DI <= DIN6_Q; 
  
  --RAM1_DI <= DIN1_Q;
  
  RAM1_WE_D <= not SYNC; -- new, only need the one wr enable 
  
--  RAM1_WE_D <= not SYNC and not WrAdr_Q(9); 
--  RAM2_WE_D <= not SYNC and     WrAdr_Q(9);
  
  ------  RAM output ----------------------
--  RAM1_RdEn_D <= RawDataRdEn_Q and not RawDataRdAdr_Q(9);
--  RAM2_RdEn_D <= RawDataRdEn_Q and     RawDataRdAdr_Q(9);

  RAM1_RdEn_D <= RawDataRdEn_Q; --new, only need the one rd enable  
  
  RAM_ADC_Data_DO_REG   <= RAM_ADC_Data_DO_Q;

--  RAM_ADC_Data_DO_D(0) <= RAM1A_DO;
--  RAM_ADC_Data_DO_D(1) <= RAM2A_DO;
--  RAM_ADC_Data_DO_D(2) <= RAM3A_DO;
--  RAM_ADC_Data_DO_D(3) <= RAM4A_DO;
--  RAM_ADC_Data_DO_D(4) <= RAM5A_DO;
--  RAM_ADC_Data_DO_D(5) <= RAM6A_DO;	

  RAM_ADC_Data_DO_D <= RAM1A_DO;

	uRAM_1 : new_raw_buff 
	  port map (
				 clka 	=> CLK,
				 clkb 	=> CLK,
				 rstb 	=> SYNC, --SYNC, --RAM_SSR_Q,
				 
				 ena 	=> '1',
				 wea 	=> "1",
				 addra 	=> WrAdrBuf_Q(9 downto 0),
				 dina 	=> DIN1_Q, --RAM1_DI,
				 
				 enb 	=> RAM1_RdEn_Q,
				 addrb 	=> RawDataRdAdr_Q(9 downto 0),
				 doutb 	=> RAM1A_DO);
				 
				 
--	uRAM_1 :  DpRam_13_1K
--	  port map (
--		 clka 	=> CLK,
--		 wea(0)	=> RAM1_WE_Q,
--		 addra 	=> WrAdrBuf_Q(9 downto 0),
--		 dina 	=> DIN1_Q,
--		 clkb 	=> CLK,
--		 addrb 	=> RawDataRdAdr_Q(9 downto 0),
--		 doutb 	=> RAM1A_DO);

  
--	uRAM_2 : new_raw_buff 
--	  port map (
--				 clka 	=> CLK,
--				 clkb 	=> CLK,
--				 rstb 	=> RAM_SSR_Q,
--				 
--				 ena 		=> RAM1_WE_Q,
--				 wea 		=> "1",
--				 addra 	=> WrAdrBuf_Q(1)(9 downto 0),
--				 dina 	=> RAM2_DI,
--				 
--				 enb 		=> RAM1_RdEn_Q,
--				 addrb 	=> RawDataRdAdr_Q(9 downto 0),
--				 doutb 	=> RAM2A_DO);
--	
--	uRAM_3 : new_raw_buff 
--	  port map (
--				 clka 	=> CLK,
--				 clkb 	=> CLK,
--				 rstb 	=> RAM_SSR_Q,
--				 
--				 ena 		=> RAM1_WE_Q,
--				 wea 		=> "1",
--				 addra 	=> WrAdrBuf_Q(2)(9 downto 0),
--				 dina 	=> RAM3_DI,
--				 
--				 enb 		=> RAM1_RdEn_Q,
--				 addrb 	=> RawDataRdAdr_Q(9 downto 0),
--				 doutb 	=> RAM3A_DO);
-- 
--	uRAM_4 : new_raw_buff 
--	  port map (
--				 clka 	=> CLK,
--				 clkb 	=> CLK,
--				 rstb 	=> RAM_SSR_Q,
--				 
--				 ena 		=> RAM1_WE_Q,
--				 wea 		=> "1",
--				 addra 	=> WrAdrBuf_Q(3)(9 downto 0),
--				 dina 	=> RAM4_DI,
--				 
--				 enb 		=> RAM1_RdEn_Q,
--				 addrb 	=> RawDataRdAdr_Q(9 downto 0),
--				 doutb 	=> RAM4A_DO);
--	 
--	uRAM_5 : new_raw_buff 
--	  port map (
--				 clka 	=> CLK,
--				 clkb 	=> CLK,
--				 rstb 	=> RAM_SSR_Q,
--				 
--				 ena 		=> RAM1_WE_Q,
--				 wea 		=> "1",
--				 addra 	=> WrAdrBuf_Q(4)(9 downto 0),
--				 dina 	=> RAM5_DI,
--				 
--				 enb 		=> RAM1_RdEn_Q,
--				 addrb 	=> RawDataRdAdr_Q(9 downto 0),
--				 doutb 	=> RAM5A_DO);
--	
--	uRAM_6 : new_raw_buff 
--	  port map (
--				 clka 	=> CLK,
--				 clkb 	=> CLK,
--				 rstb 	=> RAM_SSR_Q,
--				 
--				 ena 		=> RAM1_WE_Q,
--				 wea 		=> "1",
--				 addra 	=> WrAdrBuf_Q(5)(9 downto 0),
--				 dina 	=> RAM6_DI,
--				 
--				 enb 		=> RAM1_RdEn_Q,
--				 addrb 	=> RawDataRdAdr_Q(9 downto 0),
--				 doutb 	=> RAM6A_DO);
--

--    process (CLK, RESET_N)
--      begin
--        if RESET_N = '0' then
--			RAM_SSR_Q <= '1';
--			WrAdrBuf_Q <= (others => '0');
--        elsif rising_edge(CLK) then
--			RAM_SSR_Q <= SYNC;
--			WrAdr_Q <= WrAdr_D; 
--			WrAdrBuf_Q <= WrAdr_Q; --change
--        end if;
--      end process;

    process (CLK)
      begin
        if rising_edge(CLK) then
				-- new 6 channel buisness
--				DIN1_Q <= Adc_Data(0);
--				DIN2_Q <= Adc_Data(1);
--				DIN3_Q <= Adc_Data(2);
--				DIN4_Q <= Adc_Data(3);
--				DIN5_Q <= Adc_Data(4);
--				DIN6_Q <= Adc_Data(5);
				DIN1_Q <= Adc_Data;

				OrTrig_Q <= OrTrig_D;
				RawDataTrigAdr_Q <= RawDataTrigAdr_D;
				RAM1_WE_Q <= RAM1_WE_D;

				RAM1_RdEn_Q <= RAM1_RdEn_D;

				RawDataRdAdr_Q <=  RawDataRdAdr;
				RawDataRdEn_Q      <=  RawDataRdEn;
				RAM_ADC_Data_DO_Q  <= RAM_ADC_Data_DO_D;
				
			   WrAdr_Q <= WrAdr_D; 
			   WrAdrBuf_Q <= WrAdr_Q; --change

        end if;
      end process;
      
--    WrAdrBuf_array: for I in 0 to 5 generate -- change for 6 ch
--    process (CLK)
--      begin
--        if rising_edge(CLK) then
--           WrAdrBuf_Q(I)  <= WrAdr_Q; 
--		   
--        end if;
--      end process;
--    end generate;
      
        
end RTL;
