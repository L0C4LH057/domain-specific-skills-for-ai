# ML Foundations Reference

## The ML to LLM Lineage

Understanding where LLMs come from makes you a dramatically better AI engineer. The principles of classical ML — bias-variance tradeoff, overfitting, evaluation rigor, data quality — all apply to modern AI systems.

```
Classical ML (1990s–2010s)
  Logistic Regression, SVM, Random Forest, Gradient Boosting
        ↓
Deep Learning (2012–2017)
  CNNs, RNNs, LSTMs, Autoencoders
        ↓
Transformers (2017–2020)
  "Attention Is All You Need" — Vaswani et al., Google, 2017
        ↓
Large Language Models (2018–2022)
  GPT, BERT, T5, PaLM, Chinchilla
        ↓
Instruction-Tuned LLMs (2022–present)
  InstructGPT, ChatGPT, Claude, Gemini
        ↓
Agentic AI (2023–present)
  Tool use, function calling, multi-agent systems
```

---

## Transformer Architecture (What Powers Every LLM)

```
Input Text
    ↓
Tokenization (text → token IDs)
    ↓
Embedding (token IDs → dense vectors)
    ↓
Positional Encoding (add position information)
    ↓
[N × Transformer Blocks]
  ├── Multi-Head Self-Attention
  │   "Which other tokens should I attend to?"
  ├── Layer Normalization
  ├── Feed-Forward Network
  └── Layer Normalization
    ↓
Output Projection (dense → vocabulary size)
    ↓
Softmax → Probability distribution over next token
    ↓
Sampling → Output token
    ↓
(Repeat until [END] token)
```

### Attention Mechanism (Simplified)
```
For each token in the sequence:
  1. Create Query (Q), Key (K), Value (V) vectors
  2. Attention(Q, K, V) = softmax(QK^T / √d_k) × V
  3. "Attention score" = how much does this token attend to every other token?

Multi-Head: Run this process H times in parallel, with different learned projections
  → Each head learns different types of relationships
  → Concatenate and project back to model dimension
```

**Why this matters for AI engineering**:
- Context window size = maximum sequence length the attention can handle
- Quadratic complexity O(n²) explains why larger context windows are more expensive
- "Lost in the middle" problem = attention score distribution at extreme positions vs middle

---

## Fine-tuning Concepts

### Types of Fine-tuning

**Full Fine-tuning**
- All model weights updated
- Best performance; most expensive (requires high-end GPUs)
- Risk of catastrophic forgetting
- Use case: Domain adaptation where you have thousands of high-quality examples

**LoRA (Low-Rank Adaptation)** — Hu et al., Microsoft, 2021
- Freeze pre-trained weights; add small trainable matrices (rank r) to attention layers
- r = 4–64 (typically); lower r = fewer parameters = faster but less expressive
- Common in practice for fine-tuning 7B–70B models
```python
# LoRA adds ΔW = BA to each weight matrix W
# Where B ∈ ℝ^(d×r) and A ∈ ℝ^(r×k), r << min(d, k)
# Trainable parameters: r × (d + k) instead of d × k
```

**QLoRA** — Dettmers et al., 2023
- LoRA + 4-bit NF4 quantization of base model
- Allows fine-tuning 70B models on a single 48GB GPU (or 13B on 16GB)
- Near-full-fine-tune quality at fraction of compute
- Default choice for most fine-tuning tasks

**RLHF (Reinforcement Learning from Human Feedback)** — How Claude and ChatGPT are aligned
1. Supervised Fine-tuning (SFT) on high-quality demonstrations
2. Train Reward Model (RM) from human preference comparisons
3. RL (PPO) to optimize policy LLM against reward model

**RLAIF (RL from AI Feedback)** — Bai et al., Anthropic, 2022 (Constitutional AI)
- Replace human feedback with AI-generated feedback
- More scalable; Anthropic's approach to Claude's training

### When to Fine-tune vs Prompt Engineer
```
Fine-tune when:
  ✓ Consistent style/format that's hard to specify in a prompt
  ✓ Domain-specific vocabulary the base model doesn't know well
  ✓ Latency-critical (fine-tuned smaller model can beat prompted larger model)
  ✓ Cost-critical at large scale (fine-tuned 7B vs prompted Sonnet)
  ✓ You have 500+ high-quality training examples
  ✗ You have < 100 examples (use few-shot prompting instead)
  ✗ Your task changes frequently (retraining is expensive)
  ✗ You haven't exhausted prompt engineering yet

Prompt engineer first. Fine-tune when prompting hits its ceiling.
```

### Fine-tuning Data Quality Rules
```
1. QUALITY > QUANTITY
   100 perfect examples >> 10,000 mediocre examples

2. DIVERSITY
   Cover the full distribution of inputs, not just common cases

3. CONSISTENCY
   Same task, same format, same quality standard throughout

4. NEGATIVE EXAMPLES
   Include examples showing what NOT to do

5. BALANCE
   Equal representation across all target classes/behaviors

6. EVALUATION SPLIT
   Always hold out 10–20% for evaluation before training starts

Minimum viable dataset sizes:
   Classification fine-tuning: 100–500 examples
   Style/format fine-tuning: 500–2000 examples
   Domain knowledge: 1000–10000 examples
   Full capability addition: 10000+ examples
```

---

## Embeddings Deep Dive

Embeddings are dense vector representations of text that capture semantic meaning. The foundation of RAG, semantic search, and clustering.

```
"dog" → [0.21, -0.54, 0.89, ..., 0.12]  (1536 dimensions)
"cat" → [0.19, -0.51, 0.87, ..., 0.11]  (similar vector = semantically close)
"car" → [-0.43, 0.67, -0.12, ..., 0.88] (distant vector = semantically different)
```

### Similarity Metrics
```python
import numpy as np

# Cosine similarity (most common for semantic search)
def cosine_similarity(a: np.ndarray, b: np.ndarray) -> float:
    return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))
    # Range: -1 (opposite) to 1 (identical)

# Euclidean distance (L2)
def euclidean_distance(a: np.ndarray, b: np.ndarray) -> float:
    return np.linalg.norm(a - b)
    # Range: 0 (identical) to ∞

# Dot product (fast, used with normalized vectors)
def dot_product(a: np.ndarray, b: np.ndarray) -> float:
    return np.dot(a, b)
```

### Matryoshka Embeddings (OpenAI text-embedding-3-*)
OpenAI's newer embedding models support dimension truncation without quality loss:
```python
# Full 3072-dimension embedding (highest quality)
embedding_full = embed_model.embed("text", dimensions=3072)

# Truncated to 256 dimensions (10x smaller, ~5% quality drop)
embedding_small = embed_model.embed("text", dimensions=256)

# Use case: Store full embeddings; search with truncated for speed
```

---

## Model Selection Framework

```
Task Type → Recommended Approach:

GENERATION (open-ended writing, summarization, analysis):
  → Claude Sonnet, GPT-4o, Gemini 1.5 Pro
  
REASONING (math, logic, planning):
  → Claude Opus (extended thinking), GPT-o1/o3, Gemini 1.5 Pro
  
CODING:
  → Claude Sonnet (excellent), GPT-4o, Gemini 1.5 Pro
  
CLASSIFICATION / EXTRACTION (high volume):
  → Claude Haiku, GPT-4o-mini, Gemini Flash
  
LONG DOCUMENT (>100K tokens):
  → Claude (200K), Gemini 1.5 Pro (1M), specialized: Jamba
  
MULTIMODAL (vision + text):
  → GPT-4o (best vision), Claude Sonnet (good vision), Gemini (video)
  
EMBEDDINGS:
  → text-embedding-3-large (best quality), Voyage-3 (for Claude pipelines)
  
SELF-HOSTED (privacy, cost, offline):
  → Llama 3.1 70B (best open), Mistral Large 2, Qwen2.5 72B
  
FINE-TUNING TARGET:
  → Llama 3.1 8B or 70B, Mistral 7B, Qwen2.5 7B (LoRA-friendly)
```

---

## Key ML Metrics for AI Systems

### Classification Tasks
```python
from sklearn.metrics import classification_report, confusion_matrix

# For sentiment classifier, intent router, topic classifier
report = classification_report(y_true, y_pred)
# Gives: precision, recall, F1-score per class + macro/weighted averages

# For imbalanced datasets (common in AI apps):
# Use F1-score, not accuracy
# Use precision when false positives are costly
# Use recall when false negatives are costly
```

### Generation Tasks
```
BLEU Score: n-gram overlap with reference text (0–1; higher = better)
  → Use for: Machine translation, summarization
  → Limitation: Doesn't capture semantic similarity

ROUGE Score: Recall-oriented n-gram overlap
  → ROUGE-1: Unigram overlap
  → ROUGE-L: Longest common subsequence
  → Use for: Summarization evaluation

BERTScore: Semantic similarity via embeddings
  → More meaningful than BLEU/ROUGE for modern LLM outputs
  → Use for: Open-ended generation quality

LLM-as-Judge: Use an LLM to score outputs (G-Eval, MT-Bench)
  → Most practical for complex, subjective quality metrics
  → Use Claude or GPT-4o as judge; correlates well with human judgement
```

---

## References

- **"Attention Is All You Need"** — Vaswani et al., Google Brain, 2017 (Transformer architecture)
- **"BERT: Pre-training of Deep Bidirectional Transformers"** — Devlin et al., Google, 2018
- **"Language Models are Few-Shot Learners (GPT-3)"** — Brown et al., OpenAI, 2020
- **"Training Language Models to Follow Instructions (InstructGPT)"** — Ouyang et al., OpenAI, 2022
- **"Constitutional AI"** — Bai et al., Anthropic, 2022
- **"LoRA: Low-Rank Adaptation of Large Language Models"** — Hu et al., Microsoft, 2021
- **"QLoRA: Efficient Fine-tuning"** — Dettmers et al., UW, 2023
- **"Chinchilla: Training Compute-Optimal LLMs"** — Hoffmann et al., DeepMind, 2022
- **"Scaling Laws for Neural Language Models"** — Kaplan et al., OpenAI, 2020
- **Andrej Karpathy: "Let's Build GPT from Scratch"** — YouTube, 2023
- **Lilian Weng's Blog** — https://lilianweng.github.io/ (essential reading for AI engineers)
- **Jay Alammar's Blog** — https://jalammar.github.io/ (illustrated transformer explanations)
