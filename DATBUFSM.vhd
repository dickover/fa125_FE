--  C:\USERS\DICKOVER\DOCUMENTS\...\DATBUFSM.vhd
--  VHDL code created by Xilinx's StateCAD 10.1
--  Sun Sep 27 12:48:02 2015

--  This VHDL code (for use with IEEE compliant tools) was generated using: 
--  enumerated state assignment with structured code format.
--  Minimization is enabled,  implied else is enabled, 
--  and outputs are speed optimized.

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY DATBUFSM IS
	PORT (CLK,RESET_N,TrigBufHasData,WindowWdCntTc: IN std_logic;
		HeaderFifoWrEn,IDLE,IncNumOfBufDatCt,IncRawDatRdAdr,LdRawDataRdAdr,
			RamBufferWrEn,SelCapTrigNumHi,SelChanHasTrig,SelChanHasTrig2,SelTimeStampHi,
			SelTimeStampLo,SelTimeStampMid,TrigFifoRdEn,WindowWdCntEn : OUT std_logic);

	SIGNAL Wait4BEn,Wait4BTC,Wait4En,Wait4TC,WrDatBufDone: std_logic;
END;

ARCHITECTURE BEHAVIOR OF DATBUFSM IS
	TYPE type_sreg IS (Wait4_Done,Wait4_Idle,Wait4_St1,Wait4_St2);
	SIGNAL sreg, next_sreg : type_sreg;
	TYPE type_sreg1 IS (WrDataBufDone,WrDatBuf_chanhas,WrDatBuf_WrDat,
		WrDatBufIdle,WrDatBufWait,WrWaitForRawData);
	SIGNAL sreg1, next_sreg1 : type_sreg1;
	TYPE type_sreg2 IS (IdleSt,RdCapTrigFifo,Wait2,WrChanHasData,WrTiStampHi,
		WrTiStampLo,WrTiStampMid,WrTrigNumHi,WtWrDatBufDone);
	SIGNAL sreg2, next_sreg2 : type_sreg2;
	TYPE type_sreg3 IS (STATE0,STATE1,STATE2,STATE3);
	SIGNAL sreg3, next_sreg3 : type_sreg3;
	SIGNAL next_HeaderFifoWrEn,next_IDLE,next_IncNumOfBufDatCt,
		next_IncRawDatRdAdr,next_LdRawDataRdAdr,next_RamBufferWrEn,
		next_SelCapTrigNumHi,next_SelChanHasTrig,next_SelChanHasTrig2,
		next_SelTimeStampHi,next_SelTimeStampLo,next_SelTimeStampMid,
		next_TrigFifoRdEn,next_Wait4BEn,next_Wait4BTC,next_Wait4En,next_Wait4TC,
		next_WindowWdCntEn,next_WrDatBufDone : std_logic;
BEGIN
	PROCESS (CLK, next_sreg, next_Wait4TC)
	BEGIN
		IF CLK='1' AND CLK'event THEN
			sreg <= next_sreg;
			Wait4TC <= next_Wait4TC;
		END IF;
	END PROCESS;

	PROCESS (CLK, next_sreg1, next_IncNumOfBufDatCt, next_IncRawDatRdAdr, 
		next_LdRawDataRdAdr, next_RamBufferWrEn, next_SelChanHasTrig2, next_Wait4BEn,
		 next_WindowWdCntEn, next_WrDatBufDone)
	BEGIN
		IF CLK='1' AND CLK'event THEN
			sreg1 <= next_sreg1;
			IncNumOfBufDatCt <= next_IncNumOfBufDatCt;
			IncRawDatRdAdr <= next_IncRawDatRdAdr;
			LdRawDataRdAdr <= next_LdRawDataRdAdr;
			RamBufferWrEn <= next_RamBufferWrEn;
			SelChanHasTrig2 <= next_SelChanHasTrig2;
			Wait4BEn <= next_Wait4BEn;
			WindowWdCntEn <= next_WindowWdCntEn;
			WrDatBufDone <= next_WrDatBufDone;
		END IF;
	END PROCESS;

	PROCESS (CLK, next_sreg2, next_HeaderFifoWrEn, next_IDLE, 
		next_SelCapTrigNumHi, next_SelChanHasTrig, next_SelTimeStampHi, 
		next_SelTimeStampLo, next_SelTimeStampMid, next_TrigFifoRdEn, next_Wait4En)
	BEGIN
		IF CLK='1' AND CLK'event THEN
			sreg2 <= next_sreg2;
			HeaderFifoWrEn <= next_HeaderFifoWrEn;
			IDLE <= next_IDLE;
			SelCapTrigNumHi <= next_SelCapTrigNumHi;
			SelChanHasTrig <= next_SelChanHasTrig;
			SelTimeStampHi <= next_SelTimeStampHi;
			SelTimeStampLo <= next_SelTimeStampLo;
			SelTimeStampMid <= next_SelTimeStampMid;
			TrigFifoRdEn <= next_TrigFifoRdEn;
			Wait4En <= next_Wait4En;
		END IF;
	END PROCESS;

	PROCESS (CLK, next_sreg3, next_Wait4BTC)
	BEGIN
		IF CLK='1' AND CLK'event THEN
			sreg3 <= next_sreg3;
			Wait4BTC <= next_Wait4BTC;
		END IF;
	END PROCESS;

	PROCESS (sreg,sreg1,sreg2,sreg3,RESET_N,TrigBufHasData,Wait4BEn,Wait4BTC,
		Wait4En,Wait4TC,WindowWdCntTc,WrDatBufDone)
	BEGIN
		next_HeaderFifoWrEn <= '0'; next_IDLE <= '0'; next_IncNumOfBufDatCt <= '0';
			 next_IncRawDatRdAdr <= '0'; next_LdRawDataRdAdr <= '0'; next_RamBufferWrEn 
			<= '0'; next_SelCapTrigNumHi <= '0'; next_SelChanHasTrig <= '0'; 
			next_SelChanHasTrig2 <= '0'; next_SelTimeStampHi <= '0'; next_SelTimeStampLo 
			<= '0'; next_SelTimeStampMid <= '0'; next_TrigFifoRdEn <= '0'; next_Wait4BEn 
			<= '0'; next_Wait4BTC <= '0'; next_Wait4En <= '0'; next_Wait4TC <= '0'; 
			next_WindowWdCntEn <= '0'; next_WrDatBufDone <= '0'; 

		next_sreg<=Wait4_Done;
		next_sreg1<=WrDataBufDone;
		next_sreg2<=IdleSt;
		next_sreg3<=STATE0;

		IF ( RESET_N='0' ) THEN
			next_sreg<=Wait4_Idle;
			next_Wait4TC<='0';
		ELSE
			CASE sreg IS
				WHEN Wait4_Done =>
					next_sreg<=Wait4_Idle;
					next_Wait4TC<='0';
				WHEN Wait4_Idle =>
					IF ( Wait4En='1' ) THEN
						next_sreg<=Wait4_St1;
						next_Wait4TC<='0';
					 ELSE
						next_sreg<=Wait4_Idle;
						next_Wait4TC<='0';
					END IF;
				WHEN Wait4_St1 =>
					next_sreg<=Wait4_St2;
					next_Wait4TC<='0';
				WHEN Wait4_St2 =>
					next_sreg<=Wait4_Done;
					next_Wait4TC<='1';
				WHEN OTHERS =>
			END CASE;
		END IF;

		IF ( RESET_N='0' ) THEN
			next_sreg1<=WrDatBufIdle;
			next_WrDatBufDone<='0';
			next_WindowWdCntEn<='0';
			next_Wait4BEn<='0';
			next_SelChanHasTrig2<='0';
			next_RamBufferWrEn<='0';
			next_LdRawDataRdAdr<='0';
			next_IncRawDatRdAdr<='0';
			next_IncNumOfBufDatCt<='0';
		ELSE
			CASE sreg1 IS
				WHEN WrDataBufDone =>
					next_sreg1<=WrDatBufIdle;
					next_WrDatBufDone<='0';
					next_WindowWdCntEn<='0';
					next_Wait4BEn<='0';
					next_SelChanHasTrig2<='0';
					next_RamBufferWrEn<='0';
					next_LdRawDataRdAdr<='0';
					next_IncRawDatRdAdr<='0';
					next_IncNumOfBufDatCt<='0';
				WHEN WrDatBuf_chanhas =>
					next_sreg1<=WrDatBuf_WrDat;
					next_WrDatBufDone<='0';
					next_Wait4BEn<='0';
					next_SelChanHasTrig2<='0';
					next_LdRawDataRdAdr<='0';
					next_IncNumOfBufDatCt<='0';
					next_RamBufferWrEn<='1';
					next_WindowWdCntEn<='1';
					next_IncRawDatRdAdr<='1';
				WHEN WrDatBuf_WrDat =>
					IF ( WindowWdCntTc='1' ) THEN
						next_sreg1<=WrDataBufDone;
						next_WindowWdCntEn<='0';
						next_Wait4BEn<='0';
						next_SelChanHasTrig2<='0';
						next_RamBufferWrEn<='0';
						next_LdRawDataRdAdr<='0';
						next_IncRawDatRdAdr<='0';
						next_WrDatBufDone<='1';
						next_IncNumOfBufDatCt<='1';
					 ELSE
						next_sreg1<=WrDatBuf_WrDat;
						next_WrDatBufDone<='0';
						next_Wait4BEn<='0';
						next_SelChanHasTrig2<='0';
						next_LdRawDataRdAdr<='0';
						next_IncNumOfBufDatCt<='0';
						next_RamBufferWrEn<='1';
						next_WindowWdCntEn<='1';
						next_IncRawDatRdAdr<='1';
					END IF;
				WHEN WrDatBufIdle =>
					IF ( TrigBufHasData='1' ) THEN
						next_sreg1<=WrDatBufWait;
						next_WrDatBufDone<='0';
						next_WindowWdCntEn<='0';
						next_Wait4BEn<='0';
						next_RamBufferWrEn<='0';
						next_IncRawDatRdAdr<='0';
						next_IncNumOfBufDatCt<='0';
						next_SelChanHasTrig2<='1';
						next_LdRawDataRdAdr<='1';
					 ELSE
						next_sreg1<=WrDatBufIdle;
						next_WrDatBufDone<='0';
						next_WindowWdCntEn<='0';
						next_Wait4BEn<='0';
						next_SelChanHasTrig2<='0';
						next_RamBufferWrEn<='0';
						next_LdRawDataRdAdr<='0';
						next_IncRawDatRdAdr<='0';
						next_IncNumOfBufDatCt<='0';
					END IF;
				WHEN WrDatBufWait =>
					IF ( Wait4TC='1' ) THEN
						next_sreg1<=WrWaitForRawData;
						next_WrDatBufDone<='0';
						next_WindowWdCntEn<='0';
						next_RamBufferWrEn<='0';
						next_LdRawDataRdAdr<='0';
						next_IncNumOfBufDatCt<='0';
						next_SelChanHasTrig2<='1';
						next_IncRawDatRdAdr<='1';
						next_Wait4BEn<='1';
					 ELSE
						next_sreg1<=WrDatBufWait;
						next_WrDatBufDone<='0';
						next_WindowWdCntEn<='0';
						next_Wait4BEn<='0';
						next_RamBufferWrEn<='0';
						next_IncRawDatRdAdr<='0';
						next_IncNumOfBufDatCt<='0';
						next_SelChanHasTrig2<='1';
						next_LdRawDataRdAdr<='1';
					END IF;
				WHEN WrWaitForRawData =>
					IF ( Wait4BTC='1' ) THEN
						next_sreg1<=WrDatBuf_chanhas;
						next_WrDatBufDone<='0';
						next_Wait4BEn<='0';
						next_LdRawDataRdAdr<='0';
						next_IncNumOfBufDatCt<='0';
						next_SelChanHasTrig2<='1';
						next_RamBufferWrEn<='1';
						next_WindowWdCntEn<='1';
						next_IncRawDatRdAdr<='1';
					 ELSE
						next_sreg1<=WrWaitForRawData;
						next_WrDatBufDone<='0';
						next_WindowWdCntEn<='0';
						next_RamBufferWrEn<='0';
						next_LdRawDataRdAdr<='0';
						next_IncNumOfBufDatCt<='0';
						next_SelChanHasTrig2<='1';
						next_IncRawDatRdAdr<='1';
						next_Wait4BEn<='1';
					END IF;
				WHEN OTHERS =>
			END CASE;
		END IF;

		IF ( RESET_N='0' ) THEN
			next_sreg2<=IdleSt;
			next_Wait4En<='0';
			next_TrigFifoRdEn<='0';
			next_SelTimeStampMid<='0';
			next_SelTimeStampLo<='0';
			next_SelTimeStampHi<='0';
			next_SelChanHasTrig<='0';
			next_SelCapTrigNumHi<='0';
			next_HeaderFifoWrEn<='0';
			next_IDLE<='1';
		ELSE
			CASE sreg2 IS
				WHEN IdleSt =>
					IF ( TrigBufHasData='1' ) THEN
						next_sreg2<=RdCapTrigFifo;
						next_Wait4En<='0';
						next_SelTimeStampMid<='0';
						next_SelTimeStampLo<='0';
						next_SelTimeStampHi<='0';
						next_SelChanHasTrig<='0';
						next_SelCapTrigNumHi<='0';
						next_IDLE<='0';
						next_HeaderFifoWrEn<='0';
						next_TrigFifoRdEn<='1';
					 ELSE
						next_sreg2<=IdleSt;
						next_Wait4En<='0';
						next_TrigFifoRdEn<='0';
						next_SelTimeStampMid<='0';
						next_SelTimeStampLo<='0';
						next_SelTimeStampHi<='0';
						next_SelChanHasTrig<='0';
						next_SelCapTrigNumHi<='0';
						next_HeaderFifoWrEn<='0';
						next_IDLE<='1';
					END IF;
				WHEN RdCapTrigFifo =>
					next_sreg2<=Wait2;
					next_TrigFifoRdEn<='0';
					next_SelTimeStampMid<='0';
					next_SelTimeStampLo<='0';
					next_SelTimeStampHi<='0';
					next_SelCapTrigNumHi<='0';
					next_IDLE<='0';
					next_HeaderFifoWrEn<='0';
					next_Wait4En<='1';
					next_SelChanHasTrig<='1';
				WHEN Wait2 =>
					IF ( Wait4TC='1' ) THEN
						next_sreg2<=WrChanHasData;
						next_Wait4En<='0';
						next_TrigFifoRdEn<='0';
						next_SelTimeStampMid<='0';
						next_SelTimeStampLo<='0';
						next_SelTimeStampHi<='0';
						next_SelCapTrigNumHi<='0';
						next_IDLE<='0';
						next_SelChanHasTrig<='1';
						next_HeaderFifoWrEn<='1';
					 ELSE
						next_sreg2<=Wait2;
						next_TrigFifoRdEn<='0';
						next_SelTimeStampMid<='0';
						next_SelTimeStampLo<='0';
						next_SelTimeStampHi<='0';
						next_SelCapTrigNumHi<='0';
						next_IDLE<='0';
						next_HeaderFifoWrEn<='0';
						next_Wait4En<='1';
						next_SelChanHasTrig<='1';
					END IF;
				WHEN WrChanHasData =>
					next_sreg2<=WrTrigNumHi;
					next_Wait4En<='0';
					next_TrigFifoRdEn<='0';
					next_SelTimeStampMid<='0';
					next_SelTimeStampLo<='0';
					next_SelTimeStampHi<='0';
					next_SelChanHasTrig<='0';
					next_IDLE<='0';
					next_SelCapTrigNumHi<='1';
					next_HeaderFifoWrEn<='1';
				WHEN WrTiStampHi =>
					next_sreg2<=WrTiStampMid;
					next_Wait4En<='0';
					next_TrigFifoRdEn<='0';
					next_SelTimeStampLo<='0';
					next_SelTimeStampHi<='0';
					next_SelChanHasTrig<='0';
					next_SelCapTrigNumHi<='0';
					next_IDLE<='0';
					next_SelTimeStampMid<='1';
					next_HeaderFifoWrEn<='1';
				WHEN WrTiStampLo =>
					next_sreg2<=WtWrDatBufDone;
					next_Wait4En<='0';
					next_TrigFifoRdEn<='0';
					next_SelTimeStampMid<='0';
					next_SelTimeStampLo<='0';
					next_SelTimeStampHi<='0';
					next_SelChanHasTrig<='0';
					next_SelCapTrigNumHi<='0';
					next_IDLE<='0';
					next_HeaderFifoWrEn<='0';
				WHEN WrTiStampMid =>
					next_sreg2<=WrTiStampLo;
					next_Wait4En<='0';
					next_TrigFifoRdEn<='0';
					next_SelTimeStampMid<='0';
					next_SelTimeStampHi<='0';
					next_SelChanHasTrig<='0';
					next_SelCapTrigNumHi<='0';
					next_IDLE<='0';
					next_SelTimeStampLo<='1';
					next_HeaderFifoWrEn<='1';
				WHEN WrTrigNumHi =>
					next_sreg2<=WrTiStampHi;
					next_Wait4En<='0';
					next_TrigFifoRdEn<='0';
					next_SelTimeStampMid<='0';
					next_SelTimeStampLo<='0';
					next_SelChanHasTrig<='0';
					next_SelCapTrigNumHi<='0';
					next_IDLE<='0';
					next_SelTimeStampHi<='1';
					next_HeaderFifoWrEn<='1';
				WHEN WtWrDatBufDone =>
					IF ( WrDatBufDone='1' ) THEN
						next_sreg2<=IdleSt;
						next_Wait4En<='0';
						next_TrigFifoRdEn<='0';
						next_SelTimeStampMid<='0';
						next_SelTimeStampLo<='0';
						next_SelTimeStampHi<='0';
						next_SelChanHasTrig<='0';
						next_SelCapTrigNumHi<='0';
						next_HeaderFifoWrEn<='0';
						next_IDLE<='1';
					 ELSE
						next_sreg2<=WtWrDatBufDone;
						next_Wait4En<='0';
						next_TrigFifoRdEn<='0';
						next_SelTimeStampMid<='0';
						next_SelTimeStampLo<='0';
						next_SelTimeStampHi<='0';
						next_SelChanHasTrig<='0';
						next_SelCapTrigNumHi<='0';
						next_IDLE<='0';
						next_HeaderFifoWrEn<='0';
					END IF;
				WHEN OTHERS =>
			END CASE;
		END IF;

		IF ( RESET_N='0' ) THEN
			next_sreg3<=STATE2;
			next_Wait4BTC<='0';
		ELSE
			CASE sreg3 IS
				WHEN STATE0 =>
					next_sreg3<=STATE3;
					next_Wait4BTC<='1';
				WHEN STATE1 =>
					next_sreg3<=STATE0;
					next_Wait4BTC<='0';
				WHEN STATE2 =>
					IF ( Wait4BEn='1' ) THEN
						next_sreg3<=STATE1;
						next_Wait4BTC<='0';
					 ELSE
						next_sreg3<=STATE2;
						next_Wait4BTC<='0';
					END IF;
				WHEN STATE3 =>
					next_sreg3<=STATE2;
					next_Wait4BTC<='0';
				WHEN OTHERS =>
			END CASE;
		END IF;
	END PROCESS;
END BEHAVIOR;
