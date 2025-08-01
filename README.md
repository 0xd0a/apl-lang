# Agent Prompting Language (APL)

**A declarative domain-specific language for building production AI agents**

## Overview

APL (Agent Prompting Language) is a language proposal for creating sophisticated AI agents with clear separation between LLM reasoning and deterministic system operations. It emphasizes ultra-compact expressiveness, state-aware processing, and dynamic module composition.

## Language Features

- **Decision-Execute Separation**: Clear distinction between `@decide` (LLM reasoning) and `!execute` (system operations)
- **State Machine Support**: Native support for complex multi-step workflows
- **Dynamic Module Loading**: Runtime composition of agent behaviors
- **Template System**: Structured response formats and type definitions
- **Built-in Testing**: Examples serve as both documentation and validation

## Language Status

🚧 **This is a language proposal and specification.** 

APL is currently in the design and specification phase. The language syntax, semantics, and features described in this repository represent a proposed approach to AI agent development. Implementation of interpreters, compilers, or runtime environments is ongoing.

## Repository Structure

- [`specification.md`](specification.md) - Complete language specification
- [`examples/`](examples/) - Example APL programs demonstrating language features
- [`LICENSE`](LICENSE) - License terms for using and modifying this specification

## Quick Example

```apl
// aplv2.0
agent CustomerSupportAgent {
  role: "helpful customer support representative"
  
  states {
    initial: "greeting"
    greeting { allowed_transitions: ["issue_identification"] }
    issue_identification { allowed_transitions: ["resolution", "escalation"] }
    resolution { final_state: true }
  }
  
  behavior {
    on_event {
      event(user_input) -> {
        @decide {
          user_intent -> ["question", "complaint", "request"] [input.text]
          urgency -> 1..10 [content + customer_history]
        }
        
        if urgency > 7 {
          !execute transition_to("escalation")
        } else {
          !execute provide_standard_response(user_intent)
        }
      }
    }
  }
}
```

## Generate APL Code with LLMs

**Don't want to write code manually?** APL might seem technical, but you can leverage the power of LLMs to generate APL code without writing a single line!

### How to Generate APL Code:

1. **Upload or reference** the [specification.md](specification.md) file to your preferred LLM (ChatGPT, Claude, Gemini, Cursor, etc.)

2. **Ask in natural language** what you want your agent to do:

```
"Create an APL agent that handles customer support tickets, 
extracts customer information, routes to appropriate departments, 
and sends email notifications when issues are resolved."
```

3. **The LLM will generate** complete APL code based on the specification and your requirements.

### Example Prompt:
```
I need an APL agent for a restaurant reservation system that:
- Takes reservation requests via chat
- Checks table availability 
- Confirms bookings via SMS
- Handles cancellations and modifications
- Integrates with our booking database

Please write the complete APL code following the specification.
```

The LLM will generate a fully functional APL agent with proper state machines, decision logic, and system integrations!

## Examples

See the [`examples/`](examples/) directory for complete APL programs including:

- Customer support agents with state management
- Form handling and data collection workflows  
- Multi-module agent compositions
- Error handling and recovery patterns

## Do LLMs/Agents Understand This Language?

**Yes!** While support is not "native," LLMs have a great degree of understanding of APL since it is built with structure and LLM capabilities in mind.

### LLM Compatibility

LLMs can effectively:
- **Parse APL syntax** and understand agent structure
- **Execute decision logic** using `@decide` blocks  
- **Interpret state machines** and behavior flows
- **Generate APL code** when given specifications

### How to Use APL with LLMs

To have an LLM interpret and execute APL code, prepend your prompt with:

```
"Here's code written in Agent Prompting Language (APL). 
You need to execute this code using the user's text as input:"

[Your APL code here]

User input: "I have a billing question"
```

### Future Development

We plan to fine-tune specialized LLMs on APL code corpus, but current general-purpose LLMs already demonstrate excellent APL comprehension with proper instruction.

## Contributing

This is an open language proposal. Contributions, suggestions, and discussions about the language design are welcome through issues and pull requests.

## Use Cases

APL is designed for:
- Customer service automation
- Form processing and data collection
- Multi-step business workflows
- Interactive troubleshooting systems
- Dynamic agent behavior composition

## License

This specification is available under the [MIT License with Attribution](LICENSE). You are free to use, modify, and distribute this specification with proper citation.

---

*APL v2.0 Language Specification*
