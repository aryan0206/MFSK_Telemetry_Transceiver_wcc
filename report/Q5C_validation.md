# Q5(C) release validation - 23 October 2026

## Checks performed

- MATLAB R2026b, Linux; single computational thread for the recorded CLI runs.
- Native MATLAB tests: **14 passed, 0 failed, 0 incomplete** (13 receiver test groups plus the existing channel test group).
- Static analysis of all 12 new MATLAB files: **0 Code Analyzer messages**.
- Dependency analysis of the experiment runner: **MATLAB only**.
- Smoke profile: **160 conditions, 3,200 frames, 998,400 evaluated payload bits**.
- Final profile: **160 conditions, 160,000 frames, 49,920,000 evaluated payload bits**.
- Two full independently executed final experiments reproduced **all 160,000 per-trial record matrices exactly**, including seed, guard geometry, error and frame diagnostics.
- Final CSV summary also matched the first full run exactly; every failure-category sum and metric denominator reconciled.
- All **21 original non-Git repository files** match their original SHA-256 hashes. `git diff --exit-code` confirms no tracked original file edits.
- Both clean packets and guarded packets recover the exact 39-byte payload, with CRC A327; the standard 123456789 check is 29B1.
- Intentional protected-bit corruption is rejected. Varied guard lengths, false earlier preambles, truncated/corrupted headers, phase-insensitive tone detection, row/column inputs and invalid inputs are tested.
- Resume versus fresh outcomes match in a bounded integration test. A changed configuration is refused rather than merged.
- All six final PNGs are visually reviewed for labels, light-theme contrast, legends and configuration/sample-size captions.

## Example recorded AWGN-only measurements

Each row contains 1,000 frames and 312,000 evaluated payload bits. These are receiver observations, not a Section D design selection.

| M | Eb/N0 (dB) | Payload bit errors | Packet failures | Raw BER | End-to-end PER |
| --- | --- | --- | --- | --- | --- |
| 4 | 8 | 565 | 361 | 0.0018108974 | 0.361 |
| 4 | 10 | 12 | 10 | 3.8461538e-05 | 0.01 |
| 8 | 8 | 48 | 27 | 0.00015384615 | 0.027 |
| 8 | 10 | 0 | 0 | 0 | 0 |

Across this final grid, 0 accepted-but-incorrect packets were observed. This does not prove CRC collisions cannot occur.

## Independent AWGN sanity check

The noncoherent orthogonal MFSK AWGN expression was calculated independently for a broad-behavior check. No theoretical curve is used as a substitute for measurements.

| M | Eb/N0 (dB) | Analytical BER | Measured raw BER |
| --- | --- | --- | --- |
| 4 | 0 | 0.22933638 | 0.22897436 |
| 4 | 4 | 0.061556723 | 0.061089744 |
| 4 | 8 | 0.0016837267 | 0.0018108974 |
| 8 | 0 | 0.1947156 | 0.19408974 |
| 8 | 4 | 0.030757156 | 0.031224359 |
| 8 | 8 | 0.00014449359 | 0.00015384615 |

Expression reference: https://www.mathworks.com/help/comm/ug/analytical-expressions-used-in-berawgn-function-and-bit-error-rate-analysis-app.html (Orthogonal M-FSK with Noncoherent Detection). Individual payload bits are not treated as independent trials for uncertainty claims.

## Recorded final run information

```text
Profile: final
MATLAB: 2026b
Conditions completed: 160 of 160
Frames: 160000
Payload bits evaluated: 49920000
Elapsed processing seconds: 162.336
BER: Raw payload BER; known evaluation alignment; all payload bits
PER: No CRC-valid frame at correct location with exact payload
PER intervals: Two-sided 95 percent Wilson
Timing: Known symbol timing and tones; unknown frame location
Checkpoints resume only with matching source and configuration hashes.
```

## Reproduction evidence

- `Q5C_execution_log.txt`: passing tests, smoke/final completion and exact full-run repeat check.
- `Q5C_static_analysis.txt`: per-file Code Analyzer counts and dependency analysis.
- `Q5C_original_file_checksums.json`: original file checksums.
- `results/Q5C/final/reproducibility.txt`: full-run comparison outcome.
- `results/Q5C/final/configuration.mat`: numerical configuration, input and receiver-source checksums and MATLAB version.

## Interpretation limits

Known symbol timing and allocated frequencies are assumed; frame location is searched. Eb/N0 is per gross transmitted bit. The actual registration payload is repeated; this is not a random-payload population study. 8-FSK has a 900 bps gross rate and 4-FSK 600 bps because the transmitter holds symbol rate constant. Raw BER uses evaluator-known alignment; PER includes acquisition and CRC outcomes. Zero-error observations do not establish a zero true error rate. Wilson intervals describe fixed-sample trial estimates and are not a guarantee of link reliability.
