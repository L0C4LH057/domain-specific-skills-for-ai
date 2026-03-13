# RAG Systems Reference

## What Is RAG?

Retrieval-Augmented Generation (RAG) is an architecture pattern that enhances LLM outputs by retrieving relevant external knowledge at inference time and injecting it into the model's context. It bridges the gap between a model's static training knowledge and the dynamic, proprietary information a production system requires.

**Core equation**:
```
RAG Output Quality = f(Retrieval Quality × Generation Quality)

Weak retrieval → wrong context → wrong answer (regardless of model quality)
Strong retrieval + weak generation → mediocre answer
Strong retrieval + strong generation → excellent answer
```

---

## RAG Architecture Variants

### 1. Naive RAG (Baseline)
```
Query → Embed → Vector Search → Top-K Chunks → Inject → Generate
```
Simple, fast. Works for uniform, well-structured corpora. Fails on:
- Complex multi-hop queries
- Ambiguous queries
- Very large or diverse corpora

### 2. Advanced RAG
Adds pre-retrieval and post-retrieval optimization stages.
```
Query → [Pre-Processing] → Embed → Vector Search → [Re-ranking] → Filtered Chunks → Generate
```

Pre-retrieval: Query rewriting, HyDE, query expansion
Post-retrieval: Re-ranking, cross-encoding, deduplication, compression

### 3. Modular RAG
Fully composable — any component can be swapped independently.
```
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│  Query   │ → │  Index   │ → │ Retrieve │ → │  Rerank  │ → │ Generate │
│  Module  │   │  Module  │   │  Module  │   │  Module  │   │  Module  │
└──────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘
     ↑                                                              │
     └──────────────── Feedback Loop (optional) ───────────────────┘
```

### 4. Agentic RAG
The retrieval step is itself an agent action. The model decides WHEN to retrieve, WHAT to search for, and HOW MANY TIMES to retrieve.
```
Query → Agent decides if retrieval needed → Formulates search query → 
Retrieves → Evaluates result quality → Retrieves again if needed → Generates
```
Best for: Complex research tasks, multi-document synthesis, iterative question refinement.

### 5. GraphRAG (Microsoft, 2024)
Uses a knowledge graph constructed from the corpus. Enables:
- Relationship-aware retrieval
- Multi-hop reasoning
- Whole-document understanding
Best for: Interconnected knowledge domains (legal, scientific, corporate knowledge)

---

## Chunking Strategies

Chunking is the most underrated variable in RAG quality. Poor chunking = poor retrieval, no matter how good the rest of the pipeline is.

### Fixed-Size Chunking
```python
chunk_size = 512  # tokens
overlap = 50      # tokens (overlap prevents context loss at boundaries)

chunks = text_splitter.split(document, chunk_size=512, overlap=50)
```
Simple. Breaks semantic meaning at boundaries. Best only for uniform documents.

### Semantic Chunking
Split on sentence boundaries, then merge until a semantic similarity threshold is crossed. Produces chunks that are semantically coherent.
```python
from langchain.text_splitter import SemanticChunker
from langchain.embeddings import OpenAIEmbeddings

splitter = SemanticChunker(OpenAIEmbeddings(), breakpoint_threshold_type="percentile")
chunks = splitter.split_text(document)
```

### Recursive/Hierarchical Chunking
Split by document structure: headers → sections → paragraphs → sentences.
```python
from langchain.text_splitter import RecursiveCharacterTextSplitter

splitter = RecursiveCharacterTextSplitter(
    separators=["\n\n\n", "\n\n", "\n", ". ", " "],
    chunk_size=1000,
    chunk_overlap=100
)
```

### Document-Aware Chunking
Respect document structure:
- PDF: Parse by section headings; keep tables intact
- Markdown: Split on ## headers
- Code: Split by function/class boundaries
- HTML: Parse semantic elements (section, article, p)

### Parent-Child Chunking (Best practice for production)
Store LARGE parent chunks for context; retrieve on SMALL child chunks for precision.
```
Parent (2000 tokens) → stored in docstore
  └── Child 1 (256 tokens) → indexed in vector DB
  └── Child 2 (256 tokens) → indexed in vector DB
  └── Child 3 (256 tokens) → indexed in vector DB

Retrieval: Match on child → Return parent for generation
```
This gives the precision of small chunks with the context richness of large chunks.

---

## Embedding Models

| Model | Dimensions | Context | Best For | Cost |
|-------|-----------|---------|----------|------|
| **text-embedding-3-large** (OpenAI) | 3072 | 8191 tokens | High-accuracy semantic search | $0.13/1M tokens |
| **text-embedding-3-small** (OpenAI) | 1536 | 8191 tokens | Cost-sensitive, good quality | $0.02/1M tokens |
| **voyage-3** (Anthropic/Voyage) | 1024 | 32K tokens | Claude-optimized, long docs | $0.06/1M tokens |
| **voyage-3-lite** (Voyage) | 512 | 32K tokens | Budget RAG for Claude | $0.02/1M tokens |
| **bge-large-en** (BAAI) | 1024 | 512 tokens | Open source, self-host | Free |
| **e5-mistral-7b** (Microsoft) | 4096 | 32K tokens | High quality, open source | Free |
| **nomic-embed-text** (Nomic) | 768 | 8192 tokens | Open source, long context | Free |

**Rule**: Match embedding model to the retrieval task. Use the same model for indexing and querying — never mix.

---

## Vector Databases

| Database | Hosting | Best For | Scale |
|----------|---------|----------|-------|
| **Pinecone** | Managed cloud | Production, simplicity | Billions of vectors |
| **Weaviate** | Cloud / Self-host | Hybrid search, multi-modal | Billions |
| **Qdrant** | Cloud / Self-host | High performance, filtering | Billions |
| **Chroma** | Self-host / In-memory | Development, prototyping | Millions |
| **FAISS** (Meta) | Self-host | Research, custom pipelines | Billions (in-memory) |
| **pgvector** (Postgres) | Self-host | Teams already using Postgres | Tens of millions |
| **Milvus** | Cloud / Self-host | Enterprise, high throughput | Trillions |
| **LanceDB** | Embedded / Cloud | Serverless, versioned data | Billions |

**For Nigerian/African deployments**: Consider Qdrant (self-host) or pgvector to avoid data sovereignty issues. Pinecone/Weaviate cloud nodes are US/EU-hosted.

---

## Retrieval Strategies

### Dense Retrieval
Cosine similarity between query and document embeddings. Standard approach.
```python
query_embedding = embed_model.encode(query)
results = vector_db.query(query_embedding, top_k=10)
```

### Sparse Retrieval (BM25 / TF-IDF)
Keyword-based retrieval. Better for exact matches, product codes, names.
```python
from rank_bm25 import BM25Okapi
bm25 = BM25Okapi(tokenized_corpus)
scores = bm25.get_scores(tokenized_query)
```

### Hybrid Retrieval (Best for production)
Combine dense + sparse. Use Reciprocal Rank Fusion (RRF) to merge results.
```python
def hybrid_search(query, vector_db, bm25_index, alpha=0.5):
    dense_results = vector_db.query(embed(query), top_k=20)
    sparse_results = bm25_index.search(query, top_k=20)
    return reciprocal_rank_fusion(dense_results, sparse_results, alpha=alpha)
```

### Query Rewriting
Improve retrieval by transforming the user's query before searching.

**HyDE (Hypothetical Document Embeddings)** — Gao et al., 2022:
```python
hyde_prompt = f"Write a document that would answer this question: {query}"
hypothetical_doc = llm.generate(hyde_prompt)
results = vector_db.query(embed(hypothetical_doc), top_k=10)
```

**Multi-query expansion**:
```python
expansion_prompt = f"""
Generate 4 different versions of this search query to improve retrieval coverage:
Query: {query}
Return as a JSON array of strings.
"""
expanded_queries = llm.generate(expansion_prompt)
all_results = [vector_db.query(embed(q), top_k=5) for q in expanded_queries]
results = deduplicate(flatten(all_results))
```

---

## Re-ranking

After retrieval, re-rank results for relevance before injecting into context. Cross-encoders are far more accurate than bi-encoders for this task.

```python
from sentence_transformers import CrossEncoder

reranker = CrossEncoder("cross-encoder/ms-marco-MiniLM-L-6-v2")

pairs = [(query, chunk.text) for chunk in retrieved_chunks]
scores = reranker.predict(pairs)

reranked = sorted(zip(retrieved_chunks, scores), key=lambda x: x[1], reverse=True)
top_chunks = [chunk for chunk, score in reranked[:5]]
```

**Commercial re-rankers**:
- Cohere Rerank API (excellent quality)
- Voyage AI Rerank
- JinaAI Rerank

---

## RAG Evaluation Framework

Never ship a RAG pipeline without measuring these metrics:

| Metric | What It Measures | Tool |
|--------|-----------------|------|
| **Context Precision** | % of retrieved chunks that are relevant | RAGAS, TruLens |
| **Context Recall** | % of relevant chunks that were retrieved | RAGAS |
| **Answer Faithfulness** | Is the answer supported by the retrieved context? | RAGAS, G-Eval |
| **Answer Relevance** | Does the answer actually address the query? | RAGAS, G-Eval |
| **Retrieval Latency** | Time to retrieve (target: <200ms) | Custom |
| **Generation Latency** | Time to generate (target: <3s for most apps) | Custom |
| **Hallucination Rate** | % of statements not grounded in context | NLP fact-checkers, G-Eval |

### RAGAS (RAG Assessment) — Quick Setup
```python
from ragas import evaluate
from ragas.metrics import faithfulness, answer_relevancy, context_precision

results = evaluate(
    dataset=eval_dataset,  # questions, answers, contexts, ground_truths
    metrics=[faithfulness, answer_relevancy, context_precision]
)
```

---

## Production RAG Architecture

```
                        ┌─────────────────────────────────────────────────────────┐
INDEXING PIPELINE       │                                                         │
(Offline / Batch)       │  Documents → Parse → Chunk → Embed → Index → Vector DB │
                        └─────────────────────────────────────────────────────────┘
                                                     │
                                                     ▼
                        ┌─────────────────────────────────────────────────────────┐
QUERY PIPELINE          │                                                         │
(Online / Real-time)    │  Query → Rewrite → Embed → Hybrid Search → Re-rank →   │
                        │  Compress → Inject → LLM → Output → Groundedness Check │
                        └─────────────────────────────────────────────────────────┘

OBSERVABILITY LAYER:
  Log: query, retrieved_chunks, reranked_chunks, generated_answer, latency, cost
  Monitor: RAGAS metrics weekly; alert on faithfulness drop > 10%
```

---

## References & Papers

- **"Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks"** — Lewis et al., Meta AI, 2020 (original RAG paper)
- **"Precise Zero-Shot Dense Retrieval without Relevance Labels (HyDE)"** — Gao et al., CMU, 2022
- **"GraphRAG: Unlocking LLM Discovery on Narrative Private Data"** — Edge et al., Microsoft, 2024
- **"RAGAS: Automated Evaluation of Retrieval Augmented Generation"** — Es et al., 2023
- **"Lost in the Middle: How Language Models Use Long Contexts"** — Liu et al., 2023
- **"Improving Text Embeddings with Large Language Models"** — Wang et al., Microsoft, 2024
- **LangChain RAG Documentation** — https://python.langchain.com/docs/tutorials/rag/
- **LlamaIndex RAG Guide** — https://docs.llamaindex.ai/en/stable/
- **Weaviate Learning Center** — https://weaviate.io/learn
