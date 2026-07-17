import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Clinical Guidelines Screen - WHO and national health guidelines for CHWs
class ClinicalGuidelinesScreen extends StatefulWidget {
  const ClinicalGuidelinesScreen({super.key});

  @override
  State<ClinicalGuidelinesScreen> createState() => _ClinicalGuidelinesScreenState();
}

class _ClinicalGuidelinesScreenState extends State<ClinicalGuidelinesScreen> {
  String _selectedCategory = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<ClinicalGuideline> _guidelines = [
    // Maternal Health Guidelines
    ClinicalGuideline(
      id: '1',
      title: 'Focused Antenatal Care (FANC)',
      titleSw: 'Huduma ya Kabla ya Kujifungua (FANC)',
      titleFr: 'Soins Prénatals Focalisés (FANC)',
      category: 'maternal',
      source: 'WHO',
      lastUpdated: '2023',
      sections: [
        GuidelineSection(
          title: 'Recommended ANC Contacts',
          titleSw: 'Ziara za ANC Zinazopendekezwa',
          titleFr: 'Contacts CPN Recommandés',
          content: '''
• First contact: Before 12 weeks (first trimester)
• Second contact: 20 weeks
• Third contact: 26 weeks
• Fourth contact: 30 weeks
• Fifth contact: 34 weeks
• Sixth contact: 36 weeks
• Seventh contact: 38 weeks
• Eighth contact: 40 weeks

Key assessments at each visit:
- Blood pressure measurement
- Weight monitoring
- Fundal height measurement
- Fetal heart rate
- Urine test for protein
- Hemoglobin check (if available)
''',
          contentSw: '''
• Ziara ya kwanza: Kabla ya wiki 12 (trimester ya kwanza)
• Ziara ya pili: Wiki 20
• Ziara ya tatu: Wiki 26
• Ziara ya nne: Wiki 30
• Ziara ya tano: Wiki 34
• Ziara ya sita: Wiki 36
• Ziara ya saba: Wiki 38
• Ziara ya nane: Wiki 40

Tathmini muhimu kwa kila ziara:
- Kipimo cha shinikizo la damu
- Ufuatiliaji wa uzito
- Kipimo cha urefu wa fundasi
- Kasi ya moyo wa fetasi
- Kipimo cha mkojo kwa protini
- Kipimo cha hemoglobini (ikiwa inapatikana)
''',
        ),
        GuidelineSection(
          title: 'Danger Signs in Pregnancy',
          titleSw: 'Dalili za Hatari wakati wa Ujauzito',
          titleFr: 'Signes de Danger pendant la Grossesse',
          content: '''
REFER IMMEDIATELY if any of these signs:
• Vaginal bleeding
• Severe headache with blurred vision
• High fever
• Severe abdominal pain
• Convulsions/fits
• Difficulty breathing
• Swelling of face, hands, or feet
• Reduced or absent fetal movement
• Water breaking before labor
• Baby not moving for 12+ hours
''',
        ),
        GuidelineSection(
          title: 'Iron and Folic Acid Supplementation',
          titleSw: 'Nyongeza ya Chuma na Folic Acid',
          titleFr: 'Supplémentation en Fer et Acide Folique',
          content: '''
Daily supplementation throughout pregnancy:
• Iron: 30-60 mg elemental iron
• Folic Acid: 400 mcg (0.4 mg)

For anemic women (Hb < 11 g/dL):
• Iron: 120 mg elemental iron daily
• Duration: 3 months of treatment

Counseling points:
- Take with food to reduce nausea
- Avoid taking with tea or coffee (reduces absorption)
- Black stools are normal side effect
- Continue for 3 months postpartum
''',
        ),
      ],
    ),
    ClinicalGuideline(
      id: '2',
      title: 'Integrated Management of Childhood Illness (IMCI)',
      titleSw: 'Usimamizi wa Pamoja wa Magonjwa ya Watoto (IMCI)',
      titleFr: 'Prise en Charge Intégrée des Maladies de l\'Enfant (PCIME)',
      category: 'child',
      source: 'WHO/UNICEF',
      lastUpdated: '2023',
      sections: [
        GuidelineSection(
          title: 'General Danger Signs (2 months to 5 years)',
          titleSw: 'Dalili za Hatari za Jumla (miezi 2 hadi miaka 5)',
          titleFr: 'Signes Généraux de Danger (2 mois à 5 ans)',
          content: '''
REFER URGENTLY if child has ANY of these:
• Unable to drink or breastfeed
• Vomits everything
• Convulsions (now or in this illness)
• Lethargic or unconscious

How to check:
1. Ask: Is the child able to drink?
2. Offer breast/fluids: Does child refuse or vomit?
3. Observe: Is child abnormally sleepy or difficult to wake?
4. Ask: Has child had convulsions during illness?
''',
        ),
        GuidelineSection(
          title: 'Assessment of Cough or Difficult Breathing',
          titleSw: 'Tathmini ya Kikohozi au Ugumu wa Kupumua',
          titleFr: 'Évaluation de la Toux ou Difficultés Respiratoires',
          content: '''
Count respiratory rate for 1 full minute:
• Fast breathing:
  - Child 2-12 months: 50+ breaths/min
  - Child 12 months-5 years: 40+ breaths/min

Check for chest indrawing:
• Lower chest wall moves IN when child breathes IN
• Must be severe and visible at rest

Classify and treat:
• SEVERE PNEUMONIA: Chest indrawing or danger sign → REFER
• PNEUMONIA: Fast breathing only → Give amoxicillin, follow up in 2 days
• NO PNEUMONIA: Cough or cold → Home care, follow up in 5 days if not improving
''',
        ),
        GuidelineSection(
          title: 'Assessment of Diarrhea',
          titleSw: 'Tathmini ya Kuhara',
          titleFr: 'Évaluation de la Diarrhée',
          content: '''
Assess for dehydration:
SEVERE DEHYDRATION (2+ of these signs):
• Lethargic or unconscious
• Sunken eyes
• Unable to drink or drinks poorly
• Skin pinch goes back very slowly (>2 seconds)
→ Start IV/NG fluids and REFER

SOME DEHYDRATION (2+ of these signs):
• Restless, irritable
• Sunken eyes
• Drinks eagerly, thirsty
• Skin pinch goes back slowly (1-2 seconds)
→ Give ORS in clinic for 4 hours (Plan B)

NO DEHYDRATION:
→ Give ORS to take home, continue feeding (Plan A)

ALWAYS give zinc supplementation:
• Under 6 months: 10mg daily for 10-14 days
• 6 months and older: 20mg daily for 10-14 days
''',
        ),
        GuidelineSection(
          title: 'Assessment of Fever/Malaria',
          titleSw: 'Tathmini ya Homa/Malaria',
          titleFr: 'Évaluation de la Fièvre/Paludisme',
          content: '''
In malaria endemic areas:
1. Take temperature and/or feel for fever
2. Do malaria RDT for all children with fever

If RDT POSITIVE:
• Check for danger signs
• SEVERE MALARIA (any danger sign) → Give rectal artesunate and REFER
• UNCOMPLICATED MALARIA → Give ACT (Artemether-Lumefantrine)
  - Day 1: First dose now, second dose after 8 hours
  - Days 2-3: Two doses per day (morning and evening)

If RDT NEGATIVE:
• Look for other causes of fever
• Do NOT give antimalarials
• Give paracetamol for fever
• Follow up in 2 days if fever persists
''',
        ),
      ],
    ),
    ClinicalGuideline(
      id: '3',
      title: 'Infant and Young Child Feeding (IYCF)',
      titleSw: 'Ulishaji wa Watoto Wachanga na Wadogo (IYCF)',
      titleFr: 'Alimentation du Nourrisson et du Jeune Enfant (ANJE)',
      category: 'nutrition',
      source: 'WHO',
      lastUpdated: '2023',
      sections: [
        GuidelineSection(
          title: 'Breastfeeding Recommendations',
          titleSw: 'Mapendekezo ya Kunyonyesha',
          titleFr: 'Recommandations pour l\'Allaitement',
          content: '''
Key Messages:

1. EARLY INITIATION
• Start breastfeeding within 1 hour of birth
• Skin-to-skin contact immediately after birth
• No prelacteal feeds (water, honey, formula)

2. EXCLUSIVE BREASTFEEDING
• Only breastmilk for first 6 months
• No water, other liquids, or foods needed
• Breastfeed on demand (8-12 times per day)
• Both day and night feeding

3. CONTINUED BREASTFEEDING
• Continue breastfeeding for 2 years or beyond
• Breastfeed before giving complementary foods
• Breastmilk remains important source of nutrients

Counseling for common concerns:
• "Not enough milk" - Breastfeed more often, ensure good attachment
• Sore nipples - Check positioning and attachment
• Breast engorgement - More frequent feeding, express milk
''',
        ),
        GuidelineSection(
          title: 'Complementary Feeding (6-24 months)',
          titleSw: 'Ulishaji wa Ziada (miezi 6-24)',
          titleFr: 'Alimentation Complémentaire (6-24 mois)',
          content: '''
Starting at 6 months:

FREQUENCY:
• 6-8 months: 2-3 meals + 1-2 snacks
• 9-11 months: 3-4 meals + 1-2 snacks
• 12-24 months: 3-4 meals + 1-2 snacks

AMOUNT:
• 6-8 months: Start with 2-3 tablespoons, increase to ½ cup (125 ml)
• 9-11 months: ½ cup (125 ml) per meal
• 12-24 months: ¾ to 1 cup (175-250 ml) per meal

TEXTURE:
• 6-8 months: Pureed, mashed, semi-solid
• 9-11 months: Finely chopped, finger foods
• 12-24 months: Family foods, chopped if needed

VARIETY (4+ food groups daily):
1. Grains/roots/tubers
2. Legumes and nuts
3. Dairy products
4. Flesh foods (meat, fish, poultry)
5. Eggs
6. Vitamin A rich fruits/vegetables
7. Other fruits and vegetables
''',
        ),
        GuidelineSection(
          title: 'Identification of Malnutrition',
          titleSw: 'Utambuzi wa Utapiamlo',
          titleFr: 'Identification de la Malnutrition',
          content: '''
MUAC Screening (6-59 months):
• GREEN (≥12.5 cm): Normal - continue monitoring
• YELLOW (11.5-12.4 cm): Moderate malnutrition - nutrition counseling, follow up
• RED (<11.5 cm): Severe malnutrition - REFER urgently

Additional danger signs in SAM:
• Bilateral pitting edema (press both feet for 3 seconds)
• Visible severe wasting
• Medical complications (dehydration, fever, infection)

If MUAC RED or edema present:
1. Give first dose of amoxicillin
2. If no complications, start RUTF if available
3. REFER to health facility same day
4. Counsel on continuing breastfeeding
''',
        ),
      ],
    ),
    ClinicalGuideline(
      id: '4',
      title: 'HIV Testing and Counseling',
      titleSw: 'Upimaji na Ushauri wa VVU',
      titleFr: 'Dépistage et Conseil VIH',
      category: 'hiv',
      source: 'WHO/UNAIDS',
      lastUpdated: '2023',
      sections: [
        GuidelineSection(
          title: 'The 5 Cs of HIV Testing',
          titleSw: 'C 5 za Upimaji wa VVU',
          titleFr: 'Les 5 C du Dépistage VIH',
          content: '''
All HIV testing must follow the 5 Cs:

1. CONSENT
• Testing must be voluntary
• Client must agree to be tested
• No one should be forced or coerced

2. CONFIDENTIALITY
• Results kept private
• Only shared with permission
• Records stored securely

3. COUNSELING
• Pre-test information
• Post-test support
• Linkage to care if positive

4. CORRECT RESULTS
• Use quality-assured tests
• Follow national algorithm
• Retest if needed

5. CONNECTION TO SERVICES
• Link to treatment if positive
• Prevention services if negative
• Follow-up support for all
''',
        ),
        GuidelineSection(
          title: 'Prevention of Mother-to-Child Transmission (PMTCT)',
          titleSw: 'Kuzuia Maambukizi kutoka kwa Mama hadi Mtoto (PMTCT)',
          titleFr: 'Prévention de la Transmission Mère-Enfant (PTME)',
          content: '''
Key interventions:

FOR THE MOTHER:
• Test all pregnant women for HIV
• If positive, start ART immediately (same day)
• Continue ART for life
• Viral load monitoring

FOR THE BABY:
• Give ARV prophylaxis to all HIV-exposed infants
  - Nevirapine (NVP) for 6 weeks if mother on ART
  - Extended prophylaxis if mother not on ART or high risk

INFANT TESTING:
• First DNA PCR test at 4-6 weeks
• If negative, repeat at 9 months
• Final antibody test at 18 months
• Test any time if symptomatic

INFANT FEEDING:
• Exclusive breastfeeding for 6 months (with ART)
• Continue breastfeeding with complementary foods to 12-24 months
• Mother must remain on ART throughout breastfeeding
''',
        ),
      ],
    ),
    ClinicalGuideline(
      id: '5',
      title: 'Tuberculosis (TB) Screening and Referral',
      titleSw: 'Uchunguzi na Rufaa ya Kifua Kikuu (TB)',
      titleFr: 'Dépistage et Référence de la Tuberculose (TB)',
      category: 'infectious',
      source: 'WHO',
      lastUpdated: '2023',
      sections: [
        GuidelineSection(
          title: 'TB Symptom Screening',
          titleSw: 'Uchunguzi wa Dalili za TB',
          titleFr: 'Dépistage des Symptômes de TB',
          content: '''
Ask about these symptoms:

FOR ADULTS:
• Cough for 2+ weeks
• Night sweats
• Fever
• Weight loss or failure to gain weight

FOR CHILDREN:
• Cough for 2+ weeks
• Fever for 2+ weeks
• Weight loss or poor weight gain
• Fatigue or reduced playfulness
• Contact with TB case

ANY positive symptom = Presumptive TB → REFER for testing

High-risk groups to prioritize:
• People living with HIV
• Household contacts of TB cases
• Diabetics
• Malnourished individuals
• Smokers
• Healthcare workers
''',
        ),
        GuidelineSection(
          title: 'TB Prevention - Contact Tracing',
          titleSw: 'Kuzuia TB - Ufuatiliaji wa Mawasiliano',
          titleFr: 'Prévention TB - Recherche des Contacts',
          content: '''
When a TB case is identified:

1. LIST ALL HOUSEHOLD CONTACTS
• Everyone living in the same house
• Anyone spending significant time with patient

2. SCREEN ALL CONTACTS
• Ask about TB symptoms
• Children under 5: refer for preventive therapy regardless of symptoms
• People with HIV: refer for preventive therapy

3. FOLLOW UP
• Check that contacts complete screening
• Monitor for symptoms for 2 years
• Report any new cases

TB Preventive Treatment (TPT):
• Isoniazid daily for 6 months, OR
• Isoniazid + Rifapentine weekly for 12 weeks

Eligible for TPT:
• Child contacts under 5
• People with HIV
• Adult contacts without active TB
''',
        ),
        GuidelineSection(
          title: 'Supporting TB Treatment Adherence',
          titleSw: 'Kusaidia Ufuasi wa Matibabu ya TB',
          titleFr: 'Soutien à l\'Observance du Traitement TB',
          content: '''
Standard TB treatment is 6 months:
• First 2 months: Intensive phase (4 drugs)
• Next 4 months: Continuation phase (2 drugs)

CHW role in DOT (Directly Observed Therapy):
• Watch patient swallow medications daily
• Record doses taken
• Monitor for side effects
• Provide emotional support
• Report problems to health facility

Common side effects to watch for:
• Orange/red urine (normal - reassure)
• Nausea, vomiting
• Skin rash or itching
• Numbness in hands/feet
• Yellow eyes (REFER immediately)
• Hearing problems (REFER immediately)

Keys to success:
• Never miss a dose
• Continue even when feeling better
• Complete full 6 months
''',
        ),
      ],
    ),
    ClinicalGuideline(
      id: '6',
      title: 'Family Planning Counseling',
      titleSw: 'Ushauri wa Uzazi wa Mpango',
      titleFr: 'Conseil en Planification Familiale',
      category: 'reproductive',
      source: 'WHO',
      lastUpdated: '2023',
      sections: [
        GuidelineSection(
          title: 'Contraceptive Methods Overview',
          titleSw: 'Muhtasari wa Njia za Uzazi wa Mpango',
          titleFr: 'Aperçu des Méthodes Contraceptives',
          content: '''
SHORT-ACTING METHODS:
• Combined oral pills - Take daily
• Progestin-only pills - Take daily (safe for breastfeeding)
• Injectable (Depo-Provera) - Every 3 months
• Condoms - Each act of intercourse

LONG-ACTING REVERSIBLE (LARC):
• Implant (Jadelle/Implanon) - 3-5 years
• IUD (Copper or hormonal) - 5-10 years

PERMANENT:
• Tubal ligation (female)
• Vasectomy (male)

FERTILITY AWARENESS:
• Standard Days Method
• Lactational Amenorrhea Method (LAM)
  - Exclusive breastfeeding
  - Baby under 6 months
  - No menstruation yet
''',
        ),
        GuidelineSection(
          title: 'Counseling Approach (GATHER)',
          titleSw: 'Mbinu ya Ushauri (GATHER)',
          titleFr: 'Approche de Conseil (GATHER)',
          content: '''
G - GREET
• Welcome warmly and establish rapport
• Ensure privacy

A - ASK
• Reproductive goals and preferences
• Breastfeeding status
• Medical history
• Previous contraceptive use

T - TELL
• Explain available methods
• How each works
• Effectiveness rates
• Side effects

H - HELP
• Help choose method that fits their needs
• Consider partner involvement
• Address concerns

E - EXPLAIN
• How to use the method correctly
• When to return for follow-up
• Warning signs to watch for

R - RETURN
• Schedule follow-up visit
• Ensure they know where to go for resupply
• Remind they can switch methods anytime
''',
        ),
        GuidelineSection(
          title: 'Postpartum Family Planning',
          titleSw: 'Uzazi wa Mpango Baada ya Kujifungua',
          titleFr: 'Planification Familiale Post-Partum',
          content: '''
Timing recommendations:

IMMEDIATELY POSTPARTUM (within 48 hours):
• IUD insertion
• Implant insertion
• Tubal ligation (if planned)

BREASTFEEDING MOTHERS:
• LAM effective for 6 months if criteria met
• Progestin-only methods safe from 6 weeks
• Combined hormonal methods from 6 months

NON-BREASTFEEDING:
• Can start any method after 3 weeks
• Fertility returns by 4-6 weeks postpartum

KEY MESSAGE:
• Discuss FP during pregnancy
• Offer immediately after delivery
• Follow up at 6-week visit
• Healthy birth spacing: 2+ years between births
''',
        ),
      ],
    ),
    ClinicalGuideline(
      id: '7',
      title: 'Hypertension Management',
      titleSw: 'Usimamizi wa Shinikizo la Damu',
      titleFr: 'Gestion de l\'Hypertension',
      category: 'ncd',
      source: 'WHO HEARTS',
      lastUpdated: '2023',
      sections: [
        GuidelineSection(
          title: 'Blood Pressure Classification',
          titleSw: 'Uainishaji wa Shinikizo la Damu',
          titleFr: 'Classification de la Pression Artérielle',
          content: '''
Blood pressure readings (mmHg):

NORMAL:
• Systolic: <120 AND Diastolic: <80

ELEVATED:
• Systolic: 120-129 AND Diastolic: <80

HIGH BLOOD PRESSURE:
• Stage 1: Systolic 130-139 OR Diastolic 80-89
• Stage 2: Systolic ≥140 OR Diastolic ≥90

HYPERTENSIVE CRISIS:
• Systolic >180 AND/OR Diastolic >120
• REFER IMMEDIATELY

Proper measurement technique:
1. Patient seated quietly for 5 minutes
2. Back supported, feet flat on floor
3. Arm supported at heart level
4. Correct cuff size
5. Take 2 readings, 1 minute apart
6. Record average
''',
        ),
        GuidelineSection(
          title: 'Lifestyle Modifications',
          titleSw: 'Mabadiliko ya Mtindo wa Maisha',
          titleFr: 'Modifications du Mode de Vie',
          content: '''
Non-drug interventions for all patients:

1. DIETARY CHANGES (DASH diet)
• Reduce salt intake (<5g/day = 1 teaspoon)
• Eat more fruits and vegetables
• Reduce saturated fats
• Choose whole grains
• Limit processed foods

2. PHYSICAL ACTIVITY
• At least 30 minutes, 5 days per week
• Brisk walking, cycling, swimming
• Start slowly, increase gradually

3. WEIGHT MANAGEMENT
• Aim for healthy BMI (18.5-24.9)
• Every 5kg lost reduces BP by 4-5 mmHg

4. LIMIT ALCOHOL
• Men: ≤2 drinks per day
• Women: ≤1 drink per day

5. STOP TOBACCO
• Smoking raises BP temporarily
• Increases cardiovascular risk significantly
• Offer cessation support

6. STRESS MANAGEMENT
• Relaxation techniques
• Adequate sleep
• Social support
''',
        ),
        GuidelineSection(
          title: 'Medication Adherence Support',
          titleSw: 'Msaada wa Ufuasi wa Dawa',
          titleFr: 'Soutien à l\'Observance Médicamenteuse',
          content: '''
CHW role in medication support:

COUNSELING POINTS:
• Take medication every day, even if feeling well
• Do not stop without consulting health provider
• BP control requires lifelong treatment
• Missing doses increases risk of complications

ADHERENCE STRATEGIES:
• Link medication to daily routine
• Use pill boxes or reminders
• Keep medications visible
• Refill before running out

MONITORING:
• Check BP at each home visit
• Ask about side effects
• Count remaining pills
• Track medication refills

SIDE EFFECTS TO WATCH:
• Dizziness (especially standing up)
• Cough (with some medications)
• Swelling of ankles
• Fatigue

REFERRAL TRIGGERS:
• BP not controlled despite taking medications
• Severe headache with high BP
• Chest pain
• Vision changes
• Medication side effects
''',
        ),
      ],
    ),
    ClinicalGuideline(
      id: '8',
      title: 'Diabetes Care and Monitoring',
      titleSw: 'Huduma na Ufuatiliaji wa Kisukari',
      titleFr: 'Soins et Surveillance du Diabète',
      category: 'ncd',
      source: 'WHO',
      lastUpdated: '2023',
      sections: [
        GuidelineSection(
          title: 'Recognizing Diabetes Symptoms',
          titleSw: 'Kutambua Dalili za Kisukari',
          titleFr: 'Reconnaître les Symptômes du Diabète',
          content: '''
Common symptoms (remember "4 Ps"):
1. POLYURIA - Frequent urination
2. POLYDIPSIA - Increased thirst
3. POLYPHAGIA - Increased hunger
4. Unexplained weight loss

Other warning signs:
• Fatigue and weakness
• Blurred vision
• Slow healing wounds
• Frequent infections
• Numbness in hands/feet

High-risk individuals to screen:
• Age 40+ years
• Overweight/obese
• Family history of diabetes
• Previous gestational diabetes
• Hypertension
• History of high blood sugar

Blood glucose targets:
• Fasting: 70-130 mg/dL (4-7 mmol/L)
• 2 hours after meals: <180 mg/dL (<10 mmol/L)
• HbA1c: <7% (for most adults)
''',
        ),
        GuidelineSection(
          title: 'Foot Care Education',
          titleSw: 'Elimu ya Huduma ya Miguu',
          titleFr: 'Éducation aux Soins des Pieds',
          content: '''
Teach patients daily foot care routine:

INSPECT FEET DAILY:
• Look for cuts, blisters, redness, swelling
• Check between toes
• Use mirror for bottom of feet
• Ask family member to help if needed

WASH FEET PROPERLY:
• Wash daily with lukewarm water
• Test water temperature with elbow first
• Dry thoroughly, especially between toes
• Do not soak feet

PROTECT FEET:
• Always wear shoes or slippers
• Check inside shoes before wearing
• Wear cotton socks
• Avoid walking barefoot

NAIL CARE:
• Cut nails straight across
• Do not cut too short
• File rough edges gently
• See health worker if nails are thick

DANGER SIGNS - REFER IMMEDIATELY:
• Open sores or wounds that won't heal
• Signs of infection (redness, warmth, pus)
• Color changes (blue, black, pale)
• New numbness or tingling
• Swelling that doesn't go down
''',
        ),
        GuidelineSection(
          title: 'Hypoglycemia Recognition',
          titleSw: 'Kutambua Sukari ya Chini',
          titleFr: 'Reconnaissance de l\'Hypoglycémie',
          content: '''
LOW BLOOD SUGAR is an emergency!

Signs of hypoglycemia:
• Shakiness, trembling
• Sweating
• Dizziness
• Hunger
• Confusion
• Fast heartbeat
• Headache
• Blurred vision

IMMEDIATE ACTION (Rule of 15):
1. Give 15 grams of fast sugar:
   - 3-4 glucose tablets, OR
   - ½ cup fruit juice, OR
   - 1 tablespoon sugar or honey, OR
   - 3-4 pieces of hard candy

2. Wait 15 minutes

3. Recheck blood sugar if possible

4. Repeat if still symptomatic

IF UNCONSCIOUS:
• Do NOT give anything by mouth
• Turn on side
• REFER IMMEDIATELY

PREVENTION:
• Never skip meals
• Take medications as prescribed
• Carry fast-acting sugar always
• Wear medical ID
''',
        ),
      ],
    ),
  ];

  List<ClinicalGuideline> get _filteredGuidelines {
    return _guidelines.where((g) {
      final matchesCategory = _selectedCategory == 'all' || g.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          g.title.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(l10n),
            Expanded(
              child: Column(
                children: [
                  _buildSearchAndFilter(l10n),
                  Expanded(
                    child: _filteredGuidelines.isEmpty
                        ? _buildEmptyState(l10n)
                        : ListView.builder(
                            physics: const ClampingScrollPhysics(),
                            padding: EdgeInsets.all(AppTheme.spacingMd),
                            itemCount: _filteredGuidelines.length,
                            itemBuilder: (context, index) {
                              return _buildGuidelineCard(
                                _filteredGuidelines[index],
                                l10n,
                                lang,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green.shade600, Colors.green.shade800],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white, size: 18),
            ),
          ),
          SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.translate('clinicalGuidelines') ?? 'Clinical Guidelines',
                  style: AppTheme.headingMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.translate('whoRecommendations') ?? 'WHO & National Health Recommendations',
                  style: AppTheme.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const FaIcon(FontAwesomeIcons.bookMedical, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(AppLocalizations l10n) {
    final categories = [
      {'id': 'all', 'label': l10n.translate('all') ?? 'All', 'icon': FontAwesomeIcons.list},
      {'id': 'maternal', 'label': l10n.translate('maternal') ?? 'Maternal', 'icon': FontAwesomeIcons.personBreastfeeding},
      {'id': 'child', 'label': l10n.translate('child') ?? 'Child', 'icon': FontAwesomeIcons.baby},
      {'id': 'nutrition', 'label': l10n.translate('nutrition') ?? 'Nutrition', 'icon': FontAwesomeIcons.appleWhole},
      {'id': 'hiv', 'label': 'HIV', 'icon': FontAwesomeIcons.ribbon},
      {'id': 'infectious', 'label': l10n.translate('infectious') ?? 'Infectious', 'icon': FontAwesomeIcons.virus},
      {'id': 'reproductive', 'label': l10n.translate('reproductive') ?? 'FP', 'icon': FontAwesomeIcons.heart},
      {'id': 'ncd', 'label': l10n.translate('ncd') ?? 'NCD', 'icon': FontAwesomeIcons.heartPulse},
    ];

    return Padding(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: l10n.translate('searchGuidelines') ?? 'Search guidelines...',
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingSm),
              ),
            ),
          ),
          SizedBox(height: AppTheme.spacingSm),
          // Category filter
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = _selectedCategory == cat['id'];
                return Padding(
                  padding: EdgeInsets.only(right: AppTheme.spacingXs),
                  child: FilterChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(cat['icon'] as IconData, size: 12, 
                          color: isSelected ? Colors.white : AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(cat['label'] as String, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    onSelected: (selected) {
                      setState(() => _selectedCategory = cat['id'] as String);
                    },
                    selectedColor: Colors.green.shade600,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelineCard(ClinicalGuideline guideline, AppLocalizations l10n, String lang) {
    String getLocalizedTitle() {
      switch (lang) {
        case 'sw':
          return guideline.titleSw ?? guideline.title;
        case 'fr':
          return guideline.titleFr ?? guideline.title;
        default:
          return guideline.title;
      }
    }

    return Card(
      margin: EdgeInsets.only(bottom: AppTheme.spacingSm),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => _showGuidelineDetails(guideline, l10n, lang),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: FaIcon(
                    _getCategoryIcon(guideline.category),
                    color: Colors.green.shade600,
                    size: 22,
                  ),
                ),
              ),
              SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getLocalizedTitle(),
                      style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            guideline.source,
                            style: TextStyle(fontSize: 10, color: Colors.blue.shade700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${guideline.sections.length} ${l10n.translate('sections') ?? 'sections'}',
                          style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              FaIcon(FontAwesomeIcons.chevronRight, color: AppColors.textSecondary, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'maternal':
        return FontAwesomeIcons.personBreastfeeding;
      case 'child':
        return FontAwesomeIcons.baby;
      case 'nutrition':
        return FontAwesomeIcons.appleWhole;
      case 'hiv':
        return FontAwesomeIcons.ribbon;
      case 'infectious':
        return FontAwesomeIcons.virus;
      case 'reproductive':
        return FontAwesomeIcons.heart;
      case 'ncd':
        return FontAwesomeIcons.heartPulse;
      default:
        return FontAwesomeIcons.bookMedical;
    }
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(FontAwesomeIcons.magnifyingGlass, size: 48, color: AppColors.textSecondary),
          SizedBox(height: AppTheme.spacingMd),
          Text(
            l10n.translate('noGuidelinesFound') ?? 'No guidelines found',
            style: AppTheme.bodyLarge.copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(height: AppTheme.spacingSm),
          Text(
            l10n.translate('tryDifferentSearch') ?? 'Try a different search term',
            style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showGuidelineDetails(ClinicalGuideline guideline, AppLocalizations l10n, String lang) {
    String getLocalizedTitle() {
      switch (lang) {
        case 'sw':
          return guideline.titleSw ?? guideline.title;
        case 'fr':
          return guideline.titleFr ?? guideline.title;
        default:
          return guideline.title;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuidelineDetailScreen(
          guideline: guideline,
          localizedTitle: getLocalizedTitle(),
          lang: lang,
        ),
      ),
    );
  }
}

/// Detail screen for individual guideline
class GuidelineDetailScreen extends StatelessWidget {
  final ClinicalGuideline guideline;
  final String localizedTitle;
  final String lang;

  const GuidelineDetailScreen({
    super.key,
    required this.guideline,
    required this.localizedTitle,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        title: Text(localizedTitle, style: AppTheme.headingSmall.copyWith(color: Colors.white)),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.bookmark, size: 18),
            onPressed: () => _bookmarkGuideline(context),
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.share, size: 18),
            onPressed: () => _shareGuideline(context),
          ),
        ],
      ),
      body: ListView(
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.all(AppTheme.spacingMd),
        children: [
          // Source info
          Container(
            padding: EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FaIcon(FontAwesomeIcons.buildingColumns, color: Colors.green.shade600, size: 20),
                ),
                SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.translate('source') ?? 'Source'}: ${guideline.source}',
                        style: AppTheme.labelMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${l10n.translate('lastUpdated') ?? 'Last Updated'}: ${guideline.lastUpdated}',
                        style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppTheme.spacingMd),

          // Sections
          ...guideline.sections.map((section) => _buildSectionCard(section, context)),
          SizedBox(height: AppTheme.spacingLg),
        ],
      ),
    );
  }

  Widget _buildSectionCard(GuidelineSection section, BuildContext context) {
    String getLocalizedTitle() {
      switch (lang) {
        case 'sw':
          return section.titleSw ?? section.title;
        case 'fr':
          return section.titleFr ?? section.title;
        default:
          return section.title;
      }
    }

    String getLocalizedContent() {
      switch (lang) {
        case 'sw':
          return section.contentSw ?? section.content;
        case 'fr':
          return section.contentFr ?? section.content;
        default:
          return section.content;
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          getLocalizedTitle(),
          style: AppTheme.labelMedium.copyWith(fontWeight: FontWeight.w600, color: Colors.green.shade700),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FaIcon(FontAwesomeIcons.fileLines, color: Colors.green.shade600, size: 16),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(AppTheme.spacingMd),
            child: SelectableText(
              getLocalizedContent(),
              style: AppTheme.bodyMedium.copyWith(height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  void _bookmarkGuideline(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Guideline bookmarked!')),
    );
  }

  void _shareGuideline(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing guideline...')),
    );
  }
}

/// Model for clinical guidelines
class ClinicalGuideline {
  final String id;
  final String title;
  final String? titleSw;
  final String? titleFr;
  final String category;
  final String source;
  final String lastUpdated;
  final List<GuidelineSection> sections;

  ClinicalGuideline({
    required this.id,
    required this.title,
    this.titleSw,
    this.titleFr,
    required this.category,
    required this.source,
    required this.lastUpdated,
    required this.sections,
  });
}

/// Model for guideline sections
class GuidelineSection {
  final String title;
  final String? titleSw;
  final String? titleFr;
  final String content;
  final String? contentSw;
  final String? contentFr;

  GuidelineSection({
    required this.title,
    this.titleSw,
    this.titleFr,
    required this.content,
    this.contentSw,
    this.contentFr,
  });
}
