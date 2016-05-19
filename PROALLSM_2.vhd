--  C:\USERS\DICKOVER\DOCUMENTS\...\PROALLSM_2.vhd
--  VHDL code created by Xilinx's StateCAD 10.1
--  Sun Oct 11 16:13:06 2015

--  This VHDL code (for use with IEEE compliant tools) was generated using: 
--  enumerated state assignment with structured code format.
--  Minimization is enabled,  implied else is enabled, 
--  and outputs are speed optimized.

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY SHELL_PROALLSM_2 IS
	PORT (CLK,GO,ProIdle,RESET_N: IN std_logic;
		DEC_PTW_CNT0,DEC_PTW_CNT1,DEC_PTW_CNT2,DEC_PTW_CNT3,DEC_PTW_CNT4,
			DEC_PTW_CNT5,GoProc,IDLE,LD_PTW_RAM_ADR0,LD_PTW_RAM_ADR1,LD_PTW_RAM_ADR2,
			LD_PTW_RAM_ADR3,LD_PTW_RAM_ADR4,LD_PTW_RAM_ADR5,ST_PTW_RAM_ADR0,
			ST_PTW_RAM_ADR1,TEST_OUT : OUT std_logic);

	SIGNAL DONE_PROCESS,WaitEn_2: std_logic;
END;

ARCHITECTURE BEHAVIOR OF SHELL_PROALLSM_2 IS
	TYPE type_sreg IS (LdStartPtwRamAdr,Main_IDLE,Mode_0,StStartPtwAdr,
		WaittMode0Done);
	SIGNAL sreg, next_sreg : type_sreg;
	TYPE type_sreg1 IS (WaitDone2,WaitForDoneIdle,WaitProcDoneHi,WaitProcDoneLo)
		;
	SIGNAL sreg1, next_sreg1 : type_sreg1;
	SIGNAL next_DEC_PTW_CNT0,next_DEC_PTW_CNT1,next_DEC_PTW_CNT2,
		next_DEC_PTW_CNT3,next_DEC_PTW_CNT4,next_DEC_PTW_CNT5,next_DONE_PROCESS,
		next_GoProc,next_IDLE,next_LD_PTW_RAM_ADR0,next_LD_PTW_RAM_ADR1,
		next_LD_PTW_RAM_ADR2,next_LD_PTW_RAM_ADR3,next_LD_PTW_RAM_ADR4,
		next_LD_PTW_RAM_ADR5,next_ST_PTW_RAM_ADR0,next_ST_PTW_RAM_ADR1,next_TEST_OUT,
		next_WaitEn_2 : std_logic;
	SIGNAL DEC_PTW_CNT : std_logic_vector (5 DOWNTO 0);
	SIGNAL LD_PTW_RAM_ADR : std_logic_vector (5 DOWNTO 0);
	SIGNAL ST_PTW_RAM_ADR : std_logic_vector (1 DOWNTO 0);
BEGIN
	PROCESS (CLK, next_sreg, next_GoProc, next_IDLE, next_TEST_OUT, 
		next_WaitEn_2, next_DEC_PTW_CNT5, next_DEC_PTW_CNT4, next_DEC_PTW_CNT3, 
		next_DEC_PTW_CNT2, next_DEC_PTW_CNT1, next_DEC_PTW_CNT0, next_LD_PTW_RAM_ADR5
		, next_LD_PTW_RAM_ADR4, next_LD_PTW_RAM_ADR3, next_LD_PTW_RAM_ADR2, 
		next_LD_PTW_RAM_ADR1, next_LD_PTW_RAM_ADR0, next_ST_PTW_RAM_ADR1, 
		next_ST_PTW_RAM_ADR0)
	BEGIN
		IF CLK='1' AND CLK'event THEN
			sreg <= next_sreg;
			GoProc <= next_GoProc;
			IDLE <= next_IDLE;
			TEST_OUT <= next_TEST_OUT;
			WaitEn_2 <= next_WaitEn_2;
			DEC_PTW_CNT5 <= next_DEC_PTW_CNT5;
			DEC_PTW_CNT4 <= next_DEC_PTW_CNT4;
			DEC_PTW_CNT3 <= next_DEC_PTW_CNT3;
			DEC_PTW_CNT2 <= next_DEC_PTW_CNT2;
			DEC_PTW_CNT1 <= next_DEC_PTW_CNT1;
			DEC_PTW_CNT0 <= next_DEC_PTW_CNT0;
			LD_PTW_RAM_ADR5 <= next_LD_PTW_RAM_ADR5;
			LD_PTW_RAM_ADR4 <= next_LD_PTW_RAM_ADR4;
			LD_PTW_RAM_ADR3 <= next_LD_PTW_RAM_ADR3;
			LD_PTW_RAM_ADR2 <= next_LD_PTW_RAM_ADR2;
			LD_PTW_RAM_ADR1 <= next_LD_PTW_RAM_ADR1;
			LD_PTW_RAM_ADR0 <= next_LD_PTW_RAM_ADR0;
			ST_PTW_RAM_ADR1 <= next_ST_PTW_RAM_ADR1;
			ST_PTW_RAM_ADR0 <= next_ST_PTW_RAM_ADR0;
		END IF;
	END PROCESS;

	PROCESS (CLK, next_sreg1, next_DONE_PROCESS)
	BEGIN
		IF CLK='1' AND CLK'event THEN
			sreg1 <= next_sreg1;
			DONE_PROCESS <= next_DONE_PROCESS;
		END IF;
	END PROCESS;

	PROCESS (sreg,sreg1,DONE_PROCESS,GO,ProIdle,RESET_N,WaitEn_2,DEC_PTW_CNT,
		LD_PTW_RAM_ADR,ST_PTW_RAM_ADR)
	BEGIN
		next_DEC_PTW_CNT0 <= '0'; next_DEC_PTW_CNT1 <= '0'; next_DEC_PTW_CNT2 <= 
			'0'; next_DEC_PTW_CNT3 <= '0'; next_DEC_PTW_CNT4 <= '0'; next_DEC_PTW_CNT5 <=
			 '0'; next_DONE_PROCESS <= '0'; next_GoProc <= '0'; next_IDLE <= '0'; 
			next_LD_PTW_RAM_ADR0 <= '0'; next_LD_PTW_RAM_ADR1 <= '0'; 
			next_LD_PTW_RAM_ADR2 <= '0'; next_LD_PTW_RAM_ADR3 <= '0'; 
			next_LD_PTW_RAM_ADR4 <= '0'; next_LD_PTW_RAM_ADR5 <= '0'; 
			next_ST_PTW_RAM_ADR0 <= '0'; next_ST_PTW_RAM_ADR1 <= '0'; next_TEST_OUT <= 
			'0'; next_WaitEn_2 <= '0'; 
		DEC_PTW_CNT<=std_logic_vector'("000000"); LD_PTW_RAM_ADR<=std_logic_vector'
			("000000"); ST_PTW_RAM_ADR<=std_logic_vector'("00"); 

		next_sreg<=LdStartPtwRamAdr;
		next_sreg1<=WaitDone2;

		IF ( RESET_N='0' ) THEN
			next_sreg<=Main_IDLE;
			next_WaitEn_2<='0';
			next_TEST_OUT<='0';
			next_GoProc<='0';
			next_IDLE<='1';

			DEC_PTW_CNT <= (std_logic_vector'("000000"));
			LD_PTW_RAM_ADR <= (std_logic_vector'("000000"));
			ST_PTW_RAM_ADR <= (std_logic_vector'("00"));
		ELSE
			CASE sreg IS
				WHEN LdStartPtwRamAdr =>
					next_sreg<=Mode_0;
					next_WaitEn_2<='0';
					next_TEST_OUT<='0';
					next_IDLE<='0';
					next_GoProc<='1';

					DEC_PTW_CNT <= (std_logic_vector'("000000"));
					LD_PTW_RAM_ADR <= (std_logic_vector'("000000"));
					ST_PTW_RAM_ADR <= (std_logic_vector'("00"));
				WHEN Main_IDLE =>
					IF ( GO='1' ) THEN
						next_sreg<=StStartPtwAdr;
						next_WaitEn_2<='0';
						next_IDLE<='0';
						next_GoProc<='0';
						next_TEST_OUT<='1';

						LD_PTW_RAM_ADR <= (std_logic_vector'("000000"));
						DEC_PTW_CNT <= (std_logic_vector'("111111"));
						ST_PTW_RAM_ADR <= (std_logic_vector'("11"));
					 ELSE
						next_sreg<=Main_IDLE;
						next_WaitEn_2<='0';
						next_TEST_OUT<='0';
						next_GoProc<='0';
						next_IDLE<='1';

						DEC_PTW_CNT <= (std_logic_vector'("000000"));
						LD_PTW_RAM_ADR <= (std_logic_vector'("000000"));
						ST_PTW_RAM_ADR <= (std_logic_vector'("00"));
					END IF;
				WHEN Mode_0 =>
					next_sreg<=WaittMode0Done;
					next_TEST_OUT<='0';
					next_IDLE<='0';
					next_GoProc<='0';
					next_WaitEn_2<='1';

					DEC_PTW_CNT <= (std_logic_vector'("000000"));
					LD_PTW_RAM_ADR <= (std_logic_vector'("000000"));
					ST_PTW_RAM_ADR <= (std_logic_vector'("00"));
				WHEN StStartPtwAdr =>
					next_sreg<=LdStartPtwRamAdr;
					next_WaitEn_2<='0';
					next_TEST_OUT<='0';
					next_IDLE<='0';
					next_GoProc<='0';

					DEC_PTW_CNT <= (std_logic_vector'("000000"));
					ST_PTW_RAM_ADR <= (std_logic_vector'("00"));
					LD_PTW_RAM_ADR <= (std_logic_vector'("111111"));
				WHEN WaittMode0Done =>
					IF ( DONE_PROCESS='1' ) THEN
						next_sreg<=Main_IDLE;
						next_WaitEn_2<='0';
						next_TEST_OUT<='0';
						next_GoProc<='0';
						next_IDLE<='1';

						DEC_PTW_CNT <= (std_logic_vector'("000000"));
						LD_PTW_RAM_ADR <= (std_logic_vector'("000000"));
						ST_PTW_RAM_ADR <= (std_logic_vector'("00"));
					 ELSE
						next_sreg<=WaittMode0Done;
						next_TEST_OUT<='0';
						next_IDLE<='0';
						next_GoProc<='0';
						next_WaitEn_2<='1';

						DEC_PTW_CNT <= (std_logic_vector'("000000"));
						LD_PTW_RAM_ADR <= (std_logic_vector'("000000"));
						ST_PTW_RAM_ADR <= (std_logic_vector'("00"));
					END IF;
				WHEN OTHERS =>
			END CASE;
		END IF;

		IF ( RESET_N='0' ) THEN
			next_sreg1<=WaitForDoneIdle;
			next_DONE_PROCESS<='0';
		ELSE
			CASE sreg1 IS
				WHEN WaitDone2 =>
					next_sreg1<=WaitForDoneIdle;
					next_DONE_PROCESS<='0';
				WHEN WaitForDoneIdle =>
					IF ( WaitEn_2='1' ) THEN
						next_sreg1<=WaitProcDoneLo;
						next_DONE_PROCESS<='0';
					 ELSE
						next_sreg1<=WaitForDoneIdle;
						next_DONE_PROCESS<='0';
					END IF;
				WHEN WaitProcDoneHi =>
					IF ( ProIdle='1' ) THEN
						next_sreg1<=WaitDone2;
						next_DONE_PROCESS<='1';
					 ELSE
						next_sreg1<=WaitProcDoneHi;
						next_DONE_PROCESS<='0';
					END IF;
				WHEN WaitProcDoneLo =>
					IF ( ProIdle='0' ) THEN
						next_sreg1<=WaitProcDoneHi;
						next_DONE_PROCESS<='0';
					 ELSE
						next_sreg1<=WaitProcDoneLo;
						next_DONE_PROCESS<='0';
					END IF;
				WHEN OTHERS =>
			END CASE;
		END IF;

		next_DEC_PTW_CNT5 <= DEC_PTW_CNT(5);
		next_DEC_PTW_CNT4 <= DEC_PTW_CNT(4);
		next_DEC_PTW_CNT3 <= DEC_PTW_CNT(3);
		next_DEC_PTW_CNT2 <= DEC_PTW_CNT(2);
		next_DEC_PTW_CNT1 <= DEC_PTW_CNT(1);
		next_DEC_PTW_CNT0 <= DEC_PTW_CNT(0);
		next_LD_PTW_RAM_ADR5 <= LD_PTW_RAM_ADR(5);
		next_LD_PTW_RAM_ADR4 <= LD_PTW_RAM_ADR(4);
		next_LD_PTW_RAM_ADR3 <= LD_PTW_RAM_ADR(3);
		next_LD_PTW_RAM_ADR2 <= LD_PTW_RAM_ADR(2);
		next_LD_PTW_RAM_ADR1 <= LD_PTW_RAM_ADR(1);
		next_LD_PTW_RAM_ADR0 <= LD_PTW_RAM_ADR(0);
		next_ST_PTW_RAM_ADR1 <= ST_PTW_RAM_ADR(1);
		next_ST_PTW_RAM_ADR0 <= ST_PTW_RAM_ADR(0);
	END PROCESS;
END BEHAVIOR;

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY PROALLSM_2 IS
	PORT (DEC_PTW_CNT : OUT std_logic_vector (5 DOWNTO 0);
		LD_PTW_RAM_ADR : OUT std_logic_vector (5 DOWNTO 0);
		ST_PTW_RAM_ADR : OUT std_logic_vector (1 DOWNTO 0);
		CLK,GO,ProIdle,RESET_N: IN std_logic;
		GoProc,IDLE,TEST_OUT : OUT std_logic);
END;

ARCHITECTURE BEHAVIOR OF PROALLSM_2 IS
	COMPONENT SHELL_PROALLSM_2
		PORT (CLK,GO,ProIdle,RESET_N: IN std_logic;
			DEC_PTW_CNT0,DEC_PTW_CNT1,DEC_PTW_CNT2,DEC_PTW_CNT3,DEC_PTW_CNT4,
				DEC_PTW_CNT5,GoProc,IDLE,LD_PTW_RAM_ADR0,LD_PTW_RAM_ADR1,LD_PTW_RAM_ADR2,
				LD_PTW_RAM_ADR3,LD_PTW_RAM_ADR4,LD_PTW_RAM_ADR5,ST_PTW_RAM_ADR0,
				ST_PTW_RAM_ADR1,TEST_OUT : OUT std_logic);
	END COMPONENT;
BEGIN
	SHELL1_PROALLSM_2 : SHELL_PROALLSM_2 PORT MAP (CLK=>CLK,GO=>GO,ProIdle=>
		ProIdle,RESET_N=>RESET_N,DEC_PTW_CNT0=>DEC_PTW_CNT(0),DEC_PTW_CNT1=>
		DEC_PTW_CNT(1),DEC_PTW_CNT2=>DEC_PTW_CNT(2),DEC_PTW_CNT3=>DEC_PTW_CNT(3),
		DEC_PTW_CNT4=>DEC_PTW_CNT(4),DEC_PTW_CNT5=>DEC_PTW_CNT(5),GoProc=>GoProc,IDLE
		=>IDLE,LD_PTW_RAM_ADR0=>LD_PTW_RAM_ADR(0),LD_PTW_RAM_ADR1=>LD_PTW_RAM_ADR(1),
		LD_PTW_RAM_ADR2=>LD_PTW_RAM_ADR(2),LD_PTW_RAM_ADR3=>LD_PTW_RAM_ADR(3),
		LD_PTW_RAM_ADR4=>LD_PTW_RAM_ADR(4),LD_PTW_RAM_ADR5=>LD_PTW_RAM_ADR(5),
		ST_PTW_RAM_ADR0=>ST_PTW_RAM_ADR(0),ST_PTW_RAM_ADR1=>ST_PTW_RAM_ADR(1),
		TEST_OUT=>TEST_OUT);
END BEHAVIOR;
