------------------------------------------------------------------------------
--  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.psi_common_math_pkg.all;
    use work.psi_common_array_pkg.all;
    use work.definitions_pkg.all;

------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------
entity axi_mm_reader_wrp is
    generic
    (
        -- Config Parameters
        ClkFrequencyHz      : natural   := 100_000_000;
        TimeoutUs_g         : natural   := 100;
        MaxRegCount_g       : natural   := 1024;
        MinBuffers_g        : natural   := 4;
        Output_g            : string    := "AXIMM"; -- AXIS for AXI Sream output, AXIMM for reading via register bank
        AxiSlaveAddrWidth_g : natural   := 14;

        -- AXI Parameters
        C_S00_AXI_ID_WIDTH  : integer := 1                  -- Width of ID for for write address, write data, read address and read data
    );
    port
    (
        -----------------------------------------------------------------------------
        -- Control Signals
        -----------------------------------------------------------------------------
        Clk                         : in    std_logic;
        Rst                         : in    std_logic;

        -----------------------------------------------------------------------------
        -- Events
        -----------------------------------------------------------------------------
        Trig                        : in    std_logic := '0';
        DoneIrq                     : out   std_logic;

        -----------------------------------------------------------------------------
        -- Axi Slave Bus Interface
        -----------------------------------------------------------------------------
        -- Read address channel
        s00_axi_arid                : in    std_logic_vector(C_S00_AXI_ID_WIDTH-1   downto 0);
        s00_axi_araddr              : in    std_logic_vector(AxiSlaveAddrWidth_g-1 downto 0);
        s00_axi_arlen               : in    std_logic_vector(7 downto 0);
        s00_axi_arsize              : in    std_logic_vector(2 downto 0);
        s00_axi_arburst             : in    std_logic_vector(1 downto 0);
        s00_axi_arlock              : in    std_logic;
        s00_axi_arcache             : in    std_logic_vector(3 downto 0);
        s00_axi_arprot              : in    std_logic_vector(2 downto 0);
        s00_axi_arvalid             : in    std_logic;
        s00_axi_arready             : out   std_logic;
        -- Read data channel
        s00_axi_rid                 : out   std_logic_vector(C_S00_AXI_ID_WIDTH-1 downto 0);
        s00_axi_rdata               : out   std_logic_vector(31 downto 0);
        s00_axi_rresp               : out   std_logic_vector(1 downto 0);
        s00_axi_rlast               : out   std_logic;
        s00_axi_rvalid              : out   std_logic;
        s00_axi_rready              : in    std_logic;
        -- Write address channel
        s00_axi_awid                : in    std_logic_vector(C_S00_AXI_ID_WIDTH-1   downto 0);
        s00_axi_awaddr              : in    std_logic_vector(AxiSlaveAddrWidth_g-1 downto 0);
        s00_axi_awlen               : in    std_logic_vector(7 downto 0);
        s00_axi_awsize              : in    std_logic_vector(2 downto 0);
        s00_axi_awburst             : in    std_logic_vector(1 downto 0);
        s00_axi_awlock              : in    std_logic;
        s00_axi_awcache             : in    std_logic_vector(3 downto 0);
        s00_axi_awprot              : in    std_logic_vector(2 downto 0);
        s00_axi_awvalid             : in    std_logic;
        s00_axi_awready             : out   std_logic;
        -- Write data channel
        s00_axi_wdata               : in    std_logic_vector(31    downto 0);
        s00_axi_wstrb               : in    std_logic_vector(3 downto 0);
        s00_axi_wlast               : in    std_logic;
        s00_axi_wvalid              : in    std_logic;
        s00_axi_wready              : out   std_logic;
        -- Write response channel
        s00_axi_bid                 : out   std_logic_vector(C_S00_AXI_ID_WIDTH-1 downto 0);
        s00_axi_bresp               : out   std_logic_vector(1 downto 0);
        s00_axi_bvalid              : out   std_logic;
        s00_axi_bready              : in    std_logic;

        -----------------------------------------------------------------------------
        -- Axi Master Bus Interface
        -----------------------------------------------------------------------------
        -- AXI Read Address Channel
        m00_axi_araddr              : out   std_logic_vector(31 downto 0);
        m00_axi_arlen               : out   std_logic_vector(7 downto 0);
        m00_axi_arsize              : out   std_logic_vector(2 downto 0);
        m00_axi_arburst             : out   std_logic_vector(1 downto 0);
        m00_axi_arlock              : out   std_logic;
        m00_axi_arcache             : out   std_logic_vector(3 downto 0);
        m00_axi_arprot              : out   std_logic_vector(2 downto 0);
        m00_axi_arvalid             : out   std_logic;
        m00_axi_arready             : in    std_logic;
        -- AXI Read Data Channel
        m00_axi_rdata               : in    std_logic_vector(31 downto 0);
        m00_axi_rresp               : in    std_logic_vector(1 downto 0);
        m00_axi_rlast               : in    std_logic;
        m00_axi_rvalid              : in    std_logic;
        m00_axi_rready              : out   std_logic;

        -----------------------------------------------------------------------------
        -- Stream Output
        -----------------------------------------------------------------------------
        m_axis_tdata                : out   std_logic_vector(31 downto 0);
        m_axis_tvalid               : out   std_logic;
        m_axis_tready               : in    std_logic := '0';
        m_axis_tlast                : out   std_logic
    );

end entity axi_mm_reader_wrp;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture rtl of axi_mm_reader_wrp is

    -- Array of desired number of chip enables for each address range
    constant USER_SLV_NUM_REG               : integer              := 2**log2ceil(RegCount_c);
    constant TimeoutCkCycles_c              : natural               := integer(real(ClkFrequencyHz)*real(TimeoutUs_g)/1.0e6);

    -- IP Interconnect (IPIC) signal declarations
    signal reg_rd                           : std_logic_vector(USER_SLV_NUM_REG-1 downto  0);
    signal reg_rdata                        : t_aslv32(0 to USER_SLV_NUM_REG-1) := (others => (others => '0'));
    signal reg_wr                           : std_logic_vector(USER_SLV_NUM_REG-1 downto  0);
    signal reg_wdata                        : t_aslv32(0 to USER_SLV_NUM_REG-1);
    signal mem_addr                         : std_logic_vector(AxiSlaveAddrWidth_g-1 downto 0);
    signal mem_wr                           : std_logic_vector( 3 downto 0);
    signal mem_wdata                        : std_logic_vector(31 downto 0);
    signal mem_rdata                        : std_logic_vector(31 downto 0);
    signal mem_wrena                        : std_logic;

    -- Ohter Signals
    signal RstN                         : std_logic;
    signal AxiM_CmdRd_Addr              : std_logic_vector(31 downto 0);
    signal AxiM_CmdRd_Vld               : std_logic;
    signal AxiM_CmdRd_Rdy               : std_logic;
    signal AxiM_Rd_Done                 : std_logic;
    signal AxiM_RdDat_Data              : std_logic_vector(31 downto 0);
    signal AxiM_RdDat_Vld               : std_logic;
    signal AxiM_RdDat_Rdy               : std_logic;
    signal AxiS_Vld                     : std_logic;
    signal AxiS_Rdy                     : std_logic;
    signal AxiS_Last                    : std_logic;
    signal AxiS_Data                    : std_logic_vector(31 downto 0);
    signal AxiS_Level                   : std_logic_vector(31 downto 0);


begin

    RstN <= not Rst;

   -----------------------------------------------------------------------------
   -- Implement AXI-S Output if needed
   -----------------------------------------------------------------------------
   g_axis : if Output_g = "AXIS" generate
    m_axis_tdata    <= AxiS_Data;
    m_axis_tvalid   <= AxiS_Vld;
    AxiS_Rdy        <= m_axis_tready;
    m_axis_tlast    <= AxiS_Last;
	reg_rdata(RegIdx_Level_c)       <= AxiS_Level;
   end generate;

   g_naxis : if Output_g /= "AXIS" generate
        m_axis_tvalid                   <= '0';
        AxiS_Rdy                        <= reg_rd(RegIdx_RdData_c);
        reg_rdata(RegIdx_RdData_c)      <= AxiS_Data;
        reg_rdata(RegIdx_RdLast_c)(BitIdx_RdLast_c) <= AxiS_Last;
		reg_rdata(RegIdx_Level_c)       <= AxiS_Level;
   end generate;
   
   

   -----------------------------------------------------------------------------
   -- AXI decode instance
   -----------------------------------------------------------------------------
   axi_slave_reg_inst : entity work.psi_common_axi_slave_ipif
   generic map
   (
      -- Users parameters
      NumReg_g                             => USER_SLV_NUM_REG,
      UseMem_g                             => true,
      -- Parameters of Axi Slave Bus Interface
      AxiIdWidth_g                         => C_S00_AXI_ID_WIDTH,
      AxiAddrWidth_g                       => AxiSlaveAddrWidth_g
   )
   port map
   (
      --------------------------------------------------------------------------
      -- Axi Slave Bus Interface
      --------------------------------------------------------------------------
      -- System
      s_axi_aclk                  => Clk,
      s_axi_aresetn               => RstN,
      -- Read address channel
      s_axi_arid                  => s00_axi_arid,
      s_axi_araddr                => s00_axi_araddr,
      s_axi_arlen                 => s00_axi_arlen,
      s_axi_arsize                => s00_axi_arsize,
      s_axi_arburst               => s00_axi_arburst,
      s_axi_arlock                => s00_axi_arlock,
      s_axi_arcache               => s00_axi_arcache,
      s_axi_arprot                => s00_axi_arprot,
      s_axi_arvalid               => s00_axi_arvalid,
      s_axi_arready               => s00_axi_arready,
      -- Read data channel
      s_axi_rid                   => s00_axi_rid,
      s_axi_rdata                 => s00_axi_rdata,
      s_axi_rresp                 => s00_axi_rresp,
      s_axi_rlast                 => s00_axi_rlast,
      s_axi_rvalid                => s00_axi_rvalid,
      s_axi_rready                => s00_axi_rready,
      -- Write address channel
      s_axi_awid                  => s00_axi_awid,
      s_axi_awaddr                => s00_axi_awaddr,
      s_axi_awlen                 => s00_axi_awlen,
      s_axi_awsize                => s00_axi_awsize,
      s_axi_awburst               => s00_axi_awburst,
      s_axi_awlock                => s00_axi_awlock,
      s_axi_awcache               => s00_axi_awcache,
      s_axi_awprot                => s00_axi_awprot,
      s_axi_awvalid               => s00_axi_awvalid,
      s_axi_awready               => s00_axi_awready,
      -- Write data channel
      s_axi_wdata                 => s00_axi_wdata,
      s_axi_wstrb                 => s00_axi_wstrb,
      s_axi_wlast                 => s00_axi_wlast,
      s_axi_wvalid                => s00_axi_wvalid,
      s_axi_wready                => s00_axi_wready,
      -- Write response channel
      s_axi_bid                   => s00_axi_bid,
      s_axi_bresp                 => s00_axi_bresp,
      s_axi_bvalid                => s00_axi_bvalid,
      s_axi_bready                => s00_axi_bready,
      --------------------------------------------------------------------------
      -- Register Interface
      --------------------------------------------------------------------------
      o_reg_rd                    => reg_rd,
      i_reg_rdata                 => reg_rdata,
      o_reg_wr                    => reg_wr,
      o_reg_wdata                 => reg_wdata,
      --------------------------------------------------------------------------
      -- Memory Interface
      --------------------------------------------------------------------------
      o_mem_addr                  => mem_addr,
      o_mem_wr                    => mem_wr,
      o_mem_wdata                 => mem_wdata,
      i_mem_rdata                 => mem_rdata
   );
   mem_wrena <= '1' when mem_wr /= "0000" else '0';



    -----------------------------------------------------------------------------
    -- AXI Master Interface
    -----------------------------------------------------------------------------
    i_axim : entity work.psi_common_axi_master_simple
        generic map (
            AxiAddrWidth_g              => 32,
            AxiDataWidth_g              => 32,
            AxiMaxBeats_g               => 1,
            AxiMaxOpenTrasactions_g     => 4,
            UserTransactionSizeBits_g   => 1,
            DataFifoDepth_g             => 16,
            ImplRead_g                  => true,
            ImplWrite_g                 => false,
            RamBehavior_g               => "RBW"
        )
        port map (
            M_Axi_Aclk      => Clk,
            M_Axi_Aresetn   => RstN,
            CmdRd_Addr      => AxiM_CmdRd_Addr,
            CmdRd_Size      => "1",
            CmdRd_LowLat    => '0',
            CmdRd_Vld       => AxiM_CmdRd_Vld,
            CmdRd_Rdy       => AxiM_CmdRd_Rdy,
            RdDat_Data      => AxiM_RdDat_Data,
            RdDat_Vld       => AxiM_RdDat_Vld,
            RdDat_Rdy       => AxiM_RdDat_Rdy,
            M_Axi_ArAddr    => m00_axi_araddr,
            M_Axi_ArLen     => m00_axi_arlen,
            M_Axi_ArSize    => m00_axi_arsize,
            M_Axi_ArBurst   => m00_axi_arburst,
            M_Axi_ArLock    => m00_axi_arlock,
            M_Axi_ArCache   => m00_axi_arcache,
            M_Axi_ArProt    => m00_axi_arprot,
            M_Axi_ArValid   => m00_axi_arvalid,
            M_Axi_ArReady   => m00_axi_arready,
            M_Axi_RData     => m00_axi_rdata,
            M_Axi_RResp     => m00_axi_rresp,
            M_Axi_RLast     => m00_axi_rlast,
            M_Axi_RValid    => m00_axi_rvalid,
            M_Axi_RReady    => m00_axi_rready
        );

    -----------------------------------------------------------------------------
    -- Implementation
    -----------------------------------------------------------------------------
    i_impl : entity work.axi_mm_reader
        generic map (
            TimeoutCkCycles_g   => TimeoutCkCycles_c,
            MaxRegCount_g       => MaxRegCount_g,
            MinBuffers_g        => MinBuffers_g,
            AxiAddrWidth_g      => 32,
            RamBehavior_g       => "RBW"
        )
        port map (
            Clk             => Clk,
            Rst             => Rst,
            Trig            => Trig,
            DoneIrq         => DoneIrq,
            RegCount        => reg_wdata(RegIdx_RegCnt_c)(log2ceil(MaxRegCount_g)-1 downto 0),
            Enable          => reg_wdata(RegIdx_Ctrl_c)(BitIdx_Ctrl_Ena_c),
            RegCfg_Idx      => mem_addr(log2ceil(MaxRegCount_g)+1 downto 2),
            RegCfg_WrReg    => mem_wdata,
            RegCfg_RdReg    => mem_rdata,
            RegCfg_Wr       => mem_wrena,
            AxiM_CmdRd_Addr => AxiM_CmdRd_Addr,
            AxiM_CmdRd_Vld  => AxiM_CmdRd_Vld,
            AxiM_CmdRd_Rdy  => AxiM_CmdRd_Rdy,
            AxiM_RdDat_Data => AxiM_RdDat_Data,
            AxiM_RdDat_Vld  => AxiM_RdDat_Vld,
            AxiM_RdDat_Rdy  => AxiM_RdDat_Rdy,
            AxiS_Vld        => AxiS_Vld,
            AxiS_Rdy        => AxiS_Rdy,
            AxiS_Last       => AxiS_Last,
            AxiS_Data       => AxiS_Data,
            AxiS_Level      => AxiS_Level
        );



end rtl;
