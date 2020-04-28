------------------------------------------------------------------------------
--	Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
--	Copyright (c) 2020 by Oliver Bründler, Switzerland
--	All rights reserved.
--	Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	
library std;
	use std.textio.all;

library work;
	use work.psi_tb_txt_util.all;
	use work.psi_tb_activity_pkg.all;
	use work.psi_tb_axi_pkg.all;
	use work.definitions_pkg.all;
	use work.psi_tb_compare_pkg.all;
	use work.psi_common_math_pkg.all;
	use work.psi_common_logic_pkg.all;

entity top_tb is
	generic (
		OutputType_g	: string 	:= "AXIMM"
	);
end entity top_tb;

architecture sim of top_tb is

	-------------------------------------------------------------------------
	-- AXI Definition
	-------------------------------------------------------------------------
	constant ID_WIDTH		: integer	:= 1;
	constant ADDR_WIDTH		: integer	:= 8;
	constant USER_WIDTH		: integer	:= 1;
	constant DATA_WIDTH		: integer	:= 32;
	constant BYTE_WIDTH		: integer	:= DATA_WIDTH/8;
	
	subtype ID_RANGE is natural range ID_WIDTH-1 downto 0;
	subtype ADDR_RANGE is natural range ADDR_WIDTH-1 downto 0;
	subtype USER_RANGE is natural range USER_WIDTH-1 downto 0;
	subtype DATA_RANGE is natural range DATA_WIDTH-1 downto 0;
	subtype BYTE_RANGE is natural range BYTE_WIDTH-1 downto 0;
	
	signal axi_ms : axi_ms_r (	arid(ID_RANGE), awid(ID_RANGE),
								araddr(ADDR_RANGE), awaddr(ADDR_RANGE),
								aruser(USER_RANGE), awuser(USER_RANGE), wuser(USER_RANGE),
								wdata(DATA_RANGE),
								wstrb(BYTE_RANGE));
	
	signal axi_sm : axi_sm_r (	rid(ID_RANGE), bid(ID_RANGE),
								ruser(USER_RANGE), buser(USER_RANGE),
								rdata(DATA_RANGE));
								
	signal axi_ms_m : axi_ms_r (	arid(ID_RANGE), awid(ID_RANGE),
									araddr(31 downto 0), awaddr(31 downto 0),
									aruser(USER_RANGE), awuser(USER_RANGE), wuser(USER_RANGE),
									wdata(31 downto 0),
									wstrb(3 downto 0));
	
	signal axi_sm_m : axi_sm_r (	rid(ID_RANGE), bid(ID_RANGE),
									ruser(USER_RANGE), buser(USER_RANGE),
									rdata(31 downto 0));


	-------------------------------------------------------------------------
	-- TB Defnitions
	-------------------------------------------------------------------------
	constant	ClockFrequencyAxi_c	: real		:= 125.0e6;							-- Use slow clocks to speed up simulation
	constant	ClockPeriodAxi_c	: time		:= (1 sec)/ClockFrequencyAxi_c;
	signal		TbRunning			: boolean	:= True;
	signal		StimCase			: integer	:= -1;
	signal 		RespCase			: integer	:= -1;

	
	-------------------------------------------------------------------------
	-- Interface Signals
	-------------------------------------------------------------------------
	signal aclk				: std_logic							:= '0';
	signal aresetn			: std_logic							:= '0';
	signal areset 			: std_logic							:= '1';
	signal Trig				: std_logic							:= '0';
	signal DoneIrq			: std_logic							:= '0';
	signal m_axis_tdata		: std_logic_vector(31 downto 0);
	signal m_axis_tvalid	: std_logic;
	signal m_axis_tready	: std_logic 						:= '0';
	signal m_axis_tlast		: std_logic;


	-- *** Procedures ***
	procedure CheckResultsAxiS(	start 					: in integer; 
								step 					: in integer;
								signal vld				: in std_logic;
								signal rdy				: out std_logic;
								signal last				: in std_logic;
								signal data				: in std_logic_vector;
								signal clk				: in std_logic) is
	begin
		rdy <= '1';
		for i in 0 to 13 loop
			wait until rising_edge(clk) and vld = '1';
			StdlvCompareInt (start+i*step, data, "Data");
			StdlCompare(choose(i=13,1,0), last, "Wrong Tlast");
		end loop;
		rdy <= '0';
	end procedure;
	
	procedure CheckResultsAxiMM(	start 					: in integer; 
									step 					: in integer;
									signal axi_ms			: out axi_ms_r;
									signal axi_sm			: in axi_sm_r;
									signal clk				: in std_logic) is
		variable x : integer;
	begin
		for i in 0 to 13 loop
			-- Wait until data available
			loop
				axi_single_read(RegIdx_Level_c*4, x, axi_ms, axi_sm, clk);
				if x > 0 then
					exit;
				end if;
			end loop;
				
			-- Check last
			axi_single_expect(RegIdx_RdLast_c*4, choose(i=13,1,0), axi_ms, axi_sm, clk, "Last");
			axi_single_expect(RegIdx_RdData_c*4, start+i*step, axi_ms, axi_sm, clk, "Data " & to_string(i));
		end loop;
	end procedure;
	
	procedure CheckResults(	start 					: in integer; 
							step 					: in integer;
							signal vld				: in std_logic;
							signal rdy				: out std_logic;
							signal last				: in std_logic;
							signal data				: in std_logic_vector;
							signal axi_ms			: out axi_ms_r;
							signal axi_sm			: in axi_sm_r;
							signal clk				: in std_logic) is
	begin
		if OutputType_g = "AXIS" then
			CheckResultsAxiS(start, step, vld, rdy, last, data, clk);
		else
			CheckResultsAxiMM(start, step, axi_ms, axi_sm, clk);
		end if;
	end procedure;
begin

	areset <= not aresetn;
	-------------------------------------------------------------------------
	-- DUT
	-------------------------------------------------------------------------
	i_dut : entity work.axi_mm_reader_wrp
		generic map (
			ClkFrequencyHz		=> integer(ClockFrequencyAxi_c),
			TimeoutUs_g			=> 10,
			MaxRegCount_g		=> 16,
			MinBuffers_g		=> 2,
			Output_g			=> OutputType_g,
			AxiSlaveAddrWidth_g => 8
		)
		port map (
			Clk					=> aclk,
			Rst					=> areset,
			Trig				=> Trig,
			DoneIrq				=> DoneIrq,
			s00_axi_arid		=> axi_ms.arid,
			s00_axi_araddr		=> axi_ms.araddr,
			s00_axi_arlen		=> axi_ms.arlen,
			s00_axi_arsize		=> axi_ms.arsize,
			s00_axi_arburst		=> axi_ms.arburst,
			s00_axi_arlock		=> axi_ms.arlock,
			s00_axi_arcache		=> axi_ms.arcache,
			s00_axi_arprot		=> axi_ms.arprot,
			s00_axi_arvalid		=> axi_ms.arvalid,
			s00_axi_arready		=> axi_sm.arready,
			s00_axi_rid			=> axi_sm.rid,
			s00_axi_rdata		=> axi_sm.rdata,
			s00_axi_rresp		=> axi_sm.rresp,
			s00_axi_rlast		=> axi_sm.rlast,
			s00_axi_rvalid		=> axi_sm.rvalid,
			s00_axi_rready		=> axi_ms.rready,
			s00_axi_awid		=> axi_ms.awid,
			s00_axi_awaddr		=> axi_ms.awaddr,
			s00_axi_awlen		=> axi_ms.awlen,
			s00_axi_awsize		=> axi_ms.awsize,
			s00_axi_awburst		=> axi_ms.awburst,
			s00_axi_awlock		=> axi_ms.awlock,
			s00_axi_awcache		=> axi_ms.awcache,
			s00_axi_awprot		=> axi_ms.awprot,
			s00_axi_awvalid		=> axi_ms.awvalid,
			s00_axi_awready		=> axi_sm.awready,
			s00_axi_wdata		=> axi_ms.wdata,
			s00_axi_wstrb		=> axi_ms.wstrb,
			s00_axi_wlast		=> axi_ms.wlast,
			s00_axi_wvalid		=> axi_ms.wvalid,
			s00_axi_wready		=> axi_sm.wready,
			s00_axi_bid			=> axi_sm.bid,
			s00_axi_bresp		=> axi_sm.bresp,
			s00_axi_bvalid		=> axi_sm.bvalid,
			s00_axi_bready		=> axi_ms.bready,

			-----------------------------------------------------------------------------
			-- Axi Master Bus Interface
			-----------------------------------------------------------------------------
			m00_axi_araddr		=> axi_ms_m.araddr,
			m00_axi_arlen		=> axi_ms_m.arlen,
			m00_axi_arsize		=> axi_ms_m.arsize,
			m00_axi_arburst		=> axi_ms_m.arburst,
			m00_axi_arlock		=> axi_ms_m.arlock,
			m00_axi_arcache		=> axi_ms_m.arcache,
			m00_axi_arprot		=> axi_ms_m.arprot,
			m00_axi_arvalid		=> axi_ms_m.arvalid,
			m00_axi_arready		=> axi_sm_m.arready,
			m00_axi_rdata		=> axi_sm_m.rdata,
			m00_axi_rresp		=> axi_sm_m.rresp,
			m00_axi_rlast		=> axi_sm_m.rlast,
			m00_axi_rvalid		=> axi_sm_m.rvalid,
			m00_axi_rready		=> axi_ms_m.rready,

			-----------------------------------------------------------------------------
			-- Stream Output
			-----------------------------------------------------------------------------
			m_axis_tdata		=> m_axis_tdata,
			m_axis_tvalid		=> m_axis_tvalid,
			m_axis_tready		=> m_axis_tready,
			m_axis_tlast		=> m_axis_tlast
		);

	
	-------------------------------------------------------------------------
	-- Clock
	-------------------------------------------------------------------------
	p_aclk : process
	begin
		aclk <= '0';
		while TbRunning loop
			wait for 0.5*ClockPeriodAxi_c;
			aclk <= '1';
			wait for 0.5*ClockPeriodAxi_c;
			aclk <= '0';
		end loop;
		wait;
	end process;
	
	-------------------------------------------------------------------------
	-- TB Control
	-------------------------------------------------------------------------
	p_control : process
		variable x	: integer;
	begin
		-- Reset
		aresetn <= '0';
		wait for 1 us;
		wait until rising_edge(aclk);
		aresetn <= '1';
		wait for 1 us;
		wait until rising_edge(aclk);
		
		-- *** Setup for reading 14 registers ***		
		axi_single_write(RegIdx_RegCnt_c*4, 14, axi_ms, axi_sm, aclk);
		for i in 0 to 13 loop
			axi_single_write((MemOffs_c+i)*4, 16#00AB0000#+16*i, axi_ms, axi_sm, aclk);
		end loop;		
		axi_single_write(RegIdx_Ctrl_c*4, 1, axi_ms, axi_sm, aclk);
		
		-- *** Trigger Single Read ***
		print(">> Trigger Single Read");
		StimCase <= 1;
		ClockedWaitTime(100 ns, aclk);
		PulseSig(Trig, aclk);
		CheckResults(0, 1, m_axis_tvalid, m_axis_tready, m_axis_tlast, m_axis_tdata, axi_ms, axi_sm, aclk);
		wait until rising_edge(aclk) and RespCase = 1;

		-- *** Buffered Double Read ***
		print(">> Buffered Double Read");
		StimCase <= 2;
		axi_single_expect(RegIdx_Level_c*4, 0, axi_ms, axi_sm, aclk);
		ClockedWaitTime(100 ns, aclk);
		PulseSig(Trig, aclk);
		ClockedWaitTime(1 us, aclk);
		PulseSig(Trig, aclk);
		ClockedWaitTime(1 us, aclk);
		axi_single_expect(RegIdx_Level_c*4, 14*2, axi_ms, axi_sm, aclk);
		CheckResults(0, 1, m_axis_tvalid, m_axis_tready, m_axis_tlast, m_axis_tdata, axi_ms, axi_sm, aclk);
		CheckResults(32, 1, m_axis_tvalid, m_axis_tready, m_axis_tlast, m_axis_tdata, axi_ms, axi_sm, aclk);
		wait until rising_edge(aclk) and RespCase = 2;
		
		-- *** Timeout ***
		print(">> Timeout");
		StimCase <= 3;
		if OutputType_g = "AXIS" then
			CheckNoActivity(m_axis_tvalid, 8 us, 0, "Timeout interrupted");		
			WaitForValueStdl(m_axis_tvalid, '1', 3 us, "Timout not occurred");
		else
			ClockedWaitTime(5 us, aclk);
			axi_single_expect(RegIdx_Level_c*4, 0, axi_ms, axi_sm, aclk);
			-- Wait until data available
			loop
				axi_single_read(RegIdx_Level_c*4, x, axi_ms, axi_sm, aclk);
				if x > 0 then
					exit;
				end if;
			end loop;
		end if;
		CheckResults(0, 1, m_axis_tvalid, m_axis_tready, m_axis_tlast, m_axis_tdata, axi_ms, axi_sm, aclk);
		wait until rising_edge(aclk) and RespCase = 3;
		
		-- *** Test Disabled ***
		print(">> Disabled");
		StimCase <= 4;
		axi_single_write(RegIdx_Ctrl_c*4, 0, axi_ms, axi_sm, aclk);
		ClockedWaitTime(100 ns, aclk);
		PulseSig(Trig, aclk);
		CheckNoActivity(m_axis_tvalid, 12 us, 0, "Timeout interrupted");
		axi_single_write(RegIdx_Ctrl_c*4, 1, axi_ms, axi_sm, aclk);
		CheckNoActivity(m_axis_tvalid, 2 us, 0, "Timeout interrupted");
		wait until rising_edge(aclk) and RespCase = 4;
		
		-- *** Back Pressure ***
		print(">> Back Pressure");
		StimCase <= 5;
		ClockedWaitTime(100 ns, aclk);
		-- Trigger too often, creating back pressure
		for i in 0 to 5 loop
			PulseSig(Trig, aclk);
			ClockedWaitTime(1 us, aclk);
		end loop;
		-- Check one frame and start next
		ClockedWaitTime(1 us, aclk);
		CheckResults(0, 1, m_axis_tvalid, m_axis_tready, m_axis_tlast, m_axis_tdata, axi_ms, axi_sm, aclk);
		PulseSig(Trig, aclk);
		ClockedWaitTime(1 us, aclk);
		axi_single_write(RegIdx_Ctrl_c*4, 0, axi_ms, axi_sm, aclk);
		-- Check remainig frames (all are complete)
		if OutputType_g = "AXIS" then
			while m_axis_tvalid = '1' loop
				CheckResults(0, 1, m_axis_tvalid, m_axis_tready, m_axis_tlast, m_axis_tdata, axi_ms, axi_sm, aclk);
				ClockedWaitTime(20 ns, aclk);
			end loop;
		else
			loop
				axi_single_read(RegIdx_Level_c*4, x, axi_ms, axi_sm, aclk);
				if x = 0 then
					exit;
				end if;
				CheckResults(0, 1, m_axis_tvalid, m_axis_tready, m_axis_tlast, m_axis_tdata, axi_ms, axi_sm, aclk);
			end loop;
		end if;
		axi_single_write(RegIdx_Ctrl_c*4, 1, axi_ms, axi_sm, aclk);
		wait until rising_edge(aclk) and RespCase = 5;
		
		-- *** Single Reg Read Four Times ***
		print(">> Single Reg Read Four Time");
		StimCase <= 6;
		axi_single_write(RegIdx_RegCnt_c*4, 1, axi_ms, axi_sm, aclk);
		for i in 0 to 3 loop
			ClockedWaitTime(100 ns, aclk);
			PulseSig(Trig, aclk);
		end loop;
		ClockedWaitTime(1 us, aclk);
		if OutputType_g = "AXIS" then
			m_axis_tready <= '1';
			for i in 0 to 3 loop	
				wait until m_axis_tvalid = '1' and rising_edge(aclk);		
				StdlvCompareInt (i, m_axis_tdata, "Data");
				StdlCompare(1, m_axis_tlast, "Wrong Tlast");
			end loop;
			m_axis_tready <= '0';
		else
			for i in 0 to 3 loop	
				-- Wait until data available
				loop
					axi_single_read(RegIdx_Level_c*4, x, axi_ms, axi_sm, aclk);
					if x > 0 then
						exit;
					end if;
				end loop;
				-- Check
				axi_single_expect(RegIdx_RdLast_c*4, 1, axi_ms, axi_sm, aclk, "Last");
				axi_single_expect(RegIdx_RdData_c*4, i, axi_ms, axi_sm, aclk, "Data " & to_string(i));
			end loop;
		end if;			
		wait until rising_edge(aclk) and RespCase = 6;

		
		-- TB done
		wait for 1 us;
		TbRunning <= false;
		wait;
	end process;
	
	-------------------------------------------------------------------------
	-- SPI Emulation
	-------------------------------------------------------------------------
	p_spi : process
		constant TransWidth_c	: integer := 8;
		constant SpiCPHA_c		: integer := 0;
		constant SpiCPOL_c		: integer := 0;
		constant LsbFirst_c		: boolean := false;
		variable ShiftRegRx_v	: std_logic_vector(TransWidth_c-1 downto 0);
		variable ShiftRegTx_v	: std_logic_vector(TransWidth_c-1 downto 0);
		variable ExpLatch_v		: std_logic_vector(TransWidth_c-1 downto 0);
	begin	
		wait until aresetn = '1';
		wait until rising_edge(aclk);
		
		-- *** Trigger Single Read ***
		wait until rising_edge(aclk) and StimCase = 1;
		for i in 0 to 13 loop
			axi_expect_ar(16#00AB0000#+16*i, AxSIZE_4_c, 0, xBURST_INCR_c, axi_ms_m, axi_sm_m, aclk);
			axi_apply_rresp_single(std_logic_vector(to_unsigned(i, 32)), xRESP_OKAY_c, axi_ms_m, axi_sm_m, aclk);
		end loop;
		RespCase <= 1;
		
		-- *** Buffered Double Read ***
		wait until rising_edge(aclk) and StimCase = 2;
		for x in 0 to 1 loop
			for i in 0 to 13 loop
				axi_expect_ar(16#00AB0000#+16*i, AxSIZE_4_c, 0, xBURST_INCR_c, axi_ms_m, axi_sm_m, aclk);
				axi_apply_rresp_single(std_logic_vector(to_unsigned(i+x*32, 32)), xRESP_OKAY_c, axi_ms_m, axi_sm_m, aclk);
			end loop;
		end loop;
		RespCase <= 2;
		
		-- *** Timeout ***
		wait until rising_edge(aclk) and StimCase = 3;
		for i in 0 to 13 loop
			axi_expect_ar(16#00AB0000#+16*i, AxSIZE_4_c, 0, xBURST_INCR_c, axi_ms_m, axi_sm_m, aclk);
			axi_apply_rresp_single(std_logic_vector(to_unsigned(i, 32)), xRESP_OKAY_c, axi_ms_m, axi_sm_m, aclk);
		end loop;
		RespCase <= 3;
		
		-- *** Test Disabled ***
		wait until rising_edge(aclk) and StimCase = 4;
		RespCase <= 4;
		
		-- *** Test Back Pressure ***
		wait until rising_edge(aclk) and StimCase = 5;
		loop
			wait until axi_ms_m.arvalid = '1' and rising_edge(aclk) for 10 us;
			if axi_ms_m.arvalid = '0' then
				exit;
			end if;
			for i in 0 to 13 loop
				axi_expect_ar(16#00AB0000#+16*i, AxSIZE_4_c, 0, xBURST_INCR_c, axi_ms_m, axi_sm_m, aclk);
				axi_apply_rresp_single(std_logic_vector(to_unsigned(i, 32)), xRESP_OKAY_c, axi_ms_m, axi_sm_m, aclk);
			end loop;
		end loop;
		RespCase <= 5;
		
		-- *** Single Reg Read Four Times ***
		wait until rising_edge(aclk) and StimCase = 6;
		for i in 0 to 3 loop
			axi_expect_ar(16#00AB0000#, AxSIZE_4_c, 0, xBURST_INCR_c, axi_ms_m, axi_sm_m, aclk);
			axi_apply_rresp_single(std_logic_vector(to_unsigned(i, 32)), xRESP_OKAY_c, axi_ms_m, axi_sm_m, aclk);
		end loop;
		RespCase <= 6;

		wait;
		
	end process;
	
	

end sim;
