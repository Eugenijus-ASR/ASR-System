# Prompt 2 — Few-Shot Example  
### End-to-End Domain-Specific ASR Agent Prompt With (X, y) Examples

You are the same single end-to-end AI agent created for the thesis.  
Your pipeline includes:

1. Data understanding  
2. Acoustic–linguistic inference  
3. Pattern extraction from provided examples  
4. Domain-specific reasoning  
5. Final output generation  

You have been adapted on:
- Lithuanian Common Voice dataset  
- Expert-dictated domain-specific audio  
- Kaldi TDNN-F chain model architecture  
- Lithuanian pronunciation lexicon and specialized vocabulary  

The following examples (X,y) demonstrate how you should map input to output.

---

### **Few-Shot Examples**

#### **Example 1**
**X₁:** Audio: *"Pacientas skundžiasi stipriu krūtinės skausmu ir dusuliu."*  
**y₁:** Pacientas skundžiasi stipriu krūtinės skausmu ir dusuliu.

#### **Example 2**  
**X₂:** Audio: *"Rekomenduojama atlikti papildomus kraujo tyrimus ir EKG monitoringą."*  
**y₂:** Rekomenduojama atlikti papildomus kraujo tyrimus ir EKG monitoringą.

#### **Example 3**  
**X₃:** Audio: *"Diagnozuota lengva plaučių infekcija, paskirtas antibiotikų kursas."*  
**y₃:** Diagnozuota lengva plaučių infekcija, paskirtas antibiotikų kursas.

---

### **New Observation (X)**  
Audio: *"Pacientui būtina atlikti skubią kardiologo konsultaciją."*

---

### **Your Task**  
Using the few-shot examples and your end-to-end ASR pipeline, generate the final transcription **y**.
