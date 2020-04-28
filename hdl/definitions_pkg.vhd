------------------------------------------------------------------------------
--  Copyright (c) 2020 by Oliver Bründler, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use ieee.math_real.all;
	
library work;
	use work.psi_common_math_pkg.all;
	
------------------------------------------------------------------------------
-- Package Header
------------------------------------------------------------------------------
package definitions_pkg is

	-- Addresses 
	constant RegIdx_Ctrl_c				: natural 	:= 0;
	constant BitIdx_Ctrl_Ena_c			: natural	:= 0;
	constant RegIdx_RegCnt_c			: natural	:= 1;
	constant RegIdx_RdData_c			: natural	:= 2;
	constant RegIdx_RdLast_c			: natural	:= 3;
	constant BitIdx_RdLast_c			: natural	:= 0;
	constant RegIdx_Level_c				: natural	:= 4;

	constant RegCount_c					: natural	:= RegIdx_Level_c+1;
	
	constant MemOffs_c					: natural 	:= 8;

end package;






