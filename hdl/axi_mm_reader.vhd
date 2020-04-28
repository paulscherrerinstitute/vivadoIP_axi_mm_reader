------------------------------------------------------------------------------
--  Copyright (c) 2020 by Oliver Bründler, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
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
    use work.definitions_pkg.all;

------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
entity axi_mm_reader is
    generic (
        TimeoutCkCycles_g   : natural   := 10_000_000;
        MaxRegCount_g       : natural    := 1024;
        MinBuffers_g        : natural   := 4;
        AxiAddrWidth_g      : natural   := 32;
        RamBehavior_g       : string    := "RBW"    -- "RBW" = read-before-write, "WBR" = write-before-read
    );
    port (
        -- Control Signals
        Clk             : in    std_logic;
        Rst             : in    std_logic;

        -- Start readout
        Trig            : in    std_logic := '0';

        -- Readout done
        DoneIrq         : out   std_logic;

        -- General Configuration
        RegCount        : std_logic_vector(log2ceil(MaxRegCount_g)-1 downto 0);
        Enable          : std_logic;

        -- Register Configuration RAM
        RegCfg_Idx      : in    std_logic_vector(log2ceil(MaxRegCount_g)-1 downto 0);
        RegCfg_WrReg    : in    std_logic_vector(AxiAddrWidth_g-1 downto 0);
        RegCfg_RdReg    : out   std_logic_vector(AxiAddrWidth_g-1 downto 0);
        RegCfg_Wr       : in    std_logic;

        -- AXI Master Interface
        AxiM_CmdRd_Addr     : out   std_logic_vector(AxiAddrWidth_g-1 downto 0);
        AxiM_CmdRd_Vld      : out   std_logic;
        AxiM_CmdRd_Rdy      : in    std_logic;
        AxiM_RdDat_Data     : in    std_logic_vector(31 downto 0);
        AxiM_RdDat_Vld      : in    std_logic;
        AxiM_RdDat_Rdy      : out   std_logic;

        -- AXI-S output data
        AxiS_Vld            : out   std_logic;
        AxiS_Rdy            : in    std_logic;
        AxiS_Last           : out   std_logic;
        AxiS_Data           : out   std_logic_vector(31 downto 0);
        AxiS_Level          : out   std_logic_vector(31 downto 0)
    );
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of axi_mm_reader is

    -- *** Types ***
    type Fsm_t is (Idle_s, ReadAddr_s, SetCmd_s, ApplyCmd_s, WaitDone_s);

    -- *** Two Process Method ***
    type two_process_r is record
        TimeoutCnt      : natural range 0 to TimeoutCkCycles_g-1;
        Start           : std_logic;
        Fsm             : Fsm_t;
        RamAddr         : std_logic_vector(RegCfg_Idx'range);
        AxiM_CmdRd_Addr : std_logic_vector(AxiM_CmdRd_Addr'range);
        AxiM_CmdRd_Vld  : std_logic;
        RegCount        : integer range 0 to MaxRegCount_g;
        DoneCnt         : integer range 0 to MaxRegCount_g;
        DoneIrq         : std_logic;
    end record;
    signal r, r_next : two_process_r;

    -- *** Component Connections ***
    signal RamRegAddr   : std_logic_vector(AxiAddrWidth_g-1 downto 0);
    signal Fifo_Rdy     : std_logic;
	signal Last			: std_logic;

begin

    --------------------------------------------------------------------------
    -- Combinatorial Proccess
    --------------------------------------------------------------------------
    p_comb : process(r, Trig, RamRegAddr, AxiM_CmdRd_Rdy, Enable, RegCount, AxiM_RdDat_Data, AxiM_RdDat_Vld, Fifo_Rdy)
        variable v : two_process_r;
    begin
        -- *** hold variables stable ***
        v := r;

        -- *** Trigger ***
        v.Start := '0';
        if Trig = '1' or r.TimeoutCnt = TimeoutCkCycles_g-1 then
            if Enable = '1' then
                v.TimeoutCnt := 0;
                v.Start := '1';
            end if;
        else
            v.TimeoutCnt := r.TimeoutCnt + 1;
        end if;

        -- *** FSM ***
        v.DoneIrq := '0';
        case r.Fsm is
            when Idle_s =>
                if r.Start = '1' then
                    v.Fsm := ReadAddr_s;
                end if;
                v.RamAddr   := (others => '0');
                v.RegCount  := to_integer(unsigned(RegCount));


            when ReadAddr_s =>
                -- Check if all registers are done
                if unsigned(r.RamAddr) = r.RegCount then
                    v.Fsm := WaitDone_s;
                else
                    v.Fsm := SetCmd_s;
                end if;
                v.RamAddr   := std_logic_vector(unsigned(r.RamAddr) + 1);

            when SetCmd_s =>
                v.AxiM_CmdRd_Addr   := RamRegAddr;
                v.AxiM_CmdRd_Vld    := '1';
                v.Fsm               := ApplyCmd_s;

            when ApplyCmd_s =>
                if AxiM_CmdRd_Rdy = '1' then
                    v.AxiM_CmdRd_Vld    := '0';
					v.Fsm   := ReadAddr_s;
                end if;               

            when WaitDone_s =>
                if r.DoneCnt = r.RegCount then
                    v.Fsm       := Idle_s;
                    v.DoneIrq   := '1';
                end if;

            when others => null;
        end case;
        if Enable = '0' then
            v.Fsm := Idle_s;
			v.TimeoutCnt := 0;
        end if;

        -- *** Done Handling ***
        if r.Fsm = Idle_s and r.Start = '1' then
            v.DoneCnt := 0;
        elsif (AxiM_RdDat_Vld = '1') and (Fifo_Rdy = '1') then
            v.DoneCnt := r.DoneCnt + 1;
        end if;

        -- *** Detect last word (combinatorial) ***
        Last <= '0';
        if r.DoneCnt = r.RegCount-1 then
            Last <= '1';
        end if;

        -- *** assign signal ***
        r_next <= v;
    end process;

    --------------------------------------------------------------------------
    -- Outputs
    --------------------------------------------------------------------------
    DoneIrq <= r.DoneIrq;
    AxiM_RdDat_Rdy <= Fifo_Rdy;
	AxiM_CmdRd_Addr <= r.AxiM_CmdRd_Addr;
	AxiM_CmdRd_Vld <= r.AxiM_CmdRd_Vld;
	

    --------------------------------------------------------------------------
    -- Sequential Proccess
    --------------------------------------------------------------------------
    p_seq : process(Clk)
    begin
        if rising_edge(Clk) then
            r <= r_next;
            if Rst = '1' then
                r.TimeoutCnt        <= 0;
                r.Start             <= '0';
                r.Fsm               <= Idle_s;
                r.AxiM_CmdRd_Vld    <= '0';
            end if;
        end if;
    end process;

    --------------------------------------------------------------------------
    -- Component Instantiations
    --------------------------------------------------------------------------
    i_ram : entity work.psi_common_tdp_ram
        generic map (
            Depth_g     => MaxRegCount_g,
            Width_g     => AxiAddrWidth_g,
            Behavior_g  => RamBehavior_g
        )
        port map (
            ClkA        => Clk,
            AddrA       => RegCfg_Idx,
            WrA         => RegCfg_Wr,
            DinA        => RegCfg_WrReg,
            DoutA       => RegCfg_RdReg,
            ClkB        => Clk,
            AddrB       => r.RamAddr,
            WrB         => '0',
            DinB        => (others => '0'),
            DoutB       => RamRegAddr
        );

    AxiS_Level(31 downto log2ceil(MaxRegCount_g*MinBuffers_g)+1) <= (others => '0');
    i_rdfifo : entity work.psi_common_sync_fifo
        generic map (
            Width_g         => 32+1,
            Depth_g         => MaxRegCount_g*MinBuffers_g,
            AlmFullOn_g     => false,
            AlmEmptyOn_g    => false,
            RamStyle_g      => "auto",
            RamBehavior_g   => RamBehavior_g
        )
        port map (
            Clk                     => Clk,
            Rst                     => Rst,
            InData(31 downto 0)     => AxiM_RdDat_Data,
            InData(32)              => Last,
            InVld                   => AxiM_RdDat_Vld,
            InRdy                   => Fifo_Rdy,
            OutData(31 downto 0)    => AxiS_Data,
            OutData(32)             => AxiS_Last,
            OutVld                  => AxiS_Vld,
            OutRdy                  => AxiS_Rdy,
            OutLevel                => AxiS_Level(log2ceil(MaxRegCount_g*MinBuffers_g) downto 0)
        );



end;





