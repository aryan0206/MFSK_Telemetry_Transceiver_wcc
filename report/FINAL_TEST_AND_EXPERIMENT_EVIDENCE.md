# Final test and experiment evidence — 1 November 2026

## MATLAB execution and test result

MATLAB R2026b generated the transmitter packet and figures, 160 Q5(B) channel-calibration cases, and an independent supplementary end-to-end sweep. Ayati's supplied Q5(C) final run records 160 conditions, 1,000 packet trials per condition, **160,000 packets and 49,920,000 evaluated payload bits**. Its `reproducibility.txt` states that all 160,000 per-trial records reproduced exactly in a second complete run. The saved execution log records the original Q5(C) run.

After the pull, the complete local `runtests('tests')` run in MATLAB R2026b reported **15 passed, 0 failed, 0 incomplete**. It includes Q5(B) calibration, the supplementary clean/corrupt end-to-end test, and Ayati's CRC, mapping, phase-insensitive detection, preamble tolerance, frame search, corruption, evaluator, Wilson interval and checkpoint-resume tests. The Q5(C) runner's metadata helper was changed to avoid any Git command and use validated .NET SHA-256 because this MATLAB installation has no Java runtime. The receiver and metric algorithms were preserved.

## Signed-report Q5(C) dataset

`results/Q5C/final/summary.csv` is the numerical source corresponding to the handwritten PDF. Each of its 160 rows records modulation, Eb/N0, JSR, jammer placement, 1,000 frames, 312,000 payload bits, errors, BER/PER, Wilson PER bounds and failure categories. `trial_outcomes.mat`, 160 checkpoints, configuration, recovery demonstration, diagnostics, zero-error observations and BER/PER figures provide reproducibility and visual evidence. The receiver assumes known tones and symbol timing but searches unknown frame position with at most two preamble-bit mismatches. Only the evaluator uses the true payload and frame location.

| Signed-report condition | M | Bit errors / 312,000 | Packet failures / 1,000 | BER | PER |
| --- | ---: | ---: | ---: | ---: | ---: |
| AWGN, Eb/N0 8 dB | 4 | 565 | 361 | 0.0018108974 | 0.361 |
| AWGN, Eb/N0 8 dB | 8 | 48 | 27 | 0.0001538462 | 0.027 |
| AWGN, Eb/N0 10 dB | 4 | 12 | 10 | 0.0000384615 | 0.010 |
| AWGN, Eb/N0 10 dB | 8 | 0 | 0 | 0 | 0 |
| On tone, JSR 0 dB, Eb/N0 10 dB | 4 | 74,600 | 1,000 | 0.2391025641 | 1.000 |
| On tone, JSR 0 dB, Eb/N0 10 dB | 8 | 84,034 | 1,000 | 0.2693397436 | 1.000 |

The 8 dB AWGN counts and PERs match the signed PDF's handwritten receiver section. Q5(C)'s final CSV also supports its 160-condition and 49,920,000-bit totals. Akshat's original Q5(D) source/data were not supplied; his handwritten section is present, and the Q5(C) dataset supports its core trends, but attribution of a separate D implementation is unconfirmed. A few handwritten rounded examples may differ from exact CSV values; use the CSV for precise numbers.

## Other result classes

`results/Q5B/` contains 160 channel-calibration cases, power tables and representative waveform/spectrum figures. It measures channel powers, **not BER/PER**. Signed-report Q5(B) case 35 matches the CSV: M=4, Eb/N0=6 dB, JSR=0 dB, 2,850 Hz on-tone jammer, target noise power 2.511886 and measured noise power 2.412941.

`results/Q5_end_to_end/` contains a separate 160-condition, 1,000-trial receiver sweep made before Ayati's files arrived. It uses an exact-sync receiver and different seeds. Its counts differ from the signed report by design and are not the final PDF's experimental source. The two datasets are labeled separately in the repository.

`results/occupied_bandwidth_99pct.csv` reports equal-tail 99% FFT power spans of **5,399.23 Hz (4-FSK)** and **5,399.60 Hz (8-FSK)**. The signed report's 1,500/2,700 Hz values are explicitly approximate main-lobe spans from a different definition; its 900/2,100 Hz tone-center spans are different again. Zero observed errors in a finite run do not establish zero true error probability.
