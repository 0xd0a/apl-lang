agent ResearchAssistant {
  role: "autonomous research specialist"
  
  objectives {
    primary: "provide comprehensive, accurate research on any topic"
    secondary: ["find authoritative sources", "synthesize insights", "identify knowledge gaps"]
  }
  
  resources {
    web_search: external("search_engine")
    academic_db: external("scholar_database") 
    expert_network: external("expert_contacts")
    data_apis: external("statistical_sources")
    internal_kb: external("company_knowledge")
    visualization: external("chart_tools")
    fact_check: external("verification_service")
  }
  
  behavior {
    on research_request {
      !execute log_research_start(user_id, input.query)
      
      // INITIAL STRATEGY PLANNING
      @decide {
        research_scope -> ["narrow_focused", "broad_exploratory", "deep_technical", "comparative"] [complexity+urgency+available_time]
        research_approach -> ["top_down", "bottom_up", "parallel_threads", "iterative_spiral"] [topic_familiarity+deadline]
        confidence_target -> 1..10 [accuracy_requirements+risk_tolerance]
        source_priorities -> ["academic", "industry", "news", "government", "expert_opinion"] [topic_type+credibility_needs]
      }
      
      !execute update_research_status("planning_complete", research_scope, research_approach)
      
      // ADAPTIVE RESEARCH EXECUTION
      research_complete = false
      iteration_count = 0
      findings = []
      
      while !research_complete && iteration_count < 10 {
        iteration_count += 1
        
        // CHOOSE NEXT RESEARCH ACTION
        @decide {
          next_action -> ["web_search", "academic_lookup", "expert_consultation", "data_analysis", "fact_verification", "synthesis", "conclude"] 
            [current_findings+knowledge_gaps+time_remaining+confidence_level]
          
          search_strategy(next_action) -> ["broad_keywords", "specific_terms", "related_concepts", "expert_names", "recent_developments"]
            [what_we_know+what_we_need]
        }
        
        match next_action {
          "web_search" -> {
            @decide {
              search_terms -> search_query [current_gaps+promising_leads]
              search_depth -> ["surface", "moderate", "deep"] [time_budget+information_density]
            }
            
            results = !execute web_search(search_terms, depth: search_depth)
            
            @decide {
              relevant_sources -> filtered_results [credibility+relevance+recency]
              key_insights -> extracted_facts [importance+novelty+reliability]
              follow_up_leads -> research_directions [promising_angles+unexplored_areas]
            }
            
            findings.append(key_insights)
            !execute update_research_status("web_search_complete", relevant_sources.count, key_insights.count)
          }
          
          "academic_lookup" -> {
            @decide {
              search_strategy -> ["author_focused", "keyword_focused", "citation_tree", "recent_papers"] [research_maturity+time_constraints]
              academic_depth -> ["abstracts_only", "full_papers", "comprehensive_review"] [technical_complexity+available_time]
            }
            
            papers = !execute academic_search(input.query, strategy: search_strategy, depth: academic_depth)
            
            @decide {
              paper_priorities -> ranked_papers [relevance+citation_count+journal_quality+recency]
              analysis_approach -> ["summary", "detailed_analysis", "meta_analysis"] [paper_count+complexity]
            }
            
            insights = !execute analyze_papers(paper_priorities, approach: analysis_approach)
            findings.append(insights)
          }
          
          "expert_consultation" -> {
            @decide {
              expert_type -> ["academic", "industry", "practitioner", "analyst"] [topic_domain+credibility_needs]
              consultation_mode -> ["quick_question", "structured_interview", "ongoing_dialogue"] [complexity+relationship_status]
            }
            
            available_experts = !execute find_experts(topic: input.query, type: expert_type)
            
            if available_experts.any {
              expert_insights = !execute consult_expert(available_experts.first, mode: consultation_mode)
              findings.append(expert_insights)
            } else {
              // Pivot to alternative approach
              @decide {
                alternative_approach -> ["industry_reports", "thought_leader_content", "conference_talks"] [expert_unavailability]
              }
              alternative_results = !execute execute_alternative(alternative_approach)
              findings.append(alternative_results)
            }
          }
          
          "data_analysis" -> {
            @decide {
              data_sources -> ["government_stats", "industry_data", "survey_results", "financial_data"] [topic_requirements+availability]
              analysis_type -> ["trend_analysis", "comparative_analysis", "correlation_study", "statistical_modeling"] [data_type+research_questions]
            }
            
            datasets = !execute gather_data(sources: data_sources)
            
            @decide {
              visualization_strategy -> ["charts", "infographics", "interactive_dashboard", "summary_tables"] [audience+complexity+data_type]
            }
            
            analysis_results = !execute analyze_data(datasets, type: analysis_type)
            visualizations = !execute create_visualizations(analysis_results, strategy: visualization_strategy)
            
            findings.append({data: analysis_results, visuals: visualizations})
          }
          
          "fact_verification" -> {
            @decide {
              verification_scope -> ["key_claims", "statistics", "quotes", "controversial_points"] [findings_reliability+stakes]
              verification_depth -> ["basic_check", "cross_reference", "primary_source", "expert_validation"] [accuracy_requirements]
            }
            
            verification_results = !execute verify_facts(findings, scope: verification_scope, depth: verification_depth)
            
            @decide {
              confidence_adjustment -> confidence_delta [verification_results]
              findings_update -> ["confirm", "flag_uncertain", "remove_disputed"] [verification_outcomes]
            }
            
            findings = !execute update_findings_confidence(findings, verification_results, findings_update)
          }
          
          "synthesis" -> {
            @decide {
              synthesis_approach -> ["narrative", "analytical", "comparative", "framework_based"] [findings_type+audience+purpose]
              structure_type -> ["executive_summary", "detailed_report", "research_brief", "presentation"] [output_requirements+stakeholder_needs]
              depth_level -> ["high_level", "moderate_detail", "comprehensive"] [audience_expertise+time_constraints]
            }
            
            synthesized_report = !execute synthesize_findings(findings, approach: synthesis_approach, structure: structure_type, depth: depth_level)
            
            @decide {
              quality_check -> assessment [completeness+accuracy+clarity+actionability]
              gaps_identified -> missing_elements [what_could_be_stronger]
            }
            
            if quality_check >= confidence_target {
              !execute finalize_research(synthesized_report)
              research_complete = true
            } else {
              // Continue research to address gaps
              @decide {
                gap_resolution_strategy -> ["additional_search", "expert_input", "deeper_analysis"] [gaps_identified+remaining_resources]
              }
            }
          }
          
          "conclude" -> {
            research_complete = true
          }
        }
        
        // ADAPTIVE DECISION: CONTINUE OR CONCLUDE?
        @decide {
          should_continue -> boolean [confidence_level+time_remaining+knowledge_gaps+diminishing_returns]
          next_priority -> research_direction [biggest_knowledge_gaps+highest_impact_potential]
        }
        
        if !should_continue {
          research_complete = true
        }
        
        !execute update_research_progress(iteration_count, findings.length, confidence_level)
      }
      
      // FINAL SYNTHESIS AND DELIVERY
      @decide {
        delivery_format -> ["detailed_report", "executive_summary", "presentation_slides", "interactive_dashboard"] [stakeholder_preferences+content_type]
        follow_up_recommendations -> ["additional_research_areas", "monitoring_suggestions", "update_schedule"] [findings_implications]
      }
      
      final_output = !execute prepare_final_delivery(findings, format: delivery_format)
      !execute send_research_results(final_output, follow_up_recommendations)
      !execute log_research_complete(iteration_count, findings.length, confidence_level)
    }
  }
  
  constraints {
    max_research_time: 2_hours
    min_sources: 3
    required_verification: "controversial_claims"
    never: ["present_unverified_as_fact", "ignore_conflicting_evidence", "exceed_time_budget"]
    always: ["cite_sources", "indicate_confidence_levels", "note_limitations"]
  }
  
  adaptive_strategies {
    when confidence_level < 7 {
      approach: "seek_additional_verification"
      resources: "prioritize_authoritative_sources"
    }
    
    when time_remaining < 30_minutes {
      approach: "focus_on_synthesis"
      resources: "use_existing_findings_only"
    }
    
    when conflicting_information_found {
      approach: "investigate_discrepancies"
      resources: "find_tie_breaking_sources"
    }
    
    when research_depth == "deep_technical" {
      approach: "prioritize_academic_sources"
      verification: "expert_consultation_required"
    }
  }
}

test_suite ResearchAssistantTests {
  scenario "market_research_request" {
    input: { query: "AI agent market size and growth projections for 2025-2027" }
    expect: {
      research_scope: "broad_exploratory"
      source_priorities: includes("industry")
      actions_taken: includes(["web_search", "data_analysis", "synthesis"])
      final_confidence: >= 7
    }
  }
  
  scenario "technical_deep_dive" {
    input: { query: "Latest developments in transformer architecture optimization" }
    expect: {
      research_scope: "deep_technical"
      source_priorities: includes("academic")
      actions_taken: includes(["academic_lookup", "expert_consultation"])
      verification_depth: "expert_validation"
    }
  }
  
  scenario "urgent_fact_check" {
    input: { 
      query: "Verify claims about new regulation impact on fintech",
      urgency: "high",
      time_limit: "30_minutes"
    }
    expect: {
      research_approach: "focused_verification"
      actions_taken: includes("fact_verification")
      max_iterations: <= 3
    }
  }
}
