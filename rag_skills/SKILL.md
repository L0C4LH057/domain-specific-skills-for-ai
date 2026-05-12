---
name: rag-system
description: >
  Comprehensive skill for building, designing, and implementing Retrieval-Augmented Generation (RAG) systems.
  Use this skill whenever a user wants to build a RAG pipeline, vectorize documents, set up a knowledge base,
  implement semantic search, choose a vector database, chunk documents, embed text, design hybrid search,
  build a chatbot over their documents, or improve retrieval quality in any AI application.
  Trigger on any mention of: RAG, vector search, embeddings, chunking, retrieval pipeline, knowledge base,
  document QA, semantic search, vector DB, ingestion pipeline, context retrieval, or "chat with my docs/data".
  Always use this skill for RAG — even if the user only asks a partial question about one component.
---

# RAG System Builder

A complete, production-grade guide for designing and implementing Retrieval-Augmented Generation systems —
from ingestion and vectorization through retrieval, reranking, and generation — for any project, language, or environment.

---

## Quick Navigation

| Section | What's inside |
|---|---|
| [RAG Architecture Overview](#1-rag-architecture-overview) | Core loop, components, mental model |
| [RAG Taxonomy](#2-rag-taxonomy) | 10+ types of RAG with when to use each |
| [Ingestion Pipeline](#3-ingestion-pipeline) | Loading, parsing, cleaning every file type |
| [Chunking Strategies](#4-chunking-strategies) | Fixed, semantic, recursive, contextual, late |
| [Embedding Models](#5-embedding-models) | Model comparison, dimensions, tradeoffs |
| [Vector Databases](#6-vector-databases) | Full comparison table, when to use which |
| [Retrieval Strategies](#7-retrieval-strategies) | Dense, sparse, hybrid, MMR, multi-query |
| [Reranking](#8-reranking) | Cross-encoders, Cohere, LLM-as-judge |
| [Generation Layer](#9-generation-layer) | Prompting, context stuffing, citations |
| [Evaluation](#10-evaluation) | Metrics, RAGAS, custom evals |
| [Best Practices](#11-best-practices) | Production checklist, failure modes |
| [Environment Recipes](#12-environment-recipes) | Python, Node.js, cloud, local, serverless |

For deep dives on specific areas, see `references/` directory.

---

## 1. RAG Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                  OFFLINE: INGESTION                      │
│                                                          │
│  Raw Data ──► Loader ──► Cleaner ──► Chunker ──►        │
│              Embedder ──► Vector Store                   │
└─────────────────────────────────────────────────────────┘
                          │
                          │ (index built once, updated as needed)
                          ▼
┌─────────────────────────────────────────────────────────┐
│                   ONLINE: RETRIEVAL + GENERATION         │
│                                                          │
│  User Query ──► Query Transform ──► Retriever ──►        │
│  Reranker ──► Context Builder ──► LLM ──► Response       │
└─────────────────────────────────────────────────────────┘
```

**Every RAG system has exactly two phases:**

- **Ingestion (offline):** Load → Parse → Clean → Chunk → Embed → Store
- **Serving (online):** Query → Embed → Retrieve → Rerank → Generate

Both phases must be designed together. Poor ingestion causes retrieval failures that no amount of generation tuning can fix.

---

## 2. RAG Taxonomy

### 2.1 Naive RAG
**When:** Prototypes, small corpora (<10K docs), homogeneous text.
**How:** Fixed-size chunk → embed → top-k similarity → stuff into prompt.
**Pros:** Dead simple. **Cons:** Brittle, poor recall on complex queries.

### 2.2 Advanced RAG
**When:** Production with decent query volume. Most real-world use cases.
**How:** Naive RAG + query rewriting + reranking + better chunking.
**Enhancements:** HyDE, multi-query, sentence-window, parent-document.

### 2.3 Modular RAG
**When:** Complex pipelines with multiple data sources, formats, or retrieval strategies.
**How:** Plug-and-play components — swap chunker, embedder, retriever independently.
**Tools:** LangChain, LlamaIndex, Haystack.

### 2.4 Agentic RAG
**When:** Multi-hop questions, research-style queries, iterative reasoning.
**How:** LLM decides *when* and *what* to retrieve in a loop. May call retrieval multiple times.
**Pattern:** ReAct, Reflexion, Self-RAG.

### 2.5 Graph RAG
**When:** Entities and relationships matter (legal, scientific, enterprise knowledge).
**How:** Extract entities → build knowledge graph → traverse graph at retrieval time.
**Tools:** Microsoft GraphRAG, Neo4j + LangChain, LlamaIndex Knowledge Graph.

### 2.6 Hybrid RAG
**When:** Keyword matching + semantic search both matter. Default choice for most production systems.
**How:** BM25 (sparse) + dense embeddings → fuse scores (RRF or linear).
**Key Insight:** Sparse retrieval excels on exact terms; dense on meaning. Hybrid wins almost always.

### 2.7 Multimodal RAG
**When:** Corpora include images, charts, tables, PDFs with figures.
**How:** Embed images with CLIP/ColPali; retrieve images and text together.
**Tools:** ColPali, GPT-4V, Gemini, LlamaIndex MultiModal.

### 2.8 Streaming RAG
**When:** Very large corpora, real-time ingestion, news/log data.
**How:** Use a streaming pipeline (Kafka → Flink → vector DB upsert). Retrieval is the same.

### 2.9 Long-Context RAG
**When:** LLM has 128K+ context; retrieval is expensive or noisy.
**How:** Retrieve many chunks → compress → fit all into context. Trades retrieval precision for simplicity.
**Models:** Gemini 1.5, Claude 3, GPT-4 Turbo.

### 2.10 Self-RAG
**When:** Quality and factuality are critical; willing to pay extra inference cost.
**How:** LLM generates → reflects on whether retrieval is needed → retrieves → critiques output.
**Paper:** Asai et al., 2023.

### 2.11 Corrective RAG (CRAG)
**When:** Retrieved documents may be irrelevant or noisy.
**How:** Evaluate retrieved docs → if poor, rewrite query and search web → correct before generating.

### 2.12 RAG Fusion
**When:** Single queries often miss relevant docs.
**How:** Generate N paraphrased queries → retrieve for each → RRF fusion → single ranked list.

---

## 3. Ingestion Pipeline

**Rule: what you don't capture here, you can never retrieve.**

### 3.1 Loaders by File Type

| Format | Best Tool | Notes |
|---|---|---|
| PDF (text) | `pdfplumber`, `pypdf` | Extract text + tables per page |
| PDF (scanned) | `pytesseract`, AWS Textract, Azure DI | OCR required |
| DOCX | `python-docx`, `mammoth` | Preserve headings for structure |
| PPTX | `python-pptx` | Slide text + speaker notes |
| HTML | `BeautifulSoup`, `trafilatura` | Strip boilerplate, keep structure |
| Markdown | Direct text + parse headers | Headings = natural chunk boundaries |
| CSV/Excel | `pandas` + row/column context | Serialize rows with column names |
| JSON/JSONL | Custom traversal | Flatten nested structures |
| Audio | Whisper → transcript → ingest | STT first |
| Video | ffmpeg + Whisper + frame captions | Timestamp-anchored chunks |
| Code | Tree-sitter AST chunking | Function/class level splits |
| Email | `mailparser`, Gmail API | Thread context matters |
| Web | Playwright/Puppeteer for JS-heavy | Handle pagination |

### 3.2 Cleaning Checklist

```
□ Remove headers/footers/page numbers
□ Normalize whitespace and Unicode
□ Remove boilerplate (copyright notices, nav menus)
□ Fix encoding issues (latin-1 → utf-8)
□ Detect and handle tables separately
□ Preserve semantic markers (headings, list structure)
□ Tag language and extract metadata (title, date, author, source URL)
□ Deduplicate near-identical passages (MinHash or SimHash)
```

### 3.3 Metadata Enrichment

Every chunk should carry metadata. This enables **metadata filtering** at retrieval time.

```python
{
  "chunk_id": "doc-42-chunk-7",
  "source": "employee-handbook.pdf",
  "page": 14,
  "section": "Leave Policy",
  "date_ingested": "2025-01-15",
  "doc_type": "policy",
  "language": "en",
  "text": "..."   # the actual chunk
}
```

---

## 4. Chunking Strategies

**Chunking is the highest-impact tuning parameter in RAG.** Wrong chunk size kills retrieval.

### 4.1 Fixed-Size (Token or Character)
```
Chunk size: 512 tokens, overlap: 50–100 tokens
```
- **Use when:** Homogeneous, well-formatted text
- **Avoid when:** Paragraphs/sections span chunk boundaries frequently

### 4.2 Recursive Character (Default choice)
Split on `\n\n`, then `\n`, then `.`, then ` ` — recursively until under limit.
- Best all-around for markdown, prose, web content
- LangChain: `RecursiveCharacterTextSplitter`

### 4.3 Semantic Chunking
Embed sentences → compute cosine similarity between adjacent sentences → split on similarity drops.
- **Use when:** Document topics shift frequently
- **Library:** `semantic-chunkers` (Aurelio AI), LlamaIndex SemanticSplitter

### 4.4 Document-Structure Chunking
Split on actual document structure: headings, sections, chapters.
- **Use when:** Well-structured docs (handbooks, manuals, legal documents)
- Extract via Markdown headers, DOCX heading styles, PDF outline

### 4.5 Sentence Window (Sliding Window)
Embed single sentences for precision; retrieve surrounding context window (e.g., ±2 sentences) for generation.
- **Best for:** Precise Q&A, factual lookups
- LlamaIndex: `SentenceWindowNodeParser`

### 4.6 Parent-Document Retrieval
Store small chunks (for embedding precision), map each to its large parent chunk (for generation context).
- **Best for:** Balancing retrieval precision with generation coherence
- LangChain: `ParentDocumentRetriever`

### 4.7 Late Chunking (ColBERT-style)
Embed the whole document → pool embeddings post-hoc into chunks. Preserves full document context in embeddings.
- **Best for:** Long documents where early context affects meaning of later passages
- **Library:** `jina-embeddings-v2` with late chunking

### 4.8 Agentic Chunking
Use an LLM to determine where to split. Highest quality, high cost.
- Use for high-value corpora (legal contracts, clinical notes)

### Chunk Size Guidelines

| Use Case | Chunk Size | Overlap |
|---|---|---|
| Dense factual Q&A | 128–256 tokens | 20% |
| General knowledge base | 512 tokens | 10–15% |
| Long-form summarization | 1024–2048 tokens | 5–10% |
| Code (function level) | Variable (1 function) | 0 |

---

## 5. Embedding Models

### 5.1 Model Comparison

| Model | Dim | Context | Multilingual | Use Case |
|---|---|---|---|---|
| `text-embedding-3-small` (OpenAI) | 1536 | 8191 | Yes | General, cost-effective |
| `text-embedding-3-large` (OpenAI) | 3072 | 8191 | Yes | High accuracy |
| `embed-english-v3.0` (Cohere) | 1024 | 512 | No | English precision |
| `embed-multilingual-v3.0` (Cohere) | 1024 | 512 | Yes | 100+ languages |
| `jina-embeddings-v3` (Jina) | 1024 | 8192 | Yes | Open source friendly |
| `bge-large-en-v1.5` (BAAI) | 1024 | 512 | No | Best open local model |
| `e5-mistral-7b` | 4096 | 32768 | Yes | Long context, GPU needed |
| `nomic-embed-text` | 768 | 8192 | No | Free, local, strong |

### 5.2 Selection Guide

```
Need local/offline?     → bge-large, nomic-embed-text, e5
Need multilingual?      → multilingual-e5, Cohere multilingual, jina-v3
Need long context?      → jina-v3, e5-mistral, text-embedding-3 (OpenAI)
Need lowest cost?       → text-embedding-3-small
Need highest accuracy?  → text-embedding-3-large or domain fine-tuned
Building for code?      → voyage-code-2, CodeBERT-based
```

### 5.3 Always Normalize

```python
from sklearn.preprocessing import normalize
vectors = normalize(vectors)  # L2 norm → cosine = dot product
```

### 5.4 Fine-tuning Embeddings
When to fine-tune: domain-specific vocabulary (medical, legal, scientific), proprietary terminology, poor baseline retrieval scores.
- Use `sentence-transformers` with triplet loss
- Minimum 1,000 positive pairs; 10,000+ for strong results

---

## 6. Vector Databases

### 6.1 Comparison Table

| DB | Hosting | Scale | Hybrid | Filtering | Best For |
|---|---|---|---|---|---|
| **Pinecone** | Cloud only | Massive | Yes | Yes | Managed, no-ops |
| **Weaviate** | Cloud + Self | Large | Yes | Yes | Complex schemas |
| **Qdrant** | Cloud + Self | Large | Yes | Yes | Rust-based, fast |
| **Chroma** | Local + Cloud | Medium | No | Yes | Dev/prototyping |
| **Milvus** | Self-hosted | Massive | Yes | Yes | Enterprise self-host |
| **pgvector** | PostgreSQL | Medium | BM25 via ext | Yes | Existing PG infra |
| **Faiss** | In-memory | Large | Manual | Manual | Research, offline |
| **Redis** | Cloud + Self | Medium | Yes | Yes | Low-latency cache+search |
| **LanceDB** | Local + Cloud | Large | Yes | Yes | Embedded, columnar |
| **Supabase** | Cloud | Medium | Yes (pgvector) | Yes | Postgres + vector |

### 6.2 Decision Tree

```
Already on PostgreSQL? → pgvector (minimal new infra)
Need zero ops?         → Pinecone or Weaviate Cloud
Need self-hosted?      → Qdrant or Milvus
Just prototyping?      → Chroma (local) or LanceDB
Need time-travel/versioning? → LanceDB
Need low-latency <10ms? → Qdrant with HNSW tuned
```

### 6.3 Index Types

| Index | Build Time | Query Speed | Memory | Best For |
|---|---|---|---|---|
| **HNSW** | Slow | Very fast | High | Production default |
| **IVF_FLAT** | Fast | Fast | Medium | Large static corpora |
| **IVF_PQ** | Fast | Moderate | Low | Memory-constrained |
| **Flat** | None | Exact (slow) | Low | <100K docs, exact recall |
| **ScaNN** | Medium | Very fast | Medium | Google-scale |

---

## 7. Retrieval Strategies

### 7.1 Dense Retrieval (Semantic)
Embed query → cosine similarity → top-k.
```python
query_embedding = embedder.embed(query)
results = vector_db.search(query_embedding, top_k=10)
```

### 7.2 Sparse Retrieval (BM25)
Classic keyword matching. Best for exact term recall.
```python
from rank_bm25 import BM25Okapi
bm25 = BM25Okapi(tokenized_corpus)
scores = bm25.get_scores(query.split())
```

### 7.3 Hybrid Retrieval (Recommended Default)
Fuse dense + sparse scores with **Reciprocal Rank Fusion (RRF)**:
```python
def rrf(rankings: list[list], k=60):
    scores = {}
    for ranking in rankings:
        for rank, doc_id in enumerate(ranking):
            scores[doc_id] = scores.get(doc_id, 0) + 1 / (k + rank + 1)
    return sorted(scores, key=scores.get, reverse=True)
```
α parameter in linear fusion: start at 0.5 (equal weight), tune toward dense or sparse based on evals.

### 7.4 Multi-Query Retrieval
Generate N rephrasings of the original query → retrieve for each → deduplicate → merge.
```
Original: "What is the return policy?"
Generated: ["How do I return a product?", "What are the refund terms?", "Can I exchange an item?"]
```

### 7.5 HyDE (Hypothetical Document Embeddings)
Generate a *hypothetical answer* to the query → embed that → use it for retrieval.
- Extremely effective when query terms don't match document terms
- Cost: 1 extra LLM call per query

### 7.6 Step-Back Prompting
Generalize the query before retrieval: "What is the boiling point of ethanol?" → "What are the physical properties of ethanol?"
Works well for scientific and technical corpora.

### 7.7 MMR (Maximal Marginal Relevance)
Retrieve diverse results, not just the most similar ones.
```python
# Select docs that maximize relevance while minimizing redundancy
MMR_score = λ * sim(query, doc) - (1-λ) * max(sim(doc, selected))
```

### 7.8 Contextual Compression
Retrieve full chunks → extract only the relevant sentence(s) → pass compressed context to LLM.
- Saves tokens; reduces noise

---

## 8. Reranking

Always rerank when retrieval precision matters. Rerankers are slower but far more accurate than embedding similarity.

### 8.1 Cross-Encoder Rerankers
Take (query, document) pairs → output relevance score. Much slower but highly accurate.

| Model | Speed | Quality |
|---|---|---|
| `cross-encoder/ms-marco-MiniLM-L-6-v2` | Fast | Good |
| `cross-encoder/ms-marco-electra-base` | Medium | Great |
| Cohere `rerank-english-v3.0` | API | Excellent |
| Cohere `rerank-multilingual-v3.0` | API | Excellent |
| `bge-reranker-large` | Local GPU | Excellent |

```python
from sentence_transformers import CrossEncoder
reranker = CrossEncoder('cross-encoder/ms-marco-MiniLM-L-6-v2')
scores = reranker.predict([(query, doc) for doc in candidates])
reranked = sorted(zip(scores, candidates), reverse=True)
```

### 8.2 ColBERT
Late interaction model — token-level matching. Best tradeoff of speed + accuracy.
- **Library:** `ragatouille` (wraps ColBERT v2)

### 8.3 LLM-as-Reranker
Prompt LLM to score or rank documents. Most expensive, highest quality, good for low-volume.

### 8.4 Reranking Pipeline

```
Initial retrieval: top-50 (broad recall)
After reranking:   top-5 to top-10 (high precision)
```
Never rerank the whole corpus. Retrieve broadly, rerank narrowly.

---

## 9. Generation Layer

### 9.1 Context Window Construction

```python
system_prompt = """You are a helpful assistant. Answer using ONLY the provided context.
If the context doesn't contain the answer, say so clearly. Do not make up information."""

context_block = "\n\n---\n\n".join([
    f"[Source: {chunk['source']}, Page: {chunk.get('page', 'N/A')}]\n{chunk['text']}"
    for chunk in reranked_chunks
])

user_prompt = f"""Context:
{context_block}

Question: {query}

Answer:"""
```

### 9.2 Citation Grounding
Always include source metadata in the context so the LLM can cite.
Ask the LLM to output structured JSON with answer + citations:
```json
{
  "answer": "The return window is 30 days...",
  "citations": [{"source": "policy.pdf", "page": 4}]
}
```

### 9.3 Context Ordering
Recent research shows LLMs have "lost in the middle" problem — they pay less attention to middle context.
- Put most relevant chunks **first** and **last**
- Limit to 3–7 chunks for most queries

### 9.4 Streaming Responses
Always stream for user-facing applications. Start streaming as soon as the first token is ready.

### 9.5 Guardrails
- **Faithfulness check:** Does the answer contain only information from the context?
- **Relevance check:** Is the answer actually addressing the question?
- **Safety check:** Moderation for user inputs + outputs

---

## 10. Evaluation

**Never deploy a RAG system without baseline evals.**

### 10.1 Core Metrics

| Metric | Measures | Tool |
|---|---|---|
| **Context Recall** | Did retrieval find the relevant docs? | RAGAS |
| **Context Precision** | Are retrieved docs actually relevant? | RAGAS |
| **Answer Faithfulness** | Does answer stay within the context? | RAGAS |
| **Answer Relevancy** | Does answer address the question? | RAGAS |
| **MRR** | Rank of the first relevant result | Manual |
| **Hit Rate @K** | Is the answer in top-K? | Manual |
| **Latency** | End-to-end response time | Profiling |

### 10.2 RAGAS Setup
```python
from ragas import evaluate
from ragas.metrics import faithfulness, answer_relevancy, context_recall, context_precision

results = evaluate(
    dataset=eval_dataset,  # questions, answers, contexts, ground_truths
    metrics=[faithfulness, answer_relevancy, context_recall, context_precision]
)
```

### 10.3 Building an Eval Dataset
1. Manually write 50–200 Q&A pairs from your corpus
2. Use LLM to generate synthetic Q&A pairs (then human review)
3. Collect real user queries + mark relevant docs (golden set)

### 10.4 A/B Testing Components
Test one variable at a time: chunk size, embedder, retrieval strategy, reranker. Track metric deltas.

---

## 11. Best Practices

### 11.1 Production Checklist

```
INGESTION
□ Idempotent ingestion (re-running doesn't duplicate)
□ Chunk IDs are deterministic and stable
□ Metadata schema is documented and versioned
□ Ingestion errors are logged and retried
□ Near-duplicate detection before embedding

RETRIEVAL
□ Hybrid search enabled (sparse + dense)
□ Metadata filtering available (by date, source, type)
□ Top-K is tuned per use case (start: 10, rerank to 5)
□ Query latency is monitored (target: <500ms)

GENERATION
□ System prompt enforces context-only answering
□ Citations are included in responses
□ Fallback message when no relevant context found
□ Output moderation in place

OPERATIONS
□ Vector DB has backups / point-in-time restore
□ Embedding model version is pinned (changes break recall)
□ Re-embedding pipeline documented for model upgrades
□ User feedback collection (thumbs up/down) for drift detection
```

### 11.2 Common Failure Modes

| Problem | Symptom | Fix |
|---|---|---|
| Chunks too large | Imprecise retrieval, low precision | Smaller chunks + sentence window |
| Chunks too small | Missing context in answers | Parent-document or larger overlap |
| Wrong embedder | Semantically unrelated results | Benchmark multiple embedders |
| No reranking | Top-K has irrelevant docs | Add cross-encoder reranker |
| No metadata filter | Results from wrong time/source | Add filter fields to schema |
| LLM hallucination | Facts not in context | Stricter system prompt + faithfulness eval |
| Index stale | Missing recent documents | Incremental ingestion pipeline |
| Query-doc mismatch | Queries use different vocab than docs | HyDE or query expansion |

### 11.3 Scaling Considerations

- **< 10K docs:** Chroma + any embedder + no reranker needed
- **10K–1M docs:** Qdrant/Weaviate + HNSW + reranker essential
- **> 1M docs:** Milvus/Pinecone + IVF index + caching layer + async ingestion
- **Multi-tenant:** Namespace by tenant in vector DB; never mix embeddings across tenants

### 11.4 Cost Optimization
- Cache embedding results (docs don't change; re-embedding is waste)
- Cache retrieval results for repeated queries (TTL-based Redis cache)
- Use smaller embedding model for candidates, larger for reranking
- Compress vectors (PQ / binary quantization) at scale

---

## 12. Environment Recipes

See `references/` for detailed implementation examples. Summary:

| Environment | Stack |
|---|---|
| **Python (LangChain)** | `references/python-langchain.md` |
| **Python (LlamaIndex)** | `references/python-llamaindex.md` |
| **Node.js / TypeScript** | `references/nodejs.md` |
| **Serverless (Vercel/Lambda)** | `references/serverless.md` |
| **Fully Local (offline)** | `references/local-offline.md` |
| **Cloud (AWS/GCP/Azure)** | `references/cloud.md` |

### Quick-Start: Minimal RAG in Python (< 50 lines)
```python
from openai import OpenAI
import chromadb

client = OpenAI()
db = chromadb.Client()
collection = db.create_collection("docs")

def ingest(texts: list[str], ids: list[str]):
    embeddings = client.embeddings.create(
        model="text-embedding-3-small", input=texts
    ).data
    collection.add(
        embeddings=[e.embedding for e in embeddings],
        documents=texts,
        ids=ids
    )

def query(q: str, k: int = 5) -> str:
    q_emb = client.embeddings.create(
        model="text-embedding-3-small", input=[q]
    ).data[0].embedding
    results = collection.query(query_embeddings=[q_emb], n_results=k)
    context = "\n\n".join(results["documents"][0])
    response = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "system", "content": "Answer using ONLY the context below.\n\n" + context},
            {"role": "user", "content": q}
        ]
    )
    return response.choices[0].message.content
```

---

## References Directory

Load the relevant reference file when the user needs a specific implementation:

- `references/python-langchain.md` — Full LangChain pipeline
- `references/python-llamaindex.md` — Full LlamaIndex pipeline
- `references/nodejs.md` — Node.js + TypeScript implementation
- `references/local-offline.md` — Ollama + local embedders + Chroma
- `references/serverless.md` — Vercel AI SDK + Pinecone + Edge functions
- `references/cloud.md` — AWS Bedrock / GCP Vertex / Azure AI Search
- `references/multimodal.md` — ColPali, CLIP, multimodal RAG
- `references/graph-rag.md` — Knowledge graph construction + retrieval
- `references/evaluation.md` — RAGAS, DeepEval, custom eval harness

---

*Generated by the RAG System Skill. For updates or contributions, modify SKILL.md and reference files.*
