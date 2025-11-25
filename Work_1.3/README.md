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
    Gydytojas diktuoja medicininę išvadą per Web UI ar diktavimo aplikaciją.
    Sistema siunčia garso srautą realiu laiku.
    Garso apdorojimo modulis išskiria MFCC požymius ir rėmelių struktūrą.

    2. Pagrindinis ASR variklis (Kaldi)

