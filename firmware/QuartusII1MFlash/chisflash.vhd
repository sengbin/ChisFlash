library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- chisflash 的实体声明
entity chisflash is
	port (
		GBA_AD : inout std_logic_vector(15 downto 0)
							:= "ZZZZZZZZZZZZZZZZ"; -- GBA 24位数据-地址总线 低16位读取
		GBA_A : inout std_logic_vector(7 downto 0);   -- GBA 24位数据-地址总线 高8位地址
		GBA_CS : in std_logic;                     -- GBA Flash ROM 片选信号
		GBA_CS2 : in std_logic;                    -- GBA SRAM 片选信号
		GBA_RD : in std_logic; 		    		   -- GBA 读取信号
		GBA_WR : in std_logic; 		    		   -- GBA 写入信号
		ROM_A : out std_logic_vector(15 downto 0); -- ROM 锁存高位地址输出
		GBA_BK : out std_logic := '0';             -- GBA SRAM Bank 选择信号
		GBA_RD0 : out std_logic := '1';                -- 读取使能
		LED : inout std_logic_vector(1 downto 0) := "ZZ";           -- LED 灯
		DEBUGIO : inout std_logic_vector(1 downto 0) := "ZZ"      -- 调试IO
	);
end chisflash;

-- cart flash地址管理, bank选择
architecture cart of chisflash is
	signal GBA_RD_WR : std_logic;                    -- GBA 读写信号
	signal ADDR : std_logic_vector(15 downto 0);     -- ROM 锁存高位地址
	signal BK : std_logic := '0';                    -- GBA Bank 选择信号
	signal RD0 : std_logic := '1';                -- 读取使能
	signal WR_RD_CNT : unsigned(25 downto 0) := (others => '0'); -- GBA 读写计数器
	-- Flash状态码 | 说明
	-- 0000   | 无操作
	-- 0001   | 0005555h=AA
	-- 0010   | 0005555h=AAh, 002AAAh=55h 命令使能
	-- 0011   | 0005555h=AAh, 002AAAh=55h, 005555h=90h Chip ID
	-- 0100   | 0005555h=AAh, 002AAAh=55h, 005555h=B0h Bank切换
	-- 0101   | 0005555h=AAh, 002AAAh=55h, 005555h=A0h Write Byte 写一个字节
	-- 0110   | 0005555h=AAh, 002AAAh=55h, 005555h=80h Sector Erase/Chip Erase Start
	-- 0111   | Chip Erase End
	-- 1000   | Sector Erase End/Write Byte End
	-- 1001   | Sector/Chip Erase Erase ing
	-- 1010   | Sector/Chip Erase Erase ing
	-- 1111   | 未知中间命令
	signal FLASH_STATUS : std_logic_vector(3 downto 0) := "0000"; -- 1M Flash 状态
	-- 0x09000002
	signal MID : std_logic_vector(7 downto 0) := "11000010"; -- 1M Flash Manufacturer ID (DEFAULT: 0xC2)
	-- 0x09000004
	signal DID : std_logic_vector(7 downto 0) := "00001001"; -- 1M Flash Device ID (DEFAULT: 0x09)
begin
	GBA_RD_WR <= GBA_RD and GBA_WR;
	process (GBA_CS, GBA_RD_WR, GBA_AD) is
	begin
		-- 见: https://github.com/ChisBread/ChisFlash/blob/master/document/1-how-does-the-gba-cart-work.md#%E5%8D%A1%E6%A7%BD%E6%80%BB%E7%BA%BF---%E5%AE%9A%E4%B9%89
		if GBA_CS = '1' then
		-- 这里应该是GBA_CS下降沿时，锁存地址
			ADDR <= GBA_AD;
		elsif rising_edge(GBA_RD_WR) then
		-- GBA_RD或者GBA_WR上升沿时，触发地址自增
			ADDR <= std_logic_vector(unsigned(ADDR) + 1);
			WR_RD_CNT <= WR_RD_CNT + 1;
		end if;
	end process;
	ROM_A <= ADDR;
	process (GBA_CS, GBA_CS2, GBA_WR, ADDR, GBA_A, GBA_AD) is
	begin
		if falling_edge(GBA_WR) then
			if GBA_CS = '0' then
				if GBA_A = "10000000" then
					-- 0x1000002 MID
					if ADDR = "0000000000000001" then
						MID <= GBA_AD(7 downto 0);
					-- 0x1000004 DID
					elsif ADDR = "0000000000000010" then
						DID <= GBA_AD(7 downto 0);
					end if;
				end if;
			elsif GBA_CS2 = '0' then
				if FLASH_STATUS = "0000" or FLASH_STATUS = "1000" then
					-- 0005555h=AA
					if GBA_AD = "0101010101010101" and GBA_A = "10101010"  then
						FLASH_STATUS <= "0001";
					end if;
				elsif FLASH_STATUS = "0001" then
					-- 0005555h=AAh
					-- 002AAAh=55h 命令使能
					if GBA_AD = "0010101010101010" and GBA_A = "01010101" then
						FLASH_STATUS <= "0010";
					else
						FLASH_STATUS <= "0000";
					end if;
				elsif FLASH_STATUS = "0010" then
					-- 0005555h=AAh
					-- 002AAAh=55h
					if GBA_AD = "0101010101010101" then
						-- 005555h=90h Chip ID
						if GBA_A = "10010000" then
							FLASH_STATUS <= "0011";
						-- 005555h=B0h Bank切换
						elsif GBA_A = "10110000" then
							FLASH_STATUS <= "0100";
						else
							FLASH_STATUS <= "0000";
						end if;
					else
						FLASH_STATUS <= "0000";
					end if;
				elsif FLASH_STATUS = "0011" then
					-- 005555h=F0h ID exit
					if GBA_A = "11110000" then
						FLASH_STATUS <= "0000";
					end if;
				elsif FLASH_STATUS = "0100" then
					-- Bank切换
					BK <= GBA_A(0);
					FLASH_STATUS <= "0000";
				else
					FLASH_STATUS <= "0000";
				end if;
			end if;
		end if;
	end process;
	process (GBA_CS, GBA_CS2, GBA_RD, ADDR, GBA_A, GBA_AD, FLASH_STATUS) is
	begin
		if GBA_RD = '0' then
			if GBA_CS2 = '0' then
				if FLASH_STATUS = "0011" then
					-- manufacturer 0xC2, device 0x09
					if GBA_AD = "0000000000000001" then
						RD0 <= '1';
						GBA_A <= DID;
					elsif GBA_AD = "0000000000000000" then
						RD0 <= '1';
						GBA_A <= MID;
					else
						RD0 <= '0';
						GBA_A <= "ZZZZZZZZ";
					end if;
				else
					RD0 <= '0';
					GBA_A <= "ZZZZZZZZ";
				end if;
			else
				RD0 <= '0';
				GBA_A <= "ZZZZZZZZ";
			end if;
		else
			RD0 <= '0';
			GBA_A <= "ZZZZZZZZ";
			GBA_AD <= "ZZZZZZZZZZZZZZZZ";
		end if;
	end process;
	GBA_RD0 <= RD0 or GBA_RD; -- 读取使能，前提是GBA_RD为低电平
	GBA_BK <= BK; -- Bank选择信号
	-- 做读写指示灯用
	process (GBA_CS, GBA_CS2, WR_RD_CNT) is
	begin
		if GBA_CS2 = '0' then
			LED(1) <= '0';
			-- 关闭LED(0)指示灯
			LED(0) <= 'Z';
		else
			LED(1) <= 'Z';
			-- WR_RD_CNT 最高位为1时，亮LED(0)指示灯
			if GBA_CS = '0' AND WR_RD_CNT(25) = '0' then
				-- 实现PWM效果
				if  WR_RD_CNT(24) = '0' AND WR_RD_CNT(23 downto 12) > WR_RD_CNT(11 downto 0) then
					LED(0) <= '0';
				elsif WR_RD_CNT(24) = '1' AND WR_RD_CNT(23 downto 12) < WR_RD_CNT(11 downto 0) then
					LED(0) <= '0';
				else
					LED(0) <= 'Z';
				end if;
			else
				LED(0) <= 'Z';
			end if;
		end if;
	end process;
end cart;