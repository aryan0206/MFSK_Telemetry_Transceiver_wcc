# Consolidated technical reference — Group 5, Question 5

This technical reference accompanies the signed report, `submission/G05_Q5.pdf`, and the runnable MATLAB files. The report cover identifies B Rashmi Kini (240953568), Aryan Malik (240953668), Ayati Rauthan (240953138) and Akshat Mannur (240953634). All four handwritten sections are present. Ayati's Q5(C) source and final dataset are included and match the signed receiver results. Akshat's original Q5(D) scripts/data were not supplied; authorship of the repository's supplementary analysis is not attributed to him. The repository documentation is dated 1 November 2026; the signed report cover retains its original 25 October 2026 date.

## Objective and system diagram

Transmit registration-derived telemetry with orthogonal 4-FSK and 8-FSK through AWGN and single-tone narrowband interference, recover the payload and compare reliability. The implemented flow is:

`ASCII payload → A5 5A sync + length + payload + CRC → MSB-first MFSK tones → AWGN + sine jammer → tone-energy detector → symbol-aligned sync search → length/CRC check → recovered payload → BER/PER evaluator`.

## Q5(A): transmitter

The four registration strings are joined with `|`, giving a 39-byte ASCII payload. The length field is hexadecimal `27`. The packet is 2 sync bytes, 1 length byte, 39 payload bytes and 2 CRC bytes: 44 bytes or 352 bits. CRC-16/CCITT-FALSE covers the length and payload; its polynomial is `0x1021`, initial register `0xFFFF`, no reflection, no final XOR. The high CRC byte is sent first. The current payload yields CRC `A327` in MATLAB. The receiver checks a separate standard vector, `123456789 → 29B1`.

With symbol rate `Rs=300` symbols/s and `k=log2(M)`, gross mapped-bit rates are `Rb=kRs`: 600 bit/s for 4-FSK and 900 bit/s for 8-FSK. `Fs=24000` Hz gives 80 samples/symbol. Tones use `f_i=3000+(i-(M-1)/2)300` Hz, for `i=0,...,M-1`. 4-FSK maps 176 symbols; 8-FSK needs two zero pad bits and maps 118 symbols. The waveform is a real sine with phase restarted at each symbol. Q5(A)'s 1500 and 2700 Hz expressions are approximate main-lobe spans, not measured occupied bandwidth. The separately measured equal-tail 99% positive-frequency FFT power spans are in `results/occupied_bandwidth_99pct.csv`; the method includes sidelobes from phase resets.

## Q5(B): channel

The sampled model is `r[n]=s[n]+w[n]+j[n]`. With clean average power `Ps=mean(s.^2)`, gross `Rb=Rs log2(M)` and `Eb=Ps/Rb`, requested `Eb/N0` gives real-sample noise variance `sigma²=Ps Fs/(2 Rb 10^(EbN0dB/10))`. The jammer is `A sin(2π fj n/Fs+φ)`, with amplitude set so finite-record `Pj/Ps=10^(JSRdB/10)`. The 160 historical channel cases use Eb/N0 0:2:14 dB, baseline plus JSR -10/0/10 dB at an on-tone, between-tone or outside-bank frequency. Q5(B) tables report powers only.

## Q5(C): receiver and metrics

For each 80-sample symbol and each known tone, Ayati's receiver computes noncoherent correlation energy and chooses the highest-energy tone. Its inverse MSB-first mapping yields bits. It searches for `A5 5A` with at most two preamble-bit mismatches, reads the length byte, extracts payload and two CRC bytes, and validates CRC. The trailing 8-FSK pad bits are excluded by the decoded packet length. Sample timing and tone frequencies are assumed known; frame position is searched.

The simulator's payload BER is `sum(decoded_payload_bits ≠ transmitted_payload_bits)/(312 × trials)` for each condition. It compares tone decisions at the true simulation sample alignment even if frame acquisition fails; this must be labeled as aligned receiver-decision BER. PER is `(failed packets)/trials`, where failure includes absent sync, failed CRC, wrong length or wrong payload. The original payload is known only to the evaluator, not to the receiver.

## Q5(D): results and interpretation

Use `results/Q5C/final/summary.csv` for the signed report's quantitative values and `results/Q5C/final/` figures for its BER/PER plots. At 8 dB AWGN, 4-FSK has 565/312,000 bit errors and PER 0.361; 8-FSK has 48/312,000 and PER 0.027. Strong on-tone interference directly competes with a legitimate tone; between-tone and outside-bank effects differ because of detector correlation leakage. The separate `results/Q5_end_to_end/` run uses another receiver and seed plan and does not supply the signed-report values.

The signed report's engineering decision compares bandwidth and reliability conditions: 4-FSK has a narrower tone-center span (900 Hz versus 2,100 Hz), while 8-FSK has a higher gross rate (900 versus 600 bit/s) and stronger measured AWGN performance at the cited operating points. The tone-center spans are not occupied bandwidth. Under a strong on-tone jammer, both configurations can fail; the preferred mode therefore depends on the stated bandwidth and interference conditions. Zero observed errors in a finite run is not a zero true error probability. The 160 Q5(B) calibration cases are power measurements, not BER/PER measurements.

## Figures and evidence placement

The signed report includes tone allocation, transmitter PSD, representative received spectra, and BER/PER comparison figures. The repository retains the matching source figures in `results/`, `results/Q5B/` and `results/Q5C/final/`, with CSV/MAT data and run conditions.

## References and verification boundary

Primary technical evidence is the signed report, MATLAB source and saved outputs in this repository. The official `ICT3128_Group-Assignment_Project_Questions (2).pdf` assignment sheet dated 29 August 2026 specifies one PDF and one experiment-files ZIP, due 1 November 2026 by 5:00 PM. The older group execution guide was planning material and does not override the official sheet. No external academic reference is asserted without verification.
