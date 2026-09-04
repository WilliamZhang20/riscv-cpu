// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_core.h for the primary calling header

#include "Vtb_core__pch.h"

void Vtb_core___024root___timing_ready(Vtb_core___024root* vlSelf);

VL_ATTR_COLD void Vtb_core___024root___eval_static(Vtb_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_core___024root___eval_static\n"); );
    Vtb_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__Vtrigprevexpr___TOP__tb_core__DOT__clk__0 
        = vlSelfRef.tb_core__DOT__clk;
    vlSelfRef.__Vtrigprevexpr___TOP__tb_core__DOT__rst_n__0 
        = vlSelfRef.tb_core__DOT__rst_n;
    Vtb_core___024root___timing_ready(vlSelf);
    do {
        vlSelfRef.__VactTriggeredAcc[vlSelfRef.__Vi] 
            = vlSelfRef.__VactTriggered[vlSelfRef.__Vi];
        vlSelfRef.__Vi = ((IData)(1U) + vlSelfRef.__Vi);
    } while ((0U >= vlSelfRef.__Vi));
}

VL_ATTR_COLD void Vtb_core___024root___eval_final(Vtb_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_core___024root___eval_final\n"); );
    Vtb_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_core___024root___dump_triggers__stl(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG
VL_ATTR_COLD bool Vtb_core___024root___eval_phase__stl(Vtb_core___024root* vlSelf);

VL_ATTR_COLD void Vtb_core___024root___eval_settle(Vtb_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_core___024root___eval_settle\n"); );
    Vtb_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ __VstlIterCount;
    // Body
    __VstlIterCount = 0U;
    vlSelfRef.__VstlFirstIteration = 1U;
    do {
        if (VL_UNLIKELY(((0x00002710U < __VstlIterCount)))) {
#ifdef VL_DEBUG
            Vtb_core___024root___dump_triggers__stl(vlSelfRef.__VstlTriggered, "stl"s);
#endif
            VL_FATAL_MT("tb-core.sv", 18, "", "DIDNOTCONVERGE: Settle region did not converge after '--converge-limit' of 10000 tries");
        }
        __VstlIterCount = ((IData)(1U) + __VstlIterCount);
        vlSelfRef.__VstlPhaseResult = Vtb_core___024root___eval_phase__stl(vlSelf);
        vlSelfRef.__VstlFirstIteration = 0U;
    } while (vlSelfRef.__VstlPhaseResult);
}

VL_ATTR_COLD bool Vtb_core___024root___trigger_anySet__stl(const VlUnpacked<QData/*63:0*/, 1> &in);

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_core___024root___dump_triggers__stl(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_core___024root___dump_triggers__stl\n"); );
    // Body
    if ((1U & (~ (IData)(Vtb_core___024root___trigger_anySet__stl(triggers))))) {
        VL_DBG_MSGS("         No '" + tag + "' region triggers active\n");
    }
    if ((1U & (IData)(triggers[0U]))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD bool Vtb_core___024root___trigger_anySet__stl(const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_core___024root___trigger_anySet__stl\n"); );
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

VL_ATTR_COLD void Vtb_core___024root___stl_sequent__TOP__0(Vtb_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_core___024root___stl_sequent__TOP__0\n"); );
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
    // Body
    if (vlSelfRef.tb_core__DOT__rst_n) {
        if (VL_UNLIKELY(((0x00001000U <= vlSelfRef.tb_core__DOT__dut__DOT__pc)))) {
            VL_WRITEF_NX("[%0t] %%Fatal: tb-core.sv:102: Assertion failed in %m: FAIL: instruction fetch out of range: %08h\n",4, 'M',vlSymsp->name(),"tb_core", 'T',-9
                         , '#',64,VL_TIME_UNITED_Q(1000)
                         , '#',32,vlSelfRef.tb_core__DOT__dut__DOT__pc);
            VL_STOP_MT("tb-core.sv", 102, "", false);
        }
        if (VL_UNLIKELY(((0U != (3U & vlSelfRef.tb_core__DOT__dut__DOT__pc))))) {
            VL_WRITEF_NX("[%0t] %%Fatal: tb-core.sv:104: Assertion failed in %m: FAIL: misaligned instruction fetch: %08h\n",4, 'M',vlSymsp->name(),"tb_core", 'T',-9
                         , '#',64,VL_TIME_UNITED_Q(1000)
                         , '#',32,vlSelfRef.tb_core__DOT__dut__DOT__pc);
            VL_STOP_MT("tb-core.sv", 104, "", false);
        }
    }
    vlSelfRef.__VdfgRegularize_h6e95ff9d_0_1 = ((IData)(4U) 
                                                + vlSelfRef.tb_core__DOT__dut__DOT__pc);
    vlSelfRef.__VdfgRegularize_h6e95ff9d_0_2 = (0x000fffffU 
                                                & (- (IData)(
                                                             (vlSelfRef.tb_core__DOT__dut__DOT__ir 
                                                              >> 0x0000001fU))));
    vlSelfRef.tb_core__DOT__dut__DOT__load_byte = (0x000000ffU 
                                                   & (vlSelfRef.tb_core__DOT__mem
                                                      [
                                                      (0x000003ffU 
                                                       & (vlSelfRef.tb_core__DOT__dut__DOT__alu_q 
                                                          >> 2U))] 
                                                      >> 
                                                      (0x00000018U 
                                                       & (vlSelfRef.tb_core__DOT__dut__DOT__alu_q 
                                                          << 3U))));
    vlSelfRef.tb_core__DOT__dut__DOT__load_half = (0x0000ffffU 
                                                   & ((2U 
                                                       & vlSelfRef.tb_core__DOT__dut__DOT__alu_q)
                                                       ? 
                                                      (vlSelfRef.tb_core__DOT__mem
                                                       [
                                                       (0x000003ffU 
                                                        & (vlSelfRef.tb_core__DOT__dut__DOT__alu_q 
                                                           >> 2U))] 
                                                       >> 0x00000010U)
                                                       : vlSelfRef.tb_core__DOT__mem
                                                      [
                                                      (0x000003ffU 
                                                       & (vlSelfRef.tb_core__DOT__dut__DOT__alu_q 
                                                          >> 2U))]));
    vlSelfRef.tb_core__DOT__dut__DOT__pc_en = ((~ (IData)(vlSelfRef.tb_core__DOT__dut__DOT__illegal_q)) 
                                               & (4U 
                                                  == (IData)(vlSelfRef.tb_core__DOT__dut__DOT__state)));
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

VL_ATTR_COLD bool Vtb_core___024root___eval_phase__stl(Vtb_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_core___024root___eval_phase__stl\n"); );
    Vtb_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VstlExecute;
    // Body
    {
        // Inlined CFunc: _eval_triggers_vec__stl
        vlSelfRef.__VstlTriggered[0U] = ((0xfffffffffffffffeULL 
                                          & vlSelfRef.__VstlTriggered[0U]) 
                                         | (IData)((IData)(vlSelfRef.__VstlFirstIteration)));
    }
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vtb_core___024root___dump_triggers__stl(vlSelfRef.__VstlTriggered, "stl"s);
    }
#endif
    __VstlExecute = Vtb_core___024root___trigger_anySet__stl(vlSelfRef.__VstlTriggered);
    if (__VstlExecute) {
        {
            // Inlined CFunc: _eval_stl
            if ((1ULL & vlSelfRef.__VstlTriggered[0U])) {
                Vtb_core___024root___stl_sequent__TOP__0(vlSelf);
            }
        }
    }
    return (__VstlExecute);
}

bool Vtb_core___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in);

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_core___024root___dump_triggers__act(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_core___024root___dump_triggers__act\n"); );
    // Body
    if ((1U & (~ (IData)(Vtb_core___024root___trigger_anySet__act(triggers))))) {
        VL_DBG_MSGS("         No '" + tag + "' region triggers active\n");
    }
    if ((1U & (IData)(triggers[0U]))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 0 is active: @(posedge tb_core.clk)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 1U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 1 is active: @(negedge tb_core.rst_n)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 2U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 2 is active: @([true] __VdlySched.awaitingCurrentTime())\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vtb_core___024root___ctor_var_reset(Vtb_core___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_core___024root___ctor_var_reset\n"); );
    Vtb_core__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    const uint64_t __VscopeHash = VL_MURMUR64_HASH(vlSelf->vlNamep);
    vlSelf->tb_core__DOT__clk = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6610376131445473662ull);
    vlSelf->tb_core__DOT__rst_n = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9966589053022997338ull);
    vlSelf->tb_core__DOT__dmem_wdata = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 12218024966821269723ull);
    vlSelf->tb_core__DOT__dmem_we = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 5700019998534802524ull);
    vlSelf->tb_core__DOT__dmem_be = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 6704198769637612150ull);
    for (int __Vi0 = 0; __Vi0 < 1024; ++__Vi0) {
        vlSelf->tb_core__DOT__mem[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 15544938265557929054ull);
    }
    vlSelf->tb_core__DOT__cycles = 0;
    vlSelf->tb_core__DOT__retired = 0;
    vlSelf->tb_core__DOT__do_trace = 0;
    vlSelf->tb_core__DOT__maxcyc = 0;
    vlSelf->tb_core__DOT__dut__DOT__state = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 4494684597593262758ull);
    vlSelf->tb_core__DOT__dut__DOT__ir = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 16278939181577007003ull);
    vlSelf->tb_core__DOT__dut__DOT__rs1_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 8184604478157424974ull);
    vlSelf->tb_core__DOT__dut__DOT__rs2_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 6760486320186429722ull);
    vlSelf->tb_core__DOT__dut__DOT__imm_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 9695305443256233976ull);
    vlSelf->tb_core__DOT__dut__DOT__alu_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 16929228872819385474ull);
    vlSelf->tb_core__DOT__dut__DOT__take_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8394496576762862254ull);
    vlSelf->tb_core__DOT__dut__DOT__target_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 3966229763048896070ull);
    vlSelf->tb_core__DOT__dut__DOT__load_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 14990105246411790991ull);
    vlSelf->tb_core__DOT__dut__DOT__illegal_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1783586205449250367ull);
    vlSelf->tb_core__DOT__dut__DOT__pc = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 11829988500410995702ull);
    vlSelf->tb_core__DOT__dut__DOT__pc_en = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 17566906501007526652ull);
    vlSelf->tb_core__DOT__dut__DOT__d = VL_SCOPED_RAND_RESET_Q(39, __VscopeHash, 2630538851046045384ull);
    vlSelf->tb_core__DOT__dut__DOT__rf_wdata = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 4002760069644332194ull);
    vlSelf->tb_core__DOT__dut__DOT__alu_result = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 76167434086948303ull);
    vlSelf->tb_core__DOT__dut__DOT__load_byte = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 10873649643043071099ull);
    vlSelf->tb_core__DOT__dut__DOT__load_half = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 3573945999349962919ull);
    for (int __Vi0 = 0; __Vi0 < 32; ++__Vi0) {
        vlSelf->tb_core__DOT__dut__DOT__u_rf__DOT__regs[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 1366086999004496568ull);
    }
    vlSelf->tb_core__DOT__dut__DOT__u_rf__DOT__write_en = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 12448792820493405086ull);
    vlSelf->__VdfgRegularize_h6e95ff9d_0_1 = 0;
    vlSelf->__VdfgRegularize_h6e95ff9d_0_2 = 0;
    vlSelf->__VdlySet__tb_core__DOT__rst_n__v0 = 0;
    vlSelf->__VdlyVal__tb_core__DOT__mem__v0 = 0;
    vlSelf->__VdlyDim0__tb_core__DOT__mem__v0 = 0;
    vlSelf->__VdlySet__tb_core__DOT__mem__v0 = 0;
    vlSelf->__VdlyVal__tb_core__DOT__mem__v1 = 0;
    vlSelf->__VdlyDim0__tb_core__DOT__mem__v1 = 0;
    vlSelf->__VdlySet__tb_core__DOT__mem__v1 = 0;
    vlSelf->__VdlyVal__tb_core__DOT__mem__v2 = 0;
    vlSelf->__VdlyDim0__tb_core__DOT__mem__v2 = 0;
    vlSelf->__VdlySet__tb_core__DOT__mem__v2 = 0;
    vlSelf->__VdlyVal__tb_core__DOT__mem__v3 = 0;
    vlSelf->__VdlyDim0__tb_core__DOT__mem__v3 = 0;
    vlSelf->__VdlySet__tb_core__DOT__mem__v3 = 0;
    vlSelf->__VdlyVal__tb_core__DOT__dut__DOT__u_rf__DOT__regs__v0 = 0;
    vlSelf->__VdlyDim0__tb_core__DOT__dut__DOT__u_rf__DOT__regs__v0 = 0;
    vlSelf->__VdlySet__tb_core__DOT__dut__DOT__u_rf__DOT__regs__v0 = 0;
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VstlTriggered[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VactTriggered[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VactTriggeredAcc[__Vi0] = 0;
    }
    vlSelf->__Vtrigprevexpr___TOP__tb_core__DOT__clk__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__tb_core__DOT__rst_n__0 = 0;
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VnbaTriggered[__Vi0] = 0;
    }
    vlSelf->__Vi = 0;
}
