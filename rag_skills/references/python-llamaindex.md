# RAG with LlamaIndex (Python)

LlamaIndex is optimized for complex document hierarchies, agentic RAG, and multi-document reasoning.

## Installation

```bash
pip install llama-index llama-index-vector-stores-qdrant \
            llama-index-embeddings-openai llama-index-llms-openai \
            llama-index-postprocessor-cohere-rerank ragas
```

---

## 1. Basic Ingestion with Sentence Window

```python
from llama_index.core import SimpleDirectoryReader, VectorStoreIndex
from llama_index.core.node_parser import SentenceWindowNodeParser
from llama_index.core.postprocessor import MetadataReplacementPostProcessor
from llama_index.embeddings.openai import OpenAIEmbedding
from llama_index.llms.openai import OpenAI

# Node parser: embed single sentences, retrieve surrounding window
node_parser = SentenceWindowNodeParser.from_defaults(
    window_size=3,           # ±3 sentences of context
    window_metadata_key="window",
    original_text_metadata_key="original_text"
)

documents = SimpleDirectoryReader("./data").load_data()
nodes = node_parser.get_nodes_from_documents(documents)

# Build index
index = VectorStoreIndex(
    nodes,
    embed_model=OpenAIEmbedding(model="text-embedding-3-small")
)
```

---

## 2. Parent-Document Retriever

```python
from llama_index.core.node_parser import HierarchicalNodeParser, get_leaf_nodes
from llama_index.core.retrievers import AutoMergingRetriever
from llama_index.core.storage import StorageContext
from llama_index.core import VectorStoreIndex

# Parse into 3 levels: 2048 → 512 → 128 tokens
node_parser = HierarchicalNodeParser.from_defaults(
    chunk_sizes=[2048, 512, 128]
)

nodes = node_parser.get_nodes_from_documents(documents)
leaf_nodes = get_leaf_nodes(nodes)  # Smallest chunks — what gets embedded

storage_context = StorageContext.from_defaults()
storage_context.docstore.add_documents(nodes)  # All levels stored

index = VectorStoreIndex(leaf_nodes, storage_context=storage_context)

# Auto-merging: if enough leaf nodes from same parent are retrieved, return parent
base_retriever = index.as_retriever(similarity_top_k=12)
retriever = AutoMergingRetriever(base_retriever, storage_context, verbose=True)
```

---

## 3. Query Engine with Reranking

```python
from llama_index.postprocessor.cohere_rerank import CohereRerank
from llama_index.core.query_engine import RetrieverQueryEngine
from llama_index.core.postprocessor import SimilarityPostprocessor

reranker = CohereRerank(api_key="...", top_n=5)
similarity_filter = SimilarityPostprocessor(similarity_cutoff=0.7)

# Replace window metadata with original sentence window at generation time
window_replacer = MetadataReplacementPostProcessor(target_metadata_key="window")

query_engine = RetrieverQueryEngine.from_args(
    retriever=retriever,
    node_postprocessors=[similarity_filter, reranker, window_replacer],
    llm=OpenAI(model="gpt-4o", temperature=0),
    response_mode="compact"  # or "tree_summarize" for large contexts
)

response = query_engine.query("What are the key findings in section 3?")
print(response.response)
for node in response.source_nodes:
    print(f"  [{node.score:.3f}] {node.metadata.get('file_name')}")
```

---

## 4. Agentic RAG (ReAct)

```python
from llama_index.core.tools import QueryEngineTool, ToolMetadata
from llama_index.core.agent import ReActAgent

# Multiple knowledge bases as tools
tools = [
    QueryEngineTool(
        query_engine=query_engine,
        metadata=ToolMetadata(
            name="internal_docs",
            description="Useful for answering questions about internal company policies and procedures."
        )
    ),
    QueryEngineTool(
        query_engine=technical_query_engine,
        metadata=ToolMetadata(
            name="technical_docs",
            description="Useful for answering technical implementation questions."
        )
    )
]

agent = ReActAgent.from_tools(
    tools,
    llm=OpenAI(model="gpt-4o"),
    verbose=True,
    max_iterations=10
)

response = agent.chat("What does the security policy say about API keys and how do I implement that?")
```

---

## 5. Semantic Chunking

```python
from llama_index.core.node_parser import SemanticSplitterNodeParser

splitter = SemanticSplitterNodeParser(
    buffer_size=1,           # adjacent sentences to compare
    breakpoint_percentile_threshold=95,  # higher = fewer, larger chunks
    embed_model=OpenAIEmbedding(model="text-embedding-3-small")
)

nodes = splitter.get_nodes_from_documents(documents)
```

---

## 6. Sub-Question Query Engine (Multi-Document)

```python
from llama_index.core.query_engine import SubQuestionQueryEngine

# Break complex query into sub-questions, answer each, synthesize
sub_question_engine = SubQuestionQueryEngine.from_defaults(
    query_engine_tools=tools,
    llm=OpenAI(model="gpt-4o"),
    verbose=True
)

response = sub_question_engine.query(
    "Compare the Q2 and Q3 financial performance and explain the main differences."
)
```

---

## 7. Qdrant as Production Vector Store

```python
import qdrant_client
from llama_index.vector_stores.qdrant import QdrantVectorStore
from llama_index.core import StorageContext, VectorStoreIndex

client = qdrant_client.QdrantClient(url="http://localhost:6333")
vector_store = QdrantVectorStore(client=client, collection_name="my_docs")
storage_context = StorageContext.from_defaults(vector_store=vector_store)

index = VectorStoreIndex.from_documents(
    documents,
    storage_context=storage_context,
    embed_model=OpenAIEmbedding(model="text-embedding-3-small")
)

# Later: reload without re-embedding
index = VectorStoreIndex.from_vector_store(
    vector_store,
    embed_model=OpenAIEmbedding(model="text-embedding-3-small")
)
```

---

## 8. Metadata Filtering

```python
from llama_index.core.vector_stores import MetadataFilter, MetadataFilters, FilterOperator

# Filter by document type and date
filters = MetadataFilters(filters=[
    MetadataFilter(key="doc_type", value="policy"),
    MetadataFilter(key="year", value=2024, operator=FilterOperator.GTE)
])

query_engine = index.as_query_engine(filters=filters)
```
