# ASR-System
Lithuanian language recognition using Kaldi system

# Data Directory

This directory contains the training and evaluation data used in the thesis **"Subject Matter Language Recognition Using Training"**.  
The data is organized into supervised pairs **(X, y)**, where:

- **X (input):** audio recording of expert-dictated sentences/phrases, represented as raw waveform or extracted acoustic features (MFCC, i-vectors).  
- **y (output):** text transcription of the audio, including specialized terminology from the chosen domain (e.g., medical or technical vocabulary).  

---

## Directory Structure
\data

├── audio\ # Raw audio recordings (.wav files)

├── text\ # Reference transcriptions (.txt files)

├── features\ # Pre-computed features (MFCC, i-vectors)

└── README.md # Documentation (this file)

---

## Examples of (X, y) Pairs

**Example 1**  
- **X:** `audio/001.wav` → MFCC feature sequence  
- **y:** `"Paciento kraujospūdis yra normalus"`

**Example 2**  
- **X:** `audio/002.wav` → MFCC + i-vector (speaker adaptation)  
- **y:** `"Atlikta kompiuterinė tomografija"`

**Example 3**  
- **X:** `audio/003.wav` → MFCC + lexical mapping from the domain dictionary  
- **y:** `"Pacientui paskirta intraveninė terapija"`

**Example 4**  
- **X:** `audio/004.wav` → Acoustic features (MFCC, CMVN normalized)  
- **y:** `"Duomenų bazės serveris sėkmingai paleistas"`

**Example 5**  
- **X:** `audio/005.wav` → Feature vector sequence representing the speech signal  
- **y:** `"Įvykis užregistruotas informacinėje sistemoje"`

---

## Notes
- All audio recordings are stored in **mono, 16 kHz WAV format**.  
- Transcriptions are stored in **UTF-8 encoded text files**.  
- Features are extracted using Kaldi’s standard preprocessing pipeline (MFCC, CMVN, i-vectors).  
- The dataset combines **publicly available Lithuanian speech data** (Common Voice) with **custom expert-recorded domain-specific speech**.  
