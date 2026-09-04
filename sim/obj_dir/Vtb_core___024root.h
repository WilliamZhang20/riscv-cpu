// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vtb_core.h for the primary calling header

#ifndef VERILATED_VTB_CORE___024ROOT_H_
#define VERILATED_VTB_CORE___024ROOT_H_  // guard

#include "verilated.h"
#include "verilated_timing.h"


class Vtb_core__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vtb_core___024root final {
  public:

    // DESIGN SPECIFIC STATE
    CData/*0:0*/ tb_core__DOT__clk;
    CData/*0:0*/ tb_core__DOT__rst_n;
    CData/*0:0*/ tb_core__DOT__dmem_we;
    CData/*3:0*/ tb_core__DOT__dmem_be;
    CData/*0:0*/ tb_core__DOT__do_trace;
    CData/*2:0*/ tb_core__DOT__dut__DOT__state;
    CData/*0:0*/ tb_core__DOT__dut__DOT__take_q;
    CData/*0:0*/ tb_core__DOT__dut__DOT__illegal_q;
    CData/*0:0*/ tb_core__DOT__dut__DOT__pc_en;
    CData/*7:0*/ tb_core__DOT__dut__DOT__load_byte;
    CData/*0:0*/ tb_core__DOT__dut__DOT__u_rf__DOT__write_en;
    CData/*0:0*/ __VdlySet__tb_core__DOT__rst_n__v0;
    CData/*7:0*/ __VdlyVal__tb_core__DOT__mem__v0;
    CData/*0:0*/ __VdlySet__tb_core__DOT__mem__v0;
    CData/*7:0*/ __VdlyVal__tb_core__DOT__mem__v1;
    CData/*0:0*/ __VdlySet__tb_core__DOT__mem__v1;
    CData/*7:0*/ __VdlyVal__tb_core__DOT__mem__v2;
    CData/*0:0*/ __VdlySet__tb_core__DOT__mem__v2;
    CData/*7:0*/ __VdlyVal__tb_core__DOT__mem__v3;
    CData/*0:0*/ __VdlySet__tb_core__DOT__mem__v3;
    CData/*4:0*/ __VdlyDim0__tb_core__DOT__dut__DOT__u_rf__DOT__regs__v0;
    CData/*0:0*/ __VdlySet__tb_core__DOT__dut__DOT__u_rf__DOT__regs__v0;
    CData/*0:0*/ __VstlFirstIteration;
    CData/*0:0*/ __VstlPhaseResult;
    CData/*0:0*/ __Vtrigprevexpr___TOP__tb_core__DOT__clk__0;
    CData/*0:0*/ __Vtrigprevexpr___TOP__tb_core__DOT__rst_n__0;
    CData/*0:0*/ __VactPhaseResult;
    CData/*0:0*/ __VinactPhaseResult;
    CData/*0:0*/ __VnbaPhaseResult;
    SData/*15:0*/ tb_core__DOT__dut__DOT__load_half;
    SData/*9:0*/ __VdlyDim0__tb_core__DOT__mem__v0;
    SData/*9:0*/ __VdlyDim0__tb_core__DOT__mem__v1;
    SData/*9:0*/ __VdlyDim0__tb_core__DOT__mem__v2;
    SData/*9:0*/ __VdlyDim0__tb_core__DOT__mem__v3;
    IData/*31:0*/ tb_core__DOT__dmem_wdata;
    IData/*31:0*/ tb_core__DOT__cycles;
    IData/*31:0*/ tb_core__DOT__retired;
    IData/*31:0*/ tb_core__DOT__maxcyc;
    IData/*31:0*/ tb_core__DOT__dut__DOT__ir;
    IData/*31:0*/ tb_core__DOT__dut__DOT__rs1_q;
    IData/*31:0*/ tb_core__DOT__dut__DOT__rs2_q;
    IData/*31:0*/ tb_core__DOT__dut__DOT__imm_q;
    IData/*31:0*/ tb_core__DOT__dut__DOT__alu_q;
    IData/*31:0*/ tb_core__DOT__dut__DOT__target_q;
    IData/*31:0*/ tb_core__DOT__dut__DOT__load_q;
    IData/*31:0*/ tb_core__DOT__dut__DOT__pc;
    IData/*31:0*/ tb_core__DOT__dut__DOT__rf_wdata;
    IData/*31:0*/ tb_core__DOT__dut__DOT__alu_result;
    IData/*31:0*/ __VdfgRegularize_h6e95ff9d_0_1;
    IData/*19:0*/ __VdfgRegularize_h6e95ff9d_0_2;
    IData/*31:0*/ __VdlyVal__tb_core__DOT__dut__DOT__u_rf__DOT__regs__v0;
    IData/*31:0*/ __VactIterCount;
    IData/*31:0*/ __VinactIterCount;
    IData/*31:0*/ __Vi;
    QData/*38:0*/ tb_core__DOT__dut__DOT__d;
    VlUnpacked<IData/*31:0*/, 1024> tb_core__DOT__mem;
    VlUnpacked<IData/*31:0*/, 32> tb_core__DOT__dut__DOT__u_rf__DOT__regs;
    VlUnpacked<QData/*63:0*/, 1> __VstlTriggered;
    VlUnpacked<QData/*63:0*/, 1> __VactTriggered;
    VlUnpacked<QData/*63:0*/, 1> __VactTriggeredAcc;
    VlUnpacked<QData/*63:0*/, 1> __VnbaTriggered;
    std::string tb_core__DOT__prog;
    VlDelayScheduler __VdlySched;
    VlTriggerScheduler __VtrigSched_h5e18bfa5__0;

    // INTERNAL VARIABLES
    Vtb_core__Syms* vlSymsp;
    const char* vlNamep;

    // CONSTRUCTORS
    Vtb_core___024root(Vtb_core__Syms* symsp, const char* namep);
    ~Vtb_core___024root();
    VL_UNCOPYABLE(Vtb_core___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
