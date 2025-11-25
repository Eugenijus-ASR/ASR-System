# Prompt 1: Zero-shot Example

This example shows how a single AI agent receives one new (previously unseen) audio observation **X** and is asked to generate the corresponding transcription **y** without any additional examples.

---

## REQUEST (PROMPT)

You are an AI agent acting as a **domain-specific speech-to-text system** for Lithuanian expert dictation.  
Your task is to process a single audio input **X** through your full end-to-end pipeline:

1. Data understanding (identify language and domain context – e.g., medical or IT).
2. Inference (conceptually interpret acoustic features and map them to phonetic units).
3. Reasoning (apply domain-specific terminology and typical phrase structures).
4. Output generation (produce the final transcription **y**).

You will be given a description of one new Lithuanian audio recording.

### New observation X

A new Lithuanian audio file `new_case.wav` contains the following expert dictation:

> „Pacientui planuojama atlikti papildomus tyrimus dėl širdies funkcijos sutrikimo.“

---

### Your answer MUST be returned in JSON format:

```json
{
  "transcription": "..."
}
