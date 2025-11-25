# 1.3 GAI integracijos sprendinio aprašymas ir UML diagramos

Šiame skyriuje pateikiamas pasirinktos įmonės bei kuriamo sprendimo aprašymas, akcentuojant generatyvinio dirbtinio intelekto (GAI) integraciją į dalykinės (medicininės) kalbos automatinio kalbos atpažinimo (ASR) sistemą. Taip pat pateikiamos UML diagramos, vaizduojančios, kaip GAI komponentai sąveikauja su kitomis sistemos dalimis.

# 1.3.1 Pasirinkta įmonė ir jos veiklos sritis

Šiam magistrinio darbo sprendiniui pasirinkta įmonė yra „Tilde“ (arba kita panaši kalbos technologijų įmonė, vystanti ASR, NLP ir dirbtinio intelekto sprendimus Baltijos šalyse).
Įmonė specializuojasi:

- kalbos atpažinimo (ASR) technologijose,

- mašininio vertimo ir NLP sprendimuose,

- dirbtinio intelekto produktų integracijoje į verslo ir valstybinio sektoriaus sistemas,

- taikomųjų kalbos technologijų kūrime medicinos, teisės ir kitoms specifinėms sritims.

Kadangi magistriniame darbe kuriamas domenui pritaikytas ASR sprendimas su GAI patobulinta transkripcija, įmonė „Tilde“ yra natūralus kandidatas, galintis panaudoti šį sprendinį realioje veikloje (integruojant į E. sveikatos sistemas ar ligoninių informacines sistemas).

# 1.3.2 Sprendimo architektūros aprašymas

Sistemos tikslas – iš gydytojo diktuojamo garso generuoti struktūruotą, tikslų ir domenu paremtą medicininį tekstą, pritaikytą įkėlimui į E. sveikatos (HIS / EHR) sistemas.

Sprendinį sudaro šie pagrindiniai komponentai:

    1. Garso surinkimas ir apdorojimas
    - Gydytojas diktuoja medicininę išvadą per Web UI ar diktavimo aplikaciją.
    - Sistema siunčia garso srautą realiu laiku.
    - Garso apdorojimo modulis išskiria MFCC požymius ir rėmelių struktūrą.

    2. Pagrindinis ASR variklis (Kaldi)
    - Naudojamas kaip pirmas žingsnis generuojant pirminę transkripciją y₀.
    - Kaldi atlieka akustinį ir lingvistinį dekodavimą.

    3. RAG orkestratorius
    - Paimama pirminė Kaldi transkripcija.
    - Vykdoma semantinė paieška ChromaDB duomenų bazėje.
    - Paimami top-3 panašiausi (X, y) pavyzdžiai iš domeno duomenų rinkinio.
    - Generuojamas RAG promptas LLM modeliui (kontekstas + y₀).

    4. Generatyvinis dirbtinis intelektas (Gemini 2.5 Flash)
    - LLM sudaro patobulintą transkripciją y₁.
    - Modelis pritaiko medicininę terminologiją, sutvarko gramatiką, sustiprina semantinį tikslumą.
    - Tai yra integracijos vieta su GAI technologijomis.  

    5. Rezultatų validavimas
    - Gydytojas peržiūri, redaguoja ir patvirtina generuotą tekstą.
    - Tekstas išsaugomas į E. sveikatos sistemą.    

    6. Administraciniai procesai
    - IT administratorius stebi kokybę.
    - Atnaujina domeno pavyzdžių rinkinį (X,Y parosinių įrašų DB).
    - Atlieka modelių versijavimą ir architektūros priežiūrą. 

# 1.3.3 UML diagramos

Toliau pateikiamos UML diagramos, kurios parodo, kaip GAI integruojamas į sistemą.

A. Use case diagrama
```
Aprašymas
Naudotojai:
    Gydytojas
    Medicinos sekretorė
    IT administratorius
Pagrindiniai GAI scenarijai:
    LLM pagerintos transkripcijos generavimas
    Domeno pavyzdžių paieška ChromaDB
    Automatizuotas RAG prompto sudarymas
    Modelių priežiūra ir kokybės monitoringas
```



