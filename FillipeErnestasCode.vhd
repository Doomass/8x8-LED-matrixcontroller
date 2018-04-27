library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;    -- needed for +/- operations

-- Input/output description
entity top is
    port (
		BTN0: in std_logic;         -- START/RESET
		BTN1: in std_logic;			-- STATE TRANSITION
        
        SW0: in std_logic;          
		SW1: in std_logic; 			-- ADDER --
        
		SW_EXP0: in std_logic;          -- option1 --
        SW_EXP1: in std_logic;     		-- option2 --
		SW_EXP2: in std_logic; 			-- option3 --
		SW_EXP3: in std_logic;          --  ADDER  --
        SW_EXP4: in std_logic;     		--  ADDER  --
		SW_EXP5: in std_logic; 			--  ADDER  --
        SW_EXP6: in std_logic;          --  ADDER  --
        SW_EXP7: in std_logic;          --  ADDER  --
        
        CLK: in std_logic;
        LINE_DEC: out std_logic_vector(2 downto 0);
        RED_LED: out std_logic_vector(7 downto 0);
        GREEN_LED: out std_logic_vector(7 downto 0); 
        LED: out std_logic_vector(3 downto 0)
    );
end top;

-- Internal structure description
architecture Behavioral of top is
-- internal signal definitions
    signal clk_10: std_logic := '0';
    signal tmp_10: std_logic_vector(11 downto 0) := x"000";    -- hexadecimal value
    signal dec: std_logic_vector(2 downto 0) := "000";         -- binary value
    signal clk_500: std_logic := '0';
    signal tmp_500: std_logic_vector(11 downto 0) := x"000";    -- hexadecimal value
	signal clk_1500: std_logic := '0';
    signal tmp_1500: std_logic_vector(15 downto 0) := x"0000";    -- hexadecimal value
    signal low :std_logic := '0';
    signal high :std_logic := '1';
    
    --controll
    signal opt1,opt2,opt3,opt4  : std_logic;

        --counter  
    signal countdown: std_logic_vector(3 downto 0) := "1010";         -- binary value
    signal donecounting: std_logic:= '0';
    
    		--ADDER--
	signal a,b: std_logic_vector(1 downto 0);
    signal c0,c1: std_logic;
    signal y0,y1: std_logic;
    signal sum: std_logic_vector(2 downto 0):= "000";
    
    	-- MATRIX images
	type images_t is array (0 to 64) of std_logic_vector(7 downto 0);
    signal images : images_t;
	
    -- Trafick lights declaration
    type my_states is (RED, RO, GREEN, ORANGE,NONE);
    signal state: my_states;
	
    -- FSM declaration
    type states is (START,COUNT,MENU,OPTS1,OPTS2,OPTS3,OVER,STOP);
    signal state0: states;
    signal ending: std_logic;
    
    -- LED select
    signal RED_SUM: std_logic_vector(7 downto 0);
    signal GREEN_SUM: std_logic_vector(7 downto 0);  
    signal RED_TRF: std_logic_vector(7 downto 0);
    signal GREEN_TRF: std_logic_vector(7 downto 0);  
    signal RED_COUNT: std_logic_vector(7 downto 0);
    signal GREEN_COUNT: std_logic_vector(7 downto 0);
    signal multpx : std_logic_vector(2 downto 0):= "000";
    signal RED_FIN: std_logic_vector(7 downto 0);
    signal GREEN_FIN: std_logic_vector(7 downto 0);  
 
    
begin
    -----------------------------------------
    -- clock divider to 10 ms Refresh rate --
    -----------------------------------------
    -- increment auxiliary counter every rising edge of CLK
    -- if you meet half a period of 10 ms invert clk_10
    process (CLK)
    begin
        if rising_edge(CLK) then
            tmp_10 <= tmp_10 + 1;
            if tmp_10 = x"005" then
                tmp_10 <= x"000";
                clk_10 <= not clk_10;
            end if;
        end if;
    end process;
	-----------------------------
    -- clock divider to 500 ms --
    -----------------------------
    -- increment auxiliary counter every rising edge of CLK
    -- if you meet half a period of 500 ms invert clk_500
    process (CLK)
    begin
        if rising_edge(CLK) then
            tmp_500 <= tmp_500 + 1;
            if tmp_500 = x"9c4" then
                tmp_500 <= x"000";
                clk_500 <= not clk_500;
            end if;
        end if;
    end process;
	-----------------------------
    -- clock divider to 800 ms --
    -----------------------------
    -- increment auxiliary counter every rising edge of CLK
    -- if you meet half a period of 500 ms invert clk_800
    process (CLK)
    begin
        if rising_edge(CLK) then
            tmp_1500 <= tmp_1500 + 1;
            if tmp_1500 = x"1D4C" then
                tmp_1500 <= x"0000";
                clk_1500 <= not clk_1500;
            end if;
        end if;
    end process;
    
    --------------------------
	-- DECODER --
	--------------------------
   
   process (clk_10)
    begin
        if rising_edge(clk_10) then
            --if BTN0 = '0' then      -- synchronous RESET
             --   dec <= "0000";
           -- else
                dec <= dec + 1;     -- decimal counter
                if dec >= "111" then
                dec <= "000";
            end if;
        end if;
    end process;
    
    --------------------------
	-- PROGRAM --
	--------------------------
	process (clk_500)
		begin
			if rising_edge(clk_500) then
                if BTN1 = '0' then
                    state0 <= MENU;
                end if;
                if BTN0 = '0' then
                    state0 <= START;
                else
                    if state0 = START then
                        state0 <= COUNT;
                    elsif state0 = COUNT then
                        if donecounting='1' then                         
                           state0 <= MENU;
                        end if;
                    elsif   (state0= MENU) then
                        if opt1= '1' then
                            state0 <= OPTS1;
                        elsif opt2= '1' then
                            state0 <= OPTS2;
                        elsif opt3= '1' then
                            state0 <= OVER;
                        else 
                            state0 <= STOP;
                        end if;
                    elsif  state0= STOP then                      
                           state0 <= MENU;       
                    end if;
            end if; 
        end if;   
	end process;

    LED(0) <= BTN0;
    LED(1) <= BTN1;
    LED(2) <= not SW0;
    LED(3) <= not SW1;
    
    ------------------------------------
    -- state of PROGRAM --
    ------------------------------------  
        
        
    process (state0)
    begin
        if state0 = START then
            ending <= '0';
        elsif state0 = COUNT then
            multpx <= "011";
        elsif state0 = MENU then
            multpx <= "111";
        elsif state0 = OPTS1 then
			multpx <= "001";       
        elsif state0 = OPTS2 then
            multpx <= "010";
        elsif state0 = STOP then
            multpx <= "101";
        elsif state0 = OVER then
            GREEN_FIN <= images(52);
            RED_FIN <= images(53);
            multpx <= "100";
		end if;
    end process;

    -------------------
    -- OPT1 - ADDER --
    -------------------
    process (clk_500)
    begin
        if rising_edge(clk_500)then
        -------------------
        -- "load" inputs --
        -------------------
        a(0) <= SW_EXP0;
        a(1) <= SW_EXP1;
        b(0) <= SW_EXP2;
        b(1) <= SW_EXP3;
        ------------------------
        -- first (half) adder --
        ------------------------
        y0 <= a(0) XOR b(0);
        c0 <= a(0) AND b(0);

        -------------------------
        -- second (full) adder --
        -------------------------
        y1 <= a(1) XOR b(1) XOR C0;
        c1 <= (a(1) AND c0) OR (b(1) AND c0) OR (a(1) AND b(1));
       

        --------------------
        -- "fill" outputs --
        --------------------
        sum(0) <= y0;
        sum(1) <= y1;
        sum(2) <= c1;

        
       end if ;
    end process;
    
    with sum select                     
            RED_SUM <=  images(30) when "000",     
                        images(31) when "001",   
                        images(32) when "010",     
                        images(33) when "011", 
                        images(34) when "100",     
                        images(35) when "101",   
                        images(36) when "110",     
                        images(37) when "111", 
                        images(50) when others; 
                    
     with sum select                         
            GREEN_SUM <=images(40) when "000",     
                        images(41) when "001",   
                        images(42) when "010",     
                        images(43) when "011",     
                        images(44) when "100",   
                        images(45) when "101",     
                        images(46) when "110",
                        images(47) when "111",
                        images(50) when others; 		

        ---------------------------
        -- OPT2 - Trafick Lights --
        ---------------------------
     process (clk_1500)
     begin
        if rising_edge(clk_1500) then
                    if SW_EXP5 = '1' then
                        if state = NONE then 
                            state <= RED;
                        else
                            if state = RED then
                                    state <= RO;
                                elsif state = RO then
                                    state <= GREEN;
                                elsif state = GREEN then
                                    state <= ORANGE; 
                                elsif state = ORANGE then 
                                    state <= RED; 
                            end if;
                        end if;
                    elsif SW_EXP6 = '1' then
                    state <= ORANGE;
                        if SW_EXP7 = '1' then
                            state <= ORANGE;
                        else
                            if state = ORANGE then
                                    state <= NONE;
                                elsif state = NONE then
                                    state <= ORANGE;
                                end if;   
                            end if; 
                        end if;
                    end if;                 
        end process;

     process (state)
                begin
                    if state = RED then 
                        RED_TRF <= images(38);
                        GREEN_TRF <= images(55);
                    elsif state = RO then
                        RED_TRF <= images(39);
                        GREEN_TRF <= images(49);
                    elsif State = GREEN then
                        RED_TRF <= images(55);
                        GREEN_TRF <= images(48);
                     elsif state = ORANGE then
                        RED_TRF <= images(51);
                        GREEN_TRF <= images(51);
                     elsif state = NONE then
                        RED_TRF <= images(55);
                        GREEN_TRF <=images(55);
            end if;
     end process;


    ---------------------
    -- decimal counter --
    ---------------------
    process (clk_1500)
        begin
           if rising_edge(clk_1500) then
            countdown <= "1010";
            donecounting <='0';
                while (state0 = COUNT) loop
                    if countdown = "0000" then
                    donecounting <='1';
                    else
                    countdown <= countdown - 1;     -- decimal counter
                    end if;
                    end loop;
                end if;
    end process;

   
    with countdown select                        
        RED_COUNT <=images(0) when "0000",     
                    images(1) when "0001",   
                    images(2) when "0010",     
                    images(3) when "0011", 
                    images(4) when "0100",     
                    images(5) when "0101",   
                    images(6) when "0110",     
                    images(7) when "0111",                    
                    images(8) when "1000", 
                    images(9) when "1001",
                    images(10)when "1010",
                    images(50) when others;  					


    with countdown select                        
        GREEN_COUNT <=images(21) when "0000",     
                    images(11) when "0001",   
                    images(12) when "0010",     
                    images(13) when "0011",     
                    images(14) when "0100",   
                    images(15) when "0101",     
                    images(16) when "0110",                    
                    images(17) when "0111", 
                    images(18) when "1000",
                    images(19) when "1001",
                    images(20) when "1010",                 
                    not images(50) when others; 
       
    --------------------------------------
    --          Refresh Rate            --
    --------------------------------------	                                        
        LINE_DEC <= not dec;
                    
    --------------------------------------
    --          LED MULTIPLEX         --
    --------------------------------------	                    
    with multpx select  
        RED_LED <=  RED_SUM when "001",
                    RED_TRF when "010",
                    RED_COUNT when "011",
                    RED_FIN when "100",
                    images(50) when others;
                    
    with multpx select  
        GREEN_LED <=  GREEN_SUM when "001",
                      GREEN_TRF when "010",
                      GREEN_COUNT when "011",
                      GREEN_FIN when "100",
                      not images(50) when others;               
                      
    --------------------------------------
    --          state MULTIPLEX         --
    --------------------------------------	                    
    opt4 <= not SW0 and not SW1;
    opt1 <= SW0 and not SW1;                            
    opt2 <= not SW0 and SW1;
    opt3 <= SW0 and SW1;
    
    ------------------------------------
	--		 Graphic Images			  --
    ------------------------------------ 
	               
    with dec select 
		--RED CD--
	images(0) <=not"11000011" when "000",       
				not"10000001" when "001",
				not"00111100" when "010",
				not"10100101" when "011",
				not"10100101" when "100",
				not"00100100" when "101",
				not"10111101" when "110",
				not"11000011" when "111",
				not"00000000" when others;
	with dec select 			
	images(1) <=not"11100111" when "000",
				not"10000001" when "001",
				not"10011001" when "010",
				not"00001000" when "011",
				not"00001000" when "100",
				not"10001001" when "101",
				not"10001001" when "110",
				not"11100111" when "111",
				not"00000000" when others;	
	with dec select 			
	images(2) <=not"10000001" when "000",
				not"00000000" when "001",
				not"10011101" when "010",
				not"00000100" when "011",
				not"00011100" when "100",
				not"10010001" when "101",
				not"00011100" when "110",
				not"10000001" when "111",
				not"00000000" when others;
	with dec select 						 
	images(3) <=not"11000011" when "000",
				not"10000001" when "001",
				not"00011100" when "010",
				not"10000101" when "011",
				not"10011101" when "100",
				not"00000100" when "101",
				not"10011101" when "110",
				not"11000011" when "111",
				not"00000000" when others;
	with dec select 							 
	images(4) <=not"11011011" when "000",
				not"10000001" when "001",
				not"10010101" when "010",
				not"00010100" when "011",
				not"00011100" when "100",
				not"10000101" when "101",
				not"10000101" when "110",
				not"11011011" when "111",
				not"00000000" when others;
	with dec select 							 
	images(5) <=not"10000001" when "000",
				not"00000000" when "001",
				not"10011101" when "010",
				not"00010000" when "011",
				not"00011100" when "100",
				not"10000101" when "101",
				not"00011100" when "110",
				not"10000001" when "111",
				not"0000000" when others;
	with dec select 							 
	images(6) <=not"11000011" when "000",
				not"10000001" when "001",
				not"00011100" when "010",
				not"00010000" when "011",
				not"00011100" when "100",
				not"00010100" when "101",
				not"10011101" when "110",
				not"11000011" when "111",	
				not"00000000" when others;
	with dec select 							 
	images(7) <=not"10100101" when "000",
				not"00000000" when "001",
				not"10011101" when "010",
				not"00000100" when "011",
				not"00001100" when "100",
				not"10000101" when "101",
				not"00000100" when "110",
				not"10100101" when "111",
				not"00000000" when others;				
	with dec select 
	images(8) <=not"11100011" when "000",
				not"10000001" when "001",
				not"00011100" when "010",
				not"00010100" when "011",
				not"00011100" when "100",
				not"00010100" when "101",
				not"10011101" when "110",
				not"11000011" when "111",		
				not"00000000" when others;
	with dec select 			
	images(9) <=not"10101010" when "000",
				not"00000000" when "001",
				not"10011101" when "010",
				not"00010100" when "011",
				not"00011100" when "100",
				not"10000101" when "101",
				not"00000100" when "110",
				not"10101010" when "111",	
				not"00000000" when others;
	with dec select 			
    images(10) <=not"11111111" when "000",
				 not"00000000" when "001",
				 not"01101110" when "010",
			 	 not"00101010" when "011",
			 	 not"00101010" when "100",
				 not"00101110" when "101",
				 not"00000000" when "110",
				 not"11111111" when "111",
                 not"00000000" when others;
								 
				 
		-- GREEN CD--
    with dec select 
	images(21)<=not"00000000" when "000",
				not"00000000" when "001",
				not"00111100" when "010",
				not"00100100" when "011",
				not"00100100" when "100",
				not"00100100" when "101",
				not"00111100" when "110",
				not"00000000" when "111",
				not"00000000" when others;
	with dec select 							 
	images(11)<=not"00000000" when "000",
				not"00000000" when "001",
				not"00011000" when "010",
				not"00001000" when "011",
				not"00001000" when "100",
				not"00001000" when "101",
				not"00001000" when "110",
				not"00000000" when "111",
				not"00000000" when others;
	with dec select 							 
	images(12)<=not"00000000" when "000",
				not"00000000" when "001",
				not"00011100" when "010",
				not"00000100" when "011",
				not"00011100" when "100",
				not"00010000" when "101",
				not"00011100" when "110",
				not"00000000" when "111",
				not"00000000" when others;
	with dec select 							 
	images(13)<=not"00000000" when "000",
				not"00000000" when "001",
				not"00011100" when "010",
				not"00000100" when "011",
				not"00011100" when "100",
				not"00000100" when "101",
				not"00011100" when "110",
				not"00000000" when "111",
				not"00000000" when others;
	with dec select 							 
	images(14)<=not"00000000" when "000",
				not"00000000" when "001",
				not"00010100" when "010",
				not"00010100" when "011",
				not"00011100" when "100",
				not"00000100" when "101",
				not"00000100" when "110",
				not"00000000" when "111",
				not"00000000" when others;
	with dec select 							 
	images(15)<=not"00000000" when "000",
				not"00000000" when "001",
				not"00011100" when "010",
				not"00010000" when "011",
				not"00011100" when "100",
				not"00000100" when "101",
				not"00011100" when "110",
				not"00000000" when "111",
				not"00000000" when others;
	with dec select 							 
	images(16)<=not"00000000" when "000",
				not"00000000" when "001",
				not"00011100" when "010",
				not"00010000" when "011",
				not"00011100" when "100",
				not"00010100" when "101",
				not"00011100" when "110",
				not"00000000" when "111",	
				not"00000000" when others;
	with dec select 							 
	images(17)<=not"00000000" when "000",
				not"00000000" when "001",
				not"00011100" when "010",
				not"00000100" when "011",
				not"00001100" when "100",
				not"00000100" when "101",
				not"00000100" when "110",
				not"00000000" when "111",		
				not"00000000" when others;
	with dec select 				
	images(18)<=not"00000000" when "000",
				not"00000000" when "001",
				not"00011100" when "010",
				not"00010100" when "011",
				not"00011100" when "100",
				not"00010100" when "101",
				not"00011100" when "110",
				not"00000000" when "111",		
				not"00000000" when others;
	with dec select 							 
	images(19)<=not"00000000" when "000",
				not"00000000" when "001",
				not"00011100" when "010",
				not"00010100" when "011",
				not"00011100" when "100",
				not"00000100" when "101",
				not"00000100" when "110",
				not"00000000" when "111",	
				not"00000000" when others;
	with dec select 			
    images(20)<=not"00000000" when "000",
				not"00000000" when "001",
				not"01101110" when "010",
			 	not"00101010" when "011",
			 	not"00101010" when "100",
				not"00101110" when "101",
				not"00000000" when "110",
				not"00000000" when "111",
                not"00000000" when others;
								 
				
		--RED ADDER--
    with dec select    
	images(30)<=not"00000000" when "000",
				not"00011100" when "001",
				not"00100010" when "010",
			 	not"00100010" when "011",
			 	not"00100010" when "100",
				not"00100010" when "101",
				not"00011100" when "110",
				not"00000000" when "111",								 
				not"00000000" when others;
	with dec select 			
	images(31)<=not"00011000" when "000",
				not"00101000" when "001",
				not"01001000" when "010",
				not"00001000" when "011",
				not"00001000" when "100",
				not"00001000" when "101",
				not"00001000" when "110",
				not"00000000" when "111",
				not"00000000" when others;
	with dec select 							 
	images(32)<=not"00111000" when "000",
				not"01000100" when "001",
				not"00000100" when "010",
				not"00111000" when "011",
				not"01000000" when "100",
				not"01000000" when "101",
				not"01111100" when "110",
				not"00000000" when "111",
				not"00000000" when others;
	with dec select 							 
	images(33)<=not"00111000" when "000",
				not"01000100" when "001",
				not"00000100" when "010",
				not"00001000" when "011",
				not"00000100" when "100",
				not"01000100" when "101",
				not"00111000" when "110",
				not"00000000" when "111",
				not"00000000" when others;
	with dec select 							 
	images(34)<=not"00100100" when "000",
				not"00100100" when "001",
				not"00100100" when "010",
				not"00111100" when "011",
				not"00000100" when "100",
				not"00000100" when "101",
				not"00000100" when "110",
				not"00000000" when "111",
				not"00000000" when others;
	with dec select 							 
	images(35)<=not"00111100" when "000",
				not"01000000" when "001",
				not"01000000" when "010",
				not"01111000" when "011",
				not"00000100" when "100",
				not"00000100" when "101",
				not"01111100" when "110",
				not"00000000" when "111",
				not"00000000" when others;
	with dec select 							 
	images(36)<=not"00011100" when "000",
				not"00100000" when "001",
				not"00100000" when "010",
				not"00111100" when "011",
				not"00100010" when "100",
				not"00100010" when "101",
				not"00011100" when "110",
				not"00000000" when "111",	
				not"00000000" when others;
	with dec select 		            
	images(37)<=not"00111100" when "000",
				not"01000100" when "001",
				not"00000100" when "010",
				not"00000100" when "011",
				not"00011110" when "100",
				not"00000100" when "101",
				not"00000100" when "110",
				not"00000000" when "111",		
				not"00000000" when others;	
	
		--GREEN ADDER--
    with dec select     
	images(40)<=not"00000000" when "000",
				not"00011100" when "001",
				not"00100010" when "010",
			 	not"00100010" when "011",
			 	not"00100010" when "100",
				not"00100010" when "101",
				not"00011100" when "110",
				not"00000000" when "111",								 
				not"00000000" when others;
	with dec select 			
	images(41)<=not"00011000" when "000",
				not"00101000" when "001",
				not"01001000" when "010",
				not"00001000" when "011",
				not"00001000" when "100",
				not"00001000" when "101",
				not"00001000" when "110",
				not"00000000" when "111",
				not"00000000" when others;
	with dec select 							 
	images(42)<=not"00111000" when "000",
				not"01000100" when "001",
				not"00000100" when "010",
				not"00111000" when "011",
				not"01000000" when "100",
				not"01000000" when "101",
				not"01111100" when "110",
				not"00000000" when "111",
				not"00000000" when others;
	with dec select 							 
	images(43)<=not"00111000" when "000",
				not"01000100" when "001",
				not"00000100" when "010",
				not"00001000" when "011",
				not"00000100" when "100",
				not"01000100" when "101",
				not"00111000" when "110",
				not"00000000" when "111",
				not"00000000" when others;
	with dec select 							 
	images(44)<=not"00100100" when "000",
				not"00100100" when "001",
				not"00100100" when "010",
				not"00111100" when "011",
				not"00000100" when "100",
				not"00000100" when "101",
				not"00000100" when "110",
				not"00000000" when "111",
				not"00000000" when others;
	with dec select 							 
	images(45)<=not"00111100" when "000",
				not"01000000" when "001",
				not"01000000" when "010",
				not"01111000" when "011",
				not"00000100" when "100",
				not"00000100" when "101",
				not"01111100" when "110",
				not"00000000" when "111",
				not"00000000" when others;
	with dec select 							 
	images(46)<=not"00011100" when "000",
				not"00100000" when "001",
				not"00100000" when "010",
				not"00111100" when "011",
				not"00100010" when "100",
				not"00100010" when "101",
				not"00011100" when "110",
				not"00000000" when "111",	
				not"00000000" when others;
	with dec select 			
	images(47)<=not"00111100" when "000",
				not"01000100" when "001",
				not"00000100" when "010",
				not"00000100" when "011",
				not"00011110" when "100",
				not"00000100" when "101",
				not"00000100" when "110",
				not"00000000" when "111",		
				not"00000000" when others;	

			--RED TRAFICK LIGTHS--				
    with dec select         
	images(38)<=not"00111100" when "000",
				not"00111100" when "001",
				not"00000000" when "010",
				not"00000000" when "011",
				not"00000000" when "100",
				not"00000000" when "101",
				not"00000000" when "110",
				not"00000000" when "111",		
				not"00000000" when others;	
	with dec select 			
	images(39)<=not"00111100" when "000",
				not"00111100" when "001",
				not"00000000" when "010",
				not"00111100" when "011",
				not"00111100" when "100",
				not"00000000" when "101",
				not"00000000" when "110",
				not"00000000" when "111",		
				not"00000000" when others;	
                
	with dec select 			
	images(51)<=not"00000000" when "000",
				not"00000000" when "001",
				not"00000000" when "010",
				not"00111100" when "011",
				not"00111100" when "100",
				not"00000000" when "101",
				not"00000000" when "110",
				not"00000000" when "111",		
				not"00000000" when others;									

			--GREEN TRAFICK LIGTHS--
    with dec select         
	images(48)<=not"00000000" when "000",
				not"00000000" when "001",
				not"00000000" when "010",
				not"00000000" when "011",
				not"00000000" when "100",
				not"00000000" when "101",
				not"00111100" when "110",
				not"00111100" when "111",		
				not"00000000" when others;	
	with dec select 			
	images(49)<=not"00000000" when "000",
				not"00000000" when "001",
				not"00000000" when "010",
				not"00111100" when "011",
				not"00111100" when "100",
				not"00000000" when "101",
				not"00000000" when "110",
				not"00000000" when "111",		
				not"00000000" when others;
    with dec select 
	images(50)<=not"00110011" when "000",
				not"01100110" when "001",
				not"11001100" when "010",
				not"10011001" when "011",
				not"00110011" when "100",
				not"01100110" when "101",
				not"11001100" when "110",
				not"10011001" when "111",
				not"00000000" when others;
   
                --GREEN FIN--
   with dec select 
	images(52)<=not"10101010" when "000",
				not"00000000" when "001",
				not"11101001" when "010",
				not"10001101" when "011",
				not"11001011" when "100",
				not"10001001" when "101",
				not"00000000" when "110",
				not"01010101" when "111",
				not"00000000" when others;  
                 --RED FIN--
    with dec select 
	images(53)<=not"01010101" when "000",
				not"00000000" when "001",
				not"00011001" when "010",
				not"00011101" when "011",
				not"00011011" when "100",
				not"00011001" when "101",
				not"00000000" when "110",
				not"10101010" when "111",
				not"00000000" when others;         

                  --nothing--
    with dec select 
	images(55)<=not"00000000" when "000",
				not"00000000" when "001",
				not"00000000" when "010",
				not"00000000" when "011",
				not"00000000" when "100",
				not"00000000" when "101",
				not"00000000" when "110",
				not"00000000" when "111",
				not"00000000" when others;                    

end Behavioral;
