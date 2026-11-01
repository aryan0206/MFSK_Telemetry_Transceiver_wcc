# Official submission audit — Group 5, Question 5

**Date:** 1 November 2026  
**Subject:** ICT 3128 Wireless Communication and Computing  
**Project:** MFSK Telemetry Transceiver under AWGN and Narrowband Interference

## Completed project and ownership

The repository contains a complete transmitter → channel → receiver → packet validation → BER/PER measurement chain for 4-FSK and 8-FSK. The signed 32-page consolidated report contains handwritten sections for all four assigned parts. Its cover identifies B Rashmi Kini (240953568) for Q5(A), Aryan Malik (240953668) for Q5(B), Ayati Rauthan (240953138) for Q5(C), and Akshat Mannur (240953634) for Q5(D). These four registration numbers exactly match the source payload, which sends them in the order Aryan, Rashmi, Ayati, Akshat.

Akshat's handwritten Q5(D) section is present and signed. His original analysis scripts and numerical data were not supplied. Ayati's Q5(C) final dataset reproduces the signed report's cited BER/PER examples; this audit does not attribute Ayati's source or the supplementary experiment to Akshat.

## Technical architecture and verified interfaces

Q5(A) generates a 39-byte ASCII payload, `A5 5A` preamble, `0x27` length byte and two-byte CRC-16/CCITT-FALSE (high byte first), giving 44 bytes/352 bits. Bytes and symbol mapping are MSB first. 4-FSK has 176 symbols without pad bits; 8-FSK has 118 symbols with two trailing zero pad bits. The transmitter uses Fs=24,000 Hz, Rs=300 symbols/s, 80 samples/symbol, 3,000 Hz center and 300 Hz tone spacing.

Q5(B) accepts the real passband waveform directly and adds AWGN plus a continuous sine jammer. Its Eb/N0 uses gross mapped-bit energy, and JSR uses jammer/clean-signal power. The historical calibration runner covers 160 conditions with 4-FSK/8-FSK, Eb/N0 0:2:14 dB, AWGN-only plus three JSRs at three placements. Its CSV/MAT/figures describe channel powers and waveforms, **not BER/PER**.

The Q5(B) MAT configuration records the input MAT filename without a machine-specific absolute path. The calibration script was rerun after this metadata-only change, preserving its 160-case coverage and numerical channel method.

Ayati's Q5(C) path uses `prepare_mfsk_detector`, `mfsk_detect`, `decode_telemetry_frame`, CRC checking and `evaluate_telemetry_trial`. It searches the preamble with at most two bit mismatches, then accepts a CRC-valid frame. Known tones and symbol timing are specifications; frame position is searched. `run_q5c_receiver('final')` saved 160 conditions × 1,000 trials = 160,000 packets and 49,920,000 payload-bit decisions. The original final dataset records a full-run repeat check. After replacing a Git-revision probe and Java-only hash dependency with no-Git .NET SHA-256 metadata, MATLAB R2026b tests passed **15/15**. The hash change does not alter receiver decisions or BER/PER calculations.

## Signed report and official format

The team confirmed `WCC_Group5.pdf` as the authoritative signed report. `submission/G05_Q5.pdf` is its byte-for-byte copy with the group/question filename; both files have SHA-256 `B0C211DF8535DA038DBB2C3E2C4F314469C56D713F47C47523C62A22A144ABDE`. The original 32 pages and handwritten signatures were not edited. The cover says 25 October 2026, while this repository package is dated 1 November 2026; the cover date is preserved as part of the signed source.

The official `ICT3128_Group-Assignment_Project_Questions (2).pdf` assignment sheet specifies **one PDF and one ZIP of experiment files**, uploaded by the team lead by **1 November 2026, 5:00 PM**. The older group execution guide's 25 October deadline does not govern this final package. `submission/G05_Q5_files.zip` contains the experiment source, tests, numerical data, figures and supporting documents. Aryan performs the actual upload.

## PDF-to-repository cross-check

The PDF cover details, packet/CRC values, tone banks, symbol settings, Q5(B) 160-case grid and its example case 35 agree with the repository. Its receiver description matches Ayati's newly supplied Q5(C) source, including the two-bit preamble tolerance. Its cited 8 dB AWGN counts **565/312,000 and 48/312,000** and PER **0.361 and 0.027** match `results/Q5C/final/summary.csv`. The separate `results/Q5_end_to_end/` dataset uses a different exact-sync receiver and seed plan; its numbers must not be substituted for the signed-report measurements.

The signed report's 1,500/2,700 Hz approximate bandwidth values come from tone span plus two symbol rates. The repository separately measures equal-tail 99% FFT power spans near 5,399 Hz for each M; the definitions differ. See `FINAL_TEST_AND_EXPERIMENT_EVIDENCE.md` for methods and exact data.

## Submission disposition

All four assigned report sections and the integrated MATLAB project are present. Ayati's source and final data now provide a direct technical match for the signed receiver and BER/PER examples. Akshat's original Q5(D) scripts/data remain unconfirmed beyond his signed handwritten section. The signed PDF is preserved exactly; the official PDF and experiment ZIP are ready for the team lead's upload.
