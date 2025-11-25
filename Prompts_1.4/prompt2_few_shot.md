# Prompt 2: Few-shot Example

This example extends Prompt 1 by providing several known (X, y) pairs before asking you to transcribe a new audio input.  
These pairs simulate training examples from the thesis dataset (audio files and their ground-truth transcriptions).

---

## REQUEST (PROMPT)

You are the same AI agent: a **domain-specific Lithuanian speech-to-text system**.  
You process every input **X** through the complete pipeline:

1. Data understanding  
2. Acoustic–linguistic inference  
3. Domain-specific reasoning  
4. Output generation of **y**

Below you are given several examples of audio recordings and their correct transcriptions.  
Use these examples to understand the style, domain, and sentence structure before transcribing a new case.

---

## Few-shot examples (X, y)

### Example 1
```
**X₁:** Audio file: `001.wav` – short Lithuanian sentence about the patient’s blood pressure.  
**y₁:** Paciento kraujospūdis yra normalus.
```

### Example 2
```
**X₂:** Audio file: `002.wav` – Lithuanian sentence about an imaging procedure.  
**y₂:** Atlikta kompiuterinė tomografija.
```

### Example 3
```
**X₃:** Audio file: `003.wav` – Lithuanian sentence about prescribed treatment.  
**y₃:** Pacientui paskirta intraveninė terapija.
```

### Example 4
```
**X₄:** Audio file: `004.wav` – Lithuanian sentence about an IT system component.  
**y₄:** Duomenų bazės serveris sėkmingai paleistas.
```

### Example 5
```
**X₅:** Audio file: `005.wav` – Lithuanian sentence about an event in an information system.  
**y₅:** Įvykis užregistruotas informacinėje sistemoje.
```

---

## New observation X₆

Now you receive a new Lithuanian audio file `006.wav`.  
It contains a short expert dictation related to system maintenance:

> „Atsarginė duomenų kopija sėkmingai sukurta ir patikrinta.“

---

### Your answer MUST be returned in JSON format:

```json
{
  "transcription": "..."
}
```
Replace ... with the best Lithuanian transcription y₆ for this new audio, using patterns learned from the previous (X, y) pairs and your end-to-end ASR pipeline.
