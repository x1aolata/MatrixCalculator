LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY ledmatrix_controller IS
	PORT (
		clk : IN STD_LOGIC;
		ledmatrix_row : BUFFER STD_LOGIC_VECTOR(15 DOWNTO 0);
		--LED阵列行选（r1-r16），低电平有效，引脚为：142、137、135、134、132、131、128、127、126、120、119、118、117、113、112、111。       
		ledmatrix_column : BUFFER STD_LOGIC_VECTOR(15 DOWNTO 0);
		--LED阵列列选（c1-c16），低电平有效，引脚为：110、109、108、106、103、102、101、100、99、98、95、94、93、88、87、86。
		display_numbers : IN STD_LOGIC_VECTOR(0 TO 15);--要显示的数字 四个一组 以二进制形式编码
		cursor : IN INTEGER --光标位置 0 1 2 3 为矩阵位置 5 为不显示
	);
END ENTITY;

ARCHITECTURE rtl OF ledmatrix_controller IS
	--7*8 7行8列
	TYPE number IS ARRAY (0 TO 6) OF STD_LOGIC_VECTOR(0 TO 7);
	TYPE number_code IS ARRAY(0 TO 15) OF number;
	--数字字模
	CONSTANT number_codes : number_code := (
	(X"F1", X"EE", X"EC", X"EA", X"E6", X"EE", X"F1"), --'0'
		(X"FB", X"F3", X"FB", X"FB", X"FB", X"FB", X"F1"), --'1'
		(X"F1", X"EE", X"FE", X"F9", X"F7", X"EF", X"E0"), --'2'
		(X"F1", X"EE", X"FE", X"F9", X"FE", X"EE", X"F1"), --'3'
		(X"FD", X"F9", X"F5", X"ED", X"E0", X"FD", X"FD"), --'4'
		(X"E0", X"EF", X"E1", X"FE", X"FE", X"EE", X"F1"), --'5'
		(X"F9", X"F7", X"EF", X"E1", X"EE", X"EE", X"F1"), --'6'
		(X"E0", X"FE", X"FD", X"FB", X"F7", X"F7", X"F7"), --'7'
		(X"F1", X"EE", X"EE", X"F1", X"EE", X"EE", X"F1"), --'8'
		(X"F1", X"EE", X"EE", X"F0", X"FE", X"FD", X"F3"), --'9'
		(X"F1", X"EE", X"EE", X"E0", X"EE", X"EE", X"EE"), --'A'
		(X"E1", X"EE", X"EE", X"E1", X"EE", X"EE", X"E1"), --'B'
		(X"F1", X"EE", X"EF", X"EF", X"EF", X"EE", X"F1"), --'C'
		(X"E3", X"ED", X"EE", X"EE", X"EE", X"ED", X"E3"), --'D'
		(X"E0", X"EF", X"EF", X"E1", X"EF", X"EF", X"E0"), --'E'
		(X"E0", X"EF", X"EF", X"E1", X"EF", X"EF", X"EF")--'F'
	);
	-- 解码用
	TYPE number_list IS ARRAY (0 TO 3) OF INTEGER;
	SIGNAL numbers : number_list := (10, 10, 10, 10);

	-- 显示矩阵
	TYPE ledmatrix_type IS ARRAY (0 TO 15) OF STD_LOGIC_VECTOR(0 TO 15);
	SIGNAL ledmatrix : ledmatrix_type;

	SIGNAL counter : STD_LOGIC_VECTOR(28 DOWNTO 0);

	SIGNAL clk_refresh : STD_LOGIC;

	SIGNAL clk_cursor : STD_LOGIC;
	SIGNAL cursor_vector : STD_LOGIC_VECTOR(4 DOWNTO 0) := "00000";
BEGIN

	--刷新时钟
	clk_refresh <= counter(10);

	--光标时钟
	clk_cursor <= counter(20);

	-- 光标控制
	PROCESS (clk_cursor) IS
	BEGIN
		IF (clk_cursor'event AND clk_cursor = '1') THEN
			cursor_vector <= NOT cursor_vector;
		END IF;
	END PROCESS;
	--解码过程，将传入的数字编码转成数字
	numbers(0) <= conv_integer(display_numbers(0 TO 3));
	numbers(1) <= conv_integer(display_numbers(4 TO 7));
	numbers(2) <= conv_integer(display_numbers(8 TO 11));
	numbers(3) <= conv_integer(display_numbers(12 TO 15));

	-- 构造显示矩阵
	ledmatrix(0) <= (number_codes(numbers(0))(0) & number_codes(numbers(1))(0));
	ledmatrix(1) <= (number_codes(numbers(0))(1) & number_codes(numbers(1))(1));
	ledmatrix(2) <= (number_codes(numbers(0))(2) & number_codes(numbers(1))(2));
	ledmatrix(3) <= (number_codes(numbers(0))(3) & number_codes(numbers(1))(3));
	ledmatrix(4) <= (number_codes(numbers(0))(4) & number_codes(numbers(1))(4));
	ledmatrix(5) <= (number_codes(numbers(0))(5) & number_codes(numbers(1))(5));
	ledmatrix(6) <= (number_codes(numbers(0))(6) & number_codes(numbers(1))(6));
	--	ledmatrix(7) <= "1111111111111111";
	ledmatrix(8) <= (number_codes(numbers(2))(0) & number_codes(numbers(3))(0));
	ledmatrix(9) <= (number_codes(numbers(2))(1) & number_codes(numbers(3))(1));
	ledmatrix(10) <= (number_codes(numbers(2))(2) & number_codes(numbers(3))(2));
	ledmatrix(11) <= (number_codes(numbers(2))(3) & number_codes(numbers(3))(3));
	ledmatrix(12) <= (number_codes(numbers(2))(4) & number_codes(numbers(3))(4));
	ledmatrix(13) <= (number_codes(numbers(2))(5) & number_codes(numbers(3))(5));
	ledmatrix(14) <= (number_codes(numbers(2))(6) & number_codes(numbers(3))(6));
	--	ledmatrix(15) <= "1111111111111111";

	--光标控制
	PROCESS (cursor) IS
	BEGIN

		CASE cursor IS
			WHEN 0 => ledmatrix(7) <= "111" & cursor_vector & "11111111";
				ledmatrix(15) <= "1111111111111111";
			WHEN 1 => ledmatrix(7) <= "11111111111" & cursor_vector;
				ledmatrix(15) <= "1111111111111111";
			WHEN 2 => ledmatrix(7) <= "1111111111111111";
				ledmatrix(15) <= "111" & cursor_vector & "11111111";
			WHEN 3 => ledmatrix(7) <= "1111111111111111";
				ledmatrix(15) <= "11111111111" & cursor_vector;
			WHEN OTHERS => ledmatrix(7) <= "1111111111111111";
				ledmatrix(15) <= "1111111111111111";
		END CASE;
	END PROCESS;

	--扫描刷新显示
	PROCESS (clk) IS
	BEGIN
		IF (clk_refresh'event AND clk_refresh = '1') THEN
			IF (ledmatrix_row = "0111111111111111") THEN
				ledmatrix_row <= "1011111111111111";
				ledmatrix_column <= ledmatrix(1);
			ELSIF (ledmatrix_row = "1011111111111111") THEN
				ledmatrix_row <= "1101111111111111";
				ledmatrix_column <= ledmatrix(2);
			ELSIF (ledmatrix_row = "1101111111111111") THEN
				ledmatrix_row <= "1110111111111111";
				ledmatrix_column <= ledmatrix(3);
			ELSIF (ledmatrix_row = "1110111111111111") THEN
				ledmatrix_row <= "1111011111111111";
				ledmatrix_column <= ledmatrix(4);
			ELSIF (ledmatrix_row = "1111011111111111") THEN
				ledmatrix_row <= "1111101111111111";
				ledmatrix_column <= ledmatrix(5);
			ELSIF (ledmatrix_row = "1111101111111111") THEN
				ledmatrix_row <= "1111110111111111";
				ledmatrix_column <= ledmatrix(6);
			ELSIF (ledmatrix_row = "1111110111111111") THEN
				ledmatrix_row <= "1111111011111111";
				ledmatrix_column <= ledmatrix(7);
			ELSIF (ledmatrix_row = "1111111011111111") THEN
				ledmatrix_row <= "1111111101111111";
				ledmatrix_column <= ledmatrix(8);
			ELSIF (ledmatrix_row = "1111111101111111") THEN
				ledmatrix_row <= "1111111110111111";
				ledmatrix_column <= ledmatrix(9);
			ELSIF (ledmatrix_row = "1111111110111111") THEN
				ledmatrix_row <= "1111111111011111";
				ledmatrix_column <= ledmatrix(10);
			ELSIF (ledmatrix_row = "1111111111011111") THEN
				ledmatrix_row <= "1111111111101111";
				ledmatrix_column <= ledmatrix(11);
			ELSIF (ledmatrix_row = "1111111111101111") THEN
				ledmatrix_row <= "1111111111110111";
				ledmatrix_column <= ledmatrix(12);
			ELSIF (ledmatrix_row = "1111111111110111") THEN
				ledmatrix_row <= "1111111111111011";
				ledmatrix_column <= ledmatrix(13);
			ELSIF (ledmatrix_row = "1111111111111011") THEN
				ledmatrix_row <= "1111111111111101";
				ledmatrix_column <= ledmatrix(14);
			ELSIF (ledmatrix_row = "1111111111111101") THEN
				ledmatrix_row <= "1111111111111110";
				ledmatrix_column <= ledmatrix(15);
			ELSE
				ledmatrix_row <= "0111111111111111";
				ledmatrix_column <= ledmatrix(0);
			END IF;
		END IF;
	END PROCESS;

	PROCESS (clk) IS
	BEGIN
		IF (clk'event AND clk = '1') THEN
			counter <= counter + '1';
		END IF;
	END PROCESS;
END rtl;