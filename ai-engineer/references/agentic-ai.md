# Agentic AI Reference

## What Makes a System Agentic?

An AI system is agentic when it can:
1. **Plan** — decompose a goal into steps
2. **Act** — take actions (call tools, write files, query APIs)
3. **Observe** — receive feedback from its actions
4. **Iterate** — adjust behavior based on observations

The fundamental loop:
```
Perceive → Think → Act → Observe → [repeat until done]
```

**Agents are not chatbots with tools.** A true agent operates autonomously over multiple steps, with its behavior shaped by intermediate results, not just the initial user request.

---

## Agent Architecture Patterns

### 1. ReAct Agent (Reasoning + Acting)
The foundational agentic pattern. Model interleaves thoughts and tool calls.
```
User: Find the top 3 competitors of Paystack in Nigeria and summarize their pricing.

Thought: I need to search for fintech payment companies operating in Nigeria.
Action: web_search("Paystack competitors Nigeria payment gateway 2024")
Observation: [Results: Flutterwave, Interswitch, Moniepoint, Squad...]

Thought: I found several competitors. Let me get pricing details for each.
Action: web_fetch("https://flutterwave.com/pricing")
Observation: [Pricing page content...]

... (continue until complete)

Final Answer: The top 3 competitors are...
```

**Implementation**: LangChain `create_react_agent`, LangGraph `ReAct` node, or raw prompting.

### 2. Plan-and-Execute
Separate planning from execution. More reliable for long-horizon tasks.
```
Step 1 (Planner LLM): 
  Input: User goal
  Output: Ordered list of steps

Step 2 (Executor LLM/agent):
  For each step: execute → observe → update plan if needed

Step 3 (Verifier):
  Confirm all steps completed successfully
```

**When to use**: Tasks with 5+ steps, tasks where early steps inform later ones.

### 3. Multi-Agent Systems
Multiple specialized agents collaborating. Each agent is an expert in a narrow domain.

```
                    ┌─────────────────────┐
                    │   ORCHESTRATOR      │
                    │   (Router Agent)    │
                    └──────────┬──────────┘
               ┌───────────────┼───────────────┐
               ▼               ▼               ▼
      ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
      │  Researcher  │ │   Analyst    │ │    Writer    │
      │   Agent      │ │   Agent      │ │   Agent      │
      └──────────────┘ └──────────────┘ └──────────────┘
```

**Patterns**:
- **Supervisor**: Orchestrator delegates to sub-agents, reviews their work
- **Swarm**: Agents pass tasks peer-to-peer based on expertise
- **Pipeline**: Sequential handoff (Agent A output → Agent B input)
- **Debate**: Multiple agents argue positions; arbiter synthesizes

### 4. Reflection Agent
Agent reviews and critiques its own output before returning it.
```
Generate → Critique → Revise → [Repeat until quality threshold met]
```

```python
def reflection_loop(task, max_iterations=3):
    draft = generator_agent.run(task)
    for i in range(max_iterations):
        critique = critic_agent.run(f"Critique this output:\n{draft}")
        if critique["score"] >= 0.9:
            break
        draft = generator_agent.run(f"Revise based on critique:\n{critique['feedback']}\n\nDraft:\n{draft}")
    return draft
```

### 5. HITL (Human-in-the-Loop) Agent
Agent pauses at defined checkpoints for human approval before proceeding.
```python
# LangGraph human-in-the-loop pattern
from langgraph.checkpoint.memory import MemorySaver

graph = build_graph()
graph.add_interrupt_before("execute_payment")  # Pause here for human review

# Human reviews the planned action, then resumes
result = graph.invoke(input, config={"thread_id": "abc"})
# ... human reviews ...
graph.invoke(None, config={"thread_id": "abc"})  # Resume
```

---

## LangGraph Deep Dive

LangGraph is the production standard for stateful, multi-step agent orchestration. It models agent workflows as directed graphs (nodes = actions, edges = transitions).

### Core Concepts
```python
from langgraph.graph import StateGraph, END
from typing import TypedDict, Annotated
import operator

# 1. Define State
class AgentState(TypedDict):
    messages: Annotated[list, operator.add]
    current_step: str
    results: dict
    error_count: int

# 2. Define Nodes (functions that transform state)
def research_node(state: AgentState) -> AgentState:
    # Do research, update state
    return {"messages": [research_result], "current_step": "analyze"}

def analyze_node(state: AgentState) -> AgentState:
    return {"messages": [analysis], "current_step": "write"}

def write_node(state: AgentState) -> AgentState:
    return {"messages": [final_output], "current_step": "done"}

# 3. Build Graph
workflow = StateGraph(AgentState)
workflow.add_node("research", research_node)
workflow.add_node("analyze", analyze_node)
workflow.add_node("write", write_node)

# 4. Define Edges (transitions)
workflow.set_entry_point("research")
workflow.add_edge("research", "analyze")
workflow.add_edge("analyze", "write")
workflow.add_edge("write", END)

# 5. Conditional Edges (branching logic)
def router(state: AgentState) -> str:
    if state["error_count"] > 2:
        return "error_handler"
    return "continue"

workflow.add_conditional_edges("research", router, {
    "continue": "analyze",
    "error_handler": "error_node"
})

# 6. Compile and Run
app = workflow.compile(checkpointer=MemorySaver())
result = app.invoke({"messages": [user_input], "current_step": "start", "results": {}, "error_count": 0})
```

### LangGraph Persistence & Resumption
```python
from langgraph.checkpoint.postgres import PostgresSaver

# Persist state to Postgres for long-running workflows
checkpointer = PostgresSaver.from_conn_string(os.getenv("DATABASE_URL"))
app = workflow.compile(checkpointer=checkpointer)

# Start a workflow
config = {"configurable": {"thread_id": "workflow-123"}}
result = app.invoke(task, config=config)

# Resume from any checkpoint
app.invoke(None, config=config)  # Resume from last checkpoint
```

---

## CrewAI Deep Dive

CrewAI provides a high-level abstraction for multi-agent systems with roles, goals, and backstories.

```python
from crewai import Agent, Task, Crew, Process
from crewai_tools import SerperDevTool, WebsiteSearchTool

# Define Agents
researcher = Agent(
    role="Senior Research Analyst",
    goal="Uncover cutting-edge developments in AI engineering",
    backstory="You're a seasoned researcher with 10 years in tech industry analysis.",
    tools=[SerperDevTool(), WebsiteSearchTool()],
    verbose=True,
    llm="claude-opus-4-5"
)

writer = Agent(
    role="Technical Content Writer",
    goal="Craft compelling technical content from research findings",
    backstory="Expert at translating complex AI concepts into clear documentation.",
    verbose=True,
    llm="claude-sonnet-4-5"
)

# Define Tasks
research_task = Task(
    description="Research the latest developments in agentic AI frameworks in 2024–2025",
    expected_output="A structured report with key findings, trends, and framework comparisons",
    agent=researcher
)

writing_task = Task(
    description="Write a technical guide based on the research findings",
    expected_output="A 1500-word technical article with code examples",
    agent=writer,
    context=[research_task]  # Writer receives researcher's output
)

# Assemble Crew
crew = Crew(
    agents=[researcher, writer],
    tasks=[research_task, writing_task],
    process=Process.sequential,  # or Process.hierarchical
    verbose=True
)

result = crew.kickoff()
```

---

## Tool Design Principles

Tools are what separate agents from chatbots. Well-designed tools are critical.

### The SPEAR Framework for Tools
- **S**ingle responsibility: Each tool does one thing
- **P**redictable: Same input always produces same type of output
- **E**rror-informative: Failures return structured, actionable error messages
- **A**tomic: Can't be partially executed; either succeeds or fails cleanly
- **R**eversible where possible: Prefer tools that can be undone

### Tool Schema Design
```python
from langchain.tools import tool
from pydantic import BaseModel, Field

class SearchInput(BaseModel):
    query: str = Field(description="The search query to look up")
    max_results: int = Field(default=5, description="Maximum number of results to return (1-20)")

@tool(args_schema=SearchInput)
def web_search(query: str, max_results: int = 5) -> str:
    """
    Search the web for current information.
    Use this tool when you need recent information not in your training data.
    Returns a list of search results with titles, URLs, and snippets.
    """
    results = search_api.search(query, num_results=max_results)
    return format_results(results)
```

### Tool Error Handling
```python
@tool
def query_database(sql: str) -> str:
    """Query the company database. Use SELECT statements only."""
    try:
        if not sql.strip().upper().startswith("SELECT"):
            return "ERROR: Only SELECT queries are permitted."
        results = db.execute(sql)
        return json.dumps(results, indent=2)
    except Exception as e:
        return f"DATABASE_ERROR: {str(e)}. Please check your SQL syntax and try again."
```

---

## Agent Reliability Patterns

### Retry with Exponential Backoff
```python
import tenacity

@tenacity.retry(
    wait=tenacity.wait_exponential(multiplier=1, min=4, max=60),
    stop=tenacity.stop_after_attempt(3),
    retry=tenacity.retry_if_exception_type(RateLimitError)
)
def call_llm(prompt):
    return llm.invoke(prompt)
```

### Output Validation
```python
from pydantic import BaseModel, validator

class AgentOutput(BaseModel):
    action: str
    parameters: dict
    confidence: float
    
    @validator('confidence')
    def confidence_range(cls, v):
        assert 0 <= v <= 1, "Confidence must be between 0 and 1"
        return v

# Validate before acting
try:
    output = AgentOutput.parse_raw(llm_response)
    execute_action(output)
except ValidationError as e:
    # Ask model to regenerate with correct format
    retry_with_format_correction(llm_response, e)
```

### Agent Memory Types
```
1. In-context memory:    Conversation history in the current context window
2. External memory:      Vector DB of past interactions (episodic memory)
3. Entity memory:        Structured store of key facts (user prefs, past decisions)
4. Procedural memory:    Stored tool use patterns and successful strategies
5. Semantic memory:      Domain knowledge in RAG index
```

---

## References & Papers

- **"ReAct: Synergizing Reasoning and Acting in Language Models"** — Yao et al., Princeton/Google, 2022
- **"Toolformer: Language Models Can Teach Themselves to Use Tools"** — Schick et al., Meta AI, 2023
- **"AutoGPT: An Autonomous GPT-4 Experiment"** — Toran Bruce Richards, 2023
- **"Agents"** — Lilian Weng, OpenAI, 2023 — https://lilianweng.github.io/posts/2023-06-23-agent/
- **"CrewAI: Framework for Orchestrating Role-Playing AI Agents"** — João Moura, 2024
- **"LangGraph"** — Harrison Chase et al., LangChain, 2024 — https://langchain-ai.github.io/langgraph/
- **"Generative Agents: Interactive Simulacra of Human Behavior"** — Park et al., Stanford, 2023
- **"HumanEval: Evaluating Large Language Models Trained on Code"** — Chen et al., OpenAI, 2021
- **Anthropic Claude Tool Use Guide** — https://docs.anthropic.com/en/docs/build-with-claude/tool-use
- **"Chain of Hindsight Aligns Language Models with Feedback"** — Liu et al., 2023
