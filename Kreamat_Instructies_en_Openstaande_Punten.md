# Kreamat - Instructies en openstaande punten

Dit document groeit mee met elke sprint. Per sprint staat wat er gebouwd is, hoe je het gebruikt en wat er nog moet gebeuren. Onderaan staat het overzicht van alle openstaande punten.

## Status per sprint

| Sprint | Inhoud | Status |
|---|---|---|
| 1 | Basis, datamodel, orderkenmerken op de verkoopregel (KRM-002/010/011/012) | Klaar |
| 2 | Regelkenmerken-pagina, factbox, wezen en integriteit, opnieuw ophalen (KRM-013/014/015/016) | Klaar |
| 3 | Kenmerkbeperkingen, combinaties en cascade, staalkaart en Excel-import, toegelaten waarden testen (KRM-020/021/022/023) | Klaar |
| 4 | Optiegroepen, toegelaten opties, optie-afhankelijkheden, optieregels (KRM-030 t/m 035) | Klaar |
| 5 | Maatafwijking en toeslag, maatwerk, controles bij vrijgeven en boeken (KRM-040/041/042/050) | Klaar |
| 6 | Doorgifte bij omzetten, kopieren, boeken en archiveren (KRM-060/061/062/063) | Klaar |
| 7 | Kenmerken op klantdocumenten, werkbon, registratie en herdruk, overzicht regelkenmerken (KRM-070/071/072/080) | Klaar |
| KRM-100 (acceptatietest) en KRM-102 (livegang) | Door Kreamat en de BC-partner. Voor de livegang is de checklist klaar: `Kreamat_Livegang_Checklist.docx` (en PDF) | Nog te doen |
| KRM-101 (gebruikershandleiding) | Handleiding klaar: `Kreamat_Gebruikershandleiding.docx` (en PDF). Opleiding door Attitutor. | Handleiding klaar |
| EP-12, KRM-110/111/112 | Latere fase | Niet gestart |

Configuratietaken (door Kreamat/BC-partner, niet in code): KRM-090, KRM-091, KRM-092, KRM-093, KRM-094.

## Sprint 1 - Orderkenmerken op de verkoopregel

- Instelling per artikelcategorie, artikel of variant welke orderkenmerken gevraagd worden (pagina Orderkenmerken instellen, tabel `PTE Order Attribute Setup`), met volgorde, verplicht en niet van toepassing.
- Bij een verkoopregel worden de kenmerken opgebouwd uit de instelling, de artikelkenmerken en de variantkenmerken.
- KRM-090: de actie "Orderkenmerken aanmaken" op de pagina Artikelkenmerken maakt de kenmerken voor orders aan (Hardheid, Stof, Kleur, Stof achterkant, Kleur achterkant, Afwijkende breedte/lengte/hoogte). Uit te voeren in sandbox en daarna productie.
- KRM-091: configuratie per productfamilie (hoofdstuk 4 van de functionele analyse), na KRM-090.

## Sprint 2 - Regelkenmerken

- Pagina Regelkenmerken en een factbox op de verkoopregel.
- Pagina Wezen-kenmerken (zoek "Orphaned Line Attributes", Alt+Q): kenmerken op een regel die niet meer in de instelling staan.
- Actie om de kenmerken van een regel opnieuw op te halen (Rebuild). Dit staat op de zes subpagina's en op de verkoopregels.

## Sprint 3 - Kenmerkbeperkingen, staalkaart en Excel-import

### Hoe werken beperkingen
- Een beperking is een rij met een toegelaten waarde voor een kenmerk, op niveau Alle artikelen, Artikelcategorie, Artikel of Variant, eventueel met een voorwaarde (kenmerk + waarde).
- Staan er geen regels voor een kenmerk, dan is elke waarde toegelaten.
- Het specifiekste niveau wint: Variant, dan Artikel, dan Artikelcategorie (en bovenliggende categorieen), dan Alle artikelen. Dit geldt per groep (voorwaardekenmerk + waarde). Groepen vormen samen een doorsnede.
- Een regel met een voorwaardekenmerk zonder waarde geldt niet.
- Geblokkeerd = de waarde kan niet meer gekozen worden (bv. een stof die niet meer geleverd wordt).
- Bij wijziging van een kenmerk worden ongeldige waarden van afhankelijke kenmerken gewist (cascade).
- Pagina "Toegelaten waarden testen" (Test Allowed Values) toont per kenmerk de toegelaten waarden voor een artikel en variant, met niveau en voorwaarde.

### Staalkaart
- Pagina Staalkaart (Swatch Book): stoffen per categorie, met per stof de kleuren (actie Kleuren).
- Pagina Staalkaartinstelling (Alt+Q "Swatch Book Setup"): welke kenmerken stof, categorie en kleur zijn. Standaard op naam: Categorie Fabric, Stof, Kleur, Achterkant Fabric, Stof achterkant, Kleur achterkant. Controleren.
- De achterkant wordt gesynchroniseerd uit de voorkant (bij sluiten van de staalkaart, na import of via de actie Achterkant synchroniseren). Enkel categorieen die ook als waarde van Achterkant Fabric bestaan komen mee. Stoffen en kleuren worden aangemaakt.

### Excel-import (KRM-092 en KRM-093)
Sjabloon: `Kreamat_Import_Sjabloon.xlsx` in deze map (bladen Instructies, Staalkaart, Kenmerkbeperkingen, Optiegroepen, Toegelaten opties, Optie-afhankelijkheden, Voorbeelden, Voorbeelden opties, Referentie).

1. Kreamat vult de bladen **Staalkaart** (Stof, Categorie, Kleur), **Kenmerkbeperkingen** en de bladen voor de opties in. Het blad Instructies in het sjabloon legt elke kolom uit, de bladen Voorbeelden en Voorbeelden opties tonen de gevallen uit de analyse.
2. Open in Business Central de pagina Staalkaart of Kenmerkbeperkingen en kies **Importeren uit Excel**.
3. Volgorde: staalkaart, beperkingen, optiegroepen, toegelaten opties, optie-afhankelijkheden. Een blad dat ontbreekt wordt overgeslagen. Ontbreken alle bladen, dan volgt een foutmelding.
4. Na afloop staat in een melding hoeveel rijen zijn ingelezen en welke rijen zijn overgeslagen (met rijnummer en reden).

Regels van de import:
- Namen van bladen en kolomhoofden (rij 1) niet wijzigen.
- Categorieen op het blad Staalkaart moeten al bestaan als waarde van Categorie Fabric. Stoffen en kleuren worden aangemaakt.
- Niveau mag Nederlands, Engels of in de taal van de gebruiker (Alle artikelen, Artikelcategorie, Artikel, Variant).
- Code moet bestaan als artikelcategorie, artikel of (met Variantcode) variant. Leeg bij Alle artikelen.
- Kenmerknaam moet exact overeenkomen met de naam in BC. Bij optiekenmerken moet de waarde al bestaan, bij een numeriek kenmerk gebruik je Minimum en/of Maximum.
- Voorwaarde kenmerk en voorwaarde waarde: beide invullen of geen van beide.
- De import is herhaalbaar: bestaande rijen worden niet dubbel aangemaakt, alleen Geblokkeerd wordt bijgewerkt.
- Decimalen worden gelezen in de taalinstelling van de gebruiker. Gebruik hele getallen of de notatie die Excel toont.

Import van de opties (bladen Optiegroepen, Toegelaten opties, Optie-afhankelijkheden), in dezelfde actie en na de staalkaart en de beperkingen:
- Optiegroepen: Code, Omschrijving, Minimum, Maximum. Een bestaande groep wordt bijgewerkt. Minimum groter dan maximum wordt geweigerd. Vul dit blad eerst in.
- Toegelaten opties: Niveau, Code, Variantcode, Optiegroep, Optieartikel, Optievariant, Aantal per hoofdproduct (leeg = 1), Aantal volgt hoofdregel (leeg = Ja), Standaard toevoegen, Niet van toepassing, Variant zoeken op en Kenmerken overnemen (kenmerknamen gescheiden door ;). De optiegroep, het artikel en de kenmerken moeten bestaan. Een bestaande optie (zelfde niveau, code, variant, groep en optieartikel) wordt bijgewerkt en zijn kenmerklijsten worden vervangen.
- Optie-afhankelijkheden: Optieartikel of Optiegroep, Soort (Vereist of Sluit uit), Ander optieartikel of Andere optiegroep. Een bestaande regel wordt niet dubbel aangemaakt.
- Foute rijen worden overgeslagen en gemeld met het rijnummer, zoals bij de andere bladen.

## Sprint 4 - Opties en artikelcombinaties (KRM-030 t/m 035)

### Instelling (door beheerder, zoek via Alt+Q)
- **Optiegroepen** (bv. POTEN, ONDERBOUW, MOTOR, ACCESS): code, omschrijving, minimum en maximum aantal keuzes (leeg of 0 = onbeperkt). Een minimum groter dan het maximum wordt geweigerd. Een groep die in gebruik is, kan niet verwijderd worden.
- **Toegelaten opties**: per niveau (Alle artikelen, Artikelcategorie, Artikel, Variant) + code + variantcode van het hoofdproduct: optiegroep, optieartikel, eventueel vaste optievariant, aantal per hoofdproduct, aantal volgt hoofdregel, standaard toevoegen en niet van toepassing. Acties **Variant zoeken op** (kenmerken die tussen hoofdregel en optievariant moeten overeenkomen) en **Kenmerken overnemen** (kenmerken die van de hoofdregel naar de optieregel gekopieerd worden).
- **Optie-afhankelijkheden**: een optieartikel of optiegroep **vereist** of **sluit uit** een ander optieartikel of een andere optiegroep.
- Artikelkaart: veld **Alleen als optie verkopen** en acties **Toegelaten opties instellen** en **Toegelaten opties tonen** (resultaat per groep met het niveau waar de optie vandaan komt).
- Verkoopinstelling: **Regelkorting doorgeven aan optieregels** (standaard Ja).

### Regels
- Per optiegroep vervangt het meest specifieke niveau (variant, artikel, categorie, bovenliggende categorie, alle artikelen) de lijst van de algemenere niveaus.
- Niet van toepassing zonder optieartikel schakelt de hele groep uit op dat niveau. Niet van toepassing met een optieartikel verwijdert alleen die optie uit de overgeerfde lijst.
- Meerdere **Vereist**-rijen voor dezelfde optie zijn alternatieven: een van de vereiste opties volstaat. Twee verschillende dingen tegelijk vereisen wordt niet ondersteund.
- Standaardopties worden toegevoegd bij het aanmaken van de hoofdregel, en opnieuw als na een artikel- of variantwijziging een groep geen optieregel meer heeft.
- Het maximum per groep, vereist en sluit uit worden direct gecontroleerd bij Opties toevoegen en Koppelen aan hoofdregel. Het minimum per groep wordt alleen gecontroleerd op verzoek (voor KRM-050, bij vrijgeven).

### Gebruik op de verkoopregel (offerte, order, raamorder, factuur)
- **Opties toevoegen**: toont de toegelaten opties per groep met voorgesteld aantal en voorgestelde variant. De gekozen opties komen direct onder de hoofdregel (na de bestaande optieregels), met Gekoppeld aan regelnr. en Optiegroep. Is er geen of meer dan een passende variant, dan volgt een melding om zelf een variant te kiezen.
- **Koppelen aan hoofdregel**: koppelt een rechtstreeks ingegeven regel achteraf, met dezelfde controles. De regel behoudt zijn regelnummer en staat dus niet automatisch onder de hoofdregel.
- Een optieregel kan zelf geen opties hebben (een niveau).
- Artikelen met **Alleen als optie verkopen** kunnen niet als losse regel ingegeven worden. Accessoires zonder die markering wel.
- De optieregels volgen de hoofdregel: aantal (hoofdregel x aantal per hoofdproduct), locatie, verzenddatum, gevraagde en beloofde leverdatum, regelkorting (bij manuele wijziging op de hoofdregel in het scherm) en te verzenden / te factureren (in verhouding, bij manuele wijziging in het scherm). Wijzigt de gebruiker te verzenden of te factureren op een optieregel, dan volgt een waarschuwing en wordt de waarde aanvaard.
- Overgenomen kenmerken volgen de hoofdregel. Wijzigt de gebruiker het kenmerk op de optieregel, dan stopt de synchronisatie voor dat kenmerk en volgt bij een volgende wijziging op de hoofdregel een melding.
- Hoofdregel verwijderen: bevestiging, de optieregels worden mee verwijderd. Een volledig document verwijderen vraagt geen bevestiging per regel.
- Ander artikel of andere variant op de hoofdregel: de optieregels worden opnieuw gecontroleerd. Niet meer toegelaten opties worden na bevestiging verwijderd en de variant van de optieregels wordt na bevestiging opnieuw voorgesteld.
- Voor KRM-050 bestaat `PTE Allowed Option Mgt.`.`GetViolations(SalesLine, CheckMinimum)`: een herbruikbare controle van maximum, minimum, vereist en sluit uit voor een hoofdregel.

### Technische opmerking
- Bij het valideren van het artikelnummer initialiseert BC de verkoopregel volledig. De koppelvelden van optieregels worden daarom bewaard en daarna hersteld (`PTE Option Line Mgt.`).

## Sprint 5 - Maatafwijking, maatwerk en controles (KRM-040/041/042/050)

### Instelling maatafwijking (KRM-040, zoek via Alt+Q)
- **Instelling maatafwijking**: per niveau (Alle artikelen, Artikelcategorie, Artikel) het toeslagartikel, de maximale afwijking in cm (leeg = geen limiet) en de afronding (standaard 0,01). Het meest specifieke niveau wint. Het toeslagartikel moet een niet-voorraadartikel of een dienst zijn.
- Actie **Toeslagschijven**: tot en met afwijking (cm) en toeslag %. De schijf zonder bovengrens geldt voor alles daarboven. Standaard van Kreamat: tot en met 15 cm 25%, daarboven 50%. De schijven worden gesorteerd getoond, de open schijf laatst.
- Actie **Maatkenmerken** (pagina Instelling maatkenmerken): welke kenmerken de standaardmaten (Breedte, Lengte, Hoogte) en de afwijkende maten (Afwijkende breedte, lengte, hoogte) bevatten. Standaard op naam, controleren.

### Werking op de verkoopregel (KRM-041/042)
- De verkoper kiest de variant met de dichtstbijzijnde standaardmaat en vult bij de regelkenmerken de afwijkende maat in.
- De afwijking per maat is het absolute verschil met de standaardmaat van de variant (hoogte ook van het artikel). De grootste afwijking bepaalt het percentage. Er is een toeslagregel per hoofdregel.
- De toeslagregel is een gekoppelde regel onder de hoofdregel: toeslagartikel, aantal van de hoofdregel, eenheidsprijs = eenheidsprijs hoofdregel x % (afgerond), regelkorting van de hoofdregel en een omschrijving zoals "Toeslag maatwerk +25% (breedte 85 cm i.p.v. 80 cm)".
- Herberekening bij wijziging van de afwijkende maat, de variant, het artikel, de eenheidsprijs of het aantal. De toeslagregel verdwijnt als de maat gewist wordt of gelijk is aan de standaardmaat.
- Is de prijs van de toeslagregel manueel aangepast, dan vraagt BC bij de volgende herberekening of hij overschreven mag worden.
- Een afwijking groter dan de maximale afwijking geeft een foutmelding bij het invullen.
- Veld **Maatwerk** op de verkoopregel: automatisch Ja zodra een afwijkende maat is ingevuld, filterbaar op de pagina Verkoopregels.
- Een regel met Maatwerk = Ja kan niet uit voorraad gereserveerd worden (controle op het aanmaken van de reservering).
- De toeslagregel telt niet mee als optie voor de optiecontroles (maximum, minimum, vereist, sluit uit).
- KRM-094 (configuratie): Kreamat levert het toeslagartikel TOESLAG MAATWERK met boekingsgroepen, de schijven en de maximale afwijking per familie. De BC-partner voert dit in via de pagina Instelling maatafwijking.

### Controle bij vrijgeven en boeken (KRM-050)
- Bij vrijgeven van order, raamorder, retourorder, factuur en creditnota wordt elke artikelregel gecontroleerd op: verplichte orderkenmerken ingevuld, waarden toegelaten volgens de kenmerkbeperkingen (ook geblokkeerde waarden), verplichte en niet-toegelaten opties (minimum en maximum per groep, vereist, sluit uit, alleen als optie), maatafwijking binnen de grenzen en een actuele toeslagregel.
- Alle fouten van het document komen samen in een melding, bv. "Regel 20000 - B00002 Boxspring Sparta H12 PLUS (080x200-B): Stof, Kleur niet ingevuld".
- Hetzelfde gebeurt bij boeken als het document nog niet vrijgegeven is. Offertes worden niet gecontroleerd.
- Verkoopinstelling **Orderkenmerken controleren** (standaard Ja, door de installatie gezet) schakelt de controle tijdelijk uit, bv. bij de opstart of in een testomgeving.
- Nog niet aangesloten: de productieorder (latere fase). Daar kan `PTE Order Check Mgt.`.`CheckDocument` hergebruikt worden. De werkbon vraagt een vrijgegeven order, dus de controle is dan al gebeurd.
- De boodschap voor een ontbrekende verplichte optiegroep luidt "Optiegroep X vereist minstens N keuzes, maar er zijn er M gekozen".

## Sprint 6 - Documentstroom: omzetten, kopieren, boeken en archiveren (KRM-060 t/m 063)

De orderkenmerken, de optielinks en de toeslagregel gaan mee met het document. Dit gebeurt in `PTE Doc. Flow Mgt.`.

### Wat gaat waar mee
- **Offerte naar order (KRM-060)**: de kenmerken, de optieregels (met Gekoppeld aan regelnr., optiegroep, aantal per hoofdproduct) en de toeslagregel komen mee. De regelnummers blijven gelijk.
- **Raamorder naar order (KRM-060)**: idem, voor de regels die omgezet worden (te verzenden is niet 0).
- **Document kopieren (KRM-061)**: Kopieer document vanuit offerte, order, raamorder, factuur, creditnota, retourorder, geboekte levering, geboekte factuur, geboekte retourontvangst, geboekte creditnota en archief. De regels krijgen nieuwe regelnummers; de optieregels worden opnieuw aan de juiste hoofdregel gekoppeld. Een optieregel waarvan de hoofdregel niet gekopieerd wordt, wordt een gewone regel. Dit werkt met en zonder Regels herberekenen: de standaardopties worden dan niet nog eens toegevoegd en de kenmerken worden overgenomen.
- **Leveringsregels ophalen op een factuur en retourontvangsten ophalen op een creditnota (KRM-061)**: de nieuwe factuurregels krijgen de kenmerken en de optielinks van de geboekte regels waaruit ze komen.
- **Boeken (KRM-062)**: de geboekte levering-, factuur-, creditnota- en retourontvangstregels krijgen dezelfde kenmerken en dezelfde velden (Gekoppeld aan regelnr., Optiegroep, Aantal per hoofdproduct, Volgt aantal hoofdregel, Maatwerk, Toeslagregel, Berekende toeslagprijs). Bij gedeeltelijk leveren of factureren blijven de kenmerken ook op de orderregel staan. De kenmerken van de geboekte regels kunnen niet gewijzigd worden.
- **Archiveren en herstellen (KRM-063)**: de archiefregels krijgen de kenmerken en de optievelden. Herstellen van een versie zet de kenmerken, de links en de toeslagregel terug, zonder dubbele standaardopties.
- **Factbox Regelkenmerken (KRM-015)**: nu ook op de pagina's Geboekte verkoopleverinzage, Geboekte verkoopfactuur, Geboekte verkoopcreditnota, Geboekte retourontvangst en op de archiefpagina's van order, offerte, retourorder en raamorder.

### Technische opmerking
- Zolang zo'n stroom loopt, staat het automatische gedrag op de verkoopregel uit (standaardopties toevoegen, synchroniseren van aantal, datums en korting, toeslag herberekenen, kenmerken opnieuw opbouwen bij artikel- of variantwijziging, de controle Alleen als optie verkopen). De stroom neemt de optieregels en de toeslag zelf over uit de bronregels. `PTE Doc. Flow Mgt.`.`StartFlow`, `FinishFlow` en `IsSuppressed` regelen dit.
- Eindigt een stroom met een fout (bv. een boeking die mislukt), dan loopt het automatische gedrag na 3 minuten weer vanzelf. Tot dan worden bij het ingeven van een regel geen standaardopties toegevoegd.
- De velden op de geboekte en archiefregels hebben dezelfde nummers (50100 t/m 50108) als op de verkoopregel, zodat ze met dezelfde logica gekopieerd worden.

## Sprint 7 - Afdrukken en analyse (KRM-070/071/072/080)

### Klantdocumenten (KRM-070)
- De kenmerken met **Tonen op klantdocumenten** (veld op het kenmerk, ook per orderkenmerk-instelling) worden per regel samengesteld tot een compacte tekst, bv. `Breedte: 80 cm · Lengte: 200 cm · Stof: Velvet · Kleur: Antraciet`. De volgorde is die van de regelkenmerken (artikel en variant eerst, dan de orderkenmerken op volgorde). Lege kenmerken die niet verplicht zijn, worden niet afgedrukt.
- De tekst gebruikt de vertaling van het kenmerk en van de waarde in de taal van het document (standaardvertalingen van kenmerken in BC: Artikelkenmerk vertalingen en Waarde-vertalingen). Bestaat er geen vertaling, dan staat de oorspronkelijke tekst.
- Rapportextensies voegen twee kolommen toe aan de regels van de standaardrapporten **Verkoop - Offerte**, **Orderbevestiging**, **Pakbon** (verzending), **Factuur** en **Creditnota**: `PTE_LineAttributes` (de tekst) en `PTE_LineIndent` (1 voor optie- en toeslagregels, anders 0).
- **Let op:** de standaard Word-lay-outs tonen deze kolommen nog niet. De BC-partner voegt het veld `PTE_LineAttributes` toe onder de omschrijving van de regel (en laat de regel inspringen als `PTE_LineIndent` = 1) in de Word-lay-outs die Kreamat effectief gebruikt (te bevestigen, O11).

### Werkbon (KRM-071)
- Nieuw rapport **Werkbon** (RDLC-lay-out, A4). Starten via **Werkbon** op de verkooporder, op de lijst Verkooporders (meerdere geselecteerde orders) en op de pagina Verkoopregels (geselecteerde regels; een geselecteerde optieregel kiest zijn hoofdregel).
- Alleen voor vrijgegeven orders. Bij een order met status Open volgt de foutmelding dat de order eerst vrijgegeven moet worden en wordt niets afgedrukt.
- Opties op het aanvraagvenster: **Eén werkbon per hoofdregel** (standaard Ja, elke hoofdregel op een nieuwe pagina; Nee = één werkbon voor de hele order), **Eén werkbon per stuk** (bij aantal 2 volgen 1/2 en 2/2; de aantallen van de opties worden per stuk getoond), **Filter artikelcategorie**, **Filter verzenddatum** en **Filter gevraagde leverdatum**, **Alleen nog niet afgedrukte regels** (standaard Ja: regels zonder afdruk of gewijzigd na de afdruk).
- Inhoud: kop (order, orderdatum, klant, uw referentie, gevraagde en beloofde leverdatum, verzendwijze), per hoofdregel regelnummer, artikel, omschrijving, variant en aantal, alle kenmerken met **Tonen op productiedocumenten**, een gele regel **MAATWERK - Breedte 85 cm i.p.v. 80 cm** bij maatafwijking, de optieregels met aantal, variant en hun eigen kenmerken. De productienotitie is een kenmerk met Tonen op productiedocumenten = Ja. De toeslagregel staat niet als optie op de werkbon; het kader MAATWERK vervangt ze.
- Er is geen Word-lay-out en geen barcode (FS-11 (C)). De lay-out is `src/report/layout/PTEWorkOrder.rdlc`.

### Registratie, herdruk en wijziging na afdruk (KRM-072)
- Na het afdrukken (niet bij een voorbeeldweergave) krijgt elke hoofdregel: **Werkbon afgedrukt** = Ja, **Datum werkbon** = vandaag, **Aantal keer werkbon afgedrukt** + 1 en **Werkbon gewijzigd na afdruk** = Nee. De velden staan op de pagina Verkoopregels (en verborgen op de ordersubpagina).
- Een regel die al eens afgedrukt is, wordt gemarkeerd met **HERDRUK**.
- Wijzigen van een kenmerk (waarde invullen, wijzigen, verwijderen), een optieregel (toevoegen, verwijderen, aantal), de variant, het artikel of het aantal van een afgedrukte regel zet **Werkbon gewijzigd na afdruk** = Ja op de hoofdregel. Een wijziging aan een optieregel markeert haar hoofdregel.
- Bij het opnieuw vrijgeven volgt de melding "Werkbon opnieuw afdrukken voor regel 10000, 20000."
- Een gekopieerde order begint zonder afdrukregistratie.

### Overzicht regelkenmerken (KRM-080)
- Pagina **Overzicht regelkenmerken** (zoek via Alt+Q) met alle regelkenmerken van open verkoopdocumenten en geboekte leveringen, facturen, creditnota's en retourontvangsten (het archief niet). Kolommen: Documentsoort, Documentnr., Regelnr., Klantnr., Klantnaam, Datum (documentdatum), Artikelnr., Variantcode, Kenmerk, Waarde en Bron.
- De pagina laadt bij het openen alle regels. Met **Selectie laden** (kenmerk, waarde en datum) en de actie **Laden** laad je enkel wat je nodig hebt, wat bij veel documenten sneller is. Daarna filter je op elk veld in de lijst (de lijst wordt tijdelijk in het geheugen geladen).
- Actie **Document weergeven** opent het document van de geselecteerde regel (verkoopdocument of geboekt document).
- Actie **Openen in Excel** schrijft de regels van de lijst, met de filters die je zette, naar een Excel-bestand. De standaardanalysemodus van BC is niet beschikbaar op deze pagina (tijdelijke bron); analyseer in Excel.

## Rechten
- `KRM-GEBRUIK`: lezen van instellingen en beperkingen.
- `KRM-BEHEER`: beheren van instellingen, beperkingen, staalkaart en de Excel-import. Nieuwe objecten worden hier toegevoegd.

## Tests
- Testapp `Offimac Kreamat Tests`, 136 geautomatiseerde tests slagen (laatst na Sprint 7).
- Een nieuw testbestand wordt door de testverkenner pas ontdekt na een kleine wijziging in het bestand.
- Niet automatisch getest: het inlezen van het echte Excel-bestand (Excel Buffer), de UI-gedragingen hieronder.

## Openstaande punten (eindoverzicht)

### Te doen / configuratie
- KRM-090 uitvoeren in sandbox en productie. Stof- en Kleurwaarden (en achterkant) komen via de staalkaart (KRM-022/092).
- KRM-091: configuratie per productfamilie na KRM-090.
- KRM-092: Kreamat levert de ingevulde Excel (staalkaart O1, beperkingen O2/O3); daarna importeren.
- KRM-093: Kreamat levert welke opties en accessoires bij welke familie horen, in welke optiegroep, met min/max, standaard en afhankelijkheden (O4). Kreamat vult daarvoor de bladen Optiegroepen, Toegelaten opties en Optie-afhankelijkheden van het sjabloon in; de BC-partner importeert ze (of voert ze in via de pagina's Optiegroepen, Toegelaten opties en Optie-afhankelijkheden).
- Staalkaartinstelling controleren (zie Sprint 3). Idem de Instelling maatkenmerken (Sprint 5).
- KRM-094: toeslagartikel, schijven, maximale afwijking en afronding instellen (zie Sprint 5). Een Excel-import hiervoor bestaat niet.
- KRM-100 (acceptatietest door Kreamat), KRM-101 (opleiding key users, de handleiding is klaar) en KRM-102 (livegang). EP-12 (productie, KRM-110/111/112) is een latere fase.

### Nog niet gebouwd (bewust uitgesteld)
- Beperkingen gelden niet op de standaardwaarde in de instelling (KRM-011) en niet bij Rebuild na een artikelwijziging.
- Opzoeklijst van optiewaarden toont alle niet-geblokkeerde waarden. De filtering op toegelaten waarden zit in de lookup van de verkoopregel, niet op andere plaatsen waar Option-waarden gekozen worden.
- KRM-020 moet ook in `PTE Attribute Integrity` (IsAttributeInUse / IsValueInUse) uitgebreid worden voor kenmerkbeperkingen, zodat een kenmerk of waarde in gebruik door een beperking niet verwijderd kan worden.
- Sales Line `PTE Attributes Complete`: de install (`PTE Install`) zet bestaande verkoopregels op Ja. Een upgrade-codeunit is niet nodig zolang versie 1.0.0.0 voor het eerst geïnstalleerd wordt, ook niet in productie. Een omgeving die al een eerdere test-build had, wordt best opnieuw geïnstalleerd of krijgt een nieuw versienummer. Bij elke latere versie die velden toevoegt waarvan de standaardwaarde niet gelijk is aan de leeg-waarde, hoort een upgrade-codeunit.
- Documentstroom (Sprint 6): bij Kopieer document vanuit een geboekte regel die per artikelpost gesplitst wordt (artikelvolgnummers), krijgen alle deelregels dezelfde kenmerken en wijst de optielink naar de eerste deelregel van de hoofdregel. Handmatig controleren bij artikelen met serie- of lotnummers.
- Documentstroom: de kenmerken van de geboekte en gearchiveerde regels worden bij het boeken of archiveren vastgelegd. Documenten die voor de installatie geboekt of gearchiveerd zijn, hebben geen kenmerken.
- Documentstroom: de geboekte pagina's tonen de kenmerken alleen in de factbox. De velden Gekoppeld aan regelnr. en Optiegroep staan niet als kolom op de subpagina's van de geboekte documenten.
- Documentstroom: de automatische controle van de prestaties bij een grote order (KRM-061 AC4) is niet gemeten. Test met een order van circa 100 regels.
- Opties op krediet- en retourdocumenten: de velden bestaan, maar de acties Opties toevoegen en Koppelen aan hoofdregel staan alleen op offerte, order, raamorder en factuur.
- Een optieregel krijgt bij Koppelen aan hoofdregel geen nieuw regelnummer onder de hoofdregel; bij Opties toevoegen wel.
- Controle bij het aanmaken van een productieorder (latere fase).
- Afdrukken (Sprint 7): de Word-lay-outs van de klantdocumenten moeten door de BC-partner aangepast worden om `PTE_LineAttributes` en `PTE_LineIndent` te tonen (zie Sprint 7). Welke documenten Kreamat gebruikt is nog te bevestigen (O11). Het archief en de proforma- en conceptfactuur hebben deze kolommen niet.
- Werkbon: enkel RDLC-lay-out (geen Word-lay-out die Kreamat zelf kan aanpassen, FS-11 regel 4) en geen barcode (FS-11 (C)).
- Werkbon: bij Eén werkbon per stuk met een niet-geheel aantal (bv. 2,5) wordt naar boven afgerond (3 werkbonnen) en het aantal per werkbon is het aantal gedeeld door het aantal werkbonnen.
- Werkbon: een wijziging aan een orderkenmerk via de Regelkenmerken-pagina na het heropenen markeert de regel. Wijzigingen die BC zelf doet zonder triggers (bv. het opnieuw ophalen van artikelkenmerken via Rebuild) niet.
- Overzicht regelkenmerken: geen archief en geen standaardanalysemodus (zie Sprint 7). Bij veel documenten kan het laden van alle regels traag zijn; gebruik Selectie laden.
- Maatafwijking: de toeslag wordt per hoofdregel berekend op de eenheidsprijs van de hoofdregel zoals die op dat moment op de regel staat. Verandert een prijslijst achteraf, dan wordt de toeslag pas herberekend bij een wijziging op de regel of bij het controleren (de controle meldt dan dat de toeslagregel niet actueel is).
- Maatafwijking op kredietnota's en retourorders: niet voorzien (alleen offerte, order, raamorder en factuur).
- Geblokkeerde waarden bij vrijgeven geven een fout, geen waarschuwing (FS-05.9).
- Prijs van de optieregel (AC6 KRM-033) komt uit de standaard prijslijsten: niet apart getest.
- Kenmerken die door de cascade (Kenmerkbeperkingen) leeggemaakt worden op de hoofdregel, worden niet doorgegeven aan optieregels.

### Technische opmerkingen
- De cascade-subscriber draait bij elke `Modify(true)` van een orderkenmerk (xRec is in code niet betrouwbaar).
- Hernummeren (FS-13.4): Sales Line/Header kunnen standaard niet hernoemd worden, dus geen code nodig.
- Snelle invoer (FS-04.7, Tab/Enter naar het volgende lege kenmerk) is clientgedrag en niet in AL af te dwingen. Handmatig testen.

### Handmatig te testen in de UI
- Regelkenmerken-pagina, factbox (volgt de selectie), acties op de zes subpagina's en op Verkoopregels, wezen-pagina.
- Lookup, validatie en cascade op de verkoopregel.
- Pagina's Kenmerkbeperkingen op artikel, categorie en variant, Toegelaten waarden testen, Staalkaart.
- Excel-import met het echte sjabloon (zowel bladen apart als samen, met foutieve rijen).
- Opties: Opties toevoegen (pagina en volgorde van de regels), Koppelen aan hoofdregel (keuzelijst van hoofdregels), bevestiging bij verwijderen, korting en te verzenden / te factureren wijzigen in het scherm, Toegelaten opties tonen op de artikelkaart, meldingen bij ontbrekende variant.
- Opties in combinatie met uitgebreide teksten (AC5 KRM-031) en met verkooporders in de Business Central webclient (nieuwe regel, regelnummer en standaardopties bij aanmaak).
- Maatafwijking: afwijkende maat invullen in de Regelkenmerken-pagina (toeslagregel verschijnt onder de hoofdregel), manuele prijs wijzigen en daarna de maat aanpassen (bevestiging), Maatwerk filteren op Verkoopregels, reserveren van een maatwerkregel uit voorraad (weigering).
- Vrijgeven en boeken: melding met alle fouten van de order, boeken van een niet-vrijgegeven order, offerte vrijgeven (geen blokkering), schakelaar Orderkenmerken controleren uit, volledige order vrijgeven.
- Afdrukken (Sprint 7): de werkbon (kop, regel, kenmerken, kader MAATWERK, opties, HERDRUK, nieuwe pagina per hoofdregel, 1/2 en 2/2) in de webclient en als PDF controleren, het aanvraagvenster met alle opties, starten vanaf de orderlijst met meerdere orders en vanaf Verkoopregels met een selectie, de melding bij een open order. Het overzicht regelkenmerken (laden, filteren, Document weergeven, Openen in Excel). De klantdocumenten nadat de Word-lay-outs aangepast zijn.
- Documentstroom: offerte naar order en raamorder naar order met opties en kenmerken, Kopieer document (met en zonder Regels herberekenen, ook vanuit een geboekte factuur en het archief), Leveringsregels ophalen op een factuur, order boeken (deels en volledig) en de kenmerken in de factbox van de geboekte documenten, archiveren en een versie herstellen. Controleer ook dat een mislukte boeking de volgende regel niet blokkeert (na 3 minuten of een nieuwe sessie).

## Wijzigingslogboek
- Sprint 1 t/m 3 en KRM-092 import: zie hierboven.
