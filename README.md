# ASR-System
Lithuanian language recognition using Kaldi system / Lietuvių kalbos atpažinimas naudojant Kaldi sistemą

# Duomenų katalogas

Šiame kataloge pateikiami treniravimo ir vertinimo duomenys, naudojami baigiamajame darbe „Dalykinės kalbos atpažinimas naudojant apmokymą“.
Duomenys organizuoti į prižiūrimus (supervised) duomenų poras (X, y), kur:

- **X (įvestis): eksperto diktuojamų sakinių/frazių garso įrašas, pateikiamas kaip žaliavinis garso signalas arba akustiniai požymiai (MFCC, i-vektoriai).  
- **y (išvestis): garso transkripcija tekstu, apimanti specializuotą terminologiją iš pasirinkto domeno (pvz., medicinos ar technikos).  

---

## Katalogo struktūra

Data_X_Y\

  ├── audio\       # Raw audio recordings (.wav files)

  ├── text\        # Reference transcriptions (.txt files)

Prompts_1.4\         # Prompt scripts for model training/testing

features\        # Pre-computed features (MFCC, i-vectors)

README.md        # Documentation (this file)

---

## (X, y) duomenų porų pavyzdžiai (Lab 1.2)

**Pavyzdys 1**  
- **X:** `audio/001.wav` → MFCC požymių seka  
- **y:** `"Paciento kraujospūdis yra normalus"`

**Pavyzdys 2**  
- **X:** `audio/002.wav` → MFCC + i-vektorius (kalbėtojo adaptacijai)  
- **y:** `"Atlikta kompiuterinė tomografija"`

**Pavyzdys 3**  
- **X:** `audio/003.wav` → MFCC + leksikos žemėlapis iš domeno žodyno  
- **y:** `"Pacientui paskirta intraveninė terapija"`

**Pavyzdys 4**  
- **X:** `audio/004.wav` → Akustiniai požymiai (MFCC, CMVN normalizuoti)  
- **y:** `"Duomenų bazės serveris sėkmingai paleistas"`

**Pavyzdys 5**  
- **X:** `audio/005.wav` → Požymių seka, reprezentuojanti kalbos signalą  
- **y:** `"Įvykis užregistruotas informacinėje sistemoje"`

## Pastabos
- Visi garso įrašai saugomi mono, 16 kHz WAV formatu.**.  
- Transkripcijos pateiktos UTF-8 koduotės tekstiniuose failuose.**.  
- Požymiai išskirti naudojant standartinį Kaldi apdorojimo pipeline (MFCC, CMVN, i-vektoriai).  
- Duomenų rinkinį sudaro: viešai prieinami lietuvių kalbos garso duomenys (Common Voice), specialiai įrašyti eksperto domeno garsai.

---

# UML-Based System Design and GAI Integration (Lab 1.3)
### Magistro darbas: „Dalykinės kalbos atpažinimas naudojant apmokymą“

Šiame etape buvo sukurta išsami dalykinės kalbos ASR sistemos architektūra ir su UML diagramomis pavaizduota, kaip generatyvinis dirbtinis intelektas (GAI) integruojamas į siūlomą sprendimą. 
Darbe buvo identifikuoti pagrindiniai naudotojai, sistemos komponentai ir jų tarpusavio sąveikos.

Pagrindiniai šio etapo rezultatai:
- Sukurta Use Case diagrama, parodanti pagrindinius sistemos naudotojus (gydytoją, medicinos sekretorę, IT administratorių) ir jų sąveiką su ASR sistema.
- Parengta komponentų diagrama, vaizduojanti visą architektūrą: garso apdorojimą, Kaldi ASR, RAG orkestratorių, vektorių duomenų bazę (ChromaDB) ir GAI (Gemini API) modulį.
- Nubraižyta sekos diagrama, pademonstruojanti pilną procesą: nuo garso įvedimo → pirminės transkripcijos → RAG paieškos → LLM patobulinimo → galutinio teksto išsaugojimo E. sveikatos sistemoje.
- Atliktas sistemos elgsenos modeliavimas, parodant GAI vaidmenį transkripcijos tikslumo gerinime.

Ši UML analizė suformavo aiškų techninį pagrindą tolesniems etapams ir leido tiksliai suplanuoti end-to-end GAI integraciją, kuri vėliau įgyvendinama 1.4–1.6 laboratoriniuose darbuose.

---

# Demonstration of an End-to-End AI Solution using Gemini API (Lab 1.4)
### Magistro darbas: „Dalykinės kalbos atpažinimas naudojant apmokymą“

Šiame Colab aplanke demonstruojama pilnai veikianti end-to-end AI sistema, sukurta remiantis 1.4 laboratorinio darbo promptų inžinerija.  
Sistema vykdo domenui pritaikytus lietuvių kalbos kalbos-atpažinimo (speech-to-text) užklausas per Gemini API.

Pagrindiniai šio aplanko tikslai:
- Saugiai įkelti ir naudoti Gemini API raktą (naudojant Colab Secrets).
- Paleisti zero-shot ir few-shot promptų pavyzdžius.
- Pademonstruoti visą apdorojimo pipeline:
duomenų supratimas → samprotavimas → sprendinių generavimas → išvesties gavimas.
- Dokumentuoti sistemos elgseną kaip end-to-end AI agento.
- Susieti šį Colab aplanką su GitHub saugykla.

---

# End-to-End AI System Demonstration using the Gemini API (Lab 1.5)
### Magistro darbas: „Dalykinės kalbos atpažinimas naudojant apmokymą“

Šiame etape buvo įgyvendintas ir pademonstruotas pilnai veikiantis end-to-end dirbtinio intelekto sprendinys, kuris vykdo dalykinės lietuvių kalbos transkripciją pasitelkiant Gemini API. Užduotis tęsia ankstesnę 1.4 laboratorinio darbo promptų inžineriją ir parodo, kaip AI agentas gali būti pritaikytas realiam praktiniam naudojimui.

Pagrindiniai šio etapo rezultatai:
- Sukurtas Google Colab aplankas, kuriame dokumentuojamas visas sistemos veikimo procesas.
- Saugiai integruotas Gemini API raktas, naudojant Colab Secrets mechanizmą (be kodo įterpimo į aplanką).
- Į Colab įtraukti zero-shot ir few-shot promptų pavyzdžiai, paremti 1.4 etapo medžiaga.
- Pademonstruotas visas transkripcijos pipeline:
įvesties duomenų analizė → samprotavimas → modelio išvestis → rezultatų sugeneravimas.
- Pateiktas end-to-end agento veikimo įrodymas, naudojant tikrą domeno tekstų transkripciją.
- Dokumentuota sistemos elgsena, o galutinis Colab aplankas susietas su GitHub saugykla.

Ši demonstracija patvirtino, kad suprojektuota RAG + GAI architektūra gali veikti kaip realus praktinis sprendimas, galintis priimti garso įvestį, apdoroti ją per kelis etapus ir sugeneruoti tikslią, semantiškai praturtintą transkripciją.

---

# Retrieval-Augmented Generation (RAG) Extension (Lab 1.6)
### Magistro darbas: „Dalykinės kalbos atpažinimas naudojant apmokymą“

Šiame etape į esamą ASR + GAI sprendimą buvo integruota Retrieval-Augmented Generation (RAG) metodika. Ji išplečia AI sistemos galimybes, leidžiant modeliui priimti kontekstą iš didelės domeno žinių bazės, pagerinti transkripcijos tikslumą ir sumažinti klaidas, ypač specifinėje dalykinėje kalboje.

Pagrindiniai šio etapo rezultatai:
- Sukurtas 1200+ (X,y) domeno pavyzdžių rinkinys, naudojamas kaip semantinė bazė RAG paieškai.
- Duomenys suindeksuoti ir įkelti į ChromaDB vektorių duomenų bazę, naudojant sakinių embedding'ų modelį semantinei paieškai.
- Įgyvendintas automatinis konteksto atrinkimas, kuris bet kuriai naujai įvesčiai X suranda top-3 semantiškai panašius pavyzdžius iš duomenų bazės.
- Suformuota RAG prompto struktūra:
(pirminė transkripcija y₀ + artimiausi pavyzdžiai + instrukcijos).
- RAG praturtintas promptas siunčiamas į Gemini 2.5 Flash (LLM API), kuris grąžina semantiškai pagerintą transkripciją y₁.
- Google Colab aplanke pademonstruotas visas RAG procesas:
įvestis → paieška → pavyzdžių įterpimas → prompto generavimas → LLM transkripcija.
- Atliktas rezultato palyginimas su zero-shot metodu ir parodyta, kad RAG metodas padidina stabilumą bei tikslumą, ypač medicininiuose tekstuose.

Ši užduotis užbaigia end-to-end ASR + GAI architektūros kūrimą ir parodo, kaip realaus pasaulio duomenų kontekstas gali būti įtrauktas į generatyvinio DI sprendimo veikimą, ženkliai pagerinant jo domeninę kompetenciją.
