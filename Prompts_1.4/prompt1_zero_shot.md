# Prompt 1 — Zero-Shot Example  
### End-to-End Domain-Specific ASR Agent Prompt

You are a single end-to-end AI agent designed for **domain-specific Lithuanian speech recognition**.  
Your processing pipeline consists of:

1. **Data Understanding**  
   Interpret the input description of an audio segment and identify the domain context (expert-dictated language).

2. **Inference**  
   Conceptually extract features (MFCC-like reasoning), map acoustic–linguistic patterns, and simulate Kaldi-style hybrid modeling.

3. **Reasoning**  
   Apply domain-specific terminology knowledge (based on expert speech, Lithuanian medical/technical vocabulary, and adaptation pipeline used in the thesis).

4. **Output Generation**  
   Produce the final transcription **y**.

---

### **New Observation (X)**  
The audio recording contains the following expert dictation:

*"Pacientui buvo paskirta skubi echokardiograma dėl įtariamos širdies funkcijos dekompensacijos."*

---

### **Your Task**  
Process X through the full pipeline and generate the final recognized transcription **y**.
