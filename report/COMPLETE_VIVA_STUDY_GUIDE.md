# Complete Group 5 WCC project viva study guide

**ICT 3128 Wireless Communication and Computing · Group 5 · Question 5**  
**MFSK telemetry transceiver under AWGN and narrowband interference**

This is a study reference for the submitted simulation, not a new experiment. **[I]** means verified implementation; **[O]** saved observation; **[T]** general theory; **[A]** stated assumption; **[L]** limitation; **[U]** unverified. A numerical project claim cites its source in the same paragraph or table caption. The authoritative signed-report receiver data are `results/Q5C/final/summary.csv`; `results/Q5_end_to_end/` is a different supplementary receiver/seed experiment. No MATLAB runs or result regeneration were performed for this guide.

## Quick formula sheet

| Quantity | Equation | Units/meaning |
| --- | --- | --- |
| Bits per symbol | \(k=\log_2 M\) | bits/symbol, for power-of-two M |
| Symbol period | \(T_s=1/R_s\) | seconds |
| Gross bit rate | \(R_b=kR_s\) | bit slots/s; includes framing and pad slots |
| Samples/symbol | \(N_s=F_s/R_s\) | samples |
| Tone bank | \(f_i=f_c+[i-(M-1)/2]\Delta f\) | Hz, \(i=0,\ldots,M-1\) |
| Tone span | \((M-1)\Delta f\) | Hz between outer tone centers |
| Mean sampled power | \(P_s=N^{-1}\sum_n s[n]^2\) | normalized to 1 Ω |
| Energy per gross bit | \(E_b=P_s/R_b\) | normalized joules |
| Linear ratio | \(x=10^{x_{\rm dB}/10}\) | power ratio |
| Noise sample variance | \(\sigma_w^2=P_sF_s/(2R_b10^{E_b/N_0({\rm dB})/10})\) | waveform amplitude squared |
| Jammer power | \(P_j=P_s10^{\mathrm{JSR}_{\rm dB}/10}\) | normalized power |
| BER | \(N_{\rm bit,error}/N_{\rm payload,bits}\) | aligned payload decisions here |
| PER | \(N_{\rm packet,error}/N_{\rm trials}\) | failed packet proportion |

## 1. Communication fundamentals

**[T]** A communication system maps information into a physical signal, sends it through a channel, and estimates the information from a noisy observation. An analog signal has continuously variable information; digital communication represents a finite set of messages as bits. The physical waveform can still be analog valued: this project's discrete bits select real sine wave frequencies. The chain is ASCII bytes → framed bits → MFSK waveform → AWGN plus a sine interferer → tone decisions → frame/CRC → payload and scored outcomes. Sources: `src/Project5A_Transmitter.m`, `src/apply_channel.m`, `src/mfsk_detect.m`, `src/decode_telemetry_frame.m`, `src/evaluate_telemetry_trial.m`.

**[T]** A bit is a binary digit; a symbol is one signaling choice during \(T_s\). With \(M\) equally distinguishable tones, one symbol carries \(\log_2M\) bit slots. Here **[I]** \(R_s=300\) symbols/s, \(T_s=1/300=3.333\) ms, \(F_s=24{,}000\) samples/s and \(N_s=80\) samples/symbol (`src/Project5A_Transmitter.m`). The bit slot rates are 600 bit/s for 4-FSK and 900 bit/s for 8-FSK; useful payload throughput is lower because the frame contains sync, length and CRC, and 8-FSK pads two bits. These rates describe the waveform while it is sent, not a continuous data service.

**[T]** A sinusoid \(A\sin(2\pi ft+\phi)\) has amplitude \(A\), frequency \(f\) Hz, phase \(\phi\) radians. Its period is \(1/f\). Transmitter symbols use unit nominal amplitude and restart sine phase at each boundary **[I]** (`src/Project5A_Transmitter.m`). That restart and the finite packet generate spectral sidelobes. Power is energy per time; for a sampled real waveform the project's normalized mean power is \(P_s=\operatorname{mean}(s[n]^2)\). The saved Q5(B) baseline CSV gives \(P_s=0.5\) for both clean tones **[O]** (`results/Q5B/Q5B_channel_summary.csv`). For duration \(T\), energy is approximately \(P_sT\) in the one-ohm normalized model.

**[T]** Sampling at \(F_s\) means \(F_s\) values per second. A bandlimited real signal whose highest frequency is \(f_{\max}\) needs \(F_s>2f_{\max}\) for ordinary baseband sampling without aliasing. Here Nyquist frequency is 12 kHz and the highest allocated tone is 4.05 kHz **[I]** (`src/Project5A_Transmitter.m`). Strict bandlimitedness does **not** hold for abrupt phase-reset edges, so this tone check does not prove absence of all spectral content above Nyquist **[L]**. Bandwidth is a specified span of frequency, and its answer depends on the definition (Chapter 6).

## 2. FSK and MFSK

**[T]** Binary FSK chooses one of two frequencies for each bit. M-ary FSK chooses one of M tones per symbol. This project uses 4-FSK (2 bits/symbol) and 8-FSK (3 bits/symbol), with MSB-first binary value mapped to zero-based tone index. Thus 4-FSK `10` selects index 2; 8-FSK `101` selects index 5 **[I]** (`src/Project5A_Transmitter.m`). The receiver reverses this mapping in `src/mfsk_detect.m`.

**[I]** The transmitter sets \(\Delta f=1/T_s=300\) Hz and \(f_c=3000\) Hz, then \(f_i=f_c+[i-(M-1)/2]\Delta f\). This is exact orthogonality of the complex exponential references over an ideal symbol interval at these integer spacings; the real sine/cosine detector's actual finite sampled inner products depend on the waveform and timing. Do not call arbitrary timing offsets orthogonal. The detector compares squared magnitudes of complex correlations, which is noncoherent with respect to unknown constant phase **[I]** (`src/prepare_mfsk_detector.m`, `src/mfsk_detect.m`). A coherent detector would require a phase reference; noncoherent energy detection avoids that requirement but still needs tone frequencies and symbol timing.

| Mode | \(k\) | Exact allocated tones (Hz) | \(R_b\) | Tone-center span | Symbols/frame | Duration |
| --- | ---: | --- | ---: | ---: | ---: | ---: |
| 4-FSK | 2 | 2550, 2850, 3150, 3450 | 600 bit/s | 900 Hz | 176 | 0.5867 s |
| 8-FSK | 3 | 1950, 2250, 2550, 2850, 3150, 3450, 3750, 4050 | 900 bit/s | 2100 Hz | 118 | 0.3933 s |

All values in this table are **[I]** from `src/Project5A_Transmitter.m`; durations use \(N_{\rm sym}/R_s\). More tones raise bits per symbol at fixed \(R_s\), but widen the tone-center range and enlarge the candidate set. Orthogonal MFSK can give better power efficiency under a specified detector and noise model, but the 8-FSK advantage in this particular AWGN sweep is an observation, not a universal ranking. Rough gross spectral efficiencies using the transmitter's approximate main-lobe spans are \(600/1500=0.4\) and \(900/2700=0.333\) bit/s/Hz; those denominators are approximations, so neither number is a regulatory or measured occupied-bandwidth efficiency **[T/I]**.

## 3. Packet framing and CRC

**[I]** Four registration strings form the ASCII payload `240953668|240953568|240953138|240953634`: four 9-character strings and three separators = 39 bytes. The frame is `A5 5A | 27 | 39 payload bytes | CRC high | CRC low`, 44 bytes or 352 bits. The length is `0x27` = 39, not the whole packet length. The preamble is 16 bits; length 8; payload 312; CRC 16. Source: `src/Project5A_Transmitter.m`; cross-check: `experiments/run_q5c_receiver.m` transmitter validator. The 4-FSK frame needs 176 symbols exactly; 8-FSK needs \(\lceil352/3\rceil=118\) symbols, with two zero pad bits after the CRC. The parser uses length to stop before pad bits **[I]** (`src/decode_telemetry_frame.m`).

**[I]** CRC-16/CCITT-FALSE uses \(g(x)=x^{16}+x^{12}+x^5+1\), hexadecimal `0x1021`, initial register `0xFFFF`, input and output nonreflected, final XOR `0x0000`. CRC covers length and payload, excludes preamble and trailing symbol padding; the high CRC byte is transmitted first (`src/Project5A_Transmitter.m`, `src/crc16_ccitt_false.m`). The actual payload CRC is `A327` **[I]** (`experiments/run_q5c_receiver.m` validator). The standard *illustrative validation string* `123456789` yields `29B1` **[I]** (`experiments/run_q5c_receiver.m` recovery demonstration); it is not the transmitted payload.

**[T]** Regard the protected bit stream as polynomial \(m(x)\) over GF(2). Dividing a suitably initialized, shifted stream by \(g(x)\) leaves a 16-bit remainder. XOR is polynomial addition in GF(2), so a nonzero error polynomial generally changes the remainder. Any error pattern divisible by \(g(x)\) evades the check; CRC detects rather than corrects errors. It is not encryption or authentication: an adversary can replace the data and recompute a public CRC. A checksum usually adds numeric words, whereas this CRC uses polynomial division. The nonzero initial register makes the simple zero-initial polynomial description incomplete; the exact byte algorithm is the source of truth.

**Illustrative bitwise calculation [T/I].** For a *hypothetical single zero byte*, initialize the register at `FFFF` and XOR `00 << 8`, leaving `FFFF`. For each of eight incoming zero bits, shift left within 16 bits and XOR `1021` when the pre-shift top bit is 1. The successive registers are `EFDF → CF9F → 8F1F → 0E1F → 1C3E → 387C → 70F8 → E1F0`; thus this one-byte illustration ends at `E1F0`. This follows the algorithm in `src/Project5A_Transmitter.m` and is **not** the project packet CRC.

## 4. Channel model

**[I]** The implemented sampled equation is \(r[n]=s[n]+w[n]+j[n]\), corresponding to \(r(t)=s(t)+n(t)+j(t)\). `src/apply_channel.m` validates a real nonzero waveform and returns the same shape. AWGN is *additive* (summed), *white* (idealized flat PSD over the modeled band), *Gaussian* (each sample distributed normally). For \(W\sim\mathcal N(0,\sigma^2)\), \(p_W(w)=(2\pi\sigma^2)^{-1/2}\exp[-w^2/(2\sigma^2)]\); its mean is 0 and variance is \(\sigma^2\). Continuous real white noise convention uses two-sided PSD \(N_0/2\), so the implementation's sampled variance is \(N_0F_s/2\). Actual finite vectors need not have exactly their expected sample power.

**[I]** The code defines \(P_s=\operatorname{mean}(s^2)\), \(R_b=R_s\log_2M\), \(E_b=P_s/R_b\), \(\gamma_b=10^{E_b/N_0({\rm dB})/10}\), and \(\sigma_w^2=P_sF_s/(2R_b\gamma_b)\) (`src/apply_channel.m`). This \(E_b\) is based on *gross mapped bit slots*, including frame overhead and padding; it is not payload-only energy. At clean \(P_s=0.5\), 0 dB yields target variances 10 for 4-FSK and 6.6667 for 8-FSK; the first is directly recorded in `results/Q5B/Q5B_channel_summary.csv`, and the second follows from the implementation formula. At 6 dB, the 4-FSK target is \(10/10^{0.6}=2.511886\), while case 35 measured 2.412941 **[O]** (`results/Q5B/Q5B_channel_summary.csv`). The difference is a finite noise draw, not a different target.

**[I]** A jammer is one continuous sampled sine \(j[n]=A\sin(2\pi f_jn/F_s+\phi)\), with phase fixed if supplied or drawn from a private MT19937 stream otherwise. The implementation computes the unit sine's *finite-record* mean square \(P_u\), sets target \(P_j=P_s10^{\mathrm{JSR}/10}\), and scales \(A=\sqrt{P_j/P_u}\). Therefore requested JSR is exact for the finite vector to numerical precision; \(A=\sqrt{2P_j}\) is only the ideal half-power approximation. `-Inf` JSR disables jammer; `+Inf` Eb/N0 disables noise. Source: `src/apply_channel.m`.

**[I]** On-tone is the lower middle allocated tone, 2850 Hz for both modes; between the center tones is 3000 Hz; one spacing above the bank is 3750 Hz (4-FSK) or 4350 Hz (8-FSK). These are experiment placements, not a general rule enforced by `apply_channel.m`; see `experiments/run_q5b_channel.m` and `experiments/run_q5c_receiver.m`. An on-tone sine injects correlation energy into a valid candidate; a between-tone sine leaks into neighboring candidates; outside-bank impact depends on correlation and sidelobes. JSR measures jammer power relative to clean signal power, not relative to noise power.

## 5. Receiver

**[I]** The signed-report receiver consists of `prepare_mfsk_detector.m`, `mfsk_detect.m`, `q5c_protocol.m`, `decode_telemetry_frame.m` and `evaluate_telemetry_trial.m`. It has known \(F_s,R_s,M\) and exact tone list, and requires complete aligned 80-sample symbols. For symbol block \(r_s[n]\) and candidate tone \(f_i\), it scores \(Q_i=|\sum_{n=0}^{79}r_s[n]e^{-j2\pi f_i n/F_s}|^2\), chooses \(\arg\max_i Q_i\), then converts the zero-based tone index to \(k\) MSB-first bits. It does not estimate carrier-frequency offset, sample clock offset, or arbitrary fractional/sample symbol timing **[L]**. Phase-insensitive correlation is not full carrier recovery.

**[I]** The parser searches the detected bit stream for the `A5 5A` preamble with at most two bit mismatches. It sorts candidate starts by fewest mismatches then earlier position, reads an 8-bit length, checks enough bits remain, extracts payload and high-first CRC, and returns the first CRC-valid candidate (`src/q5c_protocol.m`, `src/decode_telemetry_frame.m`). It does not enforce length 39 internally. The external evaluator checks true frame start and exact reference payload, so a CRC-valid wrong frame is still a packet error (`src/evaluate_telemetry_trial.m`). The experiment adds 0–8 complete guard symbols before and 0–4 after the packet, generated by `src/q5c_guarded_stream.m`; this tests unknown *whole-symbol frame position*, not arbitrary sample delay. The channel itself preserves timing (`src/apply_channel.m`). The separate `src/receive_mfsk_packet.m` is the supplementary exact-preamble receiver and must not be described as Ayati's signed-report algorithm.

## 6. Performance and bandwidth measurements

**[I]** For each Q5(C) condition, the evaluator compares all 312 payload-bit decisions at the simulator's true aligned location, whether or not acquisition succeeded. \(\mathrm{BER}=\sum\text{payload bit mismatches}/(312\times\text{trials})\). The receiver does not receive the truth; `evaluate_telemetry_trial.m` does. \(\mathrm{PER}=\text{trials lacking a CRC-valid frame at the true start with exact payload}/\text{trials}\). `no_preamble`/`truncated` count as acquisition failures; `crc_failed` as CRC rejections; an accepted wrong frame as an undetected/error outcome in the evaluator. Those categories are diagnostic and do not replace PER. One payload error can fail CRC and therefore the whole packet, but BER and PER have different denominators; a sync error can raise PER with zero payload-bit errors. Sources: `src/evaluate_telemetry_trial.m`, `experiments/run_q5c_receiver.m`.

**[T/I]** Tone-center span is \((M-1)\Delta f\): 900/2100 Hz. The transmitter labels \((M-1)\Delta f+2/T_s\) as an approximate main-lobe span: 1500/2700 Hz (`src/Project5A_Transmitter.m`). The separate equal-tail 99% FFT measure zero-pads to \(N=2^{\lceil\log_2(8L)\rceil}\), doubles positive-frequency interior-bin power, accumulates the 0.5% and 99.5% quantiles, and subtracts their frequencies. It uses no window **[I]** (`experiments/measure_occupied_bandwidth.m`). Both saved FFTs use 131072 points, so bin spacing is \(24000/131072=0.183105\) Hz. Results: 4-FSK 300.476–5699.707 Hz = 5399.231 Hz; 8-FSK 300.293–5699.890 Hz = 5399.597 Hz **[O]** (`results/occupied_bandwidth_99pct.csv`). Zero padding interpolates the sampled finite-record spectrum, not physical resolution beyond record duration. Abrupt per-symbol phase resets and finite edges make sidelobes relevant to this wide 99% definition. These three bandwidth numbers answer different questions.

## 7. Complete experiment design

**[I/O]** The Q5(B) calibration and Q5(C) final BER/PER sweep each have \(2\ M\) modes × \(8\ E_b/N_0\) values (0,2,…,14 dB) × [one AWGN-only baseline + 3 JSR values (−10, 0, +10 dB) × 3 placements] = **160 conditions** (`experiments/run_q5b_channel.m`, `experiments/run_q5c_receiver.m`; both CSVs have 160 rows). Q5(B) has **one received channel realization per condition**, with `seed=3128+caseId`, and saves powers/waveforms, **not BER/PER**. Q5(C) final has **1000 packet trials per condition** = 160,000 packets; each has 312 payload bits, making 49,920,000 evaluated payload-bit decisions **[O]** (`results/Q5C/final/run_info.txt`, `summary.csv`). This is 1000 random channel realizations per condition; deterministic guard construction also varies by trial. Channel seed is `1000000+10000*caseId+trialId`; guard seed `3000000+10000*q+trialId` **[I]** (`experiments/run_q5c_receiver.m`, `src/q5c_guarded_stream.m`). The payload, tone bank, \(F_s\), \(R_s\), and detector are fixed; noise draws, jammer phase (when enabled), guard length and guard tones vary. Channel seeds differ by condition; guard seed depends on mode and trial, so guard pattern is reused across conditions for the same mode/trial. The stored `results/Q5C/final/reproducibility.txt` reports exact agreement of all 160,000 per-trial records in a second full run **[O]**; this guide did not rerun it.

**[I]** The Q5(C) runner also diagnoses the 160 saved Q5(B) vectors, but that diagnostic table is not the final sweep. Its figures and Wilson 95% PER intervals are derived from the 1000-trial summaries. The supplementary `experiments/run_q5_end_to_end.m` also sweeps 160 conditions and 1000 trials by default, but uses `receive_mfsk_packet.m`, exact sync and a different seed rule (`100000+(caseId-1)*trialsPerCase+trial`). Its `results/Q5_end_to_end/end_to_end_summary.csv` cannot substitute for the signed-report Q5(C) results.

## 8. Saved results and interpretation

All table entries below are **[O]** from `results/Q5C/final/summary.csv`; each condition uses 1000 packets and 312000 payload decisions. BER is errors divided by 312000. A printed zero means zero observed in that finite sample.

| AWGN only Eb/N0 (dB) | 4-FSK bit errors | 4-FSK PER | 8-FSK bit errors | 8-FSK PER |
| ---: | ---: | ---: | ---: | ---: |
| 0 | 71440 | 1.000 | 60556 | 1.000 |
| 2 | 43542 | 1.000 | 30957 | 1.000 |
| 4 | 19060 | 1.000 | 9742 | 0.994 |
| 6 | 4768 | 0.985 | 1237 | 0.560 |
| 8 | **565** | **0.361** | **48** | **0.027** |
| 10 | 12 | 0.010 | 0 | 0.000 |
| 12 | 1 | 0.001 | 0 | 0.000 |
| 14 | 0 | 0.000 | 0 | 0.000 |

At 8 dB, \(565/312000=0.0018108974\) and \(48/312000=0.0001538462\), matching `report/FINAL_TEST_AND_EXPERIMENT_EVIDENCE.md` and its signed-PDF cross-check. The plotted trend is improvement with Eb/N0 in the tested AWGN conditions; PER remains much larger than BER because a packet contains many vulnerable bits and sync/CRC can fail. 8-FSK performed better in this particular calibrated, known-tone, fixed-symbol-rate AWGN sweep; this does not prove it is always superior in bandwidth-constrained or jammed links.

| Eb/N0 8 dB, JSR 0 dB | 4-FSK errors / PER | 8-FSK errors / PER |
| --- | ---: | ---: |
| On tone | 75660 / 1.000 | 85189 / 1.000 |
| Between tones | 39054 / 1.000 | 34611 / 1.000 |
| Outside bank | 540 / 0.342 | 60 / 0.036 |

At 10 dB and JSR 0 dB, on-tone gives 74600/312000 (BER 0.2391026), PER 1.000 for 4-FSK and 84034/312000 (BER 0.2693397), PER 1.000 for 8-FSK **[O]** (`results/Q5C/final/summary.csv`). More AWGN improvement does not remove a fixed strong on-tone competitor. At 8 dB, JSR −10 dB on-tone gives 4-FSK 2018 errors/PER 0.826 and 8-FSK 421/PER 0.238; JSR +10 dB on-tone gives 144000/PER 1.000 and 164000/PER 1.000 **[O]** (same CSV). The outside-bank case can be close to AWGN-only but is not guaranteed harmless in other waveforms or timing. The saved equal-tail 99% spans are 5399.231/5399.597 Hz **[O]** (`results/occupied_bandwidth_99pct.csv`), while 4-FSK has the narrower tone bank. The 8-FSK bit rate is higher at the common symbol rate, but effective delivered information would require accounting for packet errors and overhead.

Across all 160 conditions, the CSV sums to 8,424,980 bit errors, 113,239 packet errors, 72,840 acquisition failures, 40,399 CRC rejections and zero recorded accepted-wrong-frame events **[O]** (`results/Q5C/final/summary.csv`; arithmetic sum, not an independent trial). These totals mix drastically different impairment conditions; they are not a single operating-point BER/PER. A zero accepted-wrong-frame count does not prove CRC can never miss an error.

## 9. Team contributions and provenance

**[I/documented]** The signed report cover and `README.md` assign Rashmi Kini Q5(A) transmitter; Aryan Malik Q5(B) channel; Ayati Rauthan Q5(C) receiver; Akshat Mannur Q5(D) handwritten experimental analysis. The four handwritten sections are present according to `report/FINAL_SUBMISSION_AUDIT.md`. Ayati's source/tests and matching final dataset are present. Akshat's handwritten Q5(D) is present, but separate provenance for his original scripts/data was not confirmed; do not attribute Ayati's receiver source or the supplementary sweep to him **[U]**. The signed report has a 25 October 2026 cover date; repository package documents are dated 1 November 2026 (`report/FINAL_SUBMISSION_AUDIT.md`). The audit reports agreement on packet, tones, receiver convention and cited 8 dB numbers; numerical bandwidth values use different definitions, and some handwritten rounded examples may differ from the exact CSV (`report/FINAL_TEST_AND_EXPERIMENT_EVIDENCE.md`). This guide did not independently extract the handwriting from the signed PDF.

**Verification boundary.** All numerical implementation settings quoted here were checked in source or saved CSV/MAT-validation code. **[U]** No separately attributable Q5(D) scripts or raw data were available in the repository evidence. **[L]** No measured tolerance to arbitrary sample timing offset, carrier-frequency offset, Doppler, fading, or multipath is established by these tests. A radio's physical transmit power, antenna, regulatory bandwidth and hardware frequency stability are outside this MATLAB simulation and **unverified**, so no hardware values are assumed.

## 10. Viva question bank (100 questions)

Each entry gives a model answer, a likely examiner follow-up, and a misconception to avoid. Equations are stated where they help. Project details use the sources cited in Chapters 1–9.

**Source key for project facts in Q1–Q100 and their Chapter 12 repeats:** Q5–7, 10–12, 15–17, 20, 24–28, 71–72, 74, 84–85: `src/Project5A_Transmitter.m`; Q18, 39–49, 50–56: `src/apply_channel.m`, with recorded clean power in `results/Q5B/Q5B_channel_summary.csv`; Q23, 29–35, 58, 62: `src/q5c_protocol.m`, `src/decode_telemetry_frame.m`, `src/crc16_ccitt_false.m`; Q57–70, 90–91: `src/prepare_mfsk_detector.m`, `src/mfsk_detect.m`, `src/evaluate_telemetry_trial.m`, `src/q5c_guarded_stream.m`; Q73–76: `experiments/measure_occupied_bandwidth.m`, `results/occupied_bandwidth_99pct.csv`; Q78–83, 92: `experiments/run_q5c_receiver.m`, `results/Q5C/final/summary.csv`; Q87: `experiments/run_q5b_channel.m`, `results/Q5B/Q5B_channel_summary.csv`; Q63, 88: `src/receive_mfsk_packet.m`, `experiments/run_q5_end_to_end.m`; Q95–100: `report/FINAL_SUBMISSION_AUDIT.md`, `report/FINAL_TEST_AND_EXPERIMENT_EVIDENCE.md`, `README.md`. Other Qs state general theory or qualitative consequences of these files.

### Basic communication theory

1. **Q:** What is a communication system? **A:** A transmitter represents information as a signal, a channel changes it, and a receiver estimates the information. **Follow-up:** Where is the source information in this project? **Avoid:** Calling the channel a decoder.
2. **Q:** What is digital communication? **A:** Information is represented by discrete symbols or bits, even when the physical waveform is continuous valued. **Follow-up:** Is the FSK sine waveform digital valued? **Avoid:** Saying every digital waveform must be square.
3. **Q:** What is a bit? **A:** One binary digit, 0 or 1. **Follow-up:** How many bit slots can one 8-FSK symbol carry? **Avoid:** Equating a bit with a sample.
4. **Q:** What is a symbol? **A:** One choice from an agreed signal alphabet over one symbol interval. **Follow-up:** What is the alphabet for 4-FSK? **Avoid:** Equating a symbol with one bit for every modulation.
5. **Q:** Define symbol rate. **A:** Symbols transmitted per second, \(R_s=1/T_s\); here 300 symbols/s. **Follow-up:** What is \(T_s\)? **Avoid:** Calling symbols/s bit/s.
6. **Q:** Define bit rate. **A:** Gross bit slots per second, \(R_b=R_s\log_2M\); here 600 or 900 bit/s. **Follow-up:** Is this payload throughput? **Avoid:** Ignoring framing overhead.
7. **Q:** What is sampling frequency? **A:** Sample count per second; here \(F_s=24000\) Hz. **Follow-up:** How many samples represent a symbol? **Avoid:** Confusing it with carrier frequency.

### MFSK

8. **Q:** What is FSK? **A:** Information selects one carrier frequency from a set. **Follow-up:** What changes at a symbol boundary here? **Avoid:** Calling it amplitude shift keying.
9. **Q:** What makes it M-ary? **A:** There are M possible signaling tones per symbol. **Follow-up:** What are M in this project? **Avoid:** Treating M as packet count.
10. **Q:** How many bits per 4-FSK symbol? **A:** \(\log_2 4=2\). **Follow-up:** How many per 8-FSK symbol? **Avoid:** Saying four bits.
11. **Q:** How does bit mapping work? **A:** MSB-first bits form a binary tone index from 0 to M−1. **Follow-up:** What index is 8-FSK `101`? **Avoid:** Reversing bit order.
12. **Q:** Why is spacing 300 Hz? **A:** The transmitter uses \(\Delta f=1/T_s=R_s=300\) Hz, aligning complex-reference tones over a symbol. **Follow-up:** What assumption is needed for orthogonality? **Avoid:** Claiming arbitrary timing remains orthogonal.
13. **Q:** What is noncoherent detection? **A:** Compare phase-insensitive correlation energies, \(|\sum r_ne^{-j2\pi f_i n/F_s}|^2\). **Follow-up:** What knowledge is still required? **Avoid:** Saying it needs no synchronization at all.
14. **Q:** Why can higher M help or hurt? **A:** At fixed symbol rate it carries more bits and may improve tested AWGN performance, while occupying more tone-center range and giving more candidates. **Follow-up:** What happened under on-tone jamming? **Avoid:** A universal 8-FSK superiority claim.

### Signal mathematics

15. **Q:** Write the symbol waveform. **A:** Here \(s[n]=\sin(2\pi f_i n/F_s)\) within each symbol; phase restarts each symbol. **Follow-up:** What spectral effect can resets cause? **Avoid:** Assuming continuous phase.
16. **Q:** What is the carrier center? **A:** \(f_c=3000\) Hz in the transmitter. **Follow-up:** Is 3000 Hz itself an allocated tone? **Avoid:** Saying yes for even M.
17. **Q:** Give the tone-bank formula. **A:** \(f_i=3000+[i-(M-1)/2]300\) Hz. **Follow-up:** Find the lowest 8-FSK tone. **Avoid:** Using 300 Hz as the center.
18. **Q:** What is signal power here? **A:** Finite-vector \(P_s=\operatorname{mean}(s[n]^2)\), normalized to 1 Ω. **Follow-up:** What does the Q5(B) CSV record? **Avoid:** Treating amplitude and power as identical.
19. **Q:** How do you calculate symbol energy? **A:** For steady mean power, \(E_s=P_sT_s=P_s/R_s\). **Follow-up:** How does \(E_b\) relate? **Avoid:** Applying it without defining the power convention.
20. **Q:** What is Nyquist frequency? **A:** \(F_s/2=12000\) Hz here. **Follow-up:** Highest allocated tone? **Avoid:** Claiming this removes all edge-generated aliasing.
21. **Q:** What is phase? **A:** The sinusoid's angular offset, in radians. **Follow-up:** Why does squared complex-correlation magnitude tolerate unknown fixed phase? **Avoid:** Confusing phase with frequency.

### Packet framing

22. **Q:** Why frame the payload? **A:** Sync marks a candidate start, length bounds payload, CRC checks integrity. **Follow-up:** Can sync alone guarantee a valid packet? **Avoid:** Treating preamble as CRC.
23. **Q:** What are the sync bytes? **A:** `A5 5A`, a 16-bit preamble. **Follow-up:** How many bit errors may Q5(C) tolerate there? **Avoid:** Confusing Q5(C) with the exact-sync supplementary receiver.
24. **Q:** What does `0x27` mean? **A:** Decimal 39, the payload byte count. **Follow-up:** What is the total frame length? **Avoid:** Reading it as 27 decimal.
25. **Q:** What is the payload? **A:** Four ASCII registration strings separated by `|`, 39 bytes. **Follow-up:** How many payload bits? **Avoid:** Claiming the frame itself is 39 bytes.
26. **Q:** How long is the full frame? **A:** \(2+1+39+2=44\) bytes, or 352 bits. **Follow-up:** How many 4-FSK symbols? **Avoid:** Omitting CRC.
27. **Q:** Why pad 8-FSK? **A:** 352 is not divisible by three; two zeros complete the 118th 3-bit symbol. **Follow-up:** Does the pad belong to the CRC? **Avoid:** Counting pad as payload.
28. **Q:** How is byte bit order set? **A:** Most significant bit first for bytes and tone-index groups. **Follow-up:** How is the CRC sent? **Avoid:** Assuming low byte first.

### CRC

29. **Q:** What CRC variant is used? **A:** CRC-16/CCITT-FALSE, `0x1021`, init `0xFFFF`, no reflection, XOR-out zero. **Follow-up:** Which bytes are covered? **Avoid:** Naming a CRC solely by width.
30. **Q:** What polynomial is `0x1021`? **A:** \(x^{16}+x^{12}+x^5+1\), with the leading degree-16 term implicit in the hex register representation. **Follow-up:** Why are operations XOR? **Avoid:** Ordinary decimal division.
31. **Q:** Which fields does CRC cover? **A:** Length and payload, not preamble or pad. **Follow-up:** What happens if a preamble bit is wrong? **Avoid:** Claiming CRC directly checks sync.
32. **Q:** How is CRC ordered? **A:** High byte then low byte; actual payload CRC is `A327`. **Follow-up:** What bytes appear at frame end? **Avoid:** Swapping bytes.
33. **Q:** What is `29B1`? **A:** CRC of illustrative standard string `123456789`, not project payload. **Follow-up:** What is actual payload CRC? **Avoid:** Reporting `29B1` as transmitted.
34. **Q:** Can CRC correct errors? **A:** No; it only detects many error patterns, except those yielding the same remainder. **Follow-up:** How could recovery be added? **Avoid:** Calling it FEC.
35. **Q:** Is CRC authentication? **A:** No; anyone can recompute a public CRC on altered data. **Follow-up:** What would authenticate? **Avoid:** Equating integrity against random noise with adversarial integrity.

### AWGN

36. **Q:** Expand AWGN. **A:** Additive white Gaussian noise. **Follow-up:** What does each adjective mean? **Avoid:** Calling white noise constant amplitude.
37. **Q:** What is Gaussian? **A:** A normal random variable with density \(e^{-(x-\mu)^2/(2\sigma^2)}/\sqrt{2\pi\sigma^2}\). **Follow-up:** What mean is used here? **Avoid:** Saying every sample has the same value.
38. **Q:** What is white? **A:** Ideal flat power spectral density over the model bandwidth. **Follow-up:** Is it physically infinite-bandwidth noise? **Avoid:** Claiming a sampled simulation implements infinite frequencies.
39. **Q:** What is noise variance? **A:** \(E[(W-\mu)^2]\); here target \(N_0F_s/2\). **Follow-up:** Why can measured power differ? **Avoid:** Replacing expected with exact finite power.
40. **Q:** What is \(N_0\)? **A:** Noise spectral-density parameter; two-sided real PSD is \(N_0/2\). **Follow-up:** How is it computed from \(E_b/N_0\)? **Avoid:** Treating \(N_0\) as noise amplitude.
41. **Q:** Is the channel multiplicative fading? **A:** No, it adds independent Gaussian samples and optionally a sine. **Follow-up:** What would fading require? **Avoid:** Describing this as Rayleigh fading.
42. **Q:** Why use a private random stream? **A:** It gives reproducible draws without changing MATLAB's global RNG state. **Follow-up:** What is the Q5(C) channel seed rule? **Avoid:** Saying all trials share one noise draw.

### Eb/N0

43. **Q:** Define \(E_b/N_0\). **A:** Gross bit energy divided by noise spectral-density parameter. **Follow-up:** Does this use payload-only bits? **Avoid:** Conflating it with sample SNR.
44. **Q:** Convert 8 dB to linear. **A:** \(10^{8/10}=6.3096\). **Follow-up:** What is 0 dB? **Avoid:** Using \(20\log_{10}\) for a power ratio.
45. **Q:** How is \(E_b\) computed here? **A:** \(E_b=P_s/(R_s\log_2M)\). **Follow-up:** Why does it differ by M? **Avoid:** Dividing only by payload bit rate.
46. **Q:** Write the noise variance formula. **A:** \(\sigma^2=P_sF_s/(2R_b10^{E_b/N_0({\rm dB})/10})\). **Follow-up:** What happens at +Inf Eb/N0? **Avoid:** Omitting the factor of two from this real-passband convention.
47. **Q:** Why does higher Eb/N0 improve AWGN BER? **A:** Lower noise relative to energy makes correct tone more likely. **Follow-up:** Does it defeat a fixed on-tone jammer? **Avoid:** Saying it guarantees zero errors.
48. **Q:** Is SNR the same as Eb/N0? **A:** No; under this sample convention \(P_s/\sigma^2=2R_b(E_b/N_0)/F_s\). **Follow-up:** Calculate it at 0 dB for 4-FSK. **Avoid:** Reusing a dB number without bandwidth convention.
49. **Q:** What is finite-record measured Eb/N0? **A:** A ratio computed from actual sampled noise power, which fluctuates around the target. **Follow-up:** What does `meta.measuredEbN0dB` use? **Avoid:** Expecting exact target on every draw.

### Narrowband interference

50. **Q:** What is the jammer model? **A:** One continuous sine added to the whole sampled packet. **Follow-up:** Is it independently randomized per symbol? **Avoid:** Calling it another AWGN source.
51. **Q:** What is JSR? **A:** \(10\log_{10}(P_j/P_s)\) dB. **Follow-up:** What power is reference? **Avoid:** Using jammer/noise ratio.
52. **Q:** What does JSR 0 dB mean? **A:** Equal jammer and clean average powers. **Follow-up:** What is target \(P_j\) if \(P_s=0.5\)? **Avoid:** Saying zero jammer.
53. **Q:** What is on-tone placement? **A:** A jammer at an allocated candidate, here 2850 Hz. **Follow-up:** Why can it force wrong decisions? **Avoid:** Calling 3000 Hz on-tone.
54. **Q:** What is between-tone placement? **A:** Here 3000 Hz, between the two central tones. **Follow-up:** Why might it leak into both correlations? **Avoid:** Saying it is allocated.
55. **Q:** What is outside-bank placement? **A:** One 300-Hz spacing above highest tone: 3750 or 4350 Hz. **Follow-up:** Does that imply zero impact? **Avoid:** Assuming perfect stopband filtering.
56. **Q:** How is jammer amplitude chosen? **A:** \(A=\sqrt{P_s10^{\mathrm{JSR}/10}/P_u}\), using measured unit-sine power \(P_u\). **Follow-up:** Why not always \(\sqrt{2P_j}\)? **Avoid:** Ignoring finite-record normalization.

### Receiver and synchronization

57. **Q:** What detector statistic is used? **A:** Squared magnitude of the complex correlation for each known tone. **Follow-up:** How is a decision made? **Avoid:** Sampling waveform amplitude once.
58. **Q:** How does Q5(C) find the frame? **A:** It searches detected bits for preamble candidates with at most two mismatches, then seeks a CRC-valid frame. **Follow-up:** How are candidates ordered? **Avoid:** Claiming sample-level timing search.
59. **Q:** What does known timing mean? **A:** Input begins at a whole-symbol sample boundary and every symbol is 80 samples. **Follow-up:** What offset was actually varied? **Avoid:** Claiming arbitrary sample delay recovery.
60. **Q:** What is known about carrier? **A:** Exact tone bank is supplied; phase need not be. **Follow-up:** Is frequency offset tracked? **Avoid:** Calling noncoherent detection CFO estimation.
61. **Q:** Why can CRC-valid still be a scored failure? **A:** Evaluator also checks true frame start and exact payload. **Follow-up:** Can receiver itself know truth? **Avoid:** Putting simulator truth into decoder.
62. **Q:** Does parser enforce 39 bytes? **A:** No; it reads the declared length and CRC, while evaluator compares the expected payload. **Follow-up:** Why is that useful for a general parser? **Avoid:** Saying length validation always equals 39 inside parser.
63. **Q:** What is the supplementary receiver? **A:** `receive_mfsk_packet.m` uses exact preamble matching and a separate seed plan. **Follow-up:** Which results match the signed report? **Avoid:** Mixing its CSV with Q5(C) final.

### BER/PER

64. **Q:** Define BER here. **A:** Payload decision bit errors divided by 312 times packet trials, evaluated at known true alignment. **Follow-up:** Can BER be low when PER high? **Avoid:** Counting only accepted packets.
65. **Q:** Define PER here. **A:** Failed trials divided by all trials, with true-start, exact-payload, CRC-valid acceptance. **Follow-up:** What failure categories are saved? **Avoid:** PER=BER.
66. **Q:** Why can a single bit error fail a packet? **A:** A changed protected bit generally changes CRC remainder. **Follow-up:** Is detection mathematically guaranteed for every pattern? **Avoid:** Claiming CRC is perfect.
67. **Q:** Can PER rise with no payload errors? **A:** Yes; sync or length/CRC bits may fail while aligned payload decisions are correct. **Follow-up:** How is BER counted in that trial? **Avoid:** Forcing BER to 1 on packet failure.
68. **Q:** What is a zero observed BER? **A:** No bit errors in the sampled trials; underlying error probability may be nonzero. **Follow-up:** What is a confidence interval? **Avoid:** Claiming guaranteed reliability.
69. **Q:** What does Wilson interval describe here? **A:** A two-sided 95% interval for packet-error probability estimated from binomial counts. **Follow-up:** Why is it useful at zero failures? **Avoid:** Treating 0/1000 as certainty.
70. **Q:** What is an undetected/error outcome in evaluator? **A:** An accepted CRC-valid frame that is wrong in start or payload. **Follow-up:** How many were recorded? **Avoid:** Claiming impossible because saved count is zero.

### Bandwidth

71. **Q:** What is tone-center span? **A:** Highest minus lowest tone: \((M-1)\Delta f\), 900 or 2100 Hz. **Follow-up:** Is this occupied bandwidth? **Avoid:** Equating center span with total spectrum.
72. **Q:** What is the approximate main-lobe span? **A:** Tone span plus \(2/T_s\): 1500 or 2700 Hz in transmitter output. **Follow-up:** Is it measured? **Avoid:** Calling it 99% occupied bandwidth.
73. **Q:** What is equal-tail 99% width? **A:** The positive-frequency interval between 0.5% and 99.5% cumulative FFT power. **Follow-up:** Why does it extend beyond outer tones? **Avoid:** Treating all definitions as equivalent.
74. **Q:** What is the FFT bin spacing? **A:** \(F_s/N=24000/131072=0.183105\) Hz for saved measure. **Follow-up:** Does zero padding increase physical observation time? **Avoid:** Calling interpolated bins independent resolution.
75. **Q:** Was a window applied in occupied-bandwidth script? **A:** No; it FFTs the raw finite packet after zero padding. **Follow-up:** What can a window alter? **Avoid:** Inventing Hann weighting.
76. **Q:** Why are 99% widths about 5.4 kHz? **A:** The finite, phase-reset waveform has sidelobes counted by the equal-tail measure. **Follow-up:** Would continuous phase necessarily give same result? **Avoid:** Calling the output a frequency allocation rule.
77. **Q:** Define rough spectral efficiency. **A:** Gross bit rate divided by a specified bandwidth, \(\eta=R_b/B\). **Follow-up:** Which B was used? **Avoid:** Giving a number without a bandwidth definition.

### Experimental results

78. **Q:** How many signed-report conditions? **A:** \(2\times8\times(1+3\times3)=160\). **Follow-up:** How many trials per condition? **Avoid:** Treating 160 as packet count.
79. **Q:** What are 8 dB AWGN results? **A:** 4-FSK 565 errors/312000, PER 0.361; 8-FSK 48/312000, PER 0.027. **Follow-up:** Calculate both BERs. **Avoid:** Quoting supplementary-run counts.
80. **Q:** What happens at 10 dB, 0 dB JSR on tone? **A:** Both PERs are 1.000; errors 74600 and 84034. **Follow-up:** Why can higher Eb/N0 fail to help? **Avoid:** Saying AWGN alone caused all failures.
81. **Q:** What do 0 errors at 10 dB 8-FSK AWGN prove? **A:** Only no observed errors in 1000 packets/312000 bits. **Follow-up:** What uncertainty remains? **Avoid:** Claiming true BER=0.
82. **Q:** How does outside-bank at 8 dB, JSR 0 compare? **A:** PER 0.342 for 4-FSK and 0.036 for 8-FSK, near AWGN-only 0.361 and 0.027. **Follow-up:** Are those differences statistically conclusive? **Avoid:** Making a universal ranking.
83. **Q:** Which dataset is Q5(B)? **A:** `results/Q5B/Q5B_channel_summary.csv` reports powers of one realization per condition. **Follow-up:** Where is BER/PER? **Avoid:** Reading calibration powers as receiver results.

### Project design decisions

84. **Q:** Why use 4-FSK and 8-FSK? **A:** They compare two M values at common symbol rate, exposing rate, tone span and reliability trade-offs. **Follow-up:** Which rate differs? **Avoid:** Saying symbol rates differ.
85. **Q:** Why use a length byte? **A:** It tells the parser how many payload bytes precede CRC and excludes trailing pad. **Follow-up:** What happens if corrupted? **Avoid:** Assuming it is out of CRC coverage.
86. **Q:** Why use both BER and PER? **A:** They measure aligned bit decisions and complete packet delivery separately. **Follow-up:** Can their trends differ? **Avoid:** Using one as substitute for the other.
87. **Q:** Why calibrate channel separately? **A:** It checks intended powers, seed behavior and placements before receiver evaluation. **Follow-up:** Does calibration produce BER? **Avoid:** Treating its 160 rows as 160000 trials.
88. **Q:** Why preserve saved final CSV? **A:** It is the exact signed-report numerical basis with counts and denominators. **Follow-up:** What is separate supplementary CSV? **Avoid:** Combining datasets.
89. **Q:** Which mode should be selected? **A:** State constraints: 4-FSK narrower tone span; 8-FSK higher gross rate and better measured AWGN reliability; both vulnerable to strong on-tone jammer. **Follow-up:** What bandwidth definition is relevant? **Avoid:** One universal winner.

### Limitations

90. **Q:** Can receiver handle arbitrary sample delay? **A:** No demonstrated capability; Q5(C) requires complete aligned symbol blocks and varies whole-symbol guard prefix. **Follow-up:** What estimator would be needed? **Avoid:** Calling frame search timing recovery.
91. **Q:** Can it track carrier-frequency offset? **A:** No; reference tones are supplied exactly. **Follow-up:** What would offset do to correlation? **Avoid:** Equating phase invariance with frequency invariance.
92. **Q:** Are zero-error cases error free in all future transmissions? **A:** No; finite 1000-packet observations have uncertainty. **Follow-up:** Why report intervals? **Avoid:** Claiming proof from zero counts.
93. **Q:** Is the channel a full wireless propagation model? **A:** No; AWGN plus one sine, without fading, multipath or Doppler. **Follow-up:** What could multipath change? **Avoid:** Presenting results as universal field performance.
94. **Q:** Does CRC make messages secure? **A:** No; it is a random-error detector and has no secret key. **Follow-up:** What is needed for authentication? **Avoid:** Equating CRC with encryption.
95. **Q:** What signed-PDF distinction matters? **A:** Its 1500/2700 Hz approximate main-lobe spans differ by definition from measured ~5399 Hz 99% widths. **Follow-up:** Which is suitable for a spectrum mask? **Avoid:** Calling the two contradictory measurements of one quantity.

### Individual responsibilities

96. **Q:** What was Rashmi Kini's assigned part? **A:** Q5(A): transmitter, packet/framing and modulation in the signed team description. **Follow-up:** What is its source file? **Avoid:** Attributing receiver code to her.
97. **Q:** What was Aryan Malik's assigned part? **A:** Q5(B): AWGN and jammer channel, calibration and integration. **Follow-up:** What does Q5(B) CSV measure? **Avoid:** Calling it a BER sweep.
98. **Q:** What was Ayati Rauthan's assigned part? **A:** Q5(C): receiver, sync/CRC and final recovery experiment. **Follow-up:** Which saved dataset matches signed BER/PER? **Avoid:** Substituting the supplementary receiver.
99. **Q:** What was Akshat Mannur's assigned part? **A:** Q5(D): handwritten comparison and engineering decision in signed report. **Follow-up:** Are his separate original scripts confirmed? **Avoid:** Inventing script authorship.
100. **Q:** What is the provenance boundary? **A:** The signed handwritten D section exists; separately attributable original D scripts/data were not supplied, while Q5(C) final data support cited trends. **Follow-up:** Which file documents this? **Avoid:** Treating missing script provenance as missing D section.

## 11. Twenty worked numerical problems

Unless marked hypothetical, inputs come from `src/Project5A_Transmitter.m`, `src/apply_channel.m`, `results/Q5C/final/summary.csv`, `results/Q5B/Q5B_channel_summary.csv`, or `results/occupied_bandwidth_99pct.csv`. Arithmetic below is derived from those inputs, not a new run.

1. **Bits per symbol, 4-FSK.** \(k=\log_2 4=2\) bits/symbol.
2. **Bits per symbol, 8-FSK.** \(k=\log_2 8=3\) bits/symbol.
3. **4-FSK gross bit rate.** \(R_b=R_sk=300(2)=600\) bit/s.
4. **8-FSK gross bit rate.** \(R_b=300(3)=900\) bit/s.
5. **Symbol duration.** \(T_s=1/300=0.003333\) s = 3.333 ms.
6. **Samples per symbol.** \(N_s=F_s/R_s=24000/300=80\) samples.
7. **Frame size.** \(2+1+39+2=44\) bytes; \(44(8)=352\) bits.
8. **4-FSK symbol count and duration.** \(352/2=176\) symbols; \(176/300=0.586667\) s.
9. **8-FSK pad, count and duration.** \(\lceil352/3\rceil=118\) symbols; \(118(3)-352=2\) pad bits; \(118/300=0.393333\) s.
10. **CRC overhead.** CRC is 2 bytes/16 bits; \(2/44=4.545\%\) of frame bytes. The entire nonpayload overhead is \((44-39)/44=11.364\%\), with 8-FSK pad beyond frame bytes.
11. **4-FSK tone bank.** \(3000+[-1.5,-0.5,0.5,1.5](300)=[2550,2850,3150,3450]\) Hz; consecutive spacing 300 Hz.
12. **8-FSK tone-center span.** \(4050-1950=2100\) Hz, or \((8-1)(300)\) Hz.
13. **Nyquist check.** \(F_s/2=12000\) Hz, greater than the highest allocated tone 4050 Hz by 7950 Hz. This is a tone-frequency check, not a claim that phase-reset edges are bandlimited.
14. **Convert Eb/N0.** At 8 dB, \(\gamma_b=10^{8/10}=6.309573\). At 0 dB, \(\gamma_b=1\).
15. **Convert JSR.** At −10 dB, \(P_j/P_s=10^{-1}=0.1\); at +10 dB it is 10. With \(P_s=0.5\), target jammer powers are 0.05 and 5 respectively. The baseline \(P_s\) is recorded in `results/Q5B/Q5B_channel_summary.csv`.
16. **Noise variance, 4-FSK, 0 dB.** \(\sigma^2=(0.5)(24000)/(2(600)(1))=10\), matching Q5(B) case 1 target. The measured case-1 draw is 10.0338549363 (`results/Q5B/Q5B_channel_summary.csv`).
17. **Noise variance, 4-FSK, 6 dB.** \(\gamma_b=10^{0.6}=3.9810717\); \(\sigma^2=10/3.9810717=2.5118864\). Q5(B) case 35 measures 2.412941 (rounded) because finite draws vary (`results/Q5B/Q5B_channel_summary.csv`).
18. **Noise variance, 8-FSK, 0 dB.** \(\sigma^2=(0.5)(24000)/(2(900))=6.666667\), using the same clean power and gross-rate convention. This is a calculation from implementation, not a newly measured noise draw.
19. **BER, 8 dB AWGN.** For 4-FSK \(565/312000=0.0018108974\); for 8-FSK \(48/312000=0.0001538462\) (`results/Q5C/final/summary.csv`).
20. **PER, 8 dB AWGN.** For 4-FSK \(361/1000=0.361\); for 8-FSK \(27/1000=0.027\) (same CSV). BER and PER denominators differ.
21. **FFT bin spacing and measured 99% width.** \(\Delta f_{\rm FFT}=24000/131072=0.1831055\) Hz. For 4-FSK, \(5699.70703125-300.47607421875=5399.230957\) Hz (`results/occupied_bandwidth_99pct.csv`).
22. **Hypothetical signal-to-noise conversion.** If a sample waveform has \(P_s=0.5\) and measured noise power 0.05, then sample-power SNR is \(10\log_{10}(0.5/0.05)=10\) dB. This is **not** a saved project condition and is not automatically \(E_b/N_0=10\) dB.
23. **Hypothetical packet reliability.** If 17 of 200 packets fail, \(\mathrm{PER}=17/200=0.085\). This illustrates the definition, not a project observation.
24. **Hypothetical bit reliability.** If 9 payload decisions out of 62400 are wrong, \(\mathrm{BER}=9/62400=0.00014423\). This illustrates a denominator of 200 × 312 bits, not a saved observation.

## 12. Full mock viva

This is a 100-turn rehearsal: 30 basic, 30 intermediate, 20 difficult, and 20 project-specific questions. Each turn below restates a question from Chapter 10, with its model answer and an examiner follow-up. Practise giving the answer aloud before reading it. The misconception line in Chapter 10 can be used for self-check. Questions are reordered by difficulty, so the bank number is a cross-reference rather than a difficulty score.

### Basic (30)

1. **Examiner (bank Q1):** What is a communication system? **Model answer:** A transmitter represents information as a signal, a channel changes it, and a receiver estimates the information. **Examiner follow-up:** Where is the source information in this project?
2. **Examiner (bank Q2):** What is digital communication? **Model answer:** Information is represented by discrete symbols or bits, even when the physical waveform is continuous valued. **Examiner follow-up:** Is the FSK sine waveform digital valued?
3. **Examiner (bank Q3):** What is a bit? **Model answer:** One binary digit, 0 or 1. **Examiner follow-up:** How many bit slots can one 8-FSK symbol carry?
4. **Examiner (bank Q4):** What is a symbol? **Model answer:** One choice from an agreed signal alphabet over one symbol interval. **Examiner follow-up:** What is the alphabet for 4-FSK?
5. **Examiner (bank Q5):** Define symbol rate. **Model answer:** Symbols transmitted per second, \(R_s=1/T_s\); here 300 symbols/s. **Examiner follow-up:** What is \(T_s\)?
6. **Examiner (bank Q6):** Define bit rate. **Model answer:** Gross bit slots per second, \(R_b=R_s\log_2M\); here 600 or 900 bit/s. **Examiner follow-up:** Is this payload throughput?
7. **Examiner (bank Q7):** What is sampling frequency? **Model answer:** Sample count per second; here \(F_s=24000\) Hz. **Examiner follow-up:** How many samples represent a symbol?
8. **Examiner (bank Q8):** What is FSK? **Model answer:** Information selects one carrier frequency from a set. **Examiner follow-up:** What changes at a symbol boundary here?
9. **Examiner (bank Q9):** What makes it M-ary? **Model answer:** There are M possible signaling tones per symbol. **Examiner follow-up:** What are M in this project?
10. **Examiner (bank Q10):** How many bits per 4-FSK symbol? **Model answer:** \(\log_2 4=2\). **Examiner follow-up:** How many per 8-FSK symbol?
11. **Examiner (bank Q11):** How does bit mapping work? **Model answer:** MSB-first bits form a binary tone index from 0 to M−1. **Examiner follow-up:** What index is 8-FSK `101`?
12. **Examiner (bank Q12):** Why is spacing 300 Hz? **Model answer:** The transmitter uses \(\Delta f=1/T_s=R_s=300\) Hz, aligning complex-reference tones over a symbol. **Examiner follow-up:** What assumption is needed for orthogonality?
13. **Examiner (bank Q13):** What is noncoherent detection? **Model answer:** Compare phase-insensitive correlation energies, \(|\sum r_ne^{-j2\pi f_i n/F_s}|^2\). **Examiner follow-up:** What knowledge is still required?
14. **Examiner (bank Q14):** Why can higher M help or hurt? **Model answer:** At fixed symbol rate it carries more bits and may improve tested AWGN performance, while occupying more tone-center range and giving more candidates. **Examiner follow-up:** What happened under on-tone jamming?
15. **Examiner (bank Q15):** Write the symbol waveform. **Model answer:** Here \(s[n]=\sin(2\pi f_i n/F_s)\) within each symbol; phase restarts each symbol. **Examiner follow-up:** What spectral effect can resets cause?
16. **Examiner (bank Q16):** What is the carrier center? **Model answer:** \(f_c=3000\) Hz in the transmitter. **Examiner follow-up:** Is 3000 Hz itself an allocated tone?
17. **Examiner (bank Q17):** Give the tone-bank formula. **Model answer:** \(f_i=3000+[i-(M-1)/2]300\) Hz. **Examiner follow-up:** Find the lowest 8-FSK tone.
18. **Examiner (bank Q18):** What is signal power here? **Model answer:** Finite-vector \(P_s=\operatorname{mean}(s[n]^2)\), normalized to 1 Ω. **Examiner follow-up:** What does the Q5(B) CSV record?
19. **Examiner (bank Q19):** How do you calculate symbol energy? **Model answer:** For steady mean power, \(E_s=P_sT_s=P_s/R_s\). **Examiner follow-up:** How does \(E_b\) relate?
20. **Examiner (bank Q20):** What is Nyquist frequency? **Model answer:** \(F_s/2=12000\) Hz here. **Examiner follow-up:** Highest allocated tone?
21. **Examiner (bank Q21):** What is phase? **Model answer:** The sinusoid's angular offset, in radians. **Examiner follow-up:** Why does squared complex-correlation magnitude tolerate unknown fixed phase?
22. **Examiner (bank Q22):** Why frame the payload? **Model answer:** Sync marks a candidate start, length bounds payload, CRC checks integrity. **Examiner follow-up:** Can sync alone guarantee a valid packet?
23. **Examiner (bank Q23):** What are the sync bytes? **Model answer:** `A5 5A`, a 16-bit preamble. **Examiner follow-up:** How many bit errors may Q5(C) tolerate there?
24. **Examiner (bank Q24):** What does `0x27` mean? **Model answer:** Decimal 39, the payload byte count. **Examiner follow-up:** What is the total frame length?
25. **Examiner (bank Q25):** What is the payload? **Model answer:** Four ASCII registration strings separated by `|`, 39 bytes. **Examiner follow-up:** How many payload bits?
26. **Examiner (bank Q26):** How long is the full frame? **Model answer:** \(2+1+39+2=44\) bytes, or 352 bits. **Examiner follow-up:** How many 4-FSK symbols?
27. **Examiner (bank Q27):** Why pad 8-FSK? **Model answer:** 352 is not divisible by three; two zeros complete the 118th 3-bit symbol. **Examiner follow-up:** Does the pad belong to the CRC?
28. **Examiner (bank Q28):** How is byte bit order set? **Model answer:** Most significant bit first for bytes and tone-index groups. **Examiner follow-up:** How is the CRC sent?
29. **Examiner (bank Q29):** What CRC variant is used? **Model answer:** CRC-16/CCITT-FALSE, `0x1021`, init `0xFFFF`, no reflection, XOR-out zero. **Examiner follow-up:** Which bytes are covered?
30. **Examiner (bank Q30):** What polynomial is `0x1021`? **Model answer:** \(x^{16}+x^{12}+x^5+1\), with the leading degree-16 term implicit in the hex register representation. **Examiner follow-up:** Why are operations XOR?

### Intermediate (30)

31. **Examiner (bank Q31):** Which fields does CRC cover? **Model answer:** Length and payload, not preamble or pad. **Examiner follow-up:** What happens if a preamble bit is wrong?
32. **Examiner (bank Q32):** How is CRC ordered? **Model answer:** High byte then low byte; actual payload CRC is `A327`. **Examiner follow-up:** What bytes appear at frame end?
33. **Examiner (bank Q33):** What is `29B1`? **Model answer:** CRC of illustrative standard string `123456789`, not project payload. **Examiner follow-up:** What is actual payload CRC?
34. **Examiner (bank Q34):** Can CRC correct errors? **Model answer:** No; it only detects many error patterns, except those yielding the same remainder. **Examiner follow-up:** How could recovery be added?
35. **Examiner (bank Q35):** Is CRC authentication? **Model answer:** No; anyone can recompute a public CRC on altered data. **Examiner follow-up:** What would authenticate?
36. **Examiner (bank Q36):** Expand AWGN. **Model answer:** Additive white Gaussian noise. **Examiner follow-up:** What does each adjective mean?
37. **Examiner (bank Q37):** What is Gaussian? **Model answer:** A normal random variable with density \(e^{-(x-\mu)^2/(2\sigma^2)}/\sqrt{2\pi\sigma^2}\). **Examiner follow-up:** What mean is used here?
38. **Examiner (bank Q38):** What is white? **Model answer:** Ideal flat power spectral density over the model bandwidth. **Examiner follow-up:** Is it physically infinite-bandwidth noise?
39. **Examiner (bank Q39):** What is noise variance? **Model answer:** \(E[(W-\mu)^2]\); here target \(N_0F_s/2\). **Examiner follow-up:** Why can measured power differ?
40. **Examiner (bank Q40):** What is \(N_0\)? **Model answer:** Noise spectral-density parameter; two-sided real PSD is \(N_0/2\). **Examiner follow-up:** How is it computed from \(E_b/N_0\)?
41. **Examiner (bank Q41):** Is the channel multiplicative fading? **Model answer:** No, it adds independent Gaussian samples and optionally a sine. **Examiner follow-up:** What would fading require?
42. **Examiner (bank Q42):** Why use a private random stream? **Model answer:** It gives reproducible draws without changing MATLAB's global RNG state. **Examiner follow-up:** What is the Q5(C) channel seed rule?
43. **Examiner (bank Q43):** Define \(E_b/N_0\). **Model answer:** Gross bit energy divided by noise spectral-density parameter. **Examiner follow-up:** Does this use payload-only bits?
44. **Examiner (bank Q44):** Convert 8 dB to linear. **Model answer:** \(10^{8/10}=6.3096\). **Examiner follow-up:** What is 0 dB?
45. **Examiner (bank Q45):** How is \(E_b\) computed here? **Model answer:** \(E_b=P_s/(R_s\log_2M)\). **Examiner follow-up:** Why does it differ by M?
46. **Examiner (bank Q46):** Write the noise variance formula. **Model answer:** \(\sigma^2=P_sF_s/(2R_b10^{E_b/N_0({\rm dB})/10})\). **Examiner follow-up:** What happens at +Inf Eb/N0?
47. **Examiner (bank Q47):** Why does higher Eb/N0 improve AWGN BER? **Model answer:** Lower noise relative to energy makes correct tone more likely. **Examiner follow-up:** Does it defeat a fixed on-tone jammer?
48. **Examiner (bank Q48):** Is SNR the same as Eb/N0? **Model answer:** No; under this sample convention \(P_s/\sigma^2=2R_b(E_b/N_0)/F_s\). **Examiner follow-up:** Calculate it at 0 dB for 4-FSK.
49. **Examiner (bank Q49):** What is finite-record measured Eb/N0? **Model answer:** A ratio computed from actual sampled noise power, which fluctuates around the target. **Examiner follow-up:** What does `meta.measuredEbN0dB` use?
50. **Examiner (bank Q50):** What is the jammer model? **Model answer:** One continuous sine added to the whole sampled packet. **Examiner follow-up:** Is it independently randomized per symbol?
51. **Examiner (bank Q51):** What is JSR? **Model answer:** \(10\log_{10}(P_j/P_s)\) dB. **Examiner follow-up:** What power is reference?
52. **Examiner (bank Q52):** What does JSR 0 dB mean? **Model answer:** Equal jammer and clean average powers. **Examiner follow-up:** What is target \(P_j\) if \(P_s=0.5\)?
53. **Examiner (bank Q53):** What is on-tone placement? **Model answer:** A jammer at an allocated candidate, here 2850 Hz. **Examiner follow-up:** Why can it force wrong decisions?
54. **Examiner (bank Q54):** What is between-tone placement? **Model answer:** Here 3000 Hz, between the two central tones. **Examiner follow-up:** Why might it leak into both correlations?
55. **Examiner (bank Q55):** What is outside-bank placement? **Model answer:** One 300-Hz spacing above highest tone: 3750 or 4350 Hz. **Examiner follow-up:** Does that imply zero impact?
56. **Examiner (bank Q56):** How is jammer amplitude chosen? **Model answer:** \(A=\sqrt{P_s10^{\mathrm{JSR}/10}/P_u}\), using measured unit-sine power \(P_u\). **Examiner follow-up:** Why not always \(\sqrt{2P_j}\)?
57. **Examiner (bank Q57):** What detector statistic is used? **Model answer:** Squared magnitude of the complex correlation for each known tone. **Examiner follow-up:** How is a decision made?
58. **Examiner (bank Q58):** How does Q5(C) find the frame? **Model answer:** It searches detected bits for preamble candidates with at most two mismatches, then seeks a CRC-valid frame. **Examiner follow-up:** How are candidates ordered?
59. **Examiner (bank Q59):** What does known timing mean? **Model answer:** Input begins at a whole-symbol sample boundary and every symbol is 80 samples. **Examiner follow-up:** What offset was actually varied?
60. **Examiner (bank Q60):** What is known about carrier? **Model answer:** Exact tone bank is supplied; phase need not be. **Examiner follow-up:** Is frequency offset tracked?

### Difficult (20)

61. **Examiner (bank Q61):** Why can CRC-valid still be a scored failure? **Model answer:** Evaluator also checks true frame start and exact payload. **Examiner follow-up:** Can receiver itself know truth?
62. **Examiner (bank Q62):** Does parser enforce 39 bytes? **Model answer:** No; it reads the declared length and CRC, while evaluator compares the expected payload. **Examiner follow-up:** Why is that useful for a general parser?
63. **Examiner (bank Q63):** What is the supplementary receiver? **Model answer:** `receive_mfsk_packet.m` uses exact preamble matching and a separate seed plan. **Examiner follow-up:** Which results match the signed report?
64. **Examiner (bank Q64):** Define BER here. **Model answer:** Payload decision bit errors divided by 312 times packet trials, evaluated at known true alignment. **Examiner follow-up:** Can BER be low when PER high?
65. **Examiner (bank Q65):** Define PER here. **Model answer:** Failed trials divided by all trials, with true-start, exact-payload, CRC-valid acceptance. **Examiner follow-up:** What failure categories are saved?
66. **Examiner (bank Q66):** Why can a single bit error fail a packet? **Model answer:** A changed protected bit generally changes CRC remainder. **Examiner follow-up:** Is detection mathematically guaranteed for every pattern?
67. **Examiner (bank Q67):** Can PER rise with no payload errors? **Model answer:** Yes; sync or length/CRC bits may fail while aligned payload decisions are correct. **Examiner follow-up:** How is BER counted in that trial?
68. **Examiner (bank Q68):** What is a zero observed BER? **Model answer:** No bit errors in the sampled trials; underlying error probability may be nonzero. **Examiner follow-up:** What is a confidence interval?
69. **Examiner (bank Q69):** What does Wilson interval describe here? **Model answer:** A two-sided 95% interval for packet-error probability estimated from binomial counts. **Examiner follow-up:** Why is it useful at zero failures?
70. **Examiner (bank Q70):** What is an undetected/error outcome in evaluator? **Model answer:** An accepted CRC-valid frame that is wrong in start or payload. **Examiner follow-up:** How many were recorded?
71. **Examiner (bank Q71):** What is tone-center span? **Model answer:** Highest minus lowest tone: \((M-1)\Delta f\), 900 or 2100 Hz. **Examiner follow-up:** Is this occupied bandwidth?
72. **Examiner (bank Q72):** What is the approximate main-lobe span? **Model answer:** Tone span plus \(2/T_s\): 1500 or 2700 Hz in transmitter output. **Examiner follow-up:** Is it measured?
73. **Examiner (bank Q73):** What is equal-tail 99% width? **Model answer:** The positive-frequency interval between 0.5% and 99.5% cumulative FFT power. **Examiner follow-up:** Why does it extend beyond outer tones?
74. **Examiner (bank Q74):** What is the FFT bin spacing? **Model answer:** \(F_s/N=24000/131072=0.183105\) Hz for saved measure. **Examiner follow-up:** Does zero padding increase physical observation time?
75. **Examiner (bank Q75):** Was a window applied in occupied-bandwidth script? **Model answer:** No; it FFTs the raw finite packet after zero padding. **Examiner follow-up:** What can a window alter?
76. **Examiner (bank Q76):** Why are 99% widths about 5.4 kHz? **Model answer:** The finite, phase-reset waveform has sidelobes counted by the equal-tail measure. **Examiner follow-up:** Would continuous phase necessarily give same result?
77. **Examiner (bank Q77):** Define rough spectral efficiency. **Model answer:** Gross bit rate divided by a specified bandwidth, \(\eta=R_b/B\). **Examiner follow-up:** Which B was used?
78. **Examiner (bank Q90):** Can receiver handle arbitrary sample delay? **Model answer:** No demonstrated capability; Q5(C) requires complete aligned symbol blocks and varies whole-symbol guard prefix. **Examiner follow-up:** What estimator would be needed?
79. **Examiner (bank Q91):** Can it track carrier-frequency offset? **Model answer:** No; reference tones are supplied exactly. **Examiner follow-up:** What would offset do to correlation?
80. **Examiner (bank Q92):** Are zero-error cases error free in all future transmissions? **Model answer:** No; finite 1000-packet observations have uncertainty. **Examiner follow-up:** Why report intervals?

### Project-specific (20)

81. **Examiner (bank Q78):** How many signed-report conditions? **Model answer:** \(2\times8\times(1+3\times3)=160\). **Examiner follow-up:** How many trials per condition?
82. **Examiner (bank Q79):** What are 8 dB AWGN results? **Model answer:** 4-FSK 565 errors/312000, PER 0.361; 8-FSK 48/312000, PER 0.027. **Examiner follow-up:** Calculate both BERs.
83. **Examiner (bank Q80):** What happens at 10 dB, 0 dB JSR on tone? **Model answer:** Both PERs are 1.000; errors 74600 and 84034. **Examiner follow-up:** Why can higher Eb/N0 fail to help?
84. **Examiner (bank Q81):** What do 0 errors at 10 dB 8-FSK AWGN prove? **Model answer:** Only no observed errors in 1000 packets/312000 bits. **Examiner follow-up:** What uncertainty remains?
85. **Examiner (bank Q82):** How does outside-bank at 8 dB, JSR 0 compare? **Model answer:** PER 0.342 for 4-FSK and 0.036 for 8-FSK, near AWGN-only 0.361 and 0.027. **Examiner follow-up:** Are those differences statistically conclusive?
86. **Examiner (bank Q83):** Which dataset is Q5(B)? **Model answer:** `results/Q5B/Q5B_channel_summary.csv` reports powers of one realization per condition. **Examiner follow-up:** Where is BER/PER?
87. **Examiner (bank Q84):** Why use 4-FSK and 8-FSK? **Model answer:** They compare two M values at common symbol rate, exposing rate, tone span and reliability trade-offs. **Examiner follow-up:** Which rate differs?
88. **Examiner (bank Q85):** Why use a length byte? **Model answer:** It tells the parser how many payload bytes precede CRC and excludes trailing pad. **Examiner follow-up:** What happens if corrupted?
89. **Examiner (bank Q86):** Why use both BER and PER? **Model answer:** They measure aligned bit decisions and complete packet delivery separately. **Examiner follow-up:** Can their trends differ?
90. **Examiner (bank Q87):** Why calibrate channel separately? **Model answer:** It checks intended powers, seed behavior and placements before receiver evaluation. **Examiner follow-up:** Does calibration produce BER?
91. **Examiner (bank Q88):** Why preserve saved final CSV? **Model answer:** It is the exact signed-report numerical basis with counts and denominators. **Examiner follow-up:** What is separate supplementary CSV?
92. **Examiner (bank Q89):** Which mode should be selected? **Model answer:** State constraints: 4-FSK narrower tone span; 8-FSK higher gross rate and better measured AWGN reliability; both vulnerable to strong on-tone jammer. **Examiner follow-up:** What bandwidth definition is relevant?
93. **Examiner (bank Q93):** Is the channel a full wireless propagation model? **Model answer:** No; AWGN plus one sine, without fading, multipath or Doppler. **Examiner follow-up:** What could multipath change?
94. **Examiner (bank Q94):** Does CRC make messages secure? **Model answer:** No; it is a random-error detector and has no secret key. **Examiner follow-up:** What is needed for authentication?
95. **Examiner (bank Q95):** What signed-PDF distinction matters? **Model answer:** Its 1500/2700 Hz approximate main-lobe spans differ by definition from measured ~5399 Hz 99% widths. **Examiner follow-up:** Which is suitable for a spectrum mask?
96. **Examiner (bank Q96):** What was Rashmi Kini's assigned part? **Model answer:** Q5(A): transmitter, packet/framing and modulation in the signed team description. **Examiner follow-up:** What is its source file?
97. **Examiner (bank Q97):** What was Aryan Malik's assigned part? **Model answer:** Q5(B): AWGN and jammer channel, calibration and integration. **Examiner follow-up:** What does Q5(B) CSV measure?
98. **Examiner (bank Q98):** What was Ayati Rauthan's assigned part? **Model answer:** Q5(C): receiver, sync/CRC and final recovery experiment. **Examiner follow-up:** Which saved dataset matches signed BER/PER?
99. **Examiner (bank Q99):** What was Akshat Mannur's assigned part? **Model answer:** Q5(D): handwritten comparison and engineering decision in signed report. **Examiner follow-up:** Are his separate original scripts confirmed?
100. **Examiner (bank Q100):** What is the provenance boundary? **Model answer:** The signed handwritten D section exists; separately attributable original D scripts/data were not supplied, while Q5(C) final data support cited trends. **Examiner follow-up:** Which file documents this?



