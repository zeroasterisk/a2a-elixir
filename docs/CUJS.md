# Critical User Journeys (CUJs)

This document defines the core Critical User Journeys for AgentMsg implementations using Given/When/Then format scenarios with exact curl commands and references to backing E2E tests.

## CUJ-01: Basic Agent Registration & Discovery

### Scenario 1.1: Agent starts and serves its agent card

**Intent:** An agent starts up and makes its capabilities discoverable via the standard `.well-known/agent-card.json` endpoint.

**Given:**
- An AgentMsg-compliant agent is running on `http://localhost:4001`
- The agent implements the EchoAgent pattern (echoes input messages)

**When:**
- A client requests the agent's discovery endpoint

**Then:**
- The agent returns its agent card in JSON format with 200 status
- The card includes name, description, skills, and supported interfaces

**Exact curl command:**
```bash
curl -H "Accept: application/json" \
     http://localhost:4001/.well-known/agent-card.json
```

**Expected response structure:**
```json
{
  "name": "echo",
  "description": "Echoes messages back",
  "version": "0.1.0",
  "skills": [
    {
      "id": "echo",
      "name": "Echo", 
      "description": "Repeats your input",
      "tags": ["demo"]
    }
  ],
  "supportedInterfaces": [
    {
      "url": "http://localhost:4001",
      "protocol": "jsonrpc",
      "version": "2.0"
    }
  ],
  "capabilities": {},
  "defaultInputModes": ["text/plain"],
  "defaultOutputModes": ["text/plain"]
}
```

**Backing test:** [test/a2a/plug_test.exs#L50-L67](test/a2a/plug_test.exs)

### Scenario 1.2: Client discovers and validates agent capabilities

**Intent:** A client programmatically discovers an agent's capabilities and validates it supports required operations.

**Given:**
- An agent is serving on `http://localhost:4001` 
- The client needs to validate the agent supports message sending

**When:**
- The client fetches the agent card
- The client examines the `supportedInterfaces` array

**Then:**
- The card contains at least one interface with `protocol: "jsonrpc"`
- The interface URL matches the agent's base URL
- The client can proceed with message operations

**Exact curl command:**
```bash
curl -v -H "Accept: application/json" \
     http://localhost:4001/.well-known/agent-card.json \
     | jq '.supportedInterfaces[] | select(.protocol == "jsonrpc")'
```

**Expected filtered output:**
```json
{
  "url": "http://localhost:4001",
  "protocol": "jsonrpc", 
  "version": "2.0"
}
```

**Backing test:** [test/a2a/client_test.exs#L68-L95](test/a2a/client_test.exs)

### Scenario 1.3: Basic message send via JSON-RPC

**Intent:** A client sends a simple text message to a discovered agent and receives a response.

**Given:**
- An EchoAgent is running and discoverable on `http://localhost:4001`
- The client has validated the agent supports JSON-RPC 2.0

**When:**
- The client sends a `message/send` JSON-RPC request with a text message

**Then:**
- The agent returns a completed task with the echoed response
- The task includes history showing user input and agent reply
- The response follows JSON-RPC 2.0 format

**Exact curl command:**
```bash
curl -X POST http://localhost:4001/ \
     -H "Content-Type: application/json" \
     -d '{
       "jsonrpc": "2.0",
       "id": 1,
       "method": "message/send",
       "params": {
         "message": {
           "messageId": "msg-001",
           "role": "user", 
           "parts": [
             {
               "kind": "text",
               "text": "Hello AgentMsg!"
             }
           ]
         }
       }
     }'
```

**Expected response structure:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "task": {
      "id": "tsk-...",
      "kind": "task",
      "status": {
        "state": "TASK_STATE_COMPLETED"
      },
      "history": [
        {
          "messageId": "msg-001", 
          "role": "user",
          "parts": [{"kind": "text", "text": "Hello AgentMsg!"}]
        },
        {
          "messageId": "msg-...",
          "role": "agent", 
          "parts": [{"kind": "text", "text": "Hello AgentMsg!"}]
        }
      ],
      "artifacts": [
        {
          "parts": [{"kind": "text", "text": "Hello AgentMsg!"}]
        }
      ]
    }
  }
}
```

**Backing test:** [test/a2a/plug_test.exs#L124-L137](test/a2a/plug_test.exs)

### Scenario 1.4: Task retrieval by ID

**Intent:** A client retrieves a previously created task using its task ID.

**Given:**
- An agent has completed a task with ID `tsk-123`
- The client has the task ID from a previous interaction

**When:**
- The client sends a `tasks/get` JSON-RPC request with the task ID

**Then:**
- The agent returns the complete task record including history and artifacts

**Exact curl command:**
```bash
curl -X POST http://localhost:4001/ \
     -H "Content-Type: application/json" \
     -d '{
       "jsonrpc": "2.0", 
       "id": 2,
       "method": "tasks/get",
       "params": {
         "id": "tsk-123"
       }
     }'
```

**Expected response structure:**
```json
{
  "jsonrpc": "2.0",
  "id": 2, 
  "result": {
    "id": "tsk-123",
    "kind": "task",
    "status": {
      "state": "TASK_STATE_COMPLETED"
    },
    "history": [...],
    "artifacts": [...]
  }
}
```

**Backing test:** [test/a2a/plug_test.exs#L180-L194](test/a2a/plug_test.exs)

## Implementation Notes

- All scenarios use the EchoAgent pattern which is the simplest conformant agent
- HTTP status codes should be 200 for successful JSON-RPC responses (errors are in the JSON-RPC error field)
- Agent card endpoint MUST use HTTP GET method - other methods return 405
- JSON-RPC endpoint MUST use HTTP POST method
- Task IDs are generated server-side and are opaque strings
- Message IDs are client-generated and should be unique per conversation

## Test Coverage

This CUJ section is backed by the following test files:

- **test/a2a/plug_test.exs** - HTTP/JSON-RPC integration tests
- **test/a2a/client_test.exs** - Client discovery and communication tests  
- **examples/client_server.exs** - Full end-to-end workflow demonstration

All scenarios have been validated against the reference Elixir implementation in this repository.