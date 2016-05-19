--  C:\USERS\DICKOVER\DOCUMENTS\...\DATFORSM_2.vhd
--  VHDL code created by Xilinx's StateCAD 10.1
--  Tue Mar 15 17:05:49 2016

--  This VHDL code (for use with Xilinx XST) was generated using: 
--  enumerated state assignment with structured code format.
--  Minimization is enabled,  implied else is enabled, 
--  and outputs are speed optimized.

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY DATFORSM_2 IS
	PORT (CLK,GO,LAST_CHANNEL,PR_TRAILER,RESET_N: IN std_logic;
		CLR_CH_SEL,DEC_BLOCK_CNT,FIFO_WEN,FIFO_WEN_H,HEADER_RD_EN,INC_CH_SEL,
			INS_CHIP_TRAIL,PR_FIFO_RD_EN,SEL_PROC_DATA,SEL_TRG_NUM,SEL_TS_1,SEL_TS_2,
			SEL_TS_3,SEL_TS_BOT,SEL_TS_TOP : OUT std_logic);
END;

ARCHITECTURE BEHAVIOR OF DATFORSM_2 IS
	TYPE type_sreg IS (DATA_IDLE,STATE0,STATE1,STATE12,STATE13,STATE14,STATE20,
		STATE21,STATE23);
	SIGNAL sreg, next_sreg : type_sreg;
	TYPE type_sreg1 IS (HEADER_IDLE,STATE2,STATE4,STATE5,STATE6,STATE7,STATE8,
		STATE9,STATE10,STATE11,STATE15,STATE17,STATE18,STATE19);
	SIGNAL sreg1, next_sreg1 : type_sreg1;
	TYPE type_sreg2 IS (CH0,CH1,CH2,CH3,CH4,CH5,Header_Info,hold,MAIN_IDLE,
		STATE3,STATE16,STATE22);
	SIGNAL sreg2, next_sreg2 : type_sreg2;
	SIGNAL next_CLR_CH_SEL,next_DEC_BLOCK_CNT,next_FIFO_WEN,next_FIFO_WEN_H,
		next_Get_Header,next_Get_Proc_Data,next_Header_Done,next_HEADER_RD_EN,
		next_INC_CH_SEL,next_INS_CHIP_TRAIL,next_PR_Data_Done,next_PR_FIFO_RD_EN,
		next_SEL_PROC_DATA,next_SEL_TRG_NUM,next_SEL_TS_1,next_SEL_TS_2,next_SEL_TS_3
		,next_SEL_TS_BOT,next_SEL_TS_TOP : std_logic;

	SIGNAL Get_Header,Get_Proc_Data,Header_Done,PR_Data_Done: std_logic;
BEGIN
	PROCESS (CLK, next_sreg, next_CLR_CH_SEL, next_DEC_BLOCK_CNT, next_FIFO_WEN,
		 next_INC_CH_SEL, next_INS_CHIP_TRAIL, next_PR_Data_Done, next_PR_FIFO_RD_EN,
		 next_SEL_PROC_DATA)
	BEGIN
		IF CLK='1' AND CLK'event THEN
			sreg <= next_sreg;
			CLR_CH_SEL <= next_CLR_CH_SEL;
			DEC_BLOCK_CNT <= next_DEC_BLOCK_CNT;
			FIFO_WEN <= next_FIFO_WEN;
			INC_CH_SEL <= next_INC_CH_SEL;
			INS_CHIP_TRAIL <= next_INS_CHIP_TRAIL;
			PR_Data_Done <= next_PR_Data_Done;
			PR_FIFO_RD_EN <= next_PR_FIFO_RD_EN;
			SEL_PROC_DATA <= next_SEL_PROC_DATA;
		END IF;
	END PROCESS;

	PROCESS (CLK, next_sreg1, next_FIFO_WEN_H, next_Header_Done, 
		next_HEADER_RD_EN, next_SEL_TRG_NUM, next_SEL_TS_1, next_SEL_TS_2, 
		next_SEL_TS_3, next_SEL_TS_BOT, next_SEL_TS_TOP)
	BEGIN
		IF CLK='1' AND CLK'event THEN
			sreg1 <= next_sreg1;
			FIFO_WEN_H <= next_FIFO_WEN_H;
			Header_Done <= next_Header_Done;
			HEADER_RD_EN <= next_HEADER_RD_EN;
			SEL_TRG_NUM <= next_SEL_TRG_NUM;
			SEL_TS_1 <= next_SEL_TS_1;
			SEL_TS_2 <= next_SEL_TS_2;
			SEL_TS_3 <= next_SEL_TS_3;
			SEL_TS_BOT <= next_SEL_TS_BOT;
			SEL_TS_TOP <= next_SEL_TS_TOP;
		END IF;
	END PROCESS;

	PROCESS (CLK, next_sreg2, next_Get_Header, next_Get_Proc_Data)
	BEGIN
		IF CLK='1' AND CLK'event THEN
			sreg2 <= next_sreg2;
			Get_Header <= next_Get_Header;
			Get_Proc_Data <= next_Get_Proc_Data;
		END IF;
	END PROCESS;

	PROCESS (sreg,sreg1,sreg2,Get_Header,Get_Proc_Data,GO,Header_Done,
		LAST_CHANNEL,PR_Data_Done,PR_TRAILER,RESET_N)
	BEGIN
		next_CLR_CH_SEL <= '0'; next_DEC_BLOCK_CNT <= '0'; next_FIFO_WEN <= '0'; 
			next_FIFO_WEN_H <= '0'; next_Get_Header <= '0'; next_Get_Proc_Data <= '0'; 
			next_Header_Done <= '0'; next_HEADER_RD_EN <= '0'; next_INC_CH_SEL <= '0'; 
			next_INS_CHIP_TRAIL <= '0'; next_PR_Data_Done <= '0'; next_PR_FIFO_RD_EN <= 
			'0'; next_SEL_PROC_DATA <= '0'; next_SEL_TRG_NUM <= '0'; next_SEL_TS_1 <= 
			'0'; next_SEL_TS_2 <= '0'; next_SEL_TS_3 <= '0'; next_SEL_TS_BOT <= '0'; 
			next_SEL_TS_TOP <= '0'; 

		next_sreg<=DATA_IDLE;
		next_sreg1<=HEADER_IDLE;
		next_sreg2<=CH0;

		IF ( RESET_N='0' ) THEN
			next_sreg<=DATA_IDLE;
			next_CLR_CH_SEL<='0';
			next_DEC_BLOCK_CNT<='0';
			next_FIFO_WEN<='0';
			next_INC_CH_SEL<='0';
			next_INS_CHIP_TRAIL<='0';
			next_PR_Data_Done<='0';
			next_PR_FIFO_RD_EN<='0';
			next_SEL_PROC_DATA<='0';
		ELSE
			CASE sreg IS
				WHEN DATA_IDLE =>
					IF ( Get_Proc_Data='1' AND PR_TRAILER='1' ) THEN
						next_sreg<=STATE0;
						next_CLR_CH_SEL<='0';
						next_DEC_BLOCK_CNT<='0';
						next_FIFO_WEN<='0';
						next_INC_CH_SEL<='0';
						next_INS_CHIP_TRAIL<='0';
						next_PR_Data_Done<='0';
						next_SEL_PROC_DATA<='0';
						next_PR_FIFO_RD_EN<='1';
					ELSIF ( Get_Proc_Data='1' AND PR_TRAILER='0' ) THEN
						next_sreg<=STATE21;
						next_CLR_CH_SEL<='0';
						next_DEC_BLOCK_CNT<='0';
						next_FIFO_WEN<='0';
						next_INC_CH_SEL<='0';
						next_INS_CHIP_TRAIL<='0';
						next_PR_Data_Done<='0';
						next_PR_FIFO_RD_EN<='0';
						next_SEL_PROC_DATA<='1';
					 ELSE
						next_sreg<=DATA_IDLE;
						next_CLR_CH_SEL<='0';
						next_DEC_BLOCK_CNT<='0';
						next_FIFO_WEN<='0';
						next_INC_CH_SEL<='0';
						next_INS_CHIP_TRAIL<='0';
						next_PR_Data_Done<='0';
						next_PR_FIFO_RD_EN<='0';
						next_SEL_PROC_DATA<='0';
					END IF;
				WHEN STATE0 =>
					IF ( LAST_CHANNEL='0' ) THEN
						next_sreg<=STATE12;
						next_CLR_CH_SEL<='0';
						next_FIFO_WEN<='0';
						next_INS_CHIP_TRAIL<='0';
						next_PR_FIFO_RD_EN<='0';
						next_SEL_PROC_DATA<='0';
						next_INC_CH_SEL<='1';
						next_PR_Data_Done<='1';
						next_DEC_BLOCK_CNT<='1';
					ELSIF ( LAST_CHANNEL='1' ) THEN
						next_sreg<=STATE13;
						next_FIFO_WEN<='0';
						next_INC_CH_SEL<='0';
						next_PR_FIFO_RD_EN<='0';
						next_SEL_PROC_DATA<='0';
						next_CLR_CH_SEL<='1';
						next_INS_CHIP_TRAIL<='1';
						next_PR_Data_Done<='1';
						next_DEC_BLOCK_CNT<='1';
					END IF;
				WHEN STATE1 =>
					IF ( PR_TRAILER='0' ) THEN
						next_sreg<=STATE21;
						next_CLR_CH_SEL<='0';
						next_DEC_BLOCK_CNT<='0';
						next_FIFO_WEN<='0';
						next_INC_CH_SEL<='0';
						next_INS_CHIP_TRAIL<='0';
						next_PR_Data_Done<='0';
						next_PR_FIFO_RD_EN<='0';
						next_SEL_PROC_DATA<='1';
					ELSIF ( PR_TRAILER='1' ) THEN
						next_sreg<=STATE0;
						next_CLR_CH_SEL<='0';
						next_DEC_BLOCK_CNT<='0';
						next_FIFO_WEN<='0';
						next_INC_CH_SEL<='0';
						next_INS_CHIP_TRAIL<='0';
						next_PR_Data_Done<='0';
						next_SEL_PROC_DATA<='0';
						next_PR_FIFO_RD_EN<='1';
					END IF;
				WHEN STATE12 =>
					next_sreg<=DATA_IDLE;
					next_CLR_CH_SEL<='0';
					next_DEC_BLOCK_CNT<='0';
					next_FIFO_WEN<='0';
					next_INC_CH_SEL<='0';
					next_INS_CHIP_TRAIL<='0';
					next_PR_Data_Done<='0';
					next_PR_FIFO_RD_EN<='0';
					next_SEL_PROC_DATA<='0';
				WHEN STATE13 =>
					next_sreg<=STATE20;
					next_CLR_CH_SEL<='0';
					next_DEC_BLOCK_CNT<='0';
					next_INC_CH_SEL<='0';
					next_PR_Data_Done<='0';
					next_PR_FIFO_RD_EN<='0';
					next_SEL_PROC_DATA<='0';
					next_INS_CHIP_TRAIL<='1';
					next_FIFO_WEN<='1';
				WHEN STATE14 =>
					next_sreg<=STATE23;
					next_CLR_CH_SEL<='0';
					next_DEC_BLOCK_CNT<='0';
					next_INC_CH_SEL<='0';
					next_INS_CHIP_TRAIL<='0';
					next_PR_Data_Done<='0';
					next_PR_FIFO_RD_EN<='0';
					next_SEL_PROC_DATA<='0';
					next_FIFO_WEN<='1';
				WHEN STATE20 =>
					next_sreg<=DATA_IDLE;
					next_CLR_CH_SEL<='0';
					next_DEC_BLOCK_CNT<='0';
					next_FIFO_WEN<='0';
					next_INC_CH_SEL<='0';
					next_INS_CHIP_TRAIL<='0';
					next_PR_Data_Done<='0';
					next_PR_FIFO_RD_EN<='0';
					next_SEL_PROC_DATA<='0';
				WHEN STATE21 =>
					next_sreg<=STATE14;
					next_CLR_CH_SEL<='0';
					next_DEC_BLOCK_CNT<='0';
					next_FIFO_WEN<='0';
					next_INC_CH_SEL<='0';
					next_INS_CHIP_TRAIL<='0';
					next_PR_Data_Done<='0';
					next_SEL_PROC_DATA<='1';
					next_PR_FIFO_RD_EN<='1';
				WHEN STATE23 =>
					next_sreg<=STATE1;
					next_CLR_CH_SEL<='0';
					next_DEC_BLOCK_CNT<='0';
					next_FIFO_WEN<='0';
					next_INC_CH_SEL<='0';
					next_INS_CHIP_TRAIL<='0';
					next_PR_Data_Done<='0';
					next_PR_FIFO_RD_EN<='0';
					next_SEL_PROC_DATA<='0';
				WHEN OTHERS =>
			END CASE;
		END IF;

		IF ( RESET_N='0' ) THEN
			next_sreg1<=HEADER_IDLE;
			next_FIFO_WEN_H<='0';
			next_Header_Done<='0';
			next_HEADER_RD_EN<='0';
			next_SEL_TRG_NUM<='0';
			next_SEL_TS_1<='0';
			next_SEL_TS_2<='0';
			next_SEL_TS_3<='0';
			next_SEL_TS_BOT<='0';
			next_SEL_TS_TOP<='0';
		ELSE
			CASE sreg1 IS
				WHEN HEADER_IDLE =>
					IF ( Get_Header='1' ) THEN
						next_sreg1<=STATE2;
						next_FIFO_WEN_H<='0';
						next_Header_Done<='0';
						next_SEL_TRG_NUM<='0';
						next_SEL_TS_1<='0';
						next_SEL_TS_2<='0';
						next_SEL_TS_3<='0';
						next_SEL_TS_BOT<='0';
						next_SEL_TS_TOP<='0';
						next_HEADER_RD_EN<='1';
					 ELSE
						next_sreg1<=HEADER_IDLE;
						next_FIFO_WEN_H<='0';
						next_Header_Done<='0';
						next_HEADER_RD_EN<='0';
						next_SEL_TRG_NUM<='0';
						next_SEL_TS_1<='0';
						next_SEL_TS_2<='0';
						next_SEL_TS_3<='0';
						next_SEL_TS_BOT<='0';
						next_SEL_TS_TOP<='0';
					END IF;
				WHEN STATE2 =>
					next_sreg1<=STATE4;
					next_FIFO_WEN_H<='0';
					next_Header_Done<='0';
					next_SEL_TRG_NUM<='0';
					next_SEL_TS_1<='0';
					next_SEL_TS_2<='0';
					next_SEL_TS_3<='0';
					next_SEL_TS_BOT<='0';
					next_SEL_TS_TOP<='0';
					next_HEADER_RD_EN<='1';
				WHEN STATE4 =>
					next_sreg1<=STATE5;
					next_FIFO_WEN_H<='0';
					next_Header_Done<='0';
					next_SEL_TRG_NUM<='0';
					next_SEL_TS_1<='0';
					next_SEL_TS_2<='0';
					next_SEL_TS_3<='0';
					next_SEL_TS_BOT<='0';
					next_SEL_TS_TOP<='0';
					next_HEADER_RD_EN<='1';
				WHEN STATE5 =>
					next_sreg1<=STATE6;
					next_FIFO_WEN_H<='0';
					next_Header_Done<='0';
					next_SEL_TRG_NUM<='0';
					next_SEL_TS_1<='0';
					next_SEL_TS_2<='0';
					next_SEL_TS_3<='0';
					next_SEL_TS_BOT<='0';
					next_SEL_TS_TOP<='0';
					next_HEADER_RD_EN<='1';
				WHEN STATE6 =>
					next_sreg1<=STATE7;
					next_Header_Done<='0';
					next_SEL_TS_1<='0';
					next_SEL_TS_2<='0';
					next_SEL_TS_3<='0';
					next_SEL_TS_BOT<='0';
					next_SEL_TS_TOP<='0';
					next_HEADER_RD_EN<='1';
					next_SEL_TRG_NUM<='1';
					next_FIFO_WEN_H<='1';
				WHEN STATE7 =>
					next_sreg1<=STATE8;
					next_FIFO_WEN_H<='0';
					next_Header_Done<='0';
					next_HEADER_RD_EN<='0';
					next_SEL_TS_2<='0';
					next_SEL_TS_3<='0';
					next_SEL_TS_BOT<='0';
					next_SEL_TS_TOP<='0';
					next_SEL_TRG_NUM<='1';
					next_SEL_TS_1<='1';
				WHEN STATE8 =>
					next_sreg1<=STATE9;
					next_FIFO_WEN_H<='0';
					next_Header_Done<='0';
					next_HEADER_RD_EN<='0';
					next_SEL_TRG_NUM<='0';
					next_SEL_TS_1<='0';
					next_SEL_TS_3<='0';
					next_SEL_TS_BOT<='0';
					next_SEL_TS_TOP<='0';
					next_SEL_TS_2<='1';
				WHEN STATE9 =>
					next_sreg1<=STATE10;
					next_FIFO_WEN_H<='0';
					next_Header_Done<='0';
					next_HEADER_RD_EN<='0';
					next_SEL_TRG_NUM<='0';
					next_SEL_TS_1<='0';
					next_SEL_TS_2<='0';
					next_SEL_TS_BOT<='0';
					next_SEL_TS_TOP<='0';
					next_SEL_TS_3<='1';
				WHEN STATE10 =>
					next_sreg1<=STATE15;
					next_FIFO_WEN_H<='0';
					next_Header_Done<='0';
					next_HEADER_RD_EN<='0';
					next_SEL_TRG_NUM<='0';
					next_SEL_TS_1<='0';
					next_SEL_TS_2<='0';
					next_SEL_TS_3<='0';
					next_SEL_TS_BOT<='0';
					next_SEL_TS_TOP<='1';
				WHEN STATE11 =>
					next_sreg1<=HEADER_IDLE;
					next_FIFO_WEN_H<='0';
					next_Header_Done<='0';
					next_HEADER_RD_EN<='0';
					next_SEL_TRG_NUM<='0';
					next_SEL_TS_1<='0';
					next_SEL_TS_2<='0';
					next_SEL_TS_3<='0';
					next_SEL_TS_BOT<='0';
					next_SEL_TS_TOP<='0';
				WHEN STATE15 =>
					next_sreg1<=STATE17;
					next_Header_Done<='0';
					next_HEADER_RD_EN<='0';
					next_SEL_TRG_NUM<='0';
					next_SEL_TS_1<='0';
					next_SEL_TS_2<='0';
					next_SEL_TS_3<='0';
					next_SEL_TS_BOT<='0';
					next_SEL_TS_TOP<='1';
					next_FIFO_WEN_H<='1';
				WHEN STATE17 =>
					next_sreg1<=STATE18;
					next_FIFO_WEN_H<='0';
					next_Header_Done<='0';
					next_HEADER_RD_EN<='0';
					next_SEL_TRG_NUM<='0';
					next_SEL_TS_1<='0';
					next_SEL_TS_2<='0';
					next_SEL_TS_3<='0';
					next_SEL_TS_TOP<='0';
					next_SEL_TS_BOT<='1';
				WHEN STATE18 =>
					next_sreg1<=STATE19;
					next_Header_Done<='0';
					next_HEADER_RD_EN<='0';
					next_SEL_TRG_NUM<='0';
					next_SEL_TS_1<='0';
					next_SEL_TS_2<='0';
					next_SEL_TS_3<='0';
					next_SEL_TS_TOP<='0';
					next_SEL_TS_BOT<='1';
					next_FIFO_WEN_H<='1';
				WHEN STATE19 =>
					next_sreg1<=STATE11;
					next_FIFO_WEN_H<='0';
					next_HEADER_RD_EN<='0';
					next_SEL_TRG_NUM<='0';
					next_SEL_TS_1<='0';
					next_SEL_TS_2<='0';
					next_SEL_TS_3<='0';
					next_SEL_TS_BOT<='0';
					next_SEL_TS_TOP<='0';
					next_Header_Done<='1';
				WHEN OTHERS =>
			END CASE;
		END IF;

		IF ( RESET_N='0' ) THEN
			next_sreg2<=MAIN_IDLE;
			next_Get_Header<='0';
			next_Get_Proc_Data<='0';
		ELSE
			CASE sreg2 IS
				WHEN CH0 =>
					IF ( PR_Data_Done='1' ) THEN
						next_sreg2<=CH1;
						next_Get_Header<='0';
						next_Get_Proc_Data<='1';
					 ELSE
						next_sreg2<=CH0;
						next_Get_Header<='0';
						next_Get_Proc_Data<='1';
					END IF;
				WHEN CH1 =>
					IF ( PR_Data_Done='1' ) THEN
						next_sreg2<=CH2;
						next_Get_Header<='0';
						next_Get_Proc_Data<='1';
					 ELSE
						next_sreg2<=CH1;
						next_Get_Header<='0';
						next_Get_Proc_Data<='1';
					END IF;
				WHEN CH2 =>
					IF ( PR_Data_Done='1' ) THEN
						next_sreg2<=CH3;
						next_Get_Header<='0';
						next_Get_Proc_Data<='1';
					 ELSE
						next_sreg2<=CH2;
						next_Get_Header<='0';
						next_Get_Proc_Data<='1';
					END IF;
				WHEN CH3 =>
					IF ( PR_Data_Done='1' ) THEN
						next_sreg2<=CH4;
						next_Get_Header<='0';
						next_Get_Proc_Data<='1';
					 ELSE
						next_sreg2<=CH3;
						next_Get_Header<='0';
						next_Get_Proc_Data<='1';
					END IF;
				WHEN CH4 =>
					IF ( PR_Data_Done='1' ) THEN
						next_sreg2<=CH5;
						next_Get_Header<='0';
						next_Get_Proc_Data<='1';
					 ELSE
						next_sreg2<=CH4;
						next_Get_Header<='0';
						next_Get_Proc_Data<='1';
					END IF;
				WHEN CH5 =>
					IF ( PR_Data_Done='1' ) THEN
						next_sreg2<=STATE22;
						next_Get_Header<='0';
						next_Get_Proc_Data<='0';
					 ELSE
						next_sreg2<=CH5;
						next_Get_Header<='0';
						next_Get_Proc_Data<='1';
					END IF;
				WHEN Header_Info =>
					IF ( Header_Done='1' ) THEN
						next_sreg2<=CH0;
						next_Get_Header<='0';
						next_Get_Proc_Data<='1';
					 ELSE
						next_sreg2<=Header_Info;
						next_Get_Proc_Data<='0';
						next_Get_Header<='1';
					END IF;
				WHEN hold =>
					next_sreg2<=MAIN_IDLE;
					next_Get_Header<='0';
					next_Get_Proc_Data<='0';
				WHEN MAIN_IDLE =>
					IF ( GO='1' ) THEN
						next_sreg2<=Header_Info;
						next_Get_Proc_Data<='0';
						next_Get_Header<='1';
					 ELSE
						next_sreg2<=MAIN_IDLE;
						next_Get_Header<='0';
						next_Get_Proc_Data<='0';
					END IF;
				WHEN STATE3 =>
					next_sreg2<=STATE16;
					next_Get_Header<='0';
					next_Get_Proc_Data<='0';
				WHEN STATE16 =>
					next_sreg2<=hold;
					next_Get_Header<='0';
					next_Get_Proc_Data<='0';
				WHEN STATE22 =>
					next_sreg2<=STATE3;
					next_Get_Header<='0';
					next_Get_Proc_Data<='0';
				WHEN OTHERS =>
			END CASE;
		END IF;
	END PROCESS;
END BEHAVIOR;
