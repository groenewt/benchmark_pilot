# RAG Embedding Model Benchmark Report

**Generated:** 2025-11-10 19:33:04
**Models Tested:** 21
**Total Questions:** 600
**Configuration:** 30 chunks × 20 questions

---

## Executive Summary

This benchmark evaluated 21 embedding models for RAG applications.
The average accuracy across all models was 56.9%. The best performing model was emb_essays_qwen3_embedding_8b
with 74.7% accuracy, while emb_essays_embeddinggemma_300m_bf16 scored 17.0%.
Performance varied significantly across question types, with some models showing specialized strengths.

---

## Key Findings

### Performance Patterns

Key patterns observed:
- Question complexity significantly impacts retrieval accuracy
- Model size does not always correlate with performance
- Context window length shows varying importance across models
- License types show no clear performance correlation

### Anomalies Detected


No significant anomalies detected.


---

## 1. Performance Overview

This section presents the overall performance metrics and comparative analysis across all embedding models.

### 1.1 Overall Accuracy Comparison

Horizontal bar chart showing overall accuracy for all models with embedded metadata.

![Overall Accuracy](../results/visualizations/01_performance/viz_01_overall_accuracy.png)

### 1.2 Comprehensive Performance Heatmap

Interactive multi-view heatmap with dropdown selector for RAG performance, external benchmarks, technical specifications, and efficiency metrics. Values are normalized within each category for easy comparison across models.

![Performance Heatmap](../results/visualizations/01_performance/viz_02_performance_heatmap.png)

### 1.3 Top Models Radar Chart

Radar chart comparing the top 3 models across all performance dimensions.

![Top 3 Models Radar](../results/visualizations/01_performance/viz_03_radar_chart.png)

### 1.4 Deviation from Mean

Shows which models perform above or below the average accuracy.

![Deviation from Mean](../results/visualizations/01_performance/viz_04_deviation.png)

---

## 2. Question Category Analysis

Analysis of model performance across different question types: short, long, direct, implied, and unclear.

### 2.1 Developer Comparison

Box plot showing performance distribution by model developer.

![Developer Comparison](../results/visualizations/02_categories/viz_05_developer_comparison.png)

### 2.2 Category Variance

Mean performance with standard deviation for each question category.

![Category Variance](../results/visualizations/02_categories/viz_06_category_variance.png)

### 2.3 Short vs Long Questions

Scatter plot comparing model performance on short vs long questions.

![Short vs Long](../results/visualizations/02_categories/viz_07_short_vs_long.png)

### 2.4 Direct vs Implied Questions

Scatter plot comparing performance on questions requiring direct lookup vs inference.

![Direct vs Implied](../results/visualizations/02_categories/viz_08_direct_vs_implied.png)

---

## 3. Model Characteristics

Analysis of model specifications and their relationship to performance.

### 3.1 Model Efficiency Analysis

Accuracy normalized by model size in parameters.

![Model Efficiency](../results/visualizations/03_characteristics/viz_09_efficiency.png)

### 3.2 Accuracy vs Context Length

Relationship between context window size and accuracy performance.

![Context Length Analysis](../results/visualizations/03_characteristics/viz_10_context_length.png)

### 3.3 Dimensions vs Accuracy

How embedding dimensionality correlates with accuracy.

![Dimensions Analysis](../results/visualizations/03_characteristics/viz_11_dimensions.png)

### 3.4 License Distribution

Model distribution by license type and average performance per license.

![License Analysis](../results/visualizations/03_characteristics/viz_12_license.png)

---

## 4. Deep Dive Analysis

Advanced analytics including correlations, performance ranges, and external benchmark comparisons.

### 4.1 Metric Correlation Matrix

Correlation coefficients between different performance metrics.

![Correlation Matrix](../results/visualizations/04_deep_dive/viz_13_correlation.png)



### 4.2 Performance Range Analysis

Min-max performance ranges for each model across question categories.

![Performance Ranges](../results/visualizations/04_deep_dive/viz_14_performance_range.png)

### 4.3 Multi-Factor Comparison

Grid showing relationships between parameters, context length, dimensions, and accuracy.

![Multi-Factor Analysis](../results/visualizations/04_deep_dive/viz_15_multi_factor.png)

### 4.4 MTEB Benchmark Comparison

Comparison between internal benchmark results and external MTEB scores.

![MTEB Comparison](../results/visualizations/04_deep_dive/viz_16_mteb_comparison.png)



---

## 5. Geographic Analysis

Analysis of model development by country of origin and regional performance patterns.

### 5.1 Model Distribution by Country

Geographic distribution of embedding models showing which regions are leading in development.

![Country Distribution](../results/visualizations/05_metadata_analysis/viz_20_country_distribution.png)



### 5.2 Performance by Country of Origin

Box plot comparing model performance across different countries of origin.

![Country Performance](../results/visualizations/05_metadata_analysis/viz_21_country_performance.png)

### 5.3 Developer Ecosystem by Region

Hierarchical view of the developer ecosystem organized by country.

![Developer Geography](../results/visualizations/05_metadata_analysis/viz_22_developer_geography.png)

---

## 6. Multi-Benchmark Validation

Cross-validation analysis comparing RAG performance with external benchmark scores (MTEB, BEIR, MIRACL, LocoScore).

### 6.1 Benchmark Radar Comparison

Radar chart showing model performance across multiple benchmark systems.

![Benchmark Radar](../results/visualizations/05_metadata_analysis/viz_23_benchmark_radar.png)



### 6.2 Benchmark Correlation Analysis

Correlation matrix showing how different benchmarks relate to each other and to RAG performance.

![Benchmark Correlation](../results/visualizations/05_metadata_analysis/viz_24_benchmark_correlation.png)

### 6.3 Benchmark Coverage Matrix

Matrix showing which models have been tested on which external benchmarks.

![Benchmark Coverage](../results/visualizations/05_metadata_analysis/viz_25_benchmark_coverage.png)

---

## 7. Temporal Evolution Analysis

Performance trends and innovation patterns over time based on model release dates.

### 7.1 Performance Evolution Timeline

Scatter plot showing model releases over time with performance trend line.

![Timeline](../results/visualizations/05_metadata_analysis/viz_26_timeline_scatter.png)



### 7.2 Year-over-Year Performance Trends

Box plot analysis showing performance distribution changes across release years.

![Evolution by Year](../results/visualizations/05_metadata_analysis/viz_27_evolution_by_year.png)

### 7.3 Developer Release History

Timeline showing developer release activity and quality trajectories.

![Developer Timeline](../results/visualizations/05_metadata_analysis/viz_28_developer_release_timeline.png)

---

## 8. System Visualizations

This section provides workflow diagrams and system architecture visualizations to better understand the benchmark process and model relationships.

### 8.1 Benchmark Workflow

The complete RAG benchmark process from configuration to report generation:


flowchart TD
    A[Start: RAG Benchmark] --> B[Load Configuration]
    B --> C[Load Embedding Models]
    C --> D[Load Test Questions]
    D --> E{Process Each Question}
    E --> F[Short Questions]
    E --> G[Long Questions]
    F --> H[Direct Questions]
    F --> I[Implied Questions]
    F --> J[Unclear Questions]
    G --> H
    G --> I
    G --> J
    H --> K[Generate Embeddings]
    I --> K
    J --> K
    K --> L[Retrieve Context]
    L --> M[Evaluate Accuracy]
    M --> N{More Questions?}
    N -->|Yes| E
    N -->|No| O[Calculate Metrics]
    O --> P[Generate Visualizations]
    P --> Q[Generate AI Insights]
    Q --> R[Create Reports]
    R --> S[End: Reports Generated]

    style A fill:#90EE90
    style S fill:#FFB6C1
    style K fill:#87CEEB
    style M fill:#FFD700
    style P fill:#DDA0DD
    style Q fill:#F0E68C
    style R fill:#FFA07A



### 8.2 Model Hierarchy

Organization of embedding models by developer:

```mermaid
graph TD
    ROOT[Embedding Models] --> DEV
    DEV[By Developer]

    DEV --> dev_BAAI_Beijing_Academy_of_Artificial_Intelligence[BAAI (Beijing Academy of Artificial Intelligence)]
    dev_BAAI_Beijing_Academy_of_Artificial_Intelligence --> bge_large_335m["bge large 335m"]
    dev_BAAI_Beijing_Academy_of_Artificial_Intelligence --> bge_m3_567m["bge m3 567m"]

    DEV --> dev_Google_DeepMind[Google DeepMind]
    dev_Google_DeepMind --> embeddinggemma_300m_qat_q4["embeddinggemma 300m qatandlt;br/andgt;q4"]
    dev_Google_DeepMind --> embeddinggemma_300m_qat_q8["embeddinggemma 300m qatandlt;br/andgt;q8"]
    dev_Google_DeepMind --> embeddinggemma_300m_bf16["embeddinggemma 300m bf16"]

    DEV --> dev_IBM_Research_/_IBM_Granite_Team[IBM Research / IBM Granite Team]
    dev_IBM_Research_/_IBM_Granite_Team --> granite_embedding_30m_fp16["granite embedding 30mandlt;br/andgt;fp16"]
    dev_IBM_Research_/_IBM_Granite_Team --> granite_embedding_278m_fp16["granite embedding 278mandlt;br/andgt;fp16"]

    DEV --> dev_Mixedbread_AI_Berlin[Mixedbread AI (Berlin)]
    dev_Mixedbread_AI_Berlin --> mxbai_embed_large["mxbai embed large"]

    DEV --> dev_Nomic_AI[Nomic AI]
    dev_Nomic_AI --> nomic_embed_text_1_5["nomic embed text 1 5"]

    DEV --> dev_Qwen_Team,_Alibaba_Cloud_/_DAMO_Academy[Qwen Team, Alibaba Cloud / DAMO Academy]
    dev_Qwen_Team,_Alibaba_Cloud_/_DAMO_Academy --> qwen3_embedding_4b_q8_0["qwen3 embedding 4b q8 0"]
    dev_Qwen_Team,_Alibaba_Cloud_/_DAMO_Academy --> qwen3_embedding_0_6b_fp16["qwen3 embedding 0 6b fp16"]
    dev_Qwen_Team,_Alibaba_Cloud_/_DAMO_Academy --> qwen3_embedding_0_6b_q8_0["qwen3 embedding 0 6b q8 0"]
    dev_Qwen_Team,_Alibaba_Cloud_/_DAMO_Academy --> qwen3_embedding_8b["qwen3 embedding 8b"]
    dev_Qwen_Team,_Alibaba_Cloud_/_DAMO_Academy --> qwen3_embedding_4b_q4_k_m["qwen3 embedding 4b q4 k m"]

    DEV --> dev_Snowflake_Inc_[Snowflake Inc.]
    dev_Snowflake_Inc_ --> snowflake_arctic_embed_22m["snowflake arctic embedandlt;br/andgt;22m"]
    dev_Snowflake_Inc_ --> snowflake_arctic_embed_110m["snowflake arctic embedandlt;br/andgt;110m"]
    dev_Snowflake_Inc_ --> snowflake_arctic_embed_137m["snowflake arctic embedandlt;br/andgt;137m"]
    dev_Snowflake_Inc_ --> snowflake_arctic_embed_335m["snowflake arctic embedandlt;br/andgt;335m"]
    dev_Snowflake_Inc_ --> snowflake_arctic_embed2_568m["snowflake arctic embed2andlt;br/andgt;568m"]

    DEV --> dev_UKPLab_sentence_transformers[UKPLab (sentence-transformers)]
    dev_UKPLab_sentence_transformers --> all_minilm_22m["all minilm 22m"]
    dev_UKPLab_sentence_transformers --> all_minilm_33m["all minilm 33m"]

    style ROOT fill:#FFD700,stroke:#333,stroke-width:3px
    style DEV fill:#87CEEB,stroke:#333,stroke-width:2px
```


### 8.3 Performance Tiers

Models grouped by performance levels:

```mermaid
graph TB
    ROOT[Performance Tiers] 

    ROOT --> TIER2["Tier 3: Medium<br/>(7 models)"]
    TIER2 --> TIER2_qwen3_embedding_8b["qwen3 embedding 8b<br/>0.7467"]
    TIER2 --> TIER2_qwen3_embedding_4b_q8_0["qwen3 embedding 4bandlt;br/andgt;q8 0<br/>0.7300"]
    TIER2 --> TIER2_bge_m3_567m["bge m3 567m<br/>0.7267"]
    style TIER2 fill:#DAA520,color:#000

    ROOT --> TIER3["Tier 4: Baseline<br/>(14 models)"]
    TIER3 --> TIER3_nomic_embed_text_1_5["nomic embed text 1 5<br/>0.6567"]
    TIER3 --> TIER3_mxbai_embed_large["mxbai embed large<br/>0.6467"]
    TIER3 --> TIER3_bge_large_335m["bge large 335m<br/>0.6283"]
    style TIER3 fill:#CD5C5C,color:#fff

    style ROOT fill:#9370DB,stroke:#333,stroke-width:4px,color:#fff
```


### 8.4 Processing Pipeline

Data flow through the benchmark system:

```mermaid
flowchart LR
    subgraph Input
        M[21 Models]
        Q[Test Questions]
    end

    subgraph Categories
        SHORT[Short: 1]
        LONG[Long: 1]
        DIRECT[Direct: 2]
        IMPLIED[Implied: 1]
        UNCLEAR[Unclear: 1]
    end

    subgraph Processing
        EMB[Embedding<br/>Generation]
        RET[Context<br/>Retrieval]
        EVAL[Accuracy<br/>Evaluation]
    end

    subgraph Outputs
        METRICS[Performance<br/>Metrics]
        VIZ[Visualizations<br/>56 charts]
        INSIGHTS[AI Insights<br/>Analysis]
        REPORT[Final Reports]
    end

    M --> EMB
    Q --> EMB
    EMB --> SHORT
    EMB --> LONG
    SHORT --> DIRECT
    SHORT --> IMPLIED
    SHORT --> UNCLEAR
    LONG --> DIRECT
    LONG --> IMPLIED
    LONG --> UNCLEAR
    DIRECT --> RET
    IMPLIED --> RET
    UNCLEAR --> RET
    RET --> EVAL
    EVAL --> METRICS
    METRICS --> VIZ
    METRICS --> INSIGHTS
    VIZ --> REPORT
    INSIGHTS --> REPORT

    style M fill:#90EE90
    style Q fill:#87CEEB
    style METRICS fill:#FFD700
    style VIZ fill:#DDA0DD
    style INSIGHTS fill:#F0E68C
    style REPORT fill:#FFB6C1
```


### 8.5 Category Performance Flow

How question categories contribute to overall performance:

```mermaid
flowchart LR
    subgraph Question_Types[Question Types]
        SHORT[Short<br/>0.539]
        LONG[Long<br/>0.668]
    end

    subgraph Intent_Types[Intent Types]
        DIRECT[Direct<br/>0.592]
        IMPLIED[Implied<br/>0.598]
        UNCLEAR[Unclear<br/>0.450]
    end

    subgraph Result[Overall Performance]
        OVERALL[Overall Accuracy<br/>0.569]
    end

    SHORT -.-> DIRECT
    SHORT -.-> IMPLIED
    SHORT -.-> UNCLEAR
    LONG -.-> DIRECT
    LONG -.-> IMPLIED
    LONG -.-> UNCLEAR
    DIRECT --> OVERALL
    IMPLIED --> OVERALL
    UNCLEAR --> OVERALL

    style SHORT fill:#87CEEB
    style LONG fill:#90EE90
    style DIRECT fill:#FFD700
    style IMPLIED fill:#DDA0DD
    style UNCLEAR fill:#FFB6C1
    style OVERALL fill:#FF6347,color:#fff,stroke:#000,stroke-width:3px
```


### 8.6 Top Models Comparison

Head-to-head comparison of top 5 performing models:

```mermaid
graph LR
    BENCH[RAG Benchmark] 

    BENCH --> M1["#1: qwen3 embedding 8b<br/>Accuracy: 0.7467"]
    style M1 fill:#2E8B57,color:#fff,stroke:#000,stroke-width:3px
    BENCH --> M2["#2: qwen3 embeddingandlt;br/andgt;4b q8 0<br/>Accuracy: 0.7300"]
    style M2 fill:#3CB371,color:#fff
    BENCH --> M3["#3: bge m3 567m<br/>Accuracy: 0.7267"]
    style M3 fill:#90EE90,color:#000
    BENCH --> M4["#4: qwen3 embeddingandlt;br/andgt;4b q4 k m<br/>Accuracy: 0.7217"]
    style M4 fill:#F0E68C,color:#000
    BENCH --> M5["#5: qwen3 embedding 0andlt;br/andgt;6b q8 0<br/>Accuracy: 0.7167"]
    style M5 fill:#FFD700,color:#000

    style BENCH fill:#9370DB,stroke:#333,stroke-width:4px,color:#fff
```


### 8.7 Geographic Distribution

Global distribution of embedding models:

```mermaid
graph TB
    ROOT[Global Distribution] 

    ROOT --> North_America[North America]
    North_America --> North_America_USA["USA<br/>(11 models)"]
    North_America_USA --> USA_snowflake_arctic_embed2_568m["snowflake arcticandlt;br/andgt;embed2 568m<br/>0.7033"]

    ROOT --> Asia[Asia]
    Asia --> Asia_China["China<br/>(7 models)"]
    Asia_China --> China_qwen3_embedding_8b["qwen3 embedding 8b<br/>0.7467"]

    ROOT --> Europe[Europe]
    Europe --> Europe_Germany["Germany<br/>(3 models)"]
    Europe_Germany --> Germany_mxbai_embed_large["mxbai embed large<br/>0.6467"]

    style ROOT fill:#9370DB,stroke:#333,stroke-width:3px,color:#fff
```


### 8.8 System Architecture

Complete system architecture showing all components:

```mermaid
graph TB
    subgraph Config[Configuration Layer]
        EMB_CFG[embedding.json<br/>Model Metadata]
        BENCH_CFG[Benchmark Config]
    end

    subgraph Data[Data Layer]
        MODELS[Embedding Models<br/>15 models]
        QUESTIONS[Test Questions<br/>5 questions]
        RESULTS[results.csv]
    end

    subgraph Processing[Processing Layer]
        EMBED[Embedding<br/>Generation]
        RAG[RAG Pipeline]
        EVAL[Evaluation<br/>Engine]
    end

    subgraph Analysis[Analysis Layer]
        STATIC[Static Charts<br/>28 matplotlib]
        INTERACTIVE[Interactive Charts<br/>28 plotly]
        INSIGHTS[AI Insights<br/>Local Large Language Model Ollama 🦙]
        MERMAID[Workflow Diagrams<br/>8 mermaid]
    end

    subgraph Output[Output Layer]
        MD_REPORT[Markdown Report]
        HTML_REPORT[HTML Report]
        DASHBOARD[Streamlit Dashboard]
    end

    EMB_CFG --> MODELS
    BENCH_CFG --> QUESTIONS
    MODELS --> EMBED
    QUESTIONS --> EMBED
    EMBED --> RAG
    RAG --> EVAL
    EVAL --> RESULTS
    RESULTS --> STATIC
    RESULTS --> INTERACTIVE
    RESULTS --> INSIGHTS
    RESULTS --> MERMAID
    EMB_CFG --> INSIGHTS
    STATIC --> MD_REPORT
    STATIC --> HTML_REPORT
    INTERACTIVE --> HTML_REPORT
    INSIGHTS --> MD_REPORT
    INSIGHTS --> HTML_REPORT
    MERMAID --> MD_REPORT
    MERMAID --> HTML_REPORT
    RESULTS --> DASHBOARD
    EMB_CFG --> DASHBOARD

    style Config fill:#E6E6FA
    style Data fill:#F0E68C
    style Processing fill:#87CEEB
    style Analysis fill:#DDA0DD
    style Output fill:#90EE90
```


---

## Model Recommendations

### Use Case: General Purpose RAG


#### General Purpose RAG

Recommended: emb_essays_qwen3_embedding_8b - Best overall performance


#### Resource-Constrained Environments

See benchmark results for small model options


#### Long Document Understanding

See Long Accuracy results for specialized models


#### Complex Inference Tasks

See Implied Accuracy results for reasoning-capable models



---

## Summary Statistics

### Overall Performance

| Metric | Value |
|--------|-------|
| Average Accuracy | 56.9% |
| Best Model | emb_essays_qwen3_embedding_8b (74.7%) |
| Worst Model | emb_essays_embeddinggemma_300m_bf16 (17.0%) |
| Performance Range | 57.7% |
| Standard Deviation | 18.4% |

### Category Performance

| Category | Average | Best Model | Best Score |
|----------|---------|------------|------------|

| Short | 53.9% | emb_essays_snowflake_arctic_embed2_568m | 71.7% |

| Long | 66.8% | emb_essays_qwen3_embedding_4b_q8_0 | 83.3% |

| Direct | 59.2% | emb_essays_bge_m3_567m | 79.2% |

| Implied | 59.8% | emb_essays_qwen3_embedding_8b | 79.2% |

| Unclear | 45.0% | emb_essays_qwen3_embedding_8b | 66.7% |


---

## Methodology

**Benchmark Configuration:**
- **Number of Chunks:** 30 random text chunks
- **Questions per Chunk:** 20
- **Question Distribution:** {'short': 4, 'long': 4, 'direct': 4, 'implied': 4, 'unclear': 4}
- **Search Depth (TOP_K):** 10
- **Generation Model:** llama3.1:8b-instruct-q8_0

**Question Types:**
1. **Short:** Simple, direct questions under 10 words
2. **Long:** Detailed, comprehensive questions requiring full context
3. **Direct:** Questions about explicitly stated information
4. **Implied:** Questions requiring inference and contextual understanding
5. **Unclear:** Vague or ambiguous questions about general topics

**Evaluation Metric:**
Accuracy is measured as the percentage of questions where the correct source chunk appears in the TOP_K vector search results.

---

## Data Files

- **Results Summary:** `results/results.csv`
- **Detailed Results:** `results/detailed_results.csv`
- **Questions:** `questions.csv`
- **Source Chunks:** `chunks.csv`
- **Model Metadata:** `configs/embedding.json`

---

*Report generated using Ollama-powered insights with model: llama3.1:8b-instruct-q8_0*