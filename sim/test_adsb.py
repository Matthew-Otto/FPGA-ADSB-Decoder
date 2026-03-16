#!/usr/bin/env python3

import os
from pathlib import Path
import numpy as np

import cocotb
from cocotb_tools.runner import get_runner
from cocotb.clock import Clock
from cocotb.triggers import Timer, ReadOnly, ReadWrite, ClockCycles, RisingEdge, FallingEdge
from cocotbext.axi import AxiLiteMasterWrite, AxiLiteSlaveWrite
from cocotbext.axi import AxiLiteWriteBus, AxiLiteReadBus, AxiLiteRamRead, AxiLiteRamWrite


def load_IQ_int8(filename):
    data = np.fromfile(filename, dtype=np.int8, count=8000000)
    i = data[0::2]
    q = data[1::2]
    return zip(i, q)


async def reset(clk, rst):
    await RisingEdge(clk)
    rst.value = 1
    await ClockCycles(clk, 5)
    rst.value = 0
    print("DUT reset")


@cocotb.test()
async def test_decode(dut):
    # load adsb signal
    filepath = Path(__file__).resolve().parent.parent / "test_samples.bin"
    sample_data = load_IQ_int8(filepath)

    # system clock 100 MHz
    cocotb.start_soon(Clock(dut.clk0, 10, unit="ns").start())
    # sample clock 8 Mhz
    cocotb.start_soon(Clock(dut.samp_clk, 125, unit="ns").start())
    await reset(dut.clk0, dut.reset)


    # pass samples @ 8 MHz
    for i, q in sample_data:
        dut.i.value = int(i)
        dut.q.value = int(q)
        await RisingEdge(dut.samp_clk)

    await ClockCycles(dut.samp_clk, 100)



def test_runner():
    top_module_name = "top"
    sim = get_runner("verilator")

    RTL_dir = Path(__file__).resolve().parent.parent / "RTL"
    sources = list(RTL_dir.glob("*.sv"))

    sim.build(
        sources=sources,
        hdl_toplevel=top_module_name,
        always=False,
        waves=True,
        build_args=[
            "-Wno-SELRANGE",
            "-Wno-WIDTH",
            "--trace-fst",
            "--trace-structs",
        ]
    )

    sim.test(
        hdl_toplevel=top_module_name,
        test_module=Path(__file__).stem,
        waves=True,
        gui=True
    )

if __name__ == "__main__":
    test_runner()