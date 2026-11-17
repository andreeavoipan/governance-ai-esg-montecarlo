# Reproducibility package

**Governance Strength and AI Adoption: A Monte Carlo Simulation of Innovation, Risk, and ESG Performance**

Simulation code, data, and robustness analyses for the manuscript submitted to
*World* (MDPI), manuscript **world-4454304**. This repository is provided for
editorial and peer-review purposes so that all reported results can be
reproduced exactly.

Authors: Dorel Badea, Andreea Elena Voipan (corresponding), Olga Bucovetchi.

---

## Requirements

- MATLAB **R2025b** (The MathWorks, Inc.)
- **Statistics and Machine Learning Toolbox** (pseudo-random generation,
  triangular sampling, non-parametric tests)

No other toolboxes or external dependencies are needed. All random-number seeds
are fixed in the scripts, so every run is bit-for-bit reproducible.

---

## Files

| File | Purpose |
|------|---------|
| `figures_final_v6.m` | Main script. Runs the full Monte Carlo simulation and generates every figure and numerical result in the manuscript body (Tables 3–6, Figures 2–6, the second-order Monte Carlo of Section 4.5). |
| `robustness_v1.m` | Robustness suite (Appendix B, part 1). Reuses the exact structural model of `figures_final_v6.m` but makes the noise, the AI×governance interaction, governance cost, AI–governance correlation, the aggregation rule, and the performance weights configurable. Runs: baseline reproduction (EXP0), noise-sensitivity sweep (EXP1), structural-stress battery under relaxed sign constraints (EXP2), and alternative performance-weighting schemes (EXP3). Writes a plain-text report plus `robustness_results.mat`, CSV summaries, and diagnostic figures. |
| `robustness_v2.m` | Threshold search (Appendix B, part 2). Extends `robustness_v1.m` with the reviewer-requested adverse structures, each as an intensity sweep that locates the point at which the Hybrid scenario (S4) stops winning: inverted-U governance→innovation (EXP4A), governance cost on innovation (EXP4B) and on performance (EXP4C), overlapping scenario boundaries (EXP4D), AI–governance correlation (EXP4E), and a combined adversarial second-order Monte Carlo (EXP4F). Writes `robustness_v2_results.mat` and `fig_rob_thresholds`. |
| `policy_space.m` | Computes the “% of AI×GOV space” column of the policy table (Table 6): the fraction of a uniform grid over (A, G) ∈ [0, 1]² (step 0.001) at which the deterministic model output satisfies each strategic constraint. |
| `corr_per_scenario.m` | Computes the within-scenario Pearson correlation matrices from the structural model: one per scenario (Supplementary Material S1), their average (Table 5), and the heat-map (Figure 4). Reported at large N so the three-decimal values are converged (seed-independent). |
| `minimal_dataset.xlsx` | Minimal dataset with the key numerical outputs: descriptive statistics, the within-scenario correlation matrix, the second-order Monte Carlo outcomes, and the baseline model parameters. |
| `README.md` | This file. |

---

## How to reproduce

Open MATLAB, change to this folder, and run:

```matlab
>> figures_final_v6     % main results: Tables 3–6, Figures 2–6, Section 4.5
>> robustness_v1        % Appendix B: noise, structural stress, weighting schemes
>> robustness_v2        % Appendix B: threshold search + combined adversarial MC
```

Each script is self-contained, prints its results to the Command Window, and
saves its figures and output tables to the working folder.

---

## Random-number seeds (for exact reproduction)

- **First-order simulation:** `rng(41 + k)` for scenario `k` in `{1,2,3,4}`
  (S1 = 42, S2 = 43, S3 = 44, S4 = 45); 10,000 draws per scenario.
- **Second-order Monte Carlo, outer draws:** `rng(5000 + j)` for draw `j = 1..500`.
- **Second-order Monte Carlo, inner draws:** `rng(5000 + j*10 + k)` for scenario
  `k`; 2,000 inner draws per scenario.
- **Robustness (`robustness_v1/v2`):** the same scheme, with the combined
  adversarial draws of EXP4F seeded `rng(7000 + j)`.

---

## Baseline model parameters (manuscript Table 2)

| Parameter | Symbol | Baseline | Min | Max |
|-----------|--------|----------|-----|-----|
| AI → Innovation (direct)        | β₁      | 0.70 | 0.50 | 0.90 |
| Governance → Innovation         | β₂      | 0.15 | 0.05 | 0.25 |
| AI × Governance synergy         | β₃      | 0.15 | 0.05 | 0.25 |
| AI → Risk (gross)               | α₁      | 0.60 | 0.40 | 0.80 |
| Governance → Risk (mitigation)  | α₂      | 0.50 | 0.30 | 0.70 |
| Governance → ESG                | β_gov   | 0.85 | 0.70 | 0.95 |
| AI → ESG (direct)               | β_ai    | 0.10 | 0.05 | 0.20 |
| Risk → ESG penalty              | γ       | 20.0 | 10.0 | 30.0 |
| Innovation weight               | w_I     | 0.50 | 0.40 | 0.60 |
| ESG weight                      | w_E     | 0.30 | 0.20 | 0.40 |
| Risk penalty weight             | w_R     | 0.20 | 0.10 | 0.30 |
| Risk floor                      | ρ       | 0.05 | 0.02 | 0.08 |

Noise standard deviations: σ_I = σ_E = σ_P = 2.0 (0–100 scale); σ_R = 0.02
(0–1 scale). Held constant across all analyses in the main text; varied
explicitly in the noise-sensitivity analysis of `robustness_v1.m` (EXP1).

---

## Citation

If you use this code, please cite the manuscript:

> Badea, D.; Voipan, A.E.; Bucovetchi, O. Governance Strength and AI Adoption:
> A Monte Carlo Simulation of Innovation, Risk, and ESG Performance. *World*
> (MDPI), manuscript world-4454304 (under review).

---

## License

Released under the MIT License (see `LICENSE`).

## Contact

Corresponding author: Andreea Elena Voipan — andreea.voipan@ugal.ro
