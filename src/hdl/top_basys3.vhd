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
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
-- TODO
port(
    sw : in std_logic_vector (7 downto 0);
    btnU : in std_logic;
    btnC : in std_logic;
    clk : in std_logic;
    an : out std_logic_vector (3 downto 0);
    led : out std_logic_vector (15 downto 0);
    seg : out std_logic_vector (6 downto 0)
    );
end top_basys3;


architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals
   component controller_fsm is
    port(
        i_clk  : in std_logic;
        i_reset  : in std_logic;
        i_adv  : in std_logic;
        o_cycle : out std_logic_vector(3 downto 0)
        );       
   end component controller_fsm;
   
   component clock_divider is
   generic ( constant k_DIV : natural := 2	);
   port ( 	i_clk    : in std_logic;           
               o_clk    : out std_logic           
       );
   end component clock_divider;
   
   component ALU is
   port(
        i_A : in std_logic_vector(7 downto 0);
        i_B : in std_logic_vector(7 downto 0);
        i_op  : in std_logic_vector(2 downto 0);
        o_result  : out std_logic_vector(7 downto 0);
        o_flag : out std_logic_vector(2 downto 0)
        );
   end component ALU;
   
   component TDM4 is
   generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
       Port ( i_clk        : in  STD_LOGIC;
              i_D3         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
              i_D2         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
              i_D1         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
              i_D0         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
              o_data        : out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
              o_sel        : out STD_LOGIC_VECTOR (3 downto 0)    -- selected data line (one-cold)
       );
   end component TDM4;
   
   component twoscomp_decimal is
   port (
           i_binary: in std_logic_vector(7 downto 0);
           o_negative: out std_logic;
           o_hundreds: out std_logic_vector(3 downto 0);
           o_tens: out std_logic_vector(3 downto 0);
           o_ones: out std_logic_vector(3 downto 0)
       );
   end component twoscomp_decimal;
   
   component sevenSegDecoder is
   Port ( i_D : in STD_LOGIC_VECTOR (3 downto 0);
         o_S : out STD_LOGIC_VECTOR (6 downto 0)
         );
   end component sevenSegDecoder;
   
   component MUX_1 is
   port(
        i_C1 : in std_logic_vector(7 downto 0);
        i_C2 : in std_logic_vector(7 downto 0);
        i_C3 : in std_logic_vector(7 downto 0);
        i_C4 : in std_logic_vector(7 downto 0);
        i_sel : in std_logic_vector(3 downto 0);
        o_bin : out std_logic_vector(7 downto 0)
        );
  end component MUX_1;
   
   component MUX_2 is
   port(
        i_sel : in std_logic;
        i_pri : in std_logic_vector (3 downto 0);
        i_ground : in std_logic_vector (3 downto 0);
        o_an : out std_logic_vector (3 downto 0)
        );
        end component MUX_2;
   
signal w_an, w_cycle, w_hundreds, w_ones, w_tens, w_sign, w_data, w_sel : std_logic_vector (3 downto 0);
signal fsm_clk, w_clk : std_logic;   
 signal w_binary, w_a, w_b, w_output : std_logic_vector (7 downto 0);
signal w_flag : std_logic_vector (2 downto 0);
  
begin
	-- PORT MAPS ----------------------------------------
controller_fsm_inst : controller_fsm
port map(
    i_clk => fsm_clk,
    i_reset => btnU,
    i_adv => btnC,
    o_cycle => w_cycle
    );
clock_divider_inst1 : clock_divider
generic map( k_DIV => 12500000)
port map(
    i_clk => clk,
    o_clk => fsm_clk
    );
clock_divider_inst2 : clock_divider
generic map( k_DIV => 12500000)
port map(
    i_clk => w_clk,
    o_clk => w_clk
    );
MUX_1_inst : MUX_1
port map(
    i_C1 => w_a,
    i_C2 => w_b,
    i_C3 => w_output,
    i_C4 => "00000000",
    i_sel => w_cycle,
    o_bin => w_binary
);
ALU_isnt : ALU
port map(
    i_A => w_a,
    i_B => w_b,
    i_op => sw(2 downto 0),
    o_result => w_output,
    o_flag => w_flag
);
TDM4_inst : TDM4
port map(
    i_D0 => w_ones,
    i_D1 => w_tens,
    i_D2 => w_hundreds,
    i_D3 => w_sign,
    i_clk => w_clk,
    o_sel => w_sel,
    o_data => w_data
);
sevenSegDecoder_inst : sevenSegDecoder
port map(
    i_D => w_data,
    o_S => seg(6 downto 0)
);

MUX_2_inst : MUX_2
port map(
i_sel => w_cycle(3),
i_pri => w_sel,
i_ground => "1111",
o_an => w_an
);	
	
	-- CONCURRENT STATEMENTS ----------------------------
an(0) <= w_an(0);
an(1)<= w_an(1);
an(2)<= w_an(2);
an(3)<= w_an(3);
led(0) <= w_cycle(0);
led(1) <= w_cycle(1);
led(2) <= w_cycle(2);
led(3) <= w_cycle(3);
led(15 downto 13) <= w_flag when (w_cycle = "0100") else "000";
end top_basys3_arch;
