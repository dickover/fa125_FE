-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- + Indiana University CEEM    /    GlueX/Hall-D Jefferson Lab                    +
-- + 72 channel 12/14 bit 125 MSPS ADC module with digital signal processing       +
-- + Frontend FPGA (acquisition buffer, readout / ZS / raw data buffer / "EVB")    +
-- + Gerard Visser - gvisser@indiana.edu - 812 855 7880                            +
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- $Id: fe.vhd 33 2012-04-25 04:19:05Z gvisser $

-- modified 10-17-2013 C. Dickover
-- intergrated fADC250 front-end architexture to seed evbd daisy chain readout
-- Alogorithms omitted but structure left for future use
-- current pin usage for first attempt are as such
	-- ferdstart is used as reset
	-- ferdcmd used as read enable in conjunction with token
	-- AF_N used as write enable (to PROC) for evbd daisy-chain fifos, 
		-- delayed according to chain location (cid) for register delays  

-- update 4-29-2014 C. Dickover
		-- updated 250 front-end processing alogorithms
		-- all processing modes now available
		-- added register space for user variables, window width, lookback, etc. 
		
-- ver 0x10101 Raw mode
-- ver 0x10201 250 processing modes
-- ver 0x10202 250 processing modes, ch mask, pulser, playback, serial line bug fix
-- ver 0x10203 event cnt bug fix	(change on proc)
-- ver 0x10205 avg 16 samples on fe tdc_SM
-- ver 0x10206 bug fix constraints on fe, proc
-- ver 0x10207 bug fix buffer overload on main, also increased buffers here on FE 
-- ver 0x20001 New algoritms 
-- ver 0x20005 first release New algoritms
-- ver 0x20006 BUSY implemented on PROC, bug fix for saturated values and multiple peaks
-- ver 0x20007 FIXED SUMMING ISSUE (OVERFLOW BIT), FIXED NPED+PG-1 to NPED+PG BY ADDING STATE BEFORE "SEARCH"  
-- ver 0x20008 FIXED end of window amplitude, FIXED suming when WE happens before ft returns, FIXED "saturation issues", Removed overflow bit
-- ver 0x20009 trying to fix extra raw data words here (state machine congig, cdcfdc) and main (fifo SM)
-- ver 0x2000A single clk on proc buff, fixed o's issue on peak algo, 1 more sample before amp algo starts, fixed we bug on amp algo (3 conditionals instead of 1)	
-- ver 0x2000B slope check, added another WE done, FSM safe mode and sequential (synthesis)
-- ver 0x2000C FT_PROCESSM_CDC_FDC gave room for setup sel 1 state before and held Q value in mux
-- ver 0x2000D Raw data and data format state machine re structure for wr en location 
-- ver 0x2000E fixed amplitude SM and Data format SM(repeated raw data words)
-- ver 0x2000F Changed pedetal shifting (NP2+- rPBIT = PBIT based on SIGN) (BUSY stuff on PROC)

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
--use IEEE.fixed_pkg.all;

library unisim;
use unisim.vcomponents.all;
library work;
use work.miscellaneous.all;	

  use IEEE.std_logic_unsigned.all; 
  use IEEE.std_logic_arith.all;

entity fe is
   generic(	
       Simulation  : integer := 0;
       svnver: integer := 0
      );
   port(
		aclk: in std_logic;
		adcclko: in std_logic;-- just added from H4, was in .ucf
		adca,adcb,adcc,adcd,adce,adcf: in std_logic_vector(11 downto 0);
		feWriterCmd: in std_logic;        -- have to consider DELAY setting! may need to tune it...
		rclk: in std_logic; --added for FE_FIFO read, B9
		FeRdCmd: in std_logic; -- read enable
		FeRdStart: in std_logic; -- used for reset, comes from PROC
		evbDin: in std_logic_vector(17 downto 0);
		evbDout: out std_logic_vector(17 downto 0);
		evbTokIn: in std_logic;
		evbTokOut: out std_logic;
		FERDBUSY_N: out std_logic; 
		EVBHOLD: in std_logic; -- tristate and need to add to ucf
		--AF_n: out std_logic; -- tristate, using as a writecmd to proc. adjusted for daisychain register delay.
		--FERDERR_n: out std_logic; -- Using as BUSY because I already used buy, whoops 
		led_sig_n,led_lim_n: out std_logic;
		--mul: out std_logic_vector(2 downto 0);  -- for internal trigger mode
	      -- slow controls
		sclk,sin : in std_logic; --softRst
		sout: out std_logic;
	      -- misc
		cid: in std_logic_vector(3 downto 0)
      );

   attribute period: string;
   attribute period of rclk: signal is "12.5ns";	
   attribute period of aclk: signal is "7.9ns";
   attribute period of sclk: signal is "25ns";
end fe;

architecture fe_0 of fe is
	type adcsr_type is array(natural range <>) of std_logic_vector(adca'range);
	type ufixed is array (INTEGER range <>) of STD_LOGIC; 
	constant NPRE: integer := 200;        -- controls number of presamples (eff. NPRE+smallconstant)
	--signal adca_r,adcb_r,adcc_r,adcd_r,adce_r,adcf_r: adcsr_type(0 to NPRE);
	signal led_sig,led_lim: std_logic;
	signal time_tolerance: ufixed (8 downto 0);
	signal rclk_b, rclk_fwd, rclk_fwd_T, ODDR_T_en : std_logic;
	signal aclk_b : std_logic;
	signal sclk_b : std_logic;
	
	signal adca_D,adcb_D,adcc_D,adcd_D,adce_D,adcf_D : std_logic_vector(11 downto 0);
	signal adca_Q,adcb_Q,adcc_Q,adcd_Q,adce_Q,adcf_Q : std_logic_vector(11 downto 0);
	
	--signal iadca_D,iadcb_D,iadcc_D,iadcd_D,iadce_D,iadcf_D : std_logic_vector(12 downto 0);
	--signal iadca_Q,iadcb_Q,iadcc_Q,iadcd_Q,iadce_Q,iadcf_Q : std_logic_vector(12 downto 0);

component ADC_PROC_TOP is
        port
         (
			CLK                  		: in std_logic; -- aclk, 125 Mhz for fADC125
			--CLK_HOST             		: in std_logic; -- 
			--CLK_80               		: in std_logic; -- trying to fix playback   -- may need back for playback
			RESET_N              		: in  std_logic;-- ferdstart... for now	  
--			SOFT_RESET_N         		: in std_logic; -- 
			
			--- To Host 
			--DATA_BUFFER_RDY_REG  : out std_logic; --  
			TRIGGER              		: in std_logic; -- feWriterCmd, from processor FPGA, all I have for trig. have to consider DELAY setting! may need to tune it...
			TRIGGER2             		: in std_logic;  --- for PPG play Back -- N/A, don't have on FE... yet	   
			NumberOfTriggerInFifo_OUT 	: out std_logic_vector(7 downto 0); --CHANGE
			--SYNC                 : in std_logic; -- 
			
			--- FROM ADC  ************
			--adcclko               		  : in std_logic; -- used for all 6 ADCs, comes from one of three adc chips, middle 2 channels, also not differential	
			ADC1_DATA					  : in std_logic_vector(11 downto 0); -- not differential,  ends up being ADC_RAWDATA_1 so delete converter	
			ADC2_DATA					  : in std_logic_vector(11 downto 0);
			ADC3_DATA					  : in std_logic_vector(11 downto 0);
			ADC4_DATA					  : in std_logic_vector(11 downto 0);
			ADC5_DATA					  : in std_logic_vector(11 downto 0);
			ADC6_DATA					  : in std_logic_vector(11 downto 0);
			-------- Only need 6 channels if will fit on FE FPGA ------------------------ 
			
			--- To control bus Status register
			--TRIGGER_NUMBER_REG  : out std_logic_vector(15 downto 0); --  
			
			--- To control bus Registers
			PTW          : in  std_logic_vector(9 downto 0); --  
			PL        : in  std_logic_vector(15 downto 0); --  

			CONFIG1           : in  std_logic_vector(15 downto 0); -- 
			CONFIG2           : in  std_logic_vector(15 downto 0); -- 
			-- Hit thresholds 
			TET0 : in  std_logic_vector(11 downto 0); --       
			TET1 : in  std_logic_vector(11 downto 0); --       
			TET2 : in  std_logic_vector(11 downto 0); --       
			TET3 : in  std_logic_vector(11 downto 0); --       
			TET4 : in  std_logic_vector(11 downto 0); --       
			TET5 : in  std_logic_vector(11 downto 0); -- 
			
			NP					: in std_logic_vector(7 downto 0); -- number of samples for initial pedestal
			NP2					: in std_logic_vector(7 downto 0);	-- number of samples for local pedestal	
				
			IBIT				: in std_logic_vector(2 downto 0);					
			ABIT				: in std_logic_vector(2 downto 0);
			PBIT				: in std_logic_vector(2 downto 0);
			
			-- NEW REGS
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

			IE 					: in std_logic_vector(11 downto 0);	
			PG 					: in std_logic_vector(7 downto 0); 
			--ExceedNumberOfMaxTrigger_REG   : out std_logic;

-- REMOVED PLAYBACK FOR NOW----

--			PPG_DAT_OUT_VALID   : in std_logic; --   
--			PPG_DAT_Out         : out  std_logic_vector(15 downto 0); --   
--			PPG_DAT_IN   : in std_logic_vector(15 downto 0); --   
			
			-- FIFO controls are for local FE fifo
			--- Controls for onboard FIFO are located on PROC FPGA U98
			cid						  : in std_logic_vector(3 downto 0);
			FIFO_DATA            	  : out std_logic_vector(31 downto 0); 
			--FIFO_WCLK                  : out std_logic; -- Write Clock
			FIFO_WEN                   : out std_logic -- Write EN
			--FIFO_OE_N                  : out std_logic -- output enable
        );
	end component; 
	
	signal FIFO_DATA		: std_logic_vector(35 downto 0); 
	--signal FIFO_WCLK		: std_logic; -- Write Clock
	signal FIFO_WEN     	: std_logic; -- Write EN
	--signal FIFO_OE_N     	: std_logic; -- output enable
	
	-- Output fifo onto evdb chain
	 
	component NEW_FIFO_4096 IS
		  PORT (
		    rst : IN STD_LOGIC;
		    wr_clk : IN STD_LOGIC;
		    rd_clk : IN STD_LOGIC;
		    din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		    wr_en : IN STD_LOGIC;
		    rd_en : IN STD_LOGIC;
		    dout : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		    full : OUT STD_LOGIC;
		    --almost_full : OUT STD_LOGIC;
		    empty : OUT STD_LOGIC
		    --wr_data_count : OUT STD_LOGIC_VECTOR(9 DOWNTO 0)
				);
	END component;

	signal wr_data_count 	: STD_LOGIC_VECTOR(9 DOWNTO 0);
	
	-- controls token passing and process communication to PROC

	component FE_TOKEN_2 IS
		PORT (CLK,Clear_Token,evbTokIn,Read_Done,RESET_N,Event_Go: IN std_logic;
			Hold_Token,Send_Token,FERDBUSY : OUT std_logic);
	END component;
	
	signal Drop_Token,Hold_Token,Wr_Hold,Send_Token,Read_Done : std_logic;
	signal Read_done_D : std_logic;
	signal Read_done_Q : std_logic;
	signal PRead_done : std_logic;

	signal evbTokIn_BUF1_D,evbTokIn_BUF2_D 			: std_logic := '0';
	signal evbTokIn_BUF1_Q,evbTokIn_BUF2_Q 			: std_logic := '0';	
	signal PevbTokIn : std_logic; 
	
	signal CLEAR_TOKEN : std_logic;
													
	signal evbTokOut1_D, evbTokOut1_Q, evbTokOut1_Q_B	: STD_LOGIC;
	signal evbTokOut2_D,evbTokOut2_Q,evbTokOut2_Q_B		: STD_LOGIC;
	
--	signal FIFO_WCLK_D, FIFO_WCLK_Q					: STD_LOGIC;
	signal FIFO_WEN_D, FIFO_WEN_Q					: STD_LOGIC;
	
	signal FeRdCmd_D,FeRdCmd_Q						 : STD_LOGIC := '0';
	signal EVBHOLD_D,EVBHOLD_Q						: std_logic;
	
	signal fe_wr_en, fe_rd_en							: STD_LOGIC;   
	signal fe_rd_en_D, fe_rd_en_Q						: STD_LOGIC;
	signal fe_wr_en_D, fe_wr_en_Q						: STD_LOGIC;
	
	signal FIFO_DATA_D, FIFO_DATA_Q					: STD_LOGIC_VECTOR(31 DOWNTO 0);
	signal fe_data_out,fe_data_out_Q					: STD_LOGIC_VECTOR(15 DOWNTO 0);
	signal evbDin_D,evbDin_Q							: STD_LOGIC_VECTOR(17 DOWNTO 0) := "00"&X"0000";
	signal evbDin_2D,evbDin_2Q							: STD_LOGIC_VECTOR(17 DOWNTO 0) := "00"&X"0000";
	
	signal EVENT_done,pEVENT_done,Event_Go,FERDBUSY				: std_logic := '0';
	signal EVENT_done_D, EVENT_done_Q 		: std_logic;
	
	signal PINC_EVENT_CNT, PDEC_EVENT_CNT			: std_logic;
	
	signal DEC_EVENT_BUF1_D, DEC_EVENT_BUF1_Q		: std_logic;
	  
	signal EVENT_CNT_D, EVENT_CNT_Q					:std_logic_vector(7 downto 0):="00000000"; 
	signal evbDout_D,evbDout_2D						: STD_LOGIC_VECTOR(17 DOWNTO 0) := "00"&X"0000";
	signal evbDout_Q,evbDout_2Q						: STD_LOGIC_VECTOR(17 DOWNTO 0) := "00"&X"0000";  
	
--	signal fe_rd_en_BUF1_D,fe_rd_en_BUF2_D			: std_logic;
--	signal fe_rd_en_BUF1_Q,fe_rd_en_BUF2_Q			: std_logic;
	signal fe_outfifo_empty,fe_outfifo_full,fe_outfifo_full_Q		: std_logic;
							  	
	signal EVENT_Go_BUF1_D,EVENT_Go_BUF2_D			: std_logic;
	signal EVENT_Go_BUF1_Q,EVENT_Go_BUF2_Q			: std_logic; 

--	signal FERDBUSY_BUF1_D,FERDBUSY_BUF1_Q			: std_logic;

	signal FERDBUSY_BUF1_D,FERDBUSY_BUF2_D			: std_logic := '1';
	signal FERDBUSY_BUF1_Q,FERDBUSY_BUF2_Q			: std_logic := '1';
	signal FERDBUSY_N_A, FERDBUSY_N_B				: std_logic;
	signal FERDBUSY_N_C, FERDBUSY_N_C_Q				: std_logic;
	
	--signal TRIGGER_NUMBER_REG : std_logic_vector(15 downto 0);
															 
	signal CONFIG1	 : std_logic_vector(15 downto 0) := X"001D"; --change revert
	signal CONFIG2   : std_logic_vector(15 downto 0) := X"003F"; --  
	-- Hit thresholds -- also need high and low thresholds here for algorithm section (will replace mode 2)	
	signal PTW_WORDS            :  std_logic_vector(9 downto 0):= "00"&X"A0"; --"00"&X"c8"; B4 -- Programmable Triggger Window number of words --default 104	:= "0"&x"68"   --change	--rate
	signal IE : std_logic_vector(11 downto 0) := X"0c8"; --X"12c" -- X"0C8"
	signal TET0, TET1, TET2, TET3, TET4, TET5 : std_logic_vector(11 downto 0) := X"078"; --X"044"; -- X"064"  -X"12C" --07D --78 
	
	signal NP,NP2 : std_logic_vector(7 downto 0) := X"04"; -- number of samples for initial/local pedestal default = 2^4 =16 	  
	signal PG : std_logic_vector(7 downto 0) := X"04"; 
	
	signal IBIT 	: std_logic_vector(2 downto 0) := "000"; -- := "100";	
	signal ABIT 	: std_logic_vector(2 downto 0) := "000"; -- := "011";	
	signal PBIT		: std_logic_vector(2 downto 0) := "000"; -- := "000";
	signal rPBIT 	: std_logic_vector(2 downto 0) := "100"; -- := "000";	
	signal PSIGN : std_logic := '1';
	
    signal THRES_HI_0: std_logic_vector(8 downto 0) := "0" & X"64"; -- 4 sigma --int 80 --X"50"
    signal THRES_LO_0: std_logic_vector(7 downto 0) := X"19"; -- 1 sigma --int 20 --X"14"
	
    signal THRES_HI_1: std_logic_vector(8 downto 0) := "0" & X"64"; -- 4 sigma --int 80
    signal THRES_LO_1: std_logic_vector(7 downto 0) := X"19"; -- 1 sigma --int 20 
	
    signal THRES_HI_2: std_logic_vector(8 downto 0) := "0" & X"64"; -- 4 sigma --int 80
    signal THRES_LO_2: std_logic_vector(7 downto 0) := X"19"; -- 1 sigma --int 20
	
    signal THRES_HI_3: std_logic_vector(8 downto 0) := "0" & X"64"; -- 4 sigma --int 80
    signal THRES_LO_3: std_logic_vector(7 downto 0) := X"19"; -- 1 sigma --int 20
	
    signal THRES_HI_4: std_logic_vector(8 downto 0) := "0" & X"64"; -- 4 sigma --int 80
    signal THRES_LO_4: std_logic_vector(7 downto 0) := X"19"; -- 1 sigma --int 20
	
    signal THRES_HI_5: std_logic_vector(8 downto 0) := "0" & X"64"; -- 4 sigma --int 80
    signal THRES_LO_5: std_logic_vector(7 downto 0) := X"19"; -- 1 sigma --int 20
		
	--signal cid_D, cid_Q : std_logic_vector(3 downto 0);
	
	signal  PPG_DAT_OUT_VALID   : std_logic; -- need to create register  
	signal  PPG_DAT_Out, PPG_DAT_IN   : std_logic_vector(15 downto 0); -- need to create register  

	--------------------------------------------------------
 ---- TEST BENCH STUFF-----------------------------------------------------------	 
 ---- TEST BENCH STUFF----------------------------------------------------------- 
 
	--constant WindowWidth    : integer := 200;  --- PTW	-- RATE
	--constant WindowWidth    : integer := 10;  --- PTW
	signal LookBack       : std_logic_vector(15 downto 0) := X"0002"; --integer := 17; --change
	--constant TrigerDelay   : std_logic_vector(13 downto 0) := "00" & x"064";  
	--constant LookBackTime   : time := conv_integer(LookBack)* 8000 ps; --(LookBack)* 8000 ps; 
--	constant CLOCK125_ns        :  time := 8000 ps;
--	constant RESET_N_ns		  : time := CLOCK125_ns * 4;
--	constant collect_on_ns		  : time := CLOCK125_ns * 1200; -- used for sim 
	
	signal i	: integer :=0; -- used for collect_on process in simulation  

--	signal PTW_WORDS_MINUS_ONE  :  std_logic_vector(8 downto 0);  -- Use to mark the end of PTW data words
	signal TRIGGER,TRIGGER2		 : std_logic := '0';
	signal TRIGGER_N            :  std_logic := '1';

	signal LATENCY_WORD              :  std_logic_vector(10 downto 0);
	signal PTW_DAT_BUF_LAST_ADR_TB :  std_logic_VECTOR(11 downto 0):= conv_std_logic_vector(2015, 12);  --- The last address of the PTW data Buffer, x"7df"
	signal MAX_PTW_DATA_BLOCK   :  std_logic_VECTOR(7 downto 0):= conv_std_logic_vector(18, 8); --- Maximum number of PTW block of data, x"12"
	
	signal PTW_DAT_BUF_LAST_ADR    :  std_logic_VECTOR(15 downto 0);

	signal PTW_TS_TN_WORDS		: std_logic_vector(11 downto 0);
--	signal TIME_STAMP_Q           :  std_logic_vector(47 downto 0);
	signal COLLECT_ON           :  std_logic; -- will come from reg config_1
	
	signal feWriterCmd_D,feWriterCmd_Q	:  std_logic := '0';	
	
	signal trail_cnt_D,trail_cnt_Q		: std_logic_vector(31 downto 0);

-------------- PPG trig and delayed trig2 --------------------------------
--	component pulse_delayed is
--		generic( bitlength: integer );
--		port( 	  go_pulse: in std_logic;									-- go_pulse is assumed synchronized to clk
--			   delay_width: in std_logic_vector((bitlength - 1) downto 0);	-- delay width - 1 in clk periods
--		       pulse_width: in std_logic_vector((bitlength - 1) downto 0);	-- pulse width - 1 in clk periods
--				       clk: in std_logic;
--			         reset: in std_logic;
--			     delay_out: out std_logic;									-- pulse asserted for delay period
--			     pulse_out: out std_logic );								-- delayed pulse out
--	end component;
	
	signal PPG_trig : std_logic_vector(1 downto 0);
	signal PPG_trig_delay_width : std_logic_vector(11 downto 0);
	--signal go_pulse, pulser_trig_delay, go_pulse_trig, soft_trig :std_logic;
	signal test_mode_on, delayed_trig : std_logic;
	
 ---- TEST BENCH STUFF-END-------------------------------------------------------
 ---- TEST BENCH STUFF-----------------------------------------------------------	 
 ---- TEST BENCH STUFF----------------------------------------------------------- 
 
-- would like to re-enable this for A24 reads
--   component acqfifo
--      port (
--         din: in std_logic_VECTOR(13 downto 0);
--         rd_clk: in std_logic;
--         rd_en: in std_logic;
--         rst: in std_logic;
--         wr_clk: in std_logic;
--         wr_en: in std_logic;
--         dout: out std_logic_VECTOR(27 downto 0);
--         empty: out std_logic;
--         full: out std_logic);
--   end component;
	
   component scslave
      port (
		osc         : in  std_logic;
		--tst_fclk    : out  std_logic;
		sclk, sin   : in  std_logic;
		sout        : out std_logic;
		ca          : out std_logic_vector(13 downto 0);
		cwr         : out std_logic;
		cwd         : out std_logic_vector(31 downto 0);
		crd         : in  std_logic_vector(31 downto 0);
		crdv, cwack : in  std_logic;
		crack : out std_logic); 
   end component;

	signal ca: std_logic_vector(13 downto 0);
	signal cab: std_logic_vector(3 downto 0);
	signal sout_int,crdv,cwr,cwack,crack: std_logic;
	signal crd,cwd: std_logic_vector(31 downto 0);
	signal csr: std_logic_vector(31 downto 0);
	--signal sync_enable : std_logic;
	signal status_1: std_logic_vector(31 downto 0);
	signal clk40MHz,clk200MHz,wiz_clk : std_logic;
--	signal wrt_stb_D,wrt_stb_2D : std_logic;
--	signal wrt_stb_Q,wrt_stb_2Q : std_logic;

   signal feWrCmd_r,feWrCmd_r2: std_logic;
--   signal rda,rda_r,rda_r2,rda_r3,rdena: std_logic;
--   signal rdb,rdb_r,rdb_r2,rdb_r3,rdenb: std_logic;
--   signal rdc,rdc_r,rdc_r2,rdc_r3,rdenc: std_logic;
--   signal rdd,rdd_r,rdd_r2,rdd_r3,rdend: std_logic;
--   signal rde,rde_r,rde_r2,rde_r3,rdene: std_logic;
--   signal rdf,rdf_r,rdf_r2,rdf_r3,rdenf: std_logic;
	
--   signal acqa,acqb,acqc,acqd,acqe,acqf: std_logic_vector(28 downto 0);
--	signal algo_a,algo_b,algo_c,algo_d,algo_e,algo_f: std_logic_vector(28 downto 0);
	
--   signal acqfifos_full: std_logic;
--   signal mul_k: integer range 0 to 7;
   
   signal k, fifo_rd, tst_fclk, aevb_sel, bevb_sel: std_logic;

--    signal test: integer range 0 to 63; (for development on mul output)
	signal sout_int_r: std_logic;
	signal sclk_sl:	std_logic;

	--NEW REG VALUES
	
	signal RESET : std_logic;  
	signal RESET_N 				: std_logic;
	signal RESET_N_D				: std_logic := '1'; 
	signal RESET_N_Q				: std_logic := '1';	
	
	signal OVERFLOW_0,OVERFLOW_1,OVERFLOW_2,OVERFLOW_3,OVERFLOW_4,OVERFLOW_5 : std_logic;
	signal ExceedNumberOfMaxTrigger_REG : std_logic;
	signal NumberOfTriggerInFifo_OUT : std_logic_vector(7 downto 0); 
	signal CHECK_RESET : std_logic_vector(7 downto 0);
	
begin
	
	--FERDERR_n <= '0' when ExceedNumberOfMaxTrigger_REG = '1' else 'Z';
	
	adca_D <= adca;
	adcb_D <= adcb;
	adcc_D <= adcc;
	adcd_D <= adcd;
	adce_D <= adce;
	adcf_D <= adcf;
--
--	OVERFLOW_0 <= '1' when adca_Q = X"FFF" else '0';
--	OVERFLOW_1 <= '1' when adcb_Q = X"FFF" else '0';
--	OVERFLOW_2 <= '1' when adcc_Q = X"FFF" else '0';
--	OVERFLOW_3 <= '1' when adcd_Q = X"FFF" else '0';
--	OVERFLOW_4 <= '1' when adce_Q = X"FFF" else '0';
--	OVERFLOW_5 <= '1' when adcf_Q = X"FFF" else '0';   
--		
--	iadca_D <= OVERFLOW_0 & adca_Q;
--	iadcb_D <= OVERFLOW_1 & adcb_Q;
--	iadcc_D <= OVERFLOW_2 & adcc_Q;
--	iadcd_D <= OVERFLOW_3 & adcd_Q;
--	iadce_D <= OVERFLOW_4 & adce_Q;
--	iadcf_D <= OVERFLOW_5 & adcf_Q;
--
		   
	sclk_B <= sclk;

	rBUFG_inst : BUFG
		port map (
			O => rclk_B, -- Clock buffer output
			I => rclk -- Clock buffer input
			);
--			
	aBUFG_inst : BUFG
		port map (
			O => aclk_B, -- Clock buffer output
			I => aclk -- Clock buffer input
			);
--		

	--led_sig_n <= '0' when led_sig='1' else 'Z';  -- wire-OR across 4 FE FPGA's
	led_sig_n <= '1';  -- wire-OR across 4 FE FPGA's
	led_lim_n <= '0' when led_lim='1' else 'Z';

	--feWriterCmd_D <= not feWriterCmd; --trigger_n from proc inverted for use
	feWriterCmd_D <= feWriterCmd;
	TRIGGER <= '1' when feWriterCmd_Q = '1' else '0';
	--TRIGGER <= feWriterCmd_Q;  
	
	EVBHOLD_D <= EVBHOLD;
	TRIGGER2 <= EVBHOLD_Q;
	
	RESET_N_D <= FeRdStart; --change to register reset 	
	RESET_N <= RESET_N_Q;
	--RESET <= not RESET_N_Q;
	RESET <= '1' when RESET_N_Q ='0' else '0';
	
	RESET_REG : process (aclk_B)
        begin
         if (aclk_B = '1' and aclk_B'event) then --aclk	  

			--RESET_N_D <= FeRdStart; --change to register reset 	
			RESET_N_Q <= RESET_N_D;
			--RESET <= not RESET_N_D;
			
			--RESET_N <= RESET_N_Q;
			--RESET <= not RESET_N_Q;	
		
        end if;
        end process RESET_REG;

-- serial comm between main/proc/fe, has issue with first read, original from Gerard
   sc1: scslave 
      port map (
				osc   => rclk_B,
				sclk  => sclk_B, --sclk_B,--sclk,
				sin   => sin,
				sout  => sout_int, --sout_int, change 
				ca    => ca,
				cwr   => cwr,
				cwd   => cwd,
				crd   => crd,
				crdv  => crdv,
				cwack => cwack,
				crack => open --crack
			);
   -- added a rescinding drive for sout, but it's a bit of a hack here, we should keep the IOFF on output
   -- enable which is now lost. try it, fix it later.
   -- however, this isn't quite optimal  -- we're left driving sout high after the cycle ends, would be better
   -- not to do that.
   -- THE WHOLE scslave and corresponding master needs revamping I think. I will leave it to another day. What
   -- is here appears to work, as long as osc input to scslave is active. Note that here that requires 3V
   -- power to be enabled... -- dosen't need power for rclk but still has issue with "first read" after reboot
	
   process(sclk_B)
   begin
      if sclk_B'event and sclk_B='1' then
         sout_int_r <= sout_int;
      end if;
   end process;
   sout <= sout_int when (sout_int='0' or sout_int_r='0') else 'Z';  -- don't forget, these are wire-OR tied on the board!
   led_lim <= not sout_int;
   
   cab <= (cid)+1; -- cid--std_logic_vector(unsigned(cid)+1);  -- set upper nibble of address from tied id pins
	
	--read acknowledge for FE reg space
--   crdv <= '1' when (	ca=cab&"0000000000" or ca=cab&"0000000001" 
--   						or std_match(ca,cab&"0000001---") or std_match(ca,cab&"0000010---") 
--						or std_match(ca,cab&"0000010110") or std_match(ca,cab&"0000010111") 
--						--or std_match(ca,cab&"0000011000") or std_match(ca,cab&"0000011001")
--						or std_match(ca,cab&"0000011100") or std_match(ca,cab&"0000011101")
--						or std_match(ca,cab&"0000011110") or std_match(ca,cab&"0000011111")
--						or std_match(ca,cab&"0000100000") or std_match(ca,cab&"0000100001")
--						--or std_match(ca,cab&"0000011010") or std_match(ca,cab&"0000011011")
--						or std_match(ca,cab&"0000100010") --or std_match(ca,cab&"0000100011") --old trig number
--						or std_match(ca,cab&"0000100100") 
--						--or std_match(ca,cab&"0000100101")or std_match(ca,cab&"0000100111")  --playback
--				--NEW REGS	  
--						or std_match(ca,cab&"0000101000") or std_match(ca,cab&"0000101001") 
--						or std_match(ca,cab&"0000101010") or std_match(ca,cab&"0000101011") 
--					  	or std_match(ca,cab&"0000101100")
--				--NEW HI THRESH
--						or std_match(ca,cab&"0000101101") or std_match(ca,cab&"0000101110")
--						
--						)
--						else '0';
						
	crdv <= '1' when (ca=cab&"0000000000" or ca=cab&"0000000001" or ca=cab&"0000010110"	or
							ca=cab&"0000010111" or ca=cab&"0000011100" or ca=cab&"0000011101" or
							ca=cab&"0000011110" or ca=cab&"0000011111" or ca=cab&"0000100000" or
							ca=cab&"0000100001" or ca=cab&"0000100010" or ca=cab&"0000100011" or
							ca=cab&"0000100100" or ca=cab&"0000101000" or ca=cab&"0000101001" or
							ca=cab&"0000101010" or ca=cab&"0000101011" or ca=cab&"0000101100" or
							ca=cab&"0000101101" or ca=cab&"0000101110")
					else '0';	
		
	--crdv <= '1' when std_match(ca,cab&"0000------") else '0';
	
	cwack <= '1' when ca="0001"&"0000000001" or ca="0001"&"0000010110" or ca="0001"&"0000010111" or --ca="0001"&"0000011000" or
				  -- ca="0001"&"0000011001" or ca="0001"&"0000011010" or ca="0001"&"0000011011" or 
				  ca=cab&"0000011100" or
				  ca=cab&"0000011101"    or ca=cab&"0000011110"    or ca=cab&"0000011111"    or ca=cab&"0000100000" or
				  ca=cab&"0000100001"    or ca="0001"&"0000100010" or ca=cab&"0000100100"    or 
				  --ca=cab&"0000100101" or  ca="0001"&"0000100110" or ca="0001"&"0000100111" or	 --playback
			--NEW REGS	  
				  ca="0001"&"0000101000" or ca=cab&"0000101001" or ca=cab&"0000101010" or ca=cab&"0000101011" or
				  ca="0001"&"0000101100"
			-- NEW HI THRESH
				or ca=cab&"0000101101" or ca=cab&"0000101110"
		else '0'; 

-------------- FE read REG SPACE --------------------------------------- 
-- A24 adc reads are not currently accesable because I removed the fifos and use the 250 code 
-- will look into a rework later
   with ca(9 downto 0) select crd <=
     	X"0002000F" when "0000000000", -- &std_logic_vector(to_unsigned(svnver,16))
      	csr when "0000000001",
		X"00000"&"00"&PTW_WORDS when "0000010110", -- (0xN058)
		X"0000"&LookBack when "0000010111", -- (0xN05C)
		X"00000"&TET0 when "0000011100", -- (0xN070)
		X"00000"&TET1 when "0000011101", -- (0xN074)
		X"00000"&TET2 when "0000011110", -- (0xN078)
		X"00000"&TET3 when "0000011111", -- (0xN07C)
		X"00000"&TET4 when "0000100000", -- (0xN080)
		X"00000"&TET5 when "0000100001", -- (0xN084)
		X"0000"&CONFIG1 when "0000100010", -- (0xN088)
		CHECK_RESET&"000000"&EVENT_done&Read_done&NumberOfTriggerInFifo_OUT&EVENT_CNT_Q when "0000100011", -- (0xN08C) --CHANGE
		X"0000"&CONFIG2 when "0000100100", -- (0xN090)
		"000"&PBIT&PSIGN&rPBIT&ABIT&IBIT&NP2&NP when "0000101000", --(0xN0A0)
		THRES_LO_1&X"00"&THRES_LO_0&X"00" when "0000101001", --0xN0A4
		THRES_LO_3&X"00"&THRES_LO_2&X"00" when "0000101010", --0xN0A8
		THRES_LO_5&X"00"&THRES_LO_4&X"00" when "0000101011", --0xN0AC
		X"000"&PG&IE when "0000101100", --0xN0B0
		"00000"&THRES_HI_2&THRES_HI_1&THRES_HI_0 when "0000101101", --0xN0B4
		"00000"&THRES_HI_5&THRES_HI_4&THRES_HI_3 when "0000101110", --0xN0B8
		
		(others => '-') when others;
			
			--csr <= X"0000000"&"000"&RESET_N; -- TRIGER_NUMBER_D(2 downto 0) 
	   
-------------- FE write REG SPACE ---------------------------------------
  process(sclk_B)
   begin
      if sclk_B'event and sclk_B='1' then
		
		if cwr='1' and ca="0001"&"0000000001" then
			csr(31 downto 0) <= cwd(31 downto 0); --csr(0) used to be RESET_N
		end if;
		
		if cwr='1' and ca="0001"&"0000010110" then -- 0x1058
			PTW_WORDS <= cwd(9 downto 0);
		end if;
		
		if cwr='1' and ca="0001"&"0000010111" then -- 0x105C
			LookBack <= cwd(15 downto 0);
		end if;
		
		if cwr='1' and ca=cab&"0000011100" then --0xN070
			TET0 <= cwd(11 downto 0);
		end if;
		
		if cwr='1' and ca=cab&"0000011101" then --0xN074
			TET1 <= cwd(11 downto 0);
		end if;
		
		if cwr='1' and ca=cab&"0000011110" then --0xN078
			TET2 <= cwd(11 downto 0);
		end if;
		
		if cwr='1' and ca=cab&"0000011111" then --0xN07C
			TET3 <= cwd(11 downto 0);
		end if;
		
		if cwr='1' and ca=cab&"0000100000" then --0xN080
			TET4 <= cwd(11 downto 0);
		end if;
		
		if cwr='1' and ca=cab&"0000100001" then --0xN084
			TET5 <= cwd(11 downto 0);
		end if;
		---------------				
		if cwr='1' and ca="0001"&"0000100010" then --0x1088
			CONFIG1 <= cwd(15 downto 0);
		end if;
		---------------				
		if cwr='1' and ca=cab&"0000100100" then --0xN090
			CONFIG2 <= cwd(15 downto 0);
		end if;
		---------------				
--		if cwr='1' and ca=cab&"0000100101" then --0xN094
--			PPG_DAT_IN <= cwd(15 downto 0);	
--		end if;
--		---------------				
--		if cwr='1' and ca="0001"&"0000100110" then --0x1098
--			PPG_trig <= cwd(1 downto 0);	
--		end if;
--		---------------				
--		if cwr='1' and ca="0001"&"0000100111" then --0x109C
--			PPG_trig_delay_width <= cwd(11 downto 0);	
--		end if;
		---------------	NEW REGS ------------------------			
		if cwr='1' and ca="0001"&"0000101000" then --0x10A0
			NP <= cwd(7 downto 0);
			NP2 <= cwd(15 downto 8);
			IBIT <=	cwd(18 downto 16);
			ABIT <=	cwd(21 downto 19);
			rPBIT <= cwd(24 downto 22);
			PSIGN <= cwd(25);
		end if;		
		---------------				
		if cwr='1' and ca=cab&"0000101001" then --0xN0A4
			--THRES_HI_0 <= cwd(7 downto 0);
			THRES_LO_0 <= cwd(15 downto 8);
			--THRES_HI_1 <= cwd(23 downto 16);
			THRES_LO_1 <= cwd(31 downto 24);	
		end if;
		---------------				
		if cwr='1' and ca=cab&"0000101010" then --0xN0A8
			--THRES_HI_2 <= cwd(7 downto 0);
			THRES_LO_2 <= cwd(15 downto 8);
			--THRES_HI_3 <= cwd(23 downto 16);
			THRES_LO_3 <= cwd(31 downto 24);
		end if;
		---------------							
		if cwr='1' and ca=cab&"0000101011" then --0xN0AC
			--THRES_HI_4 <= cwd(7 downto 0);
			THRES_LO_4 <= cwd(15 downto 8);
			--THRES_HI_5 <= cwd(23 downto 16);
			THRES_LO_5 <= cwd(31 downto 24);
		end if;	  
		---------------				
		if cwr='1' and ca="0001"&"0000101100" then --0x10B0
			IE <= cwd(11 downto 0);
			PG	<= cwd(19 downto 12);
		end if;
		---------------				
		if cwr='1' and ca="0001"&"0000101101" then --0x10B4
			THRES_HI_0 <= cwd(8 downto 0);
			THRES_HI_1 <= cwd(17 downto 9);
			THRES_HI_2 <= cwd(26 downto 18);
		end if;
		---------------				
		if cwr='1' and ca="0001"&"0000101110" then --0x10B8
			THRES_HI_3 <= cwd(8 downto 0);
			THRES_HI_4 <= cwd(17 downto 9);
			THRES_HI_5 <= cwd(26 downto 18);
		end if;
		
		
      end if;
   end process;	
   

	PBIT <= NP2(2 downto 0) - rPBIT when (PSIGN = '1' and (NP2 >= rPBIT)) else   
			NP2(2 downto 0) + rPBIT	when  PSIGN = '0';
		
   
 --  uPBIT : process (aclk_B)
--	begin
--		if (aclk_B = '1' and aclk_B'event) then --aclk
--		
--			if (PSIGN = '1' and NP2 >= rPBIT) then
--				PBIT <= NP2(2 downto 0) - rPBIT;
--			end if;
--			
--			if (PSIGN = '0') then
--				PBIT <= NP2(2 downto 0) + rPBIT;
--			end if;	
--		
--		end if;
--	end process uPBIT;

--	csr(0) <= RESET_N;
-------------- end FE REG SPACE -----------------------------------


--		wrt_stb_D <= '1' when (cwr ='1' and ca=cab&"0000100101") else '0';
--		wrt_stb_2D <= '1' when wrt_stb_D = '1' and  wrt_stb_Q ='0' else '0';
		
		--go_pulse <= PPG_trig(0) when (cwr = '1' and ca="0001"&"0000100110") else '0';
		--pulser_trig_delay <= PPG_trig(1) when (cwr = '1' and ca="0001"&"0000100110") else '0';
		--go_pulse_trig <= go_pulse and pulser_trig_delay;

--		test_mode_on <= CONFIG1(7);
		
--		sync_enable <= csr(2);
--		SYNC <= '1' when (RESET_N = '0' and sync_enable = '1') else '0';
		
		
-- top level from 250 processing    
    algo: ADC_PROC_TOP
      port map (
			CLK => aclk_B, --CLK_125, --aclk, -- 125 Mhz for fADC125 --aclk
			--CLK_80 => rclk_B, --rclk,	  -- may need back for playback
			RESET_N => RESET_N, -- RESET_N 

			--- To Host 
			--DATA_BUFFER_RDY_REG => DATA_BUFFER_RDY_REG, -- need to create reg 
			TRIGGER => TRIGGER, --feWriterCmd_Q, --feWriterCmd, -- from processor FPGA, all I have for trig. have to consider DELAY setting! may need to tune it...
			TRIGGER2 => TRIGGER2,  --- for PPG play Back -- N/A, don't have on FE... yet	
			NumberOfTriggerInFifo_OUT => NumberOfTriggerInFifo_OUT,
			--SYNC => SYNC, --not RESET_N, --SYNC, -- Use sync once enable reg is -- using reset
			--  don't have syncs, what up wih that? Answer: sync comes from Proc should put sync enable here instead of main, sync on all reset for now(including sync from proc)
			--- FROM ADC  ************

			--adcclko => adcclko, -- used for all 6 ADCs, comes from one of three adc chips, middle 2 channels, also not differential
			ADC1_DATA => adca_Q, --iadca_Q, --adca_Q, --adca, --ADC_DATA,--adca(13 downto 2), -- not differential,  ends up being ADC_RAWDATA_1 so delete converter
			ADC2_DATA => adcb_Q, --iadcb_Q, --adcb_Q, --adcb, --ADC_DATA,--adcb(13 downto 2),
			ADC3_DATA => adcc_Q, --iadcc_Q, --adcc_Q, --adcc, --ADC_DATA,--adcc(13 downto 2),
			ADC4_DATA => adcd_Q, --iadcd_Q, --adcd_Q, --adcd, --ADC_DATA,--adcd(13 downto 2),
			ADC5_DATA => adce_Q, --iadce_Q, --adce_Q, --adce, --ADC_DATA,--adce(13 downto 2),
			ADC6_DATA => adcf_Q, --iadcf_Q, --adcf_Q, --adcf, --ADC_DATA,--adcf(13 downto 2),
			-------- Only need 6 channels if will fit on FE FPGA ------------------------ 

			--- To control bus Status register
			--TRIGGER_NUMBER_REG => TRIGGER_NUMBER_REG, --

			--- To control bus Registers
			PTW => PTW_WORDS,--PTW(11 downto 0), -- window width
			CONFIG1 => CONFIG1, --CONFIG1(15 downto 4)&COLLECT_ON&CONFIG1(2 downto 0), -- X"00"&"0001"&COLLECT_ON&"111",	-- MODES
			CONFIG2 => CONFIG2, --X"003F", --X"001F", --CONFIG2, -- 

			PL => LookBack, --"00000"&LATENCY_WORD,
			-- Hit thresholds 
			TET0 => TET0, --X"0400", --X"0"&TET0, --TET0, --      
			TET1 => TET1, --X"0200", --X"0"&TET1, --TET1, --      
			TET2 => TET2, --X"0400", --X"0"&TET2, --TET2, --       
			TET3 => TET3, --X"0400", --X"0"&TET3, --TET3, --      
			TET4 => TET4, --X"0400", --X"0"&TET4, --TET4, --      
			TET5 => TET5, --X"0400", --X"0"&TET5, --TET5, --  
			
			NP	=> NP,
			NP2	=> NP2,
			
			IBIT => IBIT,				
			ABIT => ABIT,
			PBIT => PBIT,
			
		-- NEW REGS
    		THRES_HI_0		=> THRES_HI_0,
    		THRES_LO_0		=> THRES_LO_0,
			
    		THRES_HI_1		=> THRES_HI_1,
    		THRES_LO_1		=> THRES_LO_1,
			
    		THRES_HI_2		=> THRES_HI_2,
    		THRES_LO_2		=> THRES_LO_2,
    		
			THRES_HI_3		=> THRES_HI_3,
    		THRES_LO_3		=> THRES_LO_3,
			
    		THRES_HI_4		=> THRES_HI_4,
    		THRES_LO_4		=> THRES_LO_4,
			
    		THRES_HI_5		=> THRES_HI_5,
    		THRES_LO_5		=> THRES_LO_5,			
			
			IE				=> IE,
			PG				=> PG, 
			
			--ExceedNumberOfMaxTrigger_REG => ExceedNumberOfMaxTrigger_REG,
			
			cid => cid, --cid_Q, --cid,
			FIFO_DATA => FIFO_DATA_D, 
			FIFO_WEN => FIFO_WEN_D -- Write EN
			);

--------------------------------------------------------------------------------------------------------------------------
-- new version is using 32 bit to 16 bit for the daisy chain. This allows the write enable to be transmitted alongside the data
-- soucre syncronously. The repective tags will be inserted on the proc/evbd side. 
-- rd clk is now 125 Mhz
--------------------------------------------------------------------------------------------------------------------------				

	UFE_OUT_FIFO : NEW_FIFO_4096 --1024x36 2048x18, 
		  PORT MAP
				(
					 rst => RESET, --not RESET_N,
					 wr_clk => aclk_B, --FIFO_WCLK_Q, -- state driven from ADC_PROC_TOP (125Mhz sync)
					 rd_clk => aclk_B, --rclk_B, -- CHANGE
					 din => FIFO_DATA_Q, -- 32 bit data from ADC_PROC_TOP
					 wr_en => FIFO_WEN_Q, -- state driven from ADC_PROC_TOP, logic flipped from intended HW useage 
					 rd_en => fe_rd_en, -- read enable from PROC AND token
					 dout => fe_data_out, -- 16 bit data to daisy chain
					 full => open, --fe_outfifo_full, --open,
					 empty => fe_outfifo_empty
				);
			
--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------

--			EVENT_done <= '1' when ((FIFO_DATA_D(35 downto 0) = "0010"&X"E8000000") and (FIFO_WEN_D = '1')) else '0'; --"0010"&x"E8000000" 	
--			EVENT_done <= '1' when ((FIFO_DATA_D = X"E8000000") and (FIFO_WEN_D = '1')) else '0';
			EVENT_done <= '1' when ((FIFO_DATA_Q = X"E8000000") and (FIFO_WEN_Q = '1')) else '0';
			EVENT_done_D <= EVENT_done;
			pEVENT_done <= '1' when (EVENT_done_D = '1' and EVENT_done_Q = '0') else '0';

--	EV_CNT_REG : process (aclk_B)
--        begin
--         if (aclk_B = '1' and aclk_B'event) then --aclk
--			if EVENT_done = '1' and Read_done = '0' then
--				EVENT_CNT_D <= EVENT_CNT_Q + 1;
--			end if;
--			
--			if Read_done = '1' and EVENT_done = '0' then
--				EVENT_CNT_D <= EVENT_CNT_Q - 1;
--			end if;	
--			
--			if EVENT_CNT_Q > 0 then
--				Event_Go <= '1';
--			else 
--				Event_Go <= '0';
--			end if;
--        end if;
--        end process EV_CNT_REG;


		EVENT_CNT_D <= EVENT_CNT_Q + 1 when (pEVENT_done = '1' and pRead_done = '0') else --EVENT_done = '1' and Read_done = '0' CHANGE
					   EVENT_CNT_Q - 1 when (pRead_done = '1' and pEVENT_done = '0') else --Read_done = '1' and EVENT_done = '0' CHANGE
					   EVENT_CNT_Q;
					   
		Event_Go <= '1' when  EVENT_CNT_Q > 0 else '0';


			fe_rd_en_D <= '1' when FeRdCmd_Q = '1' and Hold_Token = '1' else '0';
			fe_rd_en <= fe_rd_en_Q;
				
			trail_cnt_D <= trail_cnt_Q + 1 when fe_rd_en = '1'  else
						   X"00000000" 	   when Read_done_Q = '1' else --Read_done CHANGE
						   trail_cnt_Q;

--			Read_done <= '1' when fe_data_out = "00"&x"BA00" and trail_cnt_D(0) = '1' else '0'; --fe_data_out --change
			Read_done <= '1' when fe_data_out = X"E800" and trail_cnt_D(0) = '1' else '0';
			Read_done_D <= Read_done;
			pRead_done <= '1' when (Read_done_D = '1' and Read_done_Q = '0') else '0';


	UFE_TOKEN : FE_TOKEN_2
			PORT MAP 
				(
				CLK => aclk_B, --rclk_B,   --CHANGE
				evbTokIn => evbTokIn_BUF1_Q, -- daisy chain token pass
				Event_Go => Event_Go, --EVENT_Go_BUF2_Q, -- atleast 1 event stored, i.e. trailer from adc_proc_top seen
				FERDBUSY => FERDBUSY, --"FERDBUSY" is used to tell PROC data is here so PROC can send rd_en
				Read_Done => pRead_done, -- i.e. trailer has been seen leaving FE FIFO --Read_done CHANGE
				Clear_Token => CLEAR_TOKEN, --not evbTokIn_BUF1_Q,--not evbTokIn, -- token is pulled from PROC side after all channels report
				RESET_N => RESET_N, -- 
				Hold_Token => Hold_Token, -- keeps the token untill all chips in daisy report, then PROC clears for all FE chips
				Send_Token => Send_Token -- token kept and also sent to next FE chip in chain, untill PROC clears all
				);
					
			evbTokIn_BUF1_D <=  evbTokIn;
			CLEAR_TOKEN <= not evbTokIn_BUF1_Q;
			
			evbTokOut1_D <= '1' when (evbTokIn_BUF1_Q = '1' and Send_Token = '1') else '0'; --evbTokIn='1'
			evbTokOut2_D <= evbTokOut1_Q; 
			
			--evbTokOut <= evbTokOut1_Q when evbTokOut1_Q_B = '1' else '0'; 
			evbTokOut <= evbTokOut2_Q when evbTokOut2_Q_B = '1' else '0'; 
				
			FERDBUSY_BUF1_D <= not FERDBUSY;	
			FERDBUSY_N_A <= not FERDBUSY_BUF1_D; 
			FERDBUSY_N_C <= '1' when (FERDBUSY_N_A = '1' or FERDBUSY_N_B = '1') else '0'; 
			FERDBUSY_N <= FERDBUSY_BUF1_Q when FERDBUSY_N_C_Q = '1' else 'Z';

--------------------------------------------------------------------------------------------------------------------  
-- NEW DAISY CHAIN WRITE EN : NOW PASSED WITH DATA ON BUS		
--------------------------------------------------------------------------------------------------------------------	

	IO_REG : process (aclk_B)
	begin 	
--        if RESET_N = '0' then
--			evbDin_Q <= (others => '0');
--			evbDout_Q <= (others => '0');
--		els
		if (aclk_B = '1' and aclk_B'event) then --aclk 	

			if fe_rd_en = '1' then 
				--evbDin_D <= "00" & X"0000";
				evbDout_D <= "01" & fe_data_out;
			else 
				--evbDin_D <= evbDin;
				evbDout_D <= evbDin_Q; 
			end if;
				
			evbDin_Q <= evbDin; 

			evbDout_Q <= evbDout_D;
			evbDout <= evbDout_Q;
				
		end if;
	end process IO_REG;
			
			
	sample_REG : process (aclk_B)
		begin 	
		if (aclk_B = '1' and aclk_B'event) then --aclk 		
			
			adca_Q <= adca_D;
			adcb_Q <= adcb_D;
			adcc_Q <= adcc_D;
			adcd_Q <= adcd_D;
			adce_Q <= adce_D;
			adcf_Q <= adcf_D;	
				
--			iadca_Q <= iadca_D;
--			iadcb_Q <= iadcb_D;
--			iadcc_Q <= iadcc_D;
--			iadcd_Q <= iadcd_D;
--			iadce_Q <= iadce_D;
--			iadcf_Q <= iadcf_D;	
			
		end if;
	end process sample_REG;


	REG : process (aclk_B, RESET_N) 
      begin
        if RESET_N = '0' then
						
			FERDBUSY_BUF1_Q <= '1';
			CHECK_RESET <= CHECK_RESET + 1;

			EVENT_CNT_Q <= (others => '0');
			
			trail_cnt_Q <= (others => '0');
			
			--wrt_stb_Q <= '0';
			
--			adca_Q <= (others => '0');
--			adcb_Q <= (others => '0');
--			adcc_Q <= (others => '0');
--			adcd_Q <= (others => '0');
--			adce_Q <= (others => '0');
--			adcf_Q <= (others => '0'); 

			feWriterCmd_Q <= '0'; -- changed to 0 here because logic has already been flipped from input 
			EVBHOLD_Q <= '0';  
			evbTokIn_BUF1_Q <= '0'; 
			
			FIFO_DATA_Q <= (others => '0'); 
			
        elsif (aclk_B = '1' and aclk_B'event) then --rclk_B
			
--			fe_rd_en_BUF1_Q <= fe_rd_en_BUF1_D;
--			fe_rd_en_BUF2_Q <= fe_rd_en_BUF2_D;

			evbTokIn_BUF1_Q <= evbTokIn_BUF1_D;
			--evbTokIn_BUF2_Q <= evbTokIn_BUF2_D;
			
			evbTokOut1_Q <= evbTokOut1_D;
			evbTokOut2_Q <= evbTokOut2_D;
			
			evbTokOut1_Q_B <= evbTokOut1_D;
			evbTokOut2_Q_B <= evbTokOut2_D;
			
--			EVENT_Go_BUF1_Q <= EVENT_Go_BUF1_D;
--			EVENT_Go_BUF2_Q <= EVENT_Go_BUF2_D;	
			
			FERDBUSY_BUF1_Q <= FERDBUSY_BUF1_D;
			FERDBUSY_N_B <= FERDBUSY_N_A;
			FERDBUSY_N_C_Q <= FERDBUSY_N_C;			
		
			--FeRdCmd_D <= FeRdCmd;	 --change
			FeRdCmd_Q <= FeRdCmd; --FeRdCmd_D;	
		    fe_rd_en_Q <= fe_rd_en_D;					
			
			--evbDin_D <= evbDin;
--			evbDin_Q <= evbDin; --evbDin_D;
--
--			evbDout_Q <= evbDout_D;
--			evbDout <= evbDout_Q;
						
			EVENT_CNT_Q <= EVENT_CNT_D;
			
			trail_cnt_Q <= trail_cnt_D;
			
--			wrt_stb_Q <= wrt_stb_D;
--			wrt_stb_2Q <= wrt_stb_2D;			

--			adca_Q <= adca_D;
--			adcb_Q <= adcb_D;
--			adcc_Q <= adcc_D;
--			adcd_Q <= adcd_D;
--			adce_Q <= adce_D;
--			adcf_Q <= adcf_D;		

			FIFO_WEN_Q <= FIFO_WEN_D;
			FIFO_DATA_Q <= FIFO_DATA_D;

			feWriterCmd_Q <= feWriterCmd_D;
			EVBHOLD_Q <= EVBHOLD_D;	
			
			Read_done_Q <= Read_done_D;
			EVENT_done_Q <= EVENT_done_D;
			
         end if;
      end process REG;	

	  
end architecture fe_0; 
