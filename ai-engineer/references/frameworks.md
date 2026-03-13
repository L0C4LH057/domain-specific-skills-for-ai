# AI Frameworks Reference

## Framework Selection Matrix

| Framework | Best For | Complexity | Production Ready | Key Strength |
|-----------|----------|-----------|-----------------|--------------|
| **LangChain** | Chains, RAG, tool use | Medium | Yes | Ecosystem, integrations |
| **LangGraph** | Stateful agents, workflows | Medium-High | Yes | State management, reliability |
| **LlamaIndex** | Data ingestion, RAG | Medium | Yes | Document handling, indexing |
| **CrewAI** | Multi-agent teams | Low-Medium | Yes | Role-based agents, simplicity |
| **AutoGen** | Conversational agents | Medium | Yes | Multi-agent conversation |
| **DSPy** | Prompt optimization | High | Emerging | Automated prompt tuning |
| **Haystack** | NLP pipelines, search | Medium | Yes | Document AI, search |
| **Semantic Kernel** | Enterprise .NET/Python | Medium | Yes | Microsoft ecosystem |
| **Unsloth** | Fine-tuning, training | High | Yes | 2x faster training, memory efficient |
| **Axolotl** | Fine-tuning (YAML config) | Medium | Yes | Config-driven fine-tuning |
| **PEFT/LoRA** | Fine-tuning (HuggingFace) | High | Yes | Parameter-efficient fine-tuning |
| **vLLM** | LLM serving/inference | High | Yes | High-throughput serving |
| **Ollama** | Local LLM serving | Low | Dev/SME | Local development simplicity |

---

## LangChain Deep Dive

LangChain is the broadest ecosystem for LLM application development. Think of it as the "toolkit" layer.

### Core Primitives
```python
from langchain_anthropic import ChatAnthropic
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser, JsonOutputParser
from langchain_core.runnables import RunnablePassthrough

# LLM
llm = ChatAnthropic(model="claude-sonnet-4-5")

# Prompt Template
prompt = ChatPromptTemplate.from_messages([
    ("system", "You are a helpful assistant specializing in {domain}."),
    ("human", "{question}")
])

# Chain (LCEL — LangChain Expression Language)
chain = prompt | llm | StrOutputParser()

# Invoke
result = chain.invoke({"domain": "finance", "question": "What is DCF analysis?"})

# Stream
for chunk in chain.stream({"domain": "finance", "question": "Explain options pricing"}):
    print(chunk, end="", flush=True)

# Batch (parallel)
results = chain.batch([
    {"domain": "finance", "question": q} for q in questions
])
```

### LCEL Composition Patterns
```python
from langchain_core.runnables import RunnableParallel, RunnableLambda

# Parallel execution
parallel_chain = RunnableParallel({
    "summary": summarize_chain,
    "keywords": keywords_chain,
    "sentiment": sentiment_chain
})

# Branching
def route(input):
    if input["type"] == "technical":
        return technical_chain
    return general_chain

branching_chain = RunnableLambda(route)

# With fallback
safe_chain = risky_chain.with_fallbacks([fallback_chain])

# With retry
reliable_chain = chain.with_retry(stop_after_attempt=3, wait_exponential_jitter=True)
```

### LangChain RAG Pattern
```python
from langchain_community.vectorstores import Chroma
from langchain_openai import OpenAIEmbeddings
from langchain_core.runnables import RunnablePassthrough

vectorstore = Chroma(embedding_function=OpenAIEmbeddings())
retriever = vectorstore.as_retriever(search_kwargs={"k": 5})

rag_chain = (
    {"context": retriever | format_docs, "question": RunnablePassthrough()}
    | prompt
    | llm
    | StrOutputParser()
)
```

---

## LangGraph Deep Dive

LangGraph is built on LangChain's LCEL but adds graph-based state management for complex agents.

### When LangGraph over LangChain
- Need persistent state across multiple steps
- Need cycles / loops in your workflow
- Need human-in-the-loop interrupts
- Building multi-agent systems
- Need reliable error recovery and retry within a workflow

### Complete Agent Example
```python
from langgraph.graph import StateGraph, END
from langgraph.prebuilt import ToolNode
from langchain_anthropic import ChatAnthropic
from langchain_core.tools import tool
from typing import TypedDict, Annotated
import operator

# Tools
@tool
def search_web(query: str) -> str:
    """Search the web for information."""
    return web_search_api(query)

@tool  
def calculate(expression: str) -> str:
    """Evaluate a mathematical expression."""
    return str(eval(expression))  # Use safe_eval in production!

tools = [search_web, calculate]
tool_node = ToolNode(tools)

# Model with tools bound
model = ChatAnthropic(model="claude-sonnet-4-5").bind_tools(tools)

# State
class State(TypedDict):
    messages: Annotated[list, operator.add]

# Agent node
def agent(state: State) -> State:
    response = model.invoke(state["messages"])
    return {"messages": [response]}

# Routing logic
def should_continue(state: State) -> str:
    last_message = state["messages"][-1]
    if last_message.tool_calls:
        return "tools"
    return END

# Build graph
workflow = StateGraph(State)
workflow.add_node("agent", agent)
workflow.add_node("tools", tool_node)
workflow.set_entry_point("agent")
workflow.add_conditional_edges("agent", should_continue, {"tools": "tools", END: END})
workflow.add_edge("tools", "agent")  # After tools, back to agent

app = workflow.compile()
```

---

## LlamaIndex Deep Dive

LlamaIndex excels at data ingestion and complex retrieval over diverse document types.

```python
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader, Settings
from llama_index.llms.anthropic import Anthropic
from llama_index.embeddings.openai import OpenAIEmbedding

# Configure models
Settings.llm = Anthropic(model="claude-sonnet-4-5")
Settings.embed_model = OpenAIEmbedding(model="text-embedding-3-small")

# Load documents
documents = SimpleDirectoryReader("./data/").load_data()

# Build index
index = VectorStoreIndex.from_documents(documents)

# Query
query_engine = index.as_query_engine(
    similarity_top_k=5,
    response_mode="compact"  # compact, refine, tree_summarize
)
response = query_engine.query("What are the key financial risks mentioned?")

# Advanced: Sub-question decomposition
from llama_index.core.query_engine import SubQuestionQueryEngine
sub_query_engine = SubQuestionQueryEngine.from_defaults(
    query_engine_tools=[financial_tool, legal_tool],
    use_async=True
)
```

---

## Unsloth — Fine-tuning Reference

Unsloth makes fine-tuning 2x faster with 60% less memory. Critical for African/resource-constrained environments.

### QLoRA Fine-tuning Setup
```python
from unsloth import FastLanguageModel
from trl import SFTTrainer
from transformers import TrainingArguments
from datasets import Dataset

# Load model with 4-bit quantization
model, tokenizer = FastLanguageModel.from_pretrained(
    model_name="unsloth/llama-3-8b-Instruct-bnb-4bit",
    max_seq_length=2048,
    dtype=None,  # Auto-detect
    load_in_4bit=True,
)

# Add LoRA adapters
model = FastLanguageModel.get_peft_model(
    model,
    r=16,                     # LoRA rank (8–64; higher = more parameters)
    target_modules=["q_proj", "k_proj", "v_proj", "o_proj",
                    "gate_proj", "up_proj", "down_proj"],
    lora_alpha=16,
    lora_dropout=0,
    bias="none",
    use_gradient_checkpointing="unsloth",
    random_state=42,
)

# Prepare data
dataset = Dataset.from_dict({
    "text": [
        tokenizer.apply_chat_template(example["messages"], tokenize=False)
        for example in training_data
    ]
})

# Train
trainer = SFTTrainer(
    model=model,
    tokenizer=tokenizer,
    train_dataset=dataset,
    dataset_text_field="text",
    max_seq_length=2048,
    args=TrainingArguments(
        per_device_train_batch_size=2,
        gradient_accumulation_steps=4,
        warmup_steps=5,
        max_steps=100,
        learning_rate=2e-4,
        fp16=not torch.cuda.is_bf16_supported(),
        bf16=torch.cuda.is_bf16_supported(),
        output_dir="./outputs",
    ),
)
trainer.train()

# Save
model.save_pretrained("./fine-tuned-model")
tokenizer.save_pretrained("./fine-tuned-model")
```

---

## DSPy — Programmatic Prompt Optimization

DSPy replaces hand-written prompts with learnable modules that optimize themselves.

```python
import dspy

# Configure LLM
lm = dspy.LM("anthropic/claude-sonnet-4-5")
dspy.configure(lm=lm)

# Define Signature (input/output spec)
class ClassifyReview(dspy.Signature):
    """Classify a product review as positive, negative, or neutral."""
    review: str = dspy.InputField()
    sentiment: str = dspy.OutputField(desc="POSITIVE, NEGATIVE, or NEUTRAL")
    confidence: float = dspy.OutputField(desc="Confidence score 0-1")

# Define Module
class ReviewClassifier(dspy.Module):
    def __init__(self):
        self.classify = dspy.Predict(ClassifyReview)
    
    def forward(self, review: str):
        return self.classify(review=review)

# Optimize (DSPy auto-generates best prompts from examples)
from dspy.teleprompt import BootstrapFewShot

optimizer = BootstrapFewShot(metric=accuracy_metric)
optimized_classifier = optimizer.compile(
    ReviewClassifier(),
    trainset=training_examples
)
```

---

## vLLM — Production LLM Serving

For self-hosted open-source models at scale:

```python
from vllm import LLM, SamplingParams

# Initialize (loads model to GPU)
llm = LLM(
    model="meta-llama/Meta-Llama-3-8B-Instruct",
    tensor_parallel_size=2,   # Number of GPUs
    quantization="awq",       # AWQ/GPTQ quantization for efficiency
    max_model_len=8192,
)

sampling_params = SamplingParams(temperature=0.7, max_tokens=512)

# Batch inference (very efficient)
outputs = llm.generate(prompts, sampling_params)

# OpenAI-compatible server (drop-in replacement)
# vllm serve meta-llama/Meta-Llama-3-8B-Instruct --host 0.0.0.0 --port 8000
```

---

## References

- **LangChain Docs** — https://python.langchain.com/docs/
- **LangGraph Docs** — https://langchain-ai.github.io/langgraph/
- **LlamaIndex Docs** — https://docs.llamaindex.ai/
- **CrewAI Docs** — https://docs.crewai.com/
- **Unsloth GitHub** — https://github.com/unslothai/unsloth
- **DSPy Paper** — Khattab et al., Stanford, 2023 — https://arxiv.org/abs/2310.03714
- **vLLM Paper** — Kwon et al., UC Berkeley, 2023 — "Efficient Memory Management for LLM Serving with PagedAttention"
- **AutoGen** — Wu et al., Microsoft, 2023 — https://github.com/microsoft/autogen
- **Haystack Docs** — https://docs.haystack.deepset.ai/
