--  Author:  Cody Dickover
--  Filename: PROCESSING_TOP.vhd 
--  Date: 4/30/15
--	Full RE-Write: algorithm descriptions to come 

library IEEE;
	use IEEE.std_logic_1164.all;
	use IEEE.std_logic_unsigned.all; 
	use IEEE.std_logic_arith.all;
  	use IEEE.NUMERIC_STD.all;
	  
library work;
	use work.package_EFACV2.all; 

entity PROCESSING_TOP is
        port
         (
				CLK_PROCESS          : in std_logic; 
				--CLK_HOST             : in std_logic; 
				RESET_N              : in  std_logic;
--				SOFT_RESET_N         : in std_logic;
				PTW          		: in  std_logic_vector(9 downto 0); -- NW
				--cid					: in std_logic_vector(3 downto 0);
				--CH					: in std_logic_vector(2 downto 0);
				CHANNEL_NUMBER		: in std_logic_vector(6 downto 0);
				
				NP					: in std_logic_vector(7 downto 0); -- number of samples for initial pedestal
				NP2					: in std_logic_vector(7 downto 0);	-- number of samples for local pedestal
					
				IBIT				: in std_logic_vector(2 downto 0);					
				ABIT				: in std_logic_vector(2 downto 0);
				PBIT				: in std_logic_vector(2 downto 0); 
				
				-- NEW REGS
--				NSAMPLES			: in std_logic_vector(7 downto 0);   -- max number of ADC samples to read in   --int 16
				
--	   			XTHR_SAMPLE			: in std_logic_vector(7 downto 0); -- the 5 sigma thres xing is sample[9] passed into the algo, starting with sample[0]
--	    		PED_SAMPLE 			: in std_logic_vector(7 downto 0); -- take local ped as sample[5]
	    
	    		THRES_HI			: in std_logic_vector(8 downto 0); -- 4 sigma --int 80
	    		THRES_LO			: in std_logic_vector(7 downto 0); -- 1 sigma --int 20
	
--	    		ROUGH_DT 			: in std_logic_vector(7 downto 0);   --if algo fails, return this many tenth-samples before threshold xing --int 24
--	    		INT_SAMPLE 			: in std_logic_vector(7 downto 0); -- if algo fails, start integration with this sample
	    
--	    		LIMIT_ADC_MAX 		: in std_logic_vector(15 downto 0);  -- return rough time if ADC sample exceeds this value --int 4096
--	    		LIMIT_PED_MAX 		: in std_logic_vector(15 downto 0);  -- return rough time if pedestal exceeds this --int 511
	
--	    		SET_ADC_MIN 		: in std_logic_vector(15 downto 0);  -- set min value of ADC sample subset equal to this  --int 20
--	    		LIMIT_UPS_ERR 		: in std_logic_vector(15 downto 0);  -- return midpoint time if sum of upsampling errors exceeds this --int 30	
					
				IE 					: in std_logic_vector(11 downto 0);
				PG					: in std_logic_vector(7 downto 0);
				
				--ChannelZero          : in std_logic;  -- Not to block TimeStamp word for no event for channel 0.  Tie to 1 foe Channel 0  
				MODE                 : in std_logic_vector(2 downto 0); 

				MAX_NUMBER_OF_PULSE  : in std_logic_vector(5 downto 0);  -- need to increase and implement
				PROCESS_GO           : in std_logic;     --- start Process a mode
				PROCESS_DONE         : out std_logic;    --- Done process a mode

				--DEC_PTW_CNT 			: out std_logic;  --- Rising egde decrease number of PTW Data Block ready to process by one.
				--PTW_DATA_BLOCK_CNT 	: in std_logic_vector(7 downto 0);  --- not use
				BLOCK_VALUE_THRESHOLD: in std_logic_VECTOR(11 downto 0); -- HIT THRESHOLD

				HOST_BLOCK_CNT_REG 	: out std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for host
				DEC_BLOCK_CNT 			: in std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one

				--HOST_BLOCK_OVERFLOW : out std_logic;        
				PTW_RAM_DATA   		: in std_logic_vector(11 downto 0);
				PTW_RAM_ADR    		: out std_logic_vector(9 downto 0);    --- expects four clock delay from ADR change to DATA change
				--OVERFLOW		    : in std_logic;
				
				---- From processing ALL
				LD_PTW_RAM_ADR    	: in std_logic;  --- if no multi-mode processing, tied lo
				SAVED_PTW_RAM_ADR 	: in std_logic_vector(9 downto 0);  --- if no multi-mode processing, tied lo           

				PR_FIFO_RD_EN			: in std_logic;	
				NEW_PROC_OUTDAT		: out std_logic_VECTOR(31 downto 0)           
        );
end PROCESSING_TOP;

architecture RTL of PROCESSING_TOP is
     
  signal RST : std_logic;  
  
  signal PROCESS_BUF_DATA : std_logic_vector(17 downto 0); -- changed to 32 bit
  signal NEW_PROCESS_BUF_DATA : std_logic_vector(31 downto 0);
  signal NEW_PROCESS_BUF_DATA_D, NEW_PROCESS_BUF_DATA_Q: std_logic_vector(31 downto 0);
  signal LAST_PTW_BUF_ADR_D : std_logic;
  signal LAST_PTW_BUF_ADR_Q : std_logic;
  
  signal ProcAdrHist_Din : std_logic_vector(11 downto 0);

  --- Start Processing
  signal PTW_DATA_BUF_RDY_D : std_logic;
  signal PTW_DATA_BUF_RDY_Q : std_logic;  -- not use
    
  --- PTW Data Buffer
  signal LAST_MD1_DATA_D : std_logic_vector(2 downto 0);
--  signal LAST_MD1_DATA_Q : std_logic_vector(2 downto 0);
  signal CLR_PTW_DONE    : std_logic;
  signal PTW_DONE        : std_logic;
  
  signal PTW_PTR_EN   : std_logic; -- Enable PTW_PTR_Q to count up

  signal RD_PTW_PTR_D : std_logic_vector(9 downto 0);  --- Pointer to read PTW =  PTW_PTR_Q - NSB;
  signal RD_PTW_PTR_Q : std_logic_vector(9 downto 0);
  signal SAVE_RD_PTW_PTR_D : std_logic_vector(9 downto 0);  --- Save pointer to read PTW =  PTW_PTR_Q - NSB;
  signal SAVE_RD_PTW_PTR_Q : std_logic_vector(9 downto 0);
  signal RD_PTW_PTR_SAVED_D : std_logic_vector(11 downto 0);  --- Save pointer to read PTW =  PTW_PTR_Q - NSB;
  signal RD_PTW_PTR_SAVED_Q : std_logic_vector(11 downto 0); 
  signal NP2_PTW_PTR : std_logic_vector(9 downto 0); 

  signal RD_PTW_PTR_EN : std_logic;
  signal RD_PTW_PTR_EN_1 : std_logic;
  signal RD_PTW_PTR_EN_2 : std_logic;

  signal DONE_WR_TS    : std_logic;
  signal CLR_ABOVE_THREDHOLD : std_logic;

  ---- Host Data Buffer 
  signal WR_PTR_D     : std_logic_vector(10 downto 0);  --- Pointer to write data to output buffer                     
  signal WR_PTR_Q     : std_logic_vector(10 downto 0);  --- Pointer to write data to output buffer
  signal WR_PTR_CNT_EN_D : std_logic;
  signal WR_PTR_CNT_EN_Q : std_logic;
  signal WR_PTR_CNT_EN_1 : std_logic; 

  signal LAST_HOST_BUF_ADR_D : std_logic; -- 
--  signal LAST_HOST_BUF_ADR_Q : std_logic;
  signal PROCESS_BUF_WEN_D : std_logic;
  signal PROCESS_BUF_WEN_Q : std_logic;
  signal PROBUFWEN1 : std_logic; 

  signal SEL_PULSE_TIMER_D : std_logic_vector(2 downto 0);
--  signal SEL_PULSE_TIMER_Q : std_logic_vector(2 downto 0);

  ---- Keeping Track of number of block ready to send to VME IFACE
  signal HOST_BLOCK_CNT_D  : std_logic_VECTOR(6 downto 0) := "0000000"; -- number of Data Block Ready to send to host
  signal HOST_BLOCK_CNT_Q  : std_logic_VECTOR(6 downto 0) := "0000000"; -- number of Data Block Ready to send to host
  --signal HOST_BLOCK_INC_PENDING_D : std_logic;  --- remember to increment HOST_BLOCK_CNT_Q. Set when HOST_BLOCK_INC. Reset when PHOST_BLOCK_INC = '1'
  --signal HOST_BLOCK_INC_PENDING_Q : std_logic; 
  signal PHOST_BLOCK_INC : std_logic;  -- rising edge increment HOST_BLOCK_CNT_D
  signal HOST_BLOCK_INC_D : std_logic;  
  signal HOST_BLOCK_INC_Q : std_logic;
  signal HOST_BLOCK_INC : std_logic;  -- from state machine
  signal PDEC_BLOCK_CNT : std_logic;
  signal DEC_BLOCK_CNT_BUF1_D : std_logic; -- double buffer in case host run at different rate
  signal DEC_BLOCK_CNT_BUF1_Q : std_logic; -- double buffer in case host run at different rate
  signal DEC_BLOCK_CNT_BUF2_D : std_logic; -- double buffer in case host run at different rate
  signal DEC_BLOCK_CNT_BUF2_Q : std_logic; -- double buffer in case host run at different rate
  signal DEC_BLOCK_CNT_BUF3_D : std_logic; -- double buffer in case host run at different rate
  signal DEC_BLOCK_CNT_BUF3_Q : std_logic; -- double buffer in case host run at different rate
  
  signal MODE1  : std_logic;
  signal MODE2  : std_logic;
  signal MODE3   : std_logic;
  signal MODE4,MODE5,MODE6,MODE7 : std_logic;
  --- state machine mode 1
  signal CLRPULSETIMER    :  std_logic;
  signal PULSE_TIMER_EN   :  std_logic;
  signal PULSE_TIMER_EN3   :  std_logic;
  signal LATCHPULSETIMER3  :  std_logic;
  signal SEL_PULSE_TIMER3 :  std_logic;
  signal LD_RD_PTR3        :  std_logic;

  signal INCPULSENUMBER3   :  std_logic;


  --- state machine mode 2 
  signal LATCHPULSETIMER     :  std_logic;
  signal RD_PTW_PTR_EN_5   :  std_logic;
  signal RAW_PTW_PTR_EN		: std_logic;
  --signal LAST_MD1_DATA2    : std_logic;
  signal SAVE_PTW_PTR      : std_logic; -- save PTW_PTR if there is pulses

  signal RT_PTW_PTR, RT_PTW_PTR_Q        : std_logic;  -- restore PTW_PTR if there is pulses  --change add Q, FT
  signal NoEventLatch      : std_logic;
  signal LatchNoEvenClr    : std_logic;
  signal LATCH_NOEVENT_D   : std_logic;
  signal LATCH_NOEVENT_Q   : std_logic;
  signal CRUISE_CNT_EN     : std_logic;
  signal CRUISE_CNT_D      : std_logic_vector(3 downto 0);
  signal CRUISE_CNT_Q      : std_logic_vector(3 downto 0);
  signal CRUISE_CNT_TC     : std_logic;
  signal NoEventLatchEn    : std_logic;

  --- mode 2 and mode 3

  signal ABOVE_THREDSHOLD_D   : std_logic;  --- 1 when ADC data is greater then thredshold
--  signal ABOVE_THREDSHOLD_Q   : std_logic;
  signal PABOVE_TH            : std_logic;

  signal PTW_RAM_DATA_20 : std_logic_vector(11 downto 0);
  
  signal CLEAR_PTR : std_logic;

  signal PRESENT_PULSE_NUMBER  : std_logic_vector(2 downto 0);
  --signal MAX_NUMBER_OF_PULSE_D : std_logic_vector(1 downto 0);
  --signal MAX_NUMBER_OF_PULSE_Q : std_logic_vector(1 downto 0);
--  signal BELOW_THREDSHOLD_D    : std_logic;
--  signal BELOW_THREDSHOLD_Q    : std_logic;
--  signal NOT_READY_FOR_PABOVE_TH_D : std_logic;  --- edge detect pulse
--  signal NOT_READY_FOR_PABOVE_TH_Q : std_logic;
--  signal DoneProcPulse_D : std_logic;
--  signal DoneProcPulse_Q : std_logic;

  ----- Save and restore pointers to move between Mode
--  signal SAVE_PTRS_D            : std_logic;
--  signal SAVE_PTRS_Q            : std_logic;
--  signal LOAD_PTRS_D            : std_logic;
--  signal LOAD_PTRS_Q            : std_logic;
  
--  signal NSA_CNT_TC_Q           : std_logic;
  
  signal ChannelCheck           : std_logic;
  
  ----- TDC Algorithm
  signal SEL_PULSE_TIMER_TDC : std_logic;
  signal WR_PTR_CNT_EN_TDC : std_logic;
  signal PROBUFWEN_TDC : std_logic;
  signal PROCESS_BUF_DATA_TDC     :  std_logic_vector(17 downto 0);  --- data to be store into Process Buffer
  signal SEL_PROCESS_BUF_DATA_TDC :  std_logic;
  signal LAST_MD_DATA_TDC   : std_logic;
  signal SAVE_Vpeak_ADR_TDC : std_logic;
  signal Vpeak_ADR_TDC        : std_logic_vector(11 downto 0);  --- indicate four address beyond Vpeak
  --signal SAVE_PTW_PTR_TDC     : std_logic; 
  signal PULSE_TIMER_EN_TDC   : std_logic;
  signal CLRPULSETIMER_TDC    : std_logic;
  signal SAMPLE_NUMBER_TDC        :  std_logic_vector(9 downto 0);  --- Number of sample read from window begin. Use to determine Coarse Time for multiple pulses
  signal LD_SAMPLE_NUMBER_TDC     :  std_logic;
  signal LATCHPULSETIMER_TDC      :  std_logic;
  signal INCPULSENUMBER_TDC   : std_logic;
  signal TDC_GO               : std_logic;
--  signal TDC_DONE_D           : std_logic;
--  signal TDC_DONE_Q           : std_logic;
  signal RT_PTW_PTR_TDC       : std_logic;
  signal INC_PTW_PTR_TDC      : std_logic;
  
  signal P_TDC_DONE           : std_logic;
  signal CLRPULSENUMBER_TDC   : std_logic;
  
  ----- multi mode processing
--  signal LD_PTW_RAM_ADR_D : std_logic;          
--  signal LD_PTW_RAM_ADR_Q : std_logic;  

  ---- For debugging in simulation
  signal PTW_RAM_DATA_Bit_11_0 : std_logic_vector(11 downto 0);
  signal PTW_RAM_DATA_Bit_11_0_GT_Thredshold : std_logic;        
 
	COMPONENT PROC_BUFF_FIFO
	  PORT (
		    rst 	: IN STD_LOGIC;
--		    wr_clk 	: IN STD_LOGIC;
--		    rd_clk 	: IN STD_LOGIC;
			clk 	: IN STD_LOGIC;
		    din 	: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		    wr_en 	: IN STD_LOGIC;
		    rd_en 	: IN STD_LOGIC;
		    dout 	: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		    full 	: OUT STD_LOGIC;
		    empty 	: OUT STD_LOGIC
	  );
	END COMPONENT;
	
	signal PR_FIFO_WR_EN, PR_FIFO_WR_EN_TR, PROC_BUF_WR_EN : std_logic;
	signal PROC_BUF_WR_EN_D,PROC_BUF_WR_EN_Q : std_logic; 

--component FT_PROCESSM_CDC_TST2 IS
--	PORT (MODE : IN std_logic_vector (2 DOWNTO 0);
--			CLK,FT_ABOVE_TH,FT_DONE,GO,INIT_PED_CALC_DN,LOC_PED_CALC_DN,NO_EVENT,
--			PTW_DONE,RESET_N,WE_DONE,PEAK_WRITE_DONE: IN std_logic;
--			--CLR_PEAK_CNT,
--			CLR_INIT_PED_CNT,CLR_LOC_PED_CNT,CLR_PTW_DONE,DEC_PEAK_CNT,DEC_PTW_CNT,
--			FT_GO,HOST_BLOCK_INC,IDLE,LAST_MD_DATA_CDC,LatchNoEvenClr,MODE_DONE,MODE_GO,
--			NoEventLatch,NOT_VALID_2,PINIT_CALC_EN,PLOCAL_CALC_EN,PR_FIFO_WR_EN,
--			PR_FIFO_WR_EN_TR,PTW_CNT_CLR,RAW_PTW_PTR_EN,RD_PTW_PTR_EN_5,RT_PTW_PTR,
--			RT_PTW_PTR_2,RT_PTW_PTR_PLOC,SAVE_PTW_PTR,SAVE_PTW_PTR_FT,
--			SEL_CDC_FT_WD_1,
--			SEL_CDC_FT_WD_2,SEL_MODE6_WD_1,SEL_RAW_SAMPLE_2,SEL_RS_1,SEL_RS_2 : OUT std_logic);
--end component; 

component FT_PROCESSM_CDC_FDC IS
	PORT (MODE : IN std_logic_vector (2 DOWNTO 0);
			CLK,FT_ABOVE_TH,FT_DONE,GO,INIT_PED_CALC_DN,LOC_PED_CALC_DN,NO_EVENT,
			PTW_DONE,
			wait_PG_done,
			--RAW_PTW_DONE,
			RESET_N,WE_DONE,PEAK_WRITE_DONE: IN std_logic;
			--CLR_PEAK_CNT,
			--CLR_PG,
			CLR_INIT_PED_CNT,CLR_LOC_PED_CNT,CLR_PTW_DONE,DEC_PEAK_CNT,
			--DEC_PTW_CNT,
			FT_GO,HOST_BLOCK_INC,IDLE,--LAST_MD_DATA_CDC,
			LatchNoEvenClr,--MODE_DONE,MODE_GO,
			NoEventLatch,NOT_VALID_2,PINIT_CALC_EN,PLOCAL_CALC_EN,PR_FIFO_WR_EN,
			PR_FIFO_WR_EN_TR,PTW_CNT_CLR,RAW_PTW_PTR_EN,RD_PTW_PTR_EN_5,RT_PTW_PTR,
			RT_PTW_PTR_2,RT_PTW_PTR_PLOC,SAVE_PTW_PTR,SAVE_PTW_PTR_FT,
			SEL_CDC_FT_WD_1,
			SEL_CDC_FT_WD_2,
			SEL_FDC_SUM_WD_1,
			SEL_FDC_SUM_WD_2,
			SEL_FDC_AMP_WD_1,
			SEL_FDC_AMP_WD_2,
			SEL_RAW_SAMPLE_2,SEL_RS_1,SEL_RS_2,SEL_WIN_RAW_WD_1 : OUT std_logic);
end component; 

	signal PED_CNT_D, PED_CNT_Q 	: std_logic_vector(31 downto 0);
	signal PINIT_D, PINIT_Q 		: std_logic_vector(31 downto 0) := X"00000000";
	signal PLOCAL_D, PLOCAL_Q 		: std_logic_vector(31 downto 0) := X"00000000"; 
	signal PINIT_AVG, PLOCAL_AVG	: std_logic_vector(15 downto 0) := X"0000";	
	signal PINIT_AVG_D, PINIT_AVG_Q	: std_logic_vector(15 downto 0) := X"0000";
	signal PLOCAL_AVG_D,PLOCAL_AVG_Q : std_logic_vector(31 downto 0) := X"00000000";
	--signal FDC_PLOCAL_AVG_D,FDC_PLOCAL_AVG_Q : std_logic_vector(31 downto 0) := X"00000000";
	
	signal PED_CALC_DONE, SAVE_PTW_PTR_FT, RT_PTW_PTR_PLOC, PINIT_CALC_EN, PLOCAL_CALC_EN : std_logic;
	
	signal INIT_PED_CALC_DONE, LOC_PED_CALC_DONE, IDLE : std_logic;
	
	signal CLR_INIT_PED_CNT_D, CLR_INIT_PED_CNT_Q, CLR_LOC_PED_CNT_D, CLR_LOC_PED_CNT_Q : std_logic;
	signal FT_ABOVE_TH_D, FT_ABOVE_TH_Q 	: std_logic;
	signal FT_VALUE_THRESHOLD, FT_TH : std_logic_vector(15 downto 0); 
	
	signal WindowWdCnt_D, WindowWdCnt_Q	: std_logic_vector(11 downto 0);
	signal WindowWdCntTc_D, WindowWdCntTc_Q, cruise_PTW_DONE, PTW_CNT_CLR : std_logic;
	--signal WindowWdCntTc_2D, WindowWdCntTc_2Q : std_logic; 
	signal RAW_PTW_DONE : std_logic;
	--signal CHANNEL_NUMBER	: std_logic_vector(6 downto 0);	
	constant NE : std_logic_vector(11 downto 0) := X"014";
	
	signal RAW_SAMPLE_1, RAW_SAMPLE_2 : std_logic_vector(12 downto 0);
	signal RAW_SAMPLE_1_D,RAW_SAMPLE_1_Q : std_logic_vector(11 downto 0);
	signal RAW_SAMPLE_2_D,RAW_SAMPLE_2_Q : std_logic_vector(11 downto 0);
	
	--signal X_THRESH, X_THRESH_CNT_D, X_THRESH_CNT_Q : std_logic_vector(11 downto 0); 
	--signal X_THRESH_D,X_THRESH_Q : std_logic_vector(11 downto 0);	
	
	signal WIN_RAW_WORD_1_D, WIN_RAW_WORD_1_Q, WIN_PULSE_WRD_1, RAW_SAMPLE_WORD_2 : std_logic_vector(31 downto 0); 
	--signal SET_WIN_RAW_WD_1, SET_WIN_PULSE_WD_1, SET_RAW_SAMPLE_2 : std_logic; 
	signal SEL_WIN_RAW_WD_1, SEL_WIN_PULSE_WD_1 : std_logic; 
	signal SEL_RAW_SAMPLE_2, SEL_RS_1, SEL_RS_2 : std_logic; 
	signal SEL_RAW_SAMPLE_2_D, SEL_RAW_SAMPLE_2_Q : std_logic;
	
	signal MUX_SEL,MUX_SELA,MUX_SELB,MUX_SELC,MUX_SELD : std_logic_vector(9 downto 0);
	
	signal NOT_VALID_1, NOT_VALID_2 : std_logic;

  component fifo_12_64 IS
	port (
			clk	: IN std_logic;
			din	: IN std_logic_VECTOR(11 downto 0);
			rd_en	: IN std_logic;
			rst	: IN std_logic;
			wr_en	: IN std_logic;
			dout	: OUT std_logic_VECTOR(11 downto 0);
			empty	: OUT std_logic;
			full	: OUT std_logic
	);
   end component;
   
 	----CDC findtime stuff--------
	signal ft_q_code 	: std_logic;          -- busy when 1 and finished when 0         
	signal ft_le_time 			: std_logic_vector (10 downto 0); -- leading edge time found  
	signal FT_PTW_DATA_D,FT_PTW_DATA_2D,FT_PTW_DATA_3D	: std_logic_vector (11 downto 0); 
	signal FT_PTW_DATA_Q,FT_PTW_DATA_2Q,FT_PTW_DATA_3Q	: std_logic_vector (11 downto 0); --shifting data to use threshold crossing go from old SM	
	signal FT_GO,FT_DONE,FT_INC_PTW_PTR_TDC		  : std_logic; --added for ft hack	
	signal RT_PTW_PTR_2 		: std_logic; 
	signal FT_SAVE_RD_PTW_PTR_D : std_logic_vector(9 downto 0); --change add ft
    signal FT_SAVE_RD_PTW_PTR_Q : std_logic_vector(9 downto 0);
	signal FT_RT_PTW_PTR_TDC	: std_logic; --change add for FT
	signal FT_SAVE_TC_PTW_PTR_D, FT_SAVE_TC_PTW_PTR_Q : std_logic_vector(9 downto 0);
 	signal FT_START_FROM_NU, FT_START_FROM_TC : std_logic; 
	 
	signal FT_SAVE_LS_PTW_PTR_D, FT_SAVE_LS_PTW_PTR_Q : std_logic_vector(9 downto 0);
	--signal FT_START_FROM_LS : std_logic;
	 
	--CDC FT stuff, may need to reveamp how I pass/mux this stuff. Will wait until the rest of the code is streamlined, but address before the next algos.
	signal CDC_FT_WORD_1, CDC_FT_WORD_2			: std_logic_vector(31 downto 0);
	signal FDC_FT_SUM_WORD_1, FDC_FT_SUM_WORD_2	: std_logic_vector(31 downto 0);
	signal FDC_FT_AMP_WORD_1, FDC_FT_AMP_WORD_2	: std_logic_vector(31 downto 0);
	signal MODE6_SUM_WORD_1, MODE7_SUM_WORD_1	: std_logic_vector(31 downto 0); 
	
	signal CDC_FT_WORD_1_D, CDC_FT_WORD_1_Q : std_logic_vector(31 downto 0);
	signal CDC_FT_WORD_2_D, CDC_FT_WORD_2_Q : std_logic_vector(31 downto 0); 
	
	signal FDC_FT_SUM_WORD_1_D, FDC_FT_SUM_WORD_1_Q : std_logic_vector(31 downto 0);
	
	signal FDC_FT_AMP_WORD_1_D, FDC_FT_AMP_WORD_1_Q : std_logic_vector(31 downto 0); 
	signal MODE6_SUM_WORD_1_D, MODE6_SUM_WORD_1_Q : std_logic_vector(31 downto 0);
	signal MODE7_SUM_WORD_1_D, MODE7_SUM_WORD_1_Q : std_logic_vector(31 downto 0);
	
	signal CDC_FT_WORD_1_2D,CDC_FT_WORD_2_2D,FDC_FT_SUM_WORD_1_2D,FDC_FT_SUM_WORD_2_D,FDC_FT_AMP_WORD_1_2D,
			FDC_FT_AMP_WORD_2_D,RAW_SAMPLE_WORD_2_D,MODE6_SUM_WORD_1_2D,MODE7_SUM_WORD_1_2D : std_logic_vector(31 downto 0);
	signal CDC_FT_WORD_1_2Q,CDC_FT_WORD_2_2Q,FDC_FT_SUM_WORD_1_2Q,FDC_FT_SUM_WORD_2_Q,FDC_FT_AMP_WORD_1_2Q,
			FDC_FT_AMP_WORD_2_Q,RAW_SAMPLE_WORD_2_Q,MODE6_SUM_WORD_1_2Q,MODE7_SUM_WORD_1_2Q : std_logic_vector(31 downto 0); 
	
	signal SEL_FDC_SUM_WD_1, SEL_FDC_SUM_WD_2	: std_logic;
	signal SEL_FDC_AMP_WD_1, SEL_FDC_AMP_WD_2	: std_logic;
	
	signal SEL_CDC_FT_WD_1, SEL_CDC_FT_WD_2, SEL_CDC_FT_WD_3, SEL_CDC_FT_WD_4, SEL_DATA_CDC_FT, LAST_MD_DATA_CDC : std_logic; 
	signal SEL_MODE6_WD_1, SEL_MODE7_WD_1 : std_logic;
	signal WR_PTR_CNT_EN_2, PROBUFWEN_CDC, ST_LAST_ADR_CDC : std_logic;
	signal CDC_FT_PROC_BUF_DATA : std_logic_vector(17 downto 0); 
	
	signal ft_overflow_TOTAL : std_logic_vector(2 downto 0);
	signal ft_SUM_TOTAL,ft_SUM_TOTAL_Q,ft_SUM_TOTAL_Q_C : std_logic_vector(31 downto 0) := X"00000000"; -- 12 bits for FDC 14 for CDC. So, using 14 in proc_data 
	signal ft_FIRST_MAX : std_logic_vector(31 downto 0) := X"00000000";
	--signal ft_overflow_cnt_D, ft_overflow_cnt_Q : std_logic_vector(2 downto 0):= "000"; -- need to determine how to detect and count
 	---- end CDC findtime stuff-------- 
	 
 	----FDC findtime stuff--------
	signal FDC_busy,FDC_q_code 	: std_logic;          -- busy when 1 and finished when 0         
	signal FDC_le_time 			: std_logic_vector (10 downto 0); -- leading edge time found  
	--signal FT_PTW_DATA_D,FT_PTW_DATA_2D,FT_PTW_DATA_3D	: std_logic_vector (11 downto 0); 
	--signal FT_PTW_DATA_Q,FT_PTW_DATA_2Q,FT_PTW_DATA_3Q	: std_logic_vector (11 downto 0); --shifting data to use threshold crossing go from old SM	
	signal FDC_GO,FDC_DONE,FDC_INC_PTW_PTR_TDC		  : std_logic; --added for ft hack	
	signal FDC_RT_PTW_PTR_TDC, FDC_START_FROM_TC : std_logic;
	signal FDC_SUM_TOTAL : std_logic_vector(31 downto 0);
	signal FDC_FIRST_MAX : std_logic_vector(11 downto 0);
	
	signal PEAK_NUMBER		: std_logic_vector(4 downto 0); --integer range 0 to 511;
	
	signal FINAL_MAX_time 	: std_logic_vector(11 downto 0); 
	
	signal FINAL_MAX,FINAL_MAX_Q,FINAL_MAX_Q_C 		: std_logic_vector(31 downto 0);
	
	signal DEC_PEAK_CNT	    : std_logic;
	--signal CLR_PEAK_CNT		: std_logic;
	signal PEAK_WRITE_DONE	: std_logic;

 	---- end FDC findtime stuff-------- 

	component CDC_findtime_top -- Need this to search through PTW data for threshold and send n samples to findtime (and anything else that needs doing 
			 Port ( 	-- Naomi's original signals 
					clk					: in  STD_LOGIC;
					RESET_N            	: in std_logic;
					--PTW          		: in  std_logic_vector(9 downto 0);
					MAX_NUMBER_PEAKS	: in std_logic_vector(5 downto 0);
					
					--adc					: in std_logic_vector (11 downto 0);         
					--busy				: out std_logic;          -- busy when 1 and finished when 0         
					le_time  			: out std_logic_vector (10 downto 0); -- leading edge time found
					ft_q_code			: out std_logic;  -- quality code, 0 is good
--					FIRST_MAX 			: out std_logic_vector(31 downto 0); 
					ft_overflow_TOTAL	: out std_logic_vector(2 downto 0);
					SUM_TOTAL 			: out std_logic_vector(31 downto 0); 
					
					PEAK_NUMBER_out		: out std_logic_vector(4 downto 0); --integer range 0 to 511;
					FINAL_MAX_time_out 	: out std_logic_vector(11 downto 0);
					FINAL_MAX_out 		: out std_logic_vector(31 downto 0);
					
					DEC_PEAK_CNT	    : in std_logic;
					--CLR_PEAK_CNT		: in std_logic;
					PEAK_WRITE_DONE		: out std_logic;
					
					TDC_GO             	: in  std_logic; --- Rising edge start TDC algorith
					ft_done 			: out std_logic; -- "done"using mem 

					PTW_RAM_DATA        : in std_logic_vector(11 downto 0);
					--OVERFLOW			: in std_logic;
					
					-- NEW REGS
--					NSAMPLES			: in std_logic_vector(7 downto 0);   -- max number of ADC samples to read in   --int 16
					
--		   			XTHR_SAMPLE			: in std_logic_vector(7 downto 0); -- the 5 sigma thres xing is sample[9] passed into the algo, starting with sample[0]
--		    		PED_SAMPLE 			: in std_logic_vector(7 downto 0); -- take local ped as sample[5]
		    
		    		THRES_HI			: in std_logic_vector(8 downto 0); -- 4 sigma --int 80
		    		THRES_LO			: in std_logic_vector(7 downto 0); -- 1 sigma --int 20
		
--		    		ROUGH_DT 			: in std_logic_vector(7 downto 0);   --if algo fails, return this many tenth-samples before threshold xing --int 24
--		    		INT_SAMPLE 			: in std_logic_vector(7 downto 0); -- if algo fails, start integration with this sample
		    
--		    		LIMIT_ADC_MAX 		: in std_logic_vector(15 downto 0);  -- return rough time if ADC sample exceeds this value --int 4096
--		    		LIMIT_PED_MAX 		: in std_logic_vector(15 downto 0);  -- return rough time if pedestal exceeds this --int 511
		
--		    		SET_ADC_MIN 		: in std_logic_vector(15 downto 0);  -- set min value of ADC sample subset equal to this  --int 20
--		    		LIMIT_UPS_ERR 		: in std_logic_vector(15 downto 0);  -- return midpoint time if sum of upsampling errors exceeds this --int 30
						
					IE 					: in std_logic_vector(11 downto 0);	
					PG 					: in std_logic_vector(7 downto 0);	
					
					-- NEW SIGNALS FOR CDC/FDC
					--RT_PTW_PTR_TDC      : out std_logic;   --- restore saved data buffer current address
					INC_PTW_PTR_TDC     : out std_logic;   --- inc RD_PTW_PTR_Q
					WE_DONE				: in std_logic;	
					PTW_DONE			: in std_logic;
					--
					CLR_COUNTS			: out std_logic;
					RT_PTW_PTR_LS		: out std_logic;
					
					le_sample 			: out std_logic_vector (4 downto 0); -- sample containing leading edge 
					le_sample_found_out	: out std_logic;
					FT_START_FROM_LS	: in std_logic;
					--
					FT_START_FROM_NU	: in std_logic
					--FT_START_FROM_TC  	: in std_logic
					);
	end component;	
	
	signal CLR_COUNTS, RT_PTW_PTR_LS, FT_START_FROM_LS : std_logic;
	signal le_sample : std_logic_vector (4 downto 0);
	
	signal WE_DONE : std_logic;
	signal WE_DONE_D,WE_DONE_Q : std_logic;

	signal NP_MINUS_1, NP2_MINUS_1 : std_logic_vector(11 downto 0);

	signal SUM_OUT_D : std_logic_vector(13 downto 0);
	signal AMP_OUT_D : std_logic_vector(11 downto 0);	
	signal PED_OUT_D : std_logic_vector(10 downto 0);
	signal FDC_PED_OUT_D : std_logic_vector(10 downto 0);
	
	signal SUM_OUT_Q : std_logic_vector(13 downto 0);
	signal AMP_OUT_Q : std_logic_vector(11 downto 0);	
	signal PED_OUT_Q : std_logic_vector(10 downto 0);
	--signal FDC_PED_OUT_Q : std_logic_vector(10 downto 0);
	
	signal SUM_OUT_2D : std_logic_vector(13 downto 0);
	signal AMP_OUT_2D : std_logic_vector(11 downto 0);	
	signal PED_OUT_2D : std_logic_vector(10 downto 0);
	--signal FDC_PED_OUT_2D : std_logic_vector(10 downto 0);
	
	signal SUM_OUT_2Q : std_logic_vector(13 downto 0);
	signal AMP_OUT_2Q : std_logic_vector(11 downto 0);	
	signal PED_OUT_2Q : std_logic_vector(10 downto 0);
	--signal FDC_PED_OUT_2Q : std_logic_vector(10 downto 0);
	
	signal ft_SUM_TOTAL_COMP : std_logic_vector(24 downto 0);
	signal FINAL_MAX_COMP : std_logic_vector(24 downto 0);
	signal PLOCAL_AVG_COMP : std_logic_vector(24 downto 0);	
	--signal FDC_PLOCAL_AVG_COMP : std_logic_vector(24 downto 0);	

	signal NP_int, NP2_int : integer; 
	--constant XTHR_SAMPLE: integer := 9;	
	signal XTHR_SAMPLE : std_logic_vector(7 downto 0);
	
	signal le_sample_found : std_logic;
	signal WE_MINUS_NE,PTW_MINUS_1 : std_logic_vector (11 downto 0); 
	
	signal int_XTHR_SAMPLE, int_ft_le_time, hit_threshold_crossing_sample : integer;
	signal hit_threshold_crossing_sample_D,hit_threshold_crossing_sample_Q  : integer;
	signal int_XTHR_SAMPLE_D,int_XTHR_SAMPLE_Q : integer;	
	signal int_ft_le_time_D,int_ft_le_time_Q : integer;

	signal FINAL_ft_le_time : std_logic_vector(10 downto 0);  
	signal FINAL_ft_le_time_D,FINAL_ft_le_time_Q  : std_logic_vector(10 downto 0); 
	
	signal wait_PG_done, CLR_PG : std_logic;
	signal NEW_END_D,NEW_END_Q : std_logic;
	
	signal PG_OFFSET_D, PG_OFFSET_Q : integer range 0 to 255; --: std_logic_vector(7 downto 0);	  

	signal int_IBIT, int_ABIT, int_PBIT  : integer range 0 to 7;	 
	
	signal int_IBIT_13 : integer range 0 to 20 := 13;
	signal int_ABIT_11 : integer range 0 to 18 := 11;
	signal int_PBIT_10 : integer range 0 to 17 := 10;
	
	signal int_IBIT_24, int_ABIT_24, int_PBIT_24  : integer range 0 to 31 := 24;

	signal PR_FIFO_WR_EN_D,PR_FIFO_WR_EN_Q,PR_FIFO_WR_EN_P : std_logic;
begin 

	XTHR_SAMPLE <= PG + 5;	
	
  ----- For debugging in simulation
--  PTW_RAM_DATA_Bit_11_0 <= PTW_RAM_DATA(11 downto 0);
--  PTW_RAM_DATA_Bit_11_0_GT_Thredshold <= '1' when PTW_RAM_DATA_Bit_11_0 > BLOCK_VALUE_THRESHOLD else '0';
  
  --RST <= not RESET_N;
  RST <= '1' when RESET_N = '0' else '0';
   
  PTW_RAM_ADR  <= RD_PTW_PTR_Q; -- change removed reg value for addr
   
  --- Start processing when there is data in PTW DAT BUFFER
--  PTW_DATA_BUF_RDY_D <= PTW_DATA_BLOCK_CNT(7) or PTW_DATA_BLOCK_CNT(6) or  PTW_DATA_BLOCK_CNT(5) or
--                        PTW_DATA_BLOCK_CNT(4) or PTW_DATA_BLOCK_CNT(3) or  PTW_DATA_BLOCK_CNT(2) or
--                        PTW_DATA_BLOCK_CNT(1) or  PTW_DATA_BLOCK_CNT(0); 

--------------------------------------------------------------------------
-----HERE IS WHERE ADDR POINTERS ARE SAVED AND RETURNED----------------
-------------------------------------------------------------------------- 
--NP2_PTW_PTR <= RD_PTW_PTR_Q - ((2**conv_integer(NP2)) + 2);	 
	--NP2_PTW_PTR(7 downto 0) <= PG + ((2**conv_integer(NP2)) + 2);

 PG_OFFSET_D <= ((2**conv_integer(NP2)) + 3);

 RD_PTW_PTR_D <= SAVED_PTW_RAM_ADR when  LD_PTW_RAM_ADR = '1' else --change
						SAVE_RD_PTW_PTR_Q when RT_PTW_PTR = '1' or RT_PTW_PTR_2 ='1' or RT_PTW_PTR_LS = '1' else -- 				
						--(RD_PTW_PTR_Q - ((2**conv_integer(NP2)) + 3)) - PG		when RT_PTW_PTR_PLOC = '1' else -- return address for PLOCAL begin,  
						(RD_PTW_PTR_Q - PG_OFFSET_Q) - PG when RT_PTW_PTR_PLOC = '1' else -- return address for PLOCAL begin, 
						RD_PTW_PTR_Q + 1 when (RD_PTW_PTR_EN = '1' ) or (FT_INC_PTW_PTR_TDC = '1') else	
						RD_PTW_PTR_Q;

 SAVE_RD_PTW_PTR_D <= RD_PTW_PTR_Q  when SAVE_PTW_PTR = '1' else                     
                      SAVE_RD_PTW_PTR_Q;
					  
 FT_SAVE_RD_PTW_PTR_D <= RD_PTW_PTR_Q - (XTHR_SAMPLE + 4) when  SAVE_PTW_PTR_FT = '1'  else	--change, ft finding addr for xthresh - NU, -- -11 --CHANGE! (-4 for 2 sample fth)            
						 FT_SAVE_RD_PTW_PTR_Q;	
--CHANGE	 
 --FT_SAVE_TC_PTW_PTR_D <= RD_PTW_PTR_Q  when  RT_PTW_PTR_PLOC = '1'  else	--change, save TC for intergral calc after  minus 2 for data to have arrived --CHANGE! -2              
--	 					 FT_SAVE_TC_PTW_PTR_Q;
 
 FT_START_FROM_NU <= '1' when RD_PTW_PTR_Q = FT_SAVE_RD_PTW_PTR_Q else '0'; -- start signal for fintime 
 --FT_START_FROM_TC <= '1' when RD_PTW_PTR_Q = FT_SAVE_TC_PTW_PTR_Q - 1 else '0'; -- start signal for FIND MAX 

 FT_SAVE_LS_PTW_PTR_D <= FT_SAVE_RD_PTW_PTR_Q + le_sample when le_sample_found = '1' else
	 					 FT_SAVE_LS_PTW_PTR_Q;	
	 
 FT_START_FROM_LS <= '1' when RD_PTW_PTR_Q = FT_SAVE_LS_PTW_PTR_Q + 2 else '0'; -- start signal for SUM -- + 3 to account for data delay and lesample starting at 1	--CHANGE! +3
--------------------------------------------------------------------------
--END ADDR POINTER SECTION
--------------------------------------------------------------------------

--------------------------------------------------------------------------
----------PEDESTAL CALCULATIONS--------------------------------
--------------------------------------------------------------------------
-- counting NP(2) samples for initial and local pedestal 
	
  PED_CNT_D <= PED_CNT_Q + 1 when (PINIT_CALC_EN = '1' or PLOCAL_CALC_EN = '1') else 
			   X"00000000" when (CLR_INIT_PED_CNT_D = '1' or CLR_LOC_PED_CNT_D = '1') else 	 --or CLR_PG = '1' --CLR_INIT_PED_CNT_D = '1'
			   PED_CNT_Q; 
			   
	wait_PG_done <= '1' when (WindowWdCnt_Q >= (NP_MINUS_1 + PG)) else '0'; -- -3 because 1 for q value and 2 for where it left off

 -- PED_CALC_DONE <= '1' when PED_CNT_Q = 15 else '0';	--NP - 1 
	NP_MINUS_1 <= conv_std_logic_vector((2**conv_integer(NP)) - 1, 12); 
	NP2_MINUS_1 <= conv_std_logic_vector((2**conv_integer(NP2)) - 1, 12); 
	
	INIT_PED_CALC_DONE <= '1' when PED_CNT_Q = NP_MINUS_1 else '0';
	LOC_PED_CALC_DONE <= '1' when PED_CNT_Q = NP2_MINUS_1 else '0';
	 
--	
----- averaging initial pedestal at begining of PTW
--  PINIT_D <= PINIT_Q + PTW_RAM_DATA(11 downto 0) when PINIT_CALC_EN = '1' else
--				 X"00000000"	when CLR_LOC_PED_CNT_Q = '1' else --CLR_INIT_PED_CNT_Q	--changed to clear local to hold avg until after usage
--				 PINIT_Q;

--
------ averaging local pedestal at xtrh - 16  
--  PLOCAL_D <= PLOCAL_Q + PTW_RAM_DATA(15 downto 0)	when PLOCAL_CALC_EN = '1' else
--				  X"00000000"	when CLR_LOC_PED_CNT_Q = '1' else
--				  PLOCAL_Q;
----attempting to optimize---------

----- averaging initial pedestal at begining of PTW
  PINIT_D <= PINIT_Q + PTW_RAM_DATA(11 downto 0) when PINIT_CALC_EN = '1' or PLOCAL_CALC_EN = '1' else
				 X"00000000"	when CLR_INIT_PED_CNT_Q = '1' or CLR_LOC_PED_CNT_Q = '1' else --CLR_INIT_PED_CNT_Q	--changed to clear local to hold avg until after usage
				 PINIT_Q;

				  
------FINAL AVERAGES FOR INITIAL AND LOCAL-------------------------------------------		 

  	NP_int <= conv_integer(NP);
	--PINIT_AVG_D(11 downto 0) <= PINIT_Q((NP_int + 11) downto (NP_int)) when CLR_INIT_PED_CNT_D = '1' and CLR_INIT_PED_CNT_Q = '0'; -- else PINIT_AVG_Q(11 downto 0);

 	NP2_int <= conv_integer(NP2);												  
	--PLOCAL_AVG_D(11 downto 0) <= PINIT_Q((NP2_int + 11) downto (NP2_int)) when CLR_LOC_PED_CNT_D = '1' and CLR_LOC_PED_CNT_Q = '0'; -- else PLOCAL_AVG_Q(11 downto 0);	

	avg : process (CLK_PROCESS)
        begin
         if (CLK_PROCESS = '1' and CLK_PROCESS'event) then  
			 
--			if (PINIT_CALC_EN = '1' or PLOCAL_CALC_EN = '1') then 
--				PINIT_D <= PINIT_Q + PTW_RAM_DATA(11 downto 0);
--			elsif (CLR_INIT_PED_CNT_Q = '1' or CLR_LOC_PED_CNT_Q = '1') then
--				PINIT_D <= X"00000000";	
--			end if;
--			
			if CLR_INIT_PED_CNT_D = '1' and CLR_INIT_PED_CNT_Q = '0' then 
				PINIT_AVG_D(11 downto 0) <= PINIT_Q((NP_int + 11) downto (NP_int));
			end if;
			
			if CLR_LOC_PED_CNT_D = '1' and CLR_LOC_PED_CNT_Q = '0' then
				--PLOCAL_AVG_D(11 downto 0) <= PINIT_Q((NP2_int + 11) downto (NP2_int));
				PLOCAL_AVG_D <= PINIT_Q;
			end if;
		   
        end if;
    end process avg; 
	  
-- 
---- Determine threshold relative to pedestal  
  FT_TH <= X"0"&BLOCK_VALUE_THRESHOLD; --X"003F"; -- will need to come from register TH which is adder to the initial pedestal PINIT
  FT_VALUE_THRESHOLD <= PINIT_AVG_Q + FT_TH; --  adding TH value to initial pedestal
  FT_ABOVE_TH_D <= '1' when PTW_RAM_DATA(11 downto 0) >= FT_VALUE_THRESHOLD else '0'; -- used to locate memory space where crossing occured 
--------------------------------------------------------------------------
-----------END PEDESTAL CALCULATIONS
-------------------------------------------------------------------------- 

--------------------------------------------------------------------------
--------------Scale factorz-----------------------------------------------
-------------------------------------------------------------------------- 
		
	SUM_OUT_D <= ft_SUM_TOTAL_Q(13 downto 0);	
	AMP_OUT_D <= FINAL_MAX_Q(11 downto 0);
	PED_OUT_D <= PLOCAL_AVG_Q(10 downto 0);
	--FDC_PED_OUT_D <= FDC_PLOCAL_AVG_Q(10 downto 0);
	
--	SUM_OUT_D <= ft_SUM_TOTAL_Q(int_IBIT_13 downto int_IBIT);	
--	AMP_OUT_D <= FINAL_MAX_Q(int_ABIT_11 downto int_ABIT);
--	PED_OUT_D <= PLOCAL_AVG_Q(int_PBIT_10 downto int_PBIT);
	
--	SUM_OUT_D <= ft_SUM_TOTAL_Q((conv_integer(IBIT) + 13) downto conv_integer(IBIT));	
--	AMP_OUT_D <= FINAL_MAX_Q((conv_integer(ABIT) + 11) downto conv_integer(ABIT));
--	PED_OUT_D <= PLOCAL_AVG_Q((conv_integer(PBIT) + 10) downto conv_integer(PBIT));
	
	SUM_OUT_2D <= SUM_OUT_Q;
	AMP_OUT_2D <= AMP_OUT_Q;
	PED_OUT_2D <= PED_OUT_Q; 
	--FDC_PED_OUT_2D <= FDC_PED_OUT_Q;
--------------------------------------------------------------------------
-------------- END Scale factorz
-------------------------------------------------------------------------- 
	SCALES : process (CLK_PROCESS)
        begin
         if (CLK_PROCESS = '1' and CLK_PROCESS'event) then  
			
				SUM_OUT_Q <= SUM_OUT_D;
				AMP_OUT_Q <= AMP_OUT_D;
				PED_OUT_Q <= PED_OUT_D;
				--FDC_PED_OUT_Q <= FDC_PED_OUT_D;
				
				ft_SUM_TOTAL_COMP <= ft_SUM_TOTAL_Q(24 downto 0);
				FINAL_MAX_COMP <= FINAL_MAX_Q(24 downto 0);
				PLOCAL_AVG_COMP <= PLOCAL_AVG_Q(24 downto 0);

				
--				ft_SUM_TOTAL_COMP <= ft_SUM_TOTAL_Q(int_IBIT_24 downto int_IBIT);
--				FINAL_MAX_COMP <= FINAL_MAX_Q(int_ABIT_24 downto int_ABIT);
--				PLOCAL_AVG_COMP <= PLOCAL_AVG_Q(int_PBIT_24 downto int_PBIT);
				
--				ft_SUM_TOTAL_COMP <= ft_SUM_TOTAL_Q((conv_integer(IBIT) + 24) downto conv_integer(IBIT));
--				FINAL_MAX_COMP <= FINAL_MAX_Q((conv_integer(ABIT) + 24) downto conv_integer(ABIT));
--				PLOCAL_AVG_COMP <= PLOCAL_AVG_Q((conv_integer(PBIT) + 24) downto conv_integer(PBIT));
				
		 	if (MODE = "010" or MODE = "101") then  
				if ft_SUM_TOTAL_COMP > SUM_OUT_Q(13 downto 0) then 
					SUM_OUT_2Q <= (others => '1');	
				else 
					SUM_OUT_2Q <= SUM_OUT_2D;
				end if;
				if FINAL_MAX_COMP > AMP_OUT_Q(8 downto 0) then 
					AMP_OUT_2Q <= (others => '1');	
				else 
					AMP_OUT_2Q <= AMP_OUT_2D;
				end if;	 
				if PLOCAL_AVG_COMP > PED_OUT_Q(7 downto 0) then 
					PED_OUT_2Q <= (others => '1');	
				else 
					PED_OUT_2Q <= PED_OUT_2D;
				end if;	 
			 else
			 
				if ft_SUM_TOTAL_COMP > SUM_OUT_Q(11 downto 0) then 
					SUM_OUT_2Q <= (others => '1');	
				else 
					SUM_OUT_2Q <= SUM_OUT_2D;
				end if;
				if FINAL_MAX_COMP > AMP_OUT_Q(11 downto 0) then 
					AMP_OUT_2Q <= (others => '1');	
				else 
					AMP_OUT_2Q <= AMP_OUT_2D;
				end if;	 
				if PLOCAL_AVG_COMP > PED_OUT_Q(10 downto 0) then
				--if FDC_PLOCAL_AVG_COMP > FDC_PED_OUT_Q(10 downto 0) then	
					PED_OUT_2Q <= (others => '1');	
				else 
					PED_OUT_2Q <= PED_OUT_2D;
					--PED_OUT_2Q <= FDC_PED_OUT_2D;
				end if;	 
			end if;	  		 
        end if;
    end process SCALES; 
--------------------------------------------------------------------------
---------- Data format mode muxing ---------------------------------------
-------------------------------------------------------------------------- 
	
	--LE_time + 10*hit_threshold_crossing_sample - XTHR*10 
	
--	hit_threshold_crossing_sample <= (conv_integer(WindowWdCnt_Q - 4))*10 when RT_PTW_PTR_PLOC = '1'; --CHANGE! - 2	 (-4 for 2 sample fth) 
--	int_XTHR_SAMPLE <= conv_integer(XTHR_SAMPLE)*10; 
--	int_ft_le_time <= conv_integer(ft_le_time) + hit_threshold_crossing_sample - int_XTHR_SAMPLE;
	
--	hit_threshold_crossing_sample <= (conv_integer(WindowWdCnt_Q - 4)) when RT_PTW_PTR_PLOC = '1'; --CHANGE! - 2	 (-4 for 2 sample fth) 
--	int_XTHR_SAMPLE <= conv_integer(XTHR_SAMPLE); 
--	int_ft_le_time <= conv_integer(ft_le_time) + ((hit_threshold_crossing_sample - int_XTHR_SAMPLE)*10); 

--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--	cross : process (CLK_PROCESS)
--	begin
--		if (CLK_PROCESS = '1' and CLK_PROCESS'event) then
--			if RT_PTW_PTR_PLOC = '1' then
--				hit_threshold_crossing_sample <= (conv_integer(WindowWdCnt_Q - 4) - conv_integer(XTHR_SAMPLE));	
--			else
--				hit_threshold_crossing_sample <= hit_threshold_crossing_sample;	
--			end if;
--		end if;
--	end process cross; 
--			   

--	hit_threshold_crossing_sample_D <= (conv_integer(WindowWdCnt_Q - 4) - conv_integer(XTHR_SAMPLE)) when RT_PTW_PTR_PLOC = '1' else
--		hit_threshold_crossing_sample_Q;  
		
	hit_threshold_crossing_sample_D <= (conv_integer(WindowWdCnt_Q - 4) - conv_integer(XTHR_SAMPLE)) when RT_PTW_PTR_PLOC = '1'; --change
	
	--int_XTHR_SAMPLE <= hit_threshold_crossing_sample*10;												
	--int_XTHR_SAMPLE <= hit_threshold_crossing_sample_Q*10;
	int_XTHR_SAMPLE_D <= hit_threshold_crossing_sample_Q*10;
	 	
	--int_ft_le_time <= conv_integer(ft_le_time) + int_XTHR_SAMPLE;
	int_ft_le_time_D <= conv_integer(ft_le_time) + int_XTHR_SAMPLE_Q;
--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX	 

	--FINAL_ft_le_time <= conv_std_logic_vector(int_ft_le_time, 11);
	FINAL_ft_le_time_D <= conv_std_logic_vector(int_ft_le_time_Q, 11);

--------------------------------------------------------------------------
--------------RAW SAMPLE Data words---------------------------------------
--------------------------------------------------------------------------
--	NOT_VALID_1 <= '0'; -- placeholder until needed
	
	RAW_SAMPLE_1_D <= PTW_RAM_DATA when SEL_RS_1 = '1'; -- else RAW_SAMPLE_1_Q;
	RAW_SAMPLE_2_D <= PTW_RAM_DATA when SEL_RS_2 = '1'; -- else RAW_SAMPLE_2_Q;
----	
	WIN_RAW_WORD_1_D <= "1" & "0100" & CHANNEL_NUMBER & "00000" &	"00000" & PTW;
	RAW_SAMPLE_WORD_2_D <= "0000" & RAW_SAMPLE_1_Q & "00" & NOT_VALID_2 & "0" & RAW_SAMPLE_2_Q; 
------ CDC SHORT
	CDC_FT_WORD_1_D <= "1" & "0101" & CHANNEL_NUMBER & PEAK_NUMBER & FINAL_ft_le_time_Q & ft_q_code & ft_overflow_TOTAL;   
	CDC_FT_WORD_2_D <= "0" & PED_OUT_2Q(7 downto 0) & SUM_OUT_2Q(13 downto 0) & AMP_OUT_2Q(8 downto 0);    
------ FDC SHORT	
	FDC_FT_SUM_WORD_1_D <= "1" & "0110" & CHANNEL_NUMBER & PEAK_NUMBER & FINAL_ft_le_time_Q & ft_q_code & ft_overflow_TOTAL;  
	FDC_FT_SUM_WORD_2_D <= "0" & SUM_OUT_2Q(11 downto 0) & FINAL_MAX_time(7 downto 0) & PED_OUT_2Q(10 downto 0); 
------ FDC SHORT AMP	
	FDC_FT_AMP_WORD_1_D <= "1" & "1001" & CHANNEL_NUMBER & PEAK_NUMBER & FINAL_ft_le_time_Q & ft_q_code & ft_overflow_TOTAL; 
	FDC_FT_AMP_WORD_2_D <= "0" & AMP_OUT_2Q(11 downto 0) & FINAL_MAX_time(7 downto 0) & PED_OUT_2Q(10 downto 0);   
		 
--------------------------------------------------------------------------
----------END Data format mode muxing-------------------------------------
--------------------------------------------------------------------------	

-------------------------------------------------------------------------------------- 
-- RE-Writting Process buffer data words as 32 bit. don't need tags at this stage because all mode data happens in parallel	and will be muxed before hand
-- will need to consider even/odd count for multiple peak times and what not, maybe, might be able to handle on proc.
-- will definatly need to have registered raw data for 32 bit muxed output for mode 0 and 8. plus even/odd filler consideration (now handled by 'not valid' word).	
-------------------------------------------------------------------------------------

--  PROC_BUF_WR_EN_D <= '1' when (PR_FIFO_WR_EN = '1' or PR_FIFO_WR_EN_TR = '1') else '0'; 
--							
--	NEW_PROCESS_BUF_DATA_D <= CDC_FT_WORD_1_Q 	  	when SEL_CDC_FT_WD_1 = '1' else
--							CDC_FT_WORD_2_Q 	  	when SEL_CDC_FT_WD_2 = '1' else
--						    FDC_FT_SUM_WORD_1_Q 	when SEL_FDC_SUM_WD_1 = '1' else
--							FDC_FT_SUM_WORD_2_Q		when SEL_FDC_SUM_WD_2 = '1' else
--							FDC_FT_AMP_WORD_1_Q 	when SEL_FDC_AMP_WD_1 = '1' else
--							FDC_FT_AMP_WORD_2_Q		when SEL_FDC_AMP_WD_2 = '1' else
--							WIN_RAW_WORD_1	  		when SEL_WIN_RAW_WD_1 = '1' else
--							--RAW_SAMPLE_WORD_2		when SEL_RAW_SAMPLE_2	= '1' else	
--							RAW_SAMPLE_WORD_2_Q		when SEL_RAW_SAMPLE_2	= '1' else	
--							X"FFFFFFFF"				when PR_FIFO_WR_EN_TR = '1' else --change
--							NEW_PROCESS_BUF_DATA_Q; --change	
--							--X"FFFFFFFF";
							
    MUX : process (CLK_PROCESS,SEL_CDC_FT_WD_1,SEL_CDC_FT_WD_2,SEL_FDC_SUM_WD_1,SEL_FDC_SUM_WD_2,
				   SEL_FDC_AMP_WD_1,SEL_FDC_AMP_WD_2,SEL_WIN_RAW_WD_1,SEL_RAW_SAMPLE_2,PR_FIFO_WR_EN_TR,PR_FIFO_WR_EN)
	begin
		if (CLK_PROCESS = '1' and CLK_PROCESS'event) then  

--			WIN_RAW_WORD_1 <= "1" & "0100" & CHANNEL_NUMBER & "00000" &	"00000" & PTW;
--			RAW_SAMPLE_WORD_2_D <= "0000" & RAW_SAMPLE_1_Q & "00" & NOT_VALID_2 & "0" & RAW_SAMPLE_2_Q; 
--		------ CDC SHORT
--			CDC_FT_WORD_1_D <= "1" & "0101" & CHANNEL_NUMBER & PEAK_NUMBER & FINAL_ft_le_time_Q & ft_q_code & ft_overflow_TOTAL;   
--			CDC_FT_WORD_2_D <= "0" & PED_OUT_2Q(7 downto 0) & SUM_OUT_2Q(13 downto 0) & AMP_OUT_2Q(8 downto 0);    
--		------ FDC SHORT	
--			FDC_FT_SUM_WORD_1_D <= "1" & "0110" & CHANNEL_NUMBER & PEAK_NUMBER & FINAL_ft_le_time_Q & ft_q_code & ft_overflow_TOTAL;  
--			FDC_FT_SUM_WORD_2_D <= "0" & SUM_OUT_2Q(11 downto 0) & FINAL_MAX_time(7 downto 0) & PED_OUT_2Q(10 downto 0); 
--		------ FDC SHORT AMP	
--			FDC_FT_AMP_WORD_1_D <= "1" & "1001" & CHANNEL_NUMBER & PEAK_NUMBER & FINAL_ft_le_time_Q & ft_q_code & ft_overflow_TOTAL; 
--			FDC_FT_AMP_WORD_2_D <= "0" & AMP_OUT_2Q(11 downto 0) & FINAL_MAX_time(7 downto 0) & PED_OUT_2Q(10 downto 0);   
			
			if (PR_FIFO_WR_EN = '1' or PR_FIFO_WR_EN_TR = '1') then
				PROC_BUF_WR_EN_D <= '1'; 
			else
				PROC_BUF_WR_EN_D <= '0';
			end if;
			
			if SEL_CDC_FT_WD_1 = '1' then
				NEW_PROCESS_BUF_DATA_D <= CDC_FT_WORD_1_Q;
			end if;
			if SEL_CDC_FT_WD_2 = '1' then
				NEW_PROCESS_BUF_DATA_D <= CDC_FT_WORD_2_Q;
			end if;
			if SEL_FDC_SUM_WD_1 = '1' then
				NEW_PROCESS_BUF_DATA_D <= FDC_FT_SUM_WORD_1_Q;
			end if;
			if SEL_FDC_SUM_WD_2 = '1' then
				NEW_PROCESS_BUF_DATA_D <= FDC_FT_SUM_WORD_2_Q;
			end if;
			if SEL_FDC_AMP_WD_1 = '1' then
				NEW_PROCESS_BUF_DATA_D <= FDC_FT_AMP_WORD_1_Q;
			end if;
			if SEL_FDC_AMP_WD_2 = '1' then
				NEW_PROCESS_BUF_DATA_D <= FDC_FT_AMP_WORD_2_Q;
			end if;
			if SEL_WIN_RAW_WD_1 = '1' then
				NEW_PROCESS_BUF_DATA_D <= WIN_RAW_WORD_1_Q;
			end if;
			if SEL_RAW_SAMPLE_2 = '1' then
				NEW_PROCESS_BUF_DATA_D <= RAW_SAMPLE_WORD_2_Q;
			end if;	 
			if PR_FIFO_WR_EN_TR = '1' then
				NEW_PROCESS_BUF_DATA_D <= X"FFFFFFFF";
			end if;	 
			
	 			CDC_FT_WORD_1_Q <= CDC_FT_WORD_1_D;
	 			CDC_FT_WORD_2_Q <= CDC_FT_WORD_2_D; 
	
	 			FDC_FT_SUM_WORD_1_Q <= FDC_FT_SUM_WORD_1_D;
				FDC_FT_SUM_WORD_2_Q <= FDC_FT_SUM_WORD_2_D;
				
	 			FDC_FT_AMP_WORD_1_Q <= FDC_FT_AMP_WORD_1_D;
				FDC_FT_AMP_WORD_2_Q <= FDC_FT_AMP_WORD_2_D;
				 		
				RAW_SAMPLE_1_Q <= RAW_SAMPLE_1_D;
				RAW_SAMPLE_2_Q <= RAW_SAMPLE_2_D;
				
				SEL_RAW_SAMPLE_2_Q <= SEL_RAW_SAMPLE_2_D;  
				
				WIN_RAW_WORD_1_Q <= WIN_RAW_WORD_1_D;
				RAW_SAMPLE_WORD_2_Q <= RAW_SAMPLE_WORD_2_D;
				
				PROC_BUF_WR_EN_Q <= PROC_BUF_WR_EN_D;
				NEW_PROCESS_BUF_DATA_Q <= NEW_PROCESS_BUF_DATA_D;	
		end if;		
	end process MUX;
	--PROC_BUF_WR_EN <= PROC_BUF_WR_EN_Q; --change						
	--NEW_PROCESS_BUF_DATA <= NEW_PROCESS_BUF_DATA_Q; --change
										
--------------------------------------------------------------------------  
--- Write Data to host buffer.										  
--------------------------------------------------------------------------
  --WR_PTR_D <= WR_PTR_Q + 1 when WR_PTR_CNT_EN_Q = '1' else WR_PTR_Q; -- This rolls over to 0 when LAST_PROC_BUF_ADR is reached need to make data format consistent 
  
  ---- Keep track of the number of Block processed
  HOST_BLOCK_CNT_REG <= HOST_BLOCK_CNT_Q;
  HOST_BLOCK_CNT_D <= HOST_BLOCK_CNT_Q + 1 when HOST_BLOCK_INC_D = '1' and DEC_BLOCK_CNT = '0'  else
                      HOST_BLOCK_CNT_Q - 1 when DEC_BLOCK_CNT = '1'  and HOST_BLOCK_INC_D = '0' else
                      HOST_BLOCK_CNT_Q;

  
  --PROCESS_BUF_WEN_D <= PROBUFWEN1 or PROBUFWEN_CDC;	-- or PROBUFWEN_TDC	change
  
  RD_PTW_PTR_EN   <= RD_PTW_PTR_EN_5 or RAW_PTW_PTR_EN; -- RD_PTW_PTR_EN_2 or RD_PTW_PTR_EN_1 
  --WR_PTR_CNT_EN_D      <= WR_PTR_CNT_EN_1 or WR_PTR_CNT_EN_2; -- added WR_PTR_CNT_EN_2 for CDC_FT	removed or WR_PTR_CNT_EN_TDC 
	  
	UPROCESS_BUF : PROC_BUFF_FIFO -- FWFT
	port map
	(
		    rst 	=> RST, --not RESET_N,
		    --wr_clk 	=> CLK_PROCESS, --CLK_PROCESS, --not CLK_PROCESS,
		    --rd_clk 	=> CLK_PROCESS,
			clk 	=> CLK_PROCESS,
		    din 	=> NEW_PROCESS_BUF_DATA_Q, --NEW_PROCESS_BUF_DATA_Q, --NEW_PROCESS_BUF_DATA,
		    wr_en 	=> PROC_BUF_WR_EN_Q, --PROC_BUF_WR_EN_Q, --PROC_BUF_WR_EN,
		    rd_en 	=> PR_FIFO_RD_EN,
		    dout 	=> NEW_PROC_OUTDAT,
		    full 	=> open,
		    empty 	=> open
	  );
--------------------------------------------------------------------------
--END WRITE TO HOST BUFFER SECTION
--------------------------------------------------------------------------
	  
  ---- State Machine

  LATCH_NOEVENT_D <= '1' when NoEventLatch = '1' else 
                     '0' when LatchNoEvenClr = '1' else
                     LATCH_NOEVENT_Q;

----HACKY THING TO TRY AND GET PTW_DONE RIGHT
--	WindowWdCnt_D <= (WindowWdCnt_Q - 1)	when (RD_PTW_PTR_EN_5 = '1' or RAW_PTW_PTR_EN = '1' or FT_INC_PTW_PTR_TDC = '1')  else 	-- (-1) accounts for starting at 0
--					 "00"&PTW   	when (PTW_CNT_CLR = '1' or CLR_PTW_DONE = '1' or FT_DONE = '1' or CLR_COUNTS = '1') else	 --PTW(11 downto 0)	 --change add clr_counts
--					 WindowWdCnt_Q;	 
--					
--	WindowWdCntTc_D <= '1' when WindowWdCnt_Q = conv_std_logic_vector(1,10) else '0';
--	cruise_PTW_DONE <= WindowWdCntTc_D;
--	
--	WE_DONE <= '1' when WindowWdCnt_Q = NE else '0'; -- accounting for WE <= PTW - 6; --conv_std_logic_vector(7,10)	 
		
	WindowWdCnt_D <= (WindowWdCnt_Q + 1)	when (RD_PTW_PTR_EN_5 = '1' or RAW_PTW_PTR_EN = '1' or FT_INC_PTW_PTR_TDC = '1')  else 	-- (-1) accounts for starting at 0
					 X"000"   				when (PTW_CNT_CLR = '1' or CLR_PTW_DONE = '1' or FT_DONE = '1' or CLR_COUNTS = '1') else	 --PTW(11 downto 0)	 --change add clr_counts
					 WindowWdCnt_Q;	 
					 
	PTW_MINUS_1 <= (PTW - X"002"); --change to account for data delay 
	--cruise_PTW_DONE <= '1' when WindowWdCnt_Q = PTW_MINUS_1 else '0';
	RAW_PTW_DONE <= '1' when WindowWdCnt_Q = PTW else '0'; 
		
	NEW_END_D <= '1' when WindowWdCnt_Q = PTW_MINUS_1 else '0';	
	cruise_PTW_DONE <= NEW_END_Q; --NEW_END_Q

			
	--WE_MINUS_NE <= (PTW + 2) - NE; --CHANGE!
	--WE_DONE <= '1' when WindowWdCnt_Q = WE_MINUS_NE else '0'; 
	WE_MINUS_NE <= (PTW + 1) - NE; --CHANGE!
	WE_DONE_D <= '1' when WindowWdCnt_Q = WE_MINUS_NE else '0';
	WE_DONE <= WE_DONE_Q;

---- counting up for threshold crossing value
--	PROCESS_DONE <= IDLE;
	
---- State machine that handles hit search and mode selection, writes to proc fifo		

	UPROCESSM : FT_PROCESSM_CDC_FDC 
	port map 
			(
				CLK					=> CLK_PROCESS, 
				FT_ABOVE_TH 		=> FT_ABOVE_TH_D, --FT_ABOVE_TH_Q, --change 
				FT_DONE		 		=> FT_DONE,
				GO            		=> PROCESS_GO,
				
				MODE				=> MODE,
				
				INIT_PED_CALC_DN 	=> INIT_PED_CALC_DONE,
				LOC_PED_CALC_DN 	=> LOC_PED_CALC_DONE,
				
				WE_DONE				=> WE_DONE,
				PTW_DONE      		=> RAW_PTW_DONE, --cruise_PTW_DONE, --PTW_DONE,	 
				--RAW_PTW_DONE		=> RAW_PTW_DONE, --WindowWdCntTc_Q,
				RESET_N       		=> RESET_N,
				CLR_INIT_PED_CNT   	=> CLR_INIT_PED_CNT_D,
				CLR_LOC_PED_CNT	   	=> CLR_LOC_PED_CNT_D,
				CLR_PTW_DONE    	=> CLR_PTW_DONE,
				wait_PG_done		=> wait_PG_done,
				--CLR_PG				=> CLR_PG,

				--DEC_PTW_CNT     	=> DEC_PTW_CNT,
				FT_GO				=> FT_GO,
				HOST_BLOCK_INC  	=> HOST_BLOCK_INC_D,
				IDLE            	=> IDLE, --PROCESS_DONE,
				--LAST_MD_DATA_CDC 	=> LAST_MD_DATA_CDC,
				
				NoEventLatch      	=> NoEventLatch,
				NO_EVENT			=> LATCH_NOEVENT_Q,
				LatchNoEvenClr  	=> LatchNoEvenClr,
				
				PINIT_CALC_EN 		=> PINIT_CALC_EN,
				PLOCAL_CALC_EN		=> PLOCAL_CALC_EN,
				PR_FIFO_WR_EN		=> PR_FIFO_WR_EN,
				PR_FIFO_WR_EN_TR	=> PR_FIFO_WR_EN_TR,
				RD_PTW_PTR_EN_5 	=> RD_PTW_PTR_EN_5,
				PTW_CNT_CLR			=> PTW_CNT_CLR,	
				
				RT_PTW_PTR      	=> RT_PTW_PTR,
				RT_PTW_PTR_2		=> RT_PTW_PTR_2,
				RT_PTW_PTR_PLOC		=> RT_PTW_PTR_PLOC,
				SAVE_PTW_PTR    	=> SAVE_PTW_PTR,
				SAVE_PTW_PTR_FT		=> SAVE_PTW_PTR_FT,
				
				RAW_PTW_PTR_EN		=> RAW_PTW_PTR_EN,
				SEL_WIN_RAW_WD_1	=> SEL_WIN_RAW_WD_1,
				--SEL_WIN_PLS_WD_1	=> SEL_WIN_PULSE_WD_1,
				SEL_RS_1			=> SEL_RS_1,
				SEL_RS_2			=> SEL_RS_2,
				SEL_RAW_SAMPLE_2	=> SEL_RAW_SAMPLE_2, 
				NOT_VALID_2			=> NOT_VALID_2,
				
				SEL_CDC_FT_WD_1 	=> SEL_CDC_FT_WD_1,
				SEL_CDC_FT_WD_2 	=> SEL_CDC_FT_WD_2,
				
				SEL_FDC_SUM_WD_1	=> SEL_FDC_SUM_WD_1,
				SEL_FDC_SUM_WD_2	=> SEL_FDC_SUM_WD_2,
				
				SEL_FDC_AMP_WD_1	=> SEL_FDC_AMP_WD_1,
				SEL_FDC_AMP_WD_2	=> SEL_FDC_AMP_WD_2,
				
				--SEL_MODE6_WD_1		=> SEL_MODE6_WD_1,
				--SEL_MODE7_WD_1		=> SEL_MODE7_WD_1,
				
				DEC_PEAK_CNT		=> DEC_PEAK_CNT,
				--CLR_PEAK_CNT		=> CLR_PEAK_CNT,
				PEAK_WRITE_DONE		=> PEAK_WRITE_DONE
			);


---- top level wrapper for findtime, includes state machine for SUM, peak amp, peak time values
	   	uCDC_findtime_top : CDC_findtime_top 
			 Port map
					( 
						clk => CLK_PROCESS,
						RESET_N => RESET_N,
						--PTW					  	=> PTW,
						MAX_NUMBER_PEAKS		=> MAX_NUMBER_OF_PULSE,
       
						le_time  				=> ft_le_time, 
						ft_q_code 				=> ft_q_code,  -- quality code, 0 is good
--						FIRST_MAX 				=> ft_FIRST_MAX,
						ft_overflow_TOTAL		=> ft_overflow_TOTAL,
						SUM_TOTAL 				=> ft_SUM_TOTAL,
						
						PEAK_NUMBER_out			=> PEAK_NUMBER,
						FINAL_MAX_time_out		=> FINAL_MAX_time,
						FINAL_MAX_out			=> FINAL_MAX,
						
						DEC_PEAK_CNT			=> DEC_PEAK_CNT,
						--CLR_PEAK_CNT			=> CLR_PEAK_CNT,
						PEAK_WRITE_DONE			=> PEAK_WRITE_DONE,

						TDC_GO 					=> FT_GO, --TDC_GO, 
						ft_done 				=> FT_DONE, -- "done" at end of findtime,... and ptw window

						PTW_RAM_DATA            => PTW_RAM_DATA,
						--OVERFLOW				=> OVERFLOW,

					-- NEW REGS
--						NSAMPLES				=> NSAMPLES,
						
--			   			XTHR_SAMPLE				=> XTHR_SAMPLE,
--			    		PED_SAMPLE 				=> PED_SAMPLE,
			    
			    		THRES_HI				=> THRES_HI,
			    		THRES_LO				=> THRES_LO,
			
--			    		ROUGH_DT 				=> ROUGH_DT,
--			    		INT_SAMPLE 				=> INT_SAMPLE,
			    
--			    		LIMIT_ADC_MAX 			=> LIMIT_ADC_MAX,
--			    		LIMIT_PED_MAX 			=> LIMIT_PED_MAX,
			
--			    		SET_ADC_MIN 			=> SET_ADC_MIN,
--			    		LIMIT_UPS_ERR 			=> LIMIT_UPS_ERR, 
						
						IE						=> IE,
						PG						=> PG,
						
						-- NEW SIGNALS FOR CDC/FDC 
						--RT_PTW_PTR_TDC          => FT_RT_PTW_PTR_TDC, --RT_PTW_PTR_TDC,
						INC_PTW_PTR_TDC         => FT_INC_PTW_PTR_TDC, --INC_PTW_PTR_TDC, 
						WE_DONE					=> WE_DONE,
						PTW_DONE				=> cruise_PTW_DONE, --WindowWdCntTc_D, --cruise_PTW_DONE,
						
						CLR_COUNTS				=> CLR_COUNTS,
						RT_PTW_PTR_LS			=> RT_PTW_PTR_LS,
						
						le_sample 				=> le_sample, -- sample containing leading edge	
						le_sample_found_out			=> le_sample_found,
						FT_START_FROM_LS		=> FT_START_FROM_LS,
						
						FT_START_FROM_NU		=> FT_START_FROM_NU
						--FT_START_FROM_TC		=> FT_START_FROM_TC
					);	

  ----- multi mode processing
  --LD_PTW_RAM_ADR_D <= LD_PTW_RAM_ADR;          

       
    REG : process (CLK_PROCESS, RESET_N)
      begin
        if RESET_N = '0' then
				RD_PTW_PTR_Q        <= (others => '0');
				HOST_BLOCK_CNT_Q     <= (others => '0');

				DEC_BLOCK_CNT_BUF1_Q <= '0';

				WR_PTR_CNT_EN_Q  <= '0';
				--PROCESS_BUF_WEN_Q <= '0';

				SAVE_RD_PTW_PTR_Q <= (others => '0');
				FT_SAVE_RD_PTW_PTR_Q <= (others => '0');
				--FT_SAVE_TC_PTW_PTR_Q <= (others => '0');

				LATCH_NOEVENT_Q   <= '0';

				--RD_PTW_PTR_SAVED_Q <= (others => '0');

				--LD_PTW_RAM_ADR_Q <= '0';

				PED_CNT_Q <= (others => '0');
				PINIT_Q <= (others => '0');

				CLR_LOC_PED_CNT_Q <= '0';	
				
				PINIT_AVG_Q <= (others => '0');
				PLOCAL_AVG_Q <= (others => '0');
				
				--X_THRESH_Q <= (others => '0');	
				
				--ft_overflow_cnt_Q <= "000"; 
				PROCESS_DONE <= '1';
				
				--WindowWdCnt_Q <= (others => '0');	-- cleared on reset from SM
		  
        elsif (CLK_PROCESS = '1' and CLK_PROCESS'event) then
			
			---- counting up for threshold crossing value
				PROCESS_DONE <= IDLE;
			
				RD_PTW_PTR_Q         <= RD_PTW_PTR_D;

				HOST_BLOCK_CNT_Q     <= HOST_BLOCK_CNT_D;

				WR_PTR_CNT_EN_Q  <= WR_PTR_CNT_EN_D;
				--PROCESS_BUF_WEN_Q <= PROCESS_BUF_WEN_D;

				SAVE_RD_PTW_PTR_Q <= SAVE_RD_PTW_PTR_D;
				FT_SAVE_RD_PTW_PTR_Q <= FT_SAVE_RD_PTW_PTR_D;

				LATCH_NOEVENT_Q   <= LATCH_NOEVENT_D;

				PED_CNT_Q <= PED_CNT_D;
				PINIT_Q <= PINIT_D;
				--PLOCAL_Q <= PLOCAL_D;

				CLR_INIT_PED_CNT_Q <= CLR_INIT_PED_CNT_D;
				CLR_LOC_PED_CNT_Q <= CLR_LOC_PED_CNT_D;
				FT_ABOVE_TH_Q <= FT_ABOVE_TH_D;

				--FT_SAVE_TC_PTW_PTR_Q <= FT_SAVE_TC_PTW_PTR_D;	
				FT_SAVE_LS_PTW_PTR_Q <= FT_SAVE_LS_PTW_PTR_D;

				WindowWdCnt_Q <= WindowWdCnt_D;	
				--X_THRESH_CNT_Q <= X_THRESH_CNT_D;	 
				
				PINIT_AVG_Q <= PINIT_AVG_D;	
				hit_threshold_crossing_sample_Q <= hit_threshold_crossing_sample_D;	 
				  
         		--MAX_NUMBER_OF_PULSE_Q <= MAX_NUMBER_OF_PULSE_D;
				 
								
				NEW_END_Q <= NEW_END_D;
				
				WE_DONE_Q <= WE_DONE_D;
				
				PG_OFFSET_Q <= PG_OFFSET_D;	
					
				int_XTHR_SAMPLE_Q <= int_XTHR_SAMPLE_D;
				int_ft_le_time_Q <= int_ft_le_time_D;
				FINAL_ft_le_time_Q <= FINAL_ft_le_time_D;
				
				int_IBIT <= conv_integer(IBIT);
				int_ABIT <= conv_integer(ABIT);
				int_PBIT <= conv_integer(PBIT);
	
				int_IBIT_24 <= conv_integer(IBIT) + 24;
			 	int_ABIT_24	<= conv_integer(ABIT) + 24;
				int_PBIT_24	<= conv_integer(PBIT) + 24;	


				ft_SUM_TOTAL_Q <= "0000000" & ft_SUM_TOTAL(int_IBIT_24 downto int_IBIT);
				FINAL_MAX_Q <= "0000000" & FINAL_MAX(int_ABIT_24 downto int_ABIT);
				PLOCAL_AVG_Q <= "0000000" & PLOCAL_AVG_D(int_PBIT_24 downto int_PBIT);
				--FDC_PLOCAL_AVG_Q <= "0000000" & FDC_PLOCAL_AVG_D(int_PBIT_24 downto int_PBIT);
				--PR_FIFO_WR_EN_Q <= PR_FIFO_WR_EN_D;
			end if;
      end process REG;

        
end RTL;

--	SUM_OUT_D <= ft_SUM_TOTAL_Q((conv_integer(IBIT) + 13) downto conv_integer(IBIT));	
--	AMP_OUT_D <= FINAL_MAX_Q((conv_integer(ABIT) + 11) downto conv_integer(ABIT));
--	PED_OUT_D <= PLOCAL_AVG_Q((conv_integer(PBIT) + 10) downto conv_integer(PBIT));
--
----------------------------------------------------------------------------
---------------- END Scale factorz
---------------------------------------------------------------------------- 
--	SCALES : process (CLK_PROCESS)
--        begin
--         if (CLK_PROCESS = '1' and CLK_PROCESS'event) then  
--			
--		 	if (MODE = "010" or MODE = "101") then  
--				if ft_SUM_TOTAL_Q > SUM_OUT_D(13 downto 0) then 
--					SUM_OUT_Q <= (others => '1');	
--				else 
--					SUM_OUT_Q <= SUM_OUT_D;
--				end if;
--				if FINAL_MAX_Q > AMP_OUT_D(8 downto 0) then 
--					AMP_OUT_Q <= (others => '1');	
--				else 
--					AMP_OUT_Q <= AMP_OUT_D;
--				end if;	 
--				if PLOCAL_AVG_Q > PED_OUT_D(7 downto 0) then 
--					PED_OUT_Q <= (others => '1');	
--				else 
--					PED_OUT_Q <= PED_OUT_D;
--				end if;	 
--			 else
--			 
--				if ft_SUM_TOTAL_Q > SUM_OUT_D(11 downto 0) then 
--					SUM_OUT_Q <= (others => '1');	
--				else 
--					SUM_OUT_Q <= SUM_OUT_D;
--				end if;
--				if FINAL_MAX_Q > AMP_OUT_D(11 downto 0) then 
--					AMP_OUT_Q <= (others => '1');	
--				else 
--					AMP_OUT_Q <= AMP_OUT_D;
--				end if;	 
--				if PLOCAL_AVG_Q > PED_OUT_D(10 downto 0) then 
--					PED_OUT_Q <= (others => '1');	
--				else 
--					PED_OUT_Q <= PED_OUT_D;
--				end if;	 
--			end if;	  		 
--        end if;
--    end process SCALES; 	

					 
------ mode 1
--	--WIN_RAW_WORD_1 <= "1" & "0100" & CHANNEL_NUMBER & "00000" &	"00000" & PTW when SEL_WIN_RAW_WD_1 = '1' else (others => '0');--PTW(11 downto 0); -- when SET_WIN_RAW_WD_1
--	WIN_RAW_WORD_1 <= "1" & "0100" & CHANNEL_NUMBER & "00000" &	"00000" & PTW;	
--	RAW_SAMPLE_WORD_2 <= "00" & NOT_VALID_1 & RAW_SAMPLE_1_Q & "00" & NOT_VALID_2 & RAW_SAMPLE_2_Q when SEL_RAW_SAMPLE_2 = '1' else (others => '0'); --change
-------- mode 3
--	CDC_FT_WORD_1_D <= "1" & "0101" & CHANNEL_NUMBER & PEAK_NUMBER & FINAL_ft_le_time_Q & ft_q_code & ft_overflow_TOTAL when FT_DONE = '1' else CDC_FT_WORD_1_Q;  --need to rename vars for CDC, because FDC is comming soon! 
--	CDC_FT_WORD_2_D <= "0" & PED_OUT_2Q(7 downto 0) & SUM_OUT_2Q(13 downto 0) & AMP_OUT_2Q(8 downto 0) when PR_FIFO_WR_EN = '1' else CDC_FT_WORD_2_Q;   --ft_SUM_TOTAL(13 downto 0) -- PLOCAL_AVG(7 downto 0) ft_FIRST_MAX(8 downto 0) 
-------- mode 4	
--	FDC_FT_SUM_WORD_1_D <= "1" & "0110" & CHANNEL_NUMBER & PEAK_NUMBER & FINAL_ft_le_time_Q & ft_q_code & ft_overflow_TOTAL when FT_DONE = '1' else FDC_FT_SUM_WORD_1_Q;  
--	FDC_FT_SUM_WORD_2_D <= "0" & SUM_OUT_2Q(11 downto 0) & FINAL_MAX_time(7 downto 0) & PED_OUT_2Q(10 downto 0) when PR_FIFO_WR_EN = '1' else FDC_FT_SUM_WORD_2_Q; --FT_DONE = '1'; -- ft_SUM_TOTAL(11 downto 0) -- PLOCAL_AVG(10 downto 0) 	
-------- mode 5	
--	FDC_FT_AMP_WORD_1_D <= "1" & "1001" & CHANNEL_NUMBER & PEAK_NUMBER & FINAL_ft_le_time_Q & ft_q_code & ft_overflow_TOTAL when FT_DONE = '1' else FDC_FT_AMP_WORD_1_Q; 
--	FDC_FT_AMP_WORD_2_D <= "0" & AMP_OUT_2Q(11 downto 0) & FINAL_MAX_time(7 downto 0) & PED_OUT_2Q(10 downto 0) when PR_FIFO_WR_EN = '1' else FDC_FT_AMP_WORD_2_Q; --FT_DONE = '1'; -- FINAL_MAX(11 downto 0) -- PLOCAL_AVG(10 downto 0) 



--	NEW_PROCESS_BUF_DATA <= CDC_FT_WORD_1_Q 	  	when SEL_CDC_FT_WD_1 = '1' else
--							CDC_FT_WORD_2_D 	  	when SEL_CDC_FT_WD_2 = '1' else
--						    FDC_FT_SUM_WORD_1_Q 	when SEL_FDC_SUM_WD_1 = '1' else
--							FDC_FT_SUM_WORD_2_D		when SEL_FDC_SUM_WD_2 = '1' else
--							FDC_FT_AMP_WORD_1_Q 	when SEL_FDC_AMP_WD_1 = '1' else
--							FDC_FT_AMP_WORD_2_D		when SEL_FDC_AMP_WD_2 = '1' else
--							WIN_RAW_WORD_1	  		when SEL_WIN_RAW_WD_1 = '1' else
--							--WIN_PULSE_WRD_1	  	  when SEL_WIN_PULSE_WD_1 = '1' else					  
--							RAW_SAMPLE_WORD_2 		when SEL_RAW_SAMPLE_2	= '1' else -- change
--							--MODE6_SUM_WORD_1_Q  when SEL_MODE6_WD_1	= '1' else
--							--MODE7_SUM_WORD_1_Q  when SEL_MODE7_WD_1	= '1' else
--							--"01" & x"0000" when LATCH_NOEVENT_Q = '1' and NoEventLatchEn = '1' and ChannelCheck = '0' else
--							X"FFFFFFFF" when LAST_MD_DATA_CDC = '1' else	-- or LAST_MD_DATA_TDC = '1' -- LAST_MD1_DATA_Q(2) = '1' or LAST_MD1_DATA2 = '1' or 
--							X"00000000";  