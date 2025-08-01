agent CustomerSupportV1 {
  role: "customer support form collection specialist"
  
  objectives {
    primary: "collect complete, accurate customer request information turn-by-turn"
    secondary: ["minimize customer effort", "ensure data completeness", "maintain conversation flow"]
  }
  
  resources {
    conversation_memory: external("n8n_simple_db")
    validation_rules: external("field_validators")
  }
  
  // HARDCODED FORM DEFINITIONS
  form_definitions {
    "account_issue" {
      name: "Account Issue Resolution"
      description: "Problems with login, access, or account functionality"
      required_fields: ["customer_id", "issue_type", "description", "urgency"]
      optional_fields: ["affected_features", "error_messages", "steps_to_reproduce"]
      
      field_prompts: {
        customer_id: "What's your customer ID? (8-digit number)"
        issue_type: "What type of issue are you experiencing?\n1. Login problem\n2. Billing issue\n3. Feature not working\n4. Data missing"
        description: "Please describe the issue in detail"
        urgency: "How urgent is this? (low/medium/high/critical)"
        affected_features: "Which features are affected? (optional)"
        error_messages: "What error messages do you see? (optional)"
        steps_to_reproduce: "How can we reproduce this issue? (optional)"
      }
      
      validation: {
        customer_id: "format:numeric, length:8"
        issue_type: "options:['login_problem', 'billing_issue', 'feature_not_working', 'data_missing']"
        urgency: "options:['low', 'medium', 'high', 'critical']"
        description: "min_length:10"
      }
    }
    
    "billing_dispute" {
      name: "Billing Dispute"
      description: "Disputes about transactions, charges, or refunds"
      required_fields: ["customer_id", "transaction_id", "dispute_amount", "dispute_reason", "contact_preference"]
      optional_fields: ["transaction_date", "supporting_documents", "preferred_resolution"]
      
      field_prompts: {
        customer_id: "What's your customer ID? (8-digit number)"
        transaction_id: "What's the transaction ID you're disputing? (12 characters)"
        dispute_amount: "What's the amount you're disputing? (e.g., $50.00)"
        dispute_reason: "Why are you disputing this charge?"
        contact_preference: "How should we contact you? (email/phone/chat)"
        transaction_date: "When did the transaction occur? (optional)"
        supporting_documents: "Do you have any supporting documents? (optional)"
        preferred_resolution: "What resolution would you prefer? (optional)"
      }
      
      validation: {
        customer_id: "format:numeric, length:8"
        transaction_id: "format:alphanumeric, length:12"
        dispute_amount: "format:currency, min:0.01"
        contact_preference: "options:['email', 'phone', 'chat']"
        dispute_reason: "min_length:5"
      }
    }
    
    "feature_request" {
      name: "Feature Request"
      description: "Suggestions for new features or improvements"
      required_fields: ["customer_id", "feature_description", "business_impact", "priority"]
      optional_fields: ["use_case_details", "similar_solutions", "timeline_needs"]
      
      field_prompts: {
        customer_id: "What's your customer ID? (8-digit number)"
        feature_description: "Describe the feature you'd like to see"
        business_impact: "How would this feature impact your business?"
        priority: "How important is this feature? (nice_to_have/important/critical_for_business)"
        use_case_details: "Can you provide specific use case examples? (optional)"
        similar_solutions: "Have you seen similar solutions elsewhere? (optional)"
        timeline_needs: "When do you need this feature? (optional)"
      }
      
      validation: {
        customer_id: "format:numeric, length:8"
        priority: "options:['nice_to_have', 'important', 'critical_for_business']"
        feature_description: "min_length:20"
        business_impact: "min_length:15"
      }
    }
    
    "data_request" {
      name: "Data Export Request" 
      description: "Request for personal data export or deletion"
      required_fields: ["customer_id", "data_type", "date_range", "delivery_method", "purpose"]
      optional_fields: ["specific_fields", "format_preference", "encryption_required"]
      
      field_prompts: {
        customer_id: "What's your customer ID? (8-digit number)"
        data_type: "What data do you need?\n1. Transaction history\n2. Account data\n3. Usage analytics\n4. All data"
        date_range: "What date range? (e.g., 2023-01-01 to 2023-12-31)"
        delivery_method: "How should we deliver the data? (email/secure_download/api_access)"
        purpose: "What's the purpose of this data request?"
        specific_fields: "Any specific fields needed? (optional)"
        format_preference: "Preferred format? (CSV/JSON/PDF) (optional)"
        encryption_required: "Do you need encryption? (yes/no) (optional)"
      }
      
      validation: {
        customer_id: "format:numeric, length:8"
        data_type: "options:['transaction_history', 'account_data', 'usage_analytics', 'all_data']"
        delivery_method: "options:['email', 'secure_download', 'api_access']"
        date_range: "format:date_range"
        purpose: "min_length:10"
      }
    }
  }
  
  // STATE MACHINE
  states {
    initial: "greeting"
    
    greeting {
      allowed_transitions: ["form_selection", "restart_confirmed"]
    }
    
    form_selection {
      allowed_transitions: ["collecting_fields", "form_selection"]
      timeout: 5_minutes
    }
    
    collecting_fields {
      allowed_transitions: ["collecting_fields", "validation_failed", "form_complete", "restart_confirmed"]
    }
    
    validation_failed {
      allowed_transitions: ["collecting_fields"]
      max_retries: 3
    }
    
    form_complete {
      allowed_transitions: ["confirmation", "collecting_fields"]
    }
    
    confirmation {
      allowed_transitions: ["json_generated", "collecting_fields", "restart_confirmed"]
    }
    
    json_generated {
      final_state: true
      cleanup_actions: ["save_request", "clear_form_memory"]
    }
    
    restart_confirmed {
      allowed_transitions: ["greeting"]
      cleanup_actions: ["clear_conversation_memory", "reset_form_state"]
    }
  }
  
  // CONVERSATION STATE
  conversation_state {
    current_form_type: string | empty
    selected_form_template: object | empty
    collected_fields: map[string, any]
    missing_required_fields: list[string]
    current_field_name: string | empty
    validation_attempts: map[string, integer]
    conversation_turn: integer
  }
  
  behavior {
    on_enter_state {
      greeting -> {
        @decide {
          is_restart_command -> boolean [input.text]
        }
        
        if is_restart_command {
          !execute transition_to("restart_confirmed")
        } else {
          !execute send_message("👋 Hello! I'm here to help you create a support request. What can I assist you with today?")
          !execute transition_to("form_selection")
        }
      }
      
      form_selection -> {
        !execute send_message("""
Please select the type of request:

1️⃣ **Account Issue** - Login problems, billing issues, features not working
2️⃣ **Billing Dispute** - Transaction disputes, charge issues, refunds  
3️⃣ **Feature Request** - Suggest new features or improvements
4️⃣ **Data Request** - Export your personal data

Just type the number (1-4) or describe what you need help with.
        """)
      }
      
      collecting_fields -> {
        form_template = conversation_state.selected_form_template
        collected = conversation_state.collected_fields
        
        missing_required = []
        for field in form_template.required_fields {
          if field not in collected {
            missing_required.append(field)
          }
        }
        
        if missing_required.empty {
          !execute transition_to("form_complete")
        } else {
          current_field = missing_required[0]
          conversation_state.current_field_name = current_field
          conversation_state.missing_required_fields = missing_required
          
          field_prompt = form_template.field_prompts[current_field]
          progress = f"({len(form_template.required_fields) - len(missing_required) + 1}/{len(form_template.required_fields)})"
          
          !execute send_message(f"📝 **{progress}** {field_prompt}")
        }
      }
      
      form_complete -> {
        !execute send_message("✅ All required information collected! Would you like to add any optional details, or shall we proceed? (proceed/add more)")
      }
      
      confirmation -> {
        all_data = conversation_state.collected_fields
        form_name = conversation_state.selected_form_template.name
        
        summary_lines = []
        for field, value in all_data.items() {
          summary_lines.append(f"• **{field.replace('_', ' ').title()}:** {value}")
        }
        
        summary = "\n".join(summary_lines)
        
        !execute send_message(f"""
📋 **{form_name} Summary:**

{summary}

Is this information correct? 
✅ Type 'yes' to submit
✏️ Type 'edit [field name]' to change something  
🔄 Type 'restart' to start over
        """)
      }
    }
    
    on_event {
      // RESTART COMMAND - works from any state
      event(user_input) + input.text.contains("restart") -> {
        !execute transition_to("restart_confirmed")
      }
      
      // FORM SELECTION
      state(form_selection) + event(user_input) -> {
        user_choice = input.text.trim().lower()
        
        @decide {
          selected_form -> form_type [user_choice]
        }
        
        form_mapping = {
          "1": "account_issue",
          "2": "billing_dispute", 
          "3": "feature_request",
          "4": "data_request",
          "account": "account_issue",
          "billing": "billing_dispute",
          "feature": "feature_request", 
          "data": "data_request"
        }
        
        selected_form_type = form_mapping.get(user_choice)
        
        if selected_form_type {
          conversation_state.selected_form_template = form_definitions[selected_form_type]
          conversation_state.current_form_type = selected_form_type
          
          form_name = conversation_state.selected_form_template.name
          !execute send_message(f"📝 Starting **{form_name}** form...")
          !execute transition_to("collecting_fields")
        } else {
          !execute send_message("❌ I didn't understand that selection. Please choose 1, 2, 3, or 4.")
        }
      }
      
      // FIELD COLLECTION
      state(collecting_fields) + event(user_input) -> {
        current_field = conversation_state.current_field_name
        field_value = input.text.trim()
        validation_rule = conversation_state.selected_form_template.validation.get(current_field)
        
        @decide {
          is_valid -> boolean [field_value, validation_rule]
          validation_error -> error_message [field_value, validation_rule]
        }
        
        if is_valid {
          conversation_state.collected_fields[current_field] = field_value
          
          !execute send_message(f"✅ Got it!")
          !execute transition_to("collecting_fields")  // Continue to next field
        } else {
          conversation_state.validation_attempts[current_field] = 
            conversation_state.validation_attempts.get(current_field, 0) + 1
          
          if conversation_state.validation_attempts[current_field] >= 3 {
            !execute send_message("❌ Having trouble with this field. Let me connect you with a human agent.")
            !execute escalate_to_human(conversation_state)
          } else {
            !execute send_message(f"❌ {validation_error}\n\nPlease try again:")
          }
        }
      }
      
      // FORM COMPLETE HANDLING
      state(form_complete) + event(user_input) -> {
        user_response = input.text.lower().trim()
        
        if user_response in ["proceed", "submit", "yes", "done", "finish"] {
          !execute transition_to("confirmation")
        } else if user_response in ["add", "add more", "optional"] {
          // Allow adding optional fields
          form_template = conversation_state.selected_form_template
          collected = conversation_state.collected_fields
          
          missing_optional = []
          for field in form_template.optional_fields {
            if field not in collected {
              missing_optional.append(field)
            }
          }
          
          if missing_optional.empty {
            !execute send_message("All optional fields are already filled! Proceeding to confirmation...")
            !execute transition_to("confirmation")
          } else {
            !execute send_message(f"Optional fields available: {', '.join(missing_optional)}\nWhich would you like to add?")
          }
        } else {
          !execute send_message("Type 'proceed' to submit or 'add more' for optional fields.")
        }
      }
      
      // CONFIRMATION
      state(confirmation) + event(user_input) -> {
        user_response = input.text.lower().trim()
        
        if user_response in ["yes", "y", "confirm", "submit", "looks good"] {
          !execute transition_to("json_generated")
        } else if user_response.startswith("edit") {
          @decide {
            field_to_edit -> field_name [user_response, conversation_state.collected_fields.keys()]
          }
          
          if field_to_edit {
            conversation_state.current_field_name = field_to_edit
            field_prompt = conversation_state.selected_form_template.field_prompts[field_to_edit]
            !execute send_message(f"🔄 **Editing {field_to_edit.replace('_', ' ').title()}**\n{field_prompt}")
            !execute transition_to("collecting_fields")
          } else {
            field_list = ", ".join(conversation_state.collected_fields.keys())
            !execute send_message(f"❓ Which field would you like to edit?\nAvailable fields: {field_list}")
          }
        } else {
          !execute send_message("Please respond with 'yes' to confirm, 'edit [field]' to change something, or 'restart' to start over.")
        }
      }
      
      // RESTART HANDLING
      state(restart_confirmed) + event(user_input) -> {
        !execute clear_conversation_memory()
        conversation_state = {
          current_form_type: empty,
          selected_form_template: empty,
          collected_fields: {},
          missing_required_fields: [],
          current_field_name: empty,
          validation_attempts: {},
          conversation_turn: 0
        }
        !execute send_message("🔄 Conversation restarted. How can I help you today?")
        !execute transition_to("greeting")
      }
    }
    
    on_exit_state {
      json_generated -> {
        final_data = conversation_state.collected_fields
        
        request_json = {
          "request_id": f"REQ-{generate_request_id()}",
          "request_type": conversation_state.current_form_type,
          "form_name": conversation_state.selected_form_template.name,
          "timestamp": current_timestamp(),
          "customer_data": final_data,
          "collection_method": "manual_v1",
          "conversation_turns": conversation_state.conversation_turn,
          "validation_attempts": sum(conversation_state.validation_attempts.values()),
          "completion_status": "success"
        }
        
        !execute save_request_json(request_json)
        !execute send_message(f"""
🎉 **Request Created Successfully!**

📋 **Request ID:** {request_json.request_id}
📊 **Type:** {conversation_state.selected_form_template.name}
⏱️ **Collected in:** {conversation_state.conversation_turn} turns

Your request has been submitted to our team. You'll receive updates via your preferred contact method.

**Generated JSON:**
```json
{json.stringify(request_json, indent=2)}
```

*Type 'restart' if you need to create another request.*
        """)
        
        !execute clear_form_memory()
      }
    }
  }
  
  constraints {
    max_collection_time: 30_minutes
    max_validation_attempts: 3
    never: ["skip_required_fields", "accept_invalid_data", "lose_conversation_context"]
    always: ["validate_input", "confirm_before_submission", "provide_clear_feedback"]
  }
}

test_suite SupportV1Tests {
  scenario "account_issue_complete_flow" {
    sequence: [
      "greeting" -> "I have a problem" -> "form_selection",
      "form_selection" -> "1" -> "collecting_fields",
      "collecting_fields" -> "12345678" -> "collecting_fields",
      "collecting_fields" -> "login_problem" -> "collecting_fields", 
      "collecting_fields" -> "Can't log into my account" -> "collecting_fields",
      "collecting_fields" -> "high" -> "form_complete",
      "form_complete" -> "proceed" -> "confirmation",
      "confirmation" -> "yes" -> "json_generated"
    ]
    expect: {
      final_state: "json_generated"
      request_type: "account_issue"
      required_fields_complete: true
      collection_method: "manual_v1"
    }
  }
  
  scenario "validation_failure_and_recovery" {
    sequence: [
      "collecting_fields" -> "123" -> "validation_failed",  // invalid customer_id
      "validation_failed" -> "abc" -> "validation_failed",   // still invalid
      "validation_failed" -> "12345678" -> "collecting_fields"  // valid
    ]
    expect: {
      validation_attempts: 2
      final_value_valid: true
    }
  }
  
  scenario "restart_mid_conversation" {
    sequence: [
      "collecting_fields" -> "restart" -> "restart_confirmed",
      "restart_confirmed" -> "new request" -> "greeting"
    ]
    expect: {
      conversation_memory_cleared: true
      form_state_reset: true
    }
  }
}
