----------------------------------------------------------------------------------
--
-- Engineer:  		Naomi Jarvis, Carnegie Mellon University
-- Create Date:   	09:27:11 11/04/2013 mod 07/01/15
-- Module Name:   	findtime - Behavioral 
-- Project Name:  	CDC hit time finder for GlueX
-- Target Devices: 	FA125 spartan 6
-- Tool versions: 
-- Description: 
--
--   	external module searches adc data for a threshold crossing, then passes in NSAMPLES adc samples to this module
--	  	        the adc data passed in exceed threshold crossing at sample number XTHR_SAMPLE (first sample is numbered 0)
--              
--	this module
--                      finds local pedestal as sample PED_SAMPLE
--                      calculate high and low threshold xings
--                      search forward from ped to find high thr xing with local ped
--                      then search back to find low thr xing
--                      upsample only a small region of adc data around the low thr xing
--                      find low thr xing in upsampled data
--                      report this xing point as the hit time and return q_code=0
--
--                      if adc samples do not rise above pedestal+ADC_THRES_HI,
--                      return hit time as XTHR_SAMPLE*10-ROUGH_TIME and q_code=1
--
--		        Typical values for the external threshold, THRES_HI and THRES_LO are 5sd, 4sd, and 1sd where sd = pedestal width
--                      Typical value for XTHR_SAMPLE is 9, for PED_SAMPLE is 5
--
--                      PED_SAMPLE must be equal to 5 or greater 
--                      NSAMPLES must be equal to PED_SAMPLE+7 or greater
--
--                      This is to ensure that there are enough adc samples available for upsampling--                     
--                      If THRES_HI is increased much, then NSAMPLES and XTHR_SAMPLE should
--                      also be increased.  Continuous q_code=1 will indicate that this is needed. 
--                      I suggest adding 1 to both NSAMPLES and XTHR_SAMPLE for every 20 added to THRES_HI.
--                      Start values are THRES_HI is 64, NSAMPLES=15, XTHR_SAMPLE=9
--
--                    
--
-- 	The leading edge time is returned expressed as an integer number of tenths of samples after sample 0
--
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity NEWfindtime is
    Port ( 
			clk 			: in  STD_LOGIC; 
			--RESET_N			: in  STD_LOGIC; 
			go 				: in  STD_LOGIC; -- the leading edge search process starts 1 clock sample after go is high
			adc 			: in std_logic_vector (11 downto 0);         
			busy 			: out std_logic;          -- busy when 1 and finished when 0         
			le_sample 		: out std_logic_vector (4 downto 0); -- sample containing leading edge
			le_sample_found	: out std_logic; -- signal to acknowledge that le_sample was found, I.E. can be determined, and that SUMing can start
			le_time 		: out std_logic_vector (7 downto 0); -- leading edge time found (only need 8 bits) 
			
    		THRES_HI		: in integer; --std_logic_vector(15 downto 0) := X"0050"; -- 4 sigma --int 80
    		THRES_LO		: in integer; --std_logic_vector(15 downto 0) := X"0014"; -- 1 sigma --int 20	  
			PG				: in integer;
			
			q_code			: out std_logic  -- quality code, 0 is good
         );
end NEWfindtime;


architecture Behavioral of NEWfindtime is
  

    ---------------------------------------------------------------------------
    -- variables from configuration files
    ---------------------------------------------------------------------------

    --constant THRES_HI: integer := 80; -- 4 sigma
    --constant THRES_LO: integer := 20; -- 1 sigma
--    constant PG: integer := 4; -- pedestal gap, hit threshold xing is PG samples after PED_SAMPLE
  
    ---------------------------------------------------------------------------
    -- constants
    ---------------------------------------------------------------------------
  
    constant NSAMPLES : integer := 20;   -- max number of ADC samples to read in 
    --constant NSAMPLES : std_logic_vector(4 downto 0) := X"14";  
    constant PED_SAMPLE : integer := 5; -- take local ped as sample[5]

    --constant ROUGH_DT : integer := 24;   --if algo fails, return this many tenth-samples before threshold xing

    constant LIMIT_PED_MAX : integer := 511;  -- return rough time if pedestal exceeds this
    constant SET_ADC_MIN : integer := 20;  -- set min value of ADC sample subset equal to this

    
    ---------------------------------------------------------------------------
	--type task_type is (idle, fill, check_adcvals, pre_align_min, align_min, calc_thres, search_hi, search_lo, found_lo, pre_upsample, upsample, upsample_b, upsample2, check_upsampling, search_upsampled, pre_interp, interp, round, good_time, mid_time, bad_time, ending);
    --type task_type is (idle, fill, check_adcvals, align_min, calc_thres, search_hi, search_lo, found_lo, pre_upsample, upsample, upsample_b, upsample2, upsample3, check_upsampling, search_upsampled, pre_interp, pre_interp2, interp, round, good_time, mid_time, bad_time, ending);
	type task_type is (pre_upsample2,div_upsample2, idle, fill, check_adcvals, pre_align_min, align_min, calc_thres, search_hi, search_lo, found_lo, pre_upsample, upsample, upsample_b, upsample2, check_upsampling, search_upsampled, pre_interp, pre_interp2, interp, good_time, mid_time, bad_time, ending);	-- pre_interp2, 
    signal task : task_type := idle;

    type ktype is array (0 to 42) of integer range -131072 to 131071;  -- upsampling filter constants
    constant K : ktype := (-4, -9, -13, -10, 5, 37, 82, 124, 139, 102, -1, -161, -336, -455, -436, -212, 241, 886, 1623, 2309, 2795, 2971, 2795, 2309, 1623, 886, 241, -212, -436, -455, -336, -161, -1, 102, 139, 124, 82, 37, 5, -10, -13, -9, -4);                           

    constant KSCALE : integer := 16384; --filter constants K have been multiplied by KSCALE
    constant KBITS : integer := 14;     -- KSCALE is 2**KBITS

    constant NUPSAMPLED : integer := 6; -- 0 to 11 --NSAMPLES*5 - 42;

    constant START_SEARCH : integer := PED_SAMPLE + 1;  -- start looking for hi threshold xing with this sample


--    constant XTHR_SAMPLE: integer := PED_SAMPLE + PG; -- the hit thres xing is adc sample[X], starting with sample[0]
--    constant ROUGH_TIME : integer := (XTHR_SAMPLE*10)-ROUGH_DT;  --return this for time if the algo fails
--    constant RT_SAMPLE : integer := XTHR_SAMPLE - (ROUGH_DT/10) - 1; 

--    signal XTHR_SAMPLE: integer; -- the hit thres xing is adc sample[X], starting with sample[0]
--    signal ROUGH_TIME : integer;  --return this for time if the algo fails
--    signal RT_SAMPLE : integer; 
    type iadcarray is array (natural range <>) of integer range 0 to 4095;
    type iuarray is array (natural range <>) of integer range 0 to 8191;  -- upsampled data
	
    signal iadc : iadcarray(0 to NSAMPLES-1) := (others=>0);	    -- array of adc values as integers
    signal iadc0 : iadcarray(0 to NSAMPLES-1) := (others=>0);	    -- array of adc values as integers
	
	signal align_min_comp : integer range 0 to 4095;

	
    signal iubuf: iuarray(0 to NUPSAMPLED) := (others =>0);  -- array of upsampled values 
	signal iubuf_temp : integer range 0 to 8191;
	-- iubuf 0 corresponds to low thres xing sample
    	-- iubuf 5 maps to next sample

      
    signal nadc : integer range 0 to NSAMPLES-1 := 0;  -- count of adc samples read in

    signal ndat : integer range 0 to NUPSAMPLED := 0;  -- number of upsampled data points calculated

    signal adc_thres_hi : integer range 0 to 4095 := 0;  -- high threshold
    signal adc_thres_lo : integer range 0 to 4095 := 0;  -- low threshold

    signal adc_min : integer range 0 to 4095 := 0;      -- min adc value include_overflow_bit

    signal adc_bad : std_logic := '0';  -- flag set to 1 if adc val is outside good range
    

    signal itime1 : integer range 0 to NSAMPLES*10 := 0;  -- part of hit time (which sample) in sample/10
    signal itime2 : integer range 0 to 10 := 0;           -- part of hit time (which subsample) 
    signal itime3 : integer range 0 to 1 := 0;            -- part of hit time (round up or not)
    
    
    signal j_start : integer range 0 to 4;  -- start values for array indices for upsampling
    signal x_start : integer range 0 to NSAMPLES-1;
    -- works out best with these as signals, x and j as variables

    signal ups_error : integer range -4095 to 4095 := 0;  -- upsampling error for adc_sample_lo, adjust threshold by this amount

    signal isample : integer range 0 to NSAMPLES := 0;  -- loop counter

	signal index_mux : integer range 0 to NSAMPLES -1;
	signal index_mux2 : integer range 0 to NSAMPLES -1;
	signal index_mux2_temp : integer range 0 to NSAMPLES -1; 
	--signal adc_sample_lo : integer range 0 to NSAMPLES-2 := 0;  -- sample num for adc val at or below lo thres 
	--signal adc_sample_lo2 : integer range 0 to NUPSAMPLED := 0;	
    --signal x : integer range 0 to NSAMPLES-1;
    

	    begin

      
    process(clk,PG)

    variable XTHR_SAMPLE : integer; -- the hit thres xing is adc sample[X], starting with sample[0]
    variable ROUGH_TIME : integer;  --return this for time if the algo fails
    variable RT_SAMPLE : integer;    
    -- search result vars

    variable adc_sample_hi : integer range 0 to NSAMPLES-1 := 0;  --sample number for adc val at or above hi thres
    variable adc_sample_lo : integer range 0 to NSAMPLES-2 := 0;  -- sample num for adc val at or below lo thres
    variable adc_sample_lo2 : integer range 0 to NUPSAMPLED := 0;  -- minisample num for adc val at or below lo thres

    
    -- upsample vars

--    variable buff : integer range -1347255 to 12166245 := 0;  --holds intermediate values
--    variable dz : integer range -1347255 to 12166245 := 0;  -- increment of adc * K,
--    max-- is 2971 * 4095

--    variable buff : integer range -16777215 to 33554431 := 0;
--    variable dz : integer range -16777215 to 33554431 := 0;

	--variable buff : integer range -33554431 to 67108863 := 0; 
--	variable buff_D,buff_Q : integer range -1347255 to 12166245 := 0;  --holds intermediate values
--    variable dz : integer range -33554431 to 67108863 := 0;	
	variable buff_D,buff_Q : integer range -33554431 to 67108863 := 0;  --holds intermediate values
    variable dz : integer range -33554431 to 67108863 := 0;	


    variable j : integer range 0 to 47;  
    variable x : integer range 0 to NSAMPLES-1;  

--    variable sum : integer range 0 to 65535 :=0; 
--	variable sum_temp : integer range 0 to 65535 :=0;
--    variable limit : integer range 0 to 65535 :=0;
--    variable ifrac : integer range 0 to 3 := 0; 
--    variable denom : integer range 0 to 65535 := 0; 

    variable dblth : integer range 0 to 65535 :=0; 
    variable iusum : integer range 0 to 65535 :=0;
	
    variable adjusted_threshold : integer range 0 to 4095 := 0;  -- threshold after correction as above    
       
    variable itime : integer range 0 to NSAMPLES*10 := 0;  -- ns/10
    
    begin
--change		
    XTHR_SAMPLE := PED_SAMPLE + PG;  --the hit thres xing is adc sample[X], starting with sample[0]
    ROUGH_TIME := (XTHR_SAMPLE*10)-30; -- return this for time if the algo fails
    RT_SAMPLE := XTHR_SAMPLE - 3; 
		
     if rising_edge(clk) then
		 
--    XTHR_SAMPLE := PED_SAMPLE + PG; -- the hit thres xing is adc sample[X], starting with sample[0]
--    ROUGH_TIME := (XTHR_SAMPLE*10)-30;  --return this for time if the algo fails
--    RT_SAMPLE := XTHR_SAMPLE - 3; 
		 
        case task is
          
          when idle =>
            
            if go = '1'  then

              busy <= '1';
              le_time <= (others => '0');
              le_sample <= (others => '0');
              q_code <= '0';
			  index_mux <= 0;

              nadc <= 0;
              ndat <= 0;

              itime := 0;
              
              itime1 <= 0;
              itime2 <= 0;
              itime3 <= 0;
              
              adc_min <= 4095;
              adc_bad <= '0';
             
              task <= fill;
			  
			  
				le_sample_found <= '0'; -- change added 

              report "next state: fill";
              
            end if;
            
--		
			
          when fill => 

            iadc0(index_mux) <= to_integer(unsigned(adc));
		  
            if nadc = NSAMPLES-1 then         --signal updates on next clock so test on previous value
              task <= check_adcvals;
              report "next state: check_adcvals";              
            else
			  task <= fill;
              nadc <= nadc + 1;
			  index_mux <= nadc + 1; -- change added for index mux
            end if;          
            
--            if to_integer(unsigned(adc)) <= 4095 then      
--              iadc0(index_mux) <= to_integer(unsigned(adc));
--            else
--              iadc0(index_mux) <= 4095;
--            end if;
            
            if to_integer(unsigned(adc)) < adc_min then
              adc_min <= to_integer(unsigned(adc));
              report "    min sample value is " & integer'image(to_integer(unsigned(adc))) & " moving sample data to set this at " & integer'image(SET_ADC_MIN);
            end if;

            if to_integer(unsigned(adc)) = 0 then  --check for zero
              itime1 <= ROUGH_TIME + 1;
              adc_bad <= '1';
              report "    found adc sample value 0";
            end if;

            if nadc <= PED_SAMPLE and to_integer(unsigned(adc)) > LIMIT_PED_MAX then  --check ped limit
              itime1 <= ROUGH_TIME + 2;
              adc_bad <= '1';
              report "    found high pedestal sample value " & integer'image(to_integer(unsigned(adc)));
            end if;
           
--

          when check_adcvals =>

            if adc_bad = '0' then
              --task <= align_min;
			  task <= pre_align_min;
			  index_mux <= 0; -- change added for index mux
              report "next state: align_min";                                          
            else
              task <= bad_time;
              report "next state: bad_time";                            
            end if;

            isample <= 0;

------------------------------------------------------------------------
          when pre_align_min => 
		  	task <= align_min;
		  	align_min_comp <= iadc0(index_mux) + SET_ADC_MIN - adc_min;
----------------------------------------------------------------------------
          when align_min =>            

		  	--if iadc0(index_mux) + SET_ADC_MIN - adc_min <= 4095 then
			if align_min_comp <= 4095 then  
              --iadc(index_mux) <= iadc0(index_mux) + SET_ADC_MIN - adc_min;
			  iadc(index_mux) <= align_min_comp;
            report "    sample " & integer'image(index_mux) & " new value is " & integer'image(iadc0(index_mux)) & " + " & integer'image(SET_ADC_MIN-adc_min) & " = " & integer'image(iadc0(index_mux) + SET_ADC_MIN - adc_min);              

            else
              iadc(index_mux) <= 4095;
              report "    sample " & integer'image(index_mux) & " new value is " & integer'image(iadc0(index_mux)) & " + " & integer'image(SET_ADC_MIN-adc_min) & " = " & integer'image(iadc0(index_mux) + SET_ADC_MIN - adc_min) & " reduced to 4095";              

            end if;


            if isample = NSAMPLES-1 then
              task <= calc_thres;
			  index_mux <= PED_SAMPLE; -- change added for index mux
              report "next state: calc_thres";  
			else  
				--task <= align_min;	
				task <= pre_align_min; 
				index_mux <= isample + 1; -- change added for index mux
            	isample <= isample + 1;
            end if;

--

          when calc_thres =>

              report "    local ped " & integer'image(iadc(PED_SAMPLE));
              
              adc_thres_hi <= iadc(index_mux) + THRES_HI;
              adc_thres_lo <= iadc(index_mux) + THRES_LO;
              
              report "    low threshold  " & integer'image(iadc(index_mux) + THRES_LO);                        
              report "    high threshold " & integer'image(iadc(index_mux) + THRES_HI);


              task <= search_hi;
			  index_mux <= START_SEARCH; -- change added for index mux
              report "next state: search_hi";               

              isample <= START_SEARCH;
        	
--            

          when search_hi =>
 
			 --isample <= isample + 1;	
			 --index_mux <= isample  + 1; 
            
            if iadc(index_mux) >= adc_thres_hi then 

              adc_sample_hi := isample;
              report "    adc_sample_hi " & integer'image(adc_sample_hi) & " val " & integer'image(iadc(adc_sample_hi));
              
              task <= search_lo;  
              report "next state: search_lo";

              isample <= adc_sample_hi - 1;  --prep for next state
              index_mux <= adc_sample_hi - 1; -- change added for index mux 	
				  
            elsif isample = NSAMPLES-1 then  --did not find thres xing

              itime1 <= ROUGH_TIME + 3;
              task <= bad_time;
              report "next state: bad_time"; 
			  
			else	
			 task <= search_hi;	
			 isample <= isample + 1;	
			 index_mux <= isample  + 1; 
            end if;            

--

          when search_lo =>
     
            if iadc(index_mux) <= adc_thres_lo then  -- this will be met at or before reaching PED_SAMPLE
            
              report "    sample containing leading edge of signal is sample " & integer'image(isample) & " adc val " & integer'image(iadc(isample));
              adc_sample_lo := isample;
              
              task <= found_lo;
			  index_mux <= isample; --adc_sample_lo; -- change added for index mux
             report "next state: found_lo"; 
			  
			else
			  task <= search_lo;
              isample <= isample - 1;
			  index_mux <= isample - 1; -- change added for index mux                
            end if;
            
--

          when found_lo =>
		  
		  	le_sample_found <= '1';
            itime1 <= adc_sample_lo*10 ;        -- tenths of samples
            le_sample <= std_logic_vector(to_unsigned(adc_sample_lo,5));                
            report "    itime1 " & integer'image(adc_sample_lo*10) & " x 0.1ns";

            task <= pre_upsample;
            report "next state: pre_upsample (unless countermanded in next line)";

            if (adc_sample_lo > NSAMPLES-7) then
              report "    adc_sample_lo > NSAMPLES-7, too late to upsample";
              itime2 <= 4;        -- tenths of samples
              task <= mid_time;
              report "next state: mid_time";
            end if;                   

            if iadc(index_mux) = adc_thres_lo then
              report "    adc val = adc_thres_lo, no need to upsample";
			  itime2 <= 0;
              task <= good_time;
              report "next state: good_time";
            end if;    
					
--

          when pre_upsample =>
            
            report "    adc_sample_lo " & integer'image(adc_sample_lo) & " val " & integer'image(iadc(adc_sample_lo));
           
            j_start <= 1;
            x_start <= adc_sample_lo + 4;

            j := 1; --j_start;
            x := adc_sample_lo + 4;  --x_start;
			--index_mux <= x; --CHANGE AHH
              
            --buff := 0;
				buff_D := 0;
            -- need to upsample adc_sample_lo to adc_sample_lo + 1
        
            task <= upsample;
            report "next state: upsample";

--
            
          when upsample =>

            report "    iadc(" & integer'image(x) & ") * K(" & integer'image(j) & ") " & integer'image(K(j)) & " " & integer'image(iadc(x));
            dz := iadc(x)*K(j);
			--dz := iadc(index_mux)*K(j);--CHANGE AHH
            task <= upsample_b;

            
            
          when upsample_b =>

		  	--buff := buff + dz;
		  	buff_D := buff_Q + dz;
            j := j + 5;
            x := x - 1;
			--index_mux <= x; ----CHANGE AHH

            if j>42 then
              --task <= upsample2;
			  task <= pre_upsample2;
			  index_mux2 <= ndat; -- change added for index mux
            else
              task <= upsample;
            end if;

-------test pre_upsample2-----------
          when pre_upsample2 =>
			 
		  	--buff := 5*buff;
		  	buff_D := 5*buff_Q;
			task <= div_upsample2;
				
          when div_upsample2 =>	
			 
		  	--buff := to_integer(shift_right(to_signed(buff,24),KBITS));
		  	buff_D := to_integer(shift_right(to_signed(buff_Q,27),KBITS));
			task <= upsample2;
-------end test pre_upsample2-----------
				

          when upsample2 =>
            
            if j_start = 4 then
              j := 0;
              x := x_start + 1;
              j_start <= 0;
              x_start <= x;
            else
              j := j_start + 1;
              x := x_start;
              j_start <= j;
            end if;

-----------------
            if ndat = NUPSAMPLED-1 then   -- last time through
              task <= check_upsampling;
			  index_mux <= adc_sample_lo; -- change added for index mux	
			  --index_mux2 <= 0; -- change added for index mux	  
              --report "next state: check_upsampling";
            else
              task <= upsample;           -- keep looping (for now)           
            end if;

--            buff := 5*buff;
--            buff := to_integer(shift_right(to_signed(buff,24),KBITS));
--            report "                                   upsampled: iubuf(" & integer'image(ndat) & ") " & integer'image(buff);
            
            if buff_Q >= 0 then
			  --iubuf(ndat) <= buff;	
              --iubuf(index_mux2) <= buff;
			  iubuf(index_mux2) <= buff_Q;
              ndat <= ndat + 1;
			  index_mux2 <= ndat + 1; -- change added for index mux
              --buff := 0; 
			  buff_D := 0; 
            else        
              report "    NEGATIVE upsampled value found: " & integer'image(buff_D);
              itime2 <= 5;
              
              task <= mid_time;
              report "next state: mid_time";
            end if;
-------------------
            
--
           
          when check_upsampling =>

            ups_error <= iubuf(0) - iadc(index_mux);
 			--ups_error <= iubuf(index_mux2) - iadc(index_mux);
            --report "    iubuf(0) " & integer'image(iubuf(0)) & " adc val " & integer'image(iadc(index_mux)) & " error " & integer'image(iubuf(0)-iadc(index_mux));
            --report "    iubuf(5) " & integer'image(iubuf(5)) & " adc val " & integer'image(iadc(index_mux+1)) & " error " & integer'image(iubuf(5)-iadc(index_mux+1));
  
            
            task <= search_upsampled;
            --report "next state: search_upsampled";
            
            isample <= NUPSAMPLED-1;
			index_mux2 <= NUPSAMPLED-1; -- change added for index mux
            adc_sample_lo2 := 0;       --prep for next state
            
--
            
          when search_upsampled =>

            adjusted_threshold := adc_thres_lo + ups_error;
           report "    adjusted threshold is " & integer'image(adjusted_threshold);
                       
            --if iubuf(isample) <= adjusted_threshold then  
            if iubuf(index_mux2) <= adjusted_threshold then  
              report "    iubuf(" & integer'image(isample) & ") val " & integer'image(iubuf(isample)) & " lo thres " & integer'image(adjusted_threshold);
              adc_sample_lo2 := isample;
              itime2 <= adc_sample_lo2*2;  -- convert from sample/5 to sample/10    

              report "    adc_sample_lo2 " & integer'image(adc_sample_lo2);

              --task <= pre_interp;
			  task <= pre_interp2;
			  index_mux2 <= adc_sample_lo2; -- change added for index mux
			  index_mux2_temp <= adc_sample_lo2 + 1;	  
              report "next state: pre_interp";

            else

              isample <= isample - 1;
			  index_mux2 <= isample - 1; -- change added for index mux
              
            end if;

           
            if adc_sample_lo2 = NUPSAMPLED-1 then  --upsampled points are too small (thr crossed at last point)
              report "    last upsampling point was <= threshold crossing, returning le_sample*10 + 9";

              itime2 <= 9;
              
              task <= mid_time;
              report "next state: mid_time;                     ";

            end if;
			
--------------------------------------------------------			
          when pre_interp2 =>  
		  	  task <= pre_interp;
		  	  iubuf_temp <= iubuf(index_mux2_temp);
---------------------------------------------------------	

          when pre_interp =>                 -- itime already contains adc_sample_lo                                       

            
            if iubuf(index_mux2) = adjusted_threshold then

              task <= good_time;
              report "next state: good_time";

              
            else    --interpolate
                        
              iusum := iubuf(index_mux2) + iubuf_temp;
              dblth := adjusted_threshold*2;

              report "    iusum " & integer'image(iusum);
              report "    dblth " & integer'image(dblth); 

              task <= interp;
              report "next state: interp";

            end if;
				
--          when pre_interp =>                 -- itime already contains adc_sample_lo                                       
--
--            
--            --if iubuf(adc_sample_lo2) = adjusted_threshold then	
--			if iubuf(index_mux2) = adjusted_threshold then
--              task <= good_time;
--              report "next state: good_time";
--
--              
--            else    --interpolate
--                        
--              --denom := iubuf(adc_sample_lo2+1) - iubuf(adc_sample_lo2);
--              --limit := (adjusted_threshold - iubuf(adc_sample_lo2))*2;
--			  
--			  denom := iubuf_temp - iubuf(index_mux2);
--              limit := (adjusted_threshold - iubuf(index_mux2))*2;
--
--              report "    denom " & integer'image(denom);
--              report "    limit " & integer'image(limit); 
--
--              task <= interp;
--              report "next state: interp";
--
--
--              sum := 0;
--              ifrac := 0;
--
--            end if;

-- 

          when interp =>
            
            if dblth >= iusum then
              itime3 <= 1;
              report "     itime3 1";
            end if;
              
            task <= good_time;

            report "next state: good_time";
			
			
--          when interp =>
--            
--            if sum >= limit then
--              task <= round;  
--			  sum_temp := 2*(sum-limit);
--              --report "next state: round";
--
--            else 
--              sum := sum + denom;
--              ifrac := ifrac + 1;           
--            end if;
--              
--            report "     sum " & integer'image(sum) & " ifrac " & integer'image(ifrac);

--
            
--          when round =>
--
--            report "";
--            
--            --if 2*(sum-limit) > denom then  --round	
--			if sum_temp > denom then  --round	
--              itime3 <= ifrac - 1;             
--            else
--              itime3 <= ifrac;
--            end if;
--
--            task <= good_time;
--            report "next state: good_time";

--
            
          when good_time =>

            itime := itime1 + itime2 + itime3;
            
            le_time <= std_logic_vector(to_unsigned(itime,8));   -- this is time from first sample point, in 1/10ths of samples

            report "    return good time " & integer'image(itime);
            
            q_code <= '0';

            task <= ending;
            report "next state: ending";

--
            
          when mid_time =>    

            -- get sent here if lo_thres is found between adc_sample_lo and the
            -- next, in sample search, but not in upsampled data search 
            
            itime := itime1 + itime2;
            
            le_time <= std_logic_vector(to_unsigned(itime,8));   -- this is time from first sample point, in 1/10ths of samples            
            report "    return midpoint time " & integer'image(itime);
            
            q_code <= '1';            
            task <= ending;
            report "next state: ending";

--          
            
          when bad_time =>    

            -- get sent here if hi_thres is not exeeded or adc values outside set limits            
            report "    return rough time " & integer'image(itime1);
            le_sample_found <= '1';
            le_time <= std_logic_vector(to_unsigned(itime1,8));   -- this is time from first sample point, in 1/10ths of samples
            le_sample <= std_logic_vector(to_unsigned(RT_SAMPLE,5));  -- sample containing le_time
           
            q_code <= '1';            
            task <= ending;
            report "next state: ending";

-- 
            
          when ending => 
            
          
            task <= idle;
            report "next state: idle";

            busy <= '0';  
           
        end case;
      end if; 
	  
		buff_Q := buff_D;
 
    end process; 
	
	--le_sample_found <= '1' when task = found_lo or task = bad_time else '0';  
					 
end Behavioral;