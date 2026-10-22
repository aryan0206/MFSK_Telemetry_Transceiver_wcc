# Q5(B) channel: standalone handoff

The repository has a short README and Rashmi's Q5(A) transmitter script; no
group execution guide was present when this component was prepared. This is
only the channel section. It makes no receiver or BER/PER assumptions.

## Function contract

`[rx, components, meta] = apply_channel(tx, params)` in `src/apply_channel.m`
accepts one real-valued sampled passband row or column vector. `rx`,
`components.noise`, and `components.jammer` preserve its shape and length.
`rx = tx + components.noise + components.jammer`.

Required scalar `params` fields:

| Field | Meaning |
| --- | --- |
| `Fs` | Samples per second; Q5(A) uses 24000. |
| `Rs` | Symbols per second; Q5(A) uses 300. |
| `M` | 4 or 8. |
| `EbN0dB` | Requested real-passband Eb/N0, or `Inf` to disable AWGN. |
| `JSRdB` | Requested jammer-to-signal ratio, or `-Inf` to disable jammer. |
| `seed` | Integer from 0 to 2^32-1 for a private MT19937 random stream. |
| `jammerHz` | Required when JSR is finite; strictly between 0 and Fs/2. |
| `jammerPhaseRad` | Optional fixed phase; otherwise sampled from the stream. |

Power is relative to a one-ohm normalized waveform. With clean average power
`Ps = mean(tx.^2)`, gross bit rate `Rb = Rs*log2(M)`, and `Eb = Ps/Rb`, this
implementation uses `N0 = Eb/10^(EbN0dB/10)` and real-sample AWGN variance
`N0*Fs/2`. The bit rate counts all transmitted bit slots, including framing
and padding. This is not payload-only Eb/N0. Noise samples are not rescaled to
exact finite-record power; `meta.targetNoisePower` and
`meta.measuredNoisePower` report the distinction.

The jammer is one continuous sinusoid across the packet, with
`JSR = 10*log10(Pj/Ps)`. Its amplitude is scaled using its measured power over
the actual finite sample vector, so `meta.measuredJSRdB` matches the requested
JSR to numerical precision. `meta` also reports the seed, phase, frequency,
sample count, gross bit rate and measured noise/Jammer powers.

## Q5(A) input for later integration

Use an explicit path to Rashmi's saved `results/transmitter_data.mat` and
select `signals{q}` with `M = Mvalues(q)` and `tones{q}`. The matching elements
are 4-FSK for `q=1` and 8-FSK for `q=2`. Q5(A) uses 80 samples per symbol and
generates a real unit-amplitude sine whose phase restarts at each symbol.
The channel adds impairments sample by sample and preserves symbol timing.
No transmitter workspace variables are required once the MAT file is loaded.
The existing transmitter script itself saves into MATLAB's Current Folder,
so integration should load a known path rather than assume where a fresh run
placed its output.

Example in MATLAB, with this repository as Current Folder:

```matlab
addpath('src');
data = load(fullfile('results','transmitter_data.mat'));
q = 1;
params = struct('Fs',data.Fs, 'Rs',data.Rs, 'M',data.Mvalues(q), ...
    'EbN0dB',6, 'JSRdB',0, 'jammerHz',data.tones{q}(2), ...
    'seed',3128);
[rx, components, meta] = apply_channel(data.signals{q}, params);
```

## Q5(B) experiment procedure

`experiments/run_q5b_channel.m` uses the explicit transmitter MAT path and
defaults to `results/Q5B` as output. It runs both modulation orders at
`EbN0dB = 0:2:14` and, for each, a no-jammer baseline plus JSR values of
`[-10, 0, 10]` dB at three placements:

| Placement | 4-FSK | 8-FSK |
| --- | ---: | ---: |
| On an allocated tone | 2850 Hz | 2850 Hz |
| Between the central tones | 3000 Hz | 3000 Hz |
| One spacing above the highest tone | 3750 Hz | 4350 Hz |

The 160 cases use distinct recorded seeds. Running the experiment saves
`Q5B_channel_cases.mat` with all received/noise/jammer vectors and metadata,
`Q5B_channel_summary.csv` with power measurements, and four PNGs:
received-waveform and received-PSD panels for each modulation. The
representative panels use 6 dB Eb/N0, and 0 dB JSR for jammer cases. These
are channel illustrations and calibration data, not BER/PER results.

From MATLAB with this repository as Current Folder:

```matlab
addpath('tests');
results = runtests('tests/test_apply_channel.m');
assertSuccess(results);
addpath('experiments');
run_q5b_channel
```

`tests/test_apply_channel.m` checks deterministic seeds, shape preservation,
component addition, requested finite-record JSR, approximate measured AWGN
power over a long signal, global RNG isolation, no-impairment pass-through,
and pass-through of Q5(A) saved waveforms when the MAT file is available.
Run the tests before the experiment and cite measured Q5(B) data or figures
only after that run succeeds.
