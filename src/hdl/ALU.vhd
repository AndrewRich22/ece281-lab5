--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
--|
--| ALU OPCODES:
--|
--|     ADD     000
--|
--|
--|
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity ALU is
-- TODO
port(
        i_A : in std_logic_vector(7 downto 0);
        i_B : in std_logic_vector(7 downto 0);
        i_op  : in std_logic_vector(2 downto 0);
        o_result  : out std_logic_vector(7 downto 0);
        o_flag : out std_logic_vector(2 downto 0)
        );
end ALU;

architecture behavioral of ALU is 

component ALU_41_MUX is
    port(
    i_MUX_A : in std_logic_vector(7 downto 0);
    i_MUX_B : in std_logic_vector(7 downto 0);
    i_MUX_C : in std_logic_vector(7 downto 0);
    i_MUX_D : in std_logic_vector(7 downto 0);
    i_sel: in std_logic_vector(1 downto 0);
    o_result   : out std_logic_vector(7 downto 0)
    );
end component ALU_41_MUX;	

component ALU_21_MUX is
port(
    i_MUX_A : in std_logic_vector(7 downto 0);
    i_MUX_B : in std_logic_vector(7 downto 0);
    i_sel : in std_logic;
    o_result : out std_logic_vector(7 downto 0)
    );
end component ALU_21_MUX;

component full_adder is
port(
    A : in std_logic_vector(7 downto 0);
    B : in std_logic_vector(7 downto 0);
    carry_in : in std_logic;
    carry_out : out std_logic;
    sum : out std_logic_vector(7 downto 0)
);
end component full_adder;

signal w_cout : std_logic;
signal w_left, w_right, w_or, w_and, w_shiftres, w_B, w_A, w_step, w_output, w_addstep, w_substep, w_subres : std_logic_vector (7 downto 0);

begin
	-- PORT MAPS ----------------------------------------
addition_inst : ALU_41_MUX
    port map(
        i_MUX_A => w_B,
        i_MUX_B => w_B,
        i_MUX_C => w_and,
        i_MUX_D => w_or,
        i_sel => i_op(1 downto 0),
        o_result => w_step
    );
subtraction_inst : ALU_21_MUX
port map(
    i_MUX_A => w_B,
    i_MUX_B => w_substep,
    i_sel => i_op(0),
    o_result => w_subres
    );
 
full_adder_inst : full_adder
port map(
    A => i_A,
    B => i_B,
    carry_in => i_op(0),
    carry_out => w_cout,
    sum => w_B
);

shift_inst : ALU_21_MUX
port map(
    i_MUX_A => w_left,
    i_MUX_B => w_right,
    i_sel => i_op(0),
    o_result => w_shiftres
    );
    
result_inst : ALU_21_MUX
port map(
    i_MUX_A => w_step,
    i_MUX_B => w_subres,
    i_sel => i_op(2),
    o_result => w_output
    );
	-- CONCURRENT STATEMENTS ----------------------------
w_and <= i_A and i_B;
w_or <= i_A or i_B;
w_left <= std_logic_vector(shift_left(unsigned(i_A), to_integer(unsigned(i_B))));
w_right	<= std_logic_vector(shift_right(unsigned(i_A), to_integer(unsigned(i_B))));
w_substep <= not i_B;

o_flag(0) <= (not i_op(1)) and w_cout and (not i_op(2));
o_flag(1) <= (not w_output(7)) and (not w_output(6)) and (not w_output(5))
             and (not w_output(4)) and (not w_output(3)) and (not w_output(2))
              and (not w_output(1)) and (not w_output(0));
              
o_flag(2) <= w_output(7);	
end behavioral;
