# MFSK Telemetry Transceiver — ICT 3128, Question 5

Group 5 MATLAB R2026b simulation of a registration-derived telemetry packet sent by 4-FSK or 8-FSK through AWGN and a single-tone interferer. The signed-report signal path is `Project5A_Transmitter.m` → `apply_channel.m` → Ayati's `mfsk_detect.m` and `decode_telemetry_frame.m` → `evaluate_telemetry_trial.m` → `run_q5c_receiver.m`. The signed consolidated report is `submission/G05_Q5.pdf`.

## Team contributions

| Member | Registration number | Completed contribution |
| --- | --- | --- |
| B Rashmi Kini | 240953568 | Q5(A): transmitter, framing, modulation and plots |
| Aryan Malik | 240953668 | Q5(B): AWGN and narrowband interference channel, sweep and integration |
| Ayati Rauthan | 240953138 | Q5(C): receiver, synchronization, CRC and recovery |
| Akshat Mannur | 240953634 | Q5(D): handwritten comparison and engineering decision in the signed report |

Names and registration numbers follow the signed report cover. The four handwritten sections are present. Ayati's receiver source, tests and matching final dataset are included. Akshat's original Q5(D) scripts/data were not supplied; his signed handwritten analysis is present, and the verified Q5(C) dataset supports its cited examples.

## Packet and waveform

The payload is the ASCII text `240953668|240953568|240953138|240953634` (39 bytes). The 44-byte packet is `A5 5A | 27 | 39 payload bytes | CRC high | CRC low`. CRC-16/CCITT-FALSE covers the length byte and payload, using polynomial `0x1021`, initial value `0xFFFF`, no reflection and no final XOR. Bytes and tone indices use most-significant-bit-first order. The frame is 352 bits; 4-FSK maps two bits per symbol without padding, while 8-FSK maps three bits per symbol with two trailing zero padding bits.

The transmitter uses `Fs=24000` samples/s, `Rs=300` symbols/s, 80 samples/symbol, `fc=3000` Hz and 300 Hz tone spacing. The real sine phase restarts at each symbol. 4-FSK tones are 2550–3450 Hz; 8-FSK tones are 1950–4050 Hz. Gross rates are 600 and 900 bits/s. The source's `tone span + 2/Ts` values (1500 and 2700 Hz) are approximate main-lobe spans, **not measured occupied bandwidth**.

## Channel and receiver

The channel returns `rx=tx+noise+jammer`, with deterministic private random seeds. For clean average power `Ps`, gross bit rate `Rb=Rs*log2(M)` and requested Eb/N0, it uses sample noise variance `Ps*Fs/(2*Rb*10^(EbN0dB/10))`. The jammer is a continuous sampled sine scaled to the requested finite-record `JSR=10log10(Pj/Ps)`.

Ayati's receiver scores each known tone by noncoherent correlation energy over 80-sample symbols, selects the highest score, converts symbols to MSB-first bits, searches for `A5 5A` with at most two preamble-bit mismatches, then checks decoded length and CRC. It assumes the tone bank and symbol timing are known; frame position is searched. The evaluator alone uses the transmitted payload and true frame location.

## Run in MATLAB R2026b

Open MATLAB in the repository root and run:

```matlab
run(fullfile(pwd,'src','Project5A_Transmitter.m'))
r = runtests('tests');
assertSuccess(r)
addpath('experiments')
measure_occupied_bandwidth
run_q5b_channel                 % historical channel calibration, 160 cases
run_q5c_receiver('final',fullfile(pwd,'results','Q5C','reproduction'))
```

The transmitter writes `results/transmitter_data.mat` and three PNGs. `measure_occupied_bandwidth` saves an equal-tail 99% FFT power-span table. Q5(B) writes channel powers and four demonstration PNGs to `results/Q5B/`; these are **not BER/PER**. The signed-report receiver results are in `results/Q5C/final/`, including `summary.csv`, MAT data and BER/PER plots for both M values. Use a fresh output directory for a new full run because Q5(C) checkpoints are tied to source/configuration hashes. `results/Q5_end_to_end/` is a separate supplementary run using a different receiver and seed plan; it must not be substituted for the signed-report figures. Zero observed errors are finite-sample observations.

## Measured comparison and design context

The signed-report sweep covers 160 conditions, 1,000 packets per condition and 49,920,000 payload-bit decisions. At Eb/N0 8 dB with AWGN only, Q5(C) measured PER **0.361 for 4-FSK** and **0.027 for 8-FSK**. At Eb/N0 10 dB and JSR 0 dB, an on-tone jammer gives PER 1.000 for both. The signed report weighs 4-FSK's narrower 900 Hz tone-center span against 8-FSK's higher 900 bit/s gross rate and measured AWGN advantage. Tone-center span is not occupied bandwidth: the separately measured equal-tail 99% FFT spans are 5,399.23 and 5,399.60 Hz. See the evidence report for counts and the PDF cross-check.

## Submission package

The official assignment sheet specifies one PDF named for the group and question plus one ZIP of experiment files, uploaded by the team lead. `submission/G05_Q5.pdf` is an unchanged copy of the team-confirmed signed report. `submission/G05_Q5_files.zip` contains the runnable source, tests, generated results and supporting documentation. See `report/FINAL_TEST_AND_EXPERIMENT_EVIDENCE.md` for measured outcomes and the numerical cross-check with the signed PDF. The simulation assumes known tone frequencies and symbol timing; these are stated receiver specifications.
