LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY led8_controller IS
	PORT (
		clk : IN STD_LOGIC;
		led8_column : BUFFER STD_LOGIC_VECTOR(5 DOWNTO 0); --数码管片选信号 从左到右端口：148 147 146 145 144 143 
		led8_segment : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); --a,b,c,d,e,f,g,dp 端口：173 171 168 167 166 164 162 160
		display_numbers : IN STD_LOGIC_VECTOR(0 TO 23)--要显示的数字 二进制形式编码
	);
END ENTITY;

ARCHITECTURE rtl OF led8_controller IS

	TYPE matrix IS ARRAY (0 TO 11) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
	--数字对应段码
	CONSTANT number_code : matrix := (
		"00000011", --0
		"10011111", --1
		"00100101", --2
		"00001101", --3
		"10011001", --4
		"01001001", --5
		"01000001", --6
		"00011111", --7
		"00000001", --8
		"00001001", --9
		"11111111", --X
		"11111101"
	);

	TYPE number_list IS ARRAY (5 DOWNTO 0) OF INTEGER;
	SIGNAL numbers : number_list := (2, 0, 1, 8, 1, 1);

	SIGNAL number : INTEGER;
	SIGNAL counter : STD_LOGIC_VECTOR(28 DOWNTO 0);
	SIGNAL refresh_clk : STD_LOGIC;
	SIGNAL roll_clk : STD_LOGIC;

BEGIN

	refresh_clk <= counter(10);
	roll_clk <= counter(22);
	led8_segment <= number_code(number);

	numbers(5) <= conv_integer(display_numbers(0 TO 3));
	numbers(4) <= conv_integer(display_numbers(4 TO 7));
	numbers(3) <= conv_integer(display_numbers(8 TO 11));
	numbers(2) <= conv_integer(display_numbers(12 TO 15));
	numbers(1) <= conv_integer(display_numbers(16 TO 19));
	numbers(0) <= conv_integer(display_numbers(20 TO 23));

	--滚动
	--	PROCESS (clk) IS
	--	BEGIN
	--		IF (roll_clk'event AND roll_clk = '1') THEN
	--			numbers <= numbers(number_list'length - 2 DOWNTO 0) & numbers(number_list'length - 1);
	--		END IF;
	--	END PROCESS;

	--刷新
	PROCESS (clk) IS
	BEGIN
		IF (refresh_clk'event AND refresh_clk = '1') THEN
			IF (led8_column = "111110" OR led8_column = "111111") THEN
				led8_column <= "011111";
				number <= numbers(number_list'length - 1);
			ELSIF (led8_column = "011111") THEN
				led8_column <= "101111";
				number <= numbers(number_list'length - 2);
			ELSIF (led8_column = "101111") THEN
				led8_column <= "110111";
				number <= numbers(number_list'length - 3);
			ELSIF (led8_column = "110111") THEN
				led8_column <= "111011";
				number <= numbers(number_list'length - 4);
			ELSIF (led8_column = "111011") THEN
				led8_column <= "111101";
				number <= numbers(number_list'length - 5);
			ELSIF (led8_column = "111101") THEN
				led8_column <= "111110";
				number <= numbers(number_list'length - 6);
			ELSE
				led8_column <= "111111";
				number <= 10;
			END IF;
		END IF;
	END PROCESS;

	-- 时钟控制
	PROCESS (clk) IS
	BEGIN
		IF (clk'event AND clk = '1') THEN
			counter <= counter + '1';
		END IF;
	END PROCESS;

END rtl;