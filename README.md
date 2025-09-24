# ASR-System
Lithuanian language recognition using Kaldi system

X (input):

Audio signal (expert-dictated sentences/phrases)

Extracted features, e.g., MFCC (Mel-Frequency Cepstral Coefficients), spectral properties, i-vectors (for speaker adaptation)

Additionally: domain-specific terms (dictionary, language model)

Y (output):

Text transcription (sequence of words in written form)

Including specialized terminology from the chosen domain (e.g., medical or technical vocabulary)


Simplified:

👉 X = audio recording (speech signal converted into features)

👉 Y = recognized text (domain-specific transcription)

Each (X, y) pair consists of an audio recording (X) and its corresponding transcription (y). The input audio is transformed into acoustic features (MFCC, i-vectors), while the output transcription includes domain-specific terminology relevant to the expert’s field.

Examples of (X, y) pairs

Example 1

X: Audio file 001.wav (expert-dictated phrase) → MFCC features extracted from the waveform

y: "Paciento kraujospūdis yra normalus"

Example 2

X: Audio file 002.wav → MFCC + i-vector (speaker adaptation)

y: "Atlikta kompiuterinė tomografija"

Example 3

X: Audio file 003.wav → MFCC features + lexical mapping from the domain dictionary

y: "Pacientui paskirta intraveninė terapija"

Example 4

X: Audio file 004.wav → Acoustic features (MFCC, CMVN normalized)

y: "Duomenų bazės serveris sėkmingai paleistas"

Example 5

X: Audio file 005.wav → Feature vector sequence representing the speech signal

y: "Įvykis užregistruotas informacinėje sistemoje"
