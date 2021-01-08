LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.std_logic_arith.ALL;

ENTITY matrix_calculator IS
	PORT (
		clk : IN STD_LOGIC;
		key_row : BUFFER STD_LOGIC_VECTOR(3 DOWNTO 0);
		key_col : IN STD_LOGIC_VECTOR(3 DOWNTO 0);

		led8_column : BUFFER STD_LOGIC_VECTOR(5 DOWNTO 0); --数码管片选信号 从左到右：148 147 146 145 144 143 
		led8_segment : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- a,b,c,d,e,f,g,dp 端口：173 171 168 167 166 164 162 160

		ledmatrix_row : BUFFER STD_LOGIC_VECTOR(15 DOWNTO 0);
		ledmatrix_column : BUFFER STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END ENTITY;
ARCHITECTURE rtl OF matrix_calculator IS

	--计数器
	SIGNAL counter : STD_LOGIC_VECTOR(28 DOWNTO 0);
	--更新时钟
	SIGNAL clk_update : STD_LOGIC;
	SIGNAL clk_scan : STD_LOGIC;
	--测试信号
	SIGNAL tone : INTEGER RANGE 0 TO 1023;
	COMPONENT key_controller IS
		PORT (
			clk : IN STD_LOGIC; --板载时钟
			key_row : BUFFER STD_LOGIC_VECTOR(3 DOWNTO 0); --键盘行选 从上到下  端口：21 20 19 18
			key_col : IN STD_LOGIC_VECTOR(3 DOWNTO 0); --键盘列选 从左到右  端口：9 6 5 4
			key_value : OUT STD_LOGIC_VECTOR(4 DOWNTO 0) -- 输出键码
		);
	END COMPONENT;
	SIGNAL key_value : STD_LOGIC_VECTOR(4 DOWNTO 0);
	COMPONENT led8_controller IS
		PORT (
			clk : IN STD_LOGIC;
			led8_column : BUFFER STD_LOGIC_VECTOR(5 DOWNTO 0); --数码管片选信号 从左到右：148 147 146 145 144 143 
			led8_segment : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- a,b,c,d,e,f,g,dp 端口：173 171 168 167 166 164 162 160
			display_numbers : IN STD_LOGIC_VECTOR(0 TO 23)--要显示的数字 二进制形式编码
		);
	END COMPONENT;
	TYPE number_list_led8 IS ARRAY (0 TO 5) OF INTEGER;
	SIGNAL display_led8_numbers : number_list_led8 := (0, 0, 0, 0, 0, 0);
	SIGNAL display_led8_numbers_code : STD_LOGIC_VECTOR(0 TO 23);
	SIGNAL display_led8_number : INTEGER := 0;
	COMPONENT ledmatrix_controller IS
		PORT (
			clk : IN STD_LOGIC;
			ledmatrix_row : BUFFER STD_LOGIC_VECTOR(15 DOWNTO 0);
			ledmatrix_column : BUFFER STD_LOGIC_VECTOR(15 DOWNTO 0);
			--LED阵列行选（r1-r16），低电平有效，引脚为：142、137、135、134、132、131、128、127、126、120、119、118、117、113、112、111。         
			--LED阵列列选（c1- c16），低电平有效，引脚为：110、109、108、106、103、102、101、100、99、98、95、94、93、88、87、86。
			display_numbers : IN STD_LOGIC_VECTOR(0 TO 15);--要显示的数字 二进制形式编码
			cursor : IN INTEGER
		);
	END COMPONENT;
	TYPE number_list_ledmatrix IS ARRAY (0 TO 3) OF INTEGER RANGE 0 TO 20;
	SIGNAL display_ledmatrix_numbers : number_list_ledmatrix := (0, 0, 0, 0); --数字码
	SIGNAL display_ledmatrix_numbers_code : STD_LOGIC_VECTOR(0 TO 15);
	SIGNAL display_ledmatrix_number : INTEGER := 0;
	--光标
	SIGNAL cursor : INTEGER RANGE 0 TO 4 := 0;

	-- 操作信号
	SIGNAL operation_transpose : STD_LOGIC := '0';
	SIGNAL operation_reset : STD_LOGIC := '0';

BEGIN
	clk_update <= counter(6);
	clk_scan <= counter(5);
	--被调用的控制实体
	controller_key : key_controller PORT MAP(clk, key_row, key_col, key_value);
	controller_led8 : led8_controller PORT MAP(clk, led8_column, led8_segment, display_led8_numbers_code);
	controller_ledmatrix : ledmatrix_controller PORT MAP(clk, ledmatrix_row, ledmatrix_column, display_ledmatrix_numbers_code, cursor);

	--	display_ledmatrix_numbers <= (0,9,7,8);
	--	display_led8_numbers <= (1,2,3,4,5,6);

	--编码
	display_ledmatrix_numbers_code <= conv_std_logic_vector(display_ledmatrix_numbers(0), 4) &
		conv_std_logic_vector(display_ledmatrix_numbers(1), 4) &
		conv_std_logic_vector(display_ledmatrix_numbers(2), 4) &
		conv_std_logic_vector(display_ledmatrix_numbers(3), 4);

	display_led8_numbers_code <= conv_std_logic_vector(display_led8_numbers(0), 4) &
		conv_std_logic_vector(display_led8_numbers(1), 4) &
		conv_std_logic_vector(display_led8_numbers(2), 4) &
		conv_std_logic_vector(display_led8_numbers(3), 4) &
		conv_std_logic_vector(display_led8_numbers(4), 4) &
		conv_std_logic_vector(display_led8_numbers(5), 4);
	--	--数字拆分 除法消耗资源过大
	--	PROCESS (display_led8_number)
	--	BEGIN
	--		IF (clk_update'event AND clk_update = '1') THEN
	--		if (display_led8_number>=0) then
	--		 --正数
	--			display_led8_numbers(0) <= (display_led8_number/100000) REM 10;
	--			display_led8_numbers(1) <= (display_led8_number/10000) REM 10;
	--			display_led8_numbers(2) <= (display_led8_number/1000) REM 10;
	--			display_led8_numbers(3) <= (display_led8_number/100) REM 10;
	--			display_led8_numbers(4) <= (display_led8_number/10) REM 10;
	--			display_led8_numbers(5) <= (display_led8_number/1) REM 10;
	--			
	--		else 
	---- 负数
	--		   display_led8_numbers(0) <= 11; -- 负号
	--			display_led8_numbers(1) <= (-display_led8_number/10000) REM 10;
	--			display_led8_numbers(2) <= (-display_led8_number/1000) REM 10;
	--			display_led8_numbers(3) <= (-display_led8_number/100) REM 10;
	--			display_led8_numbers(4) <= (-display_led8_number/10) REM 10;
	--			display_led8_numbers(5) <= (-display_led8_number/1) REM 10;
	--		end if;
	--		
	--		END IF;
	--	END PROCESS;
	display_led8_numbers(1) <= (display_led8_number/10000) REM 10;
	display_led8_numbers(2) <= (display_led8_number/1000) REM 10;
	display_led8_numbers(3) <= (display_led8_number/100) REM 10;
	display_led8_numbers(4) <= (display_led8_number/10) REM 10;
	display_led8_numbers(5) <= (display_led8_number/1) REM 10;
	--更新矩阵数字显示
	PROCESS (cursor)
	BEGIN
		IF (clk_scan'event AND clk_scan = '1') THEN
			--输入光标位置更新数字
			IF (cursor < 4) THEN
				display_ledmatrix_numbers(cursor) <= display_ledmatrix_number;
			END IF;
			--通过操作更新矩阵数字
			IF (operation_transpose = '1') THEN
				display_ledmatrix_numbers(1) <= display_ledmatrix_numbers(2);
				display_ledmatrix_numbers(2) <= display_ledmatrix_numbers(1);
			END IF;
			IF (operation_reset = '1') THEN
				display_ledmatrix_numbers(0) <= 0;
				display_ledmatrix_numbers(1) <= 0;
				display_ledmatrix_numbers(2) <= 0;
				display_ledmatrix_numbers(3) <= 0;
			END IF;
		END IF;
	END PROCESS;

	-- 中心控制模块
	PROCESS (key_value)
	BEGIN
		IF (clk_scan'event AND clk_scan = '1') THEN
			CASE key_value IS
				WHEN "00000" => display_ledmatrix_number <= 7;
				WHEN "00001" => display_ledmatrix_number <= 8;
				WHEN "00010" => display_ledmatrix_number <= 9;

				WHEN "00011" => -- 第1行最右 转置矩阵计算
					IF cursor = 1 THEN
						display_ledmatrix_number <= display_ledmatrix_numbers(2);
					END IF;
					IF cursor = 2 THEN
						display_ledmatrix_number <= display_ledmatrix_numbers(1);
					END IF;
					operation_transpose <= '1';

				WHEN "00100" => display_ledmatrix_number <= 4;
				WHEN "00101" => display_ledmatrix_number <= 5;
				WHEN "00110" => display_ledmatrix_number <= 6;

				WHEN "00111" => -- 第2行最右 计算行列式
					display_led8_number <= (display_ledmatrix_numbers(0) * display_ledmatrix_numbers(3)
						- display_ledmatrix_numbers(1) * display_ledmatrix_numbers(2));

					IF (display_led8_number >= 0) THEN
						display_led8_numbers(0) <= 0;
					END IF;
				WHEN "01000" => display_ledmatrix_number <= 1;
				WHEN "01001" => display_ledmatrix_number <= 2;
				WHEN "01010" => display_ledmatrix_number <= 3;

				WHEN "01011" => -- 第3行最右 计算模方 --暂时无法计算
					display_led8_number <= ((display_ledmatrix_numbers(0) * display_ledmatrix_numbers(0)) + (display_ledmatrix_numbers(2) * display_ledmatrix_numbers(2))) * ((display_ledmatrix_numbers(0) * display_ledmatrix_numbers(0)) + (display_ledmatrix_numbers(2) * display_ledmatrix_numbers(2)))
						+ ((display_ledmatrix_numbers(0) * display_ledmatrix_numbers(1)) + (display_ledmatrix_numbers(2) * display_ledmatrix_numbers(3))) * ((display_ledmatrix_numbers(0) * display_ledmatrix_numbers(1)) + (display_ledmatrix_numbers(2) * display_ledmatrix_numbers(3)))
						+ ((display_ledmatrix_numbers(0) * display_ledmatrix_numbers(1)) + (display_ledmatrix_numbers(2) * display_ledmatrix_numbers(3))) * ((display_ledmatrix_numbers(0) * display_ledmatrix_numbers(1)) + (display_ledmatrix_numbers(2) * display_ledmatrix_numbers(3)))
						+ ((display_ledmatrix_numbers(1) * display_ledmatrix_numbers(1)) + (display_ledmatrix_numbers(3) * display_ledmatrix_numbers(3))) * ((display_ledmatrix_numbers(1) * display_ledmatrix_numbers(1)) + (display_ledmatrix_numbers(3) * display_ledmatrix_numbers(3)));

					IF (display_led8_number >= 0) THEN
						display_led8_numbers(0) <= 0;
					END IF;

				WHEN "01100" => -- 光标左移
					IF cursor /= 0 THEN
						cursor <= cursor - 1;
						display_ledmatrix_number <= display_ledmatrix_numbers(cursor - 1);
					END IF;

				WHEN "01101" => display_ledmatrix_number <= 0;

				WHEN "01110" => -- 光标右移
					IF cursor /= 4 THEN
						cursor <= cursor + 1;
						display_ledmatrix_number <= display_ledmatrix_numbers(cursor + 1);
					END IF;

				WHEN "01111" => -- 第4行最右 reset
					operation_reset <= '1';
					cursor <= 0;
					display_ledmatrix_number <= 0;
					display_led8_number <= 0;
				WHEN OTHERS => --操作符取消
					operation_transpose <= '0';
					operation_reset <= '0';

					IF (display_led8_number < 0) THEN
						display_led8_numbers(0) <= 11; -- 负号
						display_led8_number <= - display_led8_number;
					END IF;

			END CASE;
		END IF;
	END PROCESS;

	-- 计数器控制电路
	PROCESS (clk) IS
	BEGIN
		IF (clk'event AND clk = '1') THEN
			counter <= counter + '1';
		END IF;
	END PROCESS;

END rtl;