----------------------------------------------------------------------------------
-- Company: Universite Bordeaux 1 departement EEA
-- Engineer: Autogenerated code 
--
-- Create Date:    
-- Design Name:
-- Module Name:    arbitrary - Behavioral
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description:
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;-- use signed numbers for numerical computations
entity arbitrary is
Port ( ent       : in   STD_LOGIC_VECTOR (15 downto 0); --N=16 bits
       sor       : out  STD_LOGIC_VECTOR (15 downto 0); --N=16 bits
       clk_50MHz : in std_logic ;
       f_ech     : in std_logic);
end arbitrary;
architecture Behavioral of RII_exemple is
 signal tmp_1, tmp_3, e_2, x1_2, op_x1_2, x2_2, op_x2_2, e_3, x1_3, op_x1_3 : signed (15 downto 0) := "0000000000000000";-- signaux intermediaires sur 16 bits,  niveau 0
 signal output_16 : signed (15 downto 0) := "0000000000000000";-- signaux intermediaires sur 16 bits,  niveau 0
 signal tmp_2, tmp_4, tmp_5, tmp_7, tmp_8, tmp_9, tmp_10, tmp_11, tmp_12, tmp_13 : signed (31 downto 0) := "00000000000000000000000000000000";-- signaux intermediaires sur 32 bits,  niveau 0
 signal tmp_14, tmp_15, tmp_16, tmp_17, tmp_18, tmp_19, tmp_20, tmp_21, tmp_22, tmp_27 : signed (31 downto 0) := "00000000000000000000000000000000";-- signaux intermediaires sur 32 bits,  niveau 0
 signal tmp_29, tmp_30, tmp_31, tmp_32, tmp_33, tmp_34, tmp_37, tmp_38, tmp_39, tmp_40 : signed (31 downto 0) := "00000000000000000000000000000000";-- signaux intermediaires sur 32 bits,  niveau 0
 signal tmp_41 : signed (31 downto 0) := "00000000000000000000000000000000";-- signaux intermediaires sur 32 bits,  niveau 0
begin
    ---------------------------------------------------------------------------------------------------------------
    -- begin of filter : convert 16 bits logic input :ent, to signed equivalent :tmp_1
    ---------------------------------------------------------------------------------------------------------------------
    tmp_1 <= signed(ent);
    tmp_2<= resize( tmp_1 , 32 );
    ---------------------------------------------
    -- code of cel 1
    ---------------------------------------------
     -- en<-en .2^0 
    tmp_3<= resize( tmp_2 , 16 ); -- en<-b0 . en 
    tmp_4 <= tmp_3 * to_signed(22708,16) ;
    tmp_37 <= shift_right(tmp_4,13) ; -- scale output of cel 1
    -- local output :tmp_37 of cel 1 will be accumulated
    ---------------------------------------------
    -- code of cel 2
    ---------------------------------------------
    tmp_5 <= shift_right(tmp_4,3) ; -- vn<-en<<L ,L=-3
    e_2 <= tmp_5(15 downto 0);
    tmp_4= (int_32)0; -- sn<-0,because D=0 
    -- update state x1_2 of cel 2
    tmp_7 <= e_2 * to_signed(9988,16) ; -- accx<-b1.vn 
    tmp_8 <= op_x1_2 * to_signed(30914,16) ; -- accx<-accx-a11 . op_x1_2 
    tmp_9 <= tmp_8 + tmp_7 ;
    tmp_10 <= op_x2_2 * to_signed(-3433,16) ; -- accx<-accx-a12 . op_x2_2 
    tmp_11 <= tmp_10 + tmp_9 ;
    tmp_12 <= shift_right(tmp_11,15) ; -- accx<-accx >> Lx1 
    x1_2 <= tmp_12(15 downto 0);
    tmp_13 <= op_x1_2 * to_signed(-24639,16) ; -- sn<-sn+C1 . x1_2 
    tmp_14 <= tmp_13 + tmp_4 ;
    -- update state x2_2 of cel 2
    tmp_15 <= e_2 * to_signed(-9475,16) ; -- accx<-b2.vn 
    tmp_16 <= op_x2_2 * to_signed(30914,16) ; -- accx<-accx-a22 . op_x2_2 
    tmp_17 <= tmp_16 + tmp_15 ;
    tmp_18 <= op_x1_2 * to_signed(6355,16) ; -- accx<-accx-a21 . op_x1_2 
    tmp_19 <= tmp_18 + tmp_17 ;
    tmp_20 <= shift_right(tmp_19,15) ; -- accx<-accx >> Lx2 
    x2_2 <= tmp_20(15 downto 0);
    tmp_21 <= op_x2_2 * to_signed(25973,16) ; -- sn<-sn+C2 . x2_2 
    tmp_22 <= tmp_21 + tmp_14 ;
    -- op_x1_2 <- q(x1_2), avec q=1/z
    z_1: process(clk_50MHz, f_ech)
    begin
      if rising_edge(clk_50MHz) then if f_ech='1' then op_x1_2 <= x1_2 ;
           end if;
      end if;
    end process;
    -- op_x2_2 <- q(x2_2), avec q=1/z
    z_2: process(clk_50MHz, f_ech)
    begin
      if rising_edge(clk_50MHz) then if f_ech='1' then op_x2_2 <= x2_2 ;
           end if;
      end if;
    end process;
    tmp_38 <= shift_right(tmp_22,1) ; -- scale output of cel 2
    -- accumulation of output: tmp_38 of cel 2 with local output: tmp_37
    tmp_39 <= tmp_37 + tmp_38 ;
    ---------------------------------------------
    -- code of cel 3
    ---------------------------------------------
    tmp_27 <= shift_right(tmp_22,3) ; -- vn<-en<<L ,L=-3
    e_3 <= tmp_27(15 downto 0);
    tmp_22= (int_32)0; -- sn<-0,because D=0 
    -- update state x1_3 of cel 3
    tmp_29 <= e_3 * to_signed(12508,16) ; -- accx<-b1.vn 
    tmp_30 <= op_x1_3 * to_signed(30287,16) ; -- accx<-accx-a11 . op_x1_3 
    tmp_31 <= tmp_30 + tmp_29 ;
    tmp_32 <= shift_right(tmp_31,15) ; -- accx<-accx >> Lx1 
    x1_3 <= tmp_32(15 downto 0);
    tmp_33 <= op_x1_3 * to_signed(20013,16) ; -- sn<-sn+C1 . x1_3 
    tmp_34 <= tmp_33 + tmp_22 ;
    -- op_x1_3 <- q(x1_3), avec q=1/z
    z_3: process(clk_50MHz, f_ech)
    begin
      if rising_edge(clk_50MHz) then if f_ech='1' then op_x1_3 <= x1_3 ;
           end if;
      end if;
    end process;
     -- scale output of cel 3
    -- accumulation of output: tmp_34 of cel 3 with local output: tmp_39
    tmp_40 <= tmp_39 + tmp_34 ;
    ----------------------------------------------------------
    -- end of filter, scale global output : tmp_40
    ----------------------------------------------------------
    tmp_41 <= shift_right(tmp_40,14) ;
    output_16 <= tmp_41(15 downto 0);
    sor <= std_logic_vector(output_16);
end Behavioral;
