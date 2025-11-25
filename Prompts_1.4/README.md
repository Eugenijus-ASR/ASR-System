# Prompts for the End-to-End Domain-Specific ASR Agent

This directory contains prompt examples and documentation used to conceptualize the thesis system as an end-to-end AI agent.  
The AI agent receives an input observation **X**, processes it through the full ASR pipeline:

1. Data understanding  
2. Feature and acoustic–linguistic inference  
3. Domain-specific reasoning  
4. Output generation  

and produces the final output **y**.

According to thesis requirement **1.4**, two prompts are included:

- `prompt1_zero_shot.md` — a simple zero-shot example where the agent is given only a new observation **X**.  
- `prompt2_few_shot.md` — a few-shot prompt that includes multiple (X, y) reference examples to guide the agent.

These prompts demonstrate how the end-to-end ASR agent interprets and processes Lithuanian domain-specific speech, following the methodology outlined in the thesis.
