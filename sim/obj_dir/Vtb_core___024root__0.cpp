// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_core.h for the primary calling header

#include "Vtb_core__pch.h"

VlCoroutine Vtb_core___024root___eval_initial__TOP__Vtiming__0(Vtb_core___024root* vlSelf);
VlCoroutine Vtb_core___024root___eval_initial__TOP__Vtiming__1(Vtb_core___024root* vlSelf);

void Vtb_core___024root___eval_initial(Vtb_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_core___024root___eval_initial\n"); );
    Vtb_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    {
        // Inlined CFunc: _eval_initial__TOP
        vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs[0U] = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs[1U] = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs[2U] = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs[3U] = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs[4U] = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs[5U] = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs[6U] = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs[7U] = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs[8U] = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs[9U] = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs[10U] = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs[11U] = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs[12U] = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs[13U] = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs[14U] = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs[15U] = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs[16U] = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs[17U] = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs[18U] = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs[19U] = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs[20U] = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs[21U] = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs[22U] = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs[23U] = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs[24U] = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs[25U] = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs[26U] = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs[27U] = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs[28U] = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs[29U] = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs[30U] = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs[31U] = 0U;
    }
    Vtb_core___024root___eval_initial__TOP__Vtiming__0(vlSelf);
    Vtb_core___024root___eval_initial__TOP__Vtiming__1(vlSelf);
}

VlCoroutine Vtb_core___024root___eval_initial__TOP__Vtiming__0(Vtb_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_core___024root___eval_initial__TOP__Vtiming__0\n"); );
    Vtb_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.tb_core__DOT__clk = 0U;
    while (true) {
        co_await vlSelfRef.__VdlySched.delay(0x0000000000001388ULL, 
                                             nullptr, 
                                             "tb-core.sv", 
                                             33);
        vlSelfRef.tb_core__DOT__clk = (1U & (~ (IData)(vlSelfRef.tb_core__DOT__clk)));
    }
    co_return;
}

void Vtb_core___024root____VbeforeTrig_h5e18bfa5__0(Vtb_core___024root* vlSelf, const char* __VeventDescription);

VlCoroutine Vtb_core___024root___eval_initial__TOP__Vtiming__1(Vtb_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_core___024root___eval_initial__TOP__Vtiming__1\n"); );
    Vtb_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ tb_core__DOT____VlemExpr_1;
    IData/*31:0*/ tb_core__DOT____VlemExpr_0;
    IData/*31:0*/ tb_core__DOT__result;
    tb_core__DOT__result = 0;
    IData/*31:0*/ tb_core__DOT__unnamedblk2__DOT__i;
    tb_core__DOT__unnamedblk2__DOT__i = 0;
    IData/*31:0*/ tb_core__DOT__unnamedblk1_1__DOT____Vrepeat0;
    tb_core__DOT__unnamedblk1_1__DOT____Vrepeat0 = 0;
    // Body
    tb_core__DOT____VlemExpr_0 = VL_VALUEPLUSARGS_INN(64, "PROG=%s"s, 
                                                      vlSelfRef.tb_core__DOT__prog);
    if ((! tb_core__DOT____VlemExpr_0)) {
        vlSelfRef.tb_core__DOT__prog = "test-basic.hex"s;
    }
    tb_core__DOT____VlemExpr_1 = VL_VALUEPLUSARGS_INI(32, "MAXCYC=%d"s, 
                                                      vlSelfRef.tb_core__DOT__maxcyc);
    if ((! tb_core__DOT____VlemExpr_1)) {
        vlSelfRef.tb_core__DOT__maxcyc = 0x000186a0U;
    }
    vlSelfRef.tb_core__DOT__do_trace = (1U & VL_TESTPLUSARGS_I("TRACE"s));
    vlSelfRef.tb_core__DOT__rst_n = 0U;
    tb_core__DOT__unnamedblk2__DOT__i = 0U;
    while (VL_GTES_III(32, 0x000003ffU, tb_core__DOT__unnamedblk2__DOT__i)) {
        vlSelfRef.tb_core__DOT__mem[(0x000003ffU & tb_core__DOT__unnamedblk2__DOT__i)] = 0U;
        tb_core__DOT__unnamedblk2__DOT__i = ((IData)(1U) 
                                             + tb_core__DOT__unnamedblk2__DOT__i);
    }
    VL_READMEM_N(true, 32, 1024, 0, vlSelfRef.tb_core__DOT__prog
                 ,  &(vlSelfRef.tb_core__DOT__mem), 0
                 , ~0ULL);
    VL_WRITEF_NX("tb_core: loaded %s\n",1, 'S',&(vlSelfRef.tb_core__DOT__prog));
    tb_core__DOT__unnamedblk1_1__DOT____Vrepeat0 = 4U;
    while (VL_LTS_III(32, 0U, tb_core__DOT__unnamedblk1_1__DOT____Vrepeat0)) {
        Vtb_core___024root____VbeforeTrig_h5e18bfa5__0(vlSelf, 
                                                       "@(posedge tb_core.clk)");
        co_await vlSelfRef.__VtrigSched_h5e18bfa5__0.trigger(0U, 
                                                             nullptr, 
                                                             "@(posedge tb_core.clk)", 
                                                             "tb-core.sv", 
                                                             144);
        tb_core__DOT__unnamedblk1_1__DOT____Vrepeat0 
            = (tb_core__DOT__unnamedblk1_1__DOT____Vrepeat0 
               - (IData)(1U));
    }
    vlSelfRef.__VdlySet__tb_core__DOT__rst_n__v0 = 1U;
    while (((5U != (IData)(vlSelfRef.tb_core__DOT__dut__DOT__state)) 
            & (vlSelfRef.tb_core__DOT__cycles < vlSelfRef.tb_core__DOT__maxcyc))) {
        Vtb_core___024root____VbeforeTrig_h5e18bfa5__0(vlSelf, 
                                                       "@(posedge tb_core.clk)");
        co_await vlSelfRef.__VtrigSched_h5e18bfa5__0.trigger(0U, 
                                                             nullptr, 
                                                             "@(posedge tb_core.clk)", 
                                                             "tb-core.sv", 
                                                             147);
    }
    if (VL_UNLIKELY(((5U != (IData)(vlSelfRef.tb_core__DOT__dut__DOT__state))))) {
        VL_WRITEF_NX("[%0t] %%Fatal: tb-core.sv:150: Assertion failed in %m: FAIL: timeout after %0d cycles (pc=%08h)\n",5, 'M',vlSymsp->name(),"tb_core", 'T',-9
                     , '#',64,VL_TIME_UNITED_Q(1000)
                     , '#',32,vlSelfRef.tb_core__DOT__cycles
                     , '#',32,vlSelfRef.tb_core__DOT__dut__DOT__pc);
        VL_STOP_MT("tb-core.sv", 150, "", false);
    }
    if (VL_UNLIKELY((((IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                               >> 0x00000026U)) & (5U 
                                                   == (IData)(vlSelfRef.tb_core__DOT__dut__DOT__state)))))) {
        VL_WRITEF_NX("[%0t] %%Fatal: tb-core.sv:153: Assertion failed in %m: FAIL: illegal instruction %08h at pc=%08h\n",5, 'M',vlSymsp->name(),"tb_core", 'T',-9
                     , '#',64,VL_TIME_UNITED_Q(1000)
                     , '#',32,vlSelfRef.tb_core__DOT__dut__DOT__ir
                     , '#',32,vlSelfRef.tb_core__DOT__dut__DOT__pc);
        VL_STOP_MT("tb-core.sv", 153, "", false);
    }
    tb_core__DOT__result = vlSelfRef.tb_core__DOT__mem[320U];
    VL_WRITEF_NX("tb_core: halted after %0d cycles, %0d instructions retired\ntb_core: result word @00000500 = %08h\n",3
                 , '#',32,vlSelfRef.tb_core__DOT__cycles
                 , '#',32,vlSelfRef.tb_core__DOT__retired
                 , '#',32,tb_core__DOT__result);
    if (VL_UNLIKELY(((0x600dc0deU == tb_core__DOT__result)))) {
        VL_WRITEF_NX("tb_core: PASS\n",0);
        VL_FINISH_MT("tb-core.sv", 164, "");
    } else if ((0xbaadc0deU == tb_core__DOT__result)) {
        VL_WRITEF_NX("[%0t] %%Fatal: tb-core.sv:166: Assertion failed in %m: FAIL: program reached its fail path (last pc=%08h)\n",4, 'M',vlSymsp->name(),"tb_core", 'T',-9
                     , '#',64,VL_TIME_UNITED_Q(1000)
                     , '#',32,vlSelfRef.tb_core__DOT__dut__DOT__pc);
        VL_STOP_MT("tb-core.sv", 166, "", false);
    } else {
        VL_WRITEF_NX("[%0t] %%Fatal: tb-core.sv:168: Assertion failed in %m: FAIL: no result magic written (got %08h)\n",4, 'M',vlSymsp->name(),"tb_core", 'T',-9
                     , '#',64,VL_TIME_UNITED_Q(1000)
                     , '#',32,tb_core__DOT__result);
        VL_STOP_MT("tb-core.sv", 168, "", false);
    }
    co_return;
}

bool Vtb_core___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_core___024root___trigger_anySet__act\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        if (in[n]) {
            return (1U);
        }
        n = ((IData)(1U) + n);
    } while ((1U > n));
    return (0U);
}

void Vtb_core___024root___nba_sequent__TOP__0(Vtb_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_core___024root___nba_sequent__TOP__0\n"); );
    Vtb_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VdlySet__tb_core__DOT__dut__DOT__u_rf__DOT__regs__v0 = 0U;
    if ((((IData)(vlSelfRef.tb_core__DOT__rst_n) & 
          ((IData)(vlSelfRef.tb_core__DOT__dmem_we) 
           | (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                      >> 0x00000014U)))) & (3U == (IData)(vlSelfRef.tb_core__DOT__dut__DOT__state)))) {
        if (VL_UNLIKELY(((0x00001000U <= vlSelfRef.tb_core__DOT__dut__DOT__alu_q)))) {
            VL_WRITEF_NX("[%0t] %%Fatal: tb-core.sv:113: Assertion failed in %m: FAIL: data access out of range: %08h\n",4, 'M',vlSymsp->name(),"tb_core", 'T',-9
                         , '#',64,VL_TIME_UNITED_Q(1000)
                         , '#',32,vlSelfRef.tb_core__DOT__dut__DOT__alu_q);
            VL_STOP_MT("tb-core.sv", 113, "", false);
        }
        if ((2U == (7U & (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                                  >> 0x00000015U))))) {
            if (VL_UNLIKELY(((0U != (3U & vlSelfRef.tb_core__DOT__dut__DOT__alu_q))))) {
                VL_WRITEF_NX("[%0t] %%Fatal: tb-core.sv:117: Assertion failed in %m: FAIL: misaligned word access: %08h\n",4, 'M',vlSymsp->name(),"tb_core", 'T',-9
                             , '#',64,VL_TIME_UNITED_Q(1000)
                             , '#',32,vlSelfRef.tb_core__DOT__dut__DOT__alu_q);
                VL_STOP_MT("tb-core.sv", 117, "", false);
            }
        } else if (((1U == (7U & (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                                          >> 0x00000015U)))) 
                    || (5U == (7U & (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                                             >> 0x00000015U)))))) {
            if (VL_UNLIKELY(((1U & vlSelfRef.tb_core__DOT__dut__DOT__alu_q)))) {
                VL_WRITEF_NX("[%0t] %%Fatal: tb-core.sv:120: Assertion failed in %m: FAIL: misaligned halfword access: %08h\n",4, 'M',vlSymsp->name(),"tb_core", 'T',-9
                             , '#',64,VL_TIME_UNITED_Q(1000)
                             , '#',32,vlSelfRef.tb_core__DOT__dut__DOT__alu_q);
                VL_STOP_MT("tb-core.sv", 120, "", false);
            }
        }
    }
    vlSelfRef.__VdlySet__tb_core__DOT__mem__v0 = 0U;
    vlSelfRef.__VdlySet__tb_core__DOT__mem__v1 = 0U;
    vlSelfRef.__VdlySet__tb_core__DOT__mem__v2 = 0U;
    vlSelfRef.__VdlySet__tb_core__DOT__mem__v3 = 0U;
    if (vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__write_en) {
        vlSelfRef.__VdlyVal__tb_core__DOT__dut__DOT__u_rf__DOT__regs__v0 
            = vlSelfRef.tb_core__DOT__dut__DOT__rf_wdata;
        vlSelfRef.__VdlyDim0__tb_core__DOT__dut__DOT__u_rf__DOT__regs__v0 
            = (0x0000001fU & (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                                      >> 0x0000000aU)));
        vlSelfRef.__VdlySet__tb_core__DOT__dut__DOT__u_rf__DOT__regs__v0 = 1U;
    }
    if (vlSelfRef.tb_core__DOT__rst_n) {
        vlSelfRef.tb_core__DOT__cycles = ((IData)(1U) 
                                          + vlSelfRef.tb_core__DOT__cycles);
        if ((4U == (IData)(vlSelfRef.tb_core__DOT__dut__DOT__state))) {
            vlSelfRef.tb_core__DOT__retired = ((IData)(1U) 
                                               + vlSelfRef.tb_core__DOT__retired);
            if (VL_UNLIKELY((vlSelfRef.tb_core__DOT__do_trace))) {
                VL_WRITEF_NX("  [%0t] pc=%08h instr=%08h\n",4, 'T',-9
                             , '#',64,VL_TIME_UNITED_Q(1000)
                             , '#',32,vlSelfRef.tb_core__DOT__dut__DOT__pc
                             , '#',32,vlSelfRef.tb_core__DOT__dut__DOT__ir);
            }
        }
    } else {
        vlSelfRef.tb_core__DOT__cycles = 0U;
        vlSelfRef.tb_core__DOT__retired = 0U;
    }
    if (vlSelfRef.tb_core__DOT__dmem_we) {
        if ((1U & (IData)(vlSelfRef.tb_core__DOT__dmem_be))) {
            vlSelfRef.__VdlyVal__tb_core__DOT__mem__v0 
                = (0x000000ffU & vlSelfRef.tb_core__DOT__dmem_wdata);
            vlSelfRef.__VdlyDim0__tb_core__DOT__mem__v0 
                = (0x000003ffU & (vlSelfRef.tb_core__DOT__dut__DOT__alu_q 
                                  >> 2U));
            vlSelfRef.__VdlySet__tb_core__DOT__mem__v0 = 1U;
        }
        if ((2U & (IData)(vlSelfRef.tb_core__DOT__dmem_be))) {
            vlSelfRef.__VdlyVal__tb_core__DOT__mem__v1 
                = (0x000000ffU & (vlSelfRef.tb_core__DOT__dmem_wdata 
                                  >> 8U));
            vlSelfRef.__VdlyDim0__tb_core__DOT__mem__v1 
                = (0x000003ffU & (vlSelfRef.tb_core__DOT__dut__DOT__alu_q 
                                  >> 2U));
            vlSelfRef.__VdlySet__tb_core__DOT__mem__v1 = 1U;
        }
        if ((4U & (IData)(vlSelfRef.tb_core__DOT__dmem_be))) {
            vlSelfRef.__VdlyVal__tb_core__DOT__mem__v2 
                = (0x000000ffU & (vlSelfRef.tb_core__DOT__dmem_wdata 
                                  >> 0x10U));
            vlSelfRef.__VdlyDim0__tb_core__DOT__mem__v2 
                = (0x000003ffU & (vlSelfRef.tb_core__DOT__dut__DOT__alu_q 
                                  >> 2U));
            vlSelfRef.__VdlySet__tb_core__DOT__mem__v2 = 1U;
        }
        if ((8U & (IData)(vlSelfRef.tb_core__DOT__dmem_be))) {
            vlSelfRef.__VdlyVal__tb_core__DOT__mem__v3 
                = (vlSelfRef.tb_core__DOT__dmem_wdata 
                   >> 0x18U);
            vlSelfRef.__VdlyDim0__tb_core__DOT__mem__v3 
                = (0x000003ffU & (vlSelfRef.tb_core__DOT__dut__DOT__alu_q 
                                  >> 2U));
            vlSelfRef.__VdlySet__tb_core__DOT__mem__v3 = 1U;
        }
    }
}

void Vtb_core___024root___nba_sequent__TOP__1(Vtb_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_core___024root___nba_sequent__TOP__1\n"); );
    Vtb_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ tb_core__DOT__dut__DOT__alu_a;
    tb_core__DOT__dut__DOT__alu_a = 0;
    IData/*31:0*/ tb_core__DOT__dut__DOT__alu_b;
    tb_core__DOT__dut__DOT__alu_b = 0;
    CData/*0:0*/ tb_core__DOT__dut__DOT__u_dec__DOT__funct7_ok;
    tb_core__DOT__dut__DOT__u_dec__DOT__funct7_ok = 0;
    CData/*0:0*/ tb_core__DOT__dut__DOT__u_dec__DOT__alt_legal_reg;
    tb_core__DOT__dut__DOT__u_dec__DOT__alt_legal_reg = 0;
    CData/*2:0*/ __Vdly__tb_core__DOT__dut__DOT__state;
    __Vdly__tb_core__DOT__dut__DOT__state = 0;
    IData/*31:0*/ __Vdly__tb_core__DOT__dut__DOT__pc;
    __Vdly__tb_core__DOT__dut__DOT__pc = 0;
    // Body
    __Vdly__tb_core__DOT__dut__DOT__state = vlSelfRef.tb_core__DOT__dut__DOT__state;
    __Vdly__tb_core__DOT__dut__DOT__pc = vlSelfRef.tb_core__DOT__dut__DOT__pc;
    if (vlSelfRef.tb_core__DOT__rst_n) {
        __Vdly__tb_core__DOT__dut__DOT__state = ((4U 
                                                  & (IData)(vlSelfRef.tb_core__DOT__dut__DOT__state))
                                                  ? 
                                                 ((2U 
                                                   & (IData)(vlSelfRef.tb_core__DOT__dut__DOT__state))
                                                   ? 5U
                                                   : 
                                                  (5U 
                                                   & (- (IData)(
                                                                (1U 
                                                                 & (IData)(vlSelfRef.tb_core__DOT__dut__DOT__state))))))
                                                  : 
                                                 ((2U 
                                                   & (IData)(vlSelfRef.tb_core__DOT__dut__DOT__state))
                                                   ? 
                                                  ((1U 
                                                    & (IData)(vlSelfRef.tb_core__DOT__dut__DOT__state))
                                                    ? 4U
                                                    : 3U)
                                                   : 
                                                  ((1U 
                                                    & (IData)(vlSelfRef.tb_core__DOT__dut__DOT__state))
                                                    ? 
                                                   ((IData)(
                                                            (0ULL 
                                                             != 
                                                             (0x0000004000008000ULL 
                                                              & vlSelfRef.tb_core__DOT__dut__DOT__d)))
                                                     ? 5U
                                                     : 2U)
                                                    : 1U)));
        if (vlSelfRef.tb_core__DOT__dut__DOT__pc_en) {
            __Vdly__tb_core__DOT__dut__DOT__pc = ((IData)(vlSelfRef.tb_core__DOT__dut__DOT__take_q)
                                                   ? vlSelfRef.tb_core__DOT__dut__DOT__target_q
                                                   : vlSelfRef.__VdfgRegularize_h6e95ff9d_0_1);
        }
        if ((3U == (IData)(vlSelfRef.tb_core__DOT__dut__DOT__state))) {
            vlSelfRef.tb_core__DOT__dut__DOT__load_q 
                = ((1U & (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                                  >> 0x00000017U)))
                    ? ((1U & (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                                      >> 0x00000016U)))
                        ? vlSelfRef.tb_core__DOT__mem
                       [(0x000003ffU & (vlSelfRef.tb_core__DOT__dut__DOT__alu_q 
                                        >> 2U))] : 
                       ((1U & (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                                       >> 0x00000015U)))
                         ? (IData)(vlSelfRef.tb_core__DOT__dut__DOT__load_half)
                         : (IData)(vlSelfRef.tb_core__DOT__dut__DOT__load_byte)))
                    : ((1U & (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                                      >> 0x00000016U)))
                        ? vlSelfRef.tb_core__DOT__mem
                       [(0x000003ffU & (vlSelfRef.tb_core__DOT__dut__DOT__alu_q 
                                        >> 2U))] : 
                       ((1U & (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                                       >> 0x00000015U)))
                         ? (((- (IData)((1U & ((IData)(vlSelfRef.tb_core__DOT__dut__DOT__load_half) 
                                               >> 0x0000000fU)))) 
                             << 0x00000010U) | (IData)(vlSelfRef.tb_core__DOT__dut__DOT__load_half))
                         : (((- (IData)((1U & ((IData)(vlSelfRef.tb_core__DOT__dut__DOT__load_byte) 
                                               >> 7U)))) 
                             << 8U) | (IData)(vlSelfRef.tb_core__DOT__dut__DOT__load_byte)))));
        }
        if ((2U == (IData)(vlSelfRef.tb_core__DOT__dut__DOT__state))) {
            vlSelfRef.tb_core__DOT__dut__DOT__alu_q 
                = vlSelfRef.tb_core__DOT__dut__DOT__alu_result;
            vlSelfRef.tb_core__DOT__dut__DOT__take_q 
                = (1U & ((1U & (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                                        >> 0x0000001bU)))
                          ? ((1U & (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                                            >> 0x0000001aU)))
                              ? ((1U & (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                                                >> 0x00000019U)))
                                  ? ((1U & (IData)(
                                                   (vlSelfRef.tb_core__DOT__dut__DOT__d 
                                                    >> 0x00000018U)))
                                      ? (vlSelfRef.tb_core__DOT__dut__DOT__rs1_q 
                                         >= vlSelfRef.tb_core__DOT__dut__DOT__rs2_q)
                                      : (vlSelfRef.tb_core__DOT__dut__DOT__rs1_q 
                                         < vlSelfRef.tb_core__DOT__dut__DOT__rs2_q))
                                  : ((1U & (IData)(
                                                   (vlSelfRef.tb_core__DOT__dut__DOT__d 
                                                    >> 0x00000018U)))
                                      ? VL_GTES_III(32, vlSelfRef.tb_core__DOT__dut__DOT__rs1_q, vlSelfRef.tb_core__DOT__dut__DOT__rs2_q)
                                      : VL_LTS_III(32, vlSelfRef.tb_core__DOT__dut__DOT__rs1_q, vlSelfRef.tb_core__DOT__dut__DOT__rs2_q)))
                              : ((~ (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                                             >> 0x00000019U))) 
                                 & ((1U & (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                                                   >> 0x00000018U)))
                                     ? (vlSelfRef.tb_core__DOT__dut__DOT__rs1_q 
                                        != vlSelfRef.tb_core__DOT__dut__DOT__rs2_q)
                                     : (vlSelfRef.tb_core__DOT__dut__DOT__rs1_q 
                                        == vlSelfRef.tb_core__DOT__dut__DOT__rs2_q))))
                          : ((~ (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                                         >> 0x0000001aU))) 
                             & ((1U & (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                                               >> 0x00000019U)))
                                 ? (~ (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                                               >> 0x00000018U)))
                                 : (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                                            >> 0x00000018U))))));
            vlSelfRef.tb_core__DOT__dut__DOT__target_q 
                = ((2U == (0x0000000fU & (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                                                  >> 0x00000018U))))
                    ? (0xfffffffeU & vlSelfRef.tb_core__DOT__dut__DOT__alu_result)
                    : vlSelfRef.tb_core__DOT__dut__DOT__alu_result);
        }
        if ((1U == (IData)(vlSelfRef.tb_core__DOT__dut__DOT__state))) {
            vlSelfRef.tb_core__DOT__dut__DOT__rs1_q 
                = (((((0x0000001fU & (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                                              >> 0x0000000aU))) 
                      == (0x0000001fU & (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                                                 >> 5U)))) 
                     & (IData)(vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__write_en))
                     ? vlSelfRef.tb_core__DOT__dut__DOT__rf_wdata
                     : vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs
                    [(0x0000001fU & (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                                             >> 5U)))]) 
                   & (- (IData)((0U != (0x0000001fU 
                                        & (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                                                   >> 5U)))))));
            vlSelfRef.tb_core__DOT__dut__DOT__rs2_q 
                = (((((0x0000001fU & (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                                              >> 0x0000000aU))) 
                      == (0x0000001fU & (IData)(vlSelfRef.tb_core__DOT__dut__DOT__d))) 
                     & (IData)(vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__write_en))
                     ? vlSelfRef.tb_core__DOT__dut__DOT__rf_wdata
                     : vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs
                    [(0x0000001fU & (IData)(vlSelfRef.tb_core__DOT__dut__DOT__d))]) 
                   & (- (IData)((0U != (0x0000001fU 
                                        & (IData)(vlSelfRef.tb_core__DOT__dut__DOT__d))))));
            vlSelfRef.tb_core__DOT__dut__DOT__imm_q 
                = ((1U & (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                                  >> 0x0000001eU)))
                    ? ((1U & (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                                      >> 0x0000001dU)))
                        ? (0x0000001fU & ((- (IData)(
                                                     (1U 
                                                      & (~ (IData)(
                                                                   (vlSelfRef.tb_core__DOT__dut__DOT__d 
                                                                    >> 0x0000001cU)))))) 
                                          & (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                             >> 0x0000000fU)))
                        : (((1U & (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                                           >> 0x0000001cU)))
                             ? ((((0x00000ffeU & ((- (IData)(
                                                             (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                                              >> 0x0000001fU))) 
                                                  << 1U)) 
                                  | (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                     >> 0x0000001fU)) 
                                 << 0x00000013U) | 
                                ((0x0007f800U & (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                                 >> 1U)) 
                                 | ((0x00000400U & 
                                     (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                      >> 0x0000000aU)) 
                                    | (0x000003ffU 
                                       & (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                          >> 0x00000015U)))))
                             : (0x7ffff800U & (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                               >> 1U))) 
                           << 1U)) : ((1U & (IData)(
                                                    (vlSelfRef.tb_core__DOT__dut__DOT__d 
                                                     >> 0x0000001dU)))
                                       ? ((1U & (IData)(
                                                        (vlSelfRef.tb_core__DOT__dut__DOT__d 
                                                         >> 0x0000001cU)))
                                           ? (((- (IData)(
                                                          (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                                           >> 0x0000001fU))) 
                                               << 0x0000000dU) 
                                              | ((((2U 
                                                    & (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                                       >> 0x0000001eU)) 
                                                   | (1U 
                                                      & (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                                         >> 7U))) 
                                                  << 0x0000000bU) 
                                                 | ((0x000007e0U 
                                                     & (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                                        >> 0x00000014U)) 
                                                    | (0x0000001eU 
                                                       & (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                                          >> 7U)))))
                                           : ((vlSelfRef.__VdfgRegularize_h6e95ff9d_0_2 
                                               << 0x0000000cU) 
                                              | ((0x00000fe0U 
                                                  & (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                                     >> 0x00000014U)) 
                                                 | (0x0000001fU 
                                                    & (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                                       >> 7U)))))
                                       : (((vlSelfRef.__VdfgRegularize_h6e95ff9d_0_2 
                                            << 0x0000000cU) 
                                           | (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                              >> 0x00000014U)) 
                                          & (- (IData)(
                                                       (1U 
                                                        & (IData)(
                                                                  (vlSelfRef.tb_core__DOT__dut__DOT__d 
                                                                   >> 0x0000001cU))))))));
            vlSelfRef.tb_core__DOT__dut__DOT__illegal_q 
                = (1U & (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                                 >> 0x00000026U)));
        }
        if ((0U == (IData)(vlSelfRef.tb_core__DOT__dut__DOT__state))) {
            vlSelfRef.tb_core__DOT__dut__DOT__ir = vlSelfRef.tb_core__DOT__mem
                [(0x000003ffU & (vlSelfRef.tb_core__DOT__dut__DOT__pc 
                                 >> 2U))];
        }
    } else {
        __Vdly__tb_core__DOT__dut__DOT__state = 0U;
        __Vdly__tb_core__DOT__dut__DOT__pc = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__ir = 0x00000013U;
        vlSelfRef.tb_core__DOT__dut__DOT__rs1_q = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__rs2_q = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__imm_q = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__alu_q = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__take_q = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__target_q = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__load_q = 0U;
        vlSelfRef.tb_core__DOT__dut__DOT__illegal_q = 0U;
    }
    vlSelfRef.tb_core__DOT__dut__DOT__state = __Vdly__tb_core__DOT__dut__DOT__state;
    vlSelfRef.tb_core__DOT__dut__DOT__pc = __Vdly__tb_core__DOT__dut__DOT__pc;
    vlSelfRef.tb_core__DOT__dut__DOT__pc_en = ((~ (IData)(vlSelfRef.tb_core__DOT__dut__DOT__illegal_q)) 
                                               & (4U 
                                                  == (IData)(vlSelfRef.tb_core__DOT__dut__DOT__state)));
    vlSelfRef.__VdfgRegularize_h6e95ff9d_0_1 = ((IData)(4U) 
                                                + vlSelfRef.tb_core__DOT__dut__DOT__pc);
    vlSelfRef.__VdfgRegularize_h6e95ff9d_0_2 = (0x000fffffU 
                                                & (- (IData)(
                                                             (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                                              >> 0x0000001fU))));
    tb_core__DOT__dut__DOT__u_dec__DOT__funct7_ok = 
        ((0U == (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                 >> 0x00000019U)) | (0x20U == (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                               >> 0x00000019U)));
    tb_core__DOT__dut__DOT__u_dec__DOT__alt_legal_reg 
        = ((0U == (7U & (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                         >> 0x0000000cU))) | (5U == 
                                              (7U & 
                                               (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                                >> 0x0000000cU))));
    vlSelfRef.tb_core__DOT__dut__DOT__d = 0ULL;
    vlSelfRef.tb_core__DOT__dut__DOT__d = ((0x000000000000001fULL 
                                            & vlSelfRef.tb_core__DOT__dut__DOT__d) 
                                           | (0x0000000080400000ULL 
                                              | ((QData)((IData)(
                                                                 ((0x000003e0U 
                                                                   & (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                                                      >> 2U)) 
                                                                  | (0x0000001fU 
                                                                     & (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                                                        >> 0x0fU))))) 
                                                 << 5U)));
    vlSelfRef.tb_core__DOT__dut__DOT__d = ((0x0000007fffffffe0ULL 
                                            & vlSelfRef.tb_core__DOT__dut__DOT__d) 
                                           | (IData)((IData)(
                                                             (0x0000001fU 
                                                              & (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                                                 >> 0x14U)))));
    if ((0x00000040U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
        if ((0x00000020U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
            if ((0x00000010U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
                if ((8U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
                    vlSelfRef.tb_core__DOT__dut__DOT__d 
                        = (0x0000004000000000ULL | vlSelfRef.tb_core__DOT__dut__DOT__d);
                } else if ((4U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
                    vlSelfRef.tb_core__DOT__dut__DOT__d 
                        = (0x0000004000000000ULL | vlSelfRef.tb_core__DOT__dut__DOT__d);
                } else if ((2U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
                    if ((1U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
                        vlSelfRef.tb_core__DOT__dut__DOT__d 
                            = (0x0000007ffffeffffULL 
                               & vlSelfRef.tb_core__DOT__dut__DOT__d);
                        vlSelfRef.tb_core__DOT__dut__DOT__d 
                            = ((0x0000007fffff7fffULL 
                                & vlSelfRef.tb_core__DOT__dut__DOT__d) 
                               | ((QData)((IData)((IData)(
                                                          ((0U 
                                                            == 
                                                            (0x00007000U 
                                                             & vlSelfRef.tb_core__DOT__dut__DOT__ir)) 
                                                           & ((0U 
                                                               == 
                                                               (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                                                >> 0x00000014U)) 
                                                              | (1U 
                                                                 == 
                                                                 (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                                                  >> 0x00000014U))))))) 
                                  << 0x0000000fU));
                        vlSelfRef.tb_core__DOT__dut__DOT__d 
                            = ((0x0000003fffffffffULL 
                                & vlSelfRef.tb_core__DOT__dut__DOT__d) 
                               | ((QData)((IData)((1U 
                                                   & (~ (IData)(
                                                                (vlSelfRef.tb_core__DOT__dut__DOT__d 
                                                                 >> 0x0000000fU)))))) 
                                  << 0x00000026U));
                    } else {
                        vlSelfRef.tb_core__DOT__dut__DOT__d 
                            = (0x0000004000000000ULL 
                               | vlSelfRef.tb_core__DOT__dut__DOT__d);
                    }
                } else {
                    vlSelfRef.tb_core__DOT__dut__DOT__d 
                        = (0x0000004000000000ULL | vlSelfRef.tb_core__DOT__dut__DOT__d);
                }
            } else if ((8U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
                if ((4U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
                    if ((2U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
                        if ((1U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
                            vlSelfRef.tb_core__DOT__dut__DOT__d 
                                = (0x00000001d1000000ULL 
                                   | (0x0000004000ffffffULL 
                                      & vlSelfRef.tb_core__DOT__dut__DOT__d));
                            vlSelfRef.tb_core__DOT__dut__DOT__d 
                                = (0x0000000000050000ULL 
                                   | (0x0000007ffff8ffffULL 
                                      & vlSelfRef.tb_core__DOT__dut__DOT__d));
                        } else {
                            vlSelfRef.tb_core__DOT__dut__DOT__d 
                                = (0x0000004000000000ULL 
                                   | vlSelfRef.tb_core__DOT__dut__DOT__d);
                        }
                    } else {
                        vlSelfRef.tb_core__DOT__dut__DOT__d 
                            = (0x0000004000000000ULL 
                               | vlSelfRef.tb_core__DOT__dut__DOT__d);
                    }
                } else {
                    vlSelfRef.tb_core__DOT__dut__DOT__d 
                        = (0x0000004000000000ULL | vlSelfRef.tb_core__DOT__dut__DOT__d);
                }
            } else if ((4U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
                if ((2U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
                    if ((1U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
                        vlSelfRef.tb_core__DOT__dut__DOT__d 
                            = (0x0000000092000000ULL 
                               | (0x0000004000ffffffULL 
                                  & vlSelfRef.tb_core__DOT__dut__DOT__d));
                        vlSelfRef.tb_core__DOT__dut__DOT__d 
                            = (0x0000000000050000ULL 
                               | (0x0000007ffff8ffffULL 
                                  & vlSelfRef.tb_core__DOT__dut__DOT__d));
                        vlSelfRef.tb_core__DOT__dut__DOT__d 
                            = ((0x0000003fffffffffULL 
                                & vlSelfRef.tb_core__DOT__dut__DOT__d) 
                               | ((QData)((IData)((0U 
                                                   != 
                                                   (7U 
                                                    & (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                                       >> 0x0000000cU))))) 
                                  << 0x00000026U));
                    } else {
                        vlSelfRef.tb_core__DOT__dut__DOT__d 
                            = (0x0000004000000000ULL 
                               | vlSelfRef.tb_core__DOT__dut__DOT__d);
                    }
                } else {
                    vlSelfRef.tb_core__DOT__dut__DOT__d 
                        = (0x0000004000000000ULL | vlSelfRef.tb_core__DOT__dut__DOT__d);
                }
            } else if ((2U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
                if ((1U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
                    vlSelfRef.tb_core__DOT__dut__DOT__d 
                        = ((0x0000004000ffffffULL & vlSelfRef.tb_core__DOT__dut__DOT__d) 
                           | ((QData)((IData)((0x000001b8U 
                                               | (7U 
                                                  & (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                                     >> 0x0000000cU))))) 
                              << 0x00000018U));
                    vlSelfRef.tb_core__DOT__dut__DOT__d 
                        = (0x0000007ffffeffffULL & vlSelfRef.tb_core__DOT__dut__DOT__d);
                    vlSelfRef.tb_core__DOT__dut__DOT__d 
                        = ((0x0000003fffffffffULL & vlSelfRef.tb_core__DOT__dut__DOT__d) 
                           | ((QData)((IData)(((2U 
                                                == 
                                                (7U 
                                                 & (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                                    >> 0x0000000cU))) 
                                               | (3U 
                                                  == 
                                                  (7U 
                                                   & (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                                      >> 0x0000000cU)))))) 
                              << 0x00000026U));
                } else {
                    vlSelfRef.tb_core__DOT__dut__DOT__d 
                        = (0x0000004000000000ULL | vlSelfRef.tb_core__DOT__dut__DOT__d);
                }
            } else {
                vlSelfRef.tb_core__DOT__dut__DOT__d 
                    = (0x0000004000000000ULL | vlSelfRef.tb_core__DOT__dut__DOT__d);
            }
        } else {
            vlSelfRef.tb_core__DOT__dut__DOT__d = (0x0000004000000000ULL 
                                                   | vlSelfRef.tb_core__DOT__dut__DOT__d);
        }
    } else if ((0x00000020U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
        if ((0x00000010U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
            if ((8U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
                vlSelfRef.tb_core__DOT__dut__DOT__d 
                    = (0x0000004000000000ULL | vlSelfRef.tb_core__DOT__dut__DOT__d);
            } else if ((4U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
                if ((2U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
                    if ((1U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
                        vlSelfRef.tb_core__DOT__dut__DOT__d 
                            = (0x0000002800000000ULL 
                               | (0x00000043ffffffffULL 
                                  & vlSelfRef.tb_core__DOT__dut__DOT__d));
                        vlSelfRef.tb_core__DOT__dut__DOT__d 
                            = (0x00000000c0000000ULL 
                               | (0x0000007f0fffffffULL 
                                  & vlSelfRef.tb_core__DOT__dut__DOT__d));
                        vlSelfRef.tb_core__DOT__dut__DOT__d 
                            = (0x0000000000010000ULL 
                               | (0x0000007ffff8ffffULL 
                                  & vlSelfRef.tb_core__DOT__dut__DOT__d));
                    } else {
                        vlSelfRef.tb_core__DOT__dut__DOT__d 
                            = (0x0000004000000000ULL 
                               | vlSelfRef.tb_core__DOT__dut__DOT__d);
                    }
                } else {
                    vlSelfRef.tb_core__DOT__dut__DOT__d 
                        = (0x0000004000000000ULL | vlSelfRef.tb_core__DOT__dut__DOT__d);
                }
            } else if ((2U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
                if ((1U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
                    vlSelfRef.tb_core__DOT__dut__DOT__d 
                        = ((0x000000407fffffffULL & vlSelfRef.tb_core__DOT__dut__DOT__d) 
                           | ((QData)((IData)(((0x000000c0U 
                                                & ((vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                                    >> 0x00000018U) 
                                                   & ((IData)(tb_core__DOT__dut__DOT__u_dec__DOT__alt_legal_reg) 
                                                      << 6U))) 
                                               | (0x00000038U 
                                                  & (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                                     >> 9U))))) 
                              << 0x0000001fU));
                    vlSelfRef.tb_core__DOT__dut__DOT__d 
                        = (0x0000000000010000ULL | 
                           (0x0000007ffff8ffffULL & vlSelfRef.tb_core__DOT__dut__DOT__d));
                    vlSelfRef.tb_core__DOT__dut__DOT__d 
                        = ((0x0000003fffffffffULL & vlSelfRef.tb_core__DOT__dut__DOT__d) 
                           | ((QData)((IData)((1U & 
                                               ((~ (IData)(tb_core__DOT__dut__DOT__u_dec__DOT__funct7_ok)) 
                                                | ((vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                                    >> 0x0000001eU) 
                                                   & (~ (IData)(tb_core__DOT__dut__DOT__u_dec__DOT__alt_legal_reg))))))) 
                              << 0x00000026U));
                } else {
                    vlSelfRef.tb_core__DOT__dut__DOT__d 
                        = (0x0000004000000000ULL | vlSelfRef.tb_core__DOT__dut__DOT__d);
                }
            } else {
                vlSelfRef.tb_core__DOT__dut__DOT__d 
                    = (0x0000004000000000ULL | vlSelfRef.tb_core__DOT__dut__DOT__d);
            }
        } else if ((8U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
            vlSelfRef.tb_core__DOT__dut__DOT__d = (0x0000004000000000ULL 
                                                   | vlSelfRef.tb_core__DOT__dut__DOT__d);
        } else if ((4U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
            vlSelfRef.tb_core__DOT__dut__DOT__d = (0x0000004000000000ULL 
                                                   | vlSelfRef.tb_core__DOT__dut__DOT__d);
        } else if ((2U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
            if ((1U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
                vlSelfRef.tb_core__DOT__dut__DOT__d 
                    = (0x00000000a0000000ULL | (0x000000400fffffffULL 
                                                & vlSelfRef.tb_core__DOT__dut__DOT__d));
                vlSelfRef.tb_core__DOT__dut__DOT__d 
                    = (0x0000000000080000ULL | vlSelfRef.tb_core__DOT__dut__DOT__d);
                vlSelfRef.tb_core__DOT__dut__DOT__d 
                    = ((0x0000007fff1fffffULL & vlSelfRef.tb_core__DOT__dut__DOT__d) 
                       | ((QData)((IData)((7U & (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                                 >> 0x0000000cU)))) 
                          << 0x00000015U));
                vlSelfRef.tb_core__DOT__dut__DOT__d 
                    = (0x0000007ffffeffffULL & vlSelfRef.tb_core__DOT__dut__DOT__d);
                vlSelfRef.tb_core__DOT__dut__DOT__d 
                    = ((0x0000003fffffffffULL & vlSelfRef.tb_core__DOT__dut__DOT__d) 
                       | ((QData)((IData)((((0U != 
                                             (7U & 
                                              (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                               >> 0x0000000cU))) 
                                            & (1U != 
                                               (7U 
                                                & (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                                   >> 0x0000000cU)))) 
                                           & (2U != 
                                              (7U & 
                                               (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                                >> 0x0000000cU)))))) 
                          << 0x00000026U));
            } else {
                vlSelfRef.tb_core__DOT__dut__DOT__d 
                    = (0x0000004000000000ULL | vlSelfRef.tb_core__DOT__dut__DOT__d);
            }
        } else {
            vlSelfRef.tb_core__DOT__dut__DOT__d = (0x0000004000000000ULL 
                                                   | vlSelfRef.tb_core__DOT__dut__DOT__d);
        }
    } else if ((0x00000010U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
        if ((8U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
            vlSelfRef.tb_core__DOT__dut__DOT__d = (0x0000004000000000ULL 
                                                   | vlSelfRef.tb_core__DOT__dut__DOT__d);
        } else if ((4U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
            if ((2U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
                if ((1U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
                    vlSelfRef.tb_core__DOT__dut__DOT__d 
                        = (0x00000001c0000000ULL | 
                           (0x000000400fffffffULL & vlSelfRef.tb_core__DOT__dut__DOT__d));
                    vlSelfRef.tb_core__DOT__dut__DOT__d 
                        = (0x0000000000010000ULL | 
                           (0x0000007ffff8ffffULL & vlSelfRef.tb_core__DOT__dut__DOT__d));
                } else {
                    vlSelfRef.tb_core__DOT__dut__DOT__d 
                        = (0x0000004000000000ULL | vlSelfRef.tb_core__DOT__dut__DOT__d);
                }
            } else {
                vlSelfRef.tb_core__DOT__dut__DOT__d 
                    = (0x0000004000000000ULL | vlSelfRef.tb_core__DOT__dut__DOT__d);
            }
        } else if ((2U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
            if ((1U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
                vlSelfRef.tb_core__DOT__dut__DOT__d 
                    = ((0x000000400fffffffULL & vlSelfRef.tb_core__DOT__dut__DOT__d) 
                       | ((QData)((IData)((9U | (((IData)(
                                                          (0x40005000U 
                                                           == 
                                                           (0x40007000U 
                                                            & vlSelfRef.tb_core__DOT__dut__DOT__ir))) 
                                                  << 9U) 
                                                 | (0x000001c0U 
                                                    & (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                                       >> 6U)))))) 
                          << 0x0000001cU));
                vlSelfRef.tb_core__DOT__dut__DOT__d 
                    = (0x0000000000010000ULL | (0x0000007ffff8ffffULL 
                                                & vlSelfRef.tb_core__DOT__dut__DOT__d));
                vlSelfRef.tb_core__DOT__dut__DOT__d 
                    = ((0x0000003fffffffffULL & vlSelfRef.tb_core__DOT__dut__DOT__d) 
                       | ((QData)((IData)((((1U == 
                                             (7U & 
                                              (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                               >> 0x0000000cU))) 
                                            | (5U == 
                                               (7U 
                                                & (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                                   >> 0x0000000cU)))) 
                                           & (~ (IData)(tb_core__DOT__dut__DOT__u_dec__DOT__funct7_ok))))) 
                          << 0x00000026U));
            } else {
                vlSelfRef.tb_core__DOT__dut__DOT__d 
                    = (0x0000004000000000ULL | vlSelfRef.tb_core__DOT__dut__DOT__d);
            }
        } else {
            vlSelfRef.tb_core__DOT__dut__DOT__d = (0x0000004000000000ULL 
                                                   | vlSelfRef.tb_core__DOT__dut__DOT__d);
        }
    } else if ((8U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
        vlSelfRef.tb_core__DOT__dut__DOT__d = ((4U 
                                                & vlSelfRef.tb_core__DOT__dut__DOT__ir)
                                                ? (
                                                   (2U 
                                                    & vlSelfRef.tb_core__DOT__dut__DOT__ir)
                                                    ? 
                                                   ((1U 
                                                     & vlSelfRef.tb_core__DOT__dut__DOT__ir)
                                                     ? 
                                                    (0x0000007ffffeffffULL 
                                                     & vlSelfRef.tb_core__DOT__dut__DOT__d)
                                                     : 
                                                    (0x0000004000000000ULL 
                                                     | vlSelfRef.tb_core__DOT__dut__DOT__d))
                                                    : 
                                                   (0x0000004000000000ULL 
                                                    | vlSelfRef.tb_core__DOT__dut__DOT__d))
                                                : (0x0000004000000000ULL 
                                                   | vlSelfRef.tb_core__DOT__dut__DOT__d));
    } else if ((4U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
        vlSelfRef.tb_core__DOT__dut__DOT__d = (0x0000004000000000ULL 
                                               | vlSelfRef.tb_core__DOT__dut__DOT__d);
    } else if ((2U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
        if ((1U & vlSelfRef.tb_core__DOT__dut__DOT__ir)) {
            vlSelfRef.tb_core__DOT__dut__DOT__d = (0x0000000090000000ULL 
                                                   | (0x000000400fffffffULL 
                                                      & vlSelfRef.tb_core__DOT__dut__DOT__d));
            vlSelfRef.tb_core__DOT__dut__DOT__d = (
                                                   (0x0000007fff0fffffULL 
                                                    & vlSelfRef.tb_core__DOT__dut__DOT__d) 
                                                   | ((QData)((IData)(
                                                                      (1U 
                                                                       | (0x0000000eU 
                                                                          & (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                                                             >> 0x0000000bU))))) 
                                                      << 0x00000014U));
            vlSelfRef.tb_core__DOT__dut__DOT__d = (0x0000000000030000ULL 
                                                   | (0x0000007ffff8ffffULL 
                                                      & vlSelfRef.tb_core__DOT__dut__DOT__d));
            vlSelfRef.tb_core__DOT__dut__DOT__d = (
                                                   (0x0000003fffffffffULL 
                                                    & vlSelfRef.tb_core__DOT__dut__DOT__d) 
                                                   | ((QData)((IData)(
                                                                      (((3U 
                                                                         == 
                                                                         (7U 
                                                                          & (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                                                             >> 0x0000000cU))) 
                                                                        | (6U 
                                                                           == 
                                                                           (7U 
                                                                            & (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                                                               >> 0x0000000cU)))) 
                                                                       | (7U 
                                                                          == 
                                                                          (7U 
                                                                           & (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                                                              >> 0x0000000cU)))))) 
                                                      << 0x00000026U));
        } else {
            vlSelfRef.tb_core__DOT__dut__DOT__d = (0x0000004000000000ULL 
                                                   | vlSelfRef.tb_core__DOT__dut__DOT__d);
        }
    } else {
        vlSelfRef.tb_core__DOT__dut__DOT__d = (0x0000004000000000ULL 
                                               | vlSelfRef.tb_core__DOT__dut__DOT__d);
    }
    if ((0U == (7U & (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                              >> 0x00000015U))))) {
        vlSelfRef.tb_core__DOT__dmem_be = (0x0000000fU 
                                           & ((IData)(1U) 
                                              << (3U 
                                                  & vlSelfRef.tb_core__DOT__dut__DOT__alu_q)));
        vlSelfRef.tb_core__DOT__dmem_wdata = ((vlSelfRef.tb_core__DOT__dut__DOT__rs2_q 
                                               << 0x00000018U) 
                                              | ((0x00ff0000U 
                                                  & (vlSelfRef.tb_core__DOT__dut__DOT__rs2_q 
                                                     << 0x00000010U)) 
                                                 | ((0x0000ff00U 
                                                     & (vlSelfRef.tb_core__DOT__dut__DOT__rs2_q 
                                                        << 8U)) 
                                                    | (0x000000ffU 
                                                       & vlSelfRef.tb_core__DOT__dut__DOT__rs2_q))));
    } else {
        vlSelfRef.tb_core__DOT__dmem_be = (0x0000000fU 
                                           & (((2U 
                                                & vlSelfRef.tb_core__DOT__dut__DOT__alu_q)
                                                ? 0x0cU
                                                : 3U) 
                                              | (- (IData)(
                                                           (1U 
                                                            != 
                                                            (7U 
                                                             & (IData)(
                                                                       (vlSelfRef.tb_core__DOT__dut__DOT__d 
                                                                        >> 0x00000015U))))))));
        vlSelfRef.tb_core__DOT__dmem_wdata = ((1U == 
                                               (7U 
                                                & (IData)(
                                                          (vlSelfRef.tb_core__DOT__dut__DOT__d 
                                                           >> 0x00000015U))))
                                               ? ((vlSelfRef.tb_core__DOT__dut__DOT__rs2_q 
                                                   << 0x00000010U) 
                                                  | (0x0000ffffU 
                                                     & vlSelfRef.tb_core__DOT__dut__DOT__rs2_q))
                                               : vlSelfRef.tb_core__DOT__dut__DOT__rs2_q);
    }
    vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__write_en 
        = ((0U != (0x0000001fU & (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                                          >> 0x0000000aU)))) 
           & ((IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                       >> 0x00000010U)) & (IData)(vlSelfRef.tb_core__DOT__dut__DOT__pc_en)));
    vlSelfRef.tb_core__DOT__dmem_we = ((~ (IData)(vlSelfRef.tb_core__DOT__dut__DOT__illegal_q)) 
                                       & ((3U == (IData)(vlSelfRef.tb_core__DOT__dut__DOT__state)) 
                                          & (IData)(
                                                    (vlSelfRef.tb_core__DOT__dut__DOT__d 
                                                     >> 0x00000013U))));
    vlSelfRef.tb_core__DOT__dut__DOT__rf_wdata = ((1U 
                                                   == 
                                                   (3U 
                                                    & (IData)(
                                                              (vlSelfRef.tb_core__DOT__dut__DOT__d 
                                                               >> 0x00000011U))))
                                                   ? vlSelfRef.tb_core__DOT__dut__DOT__load_q
                                                   : 
                                                  ((2U 
                                                    == 
                                                    (3U 
                                                     & (IData)(
                                                               (vlSelfRef.tb_core__DOT__dut__DOT__d 
                                                                >> 0x00000011U))))
                                                    ? 
                                                   ((IData)(4U) 
                                                    + vlSelfRef.tb_core__DOT__dut__DOT__pc)
                                                    : vlSelfRef.tb_core__DOT__dut__DOT__alu_q));
    tb_core__DOT__dut__DOT__alu_a = ((1U == (3U & (IData)(
                                                          (vlSelfRef.tb_core__DOT__dut__DOT__d 
                                                           >> 0x00000020U))))
                                      ? vlSelfRef.tb_core__DOT__dut__DOT__pc
                                      : (vlSelfRef.tb_core__DOT__dut__DOT__rs1_q 
                                         & (- (IData)(
                                                      (2U 
                                                       != 
                                                       (3U 
                                                        & (IData)(
                                                                  (vlSelfRef.tb_core__DOT__dut__DOT__d 
                                                                   >> 0x00000020U))))))));
    tb_core__DOT__dut__DOT__alu_b = ((1U & (IData)(
                                                   (vlSelfRef.tb_core__DOT__dut__DOT__d 
                                                    >> 0x0000001fU)))
                                      ? vlSelfRef.tb_core__DOT__dut__DOT__imm_q
                                      : vlSelfRef.tb_core__DOT__dut__DOT__rs2_q);
    vlSelfRef.tb_core__DOT__dut__DOT__alu_result = 
        ((1U & (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                        >> 0x00000025U))) ? ((1U & (IData)(
                                                           (vlSelfRef.tb_core__DOT__dut__DOT__d 
                                                            >> 0x00000024U)))
                                              ? (VL_SHIFTRS_III(32,32,5, tb_core__DOT__dut__DOT__alu_a, 
                                                                (0x0000001fU 
                                                                 & tb_core__DOT__dut__DOT__alu_b)) 
                                                 & (- (IData)((IData)(
                                                                      (0x0000000400000000ULL 
                                                                       == 
                                                                       (0x0000000c00000000ULL 
                                                                        & vlSelfRef.tb_core__DOT__dut__DOT__d))))))
                                              : ((1U 
                                                  & (IData)(
                                                            (vlSelfRef.tb_core__DOT__dut__DOT__d 
                                                             >> 0x00000023U)))
                                                  ? 
                                                 (tb_core__DOT__dut__DOT__alu_b 
                                                  & (- (IData)(
                                                               (1U 
                                                                & (~ (IData)(
                                                                             (vlSelfRef.tb_core__DOT__dut__DOT__d 
                                                                              >> 0x00000022U)))))))
                                                  : 
                                                 ((tb_core__DOT__dut__DOT__alu_a 
                                                   - tb_core__DOT__dut__DOT__alu_b) 
                                                  & (- (IData)(
                                                               (1U 
                                                                & (~ (IData)(
                                                                             (vlSelfRef.tb_core__DOT__dut__DOT__d 
                                                                              >> 0x00000022U)))))))))
          : ((1U & (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                            >> 0x00000024U))) ? ((1U 
                                                  & (IData)(
                                                            (vlSelfRef.tb_core__DOT__dut__DOT__d 
                                                             >> 0x00000023U)))
                                                  ? 
                                                 ((1U 
                                                   & (IData)(
                                                             (vlSelfRef.tb_core__DOT__dut__DOT__d 
                                                              >> 0x00000022U)))
                                                   ? 
                                                  (tb_core__DOT__dut__DOT__alu_a 
                                                   & tb_core__DOT__dut__DOT__alu_b)
                                                   : 
                                                  (tb_core__DOT__dut__DOT__alu_a 
                                                   | tb_core__DOT__dut__DOT__alu_b))
                                                  : 
                                                 ((1U 
                                                   & (IData)(
                                                             (vlSelfRef.tb_core__DOT__dut__DOT__d 
                                                              >> 0x00000022U)))
                                                   ? 
                                                  (tb_core__DOT__dut__DOT__alu_a 
                                                   >> 
                                                   (0x0000001fU 
                                                    & tb_core__DOT__dut__DOT__alu_b))
                                                   : 
                                                  (tb_core__DOT__dut__DOT__alu_a 
                                                   ^ tb_core__DOT__dut__DOT__alu_b)))
              : ((1U & (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                                >> 0x00000023U))) ? 
                 ((1U & (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                                 >> 0x00000022U))) ? 
                  (tb_core__DOT__dut__DOT__alu_a < tb_core__DOT__dut__DOT__alu_b)
                   : VL_LTS_III(32, tb_core__DOT__dut__DOT__alu_a, tb_core__DOT__dut__DOT__alu_b))
                  : ((1U & (IData)((vlSelfRef.tb_core__DOT__dut__DOT__d 
                                    >> 0x00000022U)))
                      ? (tb_core__DOT__dut__DOT__alu_a 
                         << (0x0000001fU & tb_core__DOT__dut__DOT__alu_b))
                      : (tb_core__DOT__dut__DOT__alu_a 
                         + tb_core__DOT__dut__DOT__alu_b)))));
}

void Vtb_core___024root___timing_ready(Vtb_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_core___024root___timing_ready\n"); );
    Vtb_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VactTriggered[0U])) {
        vlSelfRef.__VtrigSched_h5e18bfa5__0.ready("@(posedge tb_core.clk)");
    }
}

void Vtb_core___024root___timing_resume(Vtb_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_core___024root___timing_resume\n"); );
    Vtb_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VtrigSched_h5e18bfa5__0.moveToResumeQueue(
                                                          "@(posedge tb_core.clk)");
    vlSelfRef.__VtrigSched_h5e18bfa5__0.resume("@(posedge tb_core.clk)");
    if ((4ULL & vlSelfRef.__VactTriggered[0U])) {
        vlSelfRef.__VdlySched.resume();
    }
}

void Vtb_core___024root___trigger_orInto__act_vec_vec(VlUnpacked<QData/*63:0*/, 1> &out, const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_core___024root___trigger_orInto__act_vec_vec\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        out[n] = (out[n] | in[n]);
        n = ((IData)(1U) + n);
    } while ((0U >= n));
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_core___024root___dump_triggers__act(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG

bool Vtb_core___024root___eval_phase__act(Vtb_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_core___024root___eval_phase__act\n"); );
    Vtb_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VactExecute;
    // Body
    {
        // Inlined CFunc: _eval_triggers_vec__act
        vlSelfRef.__VactTriggered[0U] = (QData)((IData)(
                                                        ((vlSelfRef.__VdlySched.awaitingCurrentTime() 
                                                          << 2U) 
                                                         | ((((~ (IData)(vlSelfRef.tb_core__DOT__rst_n)) 
                                                              & (IData)(vlSelfRef.__Vtrigprevexpr___TOP__tb_core__DOT__rst_n__0)) 
                                                             << 1U) 
                                                            | ((IData)(vlSelfRef.tb_core__DOT__clk) 
                                                               & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__tb_core__DOT__clk__0)))))));
        vlSelfRef.__Vtrigprevexpr___TOP__tb_core__DOT__clk__0 
            = vlSelfRef.tb_core__DOT__clk;
        vlSelfRef.__Vtrigprevexpr___TOP__tb_core__DOT__rst_n__0 
            = vlSelfRef.tb_core__DOT__rst_n;
    }
    Vtb_core___024root___timing_ready(vlSelf);
    Vtb_core___024root___trigger_orInto__act_vec_vec(vlSelfRef.__VactTriggered, vlSelfRef.__VactTriggeredAcc);
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vtb_core___024root___dump_triggers__act(vlSelfRef.__VactTriggered, "act"s);
    }
#endif
    Vtb_core___024root___trigger_orInto__act_vec_vec(vlSelfRef.__VnbaTriggered, vlSelfRef.__VactTriggered);
    __VactExecute = Vtb_core___024root___trigger_anySet__act(vlSelfRef.__VactTriggered);
    if (__VactExecute) {
        vlSelfRef.__VactTriggeredAcc.fill(0ULL);
        Vtb_core___024root___timing_resume(vlSelf);
        {
            // Inlined CFunc: _eval_act
            if ((1ULL & vlSelfRef.__VactTriggered[0U])) {
                {
                    // Inlined CFunc: _act_sequent__TOP__0
                    if (vlSelfRef.tb_core__DOT__rst_n) {
                        if (VL_UNLIKELY(((0x00001000U 
                                          <= vlSelfRef.tb_core__DOT__dut__DOT__pc)))) {
                            VL_WRITEF_NX("[%0t] %%Fatal: tb-core.sv:102: Assertion failed in %m: FAIL: instruction fetch out of range: %08h\n",4, 'M',vlSymsp->name(),"tb_core", 'T',-9
                                         , '#',64,VL_TIME_UNITED_Q(1000)
                                         , '#',32,vlSelfRef.tb_core__DOT__dut__DOT__pc);
                            VL_STOP_MT("tb-core.sv", 102, "", false);
                        }
                        if (VL_UNLIKELY(((0U != (3U 
                                                 & vlSelfRef.tb_core__DOT__dut__DOT__pc))))) {
                            VL_WRITEF_NX("[%0t] %%Fatal: tb-core.sv:104: Assertion failed in %m: FAIL: misaligned instruction fetch: %08h\n",4, 'M',vlSymsp->name(),"tb_core", 'T',-9
                                         , '#',64,VL_TIME_UNITED_Q(1000)
                                         , '#',32,vlSelfRef.tb_core__DOT__dut__DOT__pc);
                            VL_STOP_MT("tb-core.sv", 104, "", false);
                        }
                    }
                    vlSelfRef.tb_core__DOT__dut__DOT__load_byte 
                        = (0x000000ffU & (vlSelfRef.tb_core__DOT__mem
                                          [(0x000003ffU 
                                            & (vlSelfRef.tb_core__DOT__dut__DOT__alu_q 
                                               >> 2U))] 
                                          >> (0x00000018U 
                                              & (vlSelfRef.tb_core__DOT__dut__DOT__alu_q 
                                                 << 3U))));
                    vlSelfRef.tb_core__DOT__dut__DOT__load_half 
                        = (0x0000ffffU & ((2U & vlSelfRef.tb_core__DOT__dut__DOT__alu_q)
                                           ? (vlSelfRef.tb_core__DOT__mem
                                              [(0x000003ffU 
                                                & (vlSelfRef.tb_core__DOT__dut__DOT__alu_q 
                                                   >> 2U))] 
                                              >> 0x00000010U)
                                           : vlSelfRef.tb_core__DOT__mem
                                          [(0x000003ffU 
                                            & (vlSelfRef.tb_core__DOT__dut__DOT__alu_q 
                                               >> 2U))]));
                }
            }
        }
    }
    return (__VactExecute);
}

bool Vtb_core___024root___eval_phase__inact(Vtb_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_core___024root___eval_phase__inact\n"); );
    Vtb_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VinactExecute;
    // Body
    __VinactExecute = vlSelfRef.__VdlySched.awaitingZeroDelay();
    if (__VinactExecute) {
        VL_FATAL_MT("tb-core.sv", 18, "", "ZERODLY: Design Verilated with '--no-sched-zero-delay', but #0 delay executed at runtime");
    }
    return (__VinactExecute);
}

void Vtb_core___024root___trigger_clear__act(VlUnpacked<QData/*63:0*/, 1> &out) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_core___024root___trigger_clear__act\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        out[n] = 0ULL;
        n = ((IData)(1U) + n);
    } while ((1U > n));
}

bool Vtb_core___024root___eval_phase__nba(Vtb_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_core___024root___eval_phase__nba\n"); );
    Vtb_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = Vtb_core___024root___trigger_anySet__act(vlSelfRef.__VnbaTriggered);
    if (__VnbaExecute) {
        {
            // Inlined CFunc: _eval_nba
            if ((1ULL & vlSelfRef.__VnbaTriggered[0U])) {
                Vtb_core___024root___nba_sequent__TOP__0(vlSelf);
            }
            if ((3ULL & vlSelfRef.__VnbaTriggered[0U])) {
                Vtb_core___024root___nba_sequent__TOP__1(vlSelf);
            }
            if ((1ULL & vlSelfRef.__VnbaTriggered[0U])) {
                {
                    // Inlined CFunc: _nba_sequent__TOP__2
                    if (vlSelfRef.__VdlySet__tb_core__DOT__dut__DOT__u_rf__DOT__regs__v0) {
                        vlSelfRef.tb_core__DOT__dut__DOT__u_rf__DOT__regs[vlSelfRef.__VdlyDim0__tb_core__DOT__dut__DOT__u_rf__DOT__regs__v0] 
                            = vlSelfRef.__VdlyVal__tb_core__DOT__dut__DOT__u_rf__DOT__regs__v0;
                    }
                    if (vlSelfRef.__VdlySet__tb_core__DOT__rst_n__v0) {
                        vlSelfRef.__VdlySet__tb_core__DOT__rst_n__v0 = 0U;
                        vlSelfRef.tb_core__DOT__rst_n = 1U;
                    }
                    if (vlSelfRef.__VdlySet__tb_core__DOT__mem__v0) {
                        vlSelfRef.tb_core__DOT__mem[vlSelfRef.__VdlyDim0__tb_core__DOT__mem__v0] 
                            = ((0xffffff00U & vlSelfRef.tb_core__DOT__mem
                                [vlSelfRef.__VdlyDim0__tb_core__DOT__mem__v0]) 
                               | (IData)(vlSelfRef.__VdlyVal__tb_core__DOT__mem__v0));
                    }
                    if (vlSelfRef.__VdlySet__tb_core__DOT__mem__v1) {
                        vlSelfRef.tb_core__DOT__mem[vlSelfRef.__VdlyDim0__tb_core__DOT__mem__v1] 
                            = ((0xffff00ffU & vlSelfRef.tb_core__DOT__mem
                                [vlSelfRef.__VdlyDim0__tb_core__DOT__mem__v1]) 
                               | ((IData)(vlSelfRef.__VdlyVal__tb_core__DOT__mem__v1) 
                                  << 8U));
                    }
                    if (vlSelfRef.__VdlySet__tb_core__DOT__mem__v2) {
                        vlSelfRef.tb_core__DOT__mem[vlSelfRef.__VdlyDim0__tb_core__DOT__mem__v2] 
                            = ((0xff00ffffU & vlSelfRef.tb_core__DOT__mem
                                [vlSelfRef.__VdlyDim0__tb_core__DOT__mem__v2]) 
                               | ((IData)(vlSelfRef.__VdlyVal__tb_core__DOT__mem__v2) 
                                  << 0x00000010U));
                    }
                    if (vlSelfRef.__VdlySet__tb_core__DOT__mem__v3) {
                        vlSelfRef.tb_core__DOT__mem[vlSelfRef.__VdlyDim0__tb_core__DOT__mem__v3] 
                            = ((0x00ffffffU & vlSelfRef.tb_core__DOT__mem
                                [vlSelfRef.__VdlyDim0__tb_core__DOT__mem__v3]) 
                               | ((IData)(vlSelfRef.__VdlyVal__tb_core__DOT__mem__v3) 
                                  << 0x00000018U));
                    }
                }
            }
            if ((3ULL & vlSelfRef.__VnbaTriggered[0U])) {
                {
                    // Inlined CFunc: _act_sequent__TOP__0
                    if (vlSelfRef.tb_core__DOT__rst_n) {
                        if (VL_UNLIKELY(((0x00001000U 
                                          <= vlSelfRef.tb_core__DOT__dut__DOT__pc)))) {
                            VL_WRITEF_NX("[%0t] %%Fatal: tb-core.sv:102: Assertion failed in %m: FAIL: instruction fetch out of range: %08h\n",4, 'M',vlSymsp->name(),"tb_core", 'T',-9
                                         , '#',64,VL_TIME_UNITED_Q(1000)
                                         , '#',32,vlSelfRef.tb_core__DOT__dut__DOT__pc);
                            VL_STOP_MT("tb-core.sv", 102, "", false);
                        }
                        if (VL_UNLIKELY(((0U != (3U 
                                                 & vlSelfRef.tb_core__DOT__dut__DOT__pc))))) {
                            VL_WRITEF_NX("[%0t] %%Fatal: tb-core.sv:104: Assertion failed in %m: FAIL: misaligned instruction fetch: %08h\n",4, 'M',vlSymsp->name(),"tb_core", 'T',-9
                                         , '#',64,VL_TIME_UNITED_Q(1000)
                                         , '#',32,vlSelfRef.tb_core__DOT__dut__DOT__pc);
                            VL_STOP_MT("tb-core.sv", 104, "", false);
                        }
                    }
                    vlSelfRef.tb_core__DOT__dut__DOT__load_byte 
                        = (0x000000ffU & (vlSelfRef.tb_core__DOT__mem
                                          [(0x000003ffU 
                                            & (vlSelfRef.tb_core__DOT__dut__DOT__alu_q 
                                               >> 2U))] 
                                          >> (0x00000018U 
                                              & (vlSelfRef.tb_core__DOT__dut__DOT__alu_q 
                                                 << 3U))));
                    vlSelfRef.tb_core__DOT__dut__DOT__load_half 
                        = (0x0000ffffU & ((2U & vlSelfRef.tb_core__DOT__dut__DOT__alu_q)
                                           ? (vlSelfRef.tb_core__DOT__mem
                                              [(0x000003ffU 
                                                & (vlSelfRef.tb_core__DOT__dut__DOT__alu_q 
                                                   >> 2U))] 
                                              >> 0x00000010U)
                                           : vlSelfRef.tb_core__DOT__mem
                                          [(0x000003ffU 
                                            & (vlSelfRef.tb_core__DOT__dut__DOT__alu_q 
                                               >> 2U))]));
                }
            }
        }
        Vtb_core___024root___trigger_clear__act(vlSelfRef.__VnbaTriggered);
    }
    return (__VnbaExecute);
}

void Vtb_core___024root___eval(Vtb_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_core___024root___eval\n"); );
    Vtb_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ __VnbaIterCount;
    // Body
    __VnbaIterCount = 0U;
    do {
        if (VL_UNLIKELY(((0x00002710U < __VnbaIterCount)))) {
#ifdef VL_DEBUG
            Vtb_core___024root___dump_triggers__act(vlSelfRef.__VnbaTriggered, "nba"s);
#endif
            VL_FATAL_MT("tb-core.sv", 18, "", "DIDNOTCONVERGE: NBA region did not converge after '--converge-limit' of 10000 tries");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        vlSelfRef.__VinactIterCount = 0U;
        do {
            if (VL_UNLIKELY(((0x00002710U < vlSelfRef.__VinactIterCount)))) {
                VL_FATAL_MT("tb-core.sv", 18, "", "DIDNOTCONVERGE: Inactive region did not converge after '--converge-limit' of 10000 tries");
            }
            vlSelfRef.__VinactIterCount = ((IData)(1U) 
                                           + vlSelfRef.__VinactIterCount);
            vlSelfRef.__VactIterCount = 0U;
            do {
                if (VL_UNLIKELY(((0x00002710U < vlSelfRef.__VactIterCount)))) {
#ifdef VL_DEBUG
                    Vtb_core___024root___dump_triggers__act(vlSelfRef.__VactTriggered, "act"s);
#endif
                    VL_FATAL_MT("tb-core.sv", 18, "", "DIDNOTCONVERGE: Active region did not converge after '--converge-limit' of 10000 tries");
                }
                vlSelfRef.__VactIterCount = ((IData)(1U) 
                                             + vlSelfRef.__VactIterCount);
                vlSelfRef.__VactPhaseResult = Vtb_core___024root___eval_phase__act(vlSelf);
            } while (vlSelfRef.__VactPhaseResult);
            vlSelfRef.__VinactPhaseResult = Vtb_core___024root___eval_phase__inact(vlSelf);
        } while (vlSelfRef.__VinactPhaseResult);
        vlSelfRef.__VnbaPhaseResult = Vtb_core___024root___eval_phase__nba(vlSelf);
    } while (vlSelfRef.__VnbaPhaseResult);
}

void Vtb_core___024root____VbeforeTrig_h5e18bfa5__0(Vtb_core___024root* vlSelf, const char* __VeventDescription) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_core___024root____VbeforeTrig_h5e18bfa5__0\n"); );
    Vtb_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    VlUnpacked<QData/*63:0*/, 1> __VTmp;
    // Body
    __VTmp[0U] = (QData)((IData)(((IData)(vlSelfRef.tb_core__DOT__clk) 
                                  & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__tb_core__DOT__clk__0)))));
    vlSelfRef.__Vtrigprevexpr___TOP__tb_core__DOT__clk__0 
        = vlSelfRef.tb_core__DOT__clk;
    if ((1ULL & __VTmp[0U])) {
        vlSelfRef.__VtrigSched_h5e18bfa5__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h5e18bfa5__0.ready(__VeventDescription);
    }
    vlSelfRef.__VactTriggeredAcc[0U] = (vlSelfRef.__VactTriggeredAcc[0U] 
                                        | __VTmp[0U]);
}

#ifdef VL_DEBUG
void Vtb_core___024root___eval_debug_assertions(Vtb_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_core___024root___eval_debug_assertions\n"); );
    Vtb_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}
#endif  // VL_DEBUG
