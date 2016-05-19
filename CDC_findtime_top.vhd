

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_unsigned.all; 
  use IEEE.std_logic_arith.all;
 
library work;
    use work.package_EFACV2.all; 

library unisim;
	use unisim.all;         
	use UNISIM.vcomponents.all;	

entity CDC_findtime_top is
       port
         (
			clk					: in  STD_LOGIC;
			RESET_N            	: in std_logic;
			--PTW          		: in std_logic_vector(9 downto 0);
			MAX_NUMBER_PEAKS	: in std_logic_vector(5 downto 0);
      
			le_time  			: out std_logic_vector (10 downto 0); -- leading edge time found
			ft_q_code			: out std_logic;  -- quality code, 0 is good
--			FIRST_MAX 			: out std_logic_vector(31 downto 0);
			ft_overflow_TOTAL	: out std_logic_vector(2 downto 0);
			SUM_TOTAL 			: out std_logic_vector(31 downto 0) := X"00000000";
			
			PEAK_NUMBER_out		: out std_logic_vector(4 downto 0); --integer range 0 to 511;
			FINAL_MAX_time_out 	: out std_logic_vector(11 downto 0);
			FINAL_MAX_out 		: out std_logic_vector(31 downto 0) := X"00000000";
			
			DEC_PEAK_CNT	    : in std_logic;
			--CLR_PEAK_CNT		: in std_logic;
			PEAK_WRITE_DONE		: out std_logic;
			
			TDC_GO             	: in  std_logic; --- Rising edge start TDC algorith
			ft_done 			: out std_logic; -- "done"using mem 

			PTW_RAM_DATA        : in std_logic_vector(11 downto 0);
			--OVERFLOW			: in std_logic;
			
			-- NEW REGS
--			NSAMPLES			: in std_logic_vector(7 downto 0);   -- max number of ADC samples to read in   --int 16
			
--	   		XTHR_SAMPLE			: in std_logic_vector(7 downto 0); -- the 5 sigma thres xing is sample[9] passed into the algo, starting with sample[0]
--    		PED_SAMPLE 			: in std_logic_vector(7 downto 0); -- take local ped as sample[5]
    
    		THRES_HI			: in std_logic_vector(8 downto 0); -- 4 sigma --int 80
    		THRES_LO			: in std_logic_vector(7 downto 0); -- 1 sigma --int 20

--    		ROUGH_DT 			: in std_logic_vector(7 downto 0);   --if algo fails, return this many tenth-samples before threshold xing --int 24
--    		INT_SAMPLE 			: in std_logic_vector(7 downto 0); -- if algo fails, start integration with this sample
    
--    		LIMIT_ADC_MAX 		: in std_logic_vector(15 downto 0);  -- return rough time if ADC sample exceeds this value --int 4096
--    		LIMIT_PED_MAX 		: in std_logic_vector(15 downto 0);  -- return rough time if pedestal exceeds this --int 511

--    		SET_ADC_MIN 		: in std_logic_vector(15 downto 0);  -- set min value of ADC sample subset equal to this  --int 20
--    		LIMIT_UPS_ERR 		: in std_logic_vector(15 downto 0);  -- return midpoint time if sum of upsampling errors exceeds this --int 30	
				
			IE 					: in std_logic_vector(11 downto 0);	
			PG 					: in std_logic_vector(7 downto 0);
			
			-- NEW SIGNALS FOR CDC/FDC
			--RT_PTW_PTR_TDC      : out std_logic;   --- restore saved data buffer current address
			INC_PTW_PTR_TDC     : out std_logic;   --- inc RD_PTW_PTR_Q	  
			WE_DONE				: in std_logic;
			PTW_DONE			: in std_logic;
			
			CLR_COUNTS			: out std_logic;
			RT_PTW_PTR_LS		: out std_logic;
			
			le_sample 			: out std_logic_vector (4 downto 0); -- sample containing leading edge 
			le_sample_found_out		: out std_logic;
			FT_START_FROM_LS	: in std_logic;
			
			FT_START_FROM_NU	: in std_logic
			--FT_START_FROM_TC  	: in std_logic        
		   );
end CDC_findtime_top;

architecture Behavior of CDC_findtime_top is

 	component NEWfindtime -- 
			 Port ( 
			 		clk 			: in  STD_LOGIC; 
			 		--RESET_N			: in  STD_LOGIC; 
					go 				: in  STD_LOGIC; -- the leading edge search process starts 1 clock sample after go is high
					adc 			: in std_logic_vector (11 downto 0); --change!         
					busy 			: out std_logic;          -- busy when 1 and finished when 0         
					le_sample 		: out std_logic_vector (4 downto 0); -- sample containing leading edge
					le_sample_found	: out std_logic; -- signal to acknowledge that le_sample was found, I.E. can be determined, and that SUMing can start
					le_time 		: out std_logic_vector (7 downto 0); -- leading edge time found (only need 8 bits) 
					
		    		THRES_HI		: in integer; --std_logic_vector(15 downto 0) := X"0050"; -- 4 sigma --int 80
		    		THRES_LO		: in integer; --std_logic_vector(15 downto 0) := X"0014"; -- 1 sigma --int 20 
					PG				: in integer;
					
					q_code			: out std_logic  -- quality code, 0 is good
					);
	end component;

	
	signal ft_give, ft_give_Q, ft_busy, ft_load_done, ft_load_samples, NO_GO, ft_done_Q	: STD_logic := '0'; --ft_q_code
	signal SM_ft_done : std_logic;
	signal ft_le_time 					: std_logic_vector (7 downto 0); -- changed to 8 bits in new findtime 
	signal ft_adc_D ,ft_adc_Q			: std_logic_vector(11 downto 0);
	signal ft_adc_2D, ft_adc_2Q 		: std_logic_vector(11 downto 0);
	signal ft_integ 	 				: std_logic_vector (14 downto 0);
	
	signal LE_SAMPLE_FOUND, LE_SAMPLE_FOUND_Q	: std_logic;
	
component FINDTIME_SM_5
	PORT (	
			CLK,
			BUSY,
			GO,
			load_done,
			RESET_N, 

			LE_SAMPLE_FOUND,
			FT_START_FROM_LS, 
			
			FT_START_FROM_NU,
			--FT_START_FROM_TC,
			MAX_FOUND,
			CHECK_MAX_FOUND,
			--CHECK_MAX_FOUND2,
			SLOPE_FOUND,
			TROUGH_FOUND,
			PEAK_DONE,
			WE_DONE, 
			JUST_WE,
			PTW_DONE  
			: IN std_logic;

			CLR_COUNTS,
			RT_PTW_PTR_LS, 
			
			ft_give,
			INC_PTW_PTR_TDC,
			COUNT_SAMPLES,
			load_samples,
			SUM_FROM_TC_GO,
			CLEAR_SUM,
			ft_done,
			SLOPE_CHECK,
			FIND_MAX_GO,
			CHECK_MAX_GO,
			--CHECK_MAX_GO_2,
			--INC_PEAK_CNT,
			FIND_TROUGH_GO,
			STORE_MAX
			--RT_PTW_PTR_TDC 
			: OUT std_logic
		  );
END component; 
	
  	--constant NSAMPLES : integer := 15;   -- max number of ADC samples to read in
	signal load_count_D,load_count_Q : integer range 0 to 4096 := 0;
	
	signal tc_integ_D, tc_integ_Q : std_logic_vector(31 downto 0);
    signal TC_SUM_D, TC_SUM_Q : std_logic_vector(31 downto 0); -- := X"00000000"

	signal SUM_FROM_TC_GO, CLEAR_SUM : std_logic; 
	
	--signal SUM_TOTAL_D, SUM_TOTAL_Q : std_logic_vector(31 downto 0);
	signal SLOPE_CHECK,SLOPE_FOUND : std_logic;
	signal FIND_MAX_GO, CHECK_MAX_GO, MAX_FOUND, CHECK_MAX_FOUND, STORE_MAX, COUNT_SAMPLES : std_logic;
	signal FIND_TROUGH_GO, TROUGH_FOUND	: std_logic; 
	signal sample_number_D, sample_number_Q	: std_logic_vector(11 downto 0);
	
	signal MAX_time_CHECK_D, MAX_time_CHECK_Q : std_logic_vector(11 downto 0); --:= X"000"
	--signal FIRST_MAX_time : std_logic_vector(11 downto 0) := X"000"; 
	signal FINAL_MAX_time : std_logic_vector(11 downto 0); --:= X"000"
	
	signal MAX_CHECK_D, MAX_CHECK_Q : std_logic_vector(31 downto 0); -- := X"00000000"
	signal SECOND_MAX, THIRD_MAX, FOURTH_MAX, ABSOLUTE_MAX : std_logic_vector(31 downto 0); -- := X"00000000" 
	signal FINAL_MAX : std_logic_vector(31 downto 0);	-- := X"00000000"
	
	signal PINC_PEAK_CNT, PEAK_DONE	: std_logic;
	--signal PEAK_NUMBER_D, PEAK_NUMBER_Q	: std_logic_vector(1 downto 0);
	signal PEAK_NUMBER_D, PEAK_NUMBER_Q	: integer range 0 to 511;	  
	
	signal PTW_MINUS_1 : std_logic_vector(15 downto 0);
	
	--signal WindowWdCnt_D, WindowWdCnt_Q	: std_logic_vector(15 downto 0);
	signal WindowWdCntTc_D, WindowWdCntTc_Q : std_logic;
	
	signal SM_INC_PTW_PTR_TDC : std_logic;
	signal not_busy : std_logic;
	signal WE_OR : std_logic;
	
--	signal OVERFLOW : std_logic := '0';	-- temp untill passed 
	signal PEAK_RESET : std_logic;
	--signal FIRST_MAX : std_logic_vector(11 downto 0);
	--signal SUM_TOTAL : std_logic_vector(31 downto 0); -- 12 bits for FDC 14 for CDC. So, using 14 in proc_data  
		
	signal IE_DONE 	: std_logic;
	signal IE_count_D,IE_count_Q : std_logic_vector(11 downto 0);  
	--signal IE : std_logic_vector(11 downto 0) := X"00A"; 
	signal IE_MINUS_1 : std_logic_vector(11 downto 0);
	
	constant NSAMPLES : integer := 20;   -- max number of ADC samples to read in 0-19 but it starts on the sample after go 
	
	type peak_array is array (0 to 15) of std_logic_vector(11 downto 0);
    --type TIME_array is array (0 to 15) of std_logic_vector(11 downto 0);  -- upsampled data
	
    signal AMP_array : peak_array;	   
    signal TIME_array : peak_array;	
	
	signal WE_MAX,LATCH_MAX : std_logic;   
	
	signal ft_overflow_cnt_D, ft_overflow_cnt_Q : std_logic_vector(2 downto 0);
	signal ft_overflow_OUT_D,ft_overflow_OUT_Q	: std_logic_vector(2 downto 0);
	
	component PEAK_AMP 
	  PORT (
	    clk 	: IN STD_LOGIC;
	    srst 	: IN STD_LOGIC;
	    din 	: IN STD_LOGIC_VECTOR(11 DOWNTO 0);
	    wr_en 	: IN STD_LOGIC;
	    rd_en 	: IN STD_LOGIC;
	    dout 	: OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
	    full 	: OUT STD_LOGIC;
	    empty 	: OUT STD_LOGIC
	  );
	END component;
	
	signal RESET : std_logic;
	
	signal CLEAR_SUM_D,CLEAR_SUM_Q,CLEAR_SUM_P :std_logic;
	signal STORE_MAX_D,STORE_MAX_Q,STORE_MAX_P : std_logic;	
	signal DEC_PEAK_CNT_D,DEC_PEAK_CNT_Q,DEC_PEAK_CNT_P : std_logic;	
	
begin

	--ft_adc_D <= OVERFLOW & PTW_RAM_DATA(11 downto 0); -- added OVERFLOW placeholder
	ft_adc_D <= PTW_RAM_DATA; --(12 downto 0);
	--ft_adc_D <=  PTW_RAM_DATA(11 downto 0);
	ft_adc_2D <= ft_adc_Q;
		
	ufindtime : NEWfindtime -- 
		Port map
		( 
			clk 			=> CLK,
			--RESET_N			=> RESET_N,
			go 				=> ft_give, -- the leading edge search process starts 1 clock sample after go is high
			adc 			=> ft_adc_Q, --(11 downto 0), --change!      
			busy 			=> ft_busy, -- busy when 1 and finished when 0         
			le_time 		=> ft_le_time, -- leading edge time found
			le_sample 		=> le_sample,
			le_sample_found	=> LE_SAMPLE_FOUND,
			
    		THRES_HI		=> conv_integer(THRES_HI),
    		THRES_LO		=> conv_integer(THRES_LO), 
			PG				=> conv_integer(PG),

			q_code 			=> ft_q_code -- quality code, 0 is good
		); 
		
	le_sample_found_out <= LE_SAMPLE_FOUND_Q;
	
					
		not_busy <= not ft_busy;
		WE_OR <= WE_DONE or IE_DONE;
		
		ufindtime_sm : FINDTIME_SM_5
		PORT map
		(
			CLK => CLK,
		    RESET_N => RESET_N,
			
			CLR_COUNTS		=> CLR_COUNTS,
			RT_PTW_PTR_LS	=> RT_PTW_PTR_LS,
			LE_SAMPLE_FOUND	=> LE_SAMPLE_FOUND_Q,
			FT_START_FROM_LS=> FT_START_FROM_LS,
			
			BUSY 			=> not_busy, --not ft_busy,
			GO 				=> TDC_GO,
			INC_PTW_PTR_TDC => SM_INC_PTW_PTR_TDC,
			COUNT_SAMPLES	=> COUNT_SAMPLES,
			load_done 		=> ft_load_done,
			FT_START_FROM_NU=> FT_START_FROM_NU,
			--FT_START_FROM_TC=> FT_START_FROM_TC,
			
			MAX_FOUND 		=> MAX_FOUND,
			CHECK_MAX_FOUND => CHECK_MAX_FOUND,
			--CHECK_MAX_FOUND2=> CHECK_MAX_FOUND2,
			PEAK_DONE		=> PEAK_DONE, --'1', --PEAK_DONE,
			--INC_PEAK_CNT	=> INC_PEAK_CNT_D,
			
			PTW_DONE 		=> PTW_DONE, --WE_DONE, --PTW_DONE,	
			WE_DONE			=> WE_OR, --WE_DONE or IE_DONE,
			JUST_WE			=> WE_DONE,
			
			
			ft_give 		=> ft_give,
			load_samples 	=> ft_load_samples,
			SUM_FROM_TC_GO 	=> SUM_FROM_TC_GO,
			CLEAR_SUM 		=> CLEAR_SUM_P, --CLEAR_SUM, --change
			ft_done 		=> SM_ft_done, --TDC_DONE
			SLOPE_CHECK		=> SLOPE_CHECK,
			SLOPE_FOUND		=> SLOPE_FOUND,
			FIND_MAX_GO 	=> FIND_MAX_GO,
			FIND_TROUGH_GO 	=> FIND_TROUGH_GO,
			TROUGH_FOUND	=> TROUGH_FOUND,
			CHECK_MAX_GO 	=> CHECK_MAX_GO,
			--CHECK_MAX_GO_2	=> CHECK_MAX_GO_2,
			STORE_MAX 		=> STORE_MAX_P --STORE_MAX --change
			--RT_PTW_PTR_TDC 	=> RT_PTW_PTR_TDC
		);	
		
  
--Increase PTW_RAM_ADR pointer	
	INC_PTW_PTR_TDC <= SM_INC_PTW_PTR_TDC;
	
-- count for IE
	IE_count_D <= IE_count_Q + 1	when SUM_FROM_TC_GO = '1' else
				  (others => '0')	when CLEAR_SUM_P = '1' else
				  IE_count_Q;
				  
	--IE_MINUS_1 <= IE - 1;	in process reg
	IE_DONE <= '1' when IE_count_Q = IE_MINUS_1 else '0';
	--IE_DONE <= '1' when IE_count_Q = IE else '0';		
		
--track IS, NSAMPLES for FT. May be able to use for peak time etc. 
	ft_done <= SM_ft_done;
	load_count_D <= load_count_Q + 1 when ft_load_samples = '1' else 
				 	0  when SM_ft_done = '1' else -- after PTW_DONE, end of window 
				 	load_count_Q;	 
				 
-- controls FT_GO, but PTW_RAM_ADR continues until end of window for SUM etc.		  
	ft_load_done <= '1' when load_count_Q = NSAMPLES else '0';
 
-- OVERFLOW count		
	--ft_overflow_cnt_D <= ft_overflow_cnt_Q + 1 when (ft_adc_Q(12) = '1' and SUM_FROM_TC_GO = '1' and ft_overflow_cnt_Q /= "111") else 	
	ft_overflow_cnt_D <= ft_overflow_cnt_Q + 1 when (ft_adc_Q = X"FFF" and SUM_FROM_TC_GO = '1' and ft_overflow_cnt_Q /= "111") else 
						 "000" 				   when CLEAR_SUM_P = '1' else 
						 ft_overflow_cnt_Q; 
						
	ft_overflow_OUT_D <=  ft_overflow_cnt_Q when CLEAR_SUM_P = '1' else ft_overflow_OUT_Q;
	ft_overflow_TOTAL <= ft_overflow_OUT_Q; 	   
	
-- SUMing from TC to WE 
	tc_integ_D <= tc_integ_Q + ft_adc_Q(11 downto 0) when SUM_FROM_TC_GO = '1' else -- change to fix the addition of overflow bit
				  (others => '0') 		when CLEAR_SUM_P = '1' else
				  tc_integ_Q;
	
-- SUM total for output
	TC_SUM_D <=  tc_integ_Q when CLEAR_SUM_P = '1' else TC_SUM_Q;
	SUM_TOTAL <= TC_SUM_Q; -- + ft_integ;
	--SUM_TOTAL <= SUM_TOTAL_Q;
-- find peak -- need to store/clear things after ft_done?

	SLOPE_FOUND <= '1' when ((ft_adc_Q > ft_adc_2Q) and (SLOPE_CHECK = '1')) else '0';

	MAX_FOUND <= '1' when ((ft_adc_2Q /= X"000") and (ft_adc_Q <= ft_adc_2Q) and (FIND_MAX_GO = '1')) else '0'; -- need to add trough/above threshold constraints -- was SUM_FROM_TC_GO = '1'
	CHECK_MAX_FOUND <= '1' when ( (ft_adc_Q <= ft_adc_2Q) and (CHECK_MAX_GO = '1')) else '0'; -- < ft_adc_Q -- MAX_CHECK_Q --ft_adc_2Q
	 --(ft_adc_Q /= X"000") and

	MAX_CHECK_D <= X"00000" & ft_adc_2Q(11 downto 0) when FIND_MAX_GO = '1' else MAX_CHECK_Q;	
	--MAX_CHECK_D <= X"00000" & ft_adc_2Q(11 downto 0) when (MAX_FOUND = '1' and CHECK_MAX_GO = '0') else MAX_CHECK_Q; --(ft_adc < ft_adc_Q) and FIND_MAX_GO = '1'; --  FIND_MAX_GO will end once the first max is found 
	--FINAL_MAX <= MAX_CHECK when STORE_MAX = '1';
--	FIRST_MAX <=  FINAL_MAX when PEAK_NUMBER_Q = 0 else X"00000000";

	TROUGH_FOUND <= '1' when ((ft_adc_Q > ft_adc_2Q) and (FIND_TROUGH_GO = '1')) else '0';
	
	--CLEAR_SUM_P <= CLEAR_SUM;	
    --CLEAR_SUM_D <= CLEAR_SUM;
    --CLEAR_SUM_P <= '1' when (CLEAR_SUM_D = '1' and CLEAR_SUM_Q = '0') else '0';
--  
	--STORE_MAX_P <= STORE_MAX;
	--STORE_MAX_D <= STORE_MAX;
    --STORE_MAX_P <= '1' when (STORE_MAX_D = '1' and STORE_MAX_Q = '0') else '0';	

	--PINC_PEAK_CNT <= '1' when STORE_MAX_P = '1' else '0';
	
	--DEC_PEAK_CNT_P <= DEC_PEAK_CNT;
	--DEC_PEAK_CNT_D <= DEC_PEAK_CNT;
	--DEC_PEAK_CNT_P <= '1' when (DEC_PEAK_CNT_D = '1' and DEC_PEAK_CNT_Q = '0') else '0';

	PEAK_NUMBER_D <= PEAK_NUMBER_Q + 1 when (STORE_MAX_P = '1') else -- from FT state machine, limited by max peak number --PINC_PEAK_CNT = '1'
					 PEAK_NUMBER_Q - 1 when (DEC_PEAK_CNT = '1' and PEAK_NUMBER_Q /= 0) else -- from process state machine, after word two is written -- and PEAK_NUMBER_Q /= 0
					 --0				   when CLR_PEAK_CNT = '1' else --change
				     PEAK_NUMBER_Q;	
					 
	   
	PEAK_DONE <= '1' when PEAK_NUMBER_Q = MAX_NUMBER_PEAKS else '0'; -- add register for max peaks	 		 
					 
	PEAK_NUMBER_out <= conv_std_logic_vector(PEAK_NUMBER_Q,5);	--change			 

	PEAK_WRITE_DONE <= '1' when PEAK_NUMBER_Q = 0 else '0';	

	sample_number_D <= sample_number_Q + 1 	when (COUNT_SAMPLES = '1') else 
					   X"000" 				when (SM_ft_done = '1') else
					   sample_number_Q; 
	
	MAX_time_CHECK_D <= sample_number_Q - 4 when FIND_MAX_GO = '1' else MAX_time_CHECK_Q;				   
	--MAX_time_CHECK_D <= sample_number_Q - 3 when (MAX_FOUND = '1' and CHECK_MAX_GO = '0') else MAX_time_CHECK_Q;  -- - 3 to account for delay
	--FINAL_MAX_time <= MAX_time_CHECK when STORE_MAX = '1';

--	FIRST_MAX_time <= FINAL_MAX_time when PEAK_NUMBER_Q = 0;
	
--- FIFOS for peak amp and peak amp time, FDC modes, 12 bits 512 deep
	--PEAK_RESET <= '1' when (CLR_PEAK_CNT = '1' or RESET_N = '0') else '0'; --change

		
	--FINAL_MAX_out <= MAX_CHECK_Q;
	--FINAL_MAX_time_out <= MAX_time_CHECK_Q;  

--	amp_io : process (clk)
--        begin
--         if (clk = '1' and clk'event) then  
--			 
--		   if STORE_MAX = '1' then 
--				AMP_array(PEAK_NUMBER_Q) <= MAX_CHECK_Q(11 downto 0);
--				TIME_array(PEAK_NUMBER_Q)<= MAX_time_CHECK_Q;
--		   end if;
--		   
--		   if DEC_PEAK_CNT = '1' then
--				FINAL_MAX_out(11 downto 0) <= AMP_array(PEAK_NUMBER_Q);
--				FINAL_MAX_time_out <= TIME_array(PEAK_NUMBER_Q);  
--		   end if;
--		   
--        end if;
--    end process amp_io;
	
	upeak_amp : PEAK_AMP 
	  PORT MAP(
	    clk 	=> CLK,
	    srst 	=> RESET, --PEAK_RESET, --not RESET_N, --change
	    din 	=> MAX_CHECK_Q(11 downto 0),
	    wr_en 	=> STORE_MAX_P, --STORE_MAX,
	    rd_en 	=> DEC_PEAK_CNT,
	    dout 	=> FINAL_MAX_out(11 downto 0),
	    full 	=> open,
	    empty 	=> open
	  ); 
	  
	upeak_amp_time : PEAK_AMP 
	  PORT MAP(
	    clk 	=> CLK,
	    srst 	=> RESET, --PEAK_RESET, --not RESET_N,
	    din 	=> MAX_time_CHECK_Q,
	    wr_en 	=> STORE_MAX_P, --STORE_MAX,
	    rd_en 	=> DEC_PEAK_CNT,
	    dout 	=> FINAL_MAX_time_out,
	    full 	=> open,
	    empty 	=> open
	  );

	
    REG : process (CLK, RESET_N)
      begin
        if RESET_N = '0' then 
			
		  load_count_Q <= 0;
--		  ft_give_Q <= '0';
		  
		  tc_integ_Q <= (others => '0');
		  sample_number_Q <= (others => '0'); 
		  
		  --INC_PEAK_CNT_Q <= '0';
		  --PEAK_NUMBER_Q <= "00";
		  PEAK_NUMBER_Q <= 0;
		  
--		  ft_done_Q <= '0';
		  
		  --WindowWdCnt_Q <= (others => '0');
		  WindowWdCntTc_Q <= '0';
		  
		  IE_count_Q <= (others => '0');  
		  
		  ft_overflow_cnt_Q	<= (others => '0'); 
		  ft_overflow_OUT_Q	<= (others => '0'); 
		  
		  TC_SUM_Q <= (others => '0');
		  
		  MAX_CHECK_Q <= (others => '0');
		  MAX_time_CHECK_Q <= (others => '0'); 
		  	  
		  --SUM_TOTAL_Q <= (others => '0');
		  
       elsif (CLK = '1' and clk'event) then	
		   
		  load_count_Q <= load_count_D;	
--		  ft_give_Q <= ft_give;
		  
		  ft_adc_Q <= ft_adc_D;
		  --ft_adc_2D <= ft_adc_Q;	
		  ft_adc_2Q <= ft_adc_2D;  
		  
		  ft_overflow_cnt_Q <= ft_overflow_cnt_D; 
		  ft_overflow_OUT_Q <= ft_overflow_OUT_D;
		  
		  tc_integ_Q <= tc_integ_D;
		  sample_number_Q <= sample_number_D;
		  
		  --INC_PEAK_CNT_Q <= INC_PEAK_CNT_D;
		  PEAK_NUMBER_Q <= PEAK_NUMBER_D;
		  
--		  ft_done_Q <= SM_ft_done;
		  
		  --WindowWdCnt_Q <= WindowWdCnt_D;
		  WindowWdCntTc_Q <= WindowWdCntTc_D;
		  
		  IE_count_Q <= IE_count_D;
		  
		  TC_SUM_Q <= TC_SUM_D;
		  
		  MAX_CHECK_Q <= MAX_CHECK_D;
		  MAX_time_CHECK_Q <= MAX_time_CHECK_D;	
		  
		  --PEAK_NUMBER_out <= PEAK_NUMBER_Q;
		 
		  LE_SAMPLE_FOUND_Q <= LE_SAMPLE_FOUND;
		  --SUM_TOTAL_Q <= SUM_TOTAL_D;	
		  IE_MINUS_1 <= IE - 1;
		  
		  --CLEAR_SUM_Q <= CLEAR_SUM_D;
		  --STORE_MAX_Q <= STORE_MAX_D;
		  --DEC_PEAK_CNT_Q <= DEC_PEAK_CNT_D; 
		  
			le_time <= "000" & ft_le_time; -- change, chack on number of bits in format vs. function!!!!!!!!!
		  
        end if;
      end process REG;


   local_rst_REG : process (CLK)
      begin
       if (CLK = '1' and clk'event) then	
		   RESET <= not RESET_N;
       end if;
      end process local_rst_REG;
        
end Behavior;

	--ft_go <= TDC_GO;

	--ft_done <= ft_load_done; --not ft_load_samples; --not ft_load_samples; --not ft_go; --(ft_go and not NO_GO); 
	--ft_busy <= busy;
	--ft_le_time <= le_time;

	--ft_q_code <= q_code;
	
--    process (CLK, RESET_N)
--      begin
--        if rising_edge(CLK) then
--       
--        end if;
--      end process;   


--component FINDTIME_SM
--	PORT (	
--			CLK,
--			BUSY,
--			GO,
--			load_done,
--			RESET_N,
--			FT_START_FROM_TC,
--			MAX_FOUND,
--			PTW_DONE
--			: IN std_logic;
--			
--			ft_go,
--			load_samples,
--			SUM_FROM_TC_GO,
--			CLEAR_SUM,
--			ft_done,
--			FIND_MAX_GO,
--			RT_PTW_PTR_TDC 
--			: OUT std_logic
--		  );
--END component;  



--	process(CLK)
--		begin
--			if CLK'event and CLK='1' then
--				if (ft_adc < ft_adc_Q) and (FIND_MAX_GO = '1') then -- < ft_adc_Q
--					MAX_FOUND <= '1';
--				else
--					MAX_FOUND <= '0'; 
--				end if;	
--			end if;
--	end process; 		
--		
--	process(CLK)
--		begin
--			if CLK'event and CLK='1' then
--				if (ft_adc < MAX_CHECK) and (CHECK_MAX_GO = '1') then -- < ft_adc_Q
--					CHECK_MAX_FOUND <= '1';
--				else
--					CHECK_MAX_FOUND <= '0'; 
--				end if;	
--			end if;
--	end process; 

--	process(CLK)
--		begin
--			if CLK'event and CLK='1' then
--				if (ft_adc > ft_adc_Q) and (FIND_TROUGH_GO = '1') then
--					TROUGH_FOUND <= '1';
--				else
--					TROUGH_FOUND <= '0'; 
--				end if;	
--			end if;
--	end process;