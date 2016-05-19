--  Author:  Cody Dickover
--  Filename: NEW_DATAFORMAT_TOP.vhd 
--  Date: 3/10/15
--

-- Complete RE-WRITE of 250 data format section
-- Processed data is now read from a FIFO instead of dual port RAM  
-- The event header/trigger number/time stamp data comes directly from the new data buffer and is no longer unique to the channel
-- Removed all signals relating to proccessor ram addresses and muxed data format 
-- The actual "data format" now occurs in the processing section and the output is 32 bit instead of 18
-- This code now simply orginizes the channels and tags for the storage in the output FIFO

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_unsigned.all; 
  use IEEE.std_logic_arith.all;
  use IEEE.numeric_std.all;

library unisim;
   use unisim.vcomponents.all;

entity NEW_DATAFORMAT_TOP is
        port
         (
           CLK_HOST             : in std_logic; 
           RESET_N              : in  std_logic;
--           SOFT_RESET_N         : in std_logic;

--           MODE : in std_logic_vector(2 downto 0); -- still need just for tags
		   --HEADER DATA FROM DATA BUFFER SECTION
           HeaderFifoRdEn          		: out std_logic; --- Read UFIFO18_header TrigIn, Trigger Number, Time Stamp, and Latched Address of RawDataBuffer
           HeaderFifoHasData_REG   		: in std_logic; --- 1 indicate UFIFO18_header has data 
           HeaderFifoData_REG      		: in std_logic_vector(15 downto 0);
		   
           ---- To Data Processing block
--           ModeFifoRdEn   : out std_logic;
--           ModeFifoDout   : in std_logic_VECTOR(1 downto 0);
--           ModeFifoEmpty  : in std_logic;

           PROC0_RD_EN   : out std_logic;
           PROC0_OUTDAT  : in std_logic_VECTOR(31 downto 0);
		   PROC1_RD_EN   : out std_logic;
           PROC1_OUTDAT  : in std_logic_VECTOR(31 downto 0);
		   PROC2_RD_EN   : out std_logic;
           PROC2_OUTDAT  : in std_logic_VECTOR(31 downto 0);
		   PROC3_RD_EN   : out std_logic;
           PROC3_OUTDAT  : in std_logic_VECTOR(31 downto 0);
		   PROC4_RD_EN   : out std_logic;
           PROC4_OUTDAT  : in std_logic_VECTOR(31 downto 0);
		   PROC5_RD_EN   : out std_logic;
           PROC5_OUTDAT  : in std_logic_VECTOR(31 downto 0);

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

           --- To Host FIFO IDT72V36100 pins
		   cid						 : in  std_logic_vector(3 downto 0);
           DATA_REG                  : out std_logic_vector(31 downto 0); 
           WEN_REG                   : out std_logic -- Write EN
        );
end NEW_DATAFORMAT_TOP;

architecture RTL of NEW_DATAFORMAT_TOP is
	
--	signal EVENT_HEADER_UPPER  : std_logic_vector(35 downto 32);
--	signal DATA_WORD_UPPER     : std_logic_vector(35 downto 32);
	signal EVENT_TRAILER       : std_logic_vector(31 downto 0);
	
	---- Indicate there is data to write to FIFO

	signal CH0_HAS_DAT_D,CH1_HAS_DAT_D,CH2_HAS_DAT_D,CH3_HAS_DAT_D,CH4_HAS_DAT_D,CH5_HAS_DAT_D : std_logic := '0'; 
	signal CH0_HAS_DAT_Q,CH1_HAS_DAT_Q,CH2_HAS_DAT_Q,CH3_HAS_DAT_Q,CH4_HAS_DAT_Q,CH5_HAS_DAT_Q : std_logic := '0';  

	signal GO_D : std_logic := '0';
	signal GO_Q : std_logic := '0';

	---- Keep track of channel
	signal CH_SEL_D : std_logic_vector(4 downto 0);
	signal CH_SEL_Q : std_logic_vector(4 downto 0);
	signal LAST_CHANNEL_D : std_logic;
	signal LAST_CHANNEL_Q : std_logic;
--	signal FIRST_CHANNEL_D : std_logic;
--	signal FIRST_CHANNEL_Q : std_logic;
	signal INC_CH_SEL : std_logic;
	signal CLR_CH_SEL : std_logic;  
	
	--- If there is no pulses
	signal NO_PULSE_D : std_logic;  --- there is event to write to FIFO
--	signal NO_PULSE_Q : std_logic;  --- there is event to write to FIFO
	
	signal PROCESS_DATA_D : std_logic_vector(31 downto 0);
	signal PROCESS_DATA_Q : std_logic_vector(31 downto 0);
	
	signal WD_HIGH_HACK : std_logic_vector(3 downto 0);
	
	---- FIFO Data Format
	--signal LD_PULSE_NUMBER     : std_logic; -- mode 02 (integral)
	signal PULSE_NUMBER_D      : std_logic_vector(1 downto 0);
	signal PULSE_NUMBER_Q      : std_logic_vector(1 downto 0);
	signal EVENT_HEADER        : std_logic_vector(31 downto 0);
	
	signal FIFO_DATA_D              : std_logic_vector(31 downto 0);
	signal FIFO_DATA_Q              : std_logic_vector(31 downto 0);
--	signal FIFO_DATA_BUF_D              : std_logic_vector(35 downto 0);
--	signal FIFO_DATA_BUF_Q              : std_logic_vector(35 downto 0);

  ---- Fifo write en
	signal FIFO_WEN : std_logic := '0';
	signal FIFO_WE_N_D : std_logic;
	signal FIFO_WE_N_Q : std_logic;
	signal FIFO_WE_BUF_N_D : std_logic;
	signal FIFO_WE_BUF_N_Q : std_logic;
	
	signal ODD_DATA_WORDS_D : std_logic;
	signal ODD_DATA_WORDS_Q : std_logic;
	
	signal DEC_BLOCK : std_logic;
	signal DEC_BLOCK_BUF_D : std_logic_vector(15 downto 0);
	signal DEC_BLOCK_BUF_Q : std_logic_vector(15 downto 0);
	
--	signal CHANNEL_NUMBER	: std_logic_vector(6 downto 0);
  
	component DATFORSM_2 
		PORT (
		CLK,
		GO,
		--GO_FIRST,GO_OTHER,
		--FIRST_CHIP,
		LAST_CHANNEL,
		PR_TRAILER,
		RESET_N: IN std_logic;
		CLR_CH_SEL,
		DEC_BLOCK_CNT,
		FIFO_WEN,
		FIFO_WEN_H,
		HEADER_RD_EN,
		SEL_TRG_NUM,
		SEL_TS_1,
		SEL_TS_2,
		SEL_TS_3,
		SEL_TS_BOT,
		SEL_TS_TOP,
		SEL_PROC_DATA,
		INC_CH_SEL,
		INS_CHIP_TRAIL,
		--FIFO_WEN_T,
		PR_FIFO_RD_EN : OUT std_logic);
	end component; 
	
	signal PR_TRAILER, FIFO_WEN_H, INS_CHIP_TRAIL, PR_FIFO_RD_EN, DEC_BLOCK_CNT : std_logic;
	signal HEADER_RD_EN, SEL_TRG_NUM, SEL_PROC_DATA : std_logic;  --FIFO_WEN_T
	signal SEL_TS_1, SEL_TS_2, SEL_TS_3, SEL_TS_BOT, SEL_TS_TOP : std_logic;
	
	signal TIME_STAMP_1_D, TIME_STAMP_2_D, TIME_STAMP_3_D : std_logic_vector(15 downto 0);
	signal TIME_STAMP_1_Q, TIME_STAMP_2_Q, TIME_STAMP_3_Q : std_logic_vector(15 downto 0); 
	
	signal TIME_STAMP_TOP, TIME_STAMP_BOT: std_logic_vector(31 downto 0); 
	
--	signal TIME_STAMP_TOP_D, TIME_STAMP_TOP_Q: std_logic_vector(31 downto 0); 
--	signal TIME_STAMP_BOT_D, TIME_STAMP_BOT_Q: std_logic_vector(31 downto 0); 
	
	signal FIRST_CHIP : std_logic;
	--signal GO_FIRST,GO_OTHER : std_logic;
	signal FIFO_WEN_D,FIFO_WEN_Q,FIFO_WEN_P : std_logic;
  
begin

    --- Start Write to FIFO when there is data
    CH0_HAS_DAT_D <= '0' when HOST_BLOCK0_CNT = "0000000"  else '1'; 
    CH1_HAS_DAT_D <= '0' when HOST_BLOCK1_CNT = "0000000"  else '1'; 
    CH2_HAS_DAT_D <= '0' when HOST_BLOCK2_CNT = "0000000"  else '1'; 
    CH3_HAS_DAT_D <= '0' when HOST_BLOCK3_CNT = "0000000"  else '1'; 
    CH4_HAS_DAT_D <= '0' when HOST_BLOCK4_CNT = "0000000"  else '1'; 
    CH5_HAS_DAT_D <= '0' when HOST_BLOCK5_CNT = "0000000"  else '1'; 

    GO_D <= CH0_HAS_DAT_Q and CH1_HAS_DAT_Q and CH2_HAS_DAT_Q  and CH3_HAS_DAT_Q  and CH4_HAS_DAT_Q  and CH5_HAS_DAT_Q;	
	--GO_D <= '1' when (CH0_HAS_DAT_Q = '1' and CH1_HAS_DAT_Q = '1' and CH2_HAS_DAT_Q = '1' and CH3_HAS_DAT_Q = '1' and CH4_HAS_DAT_Q = '1' and CH5_HAS_DAT_Q = '1') else '0';
	
	--GO_FIRST <= GO_Q and FIRST_CHIP;
	--GO_OTHER <= GO_Q and not FIRST_CHIP;
	
	FIRST_CHIP <= '1' when cid = X"0" else '0';
	--FIRST_CHIP <= '0';
  ---- The Channel Number being written to FIFO
	CH_SEL_D <= CH_SEL_Q + 1    when INC_CH_SEL = '1' else
				(others => '0') when CLR_CH_SEL = '1' else 
				CH_SEL_Q; 
				
--	FIRST_CHANNEL_D <= '1' when  CH_SEL_Q = "00000" else '0';	
	LAST_CHANNEL_D <= '1'   when CH_SEL_Q = "00101" else '0';
		
---- Handle Process data
	PROCESS_DATA_D <= PROC0_OUTDAT  when CH_SEL_Q(3 downto 0) = "0000" else
	                  PROC1_OUTDAT  when CH_SEL_Q(3 downto 0) = "0001" else
	                  PROC2_OUTDAT  when CH_SEL_Q(3 downto 0) = "0010" else
	                  PROC3_OUTDAT  when CH_SEL_Q(3 downto 0) = "0011" else
	                  PROC4_OUTDAT  when CH_SEL_Q(3 downto 0) = "0100" else
	                  PROC5_OUTDAT; 
		
	PR_TRAILER <= '1' when  PROCESS_DATA_D = X"FFFFFFFF" else '0';

	uDATFORSM_2 : DATFORSM_2 
		PORT MAP(
			CLK 			=> CLK_HOST,
			GO				=> GO_Q, 
			--GO_FIRST		=> GO_FIRST,
			--GO_OTHER		=> GO_OTHER,
			--FIRST_CHIP		=> FIRST_CHIP,
			LAST_CHANNEL 	=> LAST_CHANNEL_Q,
			PR_TRAILER 		=> PR_TRAILER,
			RESET_N 		=> RESET_N,
			CLR_CH_SEL 		=> CLR_CH_SEL,
			DEC_BLOCK_CNT 	=> DEC_BLOCK_CNT,
			FIFO_WEN 		=> FIFO_WEN,
			FIFO_WEN_H 		=> FIFO_WEN_H,
			--FIFO_WEN_T 		=> FIFO_WEN_T,
			HEADER_RD_EN 	=> HEADER_RD_EN,
			SEL_TRG_NUM 	=> SEL_TRG_NUM, 
			SEL_TS_1 		=> SEL_TS_1,
			SEL_TS_2 		=> SEL_TS_2,
			SEL_TS_3 		=> SEL_TS_3,
			SEL_TS_BOT 		=> SEL_TS_BOT,
			SEL_TS_TOP 		=> SEL_TS_TOP,
			SEL_PROC_DATA	=> SEL_PROC_DATA,
			INC_CH_SEL 		=> INC_CH_SEL,
			INS_CHIP_TRAIL 	=> INS_CHIP_TRAIL,
			PR_FIFO_RD_EN 	=> PR_FIFO_RD_EN
		);	

	HeaderFifoRdEn <= HEADER_RD_EN;
		
    ----- One block written out
    DEC_BLOCK0_CNT <= '1' when (CH_SEL_Q(3 downto 0) = "0000" and DEC_BLOCK_CNT = '1') else '0';
    DEC_BLOCK1_CNT <= '1' when (CH_SEL_Q(3 downto 0) = "0001" and DEC_BLOCK_CNT = '1') else '0';
    DEC_BLOCK2_CNT <= '1' when (CH_SEL_Q(3 downto 0) = "0010" and DEC_BLOCK_CNT = '1') else '0';
    DEC_BLOCK3_CNT <= '1' when (CH_SEL_Q(3 downto 0) = "0011" and DEC_BLOCK_CNT = '1') else '0';
    DEC_BLOCK4_CNT <= '1' when (CH_SEL_Q(3 downto 0) = "0100" and DEC_BLOCK_CNT = '1') else '0';
    DEC_BLOCK5_CNT <= '1' when (CH_SEL_Q(3 downto 0) = "0101" and DEC_BLOCK_CNT = '1') else '0';
	
---- Handle Read Enables 
	PROC0_RD_EN <= '1' when (CH_SEL_Q(3 downto 0) = "0000" and PR_FIFO_RD_EN = '1') else '0';
	PROC1_RD_EN <= '1' when (CH_SEL_Q(3 downto 0) = "0001" and PR_FIFO_RD_EN = '1') else '0';
	PROC2_RD_EN <= '1' when (CH_SEL_Q(3 downto 0) = "0010" and PR_FIFO_RD_EN = '1') else '0';
	PROC3_RD_EN <= '1' when (CH_SEL_Q(3 downto 0) = "0011" and PR_FIFO_RD_EN = '1') else '0';
	PROC4_RD_EN <= '1' when (CH_SEL_Q(3 downto 0) = "0100" and PR_FIFO_RD_EN = '1') else '0';
	PROC5_RD_EN <= '1' when (CH_SEL_Q(3 downto 0) = "0101" and PR_FIFO_RD_EN = '1') else '0';

   --- BACK END FIFO WRITE ENABLE
	
--	FIFO_WEN_D <= FIFO_WEN;
--	FIFO_WEN_P <= FIFO_WEN_D and not FIFO_WEN_Q;
--   WEN_REG <= '1' when ((FIFO_WEN_H = '1' and FIRST_CHIP = '1') or FIFO_WEN_P = '1' or FIFO_WEN_T = '1') 	else -- CHANGE (and FIRST_CHIP = '1') FIFO_WEN_P
--              '0';  

	FIFO_WEN_D <= '1' when ((FIFO_WEN_H = '1' and FIRST_CHIP = '1') or FIFO_WEN = '1') else '0';-- CHANGE (and FIRST_CHIP = '1') FIFO_WEN_P - or FIFO_WEN_T = '1')
	
	WEN_REG <= FIFO_WEN_Q;  		   
	DATA_REG  <= FIFO_DATA_Q; --FIFO_DATA_D; --FIFO_DATA_BUF_Q;                   
              
   ---- Data to external FIFO 
--   EVENT_HEADER_UPPER <= "0001";
   EVENT_HEADER <= X"9000" & HeaderFifoData_REG;

--   DATA_WORD_UPPER    <= "0000"; -- will mux in on proc 
   
   TIME_STAMP_1_D <= HeaderFifoData_REG when SEL_TS_1 = '1' else TIME_STAMP_1_Q;
   TIME_STAMP_2_D <= HeaderFifoData_REG when SEL_TS_2 = '1' else TIME_STAMP_2_Q;
   TIME_STAMP_3_D <= HeaderFifoData_REG when SEL_TS_3 = '1' else TIME_STAMP_3_Q;
  
   TIME_STAMP_TOP <= X"98" & TIME_STAMP_1_Q & TIME_STAMP_2_Q(15 downto 8); -- when SEL_TS_TOP = '1' else TIME_STAMP_TOP_Q;  
   TIME_STAMP_BOT <= X"00" & TIME_STAMP_2_Q(7 downto 0) & TIME_STAMP_3_Q; -- when SEL_TS_BOT = '1' else TIME_STAMP_BOT_Q;


--   EVENT_TRAILER <= "0010" & X"E8000000"; -- will mux in on vme 
   EVENT_TRAILER <= X"E8000000";

---- Handel MUX to daisy chain FIFO and TAGS -- CHANGE : will add tags on proc					  
--   FIFO_DATA_D   <= EVENT_HEADER_UPPER & EVENT_HEADER	when SEL_TRG_NUM = '1' 	 else
--   					DATA_WORD_UPPER & TIME_STAMP_BOT  	when SEL_TS_BOT = '1' 	 else
--	   			    DATA_WORD_UPPER & TIME_STAMP_TOP  	when SEL_TS_TOP = '1' 	 else
--                    DATA_WORD_UPPER & PROCESS_DATA_D  	when SEL_PROC_DATA = '1' else
--                    EVENT_TRAILER    				  	when INS_CHIP_TRAIL= '1' else
--                    X"000000000";	
					
	FIFO_DATA_D   <= EVENT_HEADER		when SEL_TRG_NUM = '1' 	 else 
	   			    TIME_STAMP_TOP  	when SEL_TS_TOP = '1' 	 else
   					TIME_STAMP_BOT  	when SEL_TS_BOT = '1' 	 else
                    PROCESS_DATA_Q  	when SEL_PROC_DATA = '1' else
                    EVENT_TRAILER    	when INS_CHIP_TRAIL= '1' else
					FIFO_DATA_Q;	
                    --X"00000000";	--change


    process (CLK_HOST, RESET_N)
      begin
        if RESET_N = '0' then

          CH0_HAS_DAT_Q   <= '0';
          CH1_HAS_DAT_Q   <= '0';
          CH2_HAS_DAT_Q   <= '0';
          CH3_HAS_DAT_Q   <= '0';
          CH4_HAS_DAT_Q   <= '0';
          CH5_HAS_DAT_Q   <= '0';

--          NO_PULSE_Q <= '0';
          --LAST_CHANNEL_Q    <= '0';
          CH_SEL_Q        <= (others => '0');
          --Proc_Adr1_Q <= (others => '0');
          --FIFO_WE_N_Q <= '1';
          --FIFO_WE_BUF_N_Q <= '1';

          FIFO_DATA_Q <= (others => '0'); --CHANGE (reset problem?)
 
          --DEC_BLOCK_BUF_Q <= (others => '0');
          GO_Q <= '0';
          --PROCESS_DATA_Q <= (others => '0');
		  
		  TIME_STAMP_1_Q <=	(others => '0');
		  TIME_STAMP_2_Q <=	(others => '0');
		  TIME_STAMP_3_Q <= (others => '0');
		  
--		  TIME_STAMP_TOP_Q <= (others => '0');
--		  TIME_STAMP_BOT_Q <= (others => '0');
          
        elsif (CLK_HOST = '1' and CLK_HOST'event) then
			
          CH0_HAS_DAT_Q   <= CH0_HAS_DAT_D;
          CH1_HAS_DAT_Q   <= CH1_HAS_DAT_D;
          CH2_HAS_DAT_Q   <= CH2_HAS_DAT_D;
          CH3_HAS_DAT_Q   <= CH3_HAS_DAT_D;
          CH4_HAS_DAT_Q   <= CH4_HAS_DAT_D;
          CH5_HAS_DAT_Q   <= CH5_HAS_DAT_D;

          LAST_CHANNEL_Q    <= LAST_CHANNEL_D;
          CH_SEL_Q        <= CH_SEL_D;
			-- CHANNEL_NUMBER_Q <= CHANNEL_NUMBER_D;

          --Proc_Adr1_Q <= Proc_Adr1_D;
          --FIFO_WE_N_Q <= FIFO_WE_N_D;
          --FIFO_WE_BUF_N_Q <= FIFO_WE_BUF_N_D;

          FIFO_DATA_Q <= FIFO_DATA_D;

		  --DEC_BLOCK_BUF_Q <= DEC_BLOCK_BUF_D;
          GO_Q <= GO_D;
          PROCESS_DATA_Q <= PROCESS_DATA_D;
		  
		  TIME_STAMP_1_Q <=	TIME_STAMP_1_D;
		  TIME_STAMP_2_Q <=	TIME_STAMP_2_D;
		  TIME_STAMP_3_Q <= TIME_STAMP_3_D;
		  
--		  TIME_STAMP_TOP_Q <= TIME_STAMP_TOP_D;
--		  TIME_STAMP_BOT_Q <= TIME_STAMP_BOT_D;
			
			FIFO_WEN_Q <= FIFO_WEN_D;
		  
         end if;
      end process;

  -----------------------------------------------------------------------------------------


        
end RTL;

