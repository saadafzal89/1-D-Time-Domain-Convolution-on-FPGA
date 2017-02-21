-- Greg Stitt
-- University of Florida

-- Entity: add_tree
-- Description : A pipelined adder tree with generics for the number of
-- inputs and the width of each input. To use the add tree, the inputs must be
-- converted from an array into a std_logic_vector to avoid limitations of
-- arrays of unconstrained types.

-- INSTRUCTIONS: The latency of the entity is ceil(log2(num_inputs)), which can
-- be calculated using the clog2() in math_custom.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-------------------------------------------------------------------------------
-- Generic Descriptions
-- num_inputs : The number of inputs in the adder tree
-- data_width : The width of each input
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Port Descriptions
-- (User signals)
-- clk: clock
-- rst: reset
-- en : enable ('0' stalls the pipeline)
-- inputs : The inputs to the adder tree
-- output : The sum of all inputs whose width is determined by the
--          add_tree_out_width function.
-------------------------------------------------------------------------------

entity add_tree is
  generic (
    num_inputs : positive;
    data_width : positive);
  port (
    clk    : in  std_logic;
    rst    : in  std_logic;
    en     : in  std_logic;
    input  : in  std_logic_vector(num_inputs*data_width-1 downto 0);
    output : out std_logic_vector(data_width+integer(ceil(log2(real(num_inputs))))-1 downto 0));
end add_tree;

architecture unsigned_arch of add_tree is

  type input_array is array(integer range<>) of std_logic_vector(data_width-1 downto 0);

  function getRightDepth(numInputs : natural)
    return natural is
    variable return_val : natural;
  begin
    if (numInputs = 0) then
      return_val := 0;
    else
      return_val := integer(ceil(log2(real(numInputs))));
    end if;

    return return_val;
  end getRightDepth;

  -- converts from input_array to std_logic_vector
  function vectorize(input        : input_array;
                     arraySize    : natural;
                     elementWidth : positive) return std_logic_vector is
    variable temp : std_logic_vector(arraySize*elementWidth-1 downto 0);
  begin
    for i in 0 to arraySize-1 loop
      temp((i+1)*elementWidth-1 downto i*elementWidth) := input(input'left+i);
    end loop;

    return temp;
  end function;

  -- converts from std_logic_vector to input_array
  function devectorize(input        : std_logic_vector;
                       arraySize    : natural;
                       elementWidth : positive) return input_array is
    variable temp : input_array(0 to arraySize-1);
  begin
    for i in 0 to arraySize-1 loop
      temp(i) := input((i+1)*elementWidth-1 downto i*elementWidth);
    end loop;

    return temp;
  end function;

  function add_tree_out_width(num_inputs : natural; width : natural) return positive is
  begin
    if (num_inputs > 0) then
      return width+integer(ceil(log2(real(num_inputs))));
    else
      return width;
    end if;
  end function;

  constant LEFT_TREE_INPUTS      : natural := num_inputs - num_inputs/2;
  constant RIGHT_TREE_INPUTS     : natural := num_inputs/2;
  constant LEFT_TREE_DEPTH       : natural := integer(ceil(log2(real(LEFT_TREE_INPUTS))));
  constant RIGHT_TREE_DEPTH      : natural := getRightDepth(RIGHT_TREE_INPUTS);
  constant TREE_DEPTH_DIFFERENCE : natural := LEFT_TREE_DEPTH-RIGHT_TREE_DEPTH;

  signal left_tree_out            : std_logic_vector(add_tree_out_width(LEFT_TREE_INPUTS, data_width)-1 downto 0);
  signal right_tree_out           : std_logic_vector(add_tree_out_width(RIGHT_TREE_INPUTS, data_width)-1 downto 0);
  signal right_tree_out_unaligned : std_logic_vector(add_tree_out_width(RIGHT_TREE_INPUTS, data_width)-1 downto 0);

  signal inputs     : input_array(0 to num_inputs-1);
  signal left_temp  : std_logic_vector(LEFT_TREE_INPUTS*data_width-1 downto 0);
  signal right_temp : std_logic_vector(RIGHT_TREE_INPUTS*data_width-1 downto 0);
begin

  -- convert big input vector into array of data
  inputs <= devectorize(input, num_inputs, data_width);

  -- recursion base cases  
  U_END1 : if (num_inputs = 1) generate
    output <= inputs(0);
  end generate U_END1;

  U_END2 : if (num_inputs = 2) generate
    process(clk)
    begin
      if (rising_edge(clk)) then
        if (en = '1') then
          output <= std_logic_vector(resize(unsigned(inputs(0)), data_width+1)+
                                     resize(unsigned(inputs(1)), data_width+1));
        end if;
      end if;
    end process;
  end generate U_END2;

  -- recursion to create tree  
  U_RECURSE : if (num_inputs > 2) generate

    -- put left array inputs into a big vector
    left_temp <= vectorize(inputs(num_inputs/2 to num_inputs-1), LEFT_TREE_INPUTS, data_width);

    -- left adder sub tree. In the case of odd inputs, this tree gets one more
    -- than the right tree
    U_LEFT_TREE : entity work.add_tree(unsigned_arch)
      generic map (
        num_inputs => LEFT_TREE_INPUTS,
        data_width => data_width)
      port map (
        clk    => clk,
        rst    => rst,
        en     => en,
        input  => left_temp,
        output => left_tree_out);

    -- put right array inputs into a big vector
    right_temp <= vectorize(inputs(0 to num_inputs/2-1), RIGHT_TREE_INPUTS, data_width);

    -- right adder tree
    U_RIGHT_TREE : entity work.add_tree(unsigned_arch)
      generic map (
        num_inputs => RIGHT_TREE_INPUTS,
        data_width => data_width)
      port map (
        clk    => clk,
        rst    => rst,
        en     => en,
        input  => right_temp,
        output => right_tree_out_unaligned);

    -- if there are an odd number of inputs, we need to delay the right
    -- subtree by the difference in the depth of the left and right
    U_ALIGN_ODD : if num_inputs mod 2 /= 0 generate
      U_DELAY : entity work.delay
        generic map (
          cycles => TREE_DEPTH_DIFFERENCE,
          width  => right_tree_out_unaligned'length,
          init   => std_logic_vector(to_unsigned(0, right_tree_out_unaligned'length)))
        port map (
          clk    => clk,
          rst    => rst,
          en     => en,
          input  => right_tree_out_unaligned,
          output => right_tree_out);
    end generate U_ALIGN_ODD;

    -- no alignment needed for even inputs
    U_ALIGN_EVEN : if num_inputs mod 2 = 0 generate
      right_tree_out <= right_tree_out_unaligned;
    end generate U_ALIGN_EVEN;

    -- add the two sub tree results
    process(clk)
    begin
      if (rising_edge(clk)) then
        if (en = '1') then
          output <= std_logic_vector(resize(unsigned(left_tree_out), output'length)+
                                     resize(unsigned(right_tree_out), output'length));
        end if;
      end if;
    end process;
  end generate U_RECURSE;
end unsigned_arch;


architecture signed_arch of add_tree is

  type input_array is array(integer range<>) of std_logic_vector(data_width-1 downto 0);

  function getRightDepth(numInputs : natural)
    return natural is
    variable return_val : natural;
  begin
    if (numInputs = 0) then
      return_val := 0;
    else
      return_val := integer(ceil(log2(real(numInputs))));
    end if;

    return return_val;
  end getRightDepth;

  -- converts from input_array to std_logic_vector
  function vectorize(input        : input_array;
                     arraySize    : natural;
                     elementWidth : positive) return std_logic_vector is
    variable temp : std_logic_vector(arraySize*elementWidth-1 downto 0);
  begin
    for i in 0 to arraySize-1 loop
      temp((i+1)*elementWidth-1 downto i*elementWidth) := input(input'left+i);
    end loop;

    return temp;
  end function;

  -- converts from std_logic_vector to input_array
  function devectorize(input        : std_logic_vector;
                       arraySize    : natural;
                       elementWidth : positive) return input_array is
    variable temp : input_array(0 to arraySize-1);
  begin
    for i in 0 to arraySize-1 loop
      temp(i) := input((i+1)*elementWidth-1 downto i*elementWidth);
    end loop;

    return temp;
  end function;

  function add_tree_out_width(num_inputs : natural; width : natural) return positive is
  begin
    if (num_inputs > 0) then
      return width+integer(ceil(log2(real(num_inputs))));
    else
      return width;
    end if;
  end function;

  constant LEFT_TREE_INPUTS      : natural := num_inputs - num_inputs/2;
  constant RIGHT_TREE_INPUTS     : natural := num_inputs/2;
  constant LEFT_TREE_DEPTH       : natural := integer(ceil(log2(real(LEFT_TREE_INPUTS))));
  constant RIGHT_TREE_DEPTH      : natural := getRightDepth(RIGHT_TREE_INPUTS);
  constant TREE_DEPTH_DIFFERENCE : natural := LEFT_TREE_DEPTH-RIGHT_TREE_DEPTH;

  signal left_tree_out            : std_logic_vector(add_tree_out_width(LEFT_TREE_INPUTS, data_width)-1 downto 0);
  signal right_tree_out           : std_logic_vector(add_tree_out_width(RIGHT_TREE_INPUTS, data_width)-1 downto 0);
  signal right_tree_out_unaligned : std_logic_vector(add_tree_out_width(RIGHT_TREE_INPUTS, data_width)-1 downto 0);

  signal inputs     : input_array(0 to num_inputs-1);
  signal left_temp  : std_logic_vector(LEFT_TREE_INPUTS*data_width-1 downto 0);
  signal right_temp : std_logic_vector(RIGHT_TREE_INPUTS*data_width-1 downto 0);
begin

  -- convert big input vector into array of data
  inputs <= devectorize(input, num_inputs, data_width);

  -- recursion base cases  
  U_END1 : if (num_inputs = 1) generate
    output <= inputs(0);
  end generate U_END1;

  U_END2 : if (num_inputs = 2) generate
    process(clk)
    begin
      if (rising_edge(clk)) then
        if (en = '1') then
          output <= std_logic_vector(resize(signed(inputs(0)), data_width+1)+
                                     resize(signed(inputs(1)), data_width+1));
        end if;
      end if;
    end process;
  end generate U_END2;

  -- recursion to create tree  
  U_RECURSE : if (num_inputs > 2) generate

    -- put left array inputs into a big vector
    left_temp <= vectorize(inputs(num_inputs/2 to num_inputs-1), LEFT_TREE_INPUTS, data_width);

    -- left adder sub tree. In the case of odd inputs, this tree gets one more
    -- than the right tree
    U_LEFT_TREE : entity work.add_tree(signed_arch)
      generic map (
        num_inputs => LEFT_TREE_INPUTS,
        data_width => data_width)
      port map (
        clk    => clk,
        rst    => rst,
        en     => en,
        input  => left_temp,
        output => left_tree_out);

    -- put right array inputs into a big vector
    right_temp <= vectorize(inputs(0 to num_inputs/2-1), RIGHT_TREE_INPUTS, data_width);

    -- right adder tree
    U_RIGHT_TREE : entity work.add_tree(signed_arch)
      generic map (
        num_inputs => RIGHT_TREE_INPUTS,
        data_width => data_width)
      port map (
        clk    => clk,
        rst    => rst,
        en     => en,
        input  => right_temp,
        output => right_tree_out_unaligned);

    -- if there are an odd number of inputs, we need to delay the right
    -- subtree by the difference in the depth of the left and right
    U_ALIGN_ODD : if num_inputs mod 2 /= 0 generate
      U_DELAY : entity work.delay
        generic map (
          cycles => TREE_DEPTH_DIFFERENCE,
          width  => right_tree_out_unaligned'length,
          init   => std_logic_vector(to_unsigned(0, right_tree_out_unaligned'length)))
        port map (
          clk    => clk,
          rst    => rst,
          en     => en,
          input  => right_tree_out_unaligned,
          output => right_tree_out);
    end generate U_ALIGN_ODD;

    -- no alignment needed for even inputs
    U_ALIGN_EVEN : if num_inputs mod 2 = 0 generate
      right_tree_out <= right_tree_out_unaligned;
    end generate U_ALIGN_EVEN;

    -- add the two sub tree results
    process(clk)
    begin
      if (rising_edge(clk)) then
        if (en = '1') then
          output <= std_logic_vector(resize(signed(left_tree_out), output'length)+
                                     resize(signed(right_tree_out), output'length));
        end if;
      end if;
    end process;
  end generate U_RECURSE;
end signed_arch;
