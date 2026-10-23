# Q5(C) receiver handoff - Ayati

## What this adds

Q5(C) completes detection, frame synchronization, CRC validation, payload recovery and BER/PER measurement for Rashmi's transmitter and Aryan's channel. Their existing source files, saved data and figures are unchanged. Q5(D)'s engineering selection remains Akshat's responsibility.

## Run from MATLAB

From the repository root:

```matlab
results = runtests('tests');
assertSuccess(results);
addpath('experiments');
run_q5c_receiver('smoke');   % 20 frames/condition, 3,200 total frames
run_q5c_receiver('final');   % 1,000 frames/condition, 160,000 total frames
```

The runner derives input paths from its own location. If Current Folder is elsewhere, add this repository's `experiments` directory by absolute path first. An optional second positional argument selects another output directory.

The default outputs are `results/Q5C/smoke` and `results/Q5C/final`. A repeated invocation resumes compatible condition checkpoints and reexports summaries/figures. If a source file, input file, MATLAB version or numerical configuration has changed, select a new output directory; do not combine old and new checkpoints.

Bounded test options are `TrialCount`, `ConditionIds`, `StopAfter` and `ExportFigures`. These are name-value arguments. TrialCount is limited to 1,000 by the deterministic seed partition. StopAfter counts visited conditions in the current invocation; rerunning without it finishes any remaining cases. Partial summaries explicitly report how many requested conditions completed. Do not submit partial/smoke outputs as final evidence.

## Exact public contract

- `prepare_mfsk_detector(config)` accepts Fs, Rs, M and a vector of M tone frequencies. It returns reference correlations, rates, tones and symbol dimensions. Prepare once per modulation order.
- `[bits, diagnostics] = mfsk_detect(rx, detector)` accepts a finite real row/column waveform with complete aligned symbols. It returns row bits in MSB-first natural-binary order; optional diagnostics contain one-based tone indices and an nSymbols-by-M energy matrix. Incomplete symbols are rejected, not silently dropped.
- `protocol = q5c_protocol()` contains only the 16 preamble bits and maximum mismatch count (2).
- `frame = decode_telemetry_frame(bits, protocol)` accepts no original payload, true start, checksum reference or expected payload length. It searches candidates by preamble Hamming distance, ties by earliest bit, then accepts the first candidate passing CRC. It parses payload length from the received header and preserves payload bytes.
- `crc16_ccitt_false(bytes)` returns uint16 CRC. It uses an immutable persistent polynomial lookup cache, never payload-dependent shared state.
- `metrics = evaluate_telemetry_trial(decodedBits, frame, truth)` is a separate evaluator. Only this layer knows true frameStartBit, payloadBits and payloadBytes.

Frame fields: status, startBit, preambleErrors, declaredLength, payloadBytes, payloadText, receivedCRC, calculatedCRC, crcOK and candidateCount. Status is `ok`, `no_preamble`, `truncated` or `crc_failed`. If none passes CRC, the best-ranked complete failed candidate is diagnostic only; payloadText must not be presented as a successful recovery. If there are only incomplete candidates, status is truncated.

## Packet and waveform baseline

Preamble A5 5A (16 bits), length byte 39 (8 bits), 39 ASCII payload bytes (312 bits), two CRC bytes (16 bits): 352 unpadded bits. The payload is:

`240953668|240953568|240953138|240953634`

CRC-16/CCITT-FALSE: polynomial 0x1021, initial remainder 0xFFFF, nonreflected input/output, final XOR zero. It protects the length byte and payload, not the preamble. The high CRC byte precedes the low byte. The actual frame CRC is A327; the independent standard check string 123456789 yields 29B1.

Fs=24,000 Hz; Rs=300 symbols/s; N=80 samples/symbol; center=3,000 Hz; spacing=300 Hz. 4-FSK uses 2550, 2850, 3150, 3450 Hz and 600 gross bits/s. 8-FSK uses 1950, 2250, 2550, 2850, 3150, 3450, 3750, 4050 Hz and 900 gross bits/s. Padding after the CRC is 0 and 2 bits respectively. No equal-bit-rate comparison is claimed.

Known symbol timing and known tone frequencies are assumptions. Frame position is unknown and searched. There is no arbitrary sample timing, carrier-frequency correction, fading or multipath model. These are not required additions to this C implementation.

## Experiments and reproducibility

Condition numbering matches Aryan's runner: M=4 then M=8; Eb/N0 0:2:14; baseline then JSR -10, 0, +10 dB, each with on_tone, between_tones, outside_bank. Jammer frequencies are 2850, 3000, 3750 Hz for 4-FSK and 2850, 3000, 4350 Hz for 8-FSK. The third placement is outside the bank, not another on-tone case.

Each repeated trial wraps the unchanged saved packet in 0-8 prefix symbols and 0-4 suffix symbols, drawn uniformly from the allocated tones with phase restarted as in the transmitter. Aryan's channel acts on the entire stream. Guard generation uses a private MT19937 stream with seed 3000000+10000*modulationIndex+trialId; channel seed is 1000000+10000*conditionId+trialId. Prefix/suffix realizations are shared across channel conditions within each modulation/trial. Neither helper changes the global RNG.

The final profile has 160 conditions x 1,000 frames = 160,000 frames and 49,920,000 evaluated payload bits. These are repeated transmissions of the actual fixed registration payload, not uniform random payload traffic. The original 160 stored Q5(B) cases are decoded separately as single-realization integration checks, not mixed into the repeated-trial estimates.

`configuration.mat` records full settings, MATLAB release/version, Git revision, SHA-256 hashes of source/input files, protocol and seed rules. The revision records the baseline commit; hashes identify uncommitted C source precisely. Checkpoints are written per completed condition using a temporary file then renamed. Interrupted conditions restart; completed conditions are reused only with matching fingerprints. Java's bundled SHA-256 implementation is used; no network access is needed during experiments.

## Metric definitions - use these exact labels

- **Raw payload BER, known evaluation alignment:** wrong detected bits at the true payload location, divided by all 312 transmitted payload bits per trial. This includes bits from trials with failed packet acquisition. It measures detector errors, not independently acquired payload alignment.
- **End-to-end PER:** no CRC-valid frame at the correct location with the exact original payload. A wrong-location CRC-valid candidate counts as an error even if it happens to contain the same text.
- **Acquisition failure:** no complete candidate; no_preamble or truncated.
- **CRC rejection:** a complete candidate exists but none passes CRC; crc_failed.
- **Undetected error:** the receiver accepts a CRC-valid candidate that fails evaluator location/payload checks.

PacketErrors = acquisitionFailures + crcRejections + undetectedErrors. These failure categories partition failed packets under the implemented status convention. An evaluator detecting an undetected error is simulation ground truth, not extra information available to a deployed receiver.

PER uses two-sided 95% Wilson intervals over independent trial realizations. Correlated bits within symbols are not treated as independent binomial trials to make BER confidence claims. Zero observations are not proof of a zero underlying rate. Zero-error BER samples are stored as zero, omitted from logarithmic curves, and enumerated in each panel and zero_error_observations.csv. PER plots use a linear 0-1 axis with Wilson error bars. At 1,000 frames the smallest nonzero PER observation is 0.001; zero failures has Wilson upper limit about 0.003827.

## Outputs for Akshat

- `summary.csv`: one row/condition; settings, frames, payloadBits, bitErrors, packetErrors, BER, PER, PERlower95, PERupper95 and failure-category counts.
- `trial_outcomes.mat`: compact per-condition matrices. Column names are stored in config.trialColumns, including trial/channel/guard seeds, geometry, errors, outcomes and frame diagnostics. NaN start/error fields mean no corresponding candidate diagnostic.
- `summary.mat`, `configuration.mat`, per-condition `checkpoints`: numerical reproduction and provenance.
- `saved_case_diagnostics.csv`: explicitly one realization for each of Aryan's stored cases.
- `recovery_demonstration.txt`: both clean and guarded recoveries plus intentional-corruption rejection.
- Six PNG/FIG pairs: BER and PER for each M, plus receiver evidence for each M.
- `run_info.txt`: completion, sample counts, assumptions and timing. Elapsed processing time starts after input/demo checks; it includes checkpoint aggregation and figure export, not MATLAB startup.

Use final-profile files in the report. Review the evidence index and handwritten outline in this directory. Preserve the numerical files alongside figures rather than manually reading values off charts.

## Quality and skill setup

Base MATLAB only, including its built-in unit test framework and bundled Java; no Communications, Statistics, Parallel Computing or MATLAB Test toolbox is required. Precomputed references, vectorized correlations, lookup CRC and preallocated compact trial storage keep the core small. No dynamic eval, global RNG mutation, transmitter rerun or dependence on the base workspace.

The MathWorks-authored matlab-review-code skill was installed separately in the user's skills directory from matlab/matlab-agentic-toolkit revision 7c28d73f275d98c00c21adab6577d6113264472e. Review uses MATLAB checkcode and dependency analysis through the existing CLI; the optional MCP-specific resources are unavailable here. No toolkit/MCP installation or opaque documentation helpers are used. Skill instructions: https://github.com/matlab/matlab-agentic-toolkit/blob/7c28d73f275d98c00c21adab6577d6113264472e/skills-catalog/matlab-core/matlab-review-code/SKILL.md

The receiver acceptance tests exercise CRC reference checks, both clean waveforms, every tone, input validation, guard variation, false preambles, corruption/truncation, metric categories, configuration isolation, Wilson endpoints and checkpoint reproducibility. The existing channel tests must continue passing. See Q5C_validation.md for the recorded release checks.
