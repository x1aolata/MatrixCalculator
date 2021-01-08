LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

--自动键盘控制器
ENTITY key_controller IS
	PORT (
		clk : IN STD_LOGIC; --板载时钟
		key_row : BUFFER STD_LOGIC_VECTOR(3 DOWNTO 0); --键盘行选 从上到下  端口：21 20 19 18
		key_col : IN STD_LOGIC_VECTOR(3 DOWNTO 0); --键盘列选 从左到右  端口：9 6 5 4
		key_value : OUT STD_LOGIC_VECTOR(4 DOWNTO 0) -- 输出键码

		--		键码值说明：
		--			键盘被摁下时（只能判断单一位置被摁下）：返回键码为： 
		--				位置为键盘实际位置（从左到右，从上到下）
		--					00000 00001 00010 00011 
		--					00100 00101 00110 00111 
		--					01000 01001 01010 01011 
		--					01100 01101 01110 01111 
		--			其余情况：没有键盘被摁下，多个键盘被摁下 返回键码为 10000
	);
END ENTITY;

ARCHITECTURE rtl OF key_controller IS

	SIGNAL counter : STD_LOGIC_VECTOR(28 DOWNTO 0); --计数器
	SIGNAL key_clk_scan : STD_LOGIC; --扫描时钟
	SIGNAL key_clk_feedback : STD_LOGIC; --反馈时钟

	SIGNAL key_row1, key_row2, key_row3, key_row4 : STD_LOGIC_VECTOR(3 DOWNTO 0); --临时保存四行的值
	SIGNAL key_sequence : STD_LOGIC_VECTOR(15 DOWNTO 0); -- 合并的序列
	SIGNAL key_out : STD_LOGIC_VECTOR(4 DOWNTO 0); --输出键码
	SIGNAL key_shake_counter : INTEGER; --抖动计时器
	SIGNAL key_shake_counter_max : INTEGER := 3000;
BEGIN

	-- 计数器控制电路
	PROCESS (clk) IS
	BEGIN
		IF (clk'event AND clk = '1') THEN
			counter <= counter + '1';
		END IF;
	END PROCESS;

	-- 键盘扫描时钟
	key_clk_scan <= counter(5);

	-- 反馈时钟
	PROCESS (key_clk_scan)
	BEGIN
		IF key_row = "0111" THEN
			key_clk_feedback <= '0';
		ELSIF key_row = "1110" THEN
			key_clk_feedback <= '1';
		END IF;
	END PROCESS;

	--扫描键盘上升沿刷新片选信号
	PROCESS (key_clk_scan)
	BEGIN
		IF (rising_edge(key_clk_scan)) THEN
			IF key_row = "0111" THEN
				key_row <= "1011";
			ELSIF key_row = "1011" THEN
				key_row <= "1101";
			ELSIF key_row = "1101" THEN
				key_row <= "1110";
			ELSIF key_row = "1110" THEN
				key_row <= "0111";
			ELSE
				key_row <= "0111";
			END IF;
		END IF;
	END PROCESS;

	--扫描键盘下降沿保存信息
	PROCESS (key_clk_scan)
	BEGIN
		IF falling_edge(key_clk_scan) THEN
			IF key_row = "0111" THEN
				key_row1 <= key_col;
			ELSIF key_row = "1011" THEN
				key_row2 <= key_col;
			ELSIF key_row = "1101" THEN
				key_row3 <= key_col;
			ELSIF key_row = "1110" THEN
				key_row4 <= key_col;
			END IF;
		END IF;
	END PROCESS;

	key_sequence <= key_row1 & key_row2 & key_row3 & key_row4;

	PROCESS (key_sequence)
	BEGIN
		CASE key_sequence IS
			WHEN "0111111111111111" => key_out <= "00000";
			WHEN "1011111111111111" => key_out <= "00001";
			WHEN "1101111111111111" => key_out <= "00010";
			WHEN "1110111111111111" => key_out <= "00011";
			WHEN "1111011111111111" => key_out <= "00100";
			WHEN "1111101111111111" => key_out <= "00101";
			WHEN "1111110111111111" => key_out <= "00110";
			WHEN "1111111011111111" => key_out <= "00111";
			WHEN "1111111101111111" => key_out <= "01000";
			WHEN "1111111110111111" => key_out <= "01001";
			WHEN "1111111111011111" => key_out <= "01010";
			WHEN "1111111111101111" => key_out <= "01011";
			WHEN "1111111111110111" => key_out <= "01100";
			WHEN "1111111111111011" => key_out <= "01101";
			WHEN "1111111111111101" => key_out <= "01110";
			WHEN "1111111111111110" => key_out <= "01111";
			WHEN OTHERS => key_out <= "10000";
		END CASE;
	END PROCESS;

	PROCESS (key_out)
	BEGIN
		IF (key_clk_scan'event AND key_clk_scan = '1') THEN
			--如果有按键被按下
			IF (key_out /= "10000") THEN

				--计数器计数
				IF (key_shake_counter = key_shake_counter_max) THEN
					key_shake_counter <= key_shake_counter;
				ELSE
					key_shake_counter <= key_shake_counter + 1;
				END IF;

				IF (key_shake_counter = (key_shake_counter_max - 1)) THEN
					key_value <= key_out;
				ELSE
					key_value <= "10000";
				END IF;
			ELSE
				key_shake_counter <= 0;
			END IF;
		END IF;
	END PROCESS;
	--	key_value <= key_out;

END rtl;