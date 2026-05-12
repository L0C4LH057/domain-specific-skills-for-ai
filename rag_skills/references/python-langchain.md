# RAG with LangChain (Python)

Full production-grade pipeline using LangChain v0.2+.

## Installation

```bash
pip install langchain langchain-openai langchain-community langchain-chroma \
            rank-bm25 sentence-transformers ragas chromadb tiktoken pypdf \
            langchain-cohere unstructured[all-docs]
```

---

## 1. Document Loading and Ingestion

```python
from langchain_community.document_loaders import (
    PyPDFLoader, DirectoryLoader, UnstructuredWordDocumentLoader,
    WebBaseLoader, CSVLoader, JSONLoader
)
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_openai import OpenAIEmbeddings
from langchain_chroma import Chroma
import hashlib

def load_documents(source_path: str):
    """Load from a directory of mixed file types."""
    loaders = [
        DirectoryLoader(source_path, glob="**/*.pdf", loader_cls=PyPDFLoader),
        DirectoryLoader(source_path, glob="**/*.docx", loader_cls=UnstructuredWordDocumentLoader),
        DirectoryLoader(source_path, glob="**/*.csv", loader_cls=CSVLoader),
    ]
    docs = []
    for loader in loaders:
        docs.extend(loader.load())
    return docs

def chunk_documents(docs, chunk_size=512, chunk_overlap=64):
    splitter = RecursiveCharacterTextSplitter(
        chunk_size=chunk_size,
        chunk_overlap=chunk_overlap,
        separators=["\n\n", "\n", ". ", " ", ""],
        length_function=len,
    )
    chunks = splitter.split_documents(docs)
    # Add stable chunk IDs
    for chunk in chunks:
        content_hash = hashlib.md5(chunk.page_content.encode()).hexdigest()[:8]
        source = chunk.metadata.get("source", "unknown")
        chunk.metadata["chunk_id"] = f"{source}-{content_hash}"
    return chunks

def build_vectorstore(chunks, persist_dir="./vectorstore"):
    embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
    vectorstore = Chroma.from_documents(
        documents=chunks,
        embedding=embeddings,
        persist_directory=persist_dir,
        collection_metadata={"hnsw:space": "cosine"}
    )
    return vectorstore
```

---

## 2. Hybrid Retriever (Dense + BM25)

```python
from langchain.retrievers import BM25Retriever, EnsembleRetriever

def build_hybrid_retriever(vectorstore, chunks, k=10, weights=(0.5, 0.5)):
    """Combine semantic (dense) and keyword (sparse) retrieval."""
    dense_retriever = vectorstore.as_retriever(search_kwargs={"k": k})
    sparse_retriever = BM25Retriever.from_documents(chunks, k=k)
    hybrid = EnsembleRetriever(
        retrievers=[sparse_retriever, dense_retriever],
        weights=list(weights)
    )
    return hybrid
```

---

## 3. Multi-Query Retriever

```python
from langchain.retrievers.multi_query import MultiQueryRetriever
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(model="gpt-4o-mini", temperature=0)

multi_query_retriever = MultiQueryRetriever.from_llm(
    retriever=vectorstore.as_retriever(search_kwargs={"k": 10}),
    llm=llm
)
```

---

## 4. Contextual Compression + Reranking

```python
from langchain.retrievers import ContextualCompressionRetriever
from langchain_cohere import CohereRerank

compressor = CohereRerank(model="rerank-english-v3.0", top_n=5)
compression_retriever = ContextualCompressionRetriever(
    base_compressor=compressor,
    base_retriever=hybrid_retriever
)
```

---

## 5. RAG Chain with Citations

```python
from langchain.chains import RetrievalQA
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables import RunnablePassthrough

SYSTEM_PROMPT = """You are an expert assistant. Answer using ONLY the context provided.
If the context doesn't contain enough information, say "I don't have enough information to answer this."
Always cite your sources using [Source: filename, page X] notation.

Context:
{context}"""

prompt = ChatPromptTemplate.from_messages([
    ("system", SYSTEM_PROMPT),
    ("human", "{question}")
])

def format_docs(docs):
    return "\n\n---\n\n".join([
        f"[Source: {d.metadata.get('source', 'unknown')}, "
        f"Page: {d.metadata.get('page', 'N/A')}]\n{d.page_content}"
        for d in docs
    ])

rag_chain = (
    {"context": compression_retriever | format_docs, "question": RunnablePassthrough()}
    | prompt
    | ChatOpenAI(model="gpt-4o", temperature=0)
    | StrOutputParser()
)

# Usage
response = rag_chain.invoke("What is the return policy?")
```

---

## 6. Agentic RAG with Tool Calling

```python
from langchain.agents import create_tool_calling_agent, AgentExecutor
from langchain.tools.retriever import create_retriever_tool

retriever_tool = create_retriever_tool(
    retriever=compression_retriever,
    name="search_knowledge_base",
    description="Search the internal knowledge base for information. Input should be a search query."
)

tools = [retriever_tool]

agent = create_tool_calling_agent(
    llm=ChatOpenAI(model="gpt-4o", temperature=0),
    tools=tools,
    prompt=ChatPromptTemplate.from_messages([
        ("system", "You are a helpful assistant with access to a knowledge base."),
        ("human", "{input}"),
        ("placeholder", "{agent_scratchpad}"),
    ])
)

agent_executor = AgentExecutor(agent=agent, tools=tools, verbose=True)
result = agent_executor.invoke({"input": "What are the main themes in Q3 report?"})
```

---

## 7. Incremental Ingestion (Upsert Without Duplicates)

```python
def upsert_documents(new_docs, vectorstore):
    """Only embed and add truly new documents."""
    existing_ids = set(vectorstore.get()["ids"])
    new_chunks = chunk_documents(new_docs)
    truly_new = [c for c in new_chunks if c.metadata["chunk_id"] not in existing_ids]
    if truly_new:
        vectorstore.add_documents(truly_new)
    return len(truly_new)
```

---

## 8. Streaming Responses

```python
async def stream_rag_response(query: str):
    async for chunk in rag_chain.astream(query):
        print(chunk, end="", flush=True)
        yield chunk
```

---

## 9. Evaluation with RAGAS

```python
from ragas import evaluate
from ragas.metrics import faithfulness, answer_relevancy, context_recall, context_precision
from datasets import Dataset

# Build eval dataset
eval_data = {
    "question": ["What is the refund policy?"],
    "answer": [rag_chain.invoke("What is the refund policy?")],
    "contexts": [[d.page_content for d in compression_retriever.invoke("What is the refund policy?")]],
    "ground_truth": ["Customers can return items within 30 days for a full refund."]
}

dataset = Dataset.from_dict(eval_data)
results = evaluate(dataset, metrics=[faithfulness, answer_relevancy, context_recall, context_precision])
print(results)
```
