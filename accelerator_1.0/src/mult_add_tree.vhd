-- Greg Stitt
-- University of Florida

-- Description: This entity implements a fully pipelined multiply-add tree that
-- multiplies corresponding positions in two input arrays and then accumulates
-- the results.
-- The inputs should be two arrays of num_inputs elements, where each element
-- is in_width bits wide. To use the entity the input arrays must be
-- converted to a single std_logic_vector to avoid limitations of
-- arrays of unconstrained types.

-- INSTRUCTIONS: The latency of the entity is clog2(num_inputs)+1

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.math_custom.all;

entity mult_add_tree is
  generic (
    num_inputs   : positive;
    input1_width : positive;
    input2_width : positive);
  port (
    clk    : in  std_logic;
    rst    : in  std_logic;
    en     : in  std_logic;
    input1 : in  std_logic_vector(num_inputs*input1_width-1 downto 0);
    input2 : in  std_logic_vector(num_inputs*input2_width-1 downto 0);
    output : out std_logic_vector(input1_width+input2_width+clog2(num_inputs)-1 downto 0));
end mult_add_tree;

-- architecture that assumes input1 and input2 are unsigned values (e.g., image
-- pixels)
architecture unsigned_arch of mult_add_tree is

  constant PRODUCT_WIDTH : positive := input1_width+input2_width;

  type input1_array is array(integer range<>) of std_logic_vector(input1_width-1 downto 0);
  type input2_array is array(integer range<>) of std_logic_vector(input2_width-1 downto 0);
  type mult_array is array(integer range<>) of std_logic_vector(PRODUCT_WIDTH-1 downto 0);

  signal product     : mult_array(0 to num_inputs-1);
  signal in1         : input1_array(0 to num_inputs-1);
  signal in2         : input2_array(0 to num_inputs-1);
  signal add_tree_in : std_logic_vector(num_inputs*PRODUCT_WIDTH-1 downto 0);
  
begin  -- STR

  -- convert input vectors into arrays of data
  U_DEVECTORIZE : for i in 0 to num_inputs-1 generate
    in1(i) <= input1((i+1)*input1_width-1 downto i*input1_width);
    in2(i) <= input2((i+1)*input2_width-1 downto i*input2_width);
  end generate;

  -- calculate products
  U_MULT : for i in 0 to num_inputs-1 generate
    -- a pipelined multiplier
    process(clk)
    begin
      if (rising_edge(clk)) then
        if (en = '1') then
          product(i) <= std_logic_vector(unsigned(in1(i))*unsigned(in2(i)));
        end if;
      end if;
    end process;
  end generate U_MULT;

  -- put adder tree inputs into a big vector (i.e., "vectorize")
  U_VECTORIZE : for i in 0 to num_inputs-1 generate
    add_tree_in((i+1)*PRODUCT_WIDTH-1 downto i*PRODUCT_WIDTH) <= product(i);
  end generate;

  -- sum all differences
  U_ADD_TREE : entity work.add_tree(unsigned_arch)
    generic map (
      num_inputs => num_inputs,
      data_width => PRODUCT_WIDTH)
    port map (
      clk    => clk,
      rst    => rst,
      en     => en,
      input  => add_tree_in,
      output => output);

end unsigned_arch;


architecture signed_arch of mult_add_tree is

  constant PRODUCT_WIDTH : positive := input1_width+input2_width;

  type input1_array is array(integer range<>) of std_logic_vector(input1_width-1 downto 0);
  type input2_array is array(integer range<>) of std_logic_vector(input2_width-1 downto 0);
  type mult_array is array(integer range<>) of std_logic_vector(PRODUCT_WIDTH-1 downto 0);

  signal product     : mult_array(0 to num_inputs-1);
  signal in1         : input1_array(0 to num_inputs-1);
  signal in2         : input2_array(0 to num_inputs-1);
  signal add_tree_in : std_logic_vector(num_inputs*PRODUCT_WIDTH-1 downto 0);
  
begin  -- STR

  -- convert input vectors into arrays of data
  U_DEVECTORIZE : for i in 0 to num_inputs-1 generate
    in1(i) <= input1((i+1)*input1_width-1 downto i*input1_width);
    in2(i) <= input2((i+1)*input2_width-1 downto i*input2_width);
  end generate;

  -- calculate products
  U_MULT : for i in 0 to num_inputs-1 generate
    -- a pipelined multiplier
    process(clk)
    begin
      if (rising_edge(clk)) then
        if (en = '1') then
          product(i) <= std_logic_vector(signed(in1(i))*signed(in2(i)));
        end if;
      end if;
    end process;
  end generate U_MULT;

  -- put adder tree inputs into a big vector (i.e., "vectorize")
  U_VECTORIZE : for i in 0 to num_inputs-1 generate
    add_tree_in((i+1)*PRODUCT_WIDTH-1 downto i*PRODUCT_WIDTH) <= product(i);
  end generate;

  -- sum all differences
  U_ADD_TREE : entity work.add_tree(signed_arch)
    generic map (
      num_inputs => num_inputs,
      data_width => PRODUCT_WIDTH)
    port map (
      clk    => clk,
      rst    => rst,
      en     => en,
      input  => add_tree_in,
      output => output);

end signed_arch;
