--  Author:  Hai Dong
--  Filename: TrigCapture_Top.vhd 
--  Date: 12/1/14
--
--  This code does the following:
--     1) Latched TrigIn to TrigIn_Q on rising edge of any one bit. 
--     2) Or TrigIn_Q to TrigInOr_Q.
--     3) Store TrigIn_Q, Trigger Number, Time Stamp to fifo_79_32 on rising edge of TrigInOr_Q
--     4) Clear TrigIn_Q.
--     5) Increment NumberOfTriggerInFifo_REG.
--     6) Decremnt NumberOfTriggerInFifo_REG on rising edge of DecNumberOfTriggerInTrigFifo 

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_unsigned.all; 
  use IEEE.std_logic_arith.all;
  
--library work;
    --use work.package_host.all; 
--    use work.package_oneshot.all; 

entity TrigCapture_Top is
        port
         (
           CLK                  : in std_logic;  --
           RESET_N              : in  std_logic;
           SYNC                 : in std_logic;

           TrigIn                  : in std_logic;  -- latched on rising edge of any, clear when data is stored in ROM
           Trig_fifo_Rd_en         : in std_logic;
           Raw_Address             : in std_logic_vector(10 downto 0);
           DecNumberOfTriggerInTrigFifo      : in std_logic; --- When NumberOfBufDataCnt_REG = this,

           --- To Host
           OrTrig_REG              : out  std_logic;
           TrigBufHasData_REG      : out std_logic; --- 1 indicate there a trigger ready for process, fifo_79_32 has data
           TriBufData_REG          : out std_logic_vector(78 DOWNTO 0);  --- fifo_79_32 data. TrigIn_Q, Trigger Number, Time Stamp
           NumberOfTriggerInFifo_REG      : out std_logic_vector(7 downto 0)  --- When NumberOfBufDataCnt_REG = this,

        );
end TrigCapture_Top;

architecture RTL of TrigCapture_Top is

  component fifo_79_32
  PORT (
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(78 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(78 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC
  );
  END component;

  component time_stamp
  PORT (
    b : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    clk : IN STD_LOGIC;
    sclr : IN STD_LOGIC;
    q : OUT STD_LOGIC_VECTOR(47 DOWNTO 0)
  );
  end component;

  component TrigNum_Top
        port
         (
           CLK                  : in std_logic;  --
           RESET_N              : in  std_logic;
           SYNC         : in std_logic;

           ---- Ports for testing
           CountEn                  : in std_logic;

           --- To Host
           TrigNum_REG      : out std_logic_vector(15 downto 0) --- 1 indicate there a trigger ready for process
        );
  end component;    

 

--  signal TrigIn_D                  : std_logic_vector(3 downto 0);
--  signal TrigIn_Q                  : std_logic_vector(3 downto 0);
  signal TrigInDly_Q               : std_logic_vector(3 downto 0) := X"0";
  signal TrigInOr_D                : std_logic := '0'; 
  signal TrigInOr_Q                : std_logic := '0';
  signal PTrigInOr_D                : std_logic := '0';
  signal PTrigInOr_Q                : std_logic := '0';
  signal PTrigInOr_DLY_Q           : std_logic_vector(3 downto 0) := X"0";
--  signal Trigger_D                 : std_logic_vector(3 downto 0);
--  signal Trigger_Q                 : std_logic_vector(3 downto 0);
--  signal PTrigger_D                 : std_logic_vector(3 downto 0);
--  signal PTrigger_Q                 : std_logic_vector(3 downto 0);

  signal TrigIn_D                  : std_logic := '0';
  signal TrigIn_Q                  : std_logic := '0';
--  signal TrigInDly_Q               : std_logic;
  
--  signal PTrigInOr_DLY_Q           : std_logic;
  signal Trigger_D                 : std_logic := '0';
  signal Trigger_Q                 : std_logic := '0';
  signal PTrigger_D                 : std_logic := '0';
  signal PTrigger_Q                 : std_logic := '0';
  
  signal TimeStamp_D :  std_logic_vector(47 DOWNTO 0);
  signal TimeStamp_Q :  std_logic_vector(47 DOWNTO 0);
  signal TrigNum_D   :  std_logic_vector(15 downto 0); --- 1 indicate there a trigger ready for process
  signal TrigNum_Q   :  std_logic_vector(15 downto 0); --- 1 indicate there a trigger ready for process

  --signal Raw_Address_D : std_logic_vector(10 downto 0);
  signal Raw_Address_Q : std_logic_vector(10 downto 0);
  
  signal Reset : std_logic;
  
  signal UTrig_fifo_Din   : STD_LOGIC_VECTOR(78 DOWNTO 0);
  signal UTrig_fifo_Dout  : STD_LOGIC_VECTOR(78 DOWNTO 0);
  signal UTrig_fifo_Empty : std_logic;
  signal UTrig_fifo_Full  : std_logic;
  --signal TrigEn           : std_logic_vector(3 downto 0);

  signal NumberOfTrigger_Cnt_D  : std_logic_vector(7 downto 0);
  signal NumberOfTrigger_Cnt_Q  : std_logic_vector(7 downto 0);
  signal DecNumberOfTriggerInTrigFifo_D      :  std_logic; --- When NumberOfBufDataCnt_REG = this,
  signal DecNumberOfTriggerInTrigFifo_Q      :  std_logic; --- When NumberOfBufDataCnt_REG = this,
  signal PDecNumberOfTriggerInTrigFifo      :  std_logic; --- When NumberOfBufDataCnt_REG = this,
    
begin
 
    OrTrig_REG <= TrigInOr_Q;
    
    Reset <= not RESET_N;

    TrigIn_D <= --(others => '0') when SYNC = '1' or PTrigInOr_DLY_Q(2) = '1' else
				 --TrigIn when TrigIn_Q = "0000" else\
				 '0' when SYNC = '1' or PTrigInOr_DLY_Q(2) = '1' else
				 TrigIn when TrigIn_Q = '0' else
                 TrigIn_Q;
--    TrigInOr_D <= TrigIn_Q(3) or TrigIn_Q(2) or TrigIn_Q(1) or TrigIn_Q(0);
	TrigInOr_D <= TrigIn_Q;
    PTrigInOr_D <= TrigInOr_D and not TrigInOr_Q;
    
    ---- Monitor
    NumberOfTriggerInFifo_REG <= NumberOfTrigger_Cnt_Q;
    DecNumberOfTriggerInTrigFifo_D <= DecNumberOfTriggerInTrigFifo;
    PDecNumberOfTriggerInTrigFifo  <= DecNumberOfTriggerInTrigFifo_D and not DecNumberOfTriggerInTrigFifo_Q;
    NumberOfTrigger_Cnt_D <= X"00" when SYNC = '1' else	--(others => '0') CHANGE
                             NumberOfTrigger_Cnt_Q + 1 when PTrigInOr_Q = '1' and PDecNumberOfTriggerInTrigFifo = '0' else
                             NumberOfTrigger_Cnt_Q - 1 when PTrigInOr_Q = '0' and PDecNumberOfTriggerInTrigFifo = '1' else
                             NumberOfTrigger_Cnt_Q;

  UTimeStamp : time_stamp
  PORT map
   (
    b    => "01",
    clk  => CLK,
    sclr => Reset, --Reset,
    q    => TimeStamp_D
   );

  UTrigNum_Top : TrigNum_Top
  port map
   (
     CLK                  => CLK,  --
     RESET_N              => RESET_N,
     SYNC                 => SYNC,

     ---- Ports for testing
     CountEn                  => PTrigInOr_Q,

     --- To Host
     TrigNum_REG      => TrigNum_D --- 1 indicate there a trigger ready for process
  );

  UTrig_fifo_Din <= TrigInDly_Q & TrigNum_Q & TimeStamp_Q & Raw_Address_Q;

  UTrig_fifo_79_32 : fifo_79_32
  PORT map
   (
    clk   => CLK,
    rst   => SYNC, --Reset,
    din   => UTrig_fifo_Din,
    wr_en => PTrigInOr_DLY_Q(3),
    rd_en => Trig_fifo_Rd_en,
    dout  => UTrig_fifo_Dout,
    full  => UTrig_fifo_Full,
    empty => UTrig_fifo_Empty
  );

--    Trig_array: for I in 0 to 3 generate
--       Trigger_D(I)  <= TrigInOr_Q and TrigIn_Q(I);
--       PTrigger_D(I) <= Trigger_D(I)  and not Trigger_Q(I);
--    end generate;	  


--       Trigger_D  <= TrigInOr_Q and TrigIn_Q;
--       PTrigger_D <= Trigger_D  and not Trigger_Q;

    process (CLK, RESET_N)
      begin
        if RESET_N = '0' then
          Raw_Address_Q <= (others => '0');
          
        elsif rising_edge(CLK) then
           Raw_Address_Q <= Raw_Address;

        end if;
      end process;

    process (CLK, RESET_N)
	begin
        if rising_edge(CLK) then
          TrigIn_Q <= TrigIn_D;
          TrigInDly_Q <= "000"&TrigIn_Q;
          TrigInOr_Q <= TrigInOr_D;
--          Trigger_Q  <= Trigger_D;
--          PTrigger_Q <= PTrigger_D;
          TimeStamp_Q <= TimeStamp_D;
          TrigNum_Q   <= TrigNum_D;
          PTrigInOr_Q <= PTrigInOr_D;
          PTrigInOr_DLY_Q(0) <= PTrigInOr_Q;
          PTrigInOr_DLY_Q(1) <= PTrigInOr_DLY_Q(0);
          PTrigInOr_DLY_Q(2) <= PTrigInOr_DLY_Q(1);
          PTrigInOr_DLY_Q(3) <= PTrigInOr_DLY_Q(2);
          TrigBufHasData_REG <= not UTrig_fifo_Empty;
          TriBufData_REG <= UTrig_fifo_Dout;
          NumberOfTrigger_Cnt_Q <= NumberOfTrigger_Cnt_D;
          --NumberOfTrigger_Cnt_Q <= NumberOfTrigger_Cnt_D;
          DecNumberOfTriggerInTrigFifo_Q <= DecNumberOfTriggerInTrigFifo_D;
        end if;
      end process;
      
      
        
end RTL;
