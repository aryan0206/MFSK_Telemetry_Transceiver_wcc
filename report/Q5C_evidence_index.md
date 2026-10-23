# Q5(C) evidence index

All final report figures/results are under `results/Q5C/final`. Smoke data are checks only.

| Evidence | File | What to explain by hand |
| --- | --- | --- |
| Exact payload and CRC recovery, both M | recovery_demonstration.txt | Original/recovered registration text, A327, clean frame start and guarded frame detection |
| Intentional corruption rejection | recovery_demonstration.txt | Same receiver rejects a changed protected payload bit |
| Preamble search and tone energies | receiver_evidence_4FSK.png, receiver_evidence_8FSK.png | Mismatch threshold 2, detected start, evaluator-only true start and strongest-tone energies |
| Raw payload BER | BER_4FSK.png, BER_8FSK.png | Known evaluation alignment, channel settings, all-bit denominator and zero-observation handling |
| End-to-end PER | PER_4FSK.png, PER_8FSK.png | All-frame denominator; acquisition+CRC+undetected errors; 95% Wilson intervals |
| Exact numerical results | summary.csv | M, Eb/N0, JSR, placement, frame/bit counts, BER/PER and intervals |
| Zero BER observations | zero_error_observations.csv | Zero observed errors with tested denominator; not proof of zero true rate |
| Saved channel integration | saved_case_diagnostics.csv | These are single-realization cases from Aryan, separate from repeated trials |
| Reproduction/provenance | configuration.mat, run_info.txt | MATLAB release, settings, seeds, hashes, completeness and timing assumptions |
| Validation summary | report/Q5C_validation.md | Actual checks run and results |

## Short code snapshots

Use readable excerpts instead of shrinking the whole program into one image. Keep the file/function name visible. These are recommendations, not a professor-set screenshot count.

1. `src/prepare_mfsk_detector.m`: public settings and precomputed tone references.
2. `src/mfsk_detect.m`: block reshape, correlation energy, maximum selection and MSB-first mapping.
3. `src/decode_telemetry_frame.m`: candidate search/order, length parsing and CRC acceptance/failure.
4. `src/crc16_ccitt_false.m`: documented convention and byte-update loop; the lookup table initialization may be a separate excerpt if space requires.
5. `src/evaluate_telemetry_trial.m`: BER counting and end-to-end packet outcome; explain why truth is restricted to this evaluator.
6. `experiments/run_q5c_receiver.m`: `run_condition` seed rule/channel/receiver calls and `collect_results` denominators/Wilson interval.

The compact plot panels provide evidence without requiring separate screenshots for every condition. Provide the CSV to Akshat for complete comparisons. Titles/captions must identify which M, channel condition and sample count are being shown.

## Files to send Aryan and Akshat

Send the new source functions, the C runner and C tests; the three C report guides and validation record; and the final results folder. Keep configuration, summary and trial outcomes with figures. Checkpoint files support resume but need not be inserted in the handwritten PDF. Do not submit code or a Markdown report as a substitute for the required handwritten explanations.
