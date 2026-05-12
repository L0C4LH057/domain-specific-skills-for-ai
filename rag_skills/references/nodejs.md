# RAG with Node.js / TypeScript

Using LangChain.js, Vercel AI SDK, and common vector stores.

## Installation

```bash
npm install langchain @langchain/openai @langchain/community @langchain/cohere \
            chromadb @pinecone-database/pinecone pdf-parse cheerio \
            ai @ai-sdk/openai zod
```

---

## 1. Document Ingestion

```typescript
import { PDFLoader } from "@langchain/community/document_loaders/fs/pdf";
import { DirectoryLoader } from "langchain/document_loaders/fs/directory";
import { RecursiveCharacterTextSplitter } from "langchain/text_splitter";
import { OpenAIEmbeddings } from "@langchain/openai";
import { Chroma } from "@langchain/community/vectorstores/chroma";
import crypto from "crypto";

const loader = new DirectoryLoader("./data", {
  ".pdf": (path) => new PDFLoader(path),
});

const docs = await loader.load();

const splitter = new RecursiveCharacterTextSplitter({
  chunkSize: 512,
  chunkOverlap: 64,
  separators: ["\n\n", "\n", ". ", " ", ""],
});

const chunks = await splitter.splitDocuments(docs);

// Add stable chunk IDs
chunks.forEach((chunk) => {
  const hash = crypto
    .createHash("md5")
    .update(chunk.pageContent)
    .digest("hex")
    .slice(0, 8);
  chunk.metadata.chunkId = `${chunk.metadata.source}-${hash}`;
});

const embeddings = new OpenAIEmbeddings({ model: "text-embedding-3-small" });
const vectorStore = await Chroma.fromDocuments(chunks, embeddings, {
  collectionName: "my-docs",
  url: "http://localhost:8000",
});
```

---

## 2. Hybrid Retriever

```typescript
import { EnsembleRetriever } from "langchain/retrievers/ensemble";
import { BM25Retriever } from "@langchain/community/retrievers/bm25";

const denseRetriever = vectorStore.asRetriever({ k: 10 });
const sparseRetriever = BM25Retriever.fromDocuments(chunks, { k: 10 });

const hybridRetriever = new EnsembleRetriever({
  retrievers: [sparseRetriever, denseRetriever],
  weights: [0.4, 0.6],
});
```

---

## 3. RAG Chain

```typescript
import { ChatOpenAI } from "@langchain/openai";
import { ChatPromptTemplate } from "@langchain/core/prompts";
import { StringOutputParser } from "@langchain/core/output_parsers";
import { RunnablePassthrough, RunnableSequence } from "@langchain/core/runnables";
import { Document } from "@langchain/core/documents";

const model = new ChatOpenAI({ model: "gpt-4o", temperature: 0 });

const prompt = ChatPromptTemplate.fromMessages([
  [
    "system",
    `You are a helpful assistant. Answer using ONLY the context below.
If the answer is not in the context, say so clearly.
Always cite your sources.

Context:
{context}`,
  ],
  ["human", "{question}"],
]);

function formatDocs(docs: Document[]): string {
  return docs
    .map(
      (d) =>
        `[Source: ${d.metadata.source ?? "unknown"}, Page: ${d.metadata.loc?.pageNumber ?? "N/A"}]\n${d.pageContent}`
    )
    .join("\n\n---\n\n");
}

const ragChain = RunnableSequence.from([
  {
    context: hybridRetriever.pipe(formatDocs),
    question: new RunnablePassthrough(),
  },
  prompt,
  model,
  new StringOutputParser(),
]);

const answer = await ragChain.invoke("What is the leave policy?");
```

---

## 4. Streaming with Vercel AI SDK

```typescript
import { streamText } from "ai";
import { openai } from "@ai-sdk/openai";

export async function POST(req: Request) {
  const { query } = await req.json();
  const docs = await hybridRetriever.invoke(query);
  const context = formatDocs(docs);

  const result = streamText({
    model: openai("gpt-4o"),
    system: `Answer using ONLY the context below.\n\n${context}`,
    prompt: query,
  });

  return result.toDataStreamResponse();
}
```

---

## 5. Pinecone in Production

```typescript
import { Pinecone } from "@pinecone-database/pinecone";
import { PineconeStore } from "@langchain/pinecone";

const pinecone = new Pinecone({ apiKey: process.env.PINECONE_API_KEY! });
const index = pinecone.index("my-rag-index");

// Ingest
const vectorStore = await PineconeStore.fromDocuments(chunks, embeddings, {
  pineconeIndex: index,
  namespace: "v1",
});

// Query with metadata filter
const retriever = vectorStore.asRetriever({
  k: 10,
  filter: { docType: "policy", year: { $gte: 2024 } },
});
```

---

## 6. Next.js App Router Integration

```typescript
// app/api/chat/route.ts
import { NextRequest } from "next/server";
import { streamText } from "ai";
import { openai } from "@ai-sdk/openai";

export async function POST(req: NextRequest) {
  const { messages } = await req.json();
  const lastMessage = messages[messages.length - 1].content;

  // Retrieve context
  const docs = await retriever.invoke(lastMessage);
  const context = formatDocs(docs);

  const result = streamText({
    model: openai("gpt-4o"),
    system: `You are a helpful assistant. Answer using ONLY this context:\n\n${context}`,
    messages,
  });

  return result.toDataStreamResponse();
}
```

---

## 7. Cohere Reranking

```typescript
import { CohereRerank } from "@langchain/cohere";
import { ContextualCompressionRetriever } from "langchain/retrievers/contextual_compression";

const reranker = new CohereRerank({
  apiKey: process.env.COHERE_API_KEY,
  model: "rerank-english-v3.0",
  topN: 5,
});

const compressionRetriever = new ContextualCompressionRetriever({
  baseCompressor: reranker,
  baseRetriever: hybridRetriever,
});
```
