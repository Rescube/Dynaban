----------------------------------------------------------------------------------
-- Company: Universite Bordeaux 1 departement EEA
-- Engineer: Autogenerated code 
--
-- Create Date:    
-- Design Name:
-- Module Name:    band_pass - Behavioral
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description:
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;-- use signed numbers for numerical computations
entity band_pass is
Port ( ent       : in   STD_LOGIC_VECTOR (15 downto 0); --N=16 bits
       sor       : out  STD_LOGIC_VECTOR (15 downto 0); --N=16 bits
       clk_50MHz : in std_logic ;
       f_ech     : in std_logic);
end band_pass;
architecture Behavioral of RII_exemple is
 signal tmp_1, x2_2, x1_2, opx2_2, x2_3, x1_3, opx2_3, x2_4, x1_4, opx2_4 : signed (15 downto 0) := "0000000000000000";-- signaux intermediaires sur 16 bits,  niveau 0
 signal x2_5, x1_5, opx2_5, x2_6, x1_6, opx2_6, x2_7, x1_7, opx2_7, output_16 : signed (15 downto 0) := "0000000000000000";-- signaux intermediaires sur 16 bits,  niveau 0
 signal opi1_2, tmp_15, tmp_16, tmp_17, tmp_18, i1_2, opi2_2, tmp_22, tmp_23, tmp_24 : signed (19 downto 0) := "00000000000000000000";-- signaux intermediaires sur 20 bits,  niveau 0
 signal tmp_25, i2_2, opi1_4, tmp_63, tmp_64, tmp_65, tmp_66, i1_4, opi2_4, tmp_70 : signed (19 downto 0) := "00000000000000000000";-- signaux intermediaires sur 20 bits,  niveau 0
 signal tmp_71, tmp_72, tmp_73, i2_4, opi1_6, tmp_111, tmp_112, tmp_113, tmp_114, i1_6 : signed (19 downto 0) := "00000000000000000000";-- signaux intermediaires sur 20 bits,  niveau 0
 signal opi2_6, tmp_118, tmp_119, tmp_120, tmp_121, i2_6 : signed (19 downto 0) := "00000000000000000000";-- signaux intermediaires sur 20 bits,  niveau 0
 signal opi1_3, tmp_39, tmp_40, tmp_41, tmp_42, i1_3, opi2_3, tmp_46, tmp_47, tmp_48 : signed (20 downto 0) := "000000000000000000000";-- signaux intermediaires sur 21 bits,  niveau 0
 signal tmp_49, i2_3, opi1_5, tmp_87, tmp_88, tmp_89, tmp_90, i1_5, opi2_5, tmp_94 : signed (20 downto 0) := "000000000000000000000";-- signaux intermediaires sur 21 bits,  niveau 0
 signal tmp_95, tmp_96, tmp_97, i2_5, opi1_7, tmp_135, tmp_136, tmp_137, tmp_138, i1_7 : signed (20 downto 0) := "000000000000000000000";-- signaux intermediaires sur 21 bits,  niveau 0
 signal opi2_7, tmp_142, tmp_143, tmp_144, tmp_145, i2_7 : signed (20 downto 0) := "000000000000000000000";-- signaux intermediaires sur 21 bits,  niveau 0
 signal tmp_2, tmp_3, tmp_4, tmp_5, tmp_6, tmp_7, tmp_8, tmp_9, tmp_10, tmp_11 : signed (31 downto 0) := "00000000000000000000000000000000";-- signaux intermediaires sur 32 bits,  niveau 0
 signal tmp_27, tmp_28, tmp_29, tmp_30, tmp_31, tmp_32, tmp_33, tmp_34, tmp_35, tmp_51 : signed (31 downto 0) := "00000000000000000000000000000000";-- signaux intermediaires sur 32 bits,  niveau 0
 signal tmp_52, tmp_53, tmp_54, tmp_55, tmp_56, tmp_57, tmp_58, tmp_59, tmp_75, tmp_76 : signed (31 downto 0) := "00000000000000000000000000000000";-- signaux intermediaires sur 32 bits,  niveau 0
 signal tmp_77, tmp_78, tmp_79, tmp_80, tmp_81, tmp_82, tmp_83, tmp_99, tmp_100, tmp_101 : signed (31 downto 0) := "00000000000000000000000000000000";-- signaux intermediaires sur 32 bits,  niveau 0
 signal tmp_102, tmp_103, tmp_104, tmp_105, tmp_106, tmp_107, tmp_123, tmp_124, tmp_125, tmp_126 : signed (31 downto 0) := "00000000000000000000000000000000";-- signaux intermediaires sur 32 bits,  niveau 0
 signal tmp_127, tmp_128, tmp_129, tmp_130, tmp_131, tmp_147, tmp_148, tmp_149, tmp_150, tmp_151 : signed (31 downto 0) := "00000000000000000000000000000000";-- signaux intermediaires sur 32 bits,  niveau 0
 signal tmp_152, tmp_153, tmp_154, tmp_155 : signed (31 downto 0) := "00000000000000000000000000000000";-- signaux intermediaires sur 32 bits,  niveau 0
begin
    ---------------------------------------------------------------------------------------------------------------
    -- begin of filter : convert 16 bits logic input :ent, to signed equivalent :tmp_1
    ---------------------------------------------------------------------------------------------------------------------
    tmp_1 <= signed(ent);
    tmp_2<= resize( tmp_1 , 32 );
    ---------------------------------------------
    -- code of cel 1
    ---------------------------------------------
    --  no generated code because cel 1 has zero gain
    -- no accumulation because cel 1 has zero gain 
    ---------------------------------------------
    -- code of cel 2
    ---------------------------------------------
    tmp_3 <= shift_left(tmp_2,8) ; -- en<<L+LA ,L=-5,LA=13
      -- AR part of cel 2
    tmp_4 <= x2_2 * to_signed(14058,16) ; -- - a1 . x1 
    tmp_5 <= tmp_4 + tmp_3 ;
    tmp_6 <= opx2_2 * to_signed(-18837,16) ; -- - a2 . x2 
    tmp_7 <= tmp_6 + tmp_5 ;
    tmp_8 <= shift_right(tmp_7,13) ; -- vn<-en >> LA 
    x1_2 <= tmp_8(15 downto 0); -- x1=vn  
      -- MA part of cel 2
    tmp_9 <= x2_2 * to_signed(22797,16) ; -- en<-b1 . x2 ,because b0=0
    tmp_10 <= opx2_2 * to_signed(-8059,16) ; -- b2 .op x2
    tmp_11 <= tmp_10 + tmp_9 ; -- output of cel 2
    -- x2_2 <- q(x1_2), avec q=(2^-3)/(z-[ 1 - (2^-3) ] )
    z_1: process(clk_50MHz, f_ech)
    begin
      if rising_edge(clk_50MHz) then if f_ech='1' then opi1_2 <= i1_2 ;
           end if;
      end if;
    end process;
    x2_2 <= tmp_15(15 downto 0);
    tmp_16<= resize( x1_2 , 20 );
    tmp_17<= resize( x2_2 , 20 );
    tmp_18 <= tmp_16 - tmp_17 ;
    i1_2 <= tmp_18 + opi1_2 ;
    tmp_15 <= shift_right(opi1_2,3) ;
    -- opx2_2 <- q(x2_2), avec q=(2^-3)/(z-[ 1 - (2^-3) ] )
    z_2: process(clk_50MHz, f_ech)
    begin
      if rising_edge(clk_50MHz) then if f_ech='1' then opi2_2 <= i2_2 ;
           end if;
      end if;
    end process;
    opx2_2 <= tmp_22(15 downto 0);
    tmp_23<= resize( x2_2 , 20 );
    tmp_24<= resize( opx2_2 , 20 );
    tmp_25 <= tmp_23 - tmp_24 ;
    i2_2 <= tmp_25 + opi2_2 ;
    tmp_22 <= shift_right(opi2_2,3) ;
    tmp_147 <= shift_right(tmp_11,1) ; -- scale output of cel 2
    -- local output :tmp_147 of cel 2 will be accumulated
    ---------------------------------------------
    -- code of cel 3
    ---------------------------------------------
    tmp_27 <= shift_left(tmp_2,8) ; -- en<<L+LA ,L=-6,LA=14
      -- AR part of cel 3
    tmp_28 <= x2_3 * to_signed(30623,16) ; -- - a1 . x1 
    tmp_29 <= tmp_28 + tmp_27 ;
    tmp_30 <= opx2_3 * to_signed(-30589,16) ; -- - a2 . x2 
    tmp_31 <= tmp_30 + tmp_29 ;
    tmp_32 <= shift_right(tmp_31,14) ; -- vn<-en >> LA 
    x1_3 <= tmp_32(15 downto 0); -- x1=vn  
      -- MA part of cel 3
    tmp_33 <= x2_3 * to_signed(15337,16) ; -- en<-b1 . x2 ,because b0=0
    tmp_34 <= opx2_3 * to_signed(-26497,16) ; -- b2 .op x2
    tmp_35 <= tmp_34 + tmp_33 ; -- output of cel 3
    -- x2_3 <- q(x1_3), avec q=(2^-4)/(z-[ 1 - (2^-4) ] )
    z_3: process(clk_50MHz, f_ech)
    begin
      if rising_edge(clk_50MHz) then if f_ech='1' then opi1_3 <= i1_3 ;
           end if;
      end if;
    end process;
    x2_3 <= tmp_39(15 downto 0);
    tmp_40<= resize( x1_3 , 21 );
    tmp_41<= resize( x2_3 , 21 );
    tmp_42 <= tmp_40 - tmp_41 ;
    i1_3 <= tmp_42 + opi1_3 ;
    tmp_39 <= shift_right(opi1_3,4) ;
    -- opx2_3 <- q(x2_3), avec q=(2^-4)/(z-[ 1 - (2^-4) ] )
    z_4: process(clk_50MHz, f_ech)
    begin
      if rising_edge(clk_50MHz) then if f_ech='1' then opi2_3 <= i2_3 ;
           end if;
      end if;
    end process;
    opx2_3 <= tmp_46(15 downto 0);
    tmp_47<= resize( x2_3 , 21 );
    tmp_48<= resize( opx2_3 , 21 );
    tmp_49 <= tmp_47 - tmp_48 ;
    i2_3 <= tmp_49 + opi2_3 ;
    tmp_46 <= shift_right(opi2_3,4) ;
     -- scale output of cel 3
    -- accumulation of output: tmp_35 of cel 3 with local output: tmp_147
    tmp_148 <= tmp_147 + tmp_35 ;
    ---------------------------------------------
    -- code of cel 4
    ---------------------------------------------
    tmp_51 <= shift_left(tmp_2,10) ; -- en<<L+LA ,L=-4,LA=14
      -- AR part of cel 4
    tmp_52 <= x2_4 * to_signed(26666,16) ; -- - a1 . x1 
    tmp_53 <= tmp_52 + tmp_51 ;
    tmp_54 <= opx2_4 * to_signed(-30649,16) ; -- - a2 . x2 
    tmp_55 <= tmp_54 + tmp_53 ;
    tmp_56 <= shift_right(tmp_55,14) ; -- vn<-en >> LA 
    x1_4 <= tmp_56(15 downto 0); -- x1=vn  
      -- MA part of cel 4
    tmp_57 <= x2_4 * to_signed(-24271,16) ; -- en<-b1 . x2 ,because b0=0
    tmp_58 <= opx2_4 * to_signed(-3800,16) ; -- b2 .op x2
    tmp_59 <= tmp_58 + tmp_57 ; -- output of cel 4
    -- x2_4 <- q(x1_4), avec q=(2^-3)/(z-[ 1 - (2^-3) ] )
    z_5: process(clk_50MHz, f_ech)
    begin
      if rising_edge(clk_50MHz) then if f_ech='1' then opi1_4 <= i1_4 ;
           end if;
      end if;
    end process;
    x2_4 <= tmp_63(15 downto 0);
    tmp_64<= resize( x1_4 , 20 );
    tmp_65<= resize( x2_4 , 20 );
    tmp_66 <= tmp_64 - tmp_65 ;
    i1_4 <= tmp_66 + opi1_4 ;
    tmp_63 <= shift_right(opi1_4,3) ;
    -- opx2_4 <- q(x2_4), avec q=(2^-3)/(z-[ 1 - (2^-3) ] )
    z_6: process(clk_50MHz, f_ech)
    begin
      if rising_edge(clk_50MHz) then if f_ech='1' then opi2_4 <= i2_4 ;
           end if;
      end if;
    end process;
    opx2_4 <= tmp_70(15 downto 0);
    tmp_71<= resize( x2_4 , 20 );
    tmp_72<= resize( opx2_4 , 20 );
    tmp_73 <= tmp_71 - tmp_72 ;
    i2_4 <= tmp_73 + opi2_4 ;
    tmp_70 <= shift_right(opi2_4,3) ;
    tmp_149 <= shift_right(tmp_59,1) ; -- scale output of cel 4
    -- accumulation of output: tmp_149 of cel 4 with local output: tmp_148
    tmp_150 <= tmp_148 + tmp_149 ;
    ---------------------------------------------
    -- code of cel 5
    ---------------------------------------------
    tmp_75 <= shift_left(tmp_2,10) ; -- en<<L+LA ,L=-4,LA=14
      -- AR part of cel 5
    tmp_76 <= x2_5 * to_signed(27888,16) ; -- - a1 . x1 
    tmp_77 <= tmp_76 + tmp_75 ;
    tmp_78 <= opx2_5 * to_signed(-32083,16) ; -- - a2 . x2 
    tmp_79 <= tmp_78 + tmp_77 ;
    tmp_80 <= shift_right(tmp_79,14) ; -- vn<-en >> LA 
    x1_5 <= tmp_80(15 downto 0); -- x1=vn  
      -- MA part of cel 5
    tmp_81 <= x2_5 * to_signed(-7001,16) ; -- en<-b1 . x2 ,because b0=0
    tmp_82 <= opx2_5 * to_signed(22379,16) ; -- b2 .op x2
    tmp_83 <= tmp_82 + tmp_81 ; -- output of cel 5
    -- x2_5 <- q(x1_5), avec q=(2^-4)/(z-[ 1 - (2^-4) ] )
    z_7: process(clk_50MHz, f_ech)
    begin
      if rising_edge(clk_50MHz) then if f_ech='1' then opi1_5 <= i1_5 ;
           end if;
      end if;
    end process;
    x2_5 <= tmp_87(15 downto 0);
    tmp_88<= resize( x1_5 , 21 );
    tmp_89<= resize( x2_5 , 21 );
    tmp_90 <= tmp_88 - tmp_89 ;
    i1_5 <= tmp_90 + opi1_5 ;
    tmp_87 <= shift_right(opi1_5,4) ;
    -- opx2_5 <- q(x2_5), avec q=(2^-4)/(z-[ 1 - (2^-4) ] )
    z_8: process(clk_50MHz, f_ech)
    begin
      if rising_edge(clk_50MHz) then if f_ech='1' then opi2_5 <= i2_5 ;
           end if;
      end if;
    end process;
    opx2_5 <= tmp_94(15 downto 0);
    tmp_95<= resize( x2_5 , 21 );
    tmp_96<= resize( opx2_5 , 21 );
    tmp_97 <= tmp_95 - tmp_96 ;
    i2_5 <= tmp_97 + opi2_5 ;
    tmp_94 <= shift_right(opi2_5,4) ;
     -- scale output of cel 5
    -- accumulation of output: tmp_83 of cel 5 with local output: tmp_150
    tmp_151 <= tmp_150 + tmp_83 ;
    ---------------------------------------------
    -- code of cel 6
    ---------------------------------------------
    tmp_99 <= shift_left(tmp_2,10) ; -- en<<L+LA ,L=-4,LA=14
      -- AR part of cel 6
    tmp_100 <= x2_6 * to_signed(27007,16) ; -- - a1 . x1 
    tmp_101 <= tmp_100 + tmp_99 ;
    tmp_102 <= opx2_6 * to_signed(-23817,16) ; -- - a2 . x2 
    tmp_103 <= tmp_102 + tmp_101 ;
    tmp_104 <= shift_right(tmp_103,14) ; -- vn<-en >> LA 
    x1_6 <= tmp_104(15 downto 0); -- x1=vn  
      -- MA part of cel 6
    tmp_105 <= x2_6 * to_signed(17195,16) ; -- en<-b1 . x2 ,because b0=0
    tmp_106 <= opx2_6 * to_signed(17713,16) ; -- b2 .op x2
    tmp_107 <= tmp_106 + tmp_105 ; -- output of cel 6
    -- x2_6 <- q(x1_6), avec q=(2^-3)/(z-[ 1 - (2^-3) ] )
    z_9: process(clk_50MHz, f_ech)
    begin
      if rising_edge(clk_50MHz) then if f_ech='1' then opi1_6 <= i1_6 ;
           end if;
      end if;
    end process;
    x2_6 <= tmp_111(15 downto 0);
    tmp_112<= resize( x1_6 , 20 );
    tmp_113<= resize( x2_6 , 20 );
    tmp_114 <= tmp_112 - tmp_113 ;
    i1_6 <= tmp_114 + opi1_6 ;
    tmp_111 <= shift_right(opi1_6,3) ;
    -- opx2_6 <- q(x2_6), avec q=(2^-3)/(z-[ 1 - (2^-3) ] )
    z_10: process(clk_50MHz, f_ech)
    begin
      if rising_edge(clk_50MHz) then if f_ech='1' then opi2_6 <= i2_6 ;
           end if;
      end if;
    end process;
    opx2_6 <= tmp_118(15 downto 0);
    tmp_119<= resize( x2_6 , 20 );
    tmp_120<= resize( opx2_6 , 20 );
    tmp_121 <= tmp_119 - tmp_120 ;
    i2_6 <= tmp_121 + opi2_6 ;
    tmp_118 <= shift_right(opi2_6,3) ;
    tmp_152 <= shift_right(tmp_107,1) ; -- scale output of cel 6
    -- accumulation of output: tmp_152 of cel 6 with local output: tmp_151
    tmp_153 <= tmp_151 + tmp_152 ;
    ---------------------------------------------
    -- code of cel 7
    ---------------------------------------------
    tmp_123 <= shift_left(tmp_2,10) ; -- en<<L+LA ,L=-3,LA=13
      -- AR part of cel 7
    tmp_124 <= x2_7 * to_signed(12210,16) ; -- - a1 . x1 
    tmp_125 <= tmp_124 + tmp_123 ;
    tmp_126 <= opx2_7 * to_signed(-19800,16) ; -- - a2 . x2 
    tmp_127 <= tmp_126 + tmp_125 ;
    tmp_128 <= shift_right(tmp_127,13) ; -- vn<-en >> LA 
    x1_7 <= tmp_128(15 downto 0); -- x1=vn  
      -- MA part of cel 7
    tmp_129 <= x2_7 * to_signed(-578,16) ; -- en<-b1 . x2 ,because b0=0
    tmp_130 <= opx2_7 * to_signed(-20765,16) ; -- b2 .op x2
    tmp_131 <= tmp_130 + tmp_129 ; -- output of cel 7
    -- x2_7 <- q(x1_7), avec q=(2^-4)/(z-[ 1 - (2^-4) ] )
    z_11: process(clk_50MHz, f_ech)
    begin
      if rising_edge(clk_50MHz) then if f_ech='1' then opi1_7 <= i1_7 ;
           end if;
      end if;
    end process;
    x2_7 <= tmp_135(15 downto 0);
    tmp_136<= resize( x1_7 , 21 );
    tmp_137<= resize( x2_7 , 21 );
    tmp_138 <= tmp_136 - tmp_137 ;
    i1_7 <= tmp_138 + opi1_7 ;
    tmp_135 <= shift_right(opi1_7,4) ;
    -- opx2_7 <- q(x2_7), avec q=(2^-4)/(z-[ 1 - (2^-4) ] )
    z_12: process(clk_50MHz, f_ech)
    begin
      if rising_edge(clk_50MHz) then if f_ech='1' then opi2_7 <= i2_7 ;
           end if;
      end if;
    end process;
    opx2_7 <= tmp_142(15 downto 0);
    tmp_143<= resize( x2_7 , 21 );
    tmp_144<= resize( opx2_7 , 21 );
    tmp_145 <= tmp_143 - tmp_144 ;
    i2_7 <= tmp_145 + opi2_7 ;
    tmp_142 <= shift_right(opi2_7,4) ;
     -- scale output of cel 7
    -- accumulation of output: tmp_131 of cel 7 with local output: tmp_153
    tmp_154 <= tmp_153 + tmp_131 ;
    ----------------------------------------------------------
    -- end of filter, scale global output : tmp_154
    ----------------------------------------------------------
    tmp_155 <= shift_right(tmp_154,12) ;
    output_16 <= tmp_155(15 downto 0);
    sor <= std_logic_vector(output_16);
end Behavioral;
