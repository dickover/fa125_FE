--  Author:  Hai Dong
--  Filename: DataBuffer_Top.vhd 
--  Date: 5/5/04
--
--  This code does the following:
--      1) Continuously stores ADC samples into RawDataBuffer which is a circular buffer.
--      2) On rising edge of any TrigIn bits, :
--           a: latches address of RawDataBuffer. 
--           b) in TrigCapture_Top stores TrigIn, Trigger Number, Time Stamp, and Latched Address of RawDataBuffer. Increment NumberOfTriggerInFifo_REG in TrigCapture_Top
--           c) Read TrigIn, Trigger Number, Time Stamp, and Latched Address of RawDataBuffer from TrigCapture_Top.
--           d) Stores TrigIn, Trigger Number, Time Stamp, and Latched Address of RawDataBuffer from TrigCapture_Top to UFIFO18_header.
--           e) Stores TrigIn to all 16 UDataBuffer(I).
--           f) Read number of (WindowWidth + 1) ADC_Data samples of from RawDataBuffer and stores them to UDataBuffer(I) which are circular buffer
--           g) Increment NumberOfBufDataCnt_REG.
--           h) If either NumberOfBufDataCnt_REG or NumberOfTriggerInFifo_REG is equal to MaxNumberOfTrigger, ExceedNumberOfMaxTrigger_REG goes high.  
--              ExceedNumberOfMaxTrigger_REG goes low when SYNC = '1'
--
--   HeaderFifoData_REG:
--     1) HeaderFifoData_REG contains the header information: 
--                    ChanHasTrig    which is = to TrigIn(3) & TrigIn(3) & TrigIn(3) & TrigIn(3) & TrigIn(2) & TrigIn(2) & TrigIn(2) & TrigIn(2)& TrigIn(1) & TrigIn(1) & TrigIn(1) & TrigIn(1) & TrigIn(0) & TrigIn(0) & TrigIn(0) & TrigIn(0) 
--                    CapturedTrigNum(15  downto 0)
--                    CapturedTimeStamp(47 downto 32)
--                    CapturedTimeStamp(31 downto 16)
--                    CapturedTimeStamp(15 downto 0)
--     2) The latency from rising edge of HeaderFifoRdEn to HeaderFifoData_REG is 3 CLK
--     3) To read these info;
--           1) Bring HeaderFifoRdEn high
--           2) Wait 3 CLK.
--           3) Read ChanHasTrig, 
--           4) Read CapturedTrigNum(15  downto 0). Bring HeaderFifoRdEn low.
--           5) REad CapturedTimeStamp(47 downto 32)
--           6) REad CapturedTimeStamp(31 downto 16)
--           7) REad CapturedTimeStamp(15 downto 0)
--     4) These info can be read at Data Format stage rather at the Processing Stage     
--     
--  ADC_Buffer_Data_REG: 
--         1) REset ADC_Buffer_Data_RdAdr at power up and at SYNC.
--         2) ADC_Buffer_Data_REG contains ChanHasTrig and number of (WindowWidth + 1) ADC_Data samples to be processed by Processing Algorithm.
--         3) When NumberOfBufDataCnt_REG is not zero, there is data in ADC_Buffer_Data_REG.
--         4) Read ChanHasTrig.
--         5) Increment  ADC_Buffer_Data_RdAdr and read ADC_Data Sample for (WindowWidth + 1) ADC_Buffer_Data_RdAdr address/
--         6) increment ADC_Buffer_Data_RdAdr to be ready for next trigger.
--
--
--   MaxNumberOfTrigger is the smaller of 200 or:
--           int(1024 / (WindowWidth+1))
--                
--   TrigCapture_Top can capture up to 32 consecutive TrigIn.              

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_unsigned.all; 
  use IEEE.std_logic_arith.all;
  
library work;
    use work.package_EFACV2.all; 
--    use work.package_oneshot.all; 

-- synthesis translate_off
library UNISIM;
use UNISIM.all;
-- synthesis translate_on

entity DataBuffer_Top is
        port
         (
				CLK                  			: in std_logic;  
				RESET_N              			: in std_logic;
				SYNC                 			: in std_logic;

				TrigIn                  		: in std_logic;  -- latched on rising edge of any, clear when data is stored in ROM
				--Adc_Data                		: in slv13_array(5 downto 0);  --- connect to ADC's sample data	-- CHANGE for 6 CH 
				Adc_Data_0                		: in std_logic_vector(11 downto 0);  --- connect to ADC's sample data	-- CHANGE for 6 CH 	
				Adc_Data_1                		: in std_logic_vector(11 downto 0);  --- connect to ADC's sample data	-- CHANGE for 6 CH 	
				Adc_Data_2                		: in std_logic_vector(11 downto 0);  --- connect to ADC's sample data	-- CHANGE for 6 CH 		
				Adc_Data_3                		: in std_logic_vector(11 downto 0);  --- connect to ADC's sample data	-- CHANGE for 6 CH 		
				Adc_Data_4                		: in std_logic_vector(11 downto 0);  --- connect to ADC's sample data	-- CHANGE for 6 CH 	
				Adc_Data_5                		: in std_logic_vector(11 downto 0);  --- connect to ADC's sample data	-- CHANGE for 6 CH 		
					
				lookback						: in std_logic_vector(10 downto 0);
				WindowWidth             		: in std_logic_vector(9 downto 0);  --- Number of samples in Window
				--PTW_DONE							: out std_logic;

				MaxNumberOfTrigger      		: in std_logic_vector(7 downto 0);  --- When NumberOfBufDataCnt_REG = this or NumberOfTriggerInFifo_REG = this, ExceedNumberOfMaxTrigger_REG goes high,
				DecNumberOfTriggerInTrigFifo	: in std_logic; --- rising edge decrement NumberOfTriggerInFifo_REG which is the number of trigger that are in UTrig_fifo_79_32 in TrigCapture_Top
				NumberOfTriggerInFifo_OUT 		: out std_logic_vector(7 downto 0); -- CHANGE
				
				NumberOfBufDataCnt_REG 			: out std_logic_vector(7 downto 0); --- when >0 indicate one or more Buffered Data Window is ready
				DecNumOfBufDatCnt       		: in std_logic; --- rising edge decrement number of buffer NumberOfBufDataCnt_Q
				--ADC_Buffer_Data_RdAdr   		: in  slv10_array(5 downto 0); --- address of UDataBuffer RAM -- CHANGE for 6 CH	 
				ADC_Buffer_Data_RdAdr_0   		: in  std_logic_vector(9 downto 0); --- address of UDataBuffer RAM -- CHANGE for 6 CH
				ADC_Buffer_Data_RdAdr_1   		: in  std_logic_vector(9 downto 0); --- address of UDataBuffer RAM -- CHANGE for 6 CH
				ADC_Buffer_Data_RdAdr_2   		: in  std_logic_vector(9 downto 0); --- address of UDataBuffer RAM -- CHANGE for 6 CH
				ADC_Buffer_Data_RdAdr_3   		: in  std_logic_vector(9 downto 0); --- address of UDataBuffer RAM -- CHANGE for 6 CH
				ADC_Buffer_Data_RdAdr_4   		: in  std_logic_vector(9 downto 0); --- address of UDataBuffer RAM -- CHANGE for 6 CH
				ADC_Buffer_Data_RdAdr_5   		: in  std_logic_vector(9 downto 0); --- address of UDataBuffer RAM -- CHANGE for 6 CH	
					
				--ADC_Buffer_Data_REG     		: out slv16_array(5 downto 0); --- output of UDataBuffer RAM. It has Channel Has Data indicator and ADC sample -- CHANGE for 6 CH 
				ADC_Buffer_Data_REG_0     		: out std_logic_vector(11 downto 0); 
				ADC_Buffer_Data_REG_1     		: out std_logic_vector(11 downto 0);
				ADC_Buffer_Data_REG_2     		: out std_logic_vector(11 downto 0);
				ADC_Buffer_Data_REG_3     		: out std_logic_vector(11 downto 0);
				ADC_Buffer_Data_REG_4     		: out std_logic_vector(11 downto 0);
				ADC_Buffer_Data_REG_5     		: out std_logic_vector(11 downto 0);

				HeaderFifoRdEn          		: in std_logic; --- Read UFIFO18_header TrigIn, Trigger Number, Time Stamp, and Latched Address of RawDataBuffer
				HeaderFifoHasData_REG   		: out std_logic; --- 1 indicate UFIFO18_header has data 
				HeaderFifoData_REG      		: out std_logic_vector(15 downto 0);
				ExceedNumberOfMaxTrigger_REG 	: out std_logic
        );
end DataBuffer_Top;

architecture RTL of DataBuffer_Top is

    component RawDataBuffer
        port
         (
           CLK                  : in std_logic;  
           RESET_N              : in  std_logic;
           SYNC                 : in  std_logic;
           OrTrig              	: in  std_logic;

           RawDataRdAdr   		: in std_logic_vector(9 downto 0);
           RawDataRdEn        	: in std_logic;
           
--           Adc_Data             : in slv13_array(5 downto 0);  --- connect to ADC's sample data -- CHANGE for 6 CH
           Adc_Data             : in std_logic_vector(11 downto 0);  --- connect to ADC's sample data -- CHANGE for 6 CH
--           RAM_ADC_Data_DO_REG  : out slv13_array(5 downto 0); --- output of RAM  -- CHANGE for 6 CH 
           RAM_ADC_Data_DO_REG  : out std_logic_vector(11 downto 0); --- output of RAM  -- CHANGE for 6 CH

           RawDataTrigAdr_REG   : out std_logic_vector(9 downto 0)  --- Address of RAM on rising edge of OrTrig

        );
    end component;

    component TrigCapture_Top
        port
         (
           CLK                  			: in std_logic;  
           RESET_N              			: in  std_logic;
           SYNC                 			: in std_logic;

           TrigIn                  			: in std_logic;
           DecNumberOfTriggerInTrigFifo   	: in std_logic; --- 
           Raw_Address             			: in std_logic_vector(10 downto 0);
           Trig_fifo_Rd_en         			: in std_logic;

           --- To Host
           OrTrig_REG              			: out  std_logic;
           TrigBufHasData_REG      			: out std_logic; --- 1 indicate there a trigger ready for process
           TriBufData_REG          			: out std_logic_vector(78 DOWNTO 0);  --- fifo_79_32 data. TrigIn_Q, Trigger Number, Time Stamp
           NumberOfTriggerInFifo_REG      	: out std_logic_vector(7 downto 0)  --- 
        );
    end component;

--  component DpRam_16_1K
--	  PORT (
--		 clka 	: IN STD_LOGIC;
--		 wea 		: IN STD_LOGIC_VECTOR(0 DOWNTO 0);
--		 addra 	: IN STD_LOGIC_VECTOR(9 DOWNTO 0);
--		 dina 	: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
--		 clkb 	: IN STD_LOGIC;
--		 addrb 	: IN STD_LOGIC_VECTOR(9 DOWNTO 0);
--		 doutb 	: OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
--	);
--  end component;	

  component DpRam_13_1K
	  PORT (
		 clka 	: IN STD_LOGIC;
		 wea 	: IN STD_LOGIC_VECTOR(0 DOWNTO 0);
		 addra 	: IN STD_LOGIC_VECTOR(9 DOWNTO 0);
		 dina 	: IN STD_LOGIC_VECTOR(11 DOWNTO 0);
		 clkb 	: IN STD_LOGIC;
		 addrb 	: IN STD_LOGIC_VECTOR(9 DOWNTO 0);
		 doutb 	: OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
	);
  end component;

	component HEADER_16_1K 
	  PORT (
		 clk 		: IN STD_LOGIC;
		 srst 	: IN STD_LOGIC;
		 din 		: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		 wr_en 	: IN STD_LOGIC;
		 rd_en 	: IN STD_LOGIC;
		 dout 	: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		 full 	: OUT STD_LOGIC;
		 empty 	: OUT STD_LOGIC
	  );
	END component;

 component DATBUFSM
	PORT (
		CLK,
		RESET_N,
		TrigBufHasData,
		WindowWdCntTc: IN std_logic;
		HeaderFifoWrEn,
		IDLE,
		IncRawDatRdAdr,
		RamBufferWrEn,
		SelCapTrigNumHi,
		SelChanHasTrig,
		SelChanHasTrig2,
		SelTimeStampLo,
		SelTimeStampMid,
		TrigFifoRdEn,
		IncNumOfBufDatCt,
		SelTimeStampHi,
		LdRawDataRdAdr,
		WindowWdCntEn : OUT std_logic);
 end component;
 
 

 --signal SYNC_BUF_Q 		: std_logic_vector(5 downto 0);
  signal SYNC_BUF_Q 		: std_logic;
  signal RawDataTrigAdr :  std_logic_vector(10 downto 0);  --- Address of RAM on rising edge of OrTrig
  signal OrTrigIn       :  std_logic;
  signal TrigBufHasData :  std_logic; --- 1 indicate there a trigger ready for process
  signal TriBufData     :  std_logic_vector(78 DOWNTO 0);
  
  signal RawDataRdAdr_D :  std_logic_vector(9 downto 0);
  signal RawDataRdAdr_Q :  std_logic_vector(9 downto 0);
  signal RawDataRdEn    :  std_logic;

--  signal RAM_ADC_Data_DO    :  slv13_array(5 downto 0); --- output of RAM -- CHANGE for 6 CH	
  signal RAM_ADC_Data_DO_0    :  std_logic_vector(11 downto 0); --- output of RAM -- CHANGE for 6 CH
  signal RAM_ADC_Data_DO_1    :  std_logic_vector(11 downto 0); --- output of RAM -- CHANGE for 6 CH
  signal RAM_ADC_Data_DO_2    :  std_logic_vector(11 downto 0); --- output of RAM -- CHANGE for 6 CH
  signal RAM_ADC_Data_DO_3    :  std_logic_vector(11 downto 0); --- output of RAM -- CHANGE for 6 CH
  signal RAM_ADC_Data_DO_4    :  std_logic_vector(11 downto 0); --- output of RAM -- CHANGE for 6 CH
  signal RAM_ADC_Data_DO_5    :  std_logic_vector(11 downto 0); --- output of RAM -- CHANGE for 6 CH
	  
  --signal ADC_Buffer_Data_RdAdr_D   :  std_logic_vector(9 downto 0);
  signal ADC_Buffer_Data_D_0     : std_logic_vector(11 downto 0); --- output of RAM  -- CHANGE for 6 CH
  signal ADC_Buffer_Data_D_1     : std_logic_vector(11 downto 0); --- output of RAM  -- CHANGE for 6 CH
  signal ADC_Buffer_Data_D_2     : std_logic_vector(11 downto 0); --- output of RAM  -- CHANGE for 6 CH
  signal ADC_Buffer_Data_D_3     : std_logic_vector(11 downto 0); --- output of RAM  -- CHANGE for 6 CH
  signal ADC_Buffer_Data_D_4     : std_logic_vector(11 downto 0); --- output of RAM  -- CHANGE for 6 CH
  signal ADC_Buffer_Data_D_5     : std_logic_vector(11 downto 0); --- output of RAM  -- CHANGE for 6 CH	  
	  
  ----- data read from TrigCapture_Top Fifo
  signal CapturedTrigIn    : std_logic_vector(3 downto 0);
  signal CapturedTrigNum   : std_logic_vector(15 downto 0);
  signal CapturedTimeStamp : std_logic_vector(47 DOWNTO 0);
  signal CapturedRawDataAdr : std_logic_vector(10 downto 0);
  signal HeaderFifoRdEn_Q : std_logic;
  signal NumberOfTriggerInFifo      : std_logic_vector(7 downto 0);  --- When NumberOfBufDataCnt_REG = this,
  --signal NumberOfTriggerInFifo_OUT      : std_logic_vector(7 downto 0);
  
  --- Bufferred Window data
  signal SelChanHasTrig  : std_logic;
  signal ChanHasTrig     : std_logic_vector(15 downto 0);
  signal Ld_RawDataRdAdr  : std_logic; 
  signal Inc_RawDataRdAdr : std_logic;
--  signal RamBufferDataIn_D : slv16_array(5 downto 0); -- CHANGE for 6 CH
--  signal RamBufferDataIn_Q : slv16_array(5 downto 0); -- CHANGE for 6 CH
--  signal RamBufferDataIn_D_0 : std_logic_vector(15 downto 0); -- CHANGE for 6 CH
--  signal RamBufferDataIn_Q_0 : std_logic_vector(15 downto 0); -- CHANGE for 6 CH
--  signal RamBufferDataIn_D_1 : std_logic_vector(15 downto 0); -- CHANGE for 6 CH
--  signal RamBufferDataIn_Q_1 : std_logic_vector(15 downto 0); -- CHANGE for 6 CH
--  signal RamBufferDataIn_D_2 : std_logic_vector(15 downto 0); -- CHANGE for 6 CH
--  signal RamBufferDataIn_Q_2 : std_logic_vector(15 downto 0); -- CHANGE for 6 CH
--  signal RamBufferDataIn_D_3 : std_logic_vector(15 downto 0); -- CHANGE for 6 CH
--  signal RamBufferDataIn_Q_3 : std_logic_vector(15 downto 0); -- CHANGE for 6 CH
--  signal RamBufferDataIn_D_4 : std_logic_vector(15 downto 0); -- CHANGE for 6 CH
--  signal RamBufferDataIn_Q_4 : std_logic_vector(15 downto 0); -- CHANGE for 6 CH
--  signal RamBufferDataIn_D_5 : std_logic_vector(15 downto 0); -- CHANGE for 6 CH
--  signal RamBufferDataIn_Q_5 : std_logic_vector(15 downto 0); -- CHANGE for 6 CH 
	
  signal RamBufferDataIn_D_0 : std_logic_vector(11 downto 0); -- CHANGE for 6 CH
  signal RamBufferDataIn_Q_0 : std_logic_vector(11 downto 0); -- CHANGE for 6 CH
  signal RamBufferDataIn_D_1 : std_logic_vector(11 downto 0); -- CHANGE for 6 CH
  signal RamBufferDataIn_Q_1 : std_logic_vector(11 downto 0); -- CHANGE for 6 CH
  signal RamBufferDataIn_D_2 : std_logic_vector(11 downto 0); -- CHANGE for 6 CH
  signal RamBufferDataIn_Q_2 : std_logic_vector(11 downto 0); -- CHANGE for 6 CH
  signal RamBufferDataIn_D_3 : std_logic_vector(11 downto 0); -- CHANGE for 6 CH
  signal RamBufferDataIn_Q_3 : std_logic_vector(11 downto 0); -- CHANGE for 6 CH
  signal RamBufferDataIn_D_4 : std_logic_vector(11 downto 0); -- CHANGE for 6 CH
  signal RamBufferDataIn_Q_4 : std_logic_vector(11 downto 0); -- CHANGE for 6 CH
  signal RamBufferDataIn_D_5 : std_logic_vector(11 downto 0); -- CHANGE for 6 CH
  signal RamBufferDataIn_Q_5 : std_logic_vector(11 downto 0); -- CHANGE for 6 CH
	  
  signal HeaderData_D : std_logic_vector(15 downto 0);
  signal HeaderData_Q : std_logic_vector(15 downto 0);
  signal RamBufferWrEn_D : std_logic;
  signal RamBufferWrEn_Q : std_logic;
--  signal RamBufferWrEn_Q : std_logic_vector(15 downto 0);
  signal SelCapTrigNumHi : std_logic;
  signal SelCapTrigNumLo : std_logic;
  signal SelTimeStampHi  : std_logic;
  signal SelTimeStampMid : std_logic;
  signal SelTimeStampLo  : std_logic;
  signal TrigFifoRdEn : std_logic;
  signal TrigFifoRdEn_Q : std_logic;
  signal HeaderFifoWrEn_D : std_logic;  
  signal HeaderFifoWrEn_Q : std_logic;
  signal SelChanHasTrig2 : std_logic;  
  signal HeaderFifoData_D      : std_logic_vector(15 downto 0);
  signal HeaderFifoHasData_D   : std_logic;
  signal SelRamBufferWrAdr     : std_logic;
  signal RamBufferWrAdr_D      : std_logic_vector(9 downto 0);
  signal RamBufferWrAdr_Q      : std_logic_vector(9 downto 0);	
  
--  signal RamBufferWrAdr_BUF_Q     : slv10_array(5 downto 0); -- CHANGE for 6 CH 
  signal RamBufferWrAdr_BUF_Q     : std_logic_vector(9 downto 0); -- CHANGE for 6 CH
	  
--  signal ADC_Buffer_Data_RdAdr_Q   : slv10_array(5 downto 0); -- CHANGE for 6 CH 	 
  signal ADC_Buffer_Data_RdAdr_Q_0  : std_logic_vector(9 downto 0); -- CHANGE for 6 CH 
  signal ADC_Buffer_Data_RdAdr_Q_1   : std_logic_vector(9 downto 0); -- CHANGE for 6 CH 
  signal ADC_Buffer_Data_RdAdr_Q_2   : std_logic_vector(9 downto 0); -- CHANGE for 6 CH 
  signal ADC_Buffer_Data_RdAdr_Q_3   : std_logic_vector(9 downto 0); -- CHANGE for 6 CH 
  signal ADC_Buffer_Data_RdAdr_Q_4   : std_logic_vector(9 downto 0); -- CHANGE for 6 CH 
  signal ADC_Buffer_Data_RdAdr_Q_5   : std_logic_vector(9 downto 0); -- CHANGE for 6 CH 	  
	  
  signal WindowWdCntEn  : std_logic;
  signal WindowWdCnt_D  : std_logic_vector(9 downto 0);
  signal WindowWdCnt_Q  : std_logic_vector(9 downto 0);
  signal WindowWdCntTc_D  : std_logic; 
--  signal WindowWdCntTc_Q  : std_logic; 
  signal NumberOfBufDataCnt_D : std_logic_vector(7 downto 0);
  signal NumberOfBufDataCnt_Q : std_logic_vector(7 downto 0);
  signal IncNumOfBufDatCnt : std_logic;
  signal DecNumOfBufDatCnt_D : std_logic; 
  signal DecNumOfBufDatCnt_Q : std_logic; 
  signal PDecNumOfBufDatCnt_D : std_logic; 
  signal PDecNumOfBufDatCnt_Q : std_logic; 
  
  --- Monitor
  signal ExceedNumberOfMaxTrigger_D : std_logic;
  signal ExceedNumberOfMaxTrigger_Q : std_logic;
         
begin    

  --- Monitor
  ExceedNumberOfMaxTrigger_REG <= ExceedNumberOfMaxTrigger_Q;
--  ExceedNumberOfMaxTrigger_D <= '0' when SYNC_BUF_Q = '1' else 
--                                '1' when NumberOfTriggerInFifo = MaxNumberOfTrigger or NumberOfBufDataCnt_Q = MaxNumberOfTrigger else
--                                ExceedNumberOfMaxTrigger_Q;

--  ExceedNumberOfMaxTrigger_D <= '0' when SYNC_BUF_Q = '1' else 
--                                '1' when NumberOfTriggerInFifo >= MaxNumberOfTrigger  else
--                                '0';
										  
	ExceedNumberOfMaxTrigger_D <= '1' when NumberOfTriggerInFifo >= MaxNumberOfTrigger  else '0';	
	NumberOfTriggerInFifo_OUT <= NumberOfTriggerInFifo;
           
  ----- data read from TrigCapture_Top Fifo
  --CapturedTrigIn     <= TriBufData(78 downto 75);
  CapturedTrigNum    <= TriBufData(74 downto 59);
  CapturedTimeStamp  <= TriBufData(58 DOWNTO 11);
  CapturedRawDataAdr <= TriBufData(10 downto 0);

  RawDataTrigAdr(10) <= '0';
  
    UTrigCapture_Top : TrigCapture_Top
        port map
         (
           CLK            					=> CLK,     
           RESET_N     						=> RESET_N,
           SYNC         					=> SYNC_BUF_Q, --SYNC_BUF_Q,  

           TrigIn          					=> TrigIn,
           DecNumberOfTriggerInTrigFifo 	=> DecNumberOfTriggerInTrigFifo,
           Raw_Address     					=> RawDataTrigAdr,
           Trig_fifo_Rd_en 					=> TrigFifoRdEn_Q,
           
           --- To Host
           OrTrig_REG          				=> OrTrigIn,      
           TrigBufHasData_REG  				=> TrigBufHasData,
           TriBufData_REG      				=> TriBufData,
           NumberOfTriggerInFifo_REG 		=> NumberOfTriggerInFifo   
        );
		
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
		
    URawDataBuffer_0 : RawDataBuffer
        port map 
         (
           CLK                  	=> CLK,   
           RESET_N              	=> RESET_N,      
           SYNC                 	=> SYNC_BUF_Q,
           OrTrig              		=> OrTrigIn,

           RawDataRdAdr  			=> RawDataRdAdr_Q,
           RawDataRdEn       		=> '1',


           Adc_Data             	=> Adc_Data_0,  --- connect to ADC's sample data
           
           RAM_ADC_Data_DO_REG  	=> RAM_ADC_Data_DO_0, --- output of RAM 
           RawDataTrigAdr_REG   	=> RawDataTrigAdr(9 downto 0)  --- Address of RAM on rising edge of OrTrig
        ); 
		
    URawDataBuffer_1 : RawDataBuffer
        port map 
         (
           CLK                  	=> CLK,   
           RESET_N              	=> RESET_N,      
           SYNC                 	=> SYNC_BUF_Q,
           OrTrig              		=> OrTrigIn,

           RawDataRdAdr  			=> RawDataRdAdr_Q,
           RawDataRdEn       		=> '1',


           Adc_Data             	=> Adc_Data_1,  --- connect to ADC's sample data
           
           RAM_ADC_Data_DO_REG  	=> RAM_ADC_Data_DO_1, --- output of RAM 
           RawDataTrigAdr_REG   	=> open
        );
		
    URawDataBuffer_2 : RawDataBuffer
        port map 
         (
           CLK                  	=> CLK,   
           RESET_N              	=> RESET_N,      
           SYNC                 	=> SYNC_BUF_Q,
           OrTrig              		=> OrTrigIn,

           RawDataRdAdr  			=> RawDataRdAdr_Q,
           RawDataRdEn       		=> '1',


           Adc_Data             	=> Adc_Data_2,  --- connect to ADC's sample data
           
           RAM_ADC_Data_DO_REG  	=> RAM_ADC_Data_DO_2, --- output of RAM 
           RawDataTrigAdr_REG   	=> open
        ); 
		
    URawDataBuffer_3 : RawDataBuffer
        port map 
         (
           CLK                  	=> CLK,   
           RESET_N              	=> RESET_N,      
           SYNC                 	=> SYNC_BUF_Q,
           OrTrig              		=> OrTrigIn,

           RawDataRdAdr  			=> RawDataRdAdr_Q,
           RawDataRdEn       		=> '1',


           Adc_Data             	=> Adc_Data_3,  --- connect to ADC's sample data
           
           RAM_ADC_Data_DO_REG  	=> RAM_ADC_Data_DO_3, --- output of RAM 
           RawDataTrigAdr_REG   	=> open
        );
		
    URawDataBuffer_4 : RawDataBuffer
        port map 
         (
           CLK                  	=> CLK,   
           RESET_N              	=> RESET_N,      
           SYNC                 	=> SYNC_BUF_Q,
           OrTrig              		=> OrTrigIn,

           RawDataRdAdr  			=> RawDataRdAdr_Q,
           RawDataRdEn       		=> '1',


           Adc_Data             	=> Adc_Data_4,  --- connect to ADC's sample data
           
           RAM_ADC_Data_DO_REG  	=> RAM_ADC_Data_DO_4, --- output of RAM 
           RawDataTrigAdr_REG   	=> open
        );	
		
    URawDataBuffer_5 : RawDataBuffer
        port map 
         (
           CLK                  	=> CLK,   
           RESET_N              	=> RESET_N,      
           SYNC                 	=> SYNC_BUF_Q,
           OrTrig              		=> OrTrigIn,

           RawDataRdAdr  			=> RawDataRdAdr_Q,
           RawDataRdEn       		=> '1',


           Adc_Data             	=> Adc_Data_5,  --- connect to ADC's sample data
           
           RAM_ADC_Data_DO_REG  	=> RAM_ADC_Data_DO_5, --- output of RAM 
           RawDataTrigAdr_REG   	=> open
        );
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------

--	RamBufferDataIn_D_0 <= "000" & RAM_ADC_Data_DO_0; 
--	RamBufferDataIn_D_1 <= "000" & RAM_ADC_Data_DO_1; 
--	RamBufferDataIn_D_2 <= "000" & RAM_ADC_Data_DO_2; 
--	RamBufferDataIn_D_3 <= "000" & RAM_ADC_Data_DO_3; 
--	RamBufferDataIn_D_4 <= "000" & RAM_ADC_Data_DO_4; 
--	RamBufferDataIn_D_5 <= "000" & RAM_ADC_Data_DO_5; 	

	RamBufferDataIn_D_0 <= RAM_ADC_Data_DO_0; 
	RamBufferDataIn_D_1 <= RAM_ADC_Data_DO_1; 
	RamBufferDataIn_D_2 <= RAM_ADC_Data_DO_2; 
	RamBufferDataIn_D_3 <= RAM_ADC_Data_DO_3; 
	RamBufferDataIn_D_4 <= RAM_ADC_Data_DO_4; 
	RamBufferDataIn_D_5 <= RAM_ADC_Data_DO_5; 
	
	U0DataBuffer_DpRam_13_1K : DpRam_13_1K
		 PORT map
		     (
		      clka  => CLK,
		      wea(0) => RamBufferWrEn_Q,
		      addra  => RamBufferWrAdr_BUF_Q,
		      dina   => RamBufferDataIn_Q_0,
		      clkb   => CLK,
		      addrb  => ADC_Buffer_Data_RdAdr_Q_0,
		      doutb  => ADC_Buffer_Data_REG_0
		    ); 
	 
	U1DataBuffer_DpRam_13_1K : DpRam_13_1K
		 PORT map
		     (
		      clka  => CLK,
		      wea(0) => RamBufferWrEn_Q,
		      addra  => RamBufferWrAdr_BUF_Q,
		      dina   => RamBufferDataIn_Q_1,
		      clkb   => CLK,
		      addrb  => ADC_Buffer_Data_RdAdr_Q_1,
		      doutb  => ADC_Buffer_Data_REG_1
		    ); 
  
	U2DataBuffer_DpRam_13_1K : DpRam_13_1K
		 PORT map
		     (
		      clka  => CLK,
		      wea(0) => RamBufferWrEn_Q,
		      addra  => RamBufferWrAdr_BUF_Q,
		      dina   => RamBufferDataIn_Q_2,
		      clkb   => CLK,
		      addrb  => ADC_Buffer_Data_RdAdr_Q_2,
		      doutb  => ADC_Buffer_Data_REG_2
		    ); 

	U3DataBuffer_DpRam_13_1K : DpRam_13_1K
		 PORT map
		     (
		      clka  => CLK,
		      wea(0) => RamBufferWrEn_Q,
		      addra  => RamBufferWrAdr_BUF_Q,
		      dina   => RamBufferDataIn_Q_3,
		      clkb   => CLK,
		      addrb  => ADC_Buffer_Data_RdAdr_Q_3,
		      doutb  => ADC_Buffer_Data_REG_3
		    ); 	
			
	U4DataBuffer_DpRam_13_1K : DpRam_13_1K
		 PORT map
		     (
		      clka  => CLK,
		      wea(0) => RamBufferWrEn_Q,
		      addra  => RamBufferWrAdr_BUF_Q,
		      dina   => RamBufferDataIn_Q_4,
		      clkb   => CLK,
		      addrb  => ADC_Buffer_Data_RdAdr_Q_4,
		      doutb  => ADC_Buffer_Data_REG_4
		    ); 

	U5DataBuffer_DpRam_13_1K : DpRam_13_1K
		 PORT map
		     (
		      clka  => CLK,
		      wea(0) => RamBufferWrEn_Q,
		      addra  => RamBufferWrAdr_BUF_Q,
		      dina   => RamBufferDataIn_Q_5,
		      clkb   => CLK,
		      addrb  => ADC_Buffer_Data_RdAdr_Q_5,
		      doutb  => ADC_Buffer_Data_REG_5
		    ); 
	
		
  --- Bufferred Window data	
  
		DecNumOfBufDatCnt_D <= DecNumOfBufDatCnt; 
		PDecNumOfBufDatCnt_D <= DecNumOfBufDatCnt_D and not DecNumOfBufDatCnt_Q;
						
		NumberOfBufDataCnt_REG <= NumberOfBufDataCnt_Q;

		NumberOfBufDataCnt_D <= (others => '0') 				when SYNC_BUF_Q = '1' else
										NumberOfBufDataCnt_Q + 1 	when IncNumOfBufDatCnt = '1' and PDecNumOfBufDatCnt_Q = '0' else
										NumberOfBufDataCnt_Q - 1 	when IncNumOfBufDatCnt = '0' and PDecNumOfBufDatCnt_Q = '1' else
										NumberOfBufDataCnt_Q;
							 
		RamBufferWrAdr_D    <=  (others => '0') 			when SYNC_BUF_Q = '1' else
										RamBufferWrAdr_Q + 1 	when RamBufferWrEn_D = '1' else
										RamBufferWrAdr_Q;
							
		RawDataRdAdr_D  <=  	CapturedRawDataAdr(9 downto 0) - lookback(9 downto 0)  	when Ld_RawDataRdAdr = '1' else	 -- here is where lookback can be applied? -- change added (- 1) to test 
									RawDataRdAdr_Q + 1 									when Inc_RawDataRdAdr = '1' else
									RawDataRdAdr_Q;
						
-- Don't need this for f125. will remove section along with associated state in DATBUFSM						
--    ChanHasTrig <= CapturedTrigIn(3) & CapturedTrigIn(3) & CapturedTrigIn(3) & CapturedTrigIn(3) & 
--                   CapturedTrigIn(2) & CapturedTrigIn(2) & CapturedTrigIn(2) & CapturedTrigIn(2) & 
--                   CapturedTrigIn(1) & CapturedTrigIn(1) & CapturedTrigIn(1) & CapturedTrigIn(1) & 
--                   CapturedTrigIn(0) & CapturedTrigIn(0) & CapturedTrigIn(0) & CapturedTrigIn(0);
				   
	HeaderData_D <= X"0000"  						when SelChanHasTrig  = '1' else
					--ChanHasTrig                     when SelChanHasTrig  = '1' else	 -- you can remove this one		
					CapturedTrigNum(15  downto 0)   when SelCapTrigNumHi = '1' else
                  	CapturedTimeStamp(47 downto 32) when SelTimeStampHi  = '1' else
                  	CapturedTimeStamp(31 downto 16) when SelTimeStampMid = '1' else
                  	CapturedTimeStamp(15 downto 0);
   
  
UFIFO18_header : HEADER_16_1K 
  port map (
    clk 	=> CLK,
    srst 	=> SYNC_BUF_Q,
    din  	=> HeaderData_Q,
    wr_en 	=> HeaderFifoWrEn_Q,
    rd_en 	=> HeaderFifoRdEn_Q,
    dout 	=> HeaderFifoData_D,
    full 	=> open,
    empty	=> HeaderFifoHasData_D
  );

  
  
  
  
     WindowWdCnt_D <= (WindowWdCnt_Q - 1) when WindowWdCntEn = '1' else WindowWidth - 1; -- to account for starting at 0?????
     WindowWdCntTc_D <= '1' when WindowWdCnt_Q = conv_std_logic_vector(0,10) else '0';
		 
	 --PTW_DONE <= '1' when WindowWdCntTc_D = '0' and WindowWdCntTc_Q = '1' else '0'; 
     --PTW_DONE <= WindowWdCntTc_D; -- change, trying to fix NOEVENT  
		 
--   UDataBuffer : for I in 0 to 5 generate -- change for 6 ch
--        --RamBufferDataIn_D(I) <= ChanHasTrig when SelChanHasTrig2 = '1' else ("000" & RAM_ADC_Data_DO(I)); -- don't need ChanHasTrig make sure to kick out later
--		RamBufferDataIn_D(I) <= ("000" & RAM_ADC_Data_DO(I)); -- can have CH header info here if ever needed
--		
--		UDataBuffer_DpRam_16_1K : DpRam_16_1K
--		 PORT map
--		     (
--		      clka  => CLK,
--		      wea(0) => RamBufferWrEn_Q(I),
--		      addra  => RamBufferWrAdr_BUF_Q(I),
--		      dina   => RamBufferDataIn_Q(I),
--		      clkb   => CLK,
--		      addrb  => ADC_Buffer_Data_RdAdr_Q(I),
--		      doutb  => ADC_Buffer_Data_REG(I)
--		    ); 
--		
--     end generate;

 UDATBUFSM : DATBUFSM
	PORT map
	  (
		CLK     				=> CLK,
		RESET_N 				=> RESET_N,
		TrigBufHasData 	=> TrigBufHasData,
		WindowWdCntTc 		=> WindowWdCntTc_D,
			    
		HeaderFifoWrEn  	=> HeaderFifoWrEn_D,
		IDLE            	=> open,
		IncRawDatRdAdr  	=> Inc_RawDataRdAdr,
		RamBufferWrEn   	=> RamBufferWrEn_D,
		SelCapTrigNumHi 	=> SelCapTrigNumHi,
		SelChanHasTrig  	=> SelChanHasTrig, 
		SelChanHasTrig2 	=> SelChanHasTrig2,
		SelTimeStampLo  	=> SelTimeStampLo,
		SelTimeStampMid 	=> SelTimeStampMid,
		SelTimeStampHi  	=> SelTimeStampHi,
		TrigFifoRdEn    	=> TrigFifoRdEn,
		IncNumOfBufDatCt 	=> IncNumOfBufDatCnt,
		LdRawDataRdAdr  	=> Ld_RawDataRdAdr,
		WindowWdCntEn   	=> WindowWdCntEn
		);


    process (CLK)
      begin
        if rising_edge(CLK) then 
				SYNC_BUF_Q 					<= SYNC;
--				SYNC_BUF_Q(0) 					<= SYNC;
--				SYNC_BUF_Q(1) 					<= SYNC;
--				SYNC_BUF_Q(2) 					<= SYNC;
--				SYNC_BUF_Q(3) 					<= SYNC;
--				SYNC_BUF_Q(4) 					<= SYNC;
--				SYNC_BUF_Q(5) 					<= SYNC;
				RawDataRdAdr_Q 				<= RawDataRdAdr_D;
				--RamBufferDataIn_Q 			<= RamBufferDataIn_D;
				RamBufferDataIn_Q_0 			<= RamBufferDataIn_D_0;
				RamBufferDataIn_Q_1 			<= RamBufferDataIn_D_1;
				RamBufferDataIn_Q_2 			<= RamBufferDataIn_D_2;
				RamBufferDataIn_Q_3 			<= RamBufferDataIn_D_3;
				RamBufferDataIn_Q_4 			<= RamBufferDataIn_D_4;
				RamBufferDataIn_Q_5 			<= RamBufferDataIn_D_5;
				
				TrigFifoRdEn_Q 				<= TrigFifoRdEn;
				HeaderData_Q 					<= HeaderData_D;
				HeaderFifoWrEn_Q 				<= HeaderFifoWrEn_D;
				HeaderFifoData_REG 			<= HeaderFifoData_D;
				HeaderFifoHasData_REG 		<= HeaderFifoHasData_D;
				HeaderFifoRdEn_Q   			<= HeaderFifoRdEn;
				RamBufferWrAdr_Q  			<= RamBufferWrAdr_D;
				--WindowWdCntTc_Q 				<= WindowWdCntTc_D;
				WindowWdCnt_Q 					<= WindowWdCnt_D;
				NumberOfBufDataCnt_Q 		<= NumberOfBufDataCnt_D;              
				DecNumOfBufDatCnt_Q 			<= DecNumOfBufDatCnt_D; 
				PDecNumOfBufDatCnt_Q 		<= PDecNumOfBufDatCnt_D;
				ExceedNumberOfMaxTrigger_Q <= ExceedNumberOfMaxTrigger_D; 
				
				ADC_Buffer_Data_RdAdr_Q_0 <= ADC_Buffer_Data_RdAdr_0;
				ADC_Buffer_Data_RdAdr_Q_1 <= ADC_Buffer_Data_RdAdr_1;
				ADC_Buffer_Data_RdAdr_Q_2 <= ADC_Buffer_Data_RdAdr_2;
				ADC_Buffer_Data_RdAdr_Q_3 <= ADC_Buffer_Data_RdAdr_3;
				ADC_Buffer_Data_RdAdr_Q_4 <= ADC_Buffer_Data_RdAdr_4;
				ADC_Buffer_Data_RdAdr_Q_5 <= ADC_Buffer_Data_RdAdr_5;
				
				RamBufferWrAdr_BUF_Q <= RamBufferWrAdr_Q;
				RamBufferWrEn_Q <= RamBufferWrEn_D;
				
        end if;
      end process;
      
--      BufferArray : for I in 0 to 5 generate -- change for 6 ch
--        process (CLK, RESET_N)
--           begin
--             if rising_edge(CLK) then
--                RamBufferWrAdr_BUF_Q(I) <= RamBufferWrAdr_Q;
--                ADC_Buffer_Data_RdAdr_Q(I) <= ADC_Buffer_Data_RdAdr(I);
--                RamBufferWrEn_Q(I) <= RamBufferWrEn_D;
--			 end if;
--        end process;
--       end generate;
       
        
end RTL;
