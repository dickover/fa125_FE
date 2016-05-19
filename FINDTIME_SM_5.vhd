--  C:\USERS\DICKOVER\DOCUMENTS\...\FINDTIME_SM_5.vhd
--  VHDL code created by Xilinx's StateCAD 10.1
--  Tue Mar 15 17:19:44 2016

--  This VHDL code (for use with Xilinx XST) was generated using: 
--  enumerated state assignment with structured code format.
--  Minimization is enabled,  implied else is enabled, 
--  and outputs are speed optimized.

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY FINDTIME_SM_5 IS
	PORT (CLK,BUSY,CHECK_MAX_FOUND,FT_START_FROM_LS,FT_START_FROM_NU,GO,JUST_WE,
		LE_SAMPLE_FOUND,load_done,MAX_FOUND,PEAK_DONE,PTW_DONE,RESET_N,SLOPE_FOUND,
		TROUGH_FOUND,WE_DONE: IN std_logic;
		CHECK_MAX_GO,CLEAR_SUM,CLR_COUNTS,COUNT_SAMPLES,FIND_MAX_GO,FIND_TROUGH_GO,
			ft_done,ft_give,INC_PTW_PTR_TDC,load_samples,RT_PTW_PTR_LS,SLOPE_CHECK,
			STORE_MAX,SUM_FROM_TC_GO : OUT std_logic);
END;

ARCHITECTURE BEHAVIOR OF FINDTIME_SM_5 IS
	TYPE type_sreg IS (IDLE_SUM,STATE5,STATE9,STATE12,SUM_FROM_TC);
	SIGNAL sreg, next_sreg : type_sreg;
	TYPE type_sreg1 IS (back_to_NU,Cnt_INC_PTW_TDC,FINISH_PTW,Idle,STATE1,STATE2
		,STATE3,STATE4,STATE6,wait_for_busy);
	SIGNAL sreg1, next_sreg1 : type_sreg1;
	TYPE type_sreg2 IS (CHECK_MAX,FIND_MAX,FIND_TROUGH,IDLE_PEAK,PEAK_AT_PTW_END
		,STATE0,STATE7,STATE8,STATE10,STATE11,STATE13,STATE14,WAIT_4_TROUGH,
		wait_for_WE);
	SIGNAL sreg2, next_sreg2 : type_sreg2;
	SIGNAL next_CHECK_MAX_GO,next_CLEAR_SUM,next_CLR_COUNTS,next_COUNT_SAMPLES,
		next_counting,next_FIND_MAX_GO,next_FIND_TROUGH_GO,next_ft_done,next_ft_end,
		next_ft_give,next_INC_PTW_PTR_TDC,next_load_samples,next_RT_PTW_PTR_LS,
		next_SLOPE_CHECK,next_STORE_MAX,next_SUM_FROM_TC_GO : std_logic;

	SIGNAL counting,ft_end: std_logic;
BEGIN
	PROCESS (CLK, next_sreg, next_CLEAR_SUM, next_SUM_FROM_TC_GO)
	BEGIN
		IF CLK='1' AND CLK'event THEN
			sreg <= next_sreg;
			CLEAR_SUM <= next_CLEAR_SUM;
			SUM_FROM_TC_GO <= next_SUM_FROM_TC_GO;
		END IF;
	END PROCESS;

	PROCESS (CLK, next_sreg1, next_CLR_COUNTS, next_COUNT_SAMPLES, next_counting
		, next_ft_done, next_ft_end, next_ft_give, next_INC_PTW_PTR_TDC, 
		next_load_samples, next_RT_PTW_PTR_LS)
	BEGIN
		IF CLK='1' AND CLK'event THEN
			sreg1 <= next_sreg1;
			CLR_COUNTS <= next_CLR_COUNTS;
			COUNT_SAMPLES <= next_COUNT_SAMPLES;
			counting <= next_counting;
			ft_done <= next_ft_done;
			ft_end <= next_ft_end;
			ft_give <= next_ft_give;
			INC_PTW_PTR_TDC <= next_INC_PTW_PTR_TDC;
			load_samples <= next_load_samples;
			RT_PTW_PTR_LS <= next_RT_PTW_PTR_LS;
		END IF;
	END PROCESS;

	PROCESS (CLK, next_sreg2, next_CHECK_MAX_GO, next_FIND_MAX_GO, 
		next_FIND_TROUGH_GO, next_SLOPE_CHECK, next_STORE_MAX)
	BEGIN
		IF CLK='1' AND CLK'event THEN
			sreg2 <= next_sreg2;
			CHECK_MAX_GO <= next_CHECK_MAX_GO;
			FIND_MAX_GO <= next_FIND_MAX_GO;
			FIND_TROUGH_GO <= next_FIND_TROUGH_GO;
			SLOPE_CHECK <= next_SLOPE_CHECK;
			STORE_MAX <= next_STORE_MAX;
		END IF;
	END PROCESS;

	PROCESS (sreg,sreg1,sreg2,BUSY,CHECK_MAX_FOUND,counting,ft_end,
		FT_START_FROM_LS,FT_START_FROM_NU,GO,JUST_WE,LE_SAMPLE_FOUND,load_done,
		MAX_FOUND,PEAK_DONE,PTW_DONE,RESET_N,SLOPE_FOUND,TROUGH_FOUND,WE_DONE)
	BEGIN
		next_CHECK_MAX_GO <= '0'; next_CLEAR_SUM <= '0'; next_CLR_COUNTS <= '0'; 
			next_COUNT_SAMPLES <= '0'; next_counting <= '0'; next_FIND_MAX_GO <= '0'; 
			next_FIND_TROUGH_GO <= '0'; next_ft_done <= '0'; next_ft_end <= '0'; 
			next_ft_give <= '0'; next_INC_PTW_PTR_TDC <= '0'; next_load_samples <= '0'; 
			next_RT_PTW_PTR_LS <= '0'; next_SLOPE_CHECK <= '0'; next_STORE_MAX <= '0'; 
			next_SUM_FROM_TC_GO <= '0'; 

		next_sreg<=IDLE_SUM;
		next_sreg1<=back_to_NU;
		next_sreg2<=CHECK_MAX;

		IF ( RESET_N='0' ) THEN
			next_sreg<=IDLE_SUM;
			next_SUM_FROM_TC_GO<='0';
			next_CLEAR_SUM<='0';
		ELSE
			CASE sreg IS
				WHEN IDLE_SUM =>
					IF ( counting='1' ) THEN
						next_sreg<=STATE9;
						next_SUM_FROM_TC_GO<='0';
						next_CLEAR_SUM<='0';
					 ELSE
						next_sreg<=IDLE_SUM;
						next_SUM_FROM_TC_GO<='0';
						next_CLEAR_SUM<='0';
					END IF;
				WHEN STATE5 =>
					next_sreg<=STATE12;
					next_SUM_FROM_TC_GO<='0';
					next_CLEAR_SUM<='0';
				WHEN STATE9 =>
					IF ( WE_DONE='1' ) THEN
						next_sreg<=STATE5;
						next_SUM_FROM_TC_GO<='0';
						next_CLEAR_SUM<='1';
					ELSIF ( FT_START_FROM_LS='1' ) THEN
						next_sreg<=SUM_FROM_TC;
						next_CLEAR_SUM<='0';
						next_SUM_FROM_TC_GO<='1';
					 ELSE
						next_sreg<=STATE9;
						next_SUM_FROM_TC_GO<='0';
						next_CLEAR_SUM<='0';
					END IF;
				WHEN STATE12 =>
					IF ( ft_end='1' ) THEN
						next_sreg<=IDLE_SUM;
						next_SUM_FROM_TC_GO<='0';
						next_CLEAR_SUM<='0';
					 ELSE
						next_sreg<=STATE12;
						next_SUM_FROM_TC_GO<='0';
						next_CLEAR_SUM<='0';
					END IF;
				WHEN SUM_FROM_TC =>
					IF ( WE_DONE='1' ) THEN
						next_sreg<=STATE5;
						next_SUM_FROM_TC_GO<='0';
						next_CLEAR_SUM<='1';
					 ELSE
						next_sreg<=SUM_FROM_TC;
						next_CLEAR_SUM<='0';
						next_SUM_FROM_TC_GO<='1';
					END IF;
				WHEN OTHERS =>
			END CASE;
		END IF;

		IF ( RESET_N='0' ) THEN
			next_sreg1<=Idle;
			next_RT_PTW_PTR_LS<='0';
			next_load_samples<='0';
			next_INC_PTW_PTR_TDC<='0';
			next_ft_give<='0';
			next_ft_end<='0';
			next_ft_done<='0';
			next_counting<='0';
			next_COUNT_SAMPLES<='0';
			next_CLR_COUNTS<='0';
		ELSE
			CASE sreg1 IS
				WHEN back_to_NU =>
					IF ( FT_START_FROM_NU='1' ) THEN
						next_sreg1<=STATE2;
						next_RT_PTW_PTR_LS<='0';
						next_load_samples<='0';
						next_INC_PTW_PTR_TDC<='0';
						next_ft_give<='0';
						next_ft_end<='0';
						next_ft_done<='0';
						next_counting<='0';
						next_COUNT_SAMPLES<='0';
						next_CLR_COUNTS<='0';
					 ELSE
						next_sreg1<=back_to_NU;
						next_RT_PTW_PTR_LS<='0';
						next_load_samples<='0';
						next_ft_give<='0';
						next_ft_end<='0';
						next_ft_done<='0';
						next_counting<='0';
						next_CLR_COUNTS<='0';
						next_INC_PTW_PTR_TDC<='1';
						next_COUNT_SAMPLES<='1';
					END IF;
				WHEN Cnt_INC_PTW_TDC =>
					IF ( FT_START_FROM_NU='1' ) THEN
						next_sreg1<=STATE6;
						next_RT_PTW_PTR_LS<='0';
						next_load_samples<='0';
						next_ft_give<='0';
						next_ft_end<='0';
						next_ft_done<='0';
						next_counting<='0';
						next_COUNT_SAMPLES<='0';
						next_CLR_COUNTS<='0';
						next_INC_PTW_PTR_TDC<='1';
					 ELSE
						next_sreg1<=Cnt_INC_PTW_TDC;
						next_RT_PTW_PTR_LS<='0';
						next_load_samples<='0';
						next_ft_give<='0';
						next_ft_end<='0';
						next_ft_done<='0';
						next_counting<='0';
						next_COUNT_SAMPLES<='0';
						next_CLR_COUNTS<='0';
						next_INC_PTW_PTR_TDC<='1';
					END IF;
				WHEN FINISH_PTW =>
					IF ( PTW_DONE='1' ) THEN
						next_sreg1<=wait_for_busy;
						next_RT_PTW_PTR_LS<='0';
						next_load_samples<='0';
						next_INC_PTW_PTR_TDC<='0';
						next_ft_give<='0';
						next_ft_end<='0';
						next_ft_done<='0';
						next_counting<='0';
						next_COUNT_SAMPLES<='0';
						next_CLR_COUNTS<='0';
					 ELSE
						next_sreg1<=FINISH_PTW;
						next_RT_PTW_PTR_LS<='0';
						next_load_samples<='0';
						next_ft_give<='0';
						next_ft_end<='0';
						next_ft_done<='0';
						next_CLR_COUNTS<='0';
						next_INC_PTW_PTR_TDC<='1';
						next_COUNT_SAMPLES<='1';
						next_counting<='1';
					END IF;
				WHEN Idle =>
					IF ( GO='1' ) THEN
						next_sreg1<=Cnt_INC_PTW_TDC;
						next_RT_PTW_PTR_LS<='0';
						next_load_samples<='0';
						next_ft_give<='0';
						next_ft_end<='0';
						next_ft_done<='0';
						next_counting<='0';
						next_COUNT_SAMPLES<='0';
						next_CLR_COUNTS<='0';
						next_INC_PTW_PTR_TDC<='1';
					 ELSE
						next_sreg1<=Idle;
						next_RT_PTW_PTR_LS<='0';
						next_load_samples<='0';
						next_INC_PTW_PTR_TDC<='0';
						next_ft_give<='0';
						next_ft_end<='0';
						next_ft_done<='0';
						next_counting<='0';
						next_COUNT_SAMPLES<='0';
						next_CLR_COUNTS<='0';
					END IF;
				WHEN STATE1 =>
					next_sreg1<=back_to_NU;
					next_RT_PTW_PTR_LS<='0';
					next_load_samples<='0';
					next_ft_give<='0';
					next_ft_end<='0';
					next_ft_done<='0';
					next_counting<='0';
					next_CLR_COUNTS<='0';
					next_INC_PTW_PTR_TDC<='1';
					next_COUNT_SAMPLES<='1';
				WHEN STATE2 =>
					IF ( LE_SAMPLE_FOUND='1' ) THEN
						next_sreg1<=FINISH_PTW;
						next_RT_PTW_PTR_LS<='0';
						next_load_samples<='0';
						next_ft_give<='0';
						next_ft_end<='0';
						next_ft_done<='0';
						next_CLR_COUNTS<='0';
						next_INC_PTW_PTR_TDC<='1';
						next_COUNT_SAMPLES<='1';
						next_counting<='1';
					 ELSE
						next_sreg1<=STATE2;
						next_RT_PTW_PTR_LS<='0';
						next_load_samples<='0';
						next_INC_PTW_PTR_TDC<='0';
						next_ft_give<='0';
						next_ft_end<='0';
						next_ft_done<='0';
						next_counting<='0';
						next_COUNT_SAMPLES<='0';
						next_CLR_COUNTS<='0';
					END IF;
				WHEN STATE3 =>
					IF ( load_done='1' ) THEN
						next_sreg1<=STATE1;
						next_load_samples<='0';
						next_INC_PTW_PTR_TDC<='0';
						next_ft_give<='0';
						next_ft_end<='0';
						next_ft_done<='0';
						next_counting<='0';
						next_COUNT_SAMPLES<='0';
						next_RT_PTW_PTR_LS<='1';
						next_CLR_COUNTS<='1';
					 ELSE
						next_sreg1<=STATE3;
						next_RT_PTW_PTR_LS<='0';
						next_ft_end<='0';
						next_ft_done<='0';
						next_counting<='0';
						next_COUNT_SAMPLES<='0';
						next_CLR_COUNTS<='0';
						next_INC_PTW_PTR_TDC<='1';
						next_load_samples<='1';
						next_ft_give<='1';
					END IF;
				WHEN STATE4 =>
					next_sreg1<=Idle;
					next_RT_PTW_PTR_LS<='0';
					next_load_samples<='0';
					next_INC_PTW_PTR_TDC<='0';
					next_ft_give<='0';
					next_ft_end<='0';
					next_ft_done<='0';
					next_counting<='0';
					next_COUNT_SAMPLES<='0';
					next_CLR_COUNTS<='0';
				WHEN STATE6 =>
					next_sreg1<=STATE3;
					next_RT_PTW_PTR_LS<='0';
					next_ft_end<='0';
					next_ft_done<='0';
					next_counting<='0';
					next_COUNT_SAMPLES<='0';
					next_CLR_COUNTS<='0';
					next_INC_PTW_PTR_TDC<='1';
					next_load_samples<='1';
					next_ft_give<='1';
				WHEN wait_for_busy =>
					IF ( BUSY='1' ) THEN
						next_sreg1<=STATE4;
						next_RT_PTW_PTR_LS<='0';
						next_load_samples<='0';
						next_INC_PTW_PTR_TDC<='0';
						next_ft_give<='0';
						next_counting<='0';
						next_COUNT_SAMPLES<='0';
						next_CLR_COUNTS<='0';
						next_ft_done<='1';
						next_ft_end<='1';
					 ELSE
						next_sreg1<=wait_for_busy;
						next_RT_PTW_PTR_LS<='0';
						next_load_samples<='0';
						next_INC_PTW_PTR_TDC<='0';
						next_ft_give<='0';
						next_ft_end<='0';
						next_ft_done<='0';
						next_counting<='0';
						next_COUNT_SAMPLES<='0';
						next_CLR_COUNTS<='0';
					END IF;
				WHEN OTHERS =>
			END CASE;
		END IF;

		IF ( RESET_N='0' ) THEN
			next_sreg2<=IDLE_PEAK;
			next_STORE_MAX<='0';
			next_SLOPE_CHECK<='0';
			next_FIND_TROUGH_GO<='0';
			next_FIND_MAX_GO<='0';
			next_CHECK_MAX_GO<='0';
		ELSE
			CASE sreg2 IS
				WHEN CHECK_MAX =>
					IF ( JUST_WE='1' AND CHECK_MAX_FOUND='1' ) THEN
						next_sreg2<=STATE8;
						next_STORE_MAX<='0';
						next_SLOPE_CHECK<='0';
						next_FIND_TROUGH_GO<='0';
						next_FIND_MAX_GO<='0';
						next_CHECK_MAX_GO<='0';
					ELSIF ( JUST_WE='1' AND CHECK_MAX_FOUND='0' ) THEN
						next_sreg2<=STATE7;
						next_STORE_MAX<='0';
						next_SLOPE_CHECK<='0';
						next_FIND_TROUGH_GO<='0';
						next_CHECK_MAX_GO<='0';
						next_FIND_MAX_GO<='1';
					ELSIF ( CHECK_MAX_FOUND='0' ) THEN
						next_sreg2<=FIND_MAX;
						next_STORE_MAX<='0';
						next_SLOPE_CHECK<='0';
						next_FIND_TROUGH_GO<='0';
						next_CHECK_MAX_GO<='0';
						next_FIND_MAX_GO<='1';
					ELSIF ( CHECK_MAX_FOUND='1' ) THEN
						next_sreg2<=STATE0;
						next_SLOPE_CHECK<='0';
						next_FIND_TROUGH_GO<='0';
						next_FIND_MAX_GO<='0';
						next_CHECK_MAX_GO<='0';
						next_STORE_MAX<='1';
					END IF;
				WHEN FIND_MAX =>
					IF ( JUST_WE='1' AND MAX_FOUND='1' ) THEN
						next_sreg2<=STATE8;
						next_STORE_MAX<='0';
						next_SLOPE_CHECK<='0';
						next_FIND_TROUGH_GO<='0';
						next_FIND_MAX_GO<='0';
						next_CHECK_MAX_GO<='0';
					ELSIF ( JUST_WE='1' AND MAX_FOUND='0' ) THEN
						next_sreg2<=STATE7;
						next_STORE_MAX<='0';
						next_SLOPE_CHECK<='0';
						next_FIND_TROUGH_GO<='0';
						next_CHECK_MAX_GO<='0';
						next_FIND_MAX_GO<='1';
					ELSIF ( JUST_WE='0' AND MAX_FOUND='1' ) THEN
						next_sreg2<=CHECK_MAX;
						next_STORE_MAX<='0';
						next_SLOPE_CHECK<='0';
						next_FIND_TROUGH_GO<='0';
						next_FIND_MAX_GO<='0';
						next_CHECK_MAX_GO<='1';
					 ELSE
						next_sreg2<=FIND_MAX;
						next_STORE_MAX<='0';
						next_SLOPE_CHECK<='0';
						next_FIND_TROUGH_GO<='0';
						next_CHECK_MAX_GO<='0';
						next_FIND_MAX_GO<='1';
					END IF;
				WHEN FIND_TROUGH =>
					IF ( JUST_WE='1' ) THEN
						next_sreg2<=STATE11;
						next_STORE_MAX<='0';
						next_SLOPE_CHECK<='0';
						next_FIND_TROUGH_GO<='0';
						next_FIND_MAX_GO<='0';
						next_CHECK_MAX_GO<='0';
					ELSIF ( PEAK_DONE='1' ) THEN
						next_sreg2<=wait_for_WE;
						next_STORE_MAX<='0';
						next_SLOPE_CHECK<='0';
						next_FIND_TROUGH_GO<='0';
						next_FIND_MAX_GO<='0';
						next_CHECK_MAX_GO<='0';
					ELSIF ( TROUGH_FOUND='0' ) THEN
						next_sreg2<=WAIT_4_TROUGH;
						next_STORE_MAX<='0';
						next_SLOPE_CHECK<='0';
						next_FIND_MAX_GO<='0';
						next_CHECK_MAX_GO<='0';
						next_FIND_TROUGH_GO<='1';
					ELSIF ( TROUGH_FOUND='1' ) THEN
						next_sreg2<=FIND_MAX;
						next_STORE_MAX<='0';
						next_SLOPE_CHECK<='0';
						next_FIND_TROUGH_GO<='0';
						next_CHECK_MAX_GO<='0';
						next_FIND_MAX_GO<='1';
					END IF;
				WHEN IDLE_PEAK =>
					IF ( counting='1' ) THEN
						next_sreg2<=STATE10;
						next_STORE_MAX<='0';
						next_SLOPE_CHECK<='0';
						next_FIND_TROUGH_GO<='0';
						next_FIND_MAX_GO<='0';
						next_CHECK_MAX_GO<='0';
					 ELSE
						next_sreg2<=IDLE_PEAK;
						next_STORE_MAX<='0';
						next_SLOPE_CHECK<='0';
						next_FIND_TROUGH_GO<='0';
						next_FIND_MAX_GO<='0';
						next_CHECK_MAX_GO<='0';
					END IF;
				WHEN PEAK_AT_PTW_END =>
					next_sreg2<=STATE13;
					next_STORE_MAX<='0';
					next_SLOPE_CHECK<='0';
					next_FIND_TROUGH_GO<='0';
					next_FIND_MAX_GO<='0';
					next_CHECK_MAX_GO<='0';
				WHEN STATE0 =>
					IF ( JUST_WE='1' ) THEN
						next_sreg2<=STATE11;
						next_STORE_MAX<='0';
						next_SLOPE_CHECK<='0';
						next_FIND_TROUGH_GO<='0';
						next_FIND_MAX_GO<='0';
						next_CHECK_MAX_GO<='0';
					ELSIF ( JUST_WE='0' ) THEN
						next_sreg2<=WAIT_4_TROUGH;
						next_STORE_MAX<='0';
						next_SLOPE_CHECK<='0';
						next_FIND_MAX_GO<='0';
						next_CHECK_MAX_GO<='0';
						next_FIND_TROUGH_GO<='1';
					END IF;
				WHEN STATE7 =>
					next_sreg2<=PEAK_AT_PTW_END;
					next_SLOPE_CHECK<='0';
					next_FIND_TROUGH_GO<='0';
					next_FIND_MAX_GO<='0';
					next_CHECK_MAX_GO<='0';
					next_STORE_MAX<='1';
				WHEN STATE8 =>
					next_sreg2<=PEAK_AT_PTW_END;
					next_SLOPE_CHECK<='0';
					next_FIND_TROUGH_GO<='0';
					next_FIND_MAX_GO<='0';
					next_CHECK_MAX_GO<='0';
					next_STORE_MAX<='1';
				WHEN STATE10 =>
					IF ( JUST_WE='1' ) THEN
						next_sreg2<=STATE7;
						next_STORE_MAX<='0';
						next_SLOPE_CHECK<='0';
						next_FIND_TROUGH_GO<='0';
						next_CHECK_MAX_GO<='0';
						next_FIND_MAX_GO<='1';
					ELSIF ( FT_START_FROM_LS='1' ) THEN
						next_sreg2<=STATE14;
						next_STORE_MAX<='0';
						next_FIND_TROUGH_GO<='0';
						next_FIND_MAX_GO<='0';
						next_CHECK_MAX_GO<='0';
						next_SLOPE_CHECK<='1';
					 ELSE
						next_sreg2<=STATE10;
						next_STORE_MAX<='0';
						next_SLOPE_CHECK<='0';
						next_FIND_TROUGH_GO<='0';
						next_FIND_MAX_GO<='0';
						next_CHECK_MAX_GO<='0';
					END IF;
				WHEN STATE11 =>
					IF ( ft_end='1' ) THEN
						next_sreg2<=IDLE_PEAK;
						next_STORE_MAX<='0';
						next_SLOPE_CHECK<='0';
						next_FIND_TROUGH_GO<='0';
						next_FIND_MAX_GO<='0';
						next_CHECK_MAX_GO<='0';
					 ELSE
						next_sreg2<=STATE11;
						next_STORE_MAX<='0';
						next_SLOPE_CHECK<='0';
						next_FIND_TROUGH_GO<='0';
						next_FIND_MAX_GO<='0';
						next_CHECK_MAX_GO<='0';
					END IF;
				WHEN STATE13 =>
					IF ( ft_end='1' ) THEN
						next_sreg2<=IDLE_PEAK;
						next_STORE_MAX<='0';
						next_SLOPE_CHECK<='0';
						next_FIND_TROUGH_GO<='0';
						next_FIND_MAX_GO<='0';
						next_CHECK_MAX_GO<='0';
					 ELSE
						next_sreg2<=STATE13;
						next_STORE_MAX<='0';
						next_SLOPE_CHECK<='0';
						next_FIND_TROUGH_GO<='0';
						next_FIND_MAX_GO<='0';
						next_CHECK_MAX_GO<='0';
					END IF;
				WHEN STATE14 =>
					IF ( JUST_WE='1' ) THEN
						next_sreg2<=STATE7;
						next_STORE_MAX<='0';
						next_SLOPE_CHECK<='0';
						next_FIND_TROUGH_GO<='0';
						next_CHECK_MAX_GO<='0';
						next_FIND_MAX_GO<='1';
					ELSIF ( SLOPE_FOUND='1' ) THEN
						next_sreg2<=FIND_MAX;
						next_STORE_MAX<='0';
						next_SLOPE_CHECK<='0';
						next_FIND_TROUGH_GO<='0';
						next_CHECK_MAX_GO<='0';
						next_FIND_MAX_GO<='1';
					 ELSE
						next_sreg2<=STATE14;
						next_STORE_MAX<='0';
						next_FIND_TROUGH_GO<='0';
						next_FIND_MAX_GO<='0';
						next_CHECK_MAX_GO<='0';
						next_SLOPE_CHECK<='1';
					END IF;
				WHEN WAIT_4_TROUGH =>
					IF ( JUST_WE='1' ) THEN
						next_sreg2<=STATE11;
						next_STORE_MAX<='0';
						next_SLOPE_CHECK<='0';
						next_FIND_TROUGH_GO<='0';
						next_FIND_MAX_GO<='0';
						next_CHECK_MAX_GO<='0';
					ELSIF ( TROUGH_FOUND='1' ) THEN
						next_sreg2<=FIND_TROUGH;
						next_STORE_MAX<='0';
						next_SLOPE_CHECK<='0';
						next_FIND_MAX_GO<='0';
						next_CHECK_MAX_GO<='0';
						next_FIND_TROUGH_GO<='1';
					 ELSE
						next_sreg2<=WAIT_4_TROUGH;
						next_STORE_MAX<='0';
						next_SLOPE_CHECK<='0';
						next_FIND_MAX_GO<='0';
						next_CHECK_MAX_GO<='0';
						next_FIND_TROUGH_GO<='1';
					END IF;
				WHEN wait_for_WE =>
					IF ( JUST_WE='1' ) THEN
						next_sreg2<=STATE11;
						next_STORE_MAX<='0';
						next_SLOPE_CHECK<='0';
						next_FIND_TROUGH_GO<='0';
						next_FIND_MAX_GO<='0';
						next_CHECK_MAX_GO<='0';
					 ELSE
						next_sreg2<=wait_for_WE;
						next_STORE_MAX<='0';
						next_SLOPE_CHECK<='0';
						next_FIND_TROUGH_GO<='0';
						next_FIND_MAX_GO<='0';
						next_CHECK_MAX_GO<='0';
					END IF;
				WHEN OTHERS =>
			END CASE;
		END IF;
	END PROCESS;
END BEHAVIOR;
