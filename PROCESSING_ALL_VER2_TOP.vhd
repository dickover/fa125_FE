--  Author: Cody Dickover
--  Filename: PROCESSING_ALL_VER2_TOP.vhd 
--  Date: 4/30/15
--

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_unsigned.all; 
  use IEEE.std_logic_arith.all;

entity PROCESSING_ALL_VER2_TOP is
        port
         (
           CLK_PROCESS          : in std_logic; 
           --CLK_HOST             : in std_logic; 
           RESET_N              : in  std_logic;
--           SOFT_RESET_N         : in std_logic;
		   PTW          		: in  std_logic_vector(9 downto 0);
		   cid					: in std_logic_vector(3 downto 0);
		   DEC_TRIG_BUFF		: out std_logic; -- done process for data buffer 
		   
		   	NP					: in std_logic_vector(7 downto 0); -- number of samples for initial pedestal
			NP2					: in std_logic_vector(7 downto 0);	-- number of samples for local pedestal
				
			IBIT				: in std_logic_vector(2 downto 0);					
			ABIT				: in std_logic_vector(2 downto 0);
			PBIT				: in std_logic_vector(2 downto 0);
			
			-- NEW REGS
--			NSAMPLES			: in std_logic_vector(7 downto 0);   -- max number of ADC samples to read in   --int 16
			
--	   		XTHR_SAMPLE			: in std_logic_vector(7 downto 0); -- the 5 sigma thres xing is sample[9] passed into the algo, starting with sample[0]
--    		PED_SAMPLE 			: in std_logic_vector(7 downto 0); -- take local ped as sample[5]
--    
    		THRES_HI_0			: in std_logic_vector(8 downto 0); -- 4 sigma --int 80	--will need 6 of these!!!!!!!!!!!!
    		THRES_LO_0			: in std_logic_vector(7 downto 0); -- 1 sigma --int 20	
			
    		THRES_HI_1			: in std_logic_vector(8 downto 0); -- 4 sigma --int 80	--will need 6 of these!!!!!!!!!!!!
    		THRES_LO_1			: in std_logic_vector(7 downto 0); -- 1 sigma --int 20
			
    		THRES_HI_2			: in std_logic_vector(8 downto 0); -- 4 sigma --int 80	--will need 6 of these!!!!!!!!!!!!
    		THRES_LO_2			: in std_logic_vector(7 downto 0); -- 1 sigma --int 20
			
    		THRES_HI_3			: in std_logic_vector(8 downto 0); -- 4 sigma --int 80	--will need 6 of these!!!!!!!!!!!!
    		THRES_LO_3			: in std_logic_vector(7 downto 0); -- 1 sigma --int 20
			
    		THRES_HI_4			: in std_logic_vector(8 downto 0); -- 4 sigma --int 80	--will need 6 of these!!!!!!!!!!!!
    		THRES_LO_4			: in std_logic_vector(7 downto 0); -- 1 sigma --int 20
			
    		THRES_HI_5			: in std_logic_vector(8 downto 0); -- 4 sigma --int 80	--will need 6 of these!!!!!!!!!!!!
    		THRES_LO_5			: in std_logic_vector(7 downto 0); -- 1 sigma --int 20
--
--    		ROUGH_DT 			: in std_logic_vector(7 downto 0);   --if algo fails, return this many tenth-samples before threshold xing --int 24
--    		INT_SAMPLE 			: in std_logic_vector(7 downto 0); -- if algo fails, start integration with this sample
    
--    		LIMIT_ADC_MAX 		: in std_logic_vector(15 downto 0);  -- return rough time if ADC sample exceeds this value --int 4096
--    		LIMIT_PED_MAX 		: in std_logic_vector(15 downto 0);  -- return rough time if pedestal exceeds this --int 511

--    		SET_ADC_MIN 		: in std_logic_vector(15 downto 0);  -- set min value of ADC sample subset equal to this  --int 20
--    		LIMIT_UPS_ERR 		: in std_logic_vector(15 downto 0);  -- return midpoint time if sum of upsampling errors exceeds this --int 30	
				
			IE 					: in std_logic_vector(11 downto 0);	
           	PG 					: in std_logic_vector(7 downto 0);
           -- Common to all Channel
           MODE                 : in std_logic_vector(2 downto 0);  -- 0 -> copy entire PTW buffer to Host
                                                                    -- 1 -> copy NSB and NSA words from thredshold
                                                                    -- 2 -> compute sum of NSB and NSA words
                                                                    -- 3 -> TDC mode
                                                                    -- 7 --> mode 0 and TDC run for each trigger
           MAX_NUMBER_OF_PULSE  : in std_logic_vector(5 downto 0);  -- set the max number of pulse allowed per trigger

--           PTW_DAT_BUF_LAST_ADR  : in std_logic_VECTOR(11 downto 0);  --- The last address of the PTW data Buffer
           --LAST_PROC_BUF_ADR : out std_logic_VECTOR(11 downto 0); -- Last address of Processing Buffer. To data format block
		   
		   CH0_PTW_DATA_BLOCK_CNT : in std_logic_vector(7 downto 0); -- use for GO, OTHERS REMOVED
		   
           -- Channel 0 **********************         
           CH0_DEC_PTW_CNT : out std_logic;  --- Rising egde decrease number of PTW Data Block ready to process by one.
           --CH0_PTW_DATA_BLOCK_CNT : in std_logic_vector(7 downto 0);            
           CH0_HOST_BLOCK_CNT_REG : out std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
           CH0_DEC_BLOCK_CNT : in std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
           CH0_PTW_RAM_DATA   : in std_logic_vector(11 downto 0);
           CH0_PTW_RAM_ADR    : out std_logic_vector(9 downto 0); 
		   --OVERFLOW_0		  : in std_logic;
           ---- To DATA Format block
		   CH0_RD_EN		: in std_logic;
           CH0_PROC_OUTDAT  : out std_logic_VECTOR(31 downto 0);
           TET0             : in std_logic_VECTOR(11 downto 0);


           -- Channel 1 **********************         
           CH1_DEC_PTW_CNT : out std_logic;  --- Rising egde decrease number of PTW Data Block ready to process by one.
           --CH1_PTW_DATA_BLOCK_CNT : in std_logic_vector(7 downto 0);            
           CH1_HOST_BLOCK_CNT_REG : out std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
           CH1_DEC_BLOCK_CNT : in std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
           CH1_PTW_RAM_DATA   : in std_logic_vector(11 downto 0);
           CH1_PTW_RAM_ADR    : out std_logic_vector(9 downto 0); 
		   --OVERFLOW_1		  : in std_logic;
           ---- To DATA Format block
           CH1_RD_EN		: in std_logic;
           CH1_PROC_OUTDAT  : out std_logic_VECTOR(31 downto 0);
           TET1             : in std_logic_VECTOR(11 downto 0);

           -- Channel 2 **********************          
           CH2_DEC_PTW_CNT : out std_logic;  --- Rising egde decrease number of PTW Data Block ready to process by one.
           --CH2_PTW_DATA_BLOCK_CNT : in std_logic_vector(7 downto 0);            
           CH2_HOST_BLOCK_CNT_REG : out std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
           CH2_DEC_BLOCK_CNT : in std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
           CH2_PTW_RAM_DATA   : in std_logic_vector(11 downto 0);
           CH2_PTW_RAM_ADR    : out std_logic_vector(9 downto 0); 
		   --OVERFLOW_2		  : in std_logic;
           ---- To DATA Format block
           CH2_RD_EN		: in std_logic;
           CH2_PROC_OUTDAT  : out std_logic_VECTOR(31 downto 0);
           TET2             : in std_logic_VECTOR(11 downto 0);

           -- Channel 3 **********************        
           CH3_DEC_PTW_CNT : out std_logic;  --- Rising egde decrease number of PTW Data Block ready to process by one.
           --CH3_PTW_DATA_BLOCK_CNT : in std_logic_vector(7 downto 0);            
           CH3_HOST_BLOCK_CNT_REG : out std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
           CH3_DEC_BLOCK_CNT : in std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
           CH3_PTW_RAM_DATA   : in std_logic_vector(11 downto 0);
           CH3_PTW_RAM_ADR    : out std_logic_vector(9 downto 0); 
		   --OVERFLOW_3		  : in std_logic;
           ---- To DATA Format block
           CH3_RD_EN		: in std_logic;
           CH3_PROC_OUTDAT  : out std_logic_VECTOR(31 downto 0);
           TET3             : in std_logic_VECTOR(11 downto 0);

           -- Channel 4 **********************         
           CH4_DEC_PTW_CNT : out std_logic;  --- Rising egde decrease number of PTW Data Block ready to process by one.
           --CH4_PTW_DATA_BLOCK_CNT : in std_logic_vector(7 downto 0);            
           CH4_HOST_BLOCK_CNT_REG : out std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
           CH4_DEC_BLOCK_CNT : in std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
           CH4_PTW_RAM_DATA   : in std_logic_vector(11 downto 0);
           CH4_PTW_RAM_ADR    : out std_logic_vector(9 downto 0);
		   --OVERFLOW_4		  : in std_logic;
           ---- To DATA Format block
           CH4_RD_EN		: in std_logic;
           CH4_PROC_OUTDAT  : out std_logic_VECTOR(31 downto 0);
           TET4             : in std_logic_VECTOR(11 downto 0);

           -- Channel 5 **********************        
           CH5_DEC_PTW_CNT : out std_logic;  --- Rising egde decrease number of PTW Data Block ready to process by one.
           --CH5_PTW_DATA_BLOCK_CNT : in std_logic_vector(7 downto 0);            
           CH5_HOST_BLOCK_CNT_REG : out std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for DataFormat
           CH5_DEC_BLOCK_CNT : in std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one           
           CH5_PTW_RAM_DATA   : in std_logic_vector(11 downto 0);
           CH5_PTW_RAM_ADR    : out std_logic_vector(9 downto 0); 
		   --OVERFLOW_5		  : in std_logic;
           ---- To DATA Format block
           CH5_RD_EN		: in std_logic;
           CH5_PROC_OUTDAT  : out std_logic_VECTOR(31 downto 0);
           TET5             : in std_logic_VECTOR(11 downto 0)      
        );
end PROCESSING_ALL_VER2_TOP;

architecture RTL of PROCESSING_ALL_VER2_TOP is
     
  constant MAX_WORD       : integer := 15;
  type     NSB_ARRAY   is array(0 to MAX_WORD) of std_logic_vector(11 downto 0); 
  type     NSA_ARRAY   is array(0 to MAX_WORD) of std_logic_vector(12 downto 0); 
  
  signal VCC                    : std_logic;
  signal GND                    : std_logic;
  

  signal RESET                  : std_logic;  
  signal GO_D                   : std_logic;
  signal GO_Q                   : std_logic;
  signal PROCESS_GO             : std_logic;
  signal PROCESS_GO_Q           : std_logic;
  signal PROCESS_DONE_0         : std_logic;
  signal PROCESS_DONE_1         : std_logic;
  signal PROCESS_DONE_2         : std_logic;
  signal PROCESS_DONE_3         : std_logic;
  signal PROCESS_DONE_4         : std_logic;
  signal PROCESS_DONE_5         : std_logic;

  signal DEC_PTW_CNT             : std_logic_vector(5 downto 0);

  ---- Fan out
  signal PROCESS_MODE_BUF1_D         : std_logic_vector(2 downto 0);
  
  signal PROCESS_MODE_BUF1_Q         : std_logic_vector(2 downto 0);
  signal PROCESS_MODE_BUF2_Q         : std_logic_vector(2 downto 0);
  signal PROCESS_MODE_BUF3_Q         : std_logic_vector(2 downto 0);
  signal PROCESS_MODE_BUF4_Q         : std_logic_vector(2 downto 0);
  signal PROCESS_MODE_BUF5_Q         : std_logic_vector(2 downto 0);
  signal PROCESS_MODE_BUF6_Q         : std_logic_vector(2 downto 0);
  
  signal PROCESS_GO_BUF_Q            : std_logic_vector(7 downto 0);
  signal LD_PTW_RAM_ADR_BUF_Q        : std_logic_vector(5 downto 0);
  signal ST_PTW_RAM_ADR_Q       : std_logic_vector(15 downto 0);
  signal PROCESS_DONE_0_Q         : std_logic;
  signal PROCESS_DONE_1_Q         : std_logic;
  signal PROCESS_DONE_2_Q         : std_logic;
  signal PROCESS_DONE_3_Q         : std_logic;
  signal PROCESS_DONE_4_Q         : std_logic;
  signal PROCESS_DONE_5_Q         : std_logic;

  --- Bus
  signal  CH0_PTW_RAM_ADR_NET : std_logic_vector(9 downto 0);
  signal  CH1_PTW_RAM_ADR_NET : std_logic_vector(9 downto 0);
  signal  CH2_PTW_RAM_ADR_NET : std_logic_vector(9 downto 0);
  signal  CH3_PTW_RAM_ADR_NET : std_logic_vector(9 downto 0);
  signal  CH4_PTW_RAM_ADR_NET : std_logic_vector(9 downto 0);
  signal  CH5_PTW_RAM_ADR_NET : std_logic_vector(9 downto 0);
  
  ----  Store PTW_ADR for all channel
  signal  ST_PTW_RAM_ADR       : std_logic_vector(1 downto 0);
  signal  LD_PTW_RAM_ADR       : std_logic_vector(5 downto 0);
 
  signal  CH0_SAVED_PTW_RAM_ADR_D    : std_logic_vector(9 downto 0);           
  signal  CH0_SAVED_PTW_RAM_ADR_Q    : std_logic_vector(9 downto 0);           
  signal  CH1_SAVED_PTW_RAM_ADR_D    : std_logic_vector(9 downto 0);           
  signal  CH1_SAVED_PTW_RAM_ADR_Q    : std_logic_vector(9 downto 0);           
  signal  CH2_SAVED_PTW_RAM_ADR_D    : std_logic_vector(9 downto 0);           
  signal  CH2_SAVED_PTW_RAM_ADR_Q    : std_logic_vector(9 downto 0);           
  signal  CH3_SAVED_PTW_RAM_ADR_D    : std_logic_vector(9 downto 0);           
  signal  CH3_SAVED_PTW_RAM_ADR_Q    : std_logic_vector(9 downto 0);           
  signal  CH4_SAVED_PTW_RAM_ADR_D    : std_logic_vector(9 downto 0);           
  signal  CH4_SAVED_PTW_RAM_ADR_Q    : std_logic_vector(9 downto 0);           
  signal  CH5_SAVED_PTW_RAM_ADR_D    : std_logic_vector(9 downto 0);           
  signal  CH5_SAVED_PTW_RAM_ADR_Q    : std_logic_vector(9 downto 0);

  signal DONE_PROCESS_D : std_logic;
  signal DONE_PROCESS_Q : std_logic;

  signal ModeFifoFull_NET            :  std_logic;

  ----- To make Mode 2 compatible with Mode 3 when the first four samples are above thredshold.
  signal TotFifoWrEnSM       :  std_logic;  --- Allow UTOT_dist_fifo_16_9 to be written
  signal TotFifoRstSm        :  std_logic;  --- Clear UTOT_dist_fifo_16_9  
  
  signal CH_0,CH_1,CH_2,CH_3,CH_4,CH_5	: std_logic_vector(6 downto 0);
  signal cid_Q : std_logic_vector(3 downto 0);

  component PROCESSING_TOP
        port
         (
				CLK_PROCESS          : in std_logic; 
				--CLK_HOST             : in std_logic; 
				RESET_N              : in  std_logic;
--				SOFT_RESET_N         : in std_logic;
				PTW          		: in  std_logic_vector(9 downto 0);
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
	    
	    		THRES_HI			: in std_logic_vector(8 downto 0); -- 4 sigma --int 80	--will need 6 of these!!!!!!!!!!
	    		THRES_LO			: in std_logic_vector(7 downto 0); -- 1 sigma --int 20
	
--	    		ROUGH_DT 			: in std_logic_vector(7 downto 0);   --if algo fails, return this many tenth-samples before threshold xing --int 24
--	    		INT_SAMPLE 			: in std_logic_vector(7 downto 0); -- if algo fails, start integration with this sample
	    
--	    		LIMIT_ADC_MAX 		: in std_logic_vector(15 downto 0);  -- return rough time if ADC sample exceeds this value --int 4096
--	    		LIMIT_PED_MAX 		: in std_logic_vector(15 downto 0);  -- return rough time if pedestal exceeds this --int 511
	
--	    		SET_ADC_MIN 		: in std_logic_vector(15 downto 0);  -- set min value of ADC sample subset equal to this  --int 20
--	    		LIMIT_UPS_ERR 		: in std_logic_vector(15 downto 0);  -- return midpoint time if sum of upsampling errors exceeds this --int 30	
					
				IE 					: in std_logic_vector(11 downto 0);	
				PG 					: in std_logic_vector(7 downto 0);
				--ChannelZero          : in std_logic;  -- Not to block TimeStamp word for no event for channel 0.  Tie to 1 foe Channel 0  
				MODE                 : in std_logic_vector(2 downto 0);  -- need to increase and implement 

				MAX_NUMBER_OF_PULSE  : in std_logic_vector(5 downto 0);  -- set the max number of pulse allowed per trigger
				PROCESS_GO           : in std_logic;     --- start Process a mode
				PROCESS_DONE         : out std_logic;    --- Done process a mode

				--DEC_PTW_CNT 			: out std_logic;  --- Rising egde decrease number of PTW Data Block ready to process by one.
				--PTW_DATA_BLOCK_CNT 	: in std_logic_vector(7 downto 0);  --- not use
				BLOCK_VALUE_THRESHOLD: in std_logic_VECTOR(11 downto 0); -- Mode 2 and 3. Copied NSA+NSB data and integrate when PTW_RAM_DATA = this

				HOST_BLOCK_CNT_REG 	: out std_logic_VECTOR(6 downto 0); -- number of Data Block Ready for host
				DEC_BLOCK_CNT 			: in std_logic; -- Rising edge decrease HOST_BLOCK_CNT by one

				--HOST_BLOCK_OVERFLOW : out std_logic;        
				PTW_RAM_DATA   		: in std_logic_vector(11 downto 0);
				PTW_RAM_ADR    		: out std_logic_vector(9 downto 0);    --- expects four clock delay from ADR change to DATA change 
				--OVERFLOW		    : in std_logic;

				---- From processing ALL
				LD_PTW_RAM_ADR    	: in std_logic;  --- if no multi-mode processing, tied lo
				SAVED_PTW_RAM_ADR 	: in std_logic_vector(9 downto 0);  --- if no multi-mode processing, tied lo           
			 
				---- To DATA Format block
				PR_FIFO_RD_EN			: in std_logic;	
				NEW_PROC_OUTDAT		: out std_logic_VECTOR(31 downto 0)              
        );
  end component;   

--  component PROALLSM
--        PORT (LD_PTW_RAM_ADR : OUT std_logic_vector (15 DOWNTO 0);
--                OP_MODE : IN std_logic_vector (2 DOWNTO 0);
--                ST_PTW_RAM_ADR : OUT std_logic_vector (1 DOWNTO 0);
--                ProIdle, CLK,GO,RESET_N: IN std_logic;
--                DEC_PTW_CNT : out std_logic_vector(15 downto 0);
--                GoProc,IDLE,MODE0,MODE1,TotFifoWrEnSM, TotFifoRstSm : OUT std_logic);
--  end component; 
  
 	component PROALLSM_2
        PORT (	
			CLK				: IN std_logic;	
			GO 				: IN std_logic;
			RESET_N 		: IN std_logic;
			ProIdle			: IN std_logic;
			LD_PTW_RAM_ADR 	: OUT std_logic_vector (5 DOWNTO 0);
			ST_PTW_RAM_ADR 	: OUT std_logic_vector (1 DOWNTO 0);
			DEC_PTW_CNT 	: OUT std_logic_vector(5 downto 0);
			GoProc 			: OUT std_logic;
			IDLE 			: OUT std_logic);
	end component; 
  

	
begin

--  VCC  <= '1';
--  GND  <= '0';
--  RESET <= not RESET_N;

  ---- Fan out
  ---- busses
  CH0_PTW_RAM_ADR <= CH0_PTW_RAM_ADR_NET;
  CH1_PTW_RAM_ADR <= CH1_PTW_RAM_ADR_NET;
  CH2_PTW_RAM_ADR <= CH2_PTW_RAM_ADR_NET;
  CH3_PTW_RAM_ADR <= CH3_PTW_RAM_ADR_NET;
  CH4_PTW_RAM_ADR <= CH4_PTW_RAM_ADR_NET;
  CH5_PTW_RAM_ADR <= CH5_PTW_RAM_ADR_NET;
     
  CH0_PROCESSING : PROCESSING_TOP
        port map
         (
				CLK_PROCESS            => CLK_PROCESS,           
				--CLK_HOST               => CLK_HOST,              
				RESET_N                => RESET_N,               
--				SOFT_RESET_N           => SOFT_RESET_N,
				PTW					  	=> PTW,
				--cid					   	=> cid,
				--CH					   	=> "000",
				CHANNEL_NUMBER			=> CH_0,
				
				NP						=> NP,
				NP2						=> NP2,
				
				IBIT				=> IBIT,				
				ABIT				=> ABIT,
				PBIT				=> PBIT,
				
			-- NEW REGS
--				NSAMPLES				=> NSAMPLES,
				
--	   			XTHR_SAMPLE				=> XTHR_SAMPLE,
--	    		PED_SAMPLE 				=> PED_SAMPLE,
	    
	    		THRES_HI				=> THRES_HI_0,
	    		THRES_LO				=> THRES_LO_0,
	
--	    		ROUGH_DT 				=> ROUGH_DT,
--	    		INT_SAMPLE 				=> INT_SAMPLE,
	    
--	    		LIMIT_ADC_MAX 			=> LIMIT_ADC_MAX,
--	    		LIMIT_PED_MAX 			=> LIMIT_PED_MAX,
	
--	    		SET_ADC_MIN 			=> SET_ADC_MIN,
--	    		LIMIT_UPS_ERR 			=> LIMIT_UPS_ERR,
				
				IE						=> IE,
				PG						=> PG,
				
				MODE                   => PROCESS_MODE_BUF1_Q, 
				MAX_NUMBER_OF_PULSE    => MAX_NUMBER_OF_PULSE,                 
         
				PROCESS_GO             => PROCESS_GO_BUF_Q(0),  
				PROCESS_DONE           => PROCESS_DONE_0,
            
				--DEC_PTW_CNT            => open,        
				--PTW_DATA_BLOCK_CNT     => CH0_PTW_DATA_BLOCK_CNT,    
				BLOCK_VALUE_THRESHOLD  => TET0,            
				HOST_BLOCK_CNT_REG     => CH0_HOST_BLOCK_CNT_REG,    
				DEC_BLOCK_CNT          => CH0_DEC_BLOCK_CNT,         
				PTW_RAM_DATA           => CH0_PTW_RAM_DATA,          
				PTW_RAM_ADR            => CH0_PTW_RAM_ADR_NET, 
				--OVERFLOW		  	   => OVERFLOW_0,
				
				SAVED_PTW_RAM_ADR      => CH0_SAVED_PTW_RAM_ADR_Q,
				LD_PTW_RAM_ADR         => LD_PTW_RAM_ADR_BUF_Q(0),    

				PR_FIFO_RD_EN				=> CH0_RD_EN,          
				NEW_PROC_OUTDAT        => CH0_PROC_OUTDAT                  
        );

  CH1_PROCESSING : PROCESSING_TOP
        port map
         (
				CLK_PROCESS            => CLK_PROCESS,           
				--CLK_HOST               => CLK_HOST,              
				RESET_N                => RESET_N,               
--				SOFT_RESET_N           => SOFT_RESET_N,
				PTW					  	=> PTW,
				--cid					   	=> cid,
				--CH					   	=> "001", 
				CHANNEL_NUMBER			=> CH_1,
				
				NP						=> NP,
				NP2						=> NP2,
				
				IBIT				=> IBIT,				
				ABIT				=> ABIT,
				PBIT				=> PBIT,
				
			-- NEW REGS
--				NSAMPLES				=> NSAMPLES,
				
--	   			XTHR_SAMPLE				=> XTHR_SAMPLE,
--	    		PED_SAMPLE 				=> PED_SAMPLE,
	    
	    		THRES_HI				=> THRES_HI_1,
	    		THRES_LO				=> THRES_LO_1,
	
--	    		ROUGH_DT 				=> ROUGH_DT,
--	    		INT_SAMPLE 				=> INT_SAMPLE,
	    
--	    		LIMIT_ADC_MAX 			=> LIMIT_ADC_MAX,
--	    		LIMIT_PED_MAX 			=> LIMIT_PED_MAX,
	
--	    		SET_ADC_MIN 			=> SET_ADC_MIN,
--	    		LIMIT_UPS_ERR 			=> LIMIT_UPS_ERR,
				
				IE						=> IE,
      			PG						=> PG,
				
				MODE                   => PROCESS_MODE_BUF2_Q,                  
				MAX_NUMBER_OF_PULSE    => MAX_NUMBER_OF_PULSE,                 
           
				PROCESS_GO             => PROCESS_GO_BUF_Q(1),  
				PROCESS_DONE           => PROCESS_DONE_1,
           
				--DEC_PTW_CNT            => open,           
				--PTW_DATA_BLOCK_CNT     => CH1_PTW_DATA_BLOCK_CNT,    
				BLOCK_VALUE_THRESHOLD  =>  TET1,            
				HOST_BLOCK_CNT_REG     => CH1_HOST_BLOCK_CNT_REG,    
				DEC_BLOCK_CNT          => CH1_DEC_BLOCK_CNT,         
				PTW_RAM_DATA           => CH1_PTW_RAM_DATA,          
				PTW_RAM_ADR            => CH1_PTW_RAM_ADR_NET,
				--OVERFLOW		  	   => OVERFLOW_1,
				
				SAVED_PTW_RAM_ADR      => CH1_SAVED_PTW_RAM_ADR_Q,    
				LD_PTW_RAM_ADR         => LD_PTW_RAM_ADR_BUF_Q(1),    

				PR_FIFO_RD_EN		  		=> CH1_RD_EN,              
				NEW_PROC_OUTDAT        => CH1_PROC_OUTDAT                                                     
        );

  CH2_PROCESSING : PROCESSING_TOP
        port map
         (
				CLK_PROCESS            => CLK_PROCESS,           
				--CLK_HOST               => CLK_HOST,              
				RESET_N                => RESET_N,               
--				SOFT_RESET_N           => SOFT_RESET_N,
				PTW					  	=> PTW,
				--cid					   	=> cid,
				--CH					   	=> "010", 
				CHANNEL_NUMBER			=> CH_2,
				
				NP						=> NP,
				NP2						=> NP2,
				
				IBIT				=> IBIT,				
				ABIT				=> ABIT,
				PBIT				=> PBIT,
				
			-- NEW REGS
--				NSAMPLES				=> NSAMPLES,
				
--	   			XTHR_SAMPLE				=> XTHR_SAMPLE,
--	    		PED_SAMPLE 				=> PED_SAMPLE,
	    
	    		THRES_HI				=> THRES_HI_2,
	    		THRES_LO				=> THRES_LO_2,
	
--	    		ROUGH_DT 				=> ROUGH_DT,
--	    		INT_SAMPLE 				=> INT_SAMPLE,
	    
--	    		LIMIT_ADC_MAX 			=> LIMIT_ADC_MAX,
--	    		LIMIT_PED_MAX 			=> LIMIT_PED_MAX,
	
--	    		SET_ADC_MIN 			=> SET_ADC_MIN,
--	    		LIMIT_UPS_ERR 			=> LIMIT_UPS_ERR,
				
				IE						=> IE,
     			PG						=> PG,
				
				MODE                   => PROCESS_MODE_BUF3_Q,                  
				MAX_NUMBER_OF_PULSE    => MAX_NUMBER_OF_PULSE,                 
     
				PROCESS_GO             => PROCESS_GO_BUF_Q(2),  
				PROCESS_DONE           => PROCESS_DONE_2,
            
				--DEC_PTW_CNT            => open,        
				--PTW_DATA_BLOCK_CNT     => CH2_PTW_DATA_BLOCK_CNT,    
				BLOCK_VALUE_THRESHOLD  => TET2,            
				HOST_BLOCK_CNT_REG     => CH2_HOST_BLOCK_CNT_REG,    
				DEC_BLOCK_CNT          => CH2_DEC_BLOCK_CNT,         
				PTW_RAM_DATA           => CH2_PTW_RAM_DATA,          
				PTW_RAM_ADR            => CH2_PTW_RAM_ADR_NET,
				--OVERFLOW		  	   => OVERFLOW_2,
				
				SAVED_PTW_RAM_ADR      => CH2_SAVED_PTW_RAM_ADR_Q,    
				LD_PTW_RAM_ADR         => LD_PTW_RAM_ADR_BUF_Q(2),    

				PR_FIFO_RD_EN		  		=> CH2_RD_EN,              
				NEW_PROC_OUTDAT        => CH2_PROC_OUTDAT                                                     
        );

  CH3_PROCESSING : PROCESSING_TOP
        port map
         (
				CLK_PROCESS            => CLK_PROCESS,           
				--CLK_HOST               => CLK_HOST,              
				RESET_N                => RESET_N,               
--				SOFT_RESET_N           => SOFT_RESET_N,
				PTW					  	=> PTW,
				--cid					   	=> cid,
				--CH					   	=> "011",
				CHANNEL_NUMBER			=> CH_3,
				
				NP						=> NP,
				NP2						=> NP2,
				
				IBIT				=> IBIT,				
				ABIT				=> ABIT,
				PBIT				=> PBIT,
				
			-- NEW REGS
--				NSAMPLES				=> NSAMPLES,
				
--	   			XTHR_SAMPLE				=> XTHR_SAMPLE,
--	    		PED_SAMPLE 				=> PED_SAMPLE,
	    
	    		THRES_HI				=> THRES_HI_3,
	    		THRES_LO				=> THRES_LO_3,
	
--	    		ROUGH_DT 				=> ROUGH_DT,
--	    		INT_SAMPLE 				=> INT_SAMPLE,
	    
--	    		LIMIT_ADC_MAX 			=> LIMIT_ADC_MAX,
--	    		LIMIT_PED_MAX 			=> LIMIT_PED_MAX,
	
--	    		SET_ADC_MIN 			=> SET_ADC_MIN,
--	    		LIMIT_UPS_ERR 			=> LIMIT_UPS_ERR, 
				
				IE						=> IE,
      			PG						=> PG,
				
				MODE                   => PROCESS_MODE_BUF4_Q,                  
				MAX_NUMBER_OF_PULSE    => MAX_NUMBER_OF_PULSE,                 
         
				PROCESS_GO             => PROCESS_GO_BUF_Q(3),  
				PROCESS_DONE           => PROCESS_DONE_3,
           
				--DEC_PTW_CNT            => open,           
				--PTW_DATA_BLOCK_CNT     => CH3_PTW_DATA_BLOCK_CNT,    
				BLOCK_VALUE_THRESHOLD  => TET3,            
				HOST_BLOCK_CNT_REG     => CH3_HOST_BLOCK_CNT_REG,    
				DEC_BLOCK_CNT          => CH3_DEC_BLOCK_CNT,         
				PTW_RAM_DATA           => CH3_PTW_RAM_DATA,          
				PTW_RAM_ADR            => CH3_PTW_RAM_ADR_NET,
				--OVERFLOW		  	   => OVERFLOW_3,
				
				SAVED_PTW_RAM_ADR      => CH3_SAVED_PTW_RAM_ADR_Q,    
				LD_PTW_RAM_ADR         => LD_PTW_RAM_ADR_BUF_Q(3),    

				PR_FIFO_RD_EN		  		=> CH3_RD_EN,             
				NEW_PROC_OUTDAT        => CH3_PROC_OUTDAT                                                   
        );

  CH4_PROCESSING : PROCESSING_TOP
        port map
         (
				CLK_PROCESS            => CLK_PROCESS,           
				--CLK_HOST               => CLK_HOST,              
				RESET_N                => RESET_N,               
--				SOFT_RESET_N           => SOFT_RESET_N,
				PTW					  	=> PTW,
				--cid					   	=> cid,
				--CH					   	=> "100",
				CHANNEL_NUMBER			=> CH_4,
				
				NP						=> NP,
				NP2						=> NP2,
				
				IBIT				=> IBIT,				
				ABIT				=> ABIT,
				PBIT				=> PBIT,
				
			-- NEW REGS
--				NSAMPLES				=> NSAMPLES,
				
--	   			XTHR_SAMPLE				=> XTHR_SAMPLE,
--	    		PED_SAMPLE 				=> PED_SAMPLE,
	    
	    		THRES_HI				=> THRES_HI_4,
	    		THRES_LO				=> THRES_LO_4,
	
--	    		ROUGH_DT 				=> ROUGH_DT,
--	    		INT_SAMPLE 				=> INT_SAMPLE,
	    
--	    		LIMIT_ADC_MAX 			=> LIMIT_ADC_MAX,
--	    		LIMIT_PED_MAX 			=> LIMIT_PED_MAX,
	
--	    		SET_ADC_MIN 			=> SET_ADC_MIN,
--	    		LIMIT_UPS_ERR 			=> LIMIT_UPS_ERR,
				
				IE						=> IE,
     			PG						=> PG,
				
				MODE                   => PROCESS_MODE_BUF5_Q,                  
				MAX_NUMBER_OF_PULSE    => MAX_NUMBER_OF_PULSE,                 
  
				PROCESS_GO             => PROCESS_GO_BUF_Q(4),  
				PROCESS_DONE           => PROCESS_DONE_4,
          
				--DEC_PTW_CNT            => open,           
				--PTW_DATA_BLOCK_CNT     => CH4_PTW_DATA_BLOCK_CNT,    
				BLOCK_VALUE_THRESHOLD  => TET4,            
				HOST_BLOCK_CNT_REG     => CH4_HOST_BLOCK_CNT_REG,    
				DEC_BLOCK_CNT          => CH4_DEC_BLOCK_CNT,         
				PTW_RAM_DATA           => CH4_PTW_RAM_DATA,          
				PTW_RAM_ADR            => CH4_PTW_RAM_ADR_NET,
				--OVERFLOW		  	   => OVERFLOW_4,
				
				SAVED_PTW_RAM_ADR      => CH4_SAVED_PTW_RAM_ADR_Q,    
				LD_PTW_RAM_ADR         => LD_PTW_RAM_ADR_BUF_Q(4),    

				PR_FIFO_RD_EN		  		=> CH4_RD_EN,              
				NEW_PROC_OUTDAT        => CH4_PROC_OUTDAT                                                   
        );

  CH5_PROCESSING : PROCESSING_TOP
        port map
         (
				CLK_PROCESS            => CLK_PROCESS,           
				--CLK_HOST               => CLK_HOST,              
				RESET_N                => RESET_N,               
---				SOFT_RESET_N           => SOFT_RESET_N,
				PTW					  	=> PTW,
				--cid					   	=> cid,
				--CH					   	=> "101",
				CHANNEL_NUMBER			=> CH_5,
				
				NP						=> NP,
				NP2						=> NP2,
				
				IBIT				=> IBIT,				
				ABIT				=> ABIT,
				PBIT				=> PBIT, 
				
			-- NEW REGS
--				NSAMPLES				=> NSAMPLES,
				
--	   			XTHR_SAMPLE				=> XTHR_SAMPLE,
--	    		PED_SAMPLE 				=> PED_SAMPLE,
	    
	    		THRES_HI				=> THRES_HI_5,
	    		THRES_LO				=> THRES_LO_5,
	
--	    		ROUGH_DT 				=> ROUGH_DT,
--	    		INT_SAMPLE 				=> INT_SAMPLE,
	    
--	    		LIMIT_ADC_MAX 			=> LIMIT_ADC_MAX,
--	    		LIMIT_PED_MAX 			=> LIMIT_PED_MAX,
	
--	    		SET_ADC_MIN 			=> SET_ADC_MIN,
--	    		LIMIT_UPS_ERR 			=> LIMIT_UPS_ERR, 
				
				IE						=> IE,
  				PG						=> PG,
				
				MODE                   => PROCESS_MODE_BUF6_Q,                  
				MAX_NUMBER_OF_PULSE    => MAX_NUMBER_OF_PULSE,                 
  
				PROCESS_GO             => PROCESS_GO_BUF_Q(5),  
				PROCESS_DONE           => PROCESS_DONE_5,
         
				--DEC_PTW_CNT            => open,           
				--PTW_DATA_BLOCK_CNT     => CH5_PTW_DATA_BLOCK_CNT,    
				BLOCK_VALUE_THRESHOLD  => TET5,            
				HOST_BLOCK_CNT_REG     => CH5_HOST_BLOCK_CNT_REG,    
				DEC_BLOCK_CNT          => CH5_DEC_BLOCK_CNT,         
				PTW_RAM_DATA           => CH5_PTW_RAM_DATA,          
				PTW_RAM_ADR            => CH5_PTW_RAM_ADR_NET, 
				--OVERFLOW		  	   => OVERFLOW_5,
				
				SAVED_PTW_RAM_ADR      => CH5_SAVED_PTW_RAM_ADR_Q,    
				LD_PTW_RAM_ADR         => LD_PTW_RAM_ADR_BUF_Q(5),    

				PR_FIFO_RD_EN		  		=> CH5_RD_EN,              
				NEW_PROC_OUTDAT        => CH5_PROC_OUTDAT                                                    
        );

                
    GO_D <= '1' when CH0_PTW_DATA_BLOCK_CNT > 0 else '0';

    
  ----  Store PTW_ADR for all channel
 CH0_SAVED_PTW_RAM_ADR_D <= CH0_PTW_RAM_ADR_NET when ST_PTW_RAM_ADR_Q(0) = '1' else CH0_SAVED_PTW_RAM_ADR_Q;
 CH1_SAVED_PTW_RAM_ADR_D <= CH1_PTW_RAM_ADR_NET when ST_PTW_RAM_ADR_Q(1) = '1' else CH1_SAVED_PTW_RAM_ADR_Q;
 CH2_SAVED_PTW_RAM_ADR_D <= CH2_PTW_RAM_ADR_NET when ST_PTW_RAM_ADR_Q(2) = '1' else CH2_SAVED_PTW_RAM_ADR_Q;
 CH3_SAVED_PTW_RAM_ADR_D <= CH3_PTW_RAM_ADR_NET when ST_PTW_RAM_ADR_Q(3) = '1' else CH3_SAVED_PTW_RAM_ADR_Q;
 CH4_SAVED_PTW_RAM_ADR_D <= CH4_PTW_RAM_ADR_NET when ST_PTW_RAM_ADR_Q(4) = '1' else CH4_SAVED_PTW_RAM_ADR_Q;
 CH5_SAVED_PTW_RAM_ADR_D <= CH5_PTW_RAM_ADR_NET when ST_PTW_RAM_ADR_Q(5) = '1' else CH5_SAVED_PTW_RAM_ADR_Q;

 ----- Decrease number of Trigger ready for process
 CH0_DEC_PTW_CNT <= DEC_PTW_CNT(0);
 CH1_DEC_PTW_CNT <= DEC_PTW_CNT(1);
 CH2_DEC_PTW_CNT <= DEC_PTW_CNT(2);
 CH3_DEC_PTW_CNT <= DEC_PTW_CNT(3);
 CH4_DEC_PTW_CNT <= DEC_PTW_CNT(4);
 CH5_DEC_PTW_CNT <= DEC_PTW_CNT(5);

 DONE_PROCESS_D <= PROCESS_DONE_0_Q and PROCESS_DONE_1_Q and PROCESS_DONE_2_Q and PROCESS_DONE_3_Q and PROCESS_DONE_4_Q and PROCESS_DONE_5_Q; 
 DEC_TRIG_BUFF <= DONE_PROCESS_Q;
 
	PROCESS_MODE_BUF1_D <= MODE;

		   
 	UPROALLSM : PROALLSM_2
        PORT MAP(	
			CLK				=> CLK_PROCESS,
			GO 				=> GO_Q,
			RESET_N 		=> RESET_N,
			ProIdle			=> DONE_PROCESS_Q,
			LD_PTW_RAM_ADR 	=> LD_PTW_RAM_ADR,
			ST_PTW_RAM_ADR 	=> ST_PTW_RAM_ADR,
			DEC_PTW_CNT 	=> DEC_PTW_CNT,
			GoProc 			=> PROCESS_GO,
			IDLE 			=> open
		   );

                     
    REG : process (CLK_PROCESS, RESET_N)
      begin
        if RESET_N = '0' then
           --GO_Q <= '0';
           PROCESS_GO_BUF_Q <= (others => '0');
           PROCESS_GO_Q     <= '0';
--           PROCESS_MODE_BUF1_Q <= (others => '0');
--           PROCESS_MODE_BUF2_Q <= (others => '0');
--           PROCESS_MODE_BUF3_Q <= (others => '0');
--           PROCESS_MODE_BUF4_Q <= (others => '0');
--           PROCESS_MODE_BUF5_Q <= (others => '0');
--		     PROCESS_MODE_BUF6_Q <= (others => '0');
           ST_PTW_RAM_ADR_Q         <= (others => '0'); 
--           PROCESS_DONE_0_Q         <= '0';
--           PROCESS_DONE_1_Q         <= '0';
--           PROCESS_DONE_2_Q         <= '0';
--           PROCESS_DONE_3_Q         <= '0';
--           PROCESS_DONE_4_Q         <= '0';
--           PROCESS_DONE_5_Q         <= '0';
		   
           CH0_SAVED_PTW_RAM_ADR_Q <= (others => '0');
           CH1_SAVED_PTW_RAM_ADR_Q <= (others => '0');
           CH2_SAVED_PTW_RAM_ADR_Q <= (others => '0');
           CH3_SAVED_PTW_RAM_ADR_Q <= (others => '0');
           CH4_SAVED_PTW_RAM_ADR_Q <= (others => '0');
           CH5_SAVED_PTW_RAM_ADR_Q <= (others => '0');

           DONE_PROCESS_Q <= '1'; --hack because of rising edge idle from proc

           --LD_PTW_RAM_ADR_BUF_Q <= (others => '0');
		   
        elsif rising_edge(CLK_PROCESS) then
           GO_Q <= GO_D;
           PROCESS_GO_Q     <= PROCESS_GO;
           PROCESS_GO_BUF_Q <= PROCESS_GO_Q & PROCESS_GO_Q & PROCESS_GO_Q & PROCESS_GO_Q & PROCESS_GO_Q & PROCESS_GO_Q & PROCESS_GO_Q & PROCESS_GO_Q;
           PROCESS_MODE_BUF1_Q <= PROCESS_MODE_BUF1_D;
           PROCESS_MODE_BUF2_Q <= PROCESS_MODE_BUF1_D;
           PROCESS_MODE_BUF3_Q <= PROCESS_MODE_BUF1_D;
           PROCESS_MODE_BUF4_Q <= PROCESS_MODE_BUF1_D;
           PROCESS_MODE_BUF5_Q <= PROCESS_MODE_BUF1_D;
		   PROCESS_MODE_BUF6_Q <= PROCESS_MODE_BUF1_D;
           LD_PTW_RAM_ADR_BUF_Q <= LD_PTW_RAM_ADR;
           ST_PTW_RAM_ADR_Q(0)  <=  ST_PTW_RAM_ADR(0);
           ST_PTW_RAM_ADR_Q(1)  <=  ST_PTW_RAM_ADR(0); 
           ST_PTW_RAM_ADR_Q(2)  <=  ST_PTW_RAM_ADR(0); 
           ST_PTW_RAM_ADR_Q(3)  <=  ST_PTW_RAM_ADR(0); 
           ST_PTW_RAM_ADR_Q(4)  <=  ST_PTW_RAM_ADR(0); 
           ST_PTW_RAM_ADR_Q(5)  <=  ST_PTW_RAM_ADR(0);
           
           PROCESS_DONE_0_Q         <= PROCESS_DONE_0;
           PROCESS_DONE_1_Q         <= PROCESS_DONE_1;
           PROCESS_DONE_2_Q         <= PROCESS_DONE_2;
           PROCESS_DONE_3_Q         <= PROCESS_DONE_3;
           PROCESS_DONE_4_Q         <= PROCESS_DONE_4;
           PROCESS_DONE_5_Q         <= PROCESS_DONE_5;

           CH0_SAVED_PTW_RAM_ADR_Q <= CH0_SAVED_PTW_RAM_ADR_D;
           CH1_SAVED_PTW_RAM_ADR_Q <= CH1_SAVED_PTW_RAM_ADR_D;
           CH2_SAVED_PTW_RAM_ADR_Q <= CH2_SAVED_PTW_RAM_ADR_D;
           CH3_SAVED_PTW_RAM_ADR_Q <= CH3_SAVED_PTW_RAM_ADR_D;
           CH4_SAVED_PTW_RAM_ADR_Q <= CH4_SAVED_PTW_RAM_ADR_D;
           CH5_SAVED_PTW_RAM_ADR_Q <= CH5_SAVED_PTW_RAM_ADR_D;

           DONE_PROCESS_Q <= DONE_PROCESS_D; 
		   
		   cid_Q <= cid;

         end if;
      end process REG;
 
	  
	CH_0 <= "0000000" when cid_Q = "0000" else -- 0 chip 0 main
			"0000110" when cid_Q = "0001" else -- 6 chip 1 main
			"0001100" when cid_Q = "0010" else -- 12 chip 2 mezz						
			"0010010" when cid_Q = "0011" else -- 18 chip 3 mezz
			"0011000" when cid_Q = "0100" else -- 24 chip 4 main
			"0011110" when cid_Q = "0101" else -- 30 chip 5 main
			"0100100" when cid_Q = "0110" else -- 36 chip 6 mezz
			"0101010" when cid_Q = "0111" else -- 42 chip 7 mezz
			"0110000" when cid_Q = "1000" else -- 48 chip 8 main
			"0110110" when cid_Q = "1001" else -- 54 chip 9 main
			"0111100" when cid_Q = "1010" else -- 60 chip 10 mezz
			"1000010" when cid_Q = "1011"  -- 66 chip 11 mezz
			else (others => '0');

	CH_1 <= "0000001" when cid_Q = "0000" else -- 1
			"0000111" when cid_Q = "0001" else -- 7
			"0001101" when cid_Q = "0010" else -- 13
			"0010011" when cid_Q = "0011" else -- 19
			"0011001" when cid_Q = "0100" else -- 25
			"0011111" when cid_Q = "0101" else -- 31
			"0100101" when cid_Q = "0110" else -- 37
			"0101011" when cid_Q = "0111" else -- 43
			"0110001" when cid_Q = "1000" else -- 49
			"0110111" when cid_Q = "1001" else -- 55
			"0111101" when cid_Q = "1010" else -- 61
			"1000011" when cid_Q = "1011"  -- 67
			else (others => '0');

	CH_2 <= "0000010" when cid_Q = "0000" else -- 2
			"0001000" when cid_Q = "0001" else -- 8
			"0001110" when cid_Q = "0010" else -- 14
			"0010100" when cid_Q = "0011" else -- 20
			"0011010" when cid_Q = "0100" else -- 26
			"0100000" when cid_Q = "0101" else -- 32
			"0100110" when cid_Q = "0110" else -- 38
			"0101100" when cid_Q = "0111" else -- 44
			"0110010" when cid_Q = "1000" else -- 50
			"0111000" when cid_Q = "1001" else -- 56
			"0111110" when cid_Q = "1010" else -- 62
			"1000100" when cid_Q = "1011"  -- 68
			else (others => '0');	

	CH_3 <= "0000011" when cid_Q = "0000" else -- 3
			"0001001" when cid_Q = "0001" else -- 9
			"0001111" when cid_Q = "0010" else -- 15
			"0010101" when cid_Q = "0011" else -- 21
			"0011011" when cid_Q = "0100" else -- 27
			"0100001" when cid_Q = "0101" else -- 33
			"0100111" when cid_Q = "0110" else -- 39
			"0101101" when cid_Q = "0111" else -- 45 
			"0110011" when cid_Q = "1000" else -- 51
			"0111001" when cid_Q = "1001" else -- 57
			"0111111" when cid_Q = "1010" else -- 63
			"1000101" when cid_Q = "1011"  -- 69
			else (others => '0');	

	CH_4 <= "0000100" when cid_Q = "0000" else -- 4
			"0001010" when cid_Q = "0001" else -- 10
			"0010000" when cid_Q = "0010" else -- 16
			"0010110" when cid_Q = "0011" else -- 22
			"0011100" when cid_Q = "0100" else -- 28
			"0100010" when cid_Q = "0101" else -- 34
			"0101000" when cid_Q = "0110" else -- 40
			"0101110" when cid_Q = "0111" else -- 46
			"0110100" when cid_Q = "1000" else -- 52
			"0111010" when cid_Q = "1001" else -- 58  
			"1000000" when cid_Q = "1010" else -- 64
			"1000110" when cid_Q = "1011"  -- 70
			else (others => '0');	
				
	CH_5 <= "0000101" when cid_Q = "0000" else -- 5
			"0001011" when cid_Q = "0001" else -- 11
			"0010001" when cid_Q = "0010" else -- 17
			"0010111" when cid_Q = "0011" else -- 23
			"0011101" when cid_Q = "0100" else -- 29
			"0100011" when cid_Q = "0101" else -- 35
			"0101001" when cid_Q = "0110" else -- 41
			"0101111" when cid_Q = "0111" else -- 47
			"0110101" when cid_Q = "1000" else -- 53
			"0111011" when cid_Q = "1001" else -- 59
			"1000001" when cid_Q = "1010" else -- 65
			"1000111" when cid_Q = "1011"  -- 71
			else (others => '0');
	  
end RTL;
