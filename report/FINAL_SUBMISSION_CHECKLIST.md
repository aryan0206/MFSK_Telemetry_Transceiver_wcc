# Official submission checklist — Group 5, Question 5 — 1 November 2026

## Verified in this repository

- [x] 4-FSK and 8-FSK transmitter source, clean MAT waveforms and three figures.
- [x] Packet field lengths, MSB-first mapping, 8-FSK padding and CRC convention checked against source and MATLAB output.
- [x] AWGN plus single-tone jammer with 8 Eb/N0 values, 3 JSRs and 3 placements for each M.
- [x] Q5(B) calibration data distinguished from receiver BER/PER.
- [x] Ayati's integrated detector, two-mismatch preamble search, CRC checking and payload recovery.
- [x] MATLAB tests for channel calibration, clean reception, guarded frame starts and corruption detection: 15 passed, 0 failed.
- [x] Signed-report Q5(C) BER/PER sweep with 160,000 packets, saved counts, seeds and denominators.
- [x] Numerical 99% FFT power bandwidth from the actual transmitted vectors.
- [x] README, source inventory, audit and technical report source.

## Signed report and delivery files

- [x] All four assigned sections are represented in the signed report; the repository contains an integrated A–D simulation and analysis chain.
- [x] Signed consolidated report confirmed by the team and copied byte-for-byte to `submission/G05_Q5.pdf`.
- [x] Cover identifies ICT 3128, Wireless Communication and Computing, Section A, Group 5, Question 5, all four names and registration numbers.
- [x] Handwritten A–D sections, member signatures and simulation figures inspected across the 32-page report.
- [x] Official assignment sheet checked: submit one PDF named for group/question and one ZIP of experiment files by 1 November 2026, 5:00 PM; only the team lead uploads.
- [x] Matching Q5(C) results, source, tests and documents included in `submission/G05_Q5_files.zip`; Akshat's original Q5(D) scripts/data were not supplied.
- [x] ZIP contents and PDF hash checked against the repository and confirmed signed source.

## Package to retain

Upload exactly `submission/G05_Q5.pdf` and `submission/G05_Q5_files.zip`. The ZIP includes runnable `src/`, `experiments/`, `tests/`, transmitter outputs, Q5(B) calibration evidence, signed-report `results/Q5C/final/`, and the official documentation. Ayati's smoke data, old handoff notes and the separate exact-sync comparison outputs remain in the repository but are excluded from the official ZIP. The signed PDF is supplied separately. The team lead performs the actual upload.
