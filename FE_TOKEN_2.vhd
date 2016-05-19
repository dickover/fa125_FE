--  C:\USERS\DICKOVER\DOCUMENTS\...\FE_TOKEN_2.vhd
--  VHDL code created by Xilinx's StateCAD 10.1
--  Sun Oct 11 16:14:17 2015

--  This VHDL code (for use with Xilinx XST) was generated using: 
--  enumerated state assignment with structured code format.
--  Minimization is enabled,  implied else is enabled, 
--  and outputs are speed optimized.

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY FE_TOKEN_2 IS
	PORT (CLK,Clear_Token,evbTokIn,Event_Go,Read_Done,RESET_N: IN std_logic;
		FERDBUSY,Hold_Token,Send_Token : OUT std_logic);
END;

ARCHITECTURE BEHAVIOR OF FE_TOKEN_2 IS
	TYPE type_sreg IS (Busy_Release,Have_Token,Pass_Token,STATE0,STATE1,STATE2,
		STATE3,STATE4,STATE5,STATE6,STATE7,STATE8,TOKEN_Idle);
	SIGNAL sreg, next_sreg : type_sreg;
	SIGNAL next_FERDBUSY,next_Hold_Token,next_Send_Token : std_logic;
BEGIN
	PROCESS (CLK, next_sreg, next_FERDBUSY, next_Hold_Token, next_Send_Token)
	BEGIN
		IF CLK='1' AND CLK'event THEN
			sreg <= next_sreg;
			FERDBUSY <= next_FERDBUSY;
			Hold_Token <= next_Hold_Token;
			Send_Token <= next_Send_Token;
		END IF;
	END PROCESS;

	PROCESS (sreg,Clear_Token,evbTokIn,Event_Go,Read_Done,RESET_N)
	BEGIN
		next_FERDBUSY <= '0'; next_Hold_Token <= '0'; next_Send_Token <= '0'; 

		next_sreg<=Busy_Release;

		IF ( RESET_N='0' ) THEN
			next_sreg<=TOKEN_Idle;
			next_Send_Token<='0';
			next_Hold_Token<='0';
			next_FERDBUSY<='0';
		ELSE
			CASE sreg IS
				WHEN Busy_Release =>
					IF ( Read_Done='1' ) THEN
						next_sreg<=STATE0;
						next_Send_Token<='0';
						next_Hold_Token<='0';
						next_FERDBUSY<='1';
					 ELSE
						next_sreg<=Busy_Release;
						next_Send_Token<='0';
						next_Hold_Token<='1';
						next_FERDBUSY<='1';
					END IF;
				WHEN Have_Token =>
					IF ( Event_Go='1' ) THEN
						next_sreg<=STATE1;
						next_Send_Token<='0';
						next_Hold_Token<='0';
						next_FERDBUSY<='0';
					 ELSE
						next_sreg<=Have_Token;
						next_Send_Token<='0';
						next_Hold_Token<='0';
						next_FERDBUSY<='0';
					END IF;
				WHEN Pass_Token =>
					IF ( Clear_Token='1' ) THEN
						next_sreg<=STATE3;
						next_Send_Token<='0';
						next_Hold_Token<='0';
						next_FERDBUSY<='0';
					 ELSE
						next_sreg<=Pass_Token;
						next_Hold_Token<='0';
						next_FERDBUSY<='0';
						next_Send_Token<='1';
					END IF;
				WHEN STATE0 =>
					next_sreg<=STATE2;
					next_Send_Token<='0';
					next_Hold_Token<='0';
					next_FERDBUSY<='0';
				WHEN STATE1 =>
					next_sreg<=Busy_Release;
					next_Send_Token<='0';
					next_Hold_Token<='1';
					next_FERDBUSY<='1';
				WHEN STATE2 =>
					next_sreg<=STATE4;
					next_Send_Token<='0';
					next_Hold_Token<='0';
					next_FERDBUSY<='0';
				WHEN STATE3 =>
					next_sreg<=TOKEN_Idle;
					next_Send_Token<='0';
					next_Hold_Token<='0';
					next_FERDBUSY<='0';
				WHEN STATE4 =>
					next_sreg<=STATE5;
					next_Send_Token<='0';
					next_Hold_Token<='0';
					next_FERDBUSY<='0';
				WHEN STATE5 =>
					next_sreg<=STATE6;
					next_Send_Token<='0';
					next_Hold_Token<='0';
					next_FERDBUSY<='0';
				WHEN STATE6 =>
					next_sreg<=STATE7;
					next_Send_Token<='0';
					next_Hold_Token<='0';
					next_FERDBUSY<='0';
				WHEN STATE7 =>
					next_sreg<=STATE8;
					next_Send_Token<='0';
					next_Hold_Token<='0';
					next_FERDBUSY<='0';
				WHEN STATE8 =>
					next_sreg<=Pass_Token;
					next_Hold_Token<='0';
					next_FERDBUSY<='0';
					next_Send_Token<='1';
				WHEN TOKEN_Idle =>
					IF ( evbTokIn='1' ) THEN
						next_sreg<=Have_Token;
						next_Send_Token<='0';
						next_Hold_Token<='0';
						next_FERDBUSY<='0';
					 ELSE
						next_sreg<=TOKEN_Idle;
						next_Send_Token<='0';
						next_Hold_Token<='0';
						next_FERDBUSY<='0';
					END IF;
				WHEN OTHERS =>
			END CASE;
		END IF;
	END PROCESS;
END BEHAVIOR;
