#!/bin/python3

# reads IQ samples from uart and plots them
import serial
import matplotlib.pyplot as plt
import numpy as np


PORT = "/dev/ttyUSB1"
BAUD = 1e6 #115200
SAMP_CNT = 40000 - 1
FS = 8e6

with serial.Serial(PORT, int(BAUD), timeout=None) as ser:
    data = ser.read(SAMP_CNT * 2)

samples = np.frombuffer(data, dtype=np.int8)


# samples = np.fromfile("../test_samples.bin", dtype=np.int8, count=SAMP_CNT+1)


# Deinterleave and create complex signal
i_samples = samples[1::2].astype(float)
q_samples = samples[0::2].astype(float)
complex_samples = i_samples + 1j * q_samples

# Compute FFT
# use fftshift to move 0 Hz to the center of the plot
fft_data = np.fft.fftshift(np.fft.fft(complex_samples))
freqs = np.fft.fftshift(np.fft.fftfreq(len(complex_samples), d=1/FS))

# Convert to Decibels (Power)
psd = 20 * np.log10(np.abs(fft_data) + 1e-6) # Added small constant to avoid log(0)

# Plot
fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10, 8))
plt.subplots_adjust(hspace=0.4)

# Time Domain
ax1.plot(i_samples, label="I")
ax1.plot(q_samples, label="Q")
ax1.set_title("FPGA Captured I/Q Samples")
ax1.set_xlabel("Sample Index")
ax1.set_ylabel("Amplitude")
ax1.set_ylim(-150, 150)
ax1.grid(True)
ax1.legend()

# Frequency Domain
ax2.plot(freqs / 1e3, psd) # x-axis in kHz
ax2.set_title("FPGA Captured Frequency Domain")
ax2.set_xlabel("Frequency (kHz)")
ax2.set_ylabel("Magnitude (dB)")
ax2.grid(True)

plt.show()


