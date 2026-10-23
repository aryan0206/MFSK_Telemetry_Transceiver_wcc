# Ayati's handwritten Section C outline

This is a planning/evidence guide, not a replacement for the required handwritten submission. Suggested length is 4-5 handwritten pages plus inserted figures; the professor does not state a page count. Include names/signatures according to the group's submission instructions.

## Page 1 - Objective, receiver blocks and assumptions

Title: Q5(C) - Receiver design and implementation.

Explain that the receiver recovers registration-derived telemetry under AWGN and narrowband interference for 4-FSK and 8-FSK. Draw:

Received real waveform -> aligned symbol blocks -> tone correlation / energy detector -> tone-to-bit mapping -> preamble search -> length/payload/CRC extraction -> CRC validation -> recovered bytes/text.

Draw a separate evaluation branch from detected bits and frame outcome to BER/PER counters. Only that branch uses original payload and true frame position. List Fs=24 kHz, Rs=300 symbols/s, N=80 samples, known frequencies and symbol timing. State explicitly that the frame start is unknown, but arbitrary sample timing and carrier-frequency offsets are not estimated.

## Page 2 - Detection and mapping

For each symbol block x[n], n=0,...,N-1, write:

E_i = | sum_n x[n] exp(-j 2 pi f_i n / Fs) |^2.

Select i_hat = arg max_i E_i. Convert zero-based i_hat to k=log2(M) natural-binary bits, MSB first. In MATLAB the array tone index is i_hat+1. Explain that complex correlation contains in-phase and quadrature projections and energy detection does not need the received carrier phase. Show a small mapping example using the actual allocated frequencies.

Insert the lower panel of receiver_evidence_4FSK.png or receiver_evidence_8FSK.png, or the complete figure. Explain the strongest-tone energy peaks. Describe why references are prepared once and used for all symbol blocks. Include a short detector code excerpt.

## Page 3 - Frame search and CRC

Draw the frame: A5 5A preamble, 1-byte payload length, 39-byte payload, 2-byte CRC, then modulation padding if required. The unpadded frame is 352 bits. CRC protects length+payload; padding is excluded.

Explain sliding 16-bit preamble comparison with at most two mismatches. Candidates are ranked by distance and position; parse declared length, reject incomplete frames, check CRC, and continue past false candidates. If none passes, report the failure. Do not claim CRC guarantees that every error is detectable.

CRC-16/CCITT-FALSE: x^16 + x^12 + x^5 + 1; hexadecimal polynomial 1021; init FFFF; MSB-first, no reflection, xorout 0000. CRC bytes are high then low. Show the independent reference 123456789 -> 29B1 and this packet -> A327.

Insert the preamble-search evidence and concise frame-decoder/CRC excerpts. State that the true-start annotation in the figure is evaluator-only; the receiver was not given it.

## Page 4 - Actual recovery and validation

Copy the actual original/recovered payload from final/recovery_demonstration.txt:

240953668|240953568|240953138|240953634

Show successful clean recovery for both M values. Record the guarded case's true/detected start and CRC status from the transcript. Explain that prefix and suffix symbol counts vary across trials. Show intentional payload corruption producing crc_failed. Mention false-candidate, truncated-frame and reproducibility tests; use the final validation record for actual pass counts.

Insert a readable transcript screenshot, including both M values, and selected error-handling code. Keep technical comments next to the corresponding evidence.

## Page 5 - BER/PER measurement and observations

Define raw payload BER = incorrect payload bits / all transmitted payload bits evaluated. Explain evaluator-known alignment and that acquisition failures are not removed from this denominator.

Define end-to-end PER = failed packets / all transmitted packets, where success requires a CRC-valid frame at the correct location with exact payload. Explain acquisition failures, CRC rejections and undetected errors. State 160 conditions, 1,000 frames each, 312 payload bits/frame; the final profile evaluates 160,000 frames / 49,920,000 payload bits. Identify Eb/N0 as gross transmitted-bit energy, not payload-only energy.

Insert BER/PER plots or selected panels for both M values. Quote actual settings and counts from final/summary.csv. Explain the two-sided 95% Wilson PER interval, no invented nonzero BER for zero observations, and the limitation of repeated fixed-payload traffic. Do not assume individual bit errors are independent.

Describe what the receiver measurements demonstrate; leave the preferred MFSK configuration and full bandwidth/reliability trade-off to Akshat's Section D. Point to the numerical handoff rather than reproducing every condition in prose.

## Report evidence and references

Use report/Q5C_evidence_index.md for exact files/excerpts. Exported plots are provided in a readable light theme. Explain all axes and configurations in handwritten captions. The instructor's requirements are authoritative; the evidence presentation is a recommendation.

Useful technical references:
- MathWorks noncoherent MFSK energy detection: https://www.mathworks.com/help/comm/ref/comm.fskdemodulator-system-object.html (conceptual reference; this implementation does not call that toolbox object).
- MathWorks unit tests: https://www.mathworks.com/help/matlab/function-based-unit-tests.html
- CRC-16/IBM-3740 (also known as CRC-16/CCITT-FALSE) parameter catalogue: https://reveng.sourceforge.io/crc-catalogue/16.htm
