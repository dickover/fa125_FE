--  Author:  Hai Dong
--
--   This code combines code for LX25 and FX20.
--
--      06/14/10
--           Replace PlayBack_WV with PlayBack16_WV.
--      3/22/13 Add these signals so that there is no wait for the format to be done
--              before another processing can be started.
--           ModeFifoRdEn   : std_logic;
--           ModeFifoDout   : std_logic_VECTOR(1 downto 0);
--           ModeFifoEmpty  : std_logic;
--           ModeFifoFull   : std_logic;
--   1/24/2014
--        Change NSA and NSB to (8 downto 0)
--        Remove NSA_MINUS1_D, NSA_MINUS1_Q, NSB_MINUS_2, NSA_MINUS_7
--        PROCESSING_ALL_VER2_TOP--> Change
--                      NSA           => NSA_MINUS1_Q,
--               to
--                      NSA             => NSA_Q,
--   3/3/2014
--       Replace SUM_VER2_TOP with TriggerProcessing_TOP
--       Add
--           TRIG_PATH_NSB             : in std_logic_vector(3 downto 0);  -- Delay SampleIN by this number of CLK 
--           TRIG_PATH_ThresholdValue  : in std_logic_vector(11 downto 0);   --- From Host Register.
--           TRIG_PATH_NSA             : in std_logic_vector(5 downto 0);     ----   
 

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_unsigned.all;  
  use IEEE.std_logic_arith.all;

library unisim;
use unisim.all; 	
  
library work;
    use work.package_FADC250_V2.all; 
    use work.Package_PlayBack.all;

entity ADC_PROC_TOP is
--        generic
--        (
--                CH1_IDELAY_VALUE : CH_IDELAY_VAL_ARRAY := (1,1,1,1,1,1,1,1,1,1,1,1,1);
--                CH2_IDELAY_VALUE : CH_IDELAY_VAL_ARRAY := (1,1,1,1,1,1,1,1,1,1,1,1,1);
--                CH3_IDELAY_VALUE : CH_IDELAY_VAL_ARRAY := (1,1,1,1,1,1,1,1,1,1,1,1,1);
--                CH4_IDELAY_VALUE : CH_IDELAY_VAL_ARRAY := (1,1,1,1,1,1,1,1,1,1,1,1,1);
--                CH5_IDELAY_VALUE : CH_IDELAY_VAL_ARRAY := (1,1,1,1,1,1,1,1,1,1,1,1,1);
--                CH6_IDELAY_VALUE : CH_IDELAY_VAL_ARRAY := (1,1,1,1,1,1,1,1,1,1,1,1,1);
--                CH7_IDELAY_VALUE : CH_IDELAY_VAL_ARRAY := (1,1,1,1,1,1,1,1,1,1,1,1,1);
--                CH8_IDELAY_VALUE : CH_IDELAY_VAL_ARRAY := (1,1,1,1,1,1,1,1,1,1,1,1,1); 
--                CH9_IDELAY_VALUE : CH_IDELAY_VAL_ARRAY := (1,1,1,1,1,1,1,1,1,1,1,1,1);
--                CH10_IDELAY_VALUE : CH_IDELAY_VAL_ARRAY := (1,1,1,1,1,1,1,1,1,1,1,1,1);
--                CH11_IDELAY_VALUE : CH_IDELAY_VAL_ARRAY := (1,1,1,1,1,1,1,1,1,1,1,1,1);
--                CH12_IDELAY_VALUE : CH_IDELAY_VAL_ARRAY := (1,1,1,1,1,1,1,1,1,1,1,1,1);
--                CH13_IDELAY_VALUE : CH_IDELAY_VAL_ARRAY := (1,1,1,1,1,1,1,1,1,1,1,1,1);
--                CH14_IDELAY_VALUE : CH_IDELAY_VAL_ARRAY := (1,1,1,1,1,1,1,1,1,1,1,1,1);
--                CH15_IDELAY_VALUE : CH_IDELAY_VAL_ARRAY := (1,1,1,1,1,1,1,1,1,1,1,1,1);
--                CH16_IDELAY_VALUE : CH_IDELAY_VAL_ARRAY := (1,1,1,1,1,1,1,1,1,1,1,1,1) 
--        );
        port
         (
           CLK                  : in std_logic;
           CLK_HOST             : in std_logic; 
           RESET_N              : in  std_logic;
           SOFT_RESET_N         : in std_logic;

           --- To Host 
           DATA_BUFFER_RDY_REG      : out std_logic; 

           TRIGGER              : in std_logic;   
           TRIGGER2             : in std_logic;  --- for PPG play Back   
           
           SYNC                 : in std_logic; 
			  
			  	adcclko               : in std_logic; -- used for all 6 ADCs, comes from one of three adc chips, middle 2 channels, also not differential	
				ADC1_DATA					  : in std_logic_vector(11 downto 0); -- not differential,  ends up being ADC_RAWDATA_1 so delete converter-- ouput read(y)??, either way don't have			
				ADC2_DATA					  : in std_logic_vector(11 downto 0);
				ADC3_DATA					  : in std_logic_vector(11 downto 0);
				ADC4_DATA					  : in std_logic_vector(11 downto 0);
				ADC5_DATA					  : in std_logic_vector(11 downto 0);
				ADC6_DATA					  : in std_logic_vector(11 downto 0);
 
           --- FROM ADC  ************
--           DN_1                 : in std_logic_vector(11 downto 0);
--           DP_1                 : in std_logic_vector(11 downto 0);
--           DCLKN_1              : in std_logic;
--           DCLKP_1              : in std_logic;
--           ORN_1                 : in std_logic;
--           ORP_1                 : in std_logic;
--
--           DN_2                 : in std_logic_vector(11 downto 0);
--           DP_2                 : in std_logic_vector(11 downto 0);
--           DCLKN_2              : in std_logic;
--           DCLKP_2              : in std_logic;
--           ORN_2                 : in std_logic;
--           ORP_2                 : in std_logic;
--
--           DN_3                 : in std_logic_vector(11 downto 0);
--           DP_3                 : in std_logic_vector(11 downto 0);
--           DCLKN_3              : in std_logic;
--           DCLKP_3              : in std_logic;
--           ORN_3                 : in std_logic;
--           ORP_3                 : in std_logic;
--
--           DN_4                 : in std_logic_vector(11 downto 0);
--           DP_4                 : in std_logic_vector(11 downto 0);
--           DCLKN_4              : in std_logic;
--           DCLKP_4              : in std_logic;
--           ORN_4                 : in std_logic;
--           ORP_4                 : in std_logic;
--
--           DN_5                 : in std_logic_vector(11 downto 0);
--           DP_5                 : in std_logic_vector(11 downto 0);
--           DCLKN_5              : in std_logic;
--           DCLKP_5              : in std_logic;
--           ORN_5                 : in std_logic;
--           ORP_5                 : in std_logic;
--
--           DN_6                 : in std_logic_vector(11 downto 0);
--           DP_6                 : in std_logic_vector(11 downto 0);
--           DCLKN_6              : in std_logic;
--           DCLKP_6              : in std_logic;
--           ORN_6                 : in std_logic;
--           ORP_6                 : in std_logic;
--
--           DN_7                 : in std_logic_vector(11 downto 0);
--           DP_7                 : in std_logic_vector(11 downto 0);
--           DCLKN_7              : in std_logic;
--           DCLKP_7              : in std_logic;
--           ORN_7                 : in std_logic;
--           ORP_7                 : in std_logic;
--
--           DN_8                 : in std_logic_vector(11 downto 0);
--           DP_8                 : in std_logic_vector(11 downto 0);
--           DCLKN_8              : in std_logic;
--           DCLKP_8              : in std_logic;
--           ORN_8                 : in std_logic;
--           ORP_8                 : in std_logic;
--
--           DN_9                 : in std_logic_vector(11 downto 0);
--           DP_9                 : in std_logic_vector(11 downto 0);
--           DCLKN_9              : in std_logic;
--           DCLKP_9              : in std_logic;
--           ORN_9                 : in std_logic;
--           ORP_9                 : in std_logic;
--
--           DN_10                : in std_logic_vector(11 downto 0);
--           DP_10                : in std_logic_vector(11 downto 0);
--           DCLKN_10             : in std_logic;
--           DCLKP_10             : in std_logic;
--           ORN_10                : in std_logic;
--           ORP_10                : in std_logic;
--
--           DN_11                : in std_logic_vector(11 downto 0);
--           DP_11                : in std_logic_vector(11 downto 0);
--           DCLKN_11             : in std_logic;
--           DCLKP_11             : in std_logic;
--           ORN_11                : in std_logic;
--           ORP_11                : in std_logic;
--
--           DN_12                : in std_logic_vector(11 downto 0);
--           DP_12                : in std_logic_vector(11 downto 0);
--           DCLKN_12             : in std_logic;
--           DCLKP_12             : in std_logic;
--           ORN_12                : in std_logic;
--           ORP_12                : in std_logic;
--
--           DN_13                : in std_logic_vector(11 downto 0);
--           DP_13                : in std_logic_vector(11 downto 0);
--           DCLKN_13             : in std_logic;
--           DCLKP_13             : in std_logic;
--           ORN_13                : in std_logic;
--           ORP_13                : in std_logic;
--
--           DN_14                : in std_logic_vector(11 downto 0);
--           DP_14                : in std_logic_vector(11 downto 0);
--           DCLKN_14             : in std_logic;
--           DCLKP_14             : in std_logic;
--           ORN_14                : in std_logic;
--           ORP_14                : in std_logic;
--
--           DN_15                : in std_logic_vector(11 downto 0);
--           DP_15                : in std_logic_vector(11 downto 0);
--           DCLKN_15             : in std_logic;
--           DCLKP_15             : in std_logic;
--           ORN_15                : in std_logic;
--           ORP_15                : in std_logic;
--
--           DN_16                : in std_logic_vector(11 downto 0);
--           DP_16                : in std_logic_vector(11 downto 0);
--           DCLKN_16             : in std_logic;
--           DCLKP_16             : in std_logic;
--           ORN_16                : in std_logic;
--           ORP_16                : in std_logic;
                   
           --- To control bus Status register
           TRIGGER_NUMBER_REG  : out std_logic_vector(15 downto 0);

           --- To control bus Registers
           PTW          : in  std_logic_vector(15 downto 0);
           PL        : in  std_logic_vector(15 downto 0);
           NSB   : in  std_logic_vector(8 downto 0); 
           NSA     : in  std_logic_vector(8 downto 0);
           PTW_DAT_BUF_LAST_ADR : in  std_logic_vector(15 downto 0);
           PTW_MAX_BUF          : in  std_logic_vector(15 downto 0);  
           CONFIG1           : in  std_logic_vector(15 downto 0);
           CONFIG2           : in  std_logic_vector(15 downto 0);
           TET0 : in  std_logic_vector(15 downto 0);      
           TET1 : in  std_logic_vector(15 downto 0);      
           TET2 : in  std_logic_vector(15 downto 0);      
           TET3 : in  std_logic_vector(15 downto 0);      
           TET4 : in  std_logic_vector(15 downto 0);      
           TET5 : in  std_logic_vector(15 downto 0);      
--           TET6 : in  std_logic_vector(15 downto 0);      
--           TET7 : in  std_logic_vector(15 downto 0);
--           TET8 : in  std_logic_vector(15 downto 0);      
--           TET9 : in  std_logic_vector(15 downto 0);      
--           TET10 : in  std_logic_vector(15 downto 0);      
--           TET11 : in  std_logic_vector(15 downto 0);      
--           TET12 : in  std_logic_vector(15 downto 0);      
--           TET13 : in  std_logic_vector(15 downto 0);      
--           TET14 : in  std_logic_vector(15 downto 0);      
--           TET15 : in  std_logic_vector(15 downto 0);
           TRIG_PATH_NSB             : in std_logic_vector(3 downto 0);  -- Delay SampleIN by this number of CLK 
           TRIG_PATH_ThresholdValue  : in std_logic_vector(11 downto 0);   --- From Host Register.
           TRIG_PATH_NSA             : in std_logic_vector(5 downto 0);     ----   

           ----- Pedestal Subtraction
            PedSub0            : in  std_logic_vector (15 downto 0);
            PedSub1            : in  std_logic_vector (15 downto 0);
            PedSub2            : in  std_logic_vector (15 downto 0);
            PedSub3            : in  std_logic_vector (15 downto 0);
            PedSub4            : in  std_logic_vector (15 downto 0);
            PedSub5            : in  std_logic_vector (15 downto 0);
--            PedSub6            : in  std_logic_vector (15 downto 0);
--            PedSub7            : in  std_logic_vector (15 downto 0);
--            PedSub8            : in  std_logic_vector (15 downto 0);
--            PedSub9            : in  std_logic_vector (15 downto 0);
--            PedSub10           : in std_logic_vector (15 downto 0);
--            PedSub11           : in std_logic_vector (15 downto 0);
--            PedSub12           : in std_logic_vector (15 downto 0);
--            PedSub13           : in std_logic_vector (15 downto 0);
--            PedSub14           : in std_logic_vector (15 downto 0);
--            PedSub15           : in std_logic_vector (15 downto 0);

           PPG_DAT_OUT_VALID   : in std_logic;
           PPG_DAT_Out         : out  std_logic_vector(15 downto 0);
           PPG_DAT_IN   : in std_logic_vector(15 downto 0);
           
           --- To Host FIFO IDT72V36100 pins
			  cid						  : in std_logic_vector(3 downto 0);
           FIFO_DATA             : out std_logic_vector(35 downto 0); 
           FIFO_WCLK                  : out std_logic; -- Write Clock
           FIFO_WEN                   : out std_logic; -- Write EN
           FIFO_OE_N                  : out std_logic; -- output enable
           
           --- To CTRL FPGA
           SUMP                  : out std_logic_vector(15 downto 0);
           SUMN                  : out std_logic_vector(15 downto 0);
           SUMP2_DV               : out std_logic;
           SUMN2_DV               : out std_logic;

            -- To TRIG PROC
           SUM_REG               : out std_logic_vector(15 downto 0);
           HITBIT_DV_REG    : out std_logic;
           HITBIT_N_REG          : out std_logic_vector(15 downto 0)
        );
end ADC_PROC_TOP;

architecture RTL of ADC_PROC_TOP is

--   constant   VERSION : std_logic_vector(15 downto 0) := x"0901";
--
--   component SYNC_ADC_IN_VER2
--        generic
--        (
--                CH1_IDELAY_VALUE : CH_IDELAY_VAL_ARRAY := (1,1,1,1,1,1,1,1,1,1,1,1,1);
--                CH2_IDELAY_VALUE : CH_IDELAY_VAL_ARRAY := (1,1,1,1,1,1,1,1,1,1,1,1,1);
--                CH3_IDELAY_VALUE : CH_IDELAY_VAL_ARRAY := (1,1,1,1,1,1,1,1,1,1,1,1,1);
--                CH4_IDELAY_VALUE : CH_IDELAY_VAL_ARRAY := (1,1,1,1,1,1,1,1,1,1,1,1,1);
--                CH5_IDELAY_VALUE : CH_IDELAY_VAL_ARRAY := (1,1,1,1,1,1,1,1,1,1,1,1,1);
--                CH6_IDELAY_VALUE : CH_IDELAY_VAL_ARRAY := (1,1,1,1,1,1,1,1,1,1,1,1,1);
--                CH7_IDELAY_VALUE : CH_IDELAY_VAL_ARRAY := (1,1,1,1,1,1,1,1,1,1,1,1,1);
--                CH8_IDELAY_VALUE : CH_IDELAY_VAL_ARRAY := (1,1,1,1,1,1,1,1,1,1,1,1,1) 
--        );
--        port
--         (
--           CLK                  : in std_logic; 
--           RESET_N              : in std_logic; 
--
--           --- FROM ADC  ************
--           DN_1                 : in std_logic_vector(11 downto 0);
--           DP_1                 : in std_logic_vector(11 downto 0);
--           DCLKN_1              : in std_logic;
--           DCLKP_1              : in std_logic;
--           ORN_1                 : in std_logic;
--           ORP_1                 : in std_logic;
--
--           DN_2                 : in std_logic_vector(11 downto 0);
--           DP_2                 : in std_logic_vector(11 downto 0);
--           DCLKN_2              : in std_logic;
--           DCLKP_2              : in std_logic;
--           ORN_2                 : in std_logic;
--           ORP_2                 : in std_logic;
--
--           DN_3                 : in std_logic_vector(11 downto 0);
--           DP_3                 : in std_logic_vector(11 downto 0);
--           DCLKN_3              : in std_logic;
--           DCLKP_3              : in std_logic;
--           ORN_3                 : in std_logic;
--           ORP_3                 : in std_logic;
--
--           DN_4                 : in std_logic_vector(11 downto 0);
--           DP_4                 : in std_logic_vector(11 downto 0);
--           DCLKN_4              : in std_logic;
--           DCLKP_4              : in std_logic;
--           ORN_4                 : in std_logic;
--           ORP_4                 : in std_logic;
--
--           DN_5                 : in std_logic_vector(11 downto 0);
--           DP_5                 : in std_logic_vector(11 downto 0);
--           DCLKN_5              : in std_logic;
--           DCLKP_5              : in std_logic;
--           ORN_5                 : in std_logic;
--           ORP_5                 : in std_logic;
--
--           DN_6                 : in std_logic_vector(11 downto 0);
--           DP_6                 : in std_logic_vector(11 downto 0);
--           DCLKN_6              : in std_logic;
--           DCLKP_6              : in std_logic;
--           ORN_6                 : in std_logic;
--           ORP_6                 : in std_logic;
--
--           DN_7                 : in std_logic_vector(11 downto 0);
--           DP_7                 : in std_logic_vector(11 downto 0);
--           DCLKN_7              : in std_logic;
--           DCLKP_7              : in std_logic;
--           ORN_7                 : in std_logic;
--           ORP_7                 : in std_logic;
--
--           DN_8                 : in std_logic_vector(11 downto 0);
--           DP_8                 : in std_logic_vector(11 downto 0);
--           DCLKN_8              : in std_logic;
--           DCLKP_8              : in std_logic;
--           ORN_8                 : in std_logic;
--           ORP_8                 : in std_logic;
--
--           ---- FIFO RESET
--           FIFO_RESET            : in std_logic;
--           
--           --- To System
--           ADC_DATA_1_REG        : out std_logic_vector(12 downto 0);
--           ADC_DATA_2_REG        : out std_logic_vector(12 downto 0);
--           ADC_DATA_3_REG        : out std_logic_vector(12 downto 0);
--           ADC_DATA_4_REG        : out std_logic_vector(12 downto 0);
--           ADC_DATA_5_REG        : out std_logic_vector(12 downto 0);
--           ADC_DATA_6_REG        : out std_logic_vector(12 downto 0);
--           ADC_DATA_7_REG        : out std_logic_vector(12 downto 0);
--           ADC_DATA_8_REG        : out std_logic_vector(12 downto 0)
--            
--        );
--    end component; 

    component PlayBack16_WV
      port 
       (
        CLK         : in std_logic;
        RESET_N     : in std_logic;

        WaveDataWrEN : in std_logic;   --- rising edge write to memory 
        WaveDataIN   : in std_logic_VECTOR(15 downto 0);  --- bit 16th rising edge begins write. Falling ede reset address after 2 more write. 
        PlayBack    : in std_logic;   --- 1 play back data
           
        WaveDataOUT  : out std_logic_VECTOR(15 downto 0);  --- To verify that data is written, connect to host register. 
        PlayBack16_WV_OUT : out Aray13Bits
       );
    end component; 

    component DATA_BUFFER_ALLCH_VER2_TOP
        port
         (
           CLK                  : in std_logic;  -- 
           CLK_PROCESS          : in std_logic; 
           RESET_N              : in  std_logic;
           SOFT_RESET_N         : in std_logic;

           --- To Host 
           DATA_BUFFER_RDY_REG      : out std_logic; 

           ---- Ports for testing
           TestPort                  : out std_logic_vector(7 downto 0);
           
           --- Data From 8 ADC. Each consist of 12 data bits and 1 overflow
           ADC1_DATA            : in std_logic_vector(12 downto 0);  
           ADC2_DATA            : in std_logic_vector(12 downto 0);  
           ADC3_DATA            : in std_logic_vector(12 downto 0);  
           ADC4_DATA             : in std_logic_vector(12 downto 0); 
           ADC5_DATA             : in std_logic_vector(12 downto 0); 
           ADC6_DATA             : in std_logic_vector(12 downto 0); 
--           ADC7_DATA             : in std_logic_vector(12 downto 0); 
--           ADC8_DATA             : in std_logic_vector(12 downto 0); 
--
--           ADC9_DATA            : in std_logic_vector(12 downto 0);  
--           ADC10_DATA            : in std_logic_vector(12 downto 0);  
--           ADC11_DATA            : in std_logic_vector(12 downto 0);  
--           ADC12_DATA             : in std_logic_vector(12 downto 0); 
--           ADC13_DATA             : in std_logic_vector(12 downto 0); 
--           ADC14_DATA             : in std_logic_vector(12 downto 0); 
--           ADC15_DATA             : in std_logic_vector(12 downto 0); 
--           ADC16_DATA             : in std_logic_vector(12 downto 0); 

           ---- Common to all channel
           COLLECT_ON           : in std_logic;
           TIME_STAMP           : in std_logic_vector(47 downto 0); -- From 48 bits Counter
           PTW_WORDS            : in std_logic_vector(8 downto 0);  -- Programmable Triggger Window number of words
           PTW_WORDS_MINUS_ONE  : in std_logic_vector(8 downto 0);  -- Use to mark the end of PTW data words
           TRIGGER_N            : in std_logic;                     -- From input pin
           TRIGER_NUMBER        : in std_logic_vector(26 downto 0); 
           LATENCY_WORD         : in std_logic_vector(10 downto 0); -- Number of ADC samples to look back.
           PTW_DAT_BUF_LAST_ADR : in std_logic_VECTOR(11 downto 0); --- The last address of the PTW data Buffer
           MAX_PTW_DATA_BLOCK   : in std_logic_VECTOR(7 downto 0);  --- Maximum number of PTW block of data

           --- When a PTW data block is processed, pulse the respective DEC_PTW_CNT to decrement the rescpective
           --- PTW_DATA_BLOCK_CNT_REG           
           DEC_PTW_CNT1           : in std_logic;  --- Rising egde decrease number of PTW Data Block ready to process by one.
           DEC_PTW_CNT2           : in std_logic;  
           DEC_PTW_CNT3           : in std_logic;  
           DEC_PTW_CNT4           : in std_logic;  
           DEC_PTW_CNT5           : in std_logic;  
           DEC_PTW_CNT6           : in std_logic;  
--           DEC_PTW_CNT7           : in std_logic;  
--           DEC_PTW_CNT8           : in std_logic;  
--           DEC_PTW_CNT9           : in std_logic;  --- Rising egde decrease number of PTW Data Block ready to process by one.
--           DEC_PTW_CNT10          : in std_logic;  
--           DEC_PTW_CNT11          : in std_logic;  
--           DEC_PTW_CNT12          : in std_logic;  
--           DEC_PTW_CNT13          : in std_logic;  
--           DEC_PTW_CNT14          : in std_logic;  
--           DEC_PTW_CNT15          : in std_logic;  
--           DEC_PTW_CNT16          : in std_logic;  
           PTW_DATA_BLOCK_CNT1_REG : out std_logic_vector(7 downto 0);  --- Provide the number of PTW Data Blocks ready for processing
           PTW_DATA_BLOCK_CNT2_REG : out std_logic_vector(7 downto 0);
           PTW_DATA_BLOCK_CNT3_REG : out std_logic_vector(7 downto 0);  
           PTW_DATA_BLOCK_CNT4_REG : out std_logic_vector(7 downto 0);  
           PTW_DATA_BLOCK_CNT5_REG : out std_logic_vector(7 downto 0);  
           PTW_DATA_BLOCK_CNT6_REG : out std_logic_vector(7 downto 0);  
--           PTW_DATA_BLOCK_CNT7_REG : out std_logic_vector(7 downto 0);  
--           PTW_DATA_BLOCK_CNT8_REG : out std_logic_vector(7 downto 0);  
--           PTW_DATA_BLOCK_CNT9_REG : out std_logic_vector(7 downto 0);  --- Provide the number of PTW Data Blocks ready for processing
--           PTW_DATA_BLOCK_CNT10_REG : out std_logic_vector(7 downto 0);
--           PTW_DATA_BLOCK_CNT11_REG : out std_logic_vector(7 downto 0);  
--           PTW_DATA_BLOCK_CNT12_REG : out std_logic_vector(7 downto 0);  
--           PTW_DATA_BLOCK_CNT13_REG : out std_logic_vector(7 downto 0);  
--           PTW_DATA_BLOCK_CNT14_REG : out std_logic_vector(7 downto 0);  
--           PTW_DATA_BLOCK_CNT15_REG : out std_logic_vector(7 downto 0);  
--           PTW_DATA_BLOCK_CNT16_REG : out std_logic_vector(7 downto 0);  
           
           --- Status Bits for each ADC channels
           PTW_BUFFER_OVERRUN1_REG : out std_logic;  --- Set when PTW_DATA_BLOCK_CNT_REG overflow. SOFT_RESET_N reset.
           PTW_BUFFER_OVERRUN2_REG : out std_logic;
           PTW_BUFFER_OVERRUN3_REG : out std_logic;
           PTW_BUFFER_OVERRUN4_REG : out std_logic;
           PTW_BUFFER_OVERRUN5_REG : out std_logic;
           PTW_BUFFER_OVERRUN6_REG : out std_logic;
--           PTW_BUFFER_OVERRUN7_REG : out std_logic;
--           PTW_BUFFER_OVERRUN8_REG : out std_logic;
--           PTW_BUFFER_OVERRUN9_REG : out std_logic;  --- Set when PTW_DATA_BLOCK_CNT_REG overflow.
--           PTW_BUFFER_OVERRUN10_REG : out std_logic;
--           PTW_BUFFER_OVERRUN11_REG : out std_logic;
--           PTW_BUFFER_OVERRUN12_REG : out std_logic;
--           PTW_BUFFER_OVERRUN13_REG : out std_logic;
--           PTW_BUFFER_OVERRUN14_REG : out std_logic;
--           PTW_BUFFER_OVERRUN15_REG : out std_logic;
--           PTW_BUFFER_OVERRUN16_REG : out std_logic;
           RAW_BUFFER_OVERRUN1_REG  : out std_logic;  --- Set when Trigger Rate is faster than the ADC data rate. SOFT_RESET_N reset.
           RAW_BUFFER_OVERRUN2_REG  : out std_logic;
           RAW_BUFFER_OVERRUN3_REG  : out std_logic;
           RAW_BUFFER_OVERRUN4_REG  : out std_logic;
           RAW_BUFFER_OVERRUN5_REG  : out std_logic;
           RAW_BUFFER_OVERRUN6_REG  : out std_logic;
--           RAW_BUFFER_OVERRUN7_REG  : out std_logic;
--           RAW_BUFFER_OVERRUN8_REG  : out std_logic;
--           RAW_BUFFER_OVERRUN9_REG  : out std_logic;  --- Set when Trigger Rate is faster than the ADC data rate.
--           RAW_BUFFER_OVERRUN10_REG  : out std_logic;
--           RAW_BUFFER_OVERRUN11_REG  : out std_logic;
--           RAW_BUFFER_OVERRUN12_REG  : out std_logic;
--           RAW_BUFFER_OVERRUN13_REG  : out std_logic;
--           RAW_BUFFER_OVERRUN14_REG  : out std_logic;
--           RAW_BUFFER_OVERRUN15_REG  : out std_logic;
--           RAW_BUFFER_OVERRUN16_REG  : out std_logic;
            
           -- Read out the PTW Data Block (PTW*_RAM_DATA) with PTW*_RAM_ADR for each ADC channel when PTW*_DATA_BLOCK_CNT1_REG      
           PTW1_RAM_ADR    : in std_logic_vector(11 downto 0);
           PTW1_RAM_DATA   : out std_logic_vector(16 downto 0);
           PTW2_RAM_ADR    : in std_logic_vector(11 downto 0);
           PTW2_RAM_DATA   : out std_logic_vector(16 downto 0);
           PTW3_RAM_ADR    : in std_logic_vector(11 downto 0);
           PTW3_RAM_DATA   : out std_logic_vector(16 downto 0);
           PTW4_RAM_ADR    : in std_logic_vector(11 downto 0);
           PTW4_RAM_DATA   : out std_logic_vector(16 downto 0);
           PTW5_RAM_ADR    : in std_logic_vector(11 downto 0);
           PTW5_RAM_DATA   : out std_logic_vector(16 downto 0);
           PTW6_RAM_ADR    : in std_logic_vector(11 downto 0);
           PTW6_RAM_DATA   : out std_logic_vector(16 downto 0)
--           PTW7_RAM_ADR    : in std_logic_vector(11 downto 0);
--           PTW7_RAM_DATA   : out std_logic_vector(16 downto 0);
--           PTW8_RAM_ADR    : in std_logic_vector(11 downto 0);
--           PTW8_RAM_DATA   : out std_logic_vector(16 downto 0);
--           PTW9_RAM_ADR    : in std_logic_vector(11 downto 0);
--           PTW9_RAM_DATA   : out std_logic_vector(16 downto 0);
--           PTW10_RAM_ADR    : in std_logic_vector(11 downto 0);
--           PTW10_RAM_DATA   : out std_logic_vector(16 downto 0);
--           PTW11_RAM_ADR    : in std_logic_vector(11 downto 0);
--           PTW11_RAM_DATA   : out std_logic_vector(16 downto 0);
--           PTW12_RAM_ADR    : in std_logic_vector(11 downto 0);
--           PTW12_RAM_DATA   : out std_logic_vector(16 downto 0);
--           PTW13_RAM_ADR    : in std_logic_vector(11 downto 0);
--           PTW13_RAM_DATA   : out std_logic_vector(16 downto 0);
--           PTW14_RAM_ADR    : in std_logic_vector(11 downto 0);
--           PTW14_RAM_DATA   : out std_logic_vector(16 downto 0);
--           PTW15_RAM_ADR    : in std_logic_vector(11 downto 0);
--           PTW15_RAM_DATA   : out std_logic_vector(16 downto 0);
--           PTW16_RAM_ADR    : in std_logic_vector(11 downto 0);
--           PTW16_RAM_DATA   : out std_logic_vector(16 downto 0)
        );
    end component; 

    component TIMESTAMP_TOP
        port
         (
           CLK                  : in std_logic;  -- 
           RESET_N              : in  std_logic;
           SYNC_RESET           : in std_logic;
           COLLECT_ON           : in std_logic;
           
           TIMESTAMP           : out std_logic_vector(47 downto 0) --  48 bits Counter
        );
    end component; 
    

    component TRIGGER_NUMBER_TOP
        port
         (
           CLK                  : in std_logic;  -- 
           RESET_N              : in  std_logic;
           SOFT_RESET_N         : in std_logic;           
           TRIGGER_N            : in std_logic;                      
           TRIGGER_NUMBER_REG   : out std_logic_vector(26 downto 0) --  27 bits Counter
        );
    end component; 

    component PROCESSING_ALL_VER2_TOP
        port
         (
           CLK_PROCESS          : in std_logic; 
           CLK_HOST             : in std_logic; 
           RESET_N              : in  std_logic;
           SOFT_RESET_N         : in std_logic;
           
           -- Common to all Channel
           MODE                 : in std_logic_vector(2 downto 0);  -- 0 -> copy entire PTW buffer to Host
                                                                    -- 1 -> copy NSB and NSA words from thredshold
                                                                    -- 2 -> compute sum of NSB and NSA words                                                                   -- 2 -> copy sum from mode 1
                                                                    -- 3 -> mode 0, 1, 2 run for each trigger
                                                                    -- 4 --> mode 1 and 2 run for each trigger                                                                  -- 2 -> copy sum from mode 1
           MAX_NUMBER_OF_PULSE  : in std_logic_vector(2 downto 0);  -- set the max number of pulse allowed per trigger
           MODE_TO_FORMAT        : out std_logic_vector(2 downto 0);
           PTW_TS_TN_WORDS       : in std_logic_vector(11 downto 0); -- PTW_WORDS + 3 (4 TimeStamp words + 2 TriggerNumber - 3 register delay)
           NSB                   : in std_logic_vector(8 downto 0);  -- Number of word before Thredshold to include. Min is 2
           --NSB_MINUS_2           : in std_logic_vector(11 downto 0);  --- minimum is 2
           NSA            : in std_logic_vector(8 downto 0); --- Number of sample to include after thredshold
           --NSA_MINUS7            : in std_logic_vector(12 downto 0); --- minimum is 4
           PTW_DAT_BUF_LAST_ADR  : in std_logic_VECTOR(11 downto 0);  --- The last address of the PTW data Buffer
           LAST_PROC_BUF_ADR : out std_logic_VECTOR(11 downto 0); -- Last address of Processing Buffer. To data format block

           Format_Idle   : in std_logic;

           -- Channel 0 **********************         
           CH0_DEC_PTW_CNT : out std_logic;  --- Rising egde decrease number of PTW Data Block ready to process by one.
           CH0_PTW_DATA_BLOCK_CNT : in std_logic_vector(7 downto 0);            
           CH0_HOST_BLOCK_CNT_REG : out std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
           CH0_DEC_BLOCK_CNT : in std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
           CH0_PTW_RAM_DATA   : in std_logic_vector(16 downto 0);
           CH0_PTW_RAM_ADR    : out std_logic_vector(11 downto 0);           
           ---- To DATA Format block
           CH0_PROC_ADR     : in std_logic_VECTOR(11 downto 0);
           CH0_PROC_OUTDAT  : out std_logic_VECTOR(17 downto 0);
           TET0             : in std_logic_VECTOR(11 downto 0);
           CH0_Fist_Last_Proc_Adr     : out std_logic_VECTOR(11 downto 0);
           CH0_Pop_Fist_Last_Proc_Adr : in std_logic;   --- rising edge pop next address out of FIFO

           -- Channel 1 **********************         
           CH1_DEC_PTW_CNT : out std_logic;  --- Rising egde decrease number of PTW Data Block ready to process by one.
           CH1_PTW_DATA_BLOCK_CNT : in std_logic_vector(7 downto 0);            
           CH1_HOST_BLOCK_CNT_REG : out std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
           CH1_DEC_BLOCK_CNT : in std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
           CH1_PTW_RAM_DATA   : in std_logic_vector(16 downto 0);
           CH1_PTW_RAM_ADR    : out std_logic_vector(11 downto 0);           
           ---- To DATA Format block
           CH1_PROC_ADR     : in std_logic_VECTOR(11 downto 0);
           CH1_PROC_OUTDAT  : out std_logic_VECTOR(17 downto 0);
           TET1             : in std_logic_VECTOR(11 downto 0);
           CH1_Fist_Last_Proc_Adr     : out std_logic_VECTOR(11 downto 0);
           CH1_Pop_Fist_Last_Proc_Adr : in std_logic;   --- rising edge pop next address out of FIFO

           -- Channel 2 **********************          
           CH2_DEC_PTW_CNT : out std_logic;  --- Rising egde decrease number of PTW Data Block ready to process by one.
           CH2_PTW_DATA_BLOCK_CNT : in std_logic_vector(7 downto 0);            
           CH2_HOST_BLOCK_CNT_REG : out std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
           CH2_DEC_BLOCK_CNT : in std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
           CH2_PTW_RAM_DATA   : in std_logic_vector(16 downto 0);
           CH2_PTW_RAM_ADR    : out std_logic_vector(11 downto 0);           
           ---- To DATA Format block
           CH2_PROC_ADR     : in std_logic_VECTOR(11 downto 0);
           CH2_PROC_OUTDAT  : out std_logic_VECTOR(17 downto 0);
           TET2             : in std_logic_VECTOR(11 downto 0);
           CH2_Fist_Last_Proc_Adr     : out std_logic_VECTOR(11 downto 0);
           CH2_Pop_Fist_Last_Proc_Adr : in std_logic;   --- rising edge pop next address out of FIFO

           -- Channel 3 **********************        
           CH3_DEC_PTW_CNT : out std_logic;  --- Rising egde decrease number of PTW Data Block ready to process by one.
           CH3_PTW_DATA_BLOCK_CNT : in std_logic_vector(7 downto 0);            
           CH3_HOST_BLOCK_CNT_REG : out std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
           CH3_DEC_BLOCK_CNT : in std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
           CH3_PTW_RAM_DATA   : in std_logic_vector(16 downto 0);
           CH3_PTW_RAM_ADR    : out std_logic_vector(11 downto 0);           
           ---- To DATA Format block
           CH3_PROC_ADR     : in std_logic_VECTOR(11 downto 0);
           CH3_PROC_OUTDAT  : out std_logic_VECTOR(17 downto 0);
           TET3             : in std_logic_VECTOR(11 downto 0);
           CH3_Fist_Last_Proc_Adr     : out std_logic_VECTOR(11 downto 0);
           CH3_Pop_Fist_Last_Proc_Adr : in std_logic;   --- rising edge pop next address out of FIFO

           -- Channel 4 **********************         
           CH4_DEC_PTW_CNT : out std_logic;  --- Rising egde decrease number of PTW Data Block ready to process by one.
           CH4_PTW_DATA_BLOCK_CNT : in std_logic_vector(7 downto 0);            
           CH4_HOST_BLOCK_CNT_REG : out std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
           CH4_DEC_BLOCK_CNT : in std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
           CH4_PTW_RAM_DATA   : in std_logic_vector(16 downto 0);
           CH4_PTW_RAM_ADR    : out std_logic_vector(11 downto 0);           
           ---- To DATA Format block
           CH4_PROC_ADR     : in std_logic_VECTOR(11 downto 0);
           CH4_PROC_OUTDAT  : out std_logic_VECTOR(17 downto 0);
           TET4             : in std_logic_VECTOR(11 downto 0);
           CH4_Fist_Last_Proc_Adr     : out std_logic_VECTOR(11 downto 0);
           CH4_Pop_Fist_Last_Proc_Adr : in std_logic;   --- rising edge pop next address out of FIFO

           -- Channel 5 **********************        
           CH5_DEC_PTW_CNT : out std_logic;  --- Rising egde decrease number of PTW Data Block ready to process by one.
           CH5_PTW_DATA_BLOCK_CNT : in std_logic_vector(7 downto 0);            
           CH5_HOST_BLOCK_CNT_REG : out std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
           CH5_DEC_BLOCK_CNT : in std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
           CH5_PTW_RAM_DATA   : in std_logic_vector(16 downto 0);
           CH5_PTW_RAM_ADR    : out std_logic_vector(11 downto 0);           
           ---- To DATA Format block
           CH5_PROC_ADR     : in std_logic_VECTOR(11 downto 0);
           CH5_PROC_OUTDAT  : out std_logic_VECTOR(17 downto 0);
           TET5             : in std_logic_VECTOR(11 downto 0);
           CH5_Fist_Last_Proc_Adr     : out std_logic_VECTOR(11 downto 0);
           CH5_Pop_Fist_Last_Proc_Adr : in std_logic;   --- rising edge pop next address out of FIFO

--           -- Channel 6 **********************        
--           CH6_DEC_PTW_CNT : out std_logic;  --- Rising egde decrease number of PTW Data Block ready to process by one.
--           CH6_PTW_DATA_BLOCK_CNT : in std_logic_vector(7 downto 0);            
--           CH6_HOST_BLOCK_CNT_REG : out std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
--           CH6_DEC_BLOCK_CNT : in std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
--           CH6_PTW_RAM_DATA   : in std_logic_vector(16 downto 0);
--           CH6_PTW_RAM_ADR    : out std_logic_vector(11 downto 0);           
--           ---- To DATA Format block
--           CH6_PROC_ADR     : in std_logic_VECTOR(11 downto 0);
--           CH6_PROC_OUTDAT  : out std_logic_VECTOR(17 downto 0);
--           TET6             : in std_logic_VECTOR(11 downto 0);
--           CH6_Fist_Last_Proc_Adr     : out std_logic_VECTOR(11 downto 0);
--           CH6_Pop_Fist_Last_Proc_Adr : in std_logic;   --- rising edge pop next address out of FIFO
--
--           -- Channel 7 **********************        
--           CH7_DEC_PTW_CNT : out std_logic;  --- Rising egde decrease number of PTW Data Block ready to process by one.
--           CH7_PTW_DATA_BLOCK_CNT : in std_logic_vector(7 downto 0);            
--           CH7_HOST_BLOCK_CNT_REG : out std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
--           CH7_DEC_BLOCK_CNT : in std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
--           CH7_PTW_RAM_DATA   : in std_logic_vector(16 downto 0);
--           CH7_PTW_RAM_ADR    : out std_logic_vector(11 downto 0);           
--           ---- To DATA Format block
--           CH7_PROC_ADR     : in std_logic_VECTOR(11 downto 0);
--           CH7_PROC_OUTDAT  : out std_logic_VECTOR(17 downto 0);                     
--           TET7             : in std_logic_VECTOR(11 downto 0);
--           CH7_Fist_Last_Proc_Adr     : out std_logic_VECTOR(11 downto 0);
--           CH7_Pop_Fist_Last_Proc_Adr : in std_logic;   --- rising edge pop next address out of FIFO
--
--           -- Channel 8 **********************         
--           CH8_DEC_PTW_CNT : out std_logic;  --- Rising egde decrease number of PTW Data Block ready to process by one.
--           CH8_PTW_DATA_BLOCK_CNT : in std_logic_vector(7 downto 0);            
--           CH8_HOST_BLOCK_CNT_REG : out std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
--           CH8_DEC_BLOCK_CNT : in std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
--           CH8_PTW_RAM_DATA   : in std_logic_vector(16 downto 0);
--           CH8_PTW_RAM_ADR    : out std_logic_vector(11 downto 0);           
--           ---- To DATA Format block
--           CH8_PROC_ADR     : in std_logic_VECTOR(11 downto 0);
--           CH8_PROC_OUTDAT  : out std_logic_VECTOR(17 downto 0);
--           TET8             : in std_logic_VECTOR(11 downto 0);
--           CH8_Fist_Last_Proc_Adr     : out std_logic_VECTOR(11 downto 0);
--           CH8_Pop_Fist_Last_Proc_Adr : in std_logic;   --- rising edge pop next address out of FIFO
--
--           -- Channel 9 **********************         
--           CH9_DEC_PTW_CNT : out std_logic;  --- Rising egde decrease number of PTW Data Block ready to process by one.
--           CH9_PTW_DATA_BLOCK_CNT : in std_logic_vector(7 downto 0);            
--           CH9_HOST_BLOCK_CNT_REG : out std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
--           CH9_DEC_BLOCK_CNT : in std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
--           CH9_PTW_RAM_DATA   : in std_logic_vector(16 downto 0);
--           CH9_PTW_RAM_ADR    : out std_logic_vector(11 downto 0);           
--           ---- To DATA Format block
--           CH9_PROC_ADR     : in std_logic_VECTOR(11 downto 0);
--           CH9_PROC_OUTDAT  : out std_logic_VECTOR(17 downto 0);
--           TET9             : in std_logic_VECTOR(11 downto 0);
--           CH9_Fist_Last_Proc_Adr     : out std_logic_VECTOR(11 downto 0);
--           CH9_Pop_Fist_Last_Proc_Adr : in std_logic;   --- rising edge pop next address out of FIFO
--
--           -- Channel 10**********************          
--           CH10_DEC_PTW_CNT : out std_logic;  --- Rising egde decrease number of PTW Data Block ready to process by one.
--           CH10_PTW_DATA_BLOCK_CNT : in std_logic_vector(7 downto 0);            
--           CH10_HOST_BLOCK_CNT_REG : out std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
--           CH10_DEC_BLOCK_CNT : in std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
--           CH10_PTW_RAM_DATA   : in std_logic_vector(16 downto 0);
--           CH10_PTW_RAM_ADR    : out std_logic_vector(11 downto 0);           
--           ---- To DATA Format block
--           CH10_PROC_ADR     : in std_logic_VECTOR(11 downto 0);
--           CH10_PROC_OUTDAT  : out std_logic_VECTOR(17 downto 0);
--           TET10             : in std_logic_VECTOR(11 downto 0);
--           CH10_Fist_Last_Proc_Adr     : out std_logic_VECTOR(11 downto 0);
--           CH10_Pop_Fist_Last_Proc_Adr : in std_logic;   --- rising edge pop next address out of FIFO
--
--           -- Channel 11 **********************        
--           CH11_DEC_PTW_CNT : out std_logic;  --- Rising egde decrease number of PTW Data Block ready to process by one.
--           CH11_PTW_DATA_BLOCK_CNT : in std_logic_vector(7 downto 0);            
--           CH11_HOST_BLOCK_CNT_REG : out std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
--           CH11_DEC_BLOCK_CNT : in std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
--           CH11_PTW_RAM_DATA   : in std_logic_vector(16 downto 0);
--           CH11_PTW_RAM_ADR    : out std_logic_vector(11 downto 0);           
--           ---- To DATA Format block
--           CH11_PROC_ADR     : in std_logic_VECTOR(11 downto 0);
--           CH11_PROC_OUTDAT  : out std_logic_VECTOR(17 downto 0);
--           TET11             : in std_logic_VECTOR(11 downto 0);
--           CH11_Fist_Last_Proc_Adr     : out std_logic_VECTOR(11 downto 0);
--           CH11_Pop_Fist_Last_Proc_Adr : in std_logic;   --- rising edge pop next address out of FIFO
--
--           -- Channel 12 **********************         
--           CH12_DEC_PTW_CNT : out std_logic;  --- Rising egde decrease number of PTW Data Block ready to process by one.
--           CH12_PTW_DATA_BLOCK_CNT : in std_logic_vector(7 downto 0);            
--           CH12_HOST_BLOCK_CNT_REG : out std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
--           CH12_DEC_BLOCK_CNT : in std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
--           CH12_PTW_RAM_DATA   : in std_logic_vector(16 downto 0);
--           CH12_PTW_RAM_ADR    : out std_logic_vector(11 downto 0);           
--           ---- To DATA Format block
--           CH12_PROC_ADR     : in std_logic_VECTOR(11 downto 0);
--           CH12_PROC_OUTDAT  : out std_logic_VECTOR(17 downto 0);
--           TET12             : in std_logic_VECTOR(11 downto 0);
--           CH12_Fist_Last_Proc_Adr     : out std_logic_VECTOR(11 downto 0);
--           CH12_Pop_Fist_Last_Proc_Adr : in std_logic;   --- rising edge pop next address out of FIFO
--
--           -- Channel 13 **********************        
--           CH13_DEC_PTW_CNT : out std_logic;  --- Rising egde decrease number of PTW Data Block ready to process by one.
--           CH13_PTW_DATA_BLOCK_CNT : in std_logic_vector(7 downto 0);            
--           CH13_HOST_BLOCK_CNT_REG : out std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
--           CH13_DEC_BLOCK_CNT : in std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
--           CH13_PTW_RAM_DATA   : in std_logic_vector(16 downto 0);
--           CH13_PTW_RAM_ADR    : out std_logic_vector(11 downto 0);           
--           ---- To DATA Format block
--           CH13_PROC_ADR     : in std_logic_VECTOR(11 downto 0);
--           CH13_PROC_OUTDAT  : out std_logic_VECTOR(17 downto 0);
--           TET13             : in std_logic_VECTOR(11 downto 0);
--           CH13_Fist_Last_Proc_Adr     : out std_logic_VECTOR(11 downto 0);
--           CH13_Pop_Fist_Last_Proc_Adr : in std_logic;   --- rising edge pop next address out of FIFO
--
--           -- Channel 14 **********************        
--           CH14_DEC_PTW_CNT : out std_logic;  --- Rising egde decrease number of PTW Data Block ready to process by one.
--           CH14_PTW_DATA_BLOCK_CNT : in std_logic_vector(7 downto 0);            
--           CH14_HOST_BLOCK_CNT_REG : out std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
--           CH14_DEC_BLOCK_CNT : in std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
--           CH14_PTW_RAM_DATA   : in std_logic_vector(16 downto 0);
--           CH14_PTW_RAM_ADR    : out std_logic_vector(11 downto 0);           
--           ---- To DATA Format block
--           CH14_PROC_ADR     : in std_logic_VECTOR(11 downto 0);
--           CH14_PROC_OUTDAT  : out std_logic_VECTOR(17 downto 0);
--           TET14             : in std_logic_VECTOR(11 downto 0);
--           CH14_Fist_Last_Proc_Adr     : out std_logic_VECTOR(11 downto 0);
--           CH14_Pop_Fist_Last_Proc_Adr : in std_logic;   --- rising edge pop next address out of FIFO
--
--           -- Channel 15 **********************        
--           CH15_DEC_PTW_CNT : out std_logic;  --- Rising egde decrease number of PTW Data Block ready to process by one.
--           CH15_PTW_DATA_BLOCK_CNT : in std_logic_vector(7 downto 0);            
--           CH15_HOST_BLOCK_CNT_REG : out std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
--           CH15_DEC_BLOCK_CNT : in std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
--           CH15_PTW_RAM_DATA   : in std_logic_vector(16 downto 0);
--           CH15_PTW_RAM_ADR    : out std_logic_vector(11 downto 0);           

           ---- To DATA Format block
           ModeFifoRdEn   : in std_logic;
           ModeFifoDout   : out std_logic_VECTOR(1 downto 0);
           ModeFifoEmpty  : out std_logic;
           ModeFifoFull   : out std_logic
			  
--           CH15_PROC_ADR     : in std_logic_VECTOR(11 downto 0);
--           CH15_PROC_OUTDAT  : out std_logic_VECTOR(17 downto 0);
--           TET15             : in std_logic_VECTOR(11 downto 0);
--           CH15_Fist_Last_Proc_Adr     : out std_logic_VECTOR(11 downto 0);
--           CH15_Pop_Fist_Last_Proc_Adr : in std_logic   --- rising edge pop next address out of FIFO

        );
    end component; 

    component DATAFORMAT_VER2_TOP
        port
         (
           CLK_HOST             : in std_logic; 
           RESET_N              : in  std_logic;
           SOFT_RESET_N         : in std_logic;
           
           ---- From Host
           PTW : in std_logic_vector(11 downto 0);
           COMBO_MODE : in std_logic;
           --MODE : in std_logic_vector(1 downto 0);
           LAST_PROC_BUF_ADR : in std_logic_VECTOR(11 downto 0); -- Last address of Processing Buffer
           NSA_NSB           : in std_logic_vector(9 downto 0); --- Sum of NSA and NSB
                      
           ---- From Process block
           Format_Idle   : out std_logic;
           ModeFifoRdEn   : out std_logic;
           ModeFifoDout   : in std_logic_VECTOR(1 downto 0);
           ModeFifoEmpty  : in std_logic;
           PROC0_ADR     : out std_logic_VECTOR(11 downto 0);
           PROC0_OUTDAT  : in std_logic_VECTOR(17 downto 0);
           PROC1_ADR     : out std_logic_VECTOR(11 downto 0);
           PROC1_OUTDAT  : in std_logic_VECTOR(17 downto 0);
           PROC2_ADR     : out std_logic_VECTOR(11 downto 0);
           PROC2_OUTDAT  : in std_logic_VECTOR(17 downto 0);
           PROC3_ADR     : out std_logic_VECTOR(11 downto 0);
           PROC3_OUTDAT  : in std_logic_VECTOR(17 downto 0);
           PROC4_ADR     : out std_logic_VECTOR(11 downto 0);
           PROC4_OUTDAT  : in std_logic_VECTOR(17 downto 0);
           PROC5_ADR     : out std_logic_VECTOR(11 downto 0);
           PROC5_OUTDAT  : in std_logic_VECTOR(17 downto 0);
--           PROC6_ADR     : out std_logic_VECTOR(11 downto 0);
--           PROC6_OUTDAT  : in std_logic_VECTOR(17 downto 0);
--           PROC7_ADR     : out std_logic_VECTOR(11 downto 0);
--           PROC7_OUTDAT  : in std_logic_VECTOR(17 downto 0);
--           PROC8_ADR     : out std_logic_VECTOR(11 downto 0);
--           PROC8_OUTDAT  : in std_logic_VECTOR(17 downto 0);
--           PROC9_ADR     : out std_logic_VECTOR(11 downto 0);
--           PROC9_OUTDAT  : in std_logic_VECTOR(17 downto 0);
--           PROC10_ADR     : out std_logic_VECTOR(11 downto 0);
--           PROC10_OUTDAT  : in std_logic_VECTOR(17 downto 0);
--           PROC11_ADR     : out std_logic_VECTOR(11 downto 0);
--           PROC11_OUTDAT  : in std_logic_VECTOR(17 downto 0);
--           PROC12_ADR     : out std_logic_VECTOR(11 downto 0);
--           PROC12_OUTDAT  : in std_logic_VECTOR(17 downto 0);
--           PROC13_ADR     : out std_logic_VECTOR(11 downto 0);
--           PROC13_OUTDAT  : in std_logic_VECTOR(17 downto 0);
--           PROC14_ADR     : out std_logic_VECTOR(11 downto 0);
--           PROC14_OUTDAT  : in std_logic_VECTOR(17 downto 0);
--           PROC15_ADR     : out std_logic_VECTOR(11 downto 0);
--           PROC15_OUTDAT  : in std_logic_VECTOR(17 downto 0);

           HOST_BLOCK0_CNT : in std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for host
           DEC_BLOCK0_CNT  : out std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one
           HOST_BLOCK1_CNT : in std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for host
           DEC_BLOCK1_CNT  : out std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one
           HOST_BLOCK2_CNT : in std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for host
           DEC_BLOCK2_CNT  : out std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one
           HOST_BLOCK3_CNT : in std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for host
           DEC_BLOCK3_CNT  : out std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one
           HOST_BLOCK4_CNT : in std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for host
           DEC_BLOCK4_CNT  : out std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one
           HOST_BLOCK5_CNT : in std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for host
           DEC_BLOCK5_CNT  : out std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one
--           HOST_BLOCK6_CNT : in std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for host
--           DEC_BLOCK6_CNT  : out std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one
--           HOST_BLOCK7_CNT : in std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for host
--           DEC_BLOCK7_CNT  : out std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one
--
--           HOST_BLOCK8_CNT : in std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for host
--           DEC_BLOCK8_CNT  : out std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one
--           HOST_BLOCK9_CNT : in std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for host
--           DEC_BLOCK9_CNT  : out std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one
--           HOST_BLOCK10_CNT : in std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for host
--           DEC_BLOCK10_CNT  : out std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one
--           HOST_BLOCK11_CNT : in std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for host
--           DEC_BLOCK11_CNT  : out std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one
--           HOST_BLOCK12_CNT : in std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for host
--           DEC_BLOCK12_CNT  : out std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one
--           HOST_BLOCK13_CNT : in std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for host
--           DEC_BLOCK13_CNT  : out std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one
--           HOST_BLOCK14_CNT : in std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for host
--           DEC_BLOCK14_CNT  : out std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one
--           HOST_BLOCK15_CNT : in std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for host
--           DEC_BLOCK15_CNT  : out std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one

           CH0_Fist_Last_Proc_Adr     : in  std_logic_VECTOR(11 downto 0);
           CH0_Pop_Fist_Last_Proc_Adr : out std_logic;   --- rising edge pop next address out of FIFO
           CH1_Fist_Last_Proc_Adr     : in   std_logic_VECTOR(11 downto 0);
           CH1_Pop_Fist_Last_Proc_Adr : out  std_logic;   --- rising edge pop next address out of FIFO
           CH2_Fist_Last_Proc_Adr     : in   std_logic_VECTOR(11 downto 0);
           CH2_Pop_Fist_Last_Proc_Adr : out  std_logic;   --- rising edge pop next address out of FIFO
           CH3_Fist_Last_Proc_Adr     : in   std_logic_VECTOR(11 downto 0);
           CH3_Pop_Fist_Last_Proc_Adr : out  std_logic;   --- rising edge pop next address out of FIFO
           CH4_Fist_Last_Proc_Adr     : in   std_logic_VECTOR(11 downto 0);
           CH4_Pop_Fist_Last_Proc_Adr : out  std_logic;   --- rising edge pop next address out of FIFO
           CH5_Fist_Last_Proc_Adr     : in   std_logic_VECTOR(11 downto 0);
           CH5_Pop_Fist_Last_Proc_Adr : out  std_logic;   --- rising edge pop next address out of FIFO
--           CH6_Fist_Last_Proc_Adr     : in   std_logic_VECTOR(11 downto 0);
--           CH6_Pop_Fist_Last_Proc_Adr : out  std_logic;   --- rising edge pop next address out of FIFO
--           CH7_Fist_Last_Proc_Adr     : in   std_logic_VECTOR(11 downto 0);
--           CH7_Pop_Fist_Last_Proc_Adr : out  std_logic;   --- rising edge pop next address out of FIFO
--
--           CH8_Fist_Last_Proc_Adr     : in  std_logic_vector(11 downto 0);
--           CH8_Pop_Fist_Last_Proc_Adr : out std_logic;   --- rising edge pop next address out of FIFO
--           CH9_Fist_Last_Proc_Adr     : in   std_logic_VECTOR(11 downto 0);
--           CH9_Pop_Fist_Last_Proc_Adr : out  std_logic;   --- rising edge pop next address out of FIFO
--           CH10_Fist_Last_Proc_Adr     : in   std_logic_VECTOR(11 downto 0);
--           CH10_Pop_Fist_Last_Proc_Adr : out  std_logic;   --- rising edge pop next address out of FIFO
--           CH11_Fist_Last_Proc_Adr     : in   std_logic_VECTOR(11 downto 0);
--           CH11_Pop_Fist_Last_Proc_Adr : out  std_logic;   --- rising edge pop next address out of FIFO
--           CH12_Fist_Last_Proc_Adr     : in   std_logic_VECTOR(11 downto 0);
--           CH12_Pop_Fist_Last_Proc_Adr : out  std_logic;   --- rising edge pop next address out of FIFO
--           CH13_Fist_Last_Proc_Adr     : in   std_logic_VECTOR(11 downto 0);
--           CH13_Pop_Fist_Last_Proc_Adr : out  std_logic;   --- rising edge pop next address out of FIFO
--           CH14_Fist_Last_Proc_Adr     : in   std_logic_VECTOR(11 downto 0);
--           CH14_Pop_Fist_Last_Proc_Adr : out  std_logic;   --- rising edge pop next address out of FIFO
--           CH15_Fist_Last_Proc_Adr     : in   std_logic_VECTOR(11 downto 0);
--           CH15_Pop_Fist_Last_Proc_Adr : out  std_logic;   --- rising edge pop next address out of FIFO

           --- To Host FIFO IDT72V36100 pins
			  cid								 : in  std_logic_vector(3 downto 0);
           DATA_REG                  : out std_logic_vector(35 downto 0); 
           WCLK_REG                  : out std_logic; -- Write Clock
           WEN_REG                   : out std_logic; -- Write EN
           OE_N_REG                  : out std_logic -- output enable                     
        );
    end component; 

    --component SUM_VER2_TOP
    --    port
    --     (
    --       CLK                  : in std_logic;  -- 
    --       RESET_N              : in  std_logic;
    --
    --       ADC0_IN               : in std_logic_vector(11 downto 0);           
    --       ADC1_IN               : in std_logic_vector(11 downto 0);           
    --      ADC2_IN               : in std_logic_vector(11 downto 0);           
    --       ADC3_IN               : in std_logic_vector(11 downto 0);           
    --       ADC4_IN               : in std_logic_vector(11 downto 0);           
    --       ADC5_IN               : in std_logic_vector(11 downto 0);           
    --       ADC6_IN               : in std_logic_vector(11 downto 0);           
    --       ADC7_IN               : in std_logic_vector(11 downto 0);           
    --
    --       ADC8_IN                : in std_logic_vector(11 downto 0);           
    --       ADC9_IN                : in std_logic_vector(11 downto 0);           
    --       ADC10_IN               : in std_logic_vector(11 downto 0);           
    --       ADC11_IN               : in std_logic_vector(11 downto 0);           
    --       ADC12_IN               : in std_logic_vector(11 downto 0);           
    --       ADC13_IN               : in std_logic_vector(11 downto 0);           
    --       ADC14_IN               : in std_logic_vector(11 downto 0);           
    --       ADC15_IN               : in std_logic_vector(11 downto 0);           
    --
    --       ----- Pedestal Subtraction
    --        PedSub0            : in  std_logic_vector (15 downto 0);
    --        PedSub1            : in  std_logic_vector (15 downto 0);
    --        PedSub2            : in  std_logic_vector (15 downto 0);
    --        PedSub3            : in  std_logic_vector (15 downto 0);
    --        PedSub4            : in  std_logic_vector (15 downto 0);
    --        PedSub5            : in  std_logic_vector (15 downto 0);
    --        PedSub6            : in  std_logic_vector (15 downto 0);
    --        PedSub7            : in  std_logic_vector (15 downto 0);
    --        PedSub8            : in  std_logic_vector (15 downto 0);
    --        PedSub9            : in  std_logic_vector (15 downto 0);
    --        PedSub10           : in std_logic_vector (15 downto 0);
    --        PedSub11           : in std_logic_vector (15 downto 0);
    --        PedSub12           : in std_logic_vector (15 downto 0);
    --        PedSub13           : in std_logic_vector (15 downto 0);
    --        PedSub14           : in std_logic_vector (15 downto 0);
    --        PedSub15           : in std_logic_vector (15 downto 0);
    --                
    --       SUM                   : out std_logic_vector(15 downto 0);
    --       SUM_B                 : out std_logic_vector(15 downto 0);
    --       SUMP2_DV               : out std_logic;
    --       SUMN2_DV               : out std_logic;
    --       SUM_REG               : out std_logic_vector(15 downto 0)
    --   );
    --end component; 

--    component TriggerProcessing_TOP                            
--      port                                           
--         (                                             
--           CLK      : in std_logic;   --- 250 MHz      
--           RESET_N  : in std_logic;
--                                                                                             
--           SYNC        : in std_logic;
--           NSB         : in std_logic_vector(3 downto 0);  -- Delay SampleIN by this number of CLK 
--           ThresholdValue  : in std_logic_vector(11 downto 0);   --- From Host Register.
--           NSA         : in std_logic_vector(5 downto 0);     ----   
--
--           ADC0_IN               : in std_logic_vector(11 downto 0);           
--           ADC1_IN               : in std_logic_vector(11 downto 0);           
--           ADC2_IN               : in std_logic_vector(11 downto 0);           
--           ADC3_IN               : in std_logic_vector(11 downto 0);           
--           ADC4_IN               : in std_logic_vector(11 downto 0);           
--           ADC5_IN               : in std_logic_vector(11 downto 0);           
----           ADC6_IN               : in std_logic_vector(11 downto 0);           
----           ADC7_IN               : in std_logic_vector(11 downto 0);           
----           ADC8_IN                : in std_logic_vector(11 downto 0);           
----           ADC9_IN                : in std_logic_vector(11 downto 0);           
----           ADC10_IN               : in std_logic_vector(11 downto 0);           
----           ADC11_IN               : in std_logic_vector(11 downto 0);           
----           ADC12_IN               : in std_logic_vector(11 downto 0);           
----           ADC13_IN               : in std_logic_vector(11 downto 0);           
----           ADC14_IN               : in std_logic_vector(11 downto 0);           
----           ADC15_IN               : in std_logic_vector(11 downto 0);           
--
--           ----- Pedestal Subtraction
--            PedSub0            : in  std_logic_vector (11 downto 0);
--            PedSub1            : in  std_logic_vector (11 downto 0);
--            PedSub2            : in  std_logic_vector (11 downto 0);
--            PedSub3            : in  std_logic_vector (11 downto 0);
--            PedSub4            : in  std_logic_vector (11 downto 0);
--            PedSub5            : in  std_logic_vector (11 downto 0);
----            PedSub6            : in  std_logic_vector (11 downto 0);
----            PedSub7            : in  std_logic_vector (11 downto 0);
----            PedSub8            : in  std_logic_vector (11 downto 0);
----            PedSub9            : in  std_logic_vector (11 downto 0);
----            PedSub10           : in std_logic_vector (11 downto 0);
----            PedSub11           : in std_logic_vector (11 downto 0);
----            PedSub12           : in std_logic_vector (11 downto 0);
----            PedSub13           : in std_logic_vector (11 downto 0);
----            PedSub14           : in std_logic_vector (11 downto 0);
----            PedSub15           : in std_logic_vector (11 downto 0);
--           
--           SUM                   : out std_logic_vector(15 downto 0);
--           SUM_B                 : out std_logic_vector(15 downto 0);
--           SUMP2_DV               : out std_logic;
--           SUMN2_DV               : out std_logic
--           --SUM_REG  : out std_logic_vector(15 downto 0)
--        );
--    end component;

--    component HIT_BITS_ALL_VER2_TOP
--        port
--         (
--           CLK                  : in std_logic;  -- 
--           RESET_N              : in  std_logic;
-- 
--           --- Data From 8 ADC. Each consist of 12 data bits
--           ADC1_DATA            : in std_logic_vector(11 downto 0);  
--           ADC2_DATA            : in std_logic_vector(11 downto 0);  
--           ADC3_DATA            : in std_logic_vector(11 downto 0);  
--           ADC4_DATA            : in std_logic_vector(11 downto 0); 
--           ADC5_DATA            : in std_logic_vector(11 downto 0); 
--           ADC6_DATA            : in std_logic_vector(11 downto 0); 
----           ADC7_DATA            : in std_logic_vector(11 downto 0); 
----           ADC8_DATA            : in std_logic_vector(11 downto 0); 
----           ADC9_DATA            : in std_logic_vector(11 downto 0);  
----           ADC10_DATA            : in std_logic_vector(11 downto 0);  
----           ADC11_DATA            : in std_logic_vector(11 downto 0);  
----           ADC12_DATA            : in std_logic_vector(11 downto 0); 
----           ADC13_DATA            : in std_logic_vector(11 downto 0); 
----           ADC14_DATA            : in std_logic_vector(11 downto 0); 
----           ADC15_DATA            : in std_logic_vector(11 downto 0); 
----           ADC16_DATA            : in std_logic_vector(11 downto 0); 
--           
--           --- Trigger Thredshold. From Host
--           TET0             : in std_logic_VECTOR(11 downto 0);
--           TET1             : in std_logic_VECTOR(11 downto 0);
--           TET2             : in std_logic_VECTOR(11 downto 0);
--           TET3             : in std_logic_VECTOR(11 downto 0);
--           TET4             : in std_logic_VECTOR(11 downto 0);
--           TET5             : in std_logic_VECTOR(11 downto 0);
----           TET6             : in std_logic_VECTOR(11 downto 0);
----           TET7             : in std_logic_VECTOR(11 downto 0);
----           TET8             : in std_logic_VECTOR(11 downto 0);
----           TET9             : in std_logic_VECTOR(11 downto 0);
----           TET10            : in std_logic_VECTOR(11 downto 0);
----           TET11            : in std_logic_VECTOR(11 downto 0);
----           TET12            : in std_logic_VECTOR(11 downto 0);
----           TET13            : in std_logic_VECTOR(11 downto 0);
----           TET14            : in std_logic_VECTOR(11 downto 0);
----           TET15            : in std_logic_VECTOR(11 downto 0);
--                      
--           HITBIT_DV_REG    : out std_logic;
--           HITBIT_N_REG     : out std_logic_vector(15 downto 0)
--           --HIT_BIT_N         : out std_logic_vector(15 downto 0);
--           --HIT_BIT_N_B       : out std_logic_vector(15 downto 0)
--        );
--    end component; 

  component IBUFDS
        generic
         (
            IOSTANDARD : string := "LVDS_25"; 
             DIFF_TERM  : boolean := TRUE
             --DIFF_TERM  : boolean := FALSE
        );
        port
         (
           I                  : in  std_logic;   -- To top level port
           IB                  : in  std_logic;
           O                 : out  std_logic   -- To design  
         );
  end component;

  component LVDS_IN_REG_1bit
        port
         (
           CLK                    : in std_logic;
           INSINGLE               : in std_logic;
           INSINGLE_B             : in std_logic;
           OUT_REG                : out std_logic
         );
  end component;

  component OBUFDS
        port
         (
           I                  : in  std_logic;   -- To top level port
           O                  : out  std_logic;
           OB                 : out  std_logic   -- To design  
         );
  end component;

  component BUFG
	port
	(
		O : out std_ulogic;
		I : in std_ulogic
	);
  end component;

    signal GND_BUS : std_logic_vector(15 downto 0);
    signal STATUS : std_logic_vector(15 downto 0);

    signal RESET                 : std_logic;
    
    signal TRIGGER_N_D : std_logic;
    signal TRIGGER_N_Q : std_logic;
    signal TRIGGER_N_DLY_D : std_logic;
    signal TRIGGER_N_DLY_Q : std_logic;
    signal TRIGGER_NUMBER   : std_logic_vector(26 downto 0);
    signal PTRIGGER_N : std_logic;
    
    ---- ADC Channels  ------------------------------------------------------------------------------
    signal ADC_RAWDATA_1          : std_logic_vector(12 downto 0);  --
    signal ADC_OVFL_1             : std_logic;
    signal ADC_CLK_1              : std_logic;
    signal ADC_DATA_1_D             : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
    signal ADC_DATA_1_Q             : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
    signal ADC_RAWDATA_2          : std_logic_vector(12 downto 0);  --
    signal ADC_OVFL_2             : std_logic;
    signal ADC_CLK_2              : std_logic;
    signal ADC_DATA_2_D             : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
    signal ADC_DATA_2_Q             : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
    signal ADC_RAWDATA_3          : std_logic_vector(12 downto 0);  --
    signal ADC_OVFL_3             : std_logic;
    signal ADC_CLK_3              : std_logic;
    signal ADC_DATA_3_D            : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
    signal ADC_DATA_3_Q             : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
    signal ADC_RAWDATA_4          : std_logic_vector(12 downto 0);  --
    signal ADC_OVFL_4             : std_logic;
    signal ADC_CLK_4              : std_logic;
    signal ADC_DATA_4_D            : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
    signal ADC_DATA_4_Q             : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
    signal ADC_RAWDATA_5          : std_logic_vector(12 downto 0);  --
    signal ADC_OVFL_5             : std_logic;
    signal ADC_CLK_5              : std_logic;
    --signal ADC_DATA_5             : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
    signal ADC_DATA_5_D            : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
    signal ADC_DATA_5_Q             : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
    signal ADC_RAWDATA_6          : std_logic_vector(12 downto 0);  --
    signal ADC_OVFL_6             : std_logic;
    signal ADC_CLK_6              : std_logic;
    --signal ADC_DATA_6             : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
    signal ADC_DATA_6_D            : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
    signal ADC_DATA_6_Q             : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
--    signal ADC_RAWDATA_7          : std_logic_vector(12 downto 0);  --
--    signal ADC_OVFL_7             : std_logic;
--    signal ADC_CLK_7              : std_logic;
--    --signal ADC_DATA_7             : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
--    signal ADC_DATA_7_D            : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
--    signal ADC_DATA_7_Q             : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
--
--    signal ADC_RAWDATA_8          : std_logic_vector(12 downto 0);  --
--    signal ADC_OVFL_8             : std_logic;
--    signal ADC_CLK_8              : std_logic;
--    signal ADC_DATA_8_D            : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
--    signal ADC_DATA_8_Q             : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
--
--    signal ADC_RAWDATA_9          : std_logic_vector(12 downto 0);  --
--    signal ADC_OVFL_9             : std_logic;
--    signal ADC_CLK_9              : std_logic;
--    signal ADC_DATA_9_D             : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
--    signal ADC_DATA_9_Q             : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
--
--    signal ADC_RAWDATA_10         : std_logic_vector(12 downto 0);  --
--    signal ADC_OVFL_10            : std_logic;
--    signal ADC_CLK_10             : std_logic;
--    signal ADC_DATA_10_D             : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
--    signal ADC_DATA_10_Q             : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
--
--    signal ADC_RAWDATA_11          : std_logic_vector(12 downto 0);  --
--    signal ADC_OVFL_11             : std_logic;
--    signal ADC_CLK_11              : std_logic;
--    signal ADC_DATA_11_D            : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
--    signal ADC_DATA_11_Q             : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
--
--    signal ADC_RAWDATA_12          : std_logic_vector(12 downto 0);  --
--    signal ADC_OVFL_12             : std_logic;
--    signal ADC_CLK_12              : std_logic;
--    signal ADC_DATA_12_D            : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
--    signal ADC_DATA_12_Q             : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
--
--    signal ADC_RAWDATA_13          : std_logic_vector(12 downto 0);  --
--    signal ADC_OVFL_13             : std_logic;
--    signal ADC_CLK_13              : std_logic;
--    signal ADC_DATA_13_D            : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
--    signal ADC_DATA_13_Q             : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
--
--    signal ADC_RAWDATA_14          : std_logic_vector(12 downto 0);  --
--    signal ADC_OVFL_14             : std_logic;
--    signal ADC_CLK_14              : std_logic;
--    signal ADC_DATA_14_D            : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
--    signal ADC_DATA_14_Q             : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
--
--    signal ADC_RAWDATA_15          : std_logic_vector(12 downto 0);  --
--    signal ADC_OVFL_15             : std_logic;
--    signal ADC_CLK_15              : std_logic;
--    signal ADC_DATA_15_D            : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
--    signal ADC_DATA_15_Q             : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
--
--    signal ADC_RAWDATA_16          : std_logic_vector(12 downto 0);  --
--    signal ADC_OVFL_16             : std_logic;
--    signal ADC_CLK_16              : std_logic;
--    signal ADC_DATA_16_D            : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits
--    signal ADC_DATA_16_Q             : std_logic_vector(12 downto 0);  -- 1 overflow and 12 data bits

    ------ DATA BUFFER
    signal TIMESTAMP           : std_logic_vector(47 downto 0); --  48 bits Counter
    signal DEC_PTW_CNT1        : std_logic;  --- Rising egde decrease number of PTW Data Block ready to process by one.
    signal DEC_PTW_CNT2        : std_logic;  
    signal DEC_PTW_CNT3        : std_logic;  
    signal DEC_PTW_CNT4        : std_logic;  
    signal DEC_PTW_CNT5        : std_logic;  
    signal DEC_PTW_CNT6        : std_logic;  
--    signal DEC_PTW_CNT7        : std_logic;  
--    signal DEC_PTW_CNT8        : std_logic;  
--    signal DEC_PTW_CNT9        : std_logic;  --- Rising egde decrease number of PTW Data Block ready to process by one.
--    signal DEC_PTW_CNT10       : std_logic;  
--    signal DEC_PTW_CNT11       : std_logic;  
--    signal DEC_PTW_CNT12       : std_logic;  
--    signal DEC_PTW_CNT13       : std_logic;  
--    signal DEC_PTW_CNT14       : std_logic;  
--    signal DEC_PTW_CNT15       : std_logic;  
--    signal DEC_PTW_CNT16       : std_logic;  
    signal PTW_DATA_BLOCK_CNT1 : std_logic_vector(7 downto 0);  --- Provide the number of PTW Data Blocks ready for processing
    signal PTW_DATA_BLOCK_CNT2 : std_logic_vector(7 downto 0);
    signal PTW_DATA_BLOCK_CNT3 : std_logic_vector(7 downto 0);  
    signal PTW_DATA_BLOCK_CNT4 : std_logic_vector(7 downto 0);  
    signal PTW_DATA_BLOCK_CNT5 : std_logic_vector(7 downto 0);  
    signal PTW_DATA_BLOCK_CNT6 : std_logic_vector(7 downto 0);  
--    signal PTW_DATA_BLOCK_CNT7 : std_logic_vector(7 downto 0);  
--    signal PTW_DATA_BLOCK_CNT8 : std_logic_vector(7 downto 0);  
--    signal PTW_DATA_BLOCK_CNT9 : std_logic_vector(7 downto 0);  --- Provide the number of PTW Data Blocks ready for processing
--    signal PTW_DATA_BLOCK_CNT10 : std_logic_vector(7 downto 0);
--    signal PTW_DATA_BLOCK_CNT11 : std_logic_vector(7 downto 0);  
--    signal PTW_DATA_BLOCK_CNT12 : std_logic_vector(7 downto 0);  
--    signal PTW_DATA_BLOCK_CNT13 : std_logic_vector(7 downto 0);  
--    signal PTW_DATA_BLOCK_CNT14 : std_logic_vector(7 downto 0);  
--    signal PTW_DATA_BLOCK_CNT15 : std_logic_vector(7 downto 0);  
--    signal PTW_DATA_BLOCK_CNT16 : std_logic_vector(7 downto 0);  
    signal PTW_BUFFER_OVERRUN1 :  std_logic;  --- Set when PTW_DATA_BLOCK_CNT_REG overflow. SOFT_RESET_N reset.
    signal PTW_BUFFER_OVERRUN2 :  std_logic;
    signal PTW_BUFFER_OVERRUN3 :  std_logic;
    signal PTW_BUFFER_OVERRUN4 :  std_logic;
    signal PTW_BUFFER_OVERRUN5 :  std_logic;
    signal PTW_BUFFER_OVERRUN6 :  std_logic;
--    signal PTW_BUFFER_OVERRUN7 :  std_logic;
--    signal PTW_BUFFER_OVERRUN8 :  std_logic;
--    signal PTW_BUFFER_OVERRUN9 :  std_logic;  --- Set when PTW_DATA_BLOCK_CNT_REG overflow. SOFT_RESET_N reset.
--    signal PTW_BUFFER_OVERRUN10 :  std_logic;
--    signal PTW_BUFFER_OVERRUN11 :  std_logic;
--    signal PTW_BUFFER_OVERRUN12 :  std_logic;
--    signal PTW_BUFFER_OVERRUN13 :  std_logic;
--    signal PTW_BUFFER_OVERRUN14 :  std_logic;
--    signal PTW_BUFFER_OVERRUN15 :  std_logic;
--    signal PTW_BUFFER_OVERRUN16 :  std_logic;
    signal RAW_BUFFER_OVERRUN1 :  std_logic;  --- Set when Trigger Rate is faster than the ADC data rate. SOFT_RESET_N reset.
    signal RAW_BUFFER_OVERRUN2 :  std_logic;
    signal RAW_BUFFER_OVERRUN3 :  std_logic;
    signal RAW_BUFFER_OVERRUN4 :  std_logic;
    signal RAW_BUFFER_OVERRUN5 :  std_logic;
    signal RAW_BUFFER_OVERRUN6 :  std_logic;
--    signal RAW_BUFFER_OVERRUN7 :  std_logic;
--    signal RAW_BUFFER_OVERRUN8 :  std_logic;
--    signal RAW_BUFFER_OVERRUN9 :  std_logic;  --- Set when Trigger Rate is faster than the ADC data rate. SOFT_RESET_N reset.
--    signal RAW_BUFFER_OVERRUN10 :  std_logic;
--    signal RAW_BUFFER_OVERRUN11 :  std_logic;
--    signal RAW_BUFFER_OVERRUN12 :  std_logic;
--    signal RAW_BUFFER_OVERRUN13 :  std_logic;
--    signal RAW_BUFFER_OVERRUN14 :  std_logic;
--    signal RAW_BUFFER_OVERRUN15 :  std_logic;
--    signal RAW_BUFFER_OVERRUN16 :  std_logic;
             
    ----- Control Bus
    signal PTW_WORDS_MINUS_ONE_D  : std_logic_vector(8 downto 0);  -- Use to mark the end of PTW data words
    signal PTW_WORDS_MINUS_ONE_Q  : std_logic_vector(8 downto 0);  -- Use to mark the end of PTW data words
    signal SYS_STATUS0_D   : std_logic_vector(15 downto 0);
    signal SYS_STATUS0_Q   : std_logic_vector(15 downto 0);
    signal SYS_STATUS1_D   : std_logic_vector(15 downto 0);
    signal SYS_STATUS1_Q   : std_logic_vector(15 downto 0);
    signal SYS_STATUS2_D   : std_logic_vector(15 downto 0);
    signal SYS_STATUS2_Q   : std_logic_vector(15 downto 0);
    signal SYS_STATUS3_D   : std_logic_vector(15 downto 0);
    signal SYS_STATUS3_Q   : std_logic_vector(15 downto 0);
    signal NSA_D        :  std_logic_vector(8 downto 0);
    signal NSA_Q        :  std_logic_vector(8 downto 0);
    signal PTW0_RAM_ADR    : std_logic_vector(11 downto 0);
    signal PTW0_RAM_DATA   : std_logic_vector(16 downto 0);
    signal PTW1_RAM_ADR    : std_logic_vector(11 downto 0);
    signal PTW1_RAM_DATA   : std_logic_vector(16 downto 0);
    signal PTW2_RAM_ADR    : std_logic_vector(11 downto 0);
    signal PTW2_RAM_DATA   : std_logic_vector(16 downto 0);
    signal PTW3_RAM_ADR    : std_logic_vector(11 downto 0);
    signal PTW3_RAM_DATA   : std_logic_vector(16 downto 0);
    signal PTW4_RAM_ADR    : std_logic_vector(11 downto 0);
    signal PTW4_RAM_DATA   : std_logic_vector(16 downto 0);
    signal PTW5_RAM_ADR    : std_logic_vector(11 downto 0);
    signal PTW5_RAM_DATA   : std_logic_vector(16 downto 0);
--    signal PTW6_RAM_ADR    : std_logic_vector(11 downto 0);
--    signal PTW6_RAM_DATA   : std_logic_vector(16 downto 0);
--    signal PTW7_RAM_ADR    : std_logic_vector(11 downto 0);
--    signal PTW7_RAM_DATA   : std_logic_vector(16 downto 0);
--    signal PTW8_RAM_ADR    : std_logic_vector(11 downto 0);
--    signal PTW8_RAM_DATA   : std_logic_vector(16 downto 0);
--    signal PTW9_RAM_ADR    : std_logic_vector(11 downto 0);
--    signal PTW9_RAM_DATA   : std_logic_vector(16 downto 0);
--    signal PTW10_RAM_ADR    : std_logic_vector(11 downto 0);
--    signal PTW10_RAM_DATA   : std_logic_vector(16 downto 0);
--    signal PTW11_RAM_ADR    : std_logic_vector(11 downto 0);
--    signal PTW11_RAM_DATA   : std_logic_vector(16 downto 0);
--    signal PTW12_RAM_ADR    : std_logic_vector(11 downto 0);
--    signal PTW12_RAM_DATA   : std_logic_vector(16 downto 0);
--    signal PTW13_RAM_ADR    : std_logic_vector(11 downto 0);
--    signal PTW13_RAM_DATA   : std_logic_vector(16 downto 0);
--    signal PTW14_RAM_ADR    : std_logic_vector(11 downto 0);
--    signal PTW14_RAM_DATA   : std_logic_vector(16 downto 0);
--    signal PTW15_RAM_ADR    : std_logic_vector(11 downto 0);
--    signal PTW15_RAM_DATA   : std_logic_vector(16 downto 0);
        
    ---- PROCESS BLOCK
    signal MODE            : std_logic_vector(2 downto 0);  -- 0 -> copy entire PTW buffer to Host
    signal PTW_TS_TN_WORDS_D       : std_logic_vector(11 downto 0); -- PTW_WORDS + 3 (4 TimeStamp words + 2 TriggerNumber - 3 register delay)
    signal PTW_TS_TN_WORDS_Q       : std_logic_vector(11 downto 0); -- PTW_WORDS + 3 (4 TimeStamp words + 2 TriggerNumber - 3 register delay)
    --signal NSB_MINUS_2_D           : std_logic_vector(11 downto 0);  --- minimum is 2
    --signal NSB_MINUS_2_Q           : std_logic_vector(11 downto 0);  --- minimum is 2
    --signal NSA_MINUS7_D            : std_logic_vector(12 downto 0); --- minimum is 4
    --signal NSA_MINUS7_Q            : std_logic_vector(12 downto 0); --- minimum is 4
    signal CH0_HOST_BLOCK_CNT : std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
    signal CH1_HOST_BLOCK_CNT : std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
    signal CH2_HOST_BLOCK_CNT : std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
    signal CH3_HOST_BLOCK_CNT : std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
    signal CH4_HOST_BLOCK_CNT : std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
    signal CH5_HOST_BLOCK_CNT : std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
--    signal CH6_HOST_BLOCK_CNT : std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
--    signal CH7_HOST_BLOCK_CNT : std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
--    signal CH8_HOST_BLOCK_CNT : std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
--    signal CH9_HOST_BLOCK_CNT : std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
--    signal CH10_HOST_BLOCK_CNT : std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
--    signal CH11_HOST_BLOCK_CNT : std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
--    signal CH12_HOST_BLOCK_CNT : std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
--    signal CH13_HOST_BLOCK_CNT : std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
--    signal CH14_HOST_BLOCK_CNT : std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
--    signal CH15_HOST_BLOCK_CNT : std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
    signal CH0_DEC_BLOCK_CNT  : std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
    signal CH1_DEC_BLOCK_CNT  : std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
    signal CH2_DEC_BLOCK_CNT  : std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
    signal CH3_DEC_BLOCK_CNT  : std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
    signal CH4_DEC_BLOCK_CNT  : std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
    signal CH5_DEC_BLOCK_CNT  : std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
--    signal CH6_DEC_BLOCK_CNT  : std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
--    signal CH7_DEC_BLOCK_CNT  : std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
--    signal CH8_DEC_BLOCK_CNT  : std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
--    signal CH9_DEC_BLOCK_CNT  : std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
--    signal CH10_DEC_BLOCK_CNT  : std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
--    signal CH11_DEC_BLOCK_CNT  : std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
--    signal CH12_DEC_BLOCK_CNT  : std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
--    signal CH13_DEC_BLOCK_CNT  : std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
--    signal CH14_DEC_BLOCK_CNT  : std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
--    signal CH15_DEC_BLOCK_CNT  : std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
    signal LAST_PROC_BUF_ADR  : std_logic_VECTOR(11 downto 0); -- Last address of Processing Buffer. To data format block
    signal CH0_PROC_ADR     : std_logic_VECTOR(11 downto 0);
    signal CH0_PROC_OUTDAT  : std_logic_VECTOR(17 downto 0);
    signal CH1_PROC_ADR     : std_logic_VECTOR(11 downto 0);
    signal CH1_PROC_OUTDAT  : std_logic_VECTOR(17 downto 0);
    signal CH2_PROC_ADR     : std_logic_VECTOR(11 downto 0);
    signal CH2_PROC_OUTDAT  : std_logic_VECTOR(17 downto 0);
    signal CH3_PROC_ADR     : std_logic_VECTOR(11 downto 0);
    signal CH3_PROC_OUTDAT  : std_logic_VECTOR(17 downto 0);
    signal CH4_PROC_ADR     : std_logic_VECTOR(11 downto 0);
    signal CH4_PROC_OUTDAT  : std_logic_VECTOR(17 downto 0);
    signal CH5_PROC_ADR     : std_logic_VECTOR(11 downto 0);
    signal CH5_PROC_OUTDAT  : std_logic_VECTOR(17 downto 0);
--    signal CH6_PROC_ADR     : std_logic_VECTOR(11 downto 0);
--    signal CH6_PROC_OUTDAT  : std_logic_VECTOR(17 downto 0);
--    signal CH7_PROC_ADR     : std_logic_VECTOR(11 downto 0);
--    signal CH7_PROC_OUTDAT  : std_logic_VECTOR(17 downto 0);
--    signal CH8_PROC_ADR     : std_logic_VECTOR(11 downto 0);
--    signal CH8_PROC_OUTDAT  : std_logic_VECTOR(17 downto 0);
--    signal CH9_PROC_ADR     : std_logic_VECTOR(11 downto 0);
--    signal CH9_PROC_OUTDAT  : std_logic_VECTOR(17 downto 0);
--    signal CH10_PROC_ADR     : std_logic_VECTOR(11 downto 0);
--    signal CH10_PROC_OUTDAT  : std_logic_VECTOR(17 downto 0);
--    signal CH11_PROC_ADR     : std_logic_VECTOR(11 downto 0);
--    signal CH11_PROC_OUTDAT  : std_logic_VECTOR(17 downto 0);
--    signal CH12_PROC_ADR     : std_logic_VECTOR(11 downto 0);
--    signal CH12_PROC_OUTDAT  : std_logic_VECTOR(17 downto 0);
--    signal CH13_PROC_ADR     : std_logic_VECTOR(11 downto 0);
--    signal CH13_PROC_OUTDAT  : std_logic_VECTOR(17 downto 0);
--    signal CH14_PROC_ADR     : std_logic_VECTOR(11 downto 0);
--    signal CH14_PROC_OUTDAT  : std_logic_VECTOR(17 downto 0);
--    signal CH15_PROC_ADR     : std_logic_VECTOR(11 downto 0);
--    signal CH15_PROC_OUTDAT  : std_logic_VECTOR(17 downto 0);
    signal COLLECT_ON_D          : std_logic;
    signal COLLECT_ON_Q          : std_logic;
    --signal NSA_MINUS1_D          : std_logic_vector(12 downto 0); --- Number of sample to include after thredshold
    --signal NSA_MINUS1_Q          : std_logic_vector(12 downto 0); --- Number of sample to include after thredshold
    signal MAX_NUMBER_OF_PULSE  : std_logic_vector(2 downto 0);  -- set the max number of pulse allowed per trigger

    --- Data Format 
    signal COMBO_MODE :  std_logic;	
	signal O_NSA, O_NSB        : std_logic_vector(9 downto 0);
    signal NSA_NSB_D           : std_logic_vector(9 downto 0); --- Sum of NSA and NSB
    signal NSA_NSB_Q           : std_logic_vector(9 downto 0); --- Sum of NSA and NSB
    signal Format_Idle         : std_logic;
    
    signal TRIGGER_D             : std_logic_vector(1 downto 0);  --- Double Buffer to prevent metastable
    signal TRIGGER_Q             : std_logic_vector(1 downto 0);
    signal SYNC_D                : std_logic_vector(2 downto 0);
    signal SYNC_Q                : std_logic_vector(2 downto 0);
 
    

    signal MODE_TO_FORMAT        : std_logic_vector(2 downto 0);
    
    ------- Select 12-bit ADC
    --signal SEL_ADC10bit : std_logic;

    ------- MASK ADC
    signal MASK_ADC : std_logic_vector(15 downto 0);  --- 1 --> ADC sample are forced to 0.
    
    --- Data Format to Processing
    signal ModeFifoRdEn   : std_logic;
    signal ModeFifoDout   : std_logic_VECTOR(1 downto 0);
    signal ModeFifoEmpty  : std_logic;
    signal ModeFifoFull   : std_logic;
    signal CH0_Fist_Last_Proc_Adr     :  std_logic_VECTOR(11 downto 0);
    signal CH0_Pop_Fist_Last_Proc_Adr :  std_logic;   --- rising edge pop next address out of FIFO
    signal CH1_Fist_Last_Proc_Adr     :  std_logic_VECTOR(11 downto 0);
    signal CH1_Pop_Fist_Last_Proc_Adr :  std_logic;   --- rising edge pop next address out of FIFO
    signal CH2_Fist_Last_Proc_Adr     :  std_logic_VECTOR(11 downto 0);
    signal CH2_Pop_Fist_Last_Proc_Adr :  std_logic;   --- rising edge pop next address out of FIFO
    signal CH3_Fist_Last_Proc_Adr     :  std_logic_VECTOR(11 downto 0);
    signal CH3_Pop_Fist_Last_Proc_Adr :  std_logic;   --- rising edge pop next address out of FIFO
    signal CH4_Fist_Last_Proc_Adr     :  std_logic_VECTOR(11 downto 0);
    signal CH4_Pop_Fist_Last_Proc_Adr :  std_logic;   --- rising edge pop next address out of FIFO
    signal CH5_Fist_Last_Proc_Adr     :  std_logic_VECTOR(11 downto 0);
    signal CH5_Pop_Fist_Last_Proc_Adr :  std_logic;   --- rising edge pop next address out of FIFO
--    signal CH6_Fist_Last_Proc_Adr     :  std_logic_VECTOR(11 downto 0);
--    signal CH6_Pop_Fist_Last_Proc_Adr :  std_logic;   --- rising edge pop next address out of FIFO
--    signal CH7_Fist_Last_Proc_Adr     :  std_logic_VECTOR(11 downto 0);
--    signal CH7_Pop_Fist_Last_Proc_Adr :  std_logic;   --- rising edge pop next address out of FIFO
--    signal CH8_Fist_Last_Proc_Adr     :  std_logic_VECTOR(11 downto 0);
--    signal CH8_Pop_Fist_Last_Proc_Adr :  std_logic;   --- rising edge pop next address out of FIFO
--    signal CH9_Fist_Last_Proc_Adr     :  std_logic_VECTOR(11 downto 0);
--    signal CH9_Pop_Fist_Last_Proc_Adr :  std_logic;   --- rising edge pop next address out of FIFO
--    signal CH10_Fist_Last_Proc_Adr     :  std_logic_VECTOR(11 downto 0);
--    signal CH10_Pop_Fist_Last_Proc_Adr :  std_logic;   --- rising edge pop next address out of FIFO
--    signal CH11_Fist_Last_Proc_Adr     :  std_logic_VECTOR(11 downto 0);
--    signal CH11_Pop_Fist_Last_Proc_Adr :  std_logic;   --- rising edge pop next address out of FIFO
--    signal CH12_Fist_Last_Proc_Adr     :  std_logic_VECTOR(11 downto 0);
--    signal CH12_Pop_Fist_Last_Proc_Adr :  std_logic;   --- rising edge pop next address out of FIFO
--    signal CH13_Fist_Last_Proc_Adr     :  std_logic_VECTOR(11 downto 0);
--    signal CH13_Pop_Fist_Last_Proc_Adr :  std_logic;   --- rising edge pop next address out of FIFO
--    signal CH14_Fist_Last_Proc_Adr     :  std_logic_VECTOR(11 downto 0);
--    signal CH14_Pop_Fist_Last_Proc_Adr :  std_logic;   --- rising edge pop next address out of FIFO
--    signal CH15_Fist_Last_Proc_Adr     :  std_logic_VECTOR(11 downto 0);
--    signal CH15_Pop_Fist_Last_Proc_Adr :  std_logic;   --- rising edge pop next address out of FIFO

    ----- Play Back PPG
    signal TEST_MODE    :  std_logic;
    signal PlayBack     :  std_logic;   --- 1 play back data           
    signal WaveDataOUT     :  std_logic_VECTOR(15 downto 0);  --- To verify that data is written, connect to host register. 
    signal PlayBack_WV_OUT :  std_logic_VECTOR(15 downto 0);
    signal PlayBack_WV_OUT_BUF_D :  Aray13Bits;
    signal PlayBack_WV_OUT_BUF_Q :  Aray13Bits;

    ------- BUFFERS TO MEET TIMING
    signal CH0_PROC_ADR_Q     : std_logic_VECTOR(11 downto 0);
    signal CH0_PROC_OUTDAT_Q  : std_logic_VECTOR(17 downto 0);
    signal CH1_PROC_ADR_Q     : std_logic_VECTOR(11 downto 0);
    signal CH1_PROC_OUTDAT_Q  : std_logic_VECTOR(17 downto 0);
    signal CH2_PROC_ADR_Q     : std_logic_VECTOR(11 downto 0);
    signal CH2_PROC_OUTDAT_Q  : std_logic_VECTOR(17 downto 0);
    signal CH3_PROC_ADR_Q     : std_logic_VECTOR(11 downto 0);
    signal CH3_PROC_OUTDAT_Q  : std_logic_VECTOR(17 downto 0);
    signal CH4_PROC_ADR_Q     : std_logic_VECTOR(11 downto 0);
    signal CH4_PROC_OUTDAT_Q  : std_logic_VECTOR(17 downto 0);
    signal CH5_PROC_ADR_Q     : std_logic_VECTOR(11 downto 0);
    signal CH5_PROC_OUTDAT_Q  : std_logic_VECTOR(17 downto 0);
--    signal CH6_PROC_ADR_Q     : std_logic_VECTOR(11 downto 0);
--    signal CH6_PROC_OUTDAT_Q  : std_logic_VECTOR(17 downto 0);
--    signal CH7_PROC_ADR_Q     : std_logic_VECTOR(11 downto 0);
--    signal CH7_PROC_OUTDAT_Q  : std_logic_VECTOR(17 downto 0);
--    signal CH8_PROC_ADR_Q     : std_logic_VECTOR(11 downto 0);
--    signal CH8_PROC_OUTDAT_Q  : std_logic_VECTOR(17 downto 0);
--    signal CH9_PROC_ADR_Q     : std_logic_VECTOR(11 downto 0);
--    signal CH9_PROC_OUTDAT_Q  : std_logic_VECTOR(17 downto 0);
--    signal CH10_PROC_ADR_Q     : std_logic_VECTOR(11 downto 0);
--    signal CH10_PROC_OUTDAT_Q  : std_logic_VECTOR(17 downto 0);
--    signal CH11_PROC_ADR_Q     : std_logic_VECTOR(11 downto 0);
--    signal CH11_PROC_OUTDAT_Q  : std_logic_VECTOR(17 downto 0);
--    signal CH12_PROC_ADR_Q     : std_logic_VECTOR(11 downto 0);
--    signal CH12_PROC_OUTDAT_Q  : std_logic_VECTOR(17 downto 0);
--    signal CH13_PROC_ADR_Q     : std_logic_VECTOR(11 downto 0);
--    signal CH13_PROC_OUTDAT_Q  : std_logic_VECTOR(17 downto 0);
--    signal CH14_PROC_ADR_Q     : std_logic_VECTOR(11 downto 0);
--    signal CH14_PROC_OUTDAT_Q  : std_logic_VECTOR(17 downto 0);
--    signal CH15_PROC_ADR_Q     : std_logic_VECTOR(11 downto 0);
--    signal CH15_PROC_OUTDAT_Q  : std_logic_VECTOR(17 downto 0);
    signal CH0_HOST_BLOCK_CNT_Q : std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
    signal CH1_HOST_BLOCK_CNT_Q : std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
    signal CH2_HOST_BLOCK_CNT_Q : std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
    signal CH3_HOST_BLOCK_CNT_Q : std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
    signal CH4_HOST_BLOCK_CNT_Q : std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
    signal CH5_HOST_BLOCK_CNT_Q : std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
--    signal CH6_HOST_BLOCK_CNT_Q : std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
--    signal CH7_HOST_BLOCK_CNT_Q : std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
--    signal CH8_HOST_BLOCK_CNT_Q : std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
--    signal CH9_HOST_BLOCK_CNT_Q : std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
--    signal CH10_HOST_BLOCK_CNT_Q : std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
--    signal CH11_HOST_BLOCK_CNT_Q : std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
--    signal CH12_HOST_BLOCK_CNT_Q : std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
--    signal CH13_HOST_BLOCK_CNT_Q : std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
--    signal CH14_HOST_BLOCK_CNT_Q : std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
--    signal CH15_HOST_BLOCK_CNT_Q : std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
    signal CH0_DEC_BLOCK_CNT_Q  : std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
    signal CH1_DEC_BLOCK_CNT_Q  : std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
    signal CH2_DEC_BLOCK_CNT_Q  : std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
    signal CH3_DEC_BLOCK_CNT_Q  : std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
    signal CH4_DEC_BLOCK_CNT_Q  : std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
    signal CH5_DEC_BLOCK_CNT_Q  : std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
--    signal CH6_DEC_BLOCK_CNT_Q  : std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
--    signal CH7_DEC_BLOCK_CNT_Q  : std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
--    signal CH8_DEC_BLOCK_CNT_Q  : std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
--    signal CH9_DEC_BLOCK_CNT_Q  : std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
--    signal CH10_DEC_BLOCK_CNT_Q  : std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
--    signal CH11_DEC_BLOCK_CNT_Q  : std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
--    signal CH12_DEC_BLOCK_CNT_Q  : std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
--    signal CH13_DEC_BLOCK_CNT_Q  : std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
--    signal CH14_DEC_BLOCK_CNT_Q  : std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
--    signal CH15_DEC_BLOCK_CNT_Q  : std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
    signal CH0_Fist_Last_Proc_Adr_Q     :  std_logic_VECTOR(11 downto 0);
    signal CH0_Pop_Fist_Last_Proc_Adr_Q :  std_logic;   --- rising edge pop next address out of FIFO
    signal CH1_Fist_Last_Proc_Adr_Q     :  std_logic_VECTOR(11 downto 0);
    signal CH1_Pop_Fist_Last_Proc_Adr_Q :  std_logic;   --- rising edge pop next address out of FIFO
    signal CH2_Fist_Last_Proc_Adr_Q     :  std_logic_VECTOR(11 downto 0);
    signal CH2_Pop_Fist_Last_Proc_Adr_Q :  std_logic;   --- rising edge pop next address out of FIFO
    signal CH3_Fist_Last_Proc_Adr_Q     :  std_logic_VECTOR(11 downto 0);
    signal CH3_Fist_Last_Proc_Adr_BUF2_Q     :  std_logic_VECTOR(11 downto 0);
    signal CH3_Pop_Fist_Last_Proc_Adr_Q :  std_logic;   --- rising edge pop next address out of FIFO
    signal CH4_Fist_Last_Proc_Adr_Q     :  std_logic_VECTOR(11 downto 0);
    signal CH4_Pop_Fist_Last_Proc_Adr_Q :  std_logic;   --- rising edge pop next address out of FIFO
    signal CH5_Fist_Last_Proc_Adr_Q     :  std_logic_VECTOR(11 downto 0);
    signal CH5_Pop_Fist_Last_Proc_Adr_Q :  std_logic;   --- rising edge pop next address out of FIFO
--    signal CH6_Fist_Last_Proc_Adr_Q     :  std_logic_VECTOR(11 downto 0);
--    signal CH6_Pop_Fist_Last_Proc_Adr_Q :  std_logic;   --- rising edge pop next address out of FIFO
--    signal CH7_Fist_Last_Proc_Adr_Q     :  std_logic_VECTOR(11 downto 0);
--    signal CH7_Pop_Fist_Last_Proc_Adr_Q :  std_logic;   --- rising edge pop next address out of FIFO
--    signal CH8_Fist_Last_Proc_Adr_Q     :  std_logic_VECTOR(11 downto 0);
--    signal CH8_Pop_Fist_Last_Proc_Adr_Q :  std_logic;   --- rising edge pop next address out of FIFO
--    signal CH9_Fist_Last_Proc_Adr_Q     :  std_logic_VECTOR(11 downto 0);
--    signal CH9_Pop_Fist_Last_Proc_Adr_Q :  std_logic;   --- rising edge pop next address out of FIFO
--    signal CH10_Fist_Last_Proc_Adr_Q     :  std_logic_VECTOR(11 downto 0);
--    signal CH10_Pop_Fist_Last_Proc_Adr_Q :  std_logic;   --- rising edge pop next address out of FIFO
--    signal CH11_Fist_Last_Proc_Adr_Q     :  std_logic_VECTOR(11 downto 0);
--    signal CH11_Pop_Fist_Last_Proc_Adr_Q :  std_logic;   --- rising edge pop next address out of FIFO
--    signal CH12_Fist_Last_Proc_Adr_Q     :  std_logic_VECTOR(11 downto 0);
--    signal CH12_Pop_Fist_Last_Proc_Adr_Q :  std_logic;   --- rising edge pop next address out of FIFO
--    signal CH13_Fist_Last_Proc_Adr_Q     :  std_logic_VECTOR(11 downto 0);
--    signal CH13_Pop_Fist_Last_Proc_Adr_Q :  std_logic;   --- rising edge pop next address out of FIFO
--    signal CH14_Fist_Last_Proc_Adr_Q     :  std_logic_VECTOR(11 downto 0);
--    signal CH14_Pop_Fist_Last_Proc_Adr_Q :  std_logic;   --- rising edge pop next address out of FIFO
--    signal CH15_Fist_Last_Proc_Adr_Q     :  std_logic_VECTOR(11 downto 0);
--    signal CH15_Pop_Fist_Last_Proc_Adr_Q :  std_logic;   --- rising edge pop next address out of FIFO

    ----- Buffer to meet timing
    signal COLLECT_ON_BUF_Q          : std_logic;
    

begin
    RESET  <= not RESET_N;
    TRIGGER_D(0) <= TRIGGER;
    TRIGGER_D(1)    <= TRIGGER_Q(0);
    TRIGGER_N_D     <= not TRIGGER_Q(1);
    TRIGGER_N_DLY_D <= TRIGGER_N_Q;
    PTRIGGER_N      <= not TRIGGER_N_Q and  TRIGGER_N_D;
    
    SYNC_D(0)    <= SYNC;
    SYNC_D(1)    <= SYNC_Q(0);
    SYNC_D(2)    <= SYNC_Q(1);
   
   --- Differential to Single End Register
--   USYNC_ADC_IN_VER2_1 : SYNC_ADC_IN_VER2
--        generic map
--        (
--                CH1_IDELAY_VALUE => CH1_IDELAY_VALUE, 
--                CH2_IDELAY_VALUE => CH2_IDELAY_VALUE, 
--                CH3_IDELAY_VALUE => CH3_IDELAY_VALUE, 
--                CH4_IDELAY_VALUE => CH4_IDELAY_VALUE, 
--                CH5_IDELAY_VALUE => CH5_IDELAY_VALUE, 
--                CH6_IDELAY_VALUE => CH6_IDELAY_VALUE, 
--                CH7_IDELAY_VALUE => CH7_IDELAY_VALUE, 
--                CH8_IDELAY_VALUE => CH8_IDELAY_VALUE 
--        )
--        port map
--         (
--           CLK                  => CLK,
--           RESET_N              => RESET_N,
--           DN_1                 => DN_1,         
--           DP_1                 => DP_1,         
--           DCLKN_1              => DCLKN_1,      
--           DCLKP_1              => DCLKP_1,      
--           ORN_1                => ORN_1,        
--           ORP_1                => ORP_1,        
--           DN_2                 => DN_2,         
--           DP_2                 => DP_2,         
--           DCLKN_2              => DCLKN_2,      
--           DCLKP_2              => DCLKP_2,      
--           ORN_2                => ORN_2,        
--           ORP_2                => ORP_2,        
--           DN_3                 => DN_3,         
--           DP_3                 => DP_3,         
--           DCLKN_3              => DCLKN_3,      
--           DCLKP_3              => DCLKP_3,      
--           ORN_3                => ORN_3,        
--           ORP_3                => ORP_3,        
--           DN_4                 => DN_4,         
--           DP_4                 => DP_4,         
--           DCLKN_4              => DCLKN_4,      
--           DCLKP_4              => DCLKP_4,      
--           ORN_4                => ORN_4,        
--           ORP_4                => ORP_4,        
--           DN_5                 => DN_5,         
--           DP_5                 => DP_5,         
--           DCLKN_5              => DCLKN_5,      
--           DCLKP_5              => DCLKP_5,      
--           ORN_5                => ORN_5,        
--           ORP_5                => ORP_5,        
--           DN_6                 => DN_6,         
--           DP_6                 => DP_6,         
--           DCLKN_6              => DCLKN_6,      
--           DCLKP_6              => DCLKP_6,      
--           ORN_6                => ORN_6,        
--           ORP_6                => ORP_6,        
--           DN_7                 => DN_7,         
--           DP_7                 => DP_7,         
--           DCLKN_7              => DCLKN_7,      
--           DCLKP_7              => DCLKP_7,      
--           ORN_7                => ORN_7,        
--           ORP_7                => ORP_7,        
--           DN_8                 => DN_8,         
--           DP_8                 => DP_8,         
--           DCLKN_8              => DCLKN_8,      
--           DCLKP_8              => DCLKP_8,      
--           ORN_8                => ORN_8,        
--           ORP_8                => ORP_8,        
--
--           FIFO_RESET           => RESET,
--           
--           ADC_DATA_1_REG       => ADC_RAWDATA_1,
--           ADC_DATA_2_REG       => ADC_RAWDATA_2,
--           ADC_DATA_3_REG       => ADC_RAWDATA_3,
--           ADC_DATA_4_REG       => ADC_RAWDATA_4,
--           ADC_DATA_5_REG       => ADC_RAWDATA_5,
--           ADC_DATA_6_REG       => ADC_RAWDATA_6,
--           ADC_DATA_7_REG       => ADC_RAWDATA_7,
--           ADC_DATA_8_REG       => ADC_RAWDATA_8            
--        );

--   USYNC_ADC_IN_VER2_2 : SYNC_ADC_IN_VER2
--        generic map
--        (
--                CH1_IDELAY_VALUE => CH9_IDELAY_VALUE, 
--                CH2_IDELAY_VALUE => CH10_IDELAY_VALUE, 
--                CH3_IDELAY_VALUE => CH11_IDELAY_VALUE, 
--                CH4_IDELAY_VALUE => CH12_IDELAY_VALUE, 
--                CH5_IDELAY_VALUE => CH13_IDELAY_VALUE, 
--                CH6_IDELAY_VALUE => CH14_IDELAY_VALUE, 
--                CH7_IDELAY_VALUE => CH15_IDELAY_VALUE, 
--                CH8_IDELAY_VALUE => CH16_IDELAY_VALUE 
--        )
--        port map
--         (
--           CLK                  => CLK,
--           RESET_N              => RESET_N,
--           DN_1                 => DN_9,         
--           DP_1                 => DP_9,         
--           DCLKN_1              => DCLKN_9,      
--           DCLKP_1              => DCLKP_9,      
--           ORN_1                => ORN_9,        
--           ORP_1                => ORP_9,        
--           DN_2                 => DN_10,         
--           DP_2                 => DP_10,         
--           DCLKN_2              => DCLKN_10,      
--           DCLKP_2              => DCLKP_10,      
--           ORN_2                => ORN_10,        
--           ORP_2                => ORP_10,        
--           DN_3                 => DN_11,         
--           DP_3                 => DP_11,         
--           DCLKN_3              => DCLKN_11,      
--           DCLKP_3              => DCLKP_11,      
--           ORN_3                => ORN_11,        
--           ORP_3                => ORP_11,        
--           DN_4                 => DN_12,         
--           DP_4                 => DP_12,         
--           DCLKN_4              => DCLKN_12,      
--           DCLKP_4              => DCLKP_12,      
--           ORN_4                => ORN_12,        
--           ORP_4                => ORP_12,        
--           DN_5                 => DN_13,         
--           DP_5                 => DP_13,         
--           DCLKN_5              => DCLKN_13,      
--           DCLKP_5              => DCLKP_13,      
--           ORN_5                => ORN_13,        
--           ORP_5                => ORP_13,        
--           DN_6                 => DN_14,         
--           DP_6                 => DP_14,         
--           DCLKN_6              => DCLKN_14,      
--           DCLKP_6              => DCLKP_14,      
--           ORN_6                => ORN_14,        
--           ORP_6                => ORP_14,        
--           DN_7                 => DN_15,         
--           DP_7                 => DP_15,         
--           DCLKN_7              => DCLKN_15,      
--           DCLKP_7              => DCLKP_15,      
--           ORN_7                => ORN_15,        
--           ORP_7                => ORP_15,        
--           DN_8                 => DN_16,         
--           DP_8                 => DP_16,         
--           DCLKN_8              => DCLKN_16,      
--           DCLKP_8              => DCLKP_16,      
--           ORN_8                => ORN_16,        
--           ORP_8                => ORP_16,        
--
--           FIFO_RESET           => RESET,
--           
--           ADC_DATA_1_REG       => ADC_RAWDATA_9,
--           ADC_DATA_2_REG       => ADC_RAWDATA_10,
--           ADC_DATA_3_REG       => ADC_RAWDATA_11,
--           ADC_DATA_4_REG       => ADC_RAWDATA_12,
--           ADC_DATA_5_REG       => ADC_RAWDATA_13,
--           ADC_DATA_6_REG       => ADC_RAWDATA_14,
--           ADC_DATA_7_REG       => ADC_RAWDATA_15,
--           ADC_DATA_8_REG       => ADC_RAWDATA_16            
--        );



   ---- *************************************************
   ----   Programmable Generator   
--   PlayBack <= TRIGGER2;
--    UPlayBack_WV : PlayBack16_WV
--      port  map
--       (
--        CLK          => CLK,         
--        RESET_N      => RESET_N,     
--                                 
--        WaveDataWrEN => PPG_DAT_OUT_VALID,
--        WaveDataIN   => PPG_DAT_IN,  
--        PlayBack     => PlayBack,    
--           
--        WaveDataOUT        => PPG_DAT_OUT,    
--        PlayBack16_WV_OUT  => PlayBack_WV_OUT_BUF_D
--       );
   -- ****************************************************
   
   ---- Select 12 or 10 bits ADC. Mask channel.
--   ADC_DATA_1_D <= PlayBack_WV_OUT_BUF_Q(0)(12 downto 0)  when TEST_MODE    = '1' and MASK_ADC(0) = '0' else
--                   ADC_RAWDATA_1    when  MASK_ADC(0) = '0' else
--                   (others => '0'); 
--   ADC_DATA_2_D <=  PlayBack_WV_OUT_BUF_Q(1)(12 downto 0)  when TEST_MODE    = '1' and MASK_ADC(0) = '0' else
--                   ADC_RAWDATA_2    when  MASK_ADC(1) = '0' else
--                   (others => '0'); 
--   ADC_DATA_3_D <= PlayBack_WV_OUT_BUF_Q(2)(12 downto 0)  when TEST_MODE    = '1' and MASK_ADC(0) = '0' else
--                   ADC_RAWDATA_3    when  MASK_ADC(2) = '0' else
--                   (others => '0'); 
--   ADC_DATA_4_D <= PlayBack_WV_OUT_BUF_Q(3)(12 downto 0)  when TEST_MODE    = '1' and MASK_ADC(0) = '0' else
--                   ADC_RAWDATA_4    when  MASK_ADC(3) = '0' else
--                   (others => '0'); 
--   ADC_DATA_5_D <= PlayBack_WV_OUT_BUF_Q(4)(12 downto 0)  when TEST_MODE    = '1' and MASK_ADC(0) = '0' else
--                   ADC_RAWDATA_5    when  MASK_ADC(4) = '0' else
--                   (others => '0'); 
						 
	ADC_DATA_1_D <= "0"&ADC1_DATA;
	ADC_DATA_2_D <= "0"&ADC2_DATA;
	ADC_DATA_3_D <= "0"&ADC3_DATA;
	ADC_DATA_4_D <= "0"&ADC4_DATA;
	ADC_DATA_5_D <= "0"&ADC5_DATA;
	ADC_DATA_6_D <= "0"&ADC6_DATA;
                   
   
   -- Data Buffer ****************************************
   PTW_WORDS_MINUS_ONE_D <= PTW(8 downto 0) - 1; 
   UDATA_BUFFER_ALLCH_VER2_TOP : DATA_BUFFER_ALLCH_VER2_TOP
        port map
         (
           CLK                  => CLK, 
           CLK_PROCESS          => CLK, 
           RESET_N              => RESET_N,
           SOFT_RESET_N         => SOFT_RESET_N,

           DATA_BUFFER_RDY_REG  =>  DATA_BUFFER_RDY_REG, 

           ---- Ports for testing
           TestPort               => open,
           
           --- Data From 8 ADC. Each consist of 12 data bits and 1 overflow
           ADC1_DATA            =>  ADC_DATA_1_Q,  
           ADC2_DATA            =>  ADC_DATA_2_Q,  
           ADC3_DATA            =>  ADC_DATA_3_Q,  
           ADC4_DATA            =>  ADC_DATA_4_Q,  
           ADC5_DATA            =>  ADC_DATA_5_Q,  
           ADC6_DATA            =>  ADC_DATA_6_Q,  
--           ADC7_DATA            =>  ADC_DATA_7_Q,  
--           ADC8_DATA            =>  ADC_DATA_8_Q,  
--           ADC9_DATA            =>  ADC_DATA_9_Q,  
--           ADC10_DATA           =>  ADC_DATA_10_Q,  
--           ADC11_DATA           =>  ADC_DATA_11_Q,  
--           ADC12_DATA           =>  ADC_DATA_12_Q,  
--           ADC13_DATA           =>  ADC_DATA_13_Q,  
--           ADC14_DATA           =>  ADC_DATA_14_Q,  
--           ADC15_DATA           =>  ADC_DATA_15_Q,  
--           ADC16_DATA           =>  ADC_DATA_16_Q,  
                                 
           ---- Common to all channel
           COLLECT_ON           => COLLECT_ON_Q,
           TIME_STAMP           => TIMESTAMP,
           PTW_WORDS            => PTW(8 downto 0),           
           PTW_WORDS_MINUS_ONE  => PTW_WORDS_MINUS_ONE_Q, 
           TRIGGER_N            => TRIGGER_N_DLY_Q,           
           TRIGER_NUMBER        => TRIGGER_NUMBER,       
           LATENCY_WORD         => PL(10 downto 0),        
           PTW_DAT_BUF_LAST_ADR => PTW_DAT_BUF_LAST_ADR(11 downto 0),
           MAX_PTW_DATA_BLOCK   => PTW_MAX_BUF(7 downto 0),  

           DEC_PTW_CNT1            => DEC_PTW_CNT1,           
           DEC_PTW_CNT2            => DEC_PTW_CNT2,           
           DEC_PTW_CNT3            => DEC_PTW_CNT3,           
           DEC_PTW_CNT4            => DEC_PTW_CNT4,           
           DEC_PTW_CNT5            => DEC_PTW_CNT5,           
           DEC_PTW_CNT6            => DEC_PTW_CNT6,           
--           DEC_PTW_CNT7            => DEC_PTW_CNT7,           
--           DEC_PTW_CNT8            => DEC_PTW_CNT8,           
--           DEC_PTW_CNT9            => DEC_PTW_CNT9,           
--           DEC_PTW_CNT10           => DEC_PTW_CNT10,           
--           DEC_PTW_CNT11           => DEC_PTW_CNT11,           
--           DEC_PTW_CNT12           => DEC_PTW_CNT12,           
--           DEC_PTW_CNT13           => DEC_PTW_CNT13,           
--           DEC_PTW_CNT14           => DEC_PTW_CNT14,           
--           DEC_PTW_CNT15           => DEC_PTW_CNT15,           
--           DEC_PTW_CNT16           => DEC_PTW_CNT16,           
--           PTW_DATA_BLOCK_CNT1_REG => PTW_DATA_BLOCK_CNT1,
--           PTW_DATA_BLOCK_CNT2_REG => PTW_DATA_BLOCK_CNT2,
--           PTW_DATA_BLOCK_CNT3_REG => PTW_DATA_BLOCK_CNT3,
--           PTW_DATA_BLOCK_CNT4_REG => PTW_DATA_BLOCK_CNT4,
--           PTW_DATA_BLOCK_CNT5_REG => PTW_DATA_BLOCK_CNT5,
--           PTW_DATA_BLOCK_CNT6_REG => PTW_DATA_BLOCK_CNT6,
--           PTW_DATA_BLOCK_CNT7_REG => PTW_DATA_BLOCK_CNT7,
--           PTW_DATA_BLOCK_CNT8_REG => PTW_DATA_BLOCK_CNT8,
--           PTW_DATA_BLOCK_CNT9_REG => PTW_DATA_BLOCK_CNT9,
--           PTW_DATA_BLOCK_CNT10_REG => PTW_DATA_BLOCK_CNT10,
--           PTW_DATA_BLOCK_CNT11_REG => PTW_DATA_BLOCK_CNT11,
--           PTW_DATA_BLOCK_CNT12_REG => PTW_DATA_BLOCK_CNT12,
--           PTW_DATA_BLOCK_CNT13_REG => PTW_DATA_BLOCK_CNT13,
--           PTW_DATA_BLOCK_CNT14_REG => PTW_DATA_BLOCK_CNT14,
--           PTW_DATA_BLOCK_CNT15_REG => PTW_DATA_BLOCK_CNT15,
--           PTW_DATA_BLOCK_CNT16_REG => PTW_DATA_BLOCK_CNT16,
           
           --- Status Bits for each ADC channels
           PTW_BUFFER_OVERRUN1_REG => PTW_BUFFER_OVERRUN1,
           PTW_BUFFER_OVERRUN2_REG => PTW_BUFFER_OVERRUN2,
           PTW_BUFFER_OVERRUN3_REG => PTW_BUFFER_OVERRUN3,
           PTW_BUFFER_OVERRUN4_REG => PTW_BUFFER_OVERRUN4,
           PTW_BUFFER_OVERRUN5_REG => PTW_BUFFER_OVERRUN5,
           PTW_BUFFER_OVERRUN6_REG => PTW_BUFFER_OVERRUN6,
--           PTW_BUFFER_OVERRUN7_REG => PTW_BUFFER_OVERRUN7,
--           PTW_BUFFER_OVERRUN8_REG => PTW_BUFFER_OVERRUN8,
--           PTW_BUFFER_OVERRUN9_REG => PTW_BUFFER_OVERRUN9,
--           PTW_BUFFER_OVERRUN10_REG => PTW_BUFFER_OVERRUN10,
--           PTW_BUFFER_OVERRUN11_REG => PTW_BUFFER_OVERRUN11,
--           PTW_BUFFER_OVERRUN12_REG => PTW_BUFFER_OVERRUN12,
--           PTW_BUFFER_OVERRUN13_REG => PTW_BUFFER_OVERRUN13,
--           PTW_BUFFER_OVERRUN14_REG => PTW_BUFFER_OVERRUN14,
--           PTW_BUFFER_OVERRUN15_REG => PTW_BUFFER_OVERRUN15,
--           PTW_BUFFER_OVERRUN16_REG => PTW_BUFFER_OVERRUN16,

           RAW_BUFFER_OVERRUN1_REG => RAW_BUFFER_OVERRUN1,
           RAW_BUFFER_OVERRUN2_REG => RAW_BUFFER_OVERRUN2,
           RAW_BUFFER_OVERRUN3_REG => RAW_BUFFER_OVERRUN3,
           RAW_BUFFER_OVERRUN4_REG => RAW_BUFFER_OVERRUN4,
           RAW_BUFFER_OVERRUN5_REG => RAW_BUFFER_OVERRUN5,
           RAW_BUFFER_OVERRUN6_REG => RAW_BUFFER_OVERRUN6,
--           RAW_BUFFER_OVERRUN7_REG => RAW_BUFFER_OVERRUN7,
--           RAW_BUFFER_OVERRUN8_REG => RAW_BUFFER_OVERRUN8,
--           RAW_BUFFER_OVERRUN9_REG => RAW_BUFFER_OVERRUN9,
--           RAW_BUFFER_OVERRUN10_REG => RAW_BUFFER_OVERRUN10,
--           RAW_BUFFER_OVERRUN11_REG => RAW_BUFFER_OVERRUN11,
--           RAW_BUFFER_OVERRUN12_REG => RAW_BUFFER_OVERRUN12,
--           RAW_BUFFER_OVERRUN13_REG => RAW_BUFFER_OVERRUN13,
--           RAW_BUFFER_OVERRUN14_REG => RAW_BUFFER_OVERRUN14,
--           RAW_BUFFER_OVERRUN15_REG => RAW_BUFFER_OVERRUN15,
--           RAW_BUFFER_OVERRUN16_REG => RAW_BUFFER_OVERRUN16,
            
           -- Read out the PTW Data Block (PTW*_RAM_DATA) with PTW*_RAM_ADR for each ADC channel when PTW*_DATA_BLOCK_CNT1_REG      
           PTW1_RAM_ADR    => PTW0_RAM_ADR, 
           PTW1_RAM_DATA   => PTW0_RAM_DATA,
           PTW2_RAM_ADR    => PTW1_RAM_ADR,  
           PTW2_RAM_DATA   => PTW1_RAM_DATA, 
           PTW3_RAM_ADR    => PTW2_RAM_ADR,  
           PTW3_RAM_DATA   => PTW2_RAM_DATA, 
           PTW4_RAM_ADR    => PTW3_RAM_ADR,  
           PTW4_RAM_DATA   => PTW3_RAM_DATA, 
           PTW5_RAM_ADR    => PTW4_RAM_ADR,  
           PTW5_RAM_DATA   => PTW4_RAM_DATA, 
           PTW6_RAM_ADR    => PTW5_RAM_ADR,  
           PTW6_RAM_DATA   => PTW5_RAM_DATA 
--           PTW7_RAM_ADR    => PTW6_RAM_ADR,  
--           PTW7_RAM_DATA   => PTW6_RAM_DATA, 
--           PTW8_RAM_ADR    => PTW7_RAM_ADR,  
--           PTW8_RAM_DATA   => PTW7_RAM_DATA,
--           PTW9_RAM_ADR    => PTW8_RAM_ADR, 
--           PTW9_RAM_DATA   => PTW8_RAM_DATA,
--           PTW10_RAM_ADR    => PTW9_RAM_ADR,  
--           PTW10_RAM_DATA   => PTW9_RAM_DATA, 
--           PTW11_RAM_ADR    => PTW10_RAM_ADR,  
--           PTW11_RAM_DATA   => PTW10_RAM_DATA, 
--           PTW12_RAM_ADR    => PTW11_RAM_ADR,  
--           PTW12_RAM_DATA   => PTW11_RAM_DATA, 
--           PTW13_RAM_ADR    => PTW12_RAM_ADR,  
--           PTW13_RAM_DATA   => PTW12_RAM_DATA, 
--           PTW14_RAM_ADR    => PTW13_RAM_ADR,  
--           PTW14_RAM_DATA   => PTW13_RAM_DATA, 
--           PTW15_RAM_ADR    => PTW14_RAM_ADR,  
--           PTW15_RAM_DATA   => PTW14_RAM_DATA, 
--           PTW16_RAM_ADR    => PTW15_RAM_ADR,  
--           PTW16_RAM_DATA   => PTW15_RAM_DATA
        );
   -- ****************************************************

   ---- Control Bus ************************************** 
   --SYS_STATUS0_D <= PTW_BUFFER_OVERRUN1 & PTW_BUFFER_OVERRUN2 & PTW_BUFFER_OVERRUN3 & PTW_BUFFER_OVERRUN4 &
   --                 PTW_BUFFER_OVERRUN5 & PTW_BUFFER_OVERRUN6 & PTW_BUFFER_OVERRUN7 & PTW_BUFFER_OVERRUN8 &
   --                 RAW_BUFFER_OVERRUN1 & RAW_BUFFER_OVERRUN2 & RAW_BUFFER_OVERRUN3 & RAW_BUFFER_OVERRUN4 &
   --                 RAW_BUFFER_OVERRUN5 & RAW_BUFFER_OVERRUN6 & RAW_BUFFER_OVERRUN7 & RAW_BUFFER_OVERRUN8;
   --SYS_STATUS1_D(14 downto 0)   <= VERSION (14 downto 0);
 
   --SYS_STATUS0_D <= TRIGGER_NUMBER(15 downto 0);
   --SYS_STATUS1_D <= TIMESTAMP(15 downto 0) when PTRIGGER_N = '1' else SYS_STATUS1_Q;
   TRIGGER_NUMBER_REG(15 downto 0) <= TRIGGER_NUMBER(15 downto 0);
   
   
   NSA_D <= NSA;
   
   ----- TIME STAMP **************************************
   UTIMESTAMP_TOP : TIMESTAMP_TOP
        port map
         (
           CLK                  => CLK,
           RESET_N              => RESET_N,
           SYNC_RESET         => SYNC_Q(1),     
           COLLECT_ON           => COLLECT_ON_BUF_Q,           
           TIMESTAMP            => TIMESTAMP
        );
   ---- **************************************************
   
   ---- TRIGGER COUNTER ********************************        
    UTRIGGER_COUNT :  TRIGGER_NUMBER_TOP
        port map
         (
           CLK                  => CLK,     
           RESET_N              => RESET_N,
           SOFT_RESET_N         => SOFT_RESET_N,           
           TRIGGER_N            => TRIGGER_N_Q,                      
           TRIGGER_NUMBER_REG   => TRIGGER_NUMBER 
        );
   ---- **************************************************

   --- PROCESS BLOCK ******************************
    MODE       <= CONFIG1(2 downto 0);
    COLLECT_ON_D <= '1' when CONFIG1(3) = '1' else '0'; -- or SYNC_Q(1) = '0' else '0';
    MAX_NUMBER_OF_PULSE <= CONFIG1(6 downto 4);
    TEST_MODE <= CONFIG1(7);
    MASK_ADC <= CONFIG2(15 downto 0);
    
    --PTW_TS_TN_WORDS_D <= PTW(11 downto 0) - "1"; -- + "11"; -- for mode 1
    PTW_TS_TN_WORDS_D <= PTW(11 downto 0) + "101";  --- for mode 0
    --NSB_MINUS_2_D  <= NSB(11 downto 0) - "10";
    --NSA_MINUS1_D   <= NSA(12 downto 0) - 1;
    --NSA_MINUS7_D   <= NSA(12 downto 0) - "111";

    UPROCESS_ALL :  PROCESSING_ALL_VER2_TOP
       port map
         (
           CLK_PROCESS          => CLK, 
           CLK_HOST             => CLK, 
           RESET_N              => RESET_N,      
           SOFT_RESET_N         => SOFT_RESET_N, 
           
           -- Common to all Channel
           MODE                 => MODE,
           MAX_NUMBER_OF_PULSE  => MAX_NUMBER_OF_PULSE,
           MODE_TO_FORMAT       => MODE_TO_FORMAT,
           PTW_TS_TN_WORDS      => PTW_TS_TN_WORDS_Q,
           NSB                  => NSB(8 downto 0), --NSB,  
           --NSB_MINUS_2          => NSB_MINUS_2_Q,
           
           --NSA           => NSA_MINUS1_Q,
           NSA             => NSA_Q(8 downto 0), --NSA_Q,
           --NSA_MINUS7           => NSA_MINUS7_Q, 
           PTW_DAT_BUF_LAST_ADR => PTW_DAT_BUF_LAST_ADR(11 downto 0),
           LAST_PROC_BUF_ADR    => LAST_PROC_BUF_ADR,  

           Format_Idle          => Format_Idle,

           -- Channel 0 **********************         
           CH0_DEC_PTW_CNT     => DEC_PTW_CNT1,
           CH0_PTW_DATA_BLOCK_CNT => PTW_DATA_BLOCK_CNT1,            
           CH0_HOST_BLOCK_CNT_REG => CH0_HOST_BLOCK_CNT,
           CH0_DEC_BLOCK_CNT      => CH0_DEC_BLOCK_CNT_Q,           
           CH0_PTW_RAM_DATA       => PTW0_RAM_DATA,
           CH0_PTW_RAM_ADR        => PTW0_RAM_ADR,          
           ---- To DATA Format block
           CH0_PROC_ADR     => CH0_PROC_ADR_Q,   
           CH0_PROC_OUTDAT  => CH0_PROC_OUTDAT,
           TET0             => TET0(11 downto 0),

           -- Channel 1 **********************         
           CH1_DEC_PTW_CNT => DEC_PTW_CNT2,
           CH1_PTW_DATA_BLOCK_CNT => PTW_DATA_BLOCK_CNT2,            
           CH1_HOST_BLOCK_CNT_REG => CH1_HOST_BLOCK_CNT,
           CH1_DEC_BLOCK_CNT  => CH1_DEC_BLOCK_CNT_Q,
           CH1_PTW_RAM_DATA       => PTW1_RAM_DATA,
           CH1_PTW_RAM_ADR        => PTW1_RAM_ADR,           
           ---- To DATA Format block
           CH1_PROC_ADR       => CH1_PROC_ADR_Q,   
           CH1_PROC_OUTDAT    => CH1_PROC_OUTDAT,
           TET1             => TET1(11 downto 0),

           -- Channel 2 **********************          
           CH2_DEC_PTW_CNT => DEC_PTW_CNT3,
           CH2_PTW_DATA_BLOCK_CNT => PTW_DATA_BLOCK_CNT3,            
           CH2_HOST_BLOCK_CNT_REG => CH2_HOST_BLOCK_CNT,
           CH2_DEC_BLOCK_CNT      => CH2_DEC_BLOCK_CNT_Q,          
           CH2_PTW_RAM_DATA       => PTW2_RAM_DATA,
           CH2_PTW_RAM_ADR        => PTW2_RAM_ADR,           
           ---- To DATA Format block
           CH2_PROC_ADR       => CH2_PROC_ADR_Q,   
           CH2_PROC_OUTDAT    => CH2_PROC_OUTDAT,
           TET2             => TET2(11 downto 0),

           -- Channel 3 **********************        
           CH3_DEC_PTW_CNT => DEC_PTW_CNT4,
           CH3_PTW_DATA_BLOCK_CNT => PTW_DATA_BLOCK_CNT4,           
           CH3_HOST_BLOCK_CNT_REG => CH3_HOST_BLOCK_CNT,
           CH3_DEC_BLOCK_CNT      => CH3_DEC_BLOCK_CNT_Q,           
           CH3_PTW_RAM_DATA       => PTW3_RAM_DATA,
           CH3_PTW_RAM_ADR        => PTW3_RAM_ADR,           
           ---- To DATA Format block
           CH3_PROC_ADR       => CH3_PROC_ADR_Q,   
           CH3_PROC_OUTDAT    => CH3_PROC_OUTDAT,
           TET3             => TET3(11 downto 0),

           -- Channel 4 **********************         
           CH4_DEC_PTW_CNT => DEC_PTW_CNT5,
           CH4_PTW_DATA_BLOCK_CNT => PTW_DATA_BLOCK_CNT5,          
           CH4_HOST_BLOCK_CNT_REG => CH4_HOST_BLOCK_CNT,
           CH4_DEC_BLOCK_CNT      => CH4_DEC_BLOCK_CNT_Q,           
           CH4_PTW_RAM_DATA       => PTW4_RAM_DATA,
           CH4_PTW_RAM_ADR        => PTW4_RAM_ADR,           
           ---- To DATA Format block
           CH4_PROC_ADR       => CH4_PROC_ADR_Q,   
           CH4_PROC_OUTDAT    => CH4_PROC_OUTDAT,
           TET4             => TET4(11 downto 0),

           -- Channel 5 **********************        
           CH5_DEC_PTW_CNT => DEC_PTW_CNT6,
           CH5_PTW_DATA_BLOCK_CNT => PTW_DATA_BLOCK_CNT6,            
           CH5_HOST_BLOCK_CNT_REG => CH5_HOST_BLOCK_CNT,
           CH5_DEC_BLOCK_CNT      => CH5_DEC_BLOCK_CNT_Q,           
           CH5_PTW_RAM_DATA       => PTW5_RAM_DATA,
           CH5_PTW_RAM_ADR        => PTW5_RAM_ADR,           
           ---- To DATA Format block
           CH5_PROC_ADR       => CH5_PROC_ADR_Q,   
           CH5_PROC_OUTDAT    => CH5_PROC_OUTDAT,
           TET5             => TET5(11 downto 0),

--           -- Channel 6 **********************        
--           CH6_DEC_PTW_CNT => DEC_PTW_CNT7,
--           CH6_PTW_DATA_BLOCK_CNT => PTW_DATA_BLOCK_CNT7,            
--           CH6_HOST_BLOCK_CNT_REG => CH6_HOST_BLOCK_CNT,
--           CH6_DEC_BLOCK_CNT      => CH6_DEC_BLOCK_CNT_Q,           
--           CH6_PTW_RAM_DATA        => PTW6_RAM_DATA,
--           CH6_PTW_RAM_ADR        => PTW6_RAM_ADR,           
--           ---- To DATA Format block
--           CH6_PROC_ADR       => CH6_PROC_ADR_Q,   
--           CH6_PROC_OUTDAT    => CH6_PROC_OUTDAT,
--           TET6             => TET6(11 downto 0),
--
--           -- Channel 7 **********************        
--           CH7_DEC_PTW_CNT => DEC_PTW_CNT8,
--           CH7_PTW_DATA_BLOCK_CNT => PTW_DATA_BLOCK_CNT8,           
--           CH7_HOST_BLOCK_CNT_REG => CH7_HOST_BLOCK_CNT,
--           CH7_DEC_BLOCK_CNT      => CH7_DEC_BLOCK_CNT_Q,           
--           CH7_PTW_RAM_DATA       => PTW7_RAM_DATA,
--           CH7_PTW_RAM_ADR        => PTW7_RAM_ADR,           
--           ---- To DATA Format block
--           CH7_PROC_ADR       => CH7_PROC_ADR_Q,   
--           CH7_PROC_OUTDAT    => CH7_PROC_OUTDAT,                     
--           TET7             => TET7(11 downto 0),
--
--           -- Channel 8 **********************         
--           CH8_DEC_PTW_CNT     => DEC_PTW_CNT9,
--           CH8_PTW_DATA_BLOCK_CNT => PTW_DATA_BLOCK_CNT9,            
--           CH8_HOST_BLOCK_CNT_REG => CH8_HOST_BLOCK_CNT,
--           CH8_DEC_BLOCK_CNT      => CH8_DEC_BLOCK_CNT_Q,           
--           CH8_PTW_RAM_DATA       => PTW8_RAM_DATA,
--           CH8_PTW_RAM_ADR        => PTW8_RAM_ADR,          
--           ---- To DATA Format block
--           CH8_PROC_ADR     => CH8_PROC_ADR_Q,   
--           CH8_PROC_OUTDAT  => CH8_PROC_OUTDAT,
--           TET8             => TET8(11 downto 0),
--
--           -- Channel 9 **********************         
--           CH9_DEC_PTW_CNT => DEC_PTW_CNT10,
--           CH9_PTW_DATA_BLOCK_CNT => PTW_DATA_BLOCK_CNT10,            
--           CH9_HOST_BLOCK_CNT_REG => CH9_HOST_BLOCK_CNT,
--           CH9_DEC_BLOCK_CNT  => CH9_DEC_BLOCK_CNT_Q,
--           CH9_PTW_RAM_DATA       => PTW9_RAM_DATA,
--           CH9_PTW_RAM_ADR        => PTW9_RAM_ADR,           
--           ---- To DATA Format block
--           CH9_PROC_ADR       => CH9_PROC_ADR_Q,   
--           CH9_PROC_OUTDAT    => CH9_PROC_OUTDAT,
--           TET9             => TET9(11 downto 0),
--
--           -- Channel 10 **********************          
--           CH10_DEC_PTW_CNT => DEC_PTW_CNT11,
--           CH10_PTW_DATA_BLOCK_CNT => PTW_DATA_BLOCK_CNT11,            
--           CH10_HOST_BLOCK_CNT_REG => CH10_HOST_BLOCK_CNT,
--           CH10_DEC_BLOCK_CNT      => CH10_DEC_BLOCK_CNT_Q,          
--           CH10_PTW_RAM_DATA       => PTW10_RAM_DATA,
--           CH10_PTW_RAM_ADR        => PTW10_RAM_ADR,           
--           ---- To DATA Format block
--           CH10_PROC_ADR       => CH10_PROC_ADR_Q,   
--           CH10_PROC_OUTDAT    => CH10_PROC_OUTDAT,
--           TET10             => TET10(11 downto 0),
--
--           -- Channel 11 **********************        
--           CH11_DEC_PTW_CNT => DEC_PTW_CNT12,
--           CH11_PTW_DATA_BLOCK_CNT => PTW_DATA_BLOCK_CNT12,           
--           CH11_HOST_BLOCK_CNT_REG => CH11_HOST_BLOCK_CNT,
--           CH11_DEC_BLOCK_CNT      => CH11_DEC_BLOCK_CNT_Q,           
--           CH11_PTW_RAM_DATA       => PTW11_RAM_DATA,
--           CH11_PTW_RAM_ADR        => PTW11_RAM_ADR,           
--           ---- To DATA Format block
--           CH11_PROC_ADR       => CH11_PROC_ADR_Q,   
--           CH11_PROC_OUTDAT    => CH11_PROC_OUTDAT,
--           TET11               => TET11(11 downto 0),
--
--           -- Channel 12 **********************         
--           CH12_DEC_PTW_CNT => DEC_PTW_CNT13,
--           CH12_PTW_DATA_BLOCK_CNT => PTW_DATA_BLOCK_CNT13,          
--           CH12_HOST_BLOCK_CNT_REG => CH12_HOST_BLOCK_CNT,
--           CH12_DEC_BLOCK_CNT      => CH12_DEC_BLOCK_CNT_Q,           
--           CH12_PTW_RAM_DATA       => PTW12_RAM_DATA,
--           CH12_PTW_RAM_ADR        => PTW12_RAM_ADR,           
--           ---- To DATA Format block
--           CH12_PROC_ADR       => CH12_PROC_ADR_Q,   
--           CH12_PROC_OUTDAT    => CH12_PROC_OUTDAT,
--           TET12               => TET12(11 downto 0),
--
--           -- Channel 13 **********************        
--           CH13_DEC_PTW_CNT => DEC_PTW_CNT14,
--           CH13_PTW_DATA_BLOCK_CNT => PTW_DATA_BLOCK_CNT14,            
--           CH13_HOST_BLOCK_CNT_REG => CH13_HOST_BLOCK_CNT,
--           CH13_DEC_BLOCK_CNT      => CH13_DEC_BLOCK_CNT_Q,           
--           CH13_PTW_RAM_DATA       => PTW13_RAM_DATA,
--           CH13_PTW_RAM_ADR        => PTW13_RAM_ADR,           
--           ---- To DATA Format block
--           CH13_PROC_ADR       => CH13_PROC_ADR_Q,   
--           CH13_PROC_OUTDAT    => CH13_PROC_OUTDAT,
--           TET13             => TET13(11 downto 0),
--
--           -- Channel 14 **********************        
--           CH14_DEC_PTW_CNT => DEC_PTW_CNT15,
--           CH14_PTW_DATA_BLOCK_CNT => PTW_DATA_BLOCK_CNT15,            
--           CH14_HOST_BLOCK_CNT_REG => CH14_HOST_BLOCK_CNT,
--           CH14_DEC_BLOCK_CNT      => CH14_DEC_BLOCK_CNT_Q,           
--           CH14_PTW_RAM_DATA       => PTW14_RAM_DATA,
--           CH14_PTW_RAM_ADR        => PTW14_RAM_ADR,           
--           ---- To DATA Format block
--           CH14_PROC_ADR       => CH14_PROC_ADR_Q,   
--           CH14_PROC_OUTDAT    => CH14_PROC_OUTDAT,
--           TET14               => TET14(11 downto 0),
--
--           -- Channel 15 **********************        
--           CH15_DEC_PTW_CNT => DEC_PTW_CNT16,
--           CH15_PTW_DATA_BLOCK_CNT => PTW_DATA_BLOCK_CNT16,           
--           CH15_HOST_BLOCK_CNT_REG => CH15_HOST_BLOCK_CNT,
--           CH15_DEC_BLOCK_CNT      => CH15_DEC_BLOCK_CNT_Q,           
--           CH15_PTW_RAM_DATA       => PTW15_RAM_DATA,
--           CH15_PTW_RAM_ADR        => PTW15_RAM_ADR, 
--           CH15_PROC_ADR       => CH15_PROC_ADR_Q,      
--           CH15_PROC_OUTDAT    => CH15_PROC_OUTDAT,     
--           TET15               => TET15(11 downto 0),              ---- To DATA Format block
           ModeFifoRdEn   => ModeFifoRdEn, 
           ModeFifoDout   => ModeFifoDout, 
           ModeFifoEmpty  => ModeFifoEmpty,
           ModeFifoFull   => ModeFifoFull, 
           
           CH0_Fist_Last_Proc_Adr     => CH0_Fist_Last_Proc_Adr,    
           CH0_Pop_Fist_Last_Proc_Adr => CH0_Pop_Fist_Last_Proc_Adr_Q,
           CH1_Fist_Last_Proc_Adr     => CH1_Fist_Last_Proc_Adr,    
           CH1_Pop_Fist_Last_Proc_Adr => CH1_Pop_Fist_Last_Proc_Adr_Q,
           CH2_Fist_Last_Proc_Adr     => CH2_Fist_Last_Proc_Adr,    
           CH2_Pop_Fist_Last_Proc_Adr => CH2_Pop_Fist_Last_Proc_Adr_Q,
           CH3_Fist_Last_Proc_Adr     => CH3_Fist_Last_Proc_Adr,    
           CH3_Pop_Fist_Last_Proc_Adr => CH3_Pop_Fist_Last_Proc_Adr_Q,
           CH4_Fist_Last_Proc_Adr     => CH4_Fist_Last_Proc_Adr,    
           CH4_Pop_Fist_Last_Proc_Adr => CH4_Pop_Fist_Last_Proc_Adr_Q,
           CH5_Fist_Last_Proc_Adr     => CH5_Fist_Last_Proc_Adr,    
           CH5_Pop_Fist_Last_Proc_Adr => CH5_Pop_Fist_Last_Proc_Adr_Q
--           CH6_Fist_Last_Proc_Adr     => CH6_Fist_Last_Proc_Adr,    
--           CH6_Pop_Fist_Last_Proc_Adr => CH6_Pop_Fist_Last_Proc_Adr_Q,
--           CH7_Fist_Last_Proc_Adr     => CH7_Fist_Last_Proc_Adr,    
--           CH7_Pop_Fist_Last_Proc_Adr => CH7_Pop_Fist_Last_Proc_Adr_Q,
--           CH8_Fist_Last_Proc_Adr     => CH8_Fist_Last_Proc_Adr,    
--           CH8_Pop_Fist_Last_Proc_Adr => CH8_Pop_Fist_Last_Proc_Adr_Q,
--           CH9_Fist_Last_Proc_Adr     => CH9_Fist_Last_Proc_Adr,    
--           CH9_Pop_Fist_Last_Proc_Adr => CH9_Pop_Fist_Last_Proc_Adr_Q,
--           CH10_Fist_Last_Proc_Adr     => CH10_Fist_Last_Proc_Adr,    
--           CH10_Pop_Fist_Last_Proc_Adr => CH10_Pop_Fist_Last_Proc_Adr_Q,
--           CH11_Fist_Last_Proc_Adr     => CH11_Fist_Last_Proc_Adr,    
--           CH11_Pop_Fist_Last_Proc_Adr => CH11_Pop_Fist_Last_Proc_Adr_Q,
--           CH12_Fist_Last_Proc_Adr     => CH12_Fist_Last_Proc_Adr,    
--           CH12_Pop_Fist_Last_Proc_Adr => CH12_Pop_Fist_Last_Proc_Adr_Q,
--           CH13_Fist_Last_Proc_Adr     => CH13_Fist_Last_Proc_Adr,    
--           CH13_Pop_Fist_Last_Proc_Adr => CH13_Pop_Fist_Last_Proc_Adr_Q,
--           CH14_Fist_Last_Proc_Adr     => CH14_Fist_Last_Proc_Adr,    
--           CH14_Pop_Fist_Last_Proc_Adr => CH14_Pop_Fist_Last_Proc_Adr_Q,
--           CH15_Fist_Last_Proc_Adr     => CH15_Fist_Last_Proc_Adr,    
--           CH15_Pop_Fist_Last_Proc_Adr => CH15_Pop_Fist_Last_Proc_Adr_Q

        );
   ---- **************************************************
   
   	O_NSA <= '0' & NSA;
	O_NSB <= '0' & NSA; 
	NSA_NSB_D <= O_NSA + O_NSB;
   
   --- FORMAT BLOCK  *************************************
    UDATAFORMAT : DATAFORMAT_VER2_TOP
        port map
         (
           CLK_HOST             => CLK,         
           RESET_N              => RESET_N,     
           SOFT_RESET_N         => SOFT_RESET_N,
           
           ---- From Host
           PTW                  => PTW(11 downto 0),
           COMBO_MODE           => MODE_TO_FORMAT(2),
           --MODE                 => MODE_TO_FORMAT(1 downto 0),
           LAST_PROC_BUF_ADR    => LAST_PROC_BUF_ADR,
           NSA_NSB              => NSA_NSB_Q,
                      
           ---- From DATA Format block
           Format_Idle     => Format_Idle,
           ModeFifoRdEn    => ModeFifoRdEn, 
           ModeFifoDout    => ModeFifoDout, 
           ModeFifoEmpty   => ModeFifoEmpty,
           PROC0_ADR       => CH0_PROC_ADR,
           PROC0_OUTDAT    => CH0_PROC_OUTDAT_Q,
           PROC1_ADR       => CH1_PROC_ADR,   
           PROC1_OUTDAT    => CH1_PROC_OUTDAT_Q,
           PROC2_ADR       => CH2_PROC_ADR,   
           PROC2_OUTDAT    => CH2_PROC_OUTDAT_Q,
           PROC3_ADR       => CH3_PROC_ADR,   
           PROC3_OUTDAT    => CH3_PROC_OUTDAT_Q,
           PROC4_ADR       => CH4_PROC_ADR,   
           PROC4_OUTDAT    => CH4_PROC_OUTDAT_Q,
           PROC5_ADR       => CH5_PROC_ADR,   
           PROC5_OUTDAT    => CH5_PROC_OUTDAT_Q,
--           PROC6_ADR       => CH6_PROC_ADR,   
--           PROC6_OUTDAT    => CH6_PROC_OUTDAT_Q,
--           PROC7_ADR       => CH7_PROC_ADR,   
--           PROC7_OUTDAT    => CH7_PROC_OUTDAT_Q,
--
--           PROC8_ADR       => CH8_PROC_ADR,
--           PROC8_OUTDAT    => CH8_PROC_OUTDAT_Q,
--           PROC9_ADR       => CH9_PROC_ADR,   
--           PROC9_OUTDAT    => CH9_PROC_OUTDAT_Q,
--           PROC10_ADR       => CH10_PROC_ADR,   
--           PROC10_OUTDAT    => CH10_PROC_OUTDAT_Q,
--           PROC11_ADR       => CH11_PROC_ADR,   
--           PROC11_OUTDAT    => CH11_PROC_OUTDAT_Q,
--           PROC12_ADR       => CH12_PROC_ADR,   
--           PROC12_OUTDAT    => CH12_PROC_OUTDAT_Q,
--           PROC13_ADR       => CH13_PROC_ADR,   
--           PROC13_OUTDAT    => CH13_PROC_OUTDAT_Q,
--           PROC14_ADR       => CH14_PROC_ADR,   
--           PROC14_OUTDAT    => CH14_PROC_OUTDAT_Q,
--           PROC15_ADR       => CH15_PROC_ADR,   
--           PROC15_OUTDAT    => CH15_PROC_OUTDAT_Q,

           HOST_BLOCK0_CNT => CH0_HOST_BLOCK_CNT_Q,
           DEC_BLOCK0_CNT  => CH0_DEC_BLOCK_CNT,
           HOST_BLOCK1_CNT => CH1_HOST_BLOCK_CNT_Q,
           DEC_BLOCK1_CNT  => CH1_DEC_BLOCK_CNT, 
           HOST_BLOCK2_CNT => CH2_HOST_BLOCK_CNT_Q,
           DEC_BLOCK2_CNT  => CH2_DEC_BLOCK_CNT, 
           HOST_BLOCK3_CNT => CH3_HOST_BLOCK_CNT_Q,
           DEC_BLOCK3_CNT  => CH3_DEC_BLOCK_CNT, 
           HOST_BLOCK4_CNT => CH4_HOST_BLOCK_CNT_Q,
           DEC_BLOCK4_CNT  => CH4_DEC_BLOCK_CNT, 
           HOST_BLOCK5_CNT => CH5_HOST_BLOCK_CNT_Q,
           DEC_BLOCK5_CNT  => CH5_DEC_BLOCK_CNT, 
--           HOST_BLOCK6_CNT => CH6_HOST_BLOCK_CNT_Q,
--           DEC_BLOCK6_CNT  => CH6_DEC_BLOCK_CNT, 
--           HOST_BLOCK7_CNT => CH7_HOST_BLOCK_CNT_Q,
--           DEC_BLOCK7_CNT  => CH7_DEC_BLOCK_CNT, 
--
--           HOST_BLOCK8_CNT => CH8_HOST_BLOCK_CNT,
--           DEC_BLOCK8_CNT  => CH8_DEC_BLOCK_CNT,
--           HOST_BLOCK9_CNT => CH9_HOST_BLOCK_CNT,
--           DEC_BLOCK9_CNT  => CH9_DEC_BLOCK_CNT, 
--           HOST_BLOCK10_CNT => CH10_HOST_BLOCK_CNT,
--           DEC_BLOCK10_CNT  => CH10_DEC_BLOCK_CNT, 
--           HOST_BLOCK11_CNT => CH11_HOST_BLOCK_CNT,
--           DEC_BLOCK11_CNT  => CH11_DEC_BLOCK_CNT, 
--           HOST_BLOCK12_CNT => CH12_HOST_BLOCK_CNT,
--           DEC_BLOCK12_CNT  => CH12_DEC_BLOCK_CNT, 
--           HOST_BLOCK13_CNT => CH13_HOST_BLOCK_CNT,
--           DEC_BLOCK13_CNT  => CH13_DEC_BLOCK_CNT, 
--           HOST_BLOCK14_CNT => CH14_HOST_BLOCK_CNT,
--           DEC_BLOCK14_CNT  => CH14_DEC_BLOCK_CNT, 
--           HOST_BLOCK15_CNT => CH15_HOST_BLOCK_CNT,
--           DEC_BLOCK15_CNT  => CH15_DEC_BLOCK_CNT, 

           CH0_Fist_Last_Proc_Adr     => CH0_Fist_Last_Proc_Adr_Q,    
           CH0_Pop_Fist_Last_Proc_Adr => CH0_Pop_Fist_Last_Proc_Adr,
           CH1_Fist_Last_Proc_Adr     => CH1_Fist_Last_Proc_Adr_Q,    
           CH1_Pop_Fist_Last_Proc_Adr => CH1_Pop_Fist_Last_Proc_Adr,
           CH2_Fist_Last_Proc_Adr     => CH2_Fist_Last_Proc_Adr_Q,    
           CH2_Pop_Fist_Last_Proc_Adr => CH2_Pop_Fist_Last_Proc_Adr,
           CH3_Fist_Last_Proc_Adr     => CH3_Fist_Last_Proc_Adr_BUF2_Q,    
           CH3_Pop_Fist_Last_Proc_Adr => CH3_Pop_Fist_Last_Proc_Adr,
           CH4_Fist_Last_Proc_Adr     => CH4_Fist_Last_Proc_Adr_Q,    
           CH4_Pop_Fist_Last_Proc_Adr => CH4_Pop_Fist_Last_Proc_Adr,
           CH5_Fist_Last_Proc_Adr     => CH5_Fist_Last_Proc_Adr_Q,    
           CH5_Pop_Fist_Last_Proc_Adr => CH5_Pop_Fist_Last_Proc_Adr,
--           CH6_Fist_Last_Proc_Adr     => CH6_Fist_Last_Proc_Adr_Q,    
--           CH6_Pop_Fist_Last_Proc_Adr => CH6_Pop_Fist_Last_Proc_Adr,
--           CH7_Fist_Last_Proc_Adr     => CH7_Fist_Last_Proc_Adr_Q,    
--           CH7_Pop_Fist_Last_Proc_Adr => CH7_Pop_Fist_Last_Proc_Adr,
--
--           CH8_Fist_Last_Proc_Adr     => CH8_Fist_Last_Proc_Adr_Q,    
--           CH8_Pop_Fist_Last_Proc_Adr => CH8_Pop_Fist_Last_Proc_Adr,
--           CH9_Fist_Last_Proc_Adr     => CH9_Fist_Last_Proc_Adr_Q,    
--           CH9_Pop_Fist_Last_Proc_Adr => CH9_Pop_Fist_Last_Proc_Adr,
--           CH10_Fist_Last_Proc_Adr     => CH10_Fist_Last_Proc_Adr_Q,    
--           CH10_Pop_Fist_Last_Proc_Adr => CH10_Pop_Fist_Last_Proc_Adr,
--           CH11_Fist_Last_Proc_Adr     => CH11_Fist_Last_Proc_Adr_Q,    
--           CH11_Pop_Fist_Last_Proc_Adr => CH11_Pop_Fist_Last_Proc_Adr,
--           CH12_Fist_Last_Proc_Adr     => CH12_Fist_Last_Proc_Adr_Q,    
--           CH12_Pop_Fist_Last_Proc_Adr => CH12_Pop_Fist_Last_Proc_Adr,
--           CH13_Fist_Last_Proc_Adr     => CH13_Fist_Last_Proc_Adr_Q,    
--           CH13_Pop_Fist_Last_Proc_Adr => CH13_Pop_Fist_Last_Proc_Adr,
--           CH14_Fist_Last_Proc_Adr     => CH14_Fist_Last_Proc_Adr_Q,    
--           CH14_Pop_Fist_Last_Proc_Adr => CH14_Pop_Fist_Last_Proc_Adr,
--           CH15_Fist_Last_Proc_Adr     => CH15_Fist_Last_Proc_Adr_Q,    
--           CH15_Pop_Fist_Last_Proc_Adr => CH15_Pop_Fist_Last_Proc_Adr,

           --- To Host FIFO IDT72V36100 pins
			  cid				   	 => cid,
           DATA_REG 				 => FIFO_DATA,
           WCLK_REG            => FIFO_WCLK,
           WEN_REG             => FIFO_WEN, 
           OE_N_REG            => FIFO_OE_N                 
        );

    ------ SUM ADC INPUTS    
    --USUM_TOP : SUM_VER2_TOP
    --    port map
    --     (
    --       CLK                  => CLK, 
    --       RESET_N              => RESET_N,
    --
    --
    --       ADC0_IN              => ADC_DATA_1_Q(11 downto 0),           
    --       ADC1_IN              => ADC_DATA_2_Q(11 downto 0),           
    --       ADC2_IN              => ADC_DATA_3_Q(11 downto 0),           
    --       ADC3_IN              => ADC_DATA_4_Q(11 downto 0),           
    --       ADC4_IN              => ADC_DATA_5_Q(11 downto 0),           
    --       ADC5_IN              => ADC_DATA_6_Q(11 downto 0),           
    --       ADC6_IN              => ADC_DATA_7_Q(11 downto 0),           
    --       ADC7_IN              => ADC_DATA_8_Q(11 downto 0),           
    --       ADC8_IN              => ADC_DATA_9_Q(11 downto 0),           
    --       ADC9_IN              => ADC_DATA_10_Q(11 downto 0),           
    --       ADC10_IN             => ADC_DATA_11_Q(11 downto 0),           
    --       ADC11_IN             => ADC_DATA_12_Q(11 downto 0),           
    --       ADC12_IN             => ADC_DATA_13_Q(11 downto 0),           
    --       ADC13_IN             => ADC_DATA_14_Q(11 downto 0),           
    --       ADC14_IN             => ADC_DATA_15_Q(11 downto 0),           
    --       ADC15_IN             => ADC_DATA_16_Q(11 downto 0),           
    --
    --       ----- Pedestal Subtraction
    --        PedSub0          =>    PedSub0, 
    --        PedSub1          =>    PedSub1, 
    --        PedSub2          =>    PedSub2, 
    --        PedSub3          =>    PedSub3, 
    --        PedSub4          =>    PedSub4, 
    --        PedSub5          =>    PedSub5, 
    --        PedSub6          =>    PedSub6, 
    --        PedSub7          =>    PedSub7, 
    --        PedSub8          =>    PedSub8, 
    --        PedSub9          =>    PedSub9, 
    --        PedSub10         =>    PedSub10,
    --        PedSub11         =>    PedSub11,
    --        PedSub12         =>    PedSub12,
    --        PedSub13         =>    PedSub13,
    --        PedSub14         =>    PedSub14,
    --        PedSub15         =>    PedSub15,
    --                  
    --       SUM                  => SUMP,  
    --       SUM_B                => SUMN,
    --       SUM_REG              => SUM_REG
    --   );
    --
    
--    UTriggerProcessing_TOP : TriggerProcessing_TOP                            
--      port map                                          
--         (                                             
--           CLK      => CLK,       --- 250 MHz      
--           RESET_N  => RESET_N,
--                                                                                             
--           SYNC        => SYNC_Q(2),
--           NSB             => TRIG_PATH_NSB,           -- Delay SampleIN by this number of CLK 
--           ThresholdValue  => TRIG_PATH_ThresholdValue,  --- From Host Register.
--           NSA             => TRIG_PATH_NSA,              ----   
--
--           ADC0_IN               => ADC_DATA_1_Q(11 downto 0),         
--           ADC1_IN               => ADC_DATA_2_Q(11 downto 0),         
--           ADC2_IN               => ADC_DATA_3_Q(11 downto 0),         
--           ADC3_IN               => ADC_DATA_4_Q(11 downto 0),         
--           ADC4_IN               => ADC_DATA_5_Q(11 downto 0),         
--           ADC5_IN               => ADC_DATA_6_Q(11 downto 0),         
----           ADC6_IN               => ADC_DATA_7_Q(11 downto 0),         
----           ADC7_IN               => ADC_DATA_8_Q(11 downto 0),                                          
----           ADC8_IN               => ADC_DATA_9_Q(11 downto 0),          
----           ADC9_IN               => ADC_DATA_10_Q(11 downto 0),         
----           ADC10_IN              => ADC_DATA_11_Q(11 downto 0),         
----           ADC11_IN              => ADC_DATA_12_Q(11 downto 0),         
----           ADC12_IN              => ADC_DATA_13_Q(11 downto 0),         
----           ADC13_IN              => ADC_DATA_14_Q(11 downto 0),         
----           ADC14_IN              => ADC_DATA_15_Q(11 downto 0),         
----           ADC15_IN              => ADC_DATA_16_Q(11 downto 0),          
--
--           ----- Pedestal Subtraction
--            PedSub0          =>    PedSub0(11 downto 0), 
--            PedSub1          =>    PedSub1(11 downto 0), 
--            PedSub2          =>    PedSub2(11 downto 0), 
--            PedSub3          =>    PedSub3(11 downto 0), 
--            PedSub4          =>    PedSub4(11 downto 0), 
--            PedSub5          =>    PedSub5(11 downto 0), 
----            PedSub6          =>    PedSub6(11 downto 0), 
----            PedSub7          =>    PedSub7(11 downto 0), 
----            PedSub8          =>    PedSub8(11 downto 0), 
----            PedSub9          =>    PedSub9(11 downto 0), 
----            PedSub10         =>    PedSub10(11 downto 0),
----            PedSub11         =>    PedSub11(11 downto 0),
----            PedSub12         =>    PedSub12(11 downto 0),
----            PedSub13         =>    PedSub13(11 downto 0),
----            PedSub14         =>    PedSub14(11 downto 0),
----            PedSub15         =>    PedSub15(11 downto 0),
--           
--           SUM                  => SUMP,
--           SUM_B                => SUMN,
--           SUMP2_DV             => SUMP2_DV,
--           SUMN2_DV             => SUMN2_DV
--        );


   ----- HIT BITS
--   UHIT_BITS_ALL_TOP : HIT_BITS_ALL_VER2_TOP
--      port map
--         (
--           CLK                  => CLK,     
--           RESET_N              => RESET_N,
-- 
--           --- Data From 8 ADC. Each consist of 12 data bits
--           ADC1_DATA            => ADC_DATA_1_Q(11 downto 0),  
--           ADC2_DATA            => ADC_DATA_2_Q(11 downto 0),  
--           ADC3_DATA            => ADC_DATA_3_Q(11 downto 0),  
--           ADC4_DATA            => ADC_DATA_4_Q(11 downto 0), 
--           ADC5_DATA            => ADC_DATA_5_Q(11 downto 0), 
--           ADC6_DATA            => ADC_DATA_6_Q(11 downto 0), 
--           ADC7_DATA            => ADC_DATA_7_Q(11 downto 0), 
--           ADC8_DATA            => ADC_DATA_8_Q(11 downto 0), 
--           ADC9_DATA            => ADC_DATA_9_Q(11 downto 0),  
--           ADC10_DATA           => ADC_DATA_10_Q(11 downto 0),  
--           ADC11_DATA           => ADC_DATA_11_Q(11 downto 0),  
--           ADC12_DATA           => ADC_DATA_12_Q(11 downto 0), 
--           ADC13_DATA           => ADC_DATA_13_Q(11 downto 0), 
--           ADC14_DATA           => ADC_DATA_14_Q(11 downto 0), 
--           ADC15_DATA           => ADC_DATA_15_Q(11 downto 0), 
--           ADC16_DATA           => ADC_DATA_16_Q(11 downto 0), 
--           
--           --- Trigger Thredshold. From Host
--           TET0             => TET0(11 downto 0), 
--           TET1             => TET1(11 downto 0), 
--           TET2             => TET2(11 downto 0), 
--           TET3             => TET3(11 downto 0), 
--           TET4             => TET4(11 downto 0), 
--           TET5             => TET5(11 downto 0), 
--           TET6             => TET6(11 downto 0), 
--           TET7             => TET7(11 downto 0), 
--           TET8             => TET8(11 downto 0), 
--           TET9             => TET9(11 downto 0), 
--           TET10            => TET10(11 downto 0), 
--           TET11            => TET11(11 downto 0), 
--           TET12            => TET12(11 downto 0), 
--           TET13            => TET13(11 downto 0), 
--           TET14            => TET14(11 downto 0), 
--           TET15            => TET15(11 downto 0), 
--                      
--           HITBIT_DV_REG       => HITBIT_DV_REG,
--           HITBIT_N_REG        => HITBIT_N_REG  
--        );

    REG_RESET_RESYNC : process (CLK)
      begin
        if rising_edge(CLK) then
          SYNC_Q  <= SYNC_D;
        end if;
      end process REG_RESET_RESYNC;


    REG : process (CLK, RESET_N)
      begin
        if RESET_N = '0' then
          ADC_DATA_1_Q <= (others => '0');
          ADC_DATA_2_Q <= (others => '0');
          ADC_DATA_3_Q <= (others => '0');
          ADC_DATA_4_Q <= (others => '0');
          ADC_DATA_5_Q <= (others => '0');
          ADC_DATA_6_Q <= (others => '0');
--          ADC_DATA_7_Q <= (others => '0');
--          ADC_DATA_8_Q <= (others => '0');
--          ADC_DATA_9_Q <= (others => '0');
--          ADC_DATA_10_Q <= (others => '0');
--          ADC_DATA_11_Q <= (others => '0');
--          ADC_DATA_12_Q <= (others => '0');
--          ADC_DATA_13_Q <= (others => '0');
--          ADC_DATA_14_Q <= (others => '0');
--          ADC_DATA_15_Q <= (others => '0');
--          ADC_DATA_16_Q <= (others => '0');
          PTW_WORDS_MINUS_ONE_Q <= (others => '0');
          TRIGGER_N_Q  <= '0';
          TRIGGER_N_DLY_Q <= '0';
          PTW_TS_TN_WORDS_Q <= (others => '0');
          --NSB_MINUS_2_Q  <= (others => '0');  
          --NSA_MINUS7_Q   <= (others => '0');
          COLLECT_ON_Q   <= '0';
          --NSA_MINUS1_Q   <= (others => '0');
          NSA_NSB_Q <= (others => '0');
          SYS_STATUS0_Q <= (others => '0');
          SYS_STATUS1_Q <= (others => '0');
          TRIGGER_Q <= (others => '1');
          NSA_Q     <= (others => '0');
          CH0_PROC_ADR_Q     <= (others => '0');
          CH0_PROC_OUTDAT_Q  <= (others => '0');
          CH1_PROC_ADR_Q     <= (others => '0');
          CH1_PROC_OUTDAT_Q  <= (others => '0');
          CH2_PROC_ADR_Q     <= (others => '0');
          CH2_PROC_OUTDAT_Q  <= (others => '0');
          CH3_PROC_ADR_Q     <= (others => '0');
          CH3_PROC_OUTDAT_Q  <= (others => '0');
          CH4_PROC_ADR_Q     <= (others => '0');
          CH4_PROC_OUTDAT_Q  <= (others => '0');
          CH5_PROC_ADR_Q     <= (others => '0');
          CH5_PROC_OUTDAT_Q  <= (others => '0');
--          CH6_PROC_ADR_Q     <= (others => '0');
--          CH6_PROC_OUTDAT_Q  <= (others => '0');
--          CH7_PROC_ADR_Q     <= (others => '0');
--          CH7_PROC_OUTDAT_Q  <= (others => '0');
--          CH8_PROC_ADR_Q     <= (others => '0');
--          CH8_PROC_OUTDAT_Q  <= (others => '0');
--          CH9_PROC_ADR_Q     <= (others => '0');
--          CH9_PROC_OUTDAT_Q  <= (others => '0');
--          CH10_PROC_ADR_Q    <= (others => '0');
--          CH10_PROC_OUTDAT_Q <= (others => '0');
--          CH11_PROC_ADR_Q    <= (others => '0');
--          CH11_PROC_OUTDAT_Q <= (others => '0');
--          CH12_PROC_ADR_Q    <= (others => '0');
--          CH12_PROC_OUTDAT_Q <= (others => '0');
--          CH13_PROC_ADR_Q    <= (others => '0');
--          CH13_PROC_OUTDAT_Q <= (others => '0');
--          CH14_PROC_ADR_Q    <= (others => '0');
--          CH14_PROC_OUTDAT_Q <= (others => '0');
--          CH15_PROC_ADR_Q    <= (others => '0');
--          CH15_PROC_OUTDAT_Q <= (others => '0');
          CH0_HOST_BLOCK_CNT_Q <= (others => '0'); 
          CH1_HOST_BLOCK_CNT_Q <= (others => '0'); 
          CH2_HOST_BLOCK_CNT_Q <= (others => '0'); 
          CH3_HOST_BLOCK_CNT_Q <= (others => '0'); 
          CH4_HOST_BLOCK_CNT_Q <= (others => '0'); 
          CH5_HOST_BLOCK_CNT_Q <= (others => '0'); 
--          CH6_HOST_BLOCK_CNT_Q <= (others => '0'); 
--          CH7_HOST_BLOCK_CNT_Q <= (others => '0'); 
--          CH8_HOST_BLOCK_CNT_Q <= (others => '0'); 
--          CH9_HOST_BLOCK_CNT_Q <= (others => '0'); 
--          CH10_HOST_BLOCK_CNT_Q <= (others => '0');
--          CH11_HOST_BLOCK_CNT_Q <= (others => '0');
--          CH12_HOST_BLOCK_CNT_Q <= (others => '0');
--          CH13_HOST_BLOCK_CNT_Q <= (others => '0');
--          CH14_HOST_BLOCK_CNT_Q <= (others => '0');
--          CH15_HOST_BLOCK_CNT_Q <= (others => '0');
          CH0_DEC_BLOCK_CNT_Q  <= '0';            
          CH1_DEC_BLOCK_CNT_Q  <= '0';            
          CH2_DEC_BLOCK_CNT_Q  <= '0';            
          CH3_DEC_BLOCK_CNT_Q  <= '0';            
          CH4_DEC_BLOCK_CNT_Q  <= '0';            
          CH5_DEC_BLOCK_CNT_Q  <= '0';            
--          CH6_DEC_BLOCK_CNT_Q  <= '0';            
--          CH7_DEC_BLOCK_CNT_Q  <= '0';            
--          CH8_DEC_BLOCK_CNT_Q  <= '0';            
--          CH9_DEC_BLOCK_CNT_Q  <= '0';            
--          CH10_DEC_BLOCK_CNT_Q <= '0';            
--          CH11_DEC_BLOCK_CNT_Q <= '0';            
--          CH12_DEC_BLOCK_CNT_Q <= '0';            
--          CH13_DEC_BLOCK_CNT_Q <= '0';            
--          CH14_DEC_BLOCK_CNT_Q <= '0';            
--          CH15_DEC_BLOCK_CNT_Q <= '0';            
          CH0_Fist_Last_Proc_Adr_Q     <= (others => '0');
          CH0_Pop_Fist_Last_Proc_Adr_Q <= '0';  
          CH1_Fist_Last_Proc_Adr_Q     <= (others => '0'); 
          CH1_Pop_Fist_Last_Proc_Adr_Q <= '0';             
          CH2_Fist_Last_Proc_Adr_Q     <= (others => '0'); 
          CH2_Pop_Fist_Last_Proc_Adr_Q <= '0';             
          CH3_Fist_Last_Proc_Adr_Q     <= (others => '0');
          CH3_Fist_Last_Proc_Adr_BUF2_Q <= (others => '0'); 
          CH3_Pop_Fist_Last_Proc_Adr_Q <= '0';             
          CH4_Fist_Last_Proc_Adr_Q     <= (others => '0'); 
          CH4_Pop_Fist_Last_Proc_Adr_Q <= '0';             
          CH5_Fist_Last_Proc_Adr_Q     <= (others => '0'); 
          CH5_Pop_Fist_Last_Proc_Adr_Q <= '0';             
--          CH6_Fist_Last_Proc_Adr_Q     <= (others => '0'); 
--          CH6_Pop_Fist_Last_Proc_Adr_Q <= '0';             
--          CH7_Fist_Last_Proc_Adr_Q     <= (others => '0'); 
--          CH7_Pop_Fist_Last_Proc_Adr_Q <= '0';             
--          CH8_Fist_Last_Proc_Adr_Q     <= (others => '0'); 
--          CH8_Pop_Fist_Last_Proc_Adr_Q <= '0';             
--          CH9_Fist_Last_Proc_Adr_Q     <= (others => '0'); 
--          CH9_Pop_Fist_Last_Proc_Adr_Q <= '0';             
--          CH10_Fist_Last_Proc_Adr_Q      <= (others => '0');
--          CH10_Pop_Fist_Last_Proc_Adr_Q  <= '0';            
--          CH11_Fist_Last_Proc_Adr_Q      <= (others => '0');
--          CH11_Pop_Fist_Last_Proc_Adr_Q  <= '0';            
--          CH12_Fist_Last_Proc_Adr_Q      <= (others => '0');
--          CH12_Pop_Fist_Last_Proc_Adr_Q  <= '0';            
--          CH13_Fist_Last_Proc_Adr_Q      <= (others => '0');
--          CH13_Pop_Fist_Last_Proc_Adr_Q  <= '0';            
--          CH14_Fist_Last_Proc_Adr_Q      <= (others => '0');
--          CH14_Pop_Fist_Last_Proc_Adr_Q  <= '0';            
--          CH15_Fist_Last_Proc_Adr_Q      <= (others => '0');
--          CH15_Pop_Fist_Last_Proc_Adr_Q  <= '0';
          COLLECT_ON_BUF_Q <= '0';            
        elsif rising_edge(CLK) then
          ADC_DATA_1_Q <= ADC_DATA_1_D;
          ADC_DATA_2_Q <= ADC_DATA_2_D;
          ADC_DATA_3_Q <= ADC_DATA_3_D;
          ADC_DATA_4_Q <= ADC_DATA_4_D;
          ADC_DATA_5_Q <= ADC_DATA_5_D;
          ADC_DATA_6_Q <= ADC_DATA_6_D;
--          ADC_DATA_7_Q <= ADC_DATA_7_D;
--          ADC_DATA_8_Q <= ADC_DATA_8_D;
--          ADC_DATA_9_Q <= ADC_DATA_9_D;
--          ADC_DATA_10_Q <= ADC_DATA_10_D;
--          ADC_DATA_11_Q <= ADC_DATA_11_D;
--          ADC_DATA_12_Q <= ADC_DATA_12_D;
--          ADC_DATA_13_Q <= ADC_DATA_13_D;
--          ADC_DATA_14_Q <= ADC_DATA_14_D;
--          ADC_DATA_15_Q <= ADC_DATA_15_D;
--          ADC_DATA_16_Q <= ADC_DATA_16_D;
          PTW_WORDS_MINUS_ONE_Q <= PTW_WORDS_MINUS_ONE_D;
          TRIGGER_N_Q  <= TRIGGER_N_D;
          TRIGGER_N_DLY_Q <= TRIGGER_N_DLY_D;
          PTW_TS_TN_WORDS_Q <= PTW_TS_TN_WORDS_D;
          --NSB_MINUS_2_Q  <= NSB_MINUS_2_D;  
          --NSA_MINUS7_Q   <= NSA_MINUS7_D;
          COLLECT_ON_Q   <= COLLECT_ON_D;
          --NSA_MINUS1_Q   <= NSA_MINUS1_D;
          NSA_NSB_Q <= NSA_NSB_D;
          SYS_STATUS0_Q <= SYS_STATUS0_D;
          SYS_STATUS1_Q <= SYS_STATUS1_D;
          TRIGGER_Q <= TRIGGER_D; 
          NSA_Q     <= NSA_D;
          PlayBack_WV_OUT_BUF_Q <= PlayBack_WV_OUT_BUF_D;
          CH0_PROC_ADR_Q     <= CH0_PROC_ADR;
          CH0_PROC_OUTDAT_Q  <= CH0_PROC_OUTDAT;
          CH1_PROC_ADR_Q     <= CH1_PROC_ADR;
          CH1_PROC_OUTDAT_Q  <= CH1_PROC_OUTDAT;
          CH2_PROC_ADR_Q     <= CH2_PROC_ADR;
          CH2_PROC_OUTDAT_Q  <= CH2_PROC_OUTDAT;
          CH3_PROC_ADR_Q     <= CH3_PROC_ADR;
          CH3_PROC_OUTDAT_Q  <= CH3_PROC_OUTDAT;
          CH4_PROC_ADR_Q     <= CH4_PROC_ADR;
          CH4_PROC_OUTDAT_Q  <= CH4_PROC_OUTDAT;
          CH5_PROC_ADR_Q     <= CH5_PROC_ADR;
          CH5_PROC_OUTDAT_Q  <= CH5_PROC_OUTDAT;
--          CH6_PROC_ADR_Q     <= CH6_PROC_ADR;
--          CH6_PROC_OUTDAT_Q  <= CH6_PROC_OUTDAT;
--          CH7_PROC_ADR_Q     <= CH7_PROC_ADR;
--          CH7_PROC_OUTDAT_Q  <= CH7_PROC_OUTDAT;
--          CH8_PROC_ADR_Q     <= CH8_PROC_ADR;
--          CH8_PROC_OUTDAT_Q  <= CH8_PROC_OUTDAT;
--          CH9_PROC_ADR_Q     <= CH9_PROC_ADR;
--          CH9_PROC_OUTDAT_Q  <= CH9_PROC_OUTDAT;
--          CH10_PROC_ADR_Q    <= CH10_PROC_ADR;
--          CH10_PROC_OUTDAT_Q <= CH10_PROC_OUTDAT;
--          CH11_PROC_ADR_Q    <= CH11_PROC_ADR;
--          CH11_PROC_OUTDAT_Q <= CH11_PROC_OUTDAT;
--          CH12_PROC_ADR_Q    <= CH12_PROC_ADR;
--          CH12_PROC_OUTDAT_Q <= CH12_PROC_OUTDAT;
--          CH13_PROC_ADR_Q    <= CH13_PROC_ADR;
--          CH13_PROC_OUTDAT_Q <= CH13_PROC_OUTDAT;
--          CH14_PROC_ADR_Q    <= CH14_PROC_ADR;
--          CH14_PROC_OUTDAT_Q <= CH14_PROC_OUTDAT;
--          CH15_PROC_ADR_Q    <= CH15_PROC_ADR;
--          CH15_PROC_OUTDAT_Q <= CH15_PROC_OUTDAT;
          CH0_HOST_BLOCK_CNT_Q <= CH0_HOST_BLOCK_CNT; 
          CH1_HOST_BLOCK_CNT_Q <= CH1_HOST_BLOCK_CNT; 
          CH2_HOST_BLOCK_CNT_Q <= CH2_HOST_BLOCK_CNT; 
          CH3_HOST_BLOCK_CNT_Q <= CH3_HOST_BLOCK_CNT; 
          CH4_HOST_BLOCK_CNT_Q <= CH4_HOST_BLOCK_CNT; 
          CH5_HOST_BLOCK_CNT_Q <= CH5_HOST_BLOCK_CNT; 
--          CH6_HOST_BLOCK_CNT_Q <= CH6_HOST_BLOCK_CNT; 
--          CH7_HOST_BLOCK_CNT_Q <= CH7_HOST_BLOCK_CNT; 
--          CH8_HOST_BLOCK_CNT_Q <= CH8_HOST_BLOCK_CNT; 
--          CH9_HOST_BLOCK_CNT_Q <= CH9_HOST_BLOCK_CNT; 
--          CH10_HOST_BLOCK_CNT_Q <= CH10_HOST_BLOCK_CNT;
--          CH11_HOST_BLOCK_CNT_Q <= CH11_HOST_BLOCK_CNT;
--          CH12_HOST_BLOCK_CNT_Q <= CH12_HOST_BLOCK_CNT;
--          CH13_HOST_BLOCK_CNT_Q <= CH13_HOST_BLOCK_CNT;
--          CH14_HOST_BLOCK_CNT_Q <= CH14_HOST_BLOCK_CNT;
--          CH15_HOST_BLOCK_CNT_Q <= CH15_HOST_BLOCK_CNT;
          CH0_DEC_BLOCK_CNT_Q  <= CH0_DEC_BLOCK_CNT;            
          CH1_DEC_BLOCK_CNT_Q  <= CH1_DEC_BLOCK_CNT;            
          CH2_DEC_BLOCK_CNT_Q  <= CH2_DEC_BLOCK_CNT;            
          CH3_DEC_BLOCK_CNT_Q  <= CH3_DEC_BLOCK_CNT;            
          CH4_DEC_BLOCK_CNT_Q  <= CH4_DEC_BLOCK_CNT;            
          CH5_DEC_BLOCK_CNT_Q  <= CH5_DEC_BLOCK_CNT;            
--          CH6_DEC_BLOCK_CNT_Q  <= CH6_DEC_BLOCK_CNT;            
--          CH7_DEC_BLOCK_CNT_Q  <= CH7_DEC_BLOCK_CNT;            
--          CH8_DEC_BLOCK_CNT_Q  <= CH8_DEC_BLOCK_CNT;            
--          CH9_DEC_BLOCK_CNT_Q  <= CH9_DEC_BLOCK_CNT;            
--          CH10_DEC_BLOCK_CNT_Q <= CH10_DEC_BLOCK_CNT;            
--          CH11_DEC_BLOCK_CNT_Q <= CH11_DEC_BLOCK_CNT;            
--          CH12_DEC_BLOCK_CNT_Q <= CH12_DEC_BLOCK_CNT;            
--          CH13_DEC_BLOCK_CNT_Q <= CH13_DEC_BLOCK_CNT;            
--          CH14_DEC_BLOCK_CNT_Q <= CH14_DEC_BLOCK_CNT;            
--          CH15_DEC_BLOCK_CNT_Q <= CH15_DEC_BLOCK_CNT;            
          CH0_Fist_Last_Proc_Adr_Q     <= CH0_Fist_Last_Proc_Adr;
          CH0_Pop_Fist_Last_Proc_Adr_Q <= CH0_Pop_Fist_Last_Proc_Adr;
          CH1_Fist_Last_Proc_Adr_Q     <= CH1_Fist_Last_Proc_Adr; 
          CH1_Pop_Fist_Last_Proc_Adr_Q <= CH1_Pop_Fist_Last_Proc_Adr; 
          CH2_Fist_Last_Proc_Adr_Q     <= CH2_Fist_Last_Proc_Adr; 
          CH2_Pop_Fist_Last_Proc_Adr_Q <= CH2_Pop_Fist_Last_Proc_Adr;  
          CH3_Fist_Last_Proc_Adr_Q     <= CH3_Fist_Last_Proc_Adr;
          CH3_Fist_Last_Proc_Adr_BUF2_Q <= CH3_Fist_Last_Proc_Adr_Q; 
          CH3_Pop_Fist_Last_Proc_Adr_Q <= CH3_Pop_Fist_Last_Proc_Adr; 
          CH4_Fist_Last_Proc_Adr_Q     <= CH4_Fist_Last_Proc_Adr; 
          CH4_Pop_Fist_Last_Proc_Adr_Q <= CH4_Pop_Fist_Last_Proc_Adr;  
          CH5_Fist_Last_Proc_Adr_Q     <= CH5_Fist_Last_Proc_Adr; 
          CH5_Pop_Fist_Last_Proc_Adr_Q <= CH5_Pop_Fist_Last_Proc_Adr;  
--          CH6_Fist_Last_Proc_Adr_Q     <= CH6_Fist_Last_Proc_Adr; 
--          CH6_Pop_Fist_Last_Proc_Adr_Q <= CH6_Pop_Fist_Last_Proc_Adr;  
--          CH7_Fist_Last_Proc_Adr_Q     <= CH7_Fist_Last_Proc_Adr; 
--          CH7_Pop_Fist_Last_Proc_Adr_Q <= CH7_Pop_Fist_Last_Proc_Adr;  
--          CH8_Fist_Last_Proc_Adr_Q     <= CH8_Fist_Last_Proc_Adr; 
--          CH8_Pop_Fist_Last_Proc_Adr_Q <= CH8_Pop_Fist_Last_Proc_Adr;  
--          CH9_Fist_Last_Proc_Adr_Q     <= CH9_Fist_Last_Proc_Adr; 
--          CH9_Pop_Fist_Last_Proc_Adr_Q <= CH9_Pop_Fist_Last_Proc_Adr;  
--          CH10_Fist_Last_Proc_Adr_Q      <= CH10_Fist_Last_Proc_Adr;
--          CH10_Pop_Fist_Last_Proc_Adr_Q  <= CH10_Pop_Fist_Last_Proc_Adr; 
--          CH11_Fist_Last_Proc_Adr_Q      <= CH11_Fist_Last_Proc_Adr;
--          CH11_Pop_Fist_Last_Proc_Adr_Q  <= CH11_Pop_Fist_Last_Proc_Adr; 
--          CH12_Fist_Last_Proc_Adr_Q      <= CH12_Fist_Last_Proc_Adr;
--          CH12_Pop_Fist_Last_Proc_Adr_Q  <= CH12_Pop_Fist_Last_Proc_Adr; 
--          CH13_Fist_Last_Proc_Adr_Q      <= CH13_Fist_Last_Proc_Adr;
--          CH13_Pop_Fist_Last_Proc_Adr_Q  <= CH13_Pop_Fist_Last_Proc_Adr; 
--          CH14_Fist_Last_Proc_Adr_Q      <= CH14_Fist_Last_Proc_Adr;
--          CH14_Pop_Fist_Last_Proc_Adr_Q  <= CH14_Pop_Fist_Last_Proc_Adr; 
--          CH15_Fist_Last_Proc_Adr_Q      <= CH15_Fist_Last_Proc_Adr;
--          CH15_Pop_Fist_Last_Proc_Adr_Q  <= CH15_Pop_Fist_Last_Proc_Adr; 
          COLLECT_ON_BUF_Q <= COLLECT_ON_Q;            
         end if;
      end process REG;

    REGSLOW : process (CLK_HOST, RESET_N)
      begin
        if RESET_N = '0' then
        elsif (CLK_HOST = '1' and CLK_HOST'event) then
        end if;
      end process;
end RTL;
