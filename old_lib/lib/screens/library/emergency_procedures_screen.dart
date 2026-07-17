import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Emergency Procedures Screen - provides critical emergency protocols for CHWs
class EmergencyProceduresScreen extends StatefulWidget {
  const EmergencyProceduresScreen({super.key});

  @override
  State<EmergencyProceduresScreen> createState() => _EmergencyProceduresScreenState();
}

class _EmergencyProceduresScreenState extends State<EmergencyProceduresScreen> {
  String _selectedCategory = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<EmergencyProcedure> _procedures = [
    EmergencyProcedure(
      id: '1',
      title: 'Choking in Adults',
      titleSw: 'Kuziba Koo kwa Watu Wazima',
      titleFr: 'Étouffement chez l\'Adulte',
      category: 'airway',
      priority: 'critical',
      steps: [
        'Ask "Are you choking?" - if person can speak, encourage coughing',
        'If cannot speak or breathe, stand behind the person',
        'Place your fist just above the navel',
        'Grasp your fist with other hand',
        'Give 5 quick upward abdominal thrusts',
        'Repeat until object is expelled or person becomes unconscious',
        'If unconscious, call for help and begin CPR',
      ],
      stepsSw: [
        'Uliza "Je, unaziba koo?" - ikiwa mtu anaweza kuongea, mhimize kukohoa',
        'Ikiwa hawezi kuongea au kupumua, simama nyuma ya mtu',
        'Weka ngumi yako juu kidogo ya kitovu',
        'Shika ngumi yako kwa mkono mwingine',
        'Toa misukumo 5 ya haraka ya juu kwenye tumbo',
        'Rudia hadi kitu kitoke au mtu apoteze fahamu',
        'Ikiwa amepoteza fahamu, piga simu kwa msaada na anza CPR',
      ],
      stepsFr: [
        'Demandez "Vous étouffez-vous?" - si la personne peut parler, encouragez la toux',
        'Si elle ne peut ni parler ni respirer, placez-vous derrière elle',
        'Placez votre poing juste au-dessus du nombril',
        'Saisissez votre poing avec l\'autre main',
        'Effectuez 5 poussées abdominales rapides vers le haut',
        'Répétez jusqu\'à ce que l\'objet soit expulsé ou que la personne perde connaissance',
        'En cas d\'inconscience, appelez à l\'aide et commencez la RCP',
      ],
      warnings: [
        'Do NOT perform abdominal thrusts on pregnant women or obese patients - use chest thrusts instead',
        'For infants, use back blows and chest thrusts, NOT abdominal thrusts',
      ],
      referralIndicators: [
        'Object not expelled after multiple attempts',
        'Person becomes unconscious',
        'Breathing difficulty persists after object removal',
      ],
    ),
    EmergencyProcedure(
      id: '2',
      title: 'Severe Bleeding Control',
      titleSw: 'Kudhibiti Kutoka Damu Kwa Wingi',
      titleFr: 'Contrôle des Hémorragies Sévères',
      category: 'bleeding',
      priority: 'critical',
      steps: [
        'Wear gloves if available to protect yourself',
        'Apply direct pressure to the wound using clean cloth or gauze',
        'Maintain firm, continuous pressure for at least 10 minutes',
        'If blood soaks through, add more material on top without removing first layer',
        'Elevate the injured limb above heart level if possible',
        'If bleeding is from arm or leg and won\'t stop, apply tourniquet 2-3 inches above wound',
        'Note the time tourniquet was applied',
        'Arrange IMMEDIATE transport to health facility',
      ],
      stepsSw: [
        'Vaa glavu ikiwa zinapatikana kujilinda',
        'Weka shinikizo moja kwa moja kwenye jeraha kwa kutumia kitambaa safi au gauze',
        'Endelea na shinikizo kwa dakika 10 au zaidi',
        'Ikiwa damu inapenya, ongeza nyenzo zaidi juu bila kuondoa safu ya kwanza',
        'Inua mguu au mkono ulioumia juu ya kiwango cha moyo ikiwezekana',
        'Ikiwa damu inatoka mkononi au mguuni na haisimami, funga tourniquet inchi 2-3 juu ya jeraha',
        'Andika muda tourniquet ilifungwa',
        'Panga usafiri wa HARAKA kwenda hospitalini',
      ],
      stepsFr: [
        'Portez des gants si disponibles pour vous protéger',
        'Appliquez une pression directe sur la plaie avec un tissu propre ou de la gaze',
        'Maintenez une pression ferme et continue pendant au moins 10 minutes',
        'Si le sang traverse, ajoutez du matériel supplémentaire sans retirer la première couche',
        'Élevez le membre blessé au-dessus du niveau du cœur si possible',
        'Si le saignement provient du bras ou de la jambe et ne s\'arrête pas, appliquez un garrot 5-7 cm au-dessus de la plaie',
        'Notez l\'heure d\'application du garrot',
        'Organisez un transport IMMÉDIAT vers un établissement de santé',
      ],
      warnings: [
        'Never remove a tourniquet once applied - this must be done by trained medical personnel',
        'Do not remove objects impaled in the body - stabilize them in place',
        'Watch for signs of shock: pale skin, rapid breathing, confusion',
      ],
      referralIndicators: [
        'Bleeding does not stop with direct pressure',
        'Large or deep wound',
        'Signs of shock',
        'Tourniquet applied',
      ],
    ),
    EmergencyProcedure(
      id: '3',
      title: 'Infant Not Breathing',
      titleSw: 'Mtoto Mdogo Hapumui',
      titleFr: 'Nourrisson qui ne Respire Pas',
      category: 'pediatric',
      priority: 'critical',
      steps: [
        'Gently tap the baby\'s foot and call out - check for response',
        'Check if chest is rising and falling for 10 seconds',
        'If not breathing, place baby on firm flat surface',
        'Tilt head back slightly - be gentle, do not over-extend',
        'Cover baby\'s mouth AND nose with your mouth',
        'Give 2 gentle puffs of air (just enough to see chest rise)',
        'Check for pulse at brachial artery (inside of upper arm) for 10 seconds',
        'If no pulse, begin CPR: 30 chest compressions, 2 breaths',
        'Use 2 fingers for compressions in center of chest',
        'Push down about 1.5 inches (4 cm), allow full recoil',
        'Continue until baby responds or help arrives',
      ],
      stepsSw: [
        'Gusa mguu wa mtoto kwa upole na mwite - angalia majibu',
        'Angalia kama kifua kinapanda na kushuka kwa sekunde 10',
        'Ikiwa hapumui, weka mtoto kwenye uso mgumu',
        'Inamia kichwa nyuma kidogo - kuwa mpole, usiinamie sana',
        'Funika mdomo NA pua ya mtoto kwa mdomo wako',
        'Pumua pumzi 2 za upole (tu kutosha kuona kifua kupanda)',
        'Angalia mapigo ya moyo kwenye msuli wa brachial (ndani ya mkono wa juu) kwa sekunde 10',
        'Ikiwa hakuna mapigo, anza CPR: misukumo 30 ya kifua, pumzi 2',
        'Tumia vidole 2 kwa misukumo katikati ya kifua',
        'Bonyeza chini karibu inchi 1.5 (sm 4), ruhusu kurudi kamili',
        'Endelea hadi mtoto ajibu au msaada ufike',
      ],
      stepsFr: [
        'Tapotez doucement le pied du bébé et appelez - vérifiez la réponse',
        'Vérifiez si la poitrine se soulève et s\'abaisse pendant 10 secondes',
        'S\'il ne respire pas, placez le bébé sur une surface ferme et plate',
        'Inclinez légèrement la tête en arrière - soyez doux, ne sur-étendez pas',
        'Couvrez la bouche ET le nez du bébé avec votre bouche',
        'Donnez 2 petites insufflations (juste assez pour voir la poitrine se soulever)',
        'Vérifiez le pouls à l\'artère brachiale (intérieur du bras) pendant 10 secondes',
        'S\'il n\'y a pas de pouls, commencez la RCP: 30 compressions thoraciques, 2 insufflations',
        'Utilisez 2 doigts pour les compressions au centre de la poitrine',
        'Appuyez d\'environ 4 cm, permettez un recul complet',
        'Continuez jusqu\'à ce que le bébé réagisse ou que l\'aide arrive',
      ],
      warnings: [
        'Never shake a baby',
        'Do not blow too hard - baby\'s lungs are small',
        'Be gentle with head positioning to protect the neck',
      ],
      referralIndicators: [
        'Any infant who required resuscitation',
        'Baby remains unresponsive',
        'Breathing difficulty after resuscitation',
        'Color remains blue or pale',
      ],
    ),
    EmergencyProcedure(
      id: '4',
      title: 'Seizures / Convulsions',
      titleSw: 'Kifafa / Degedege',
      titleFr: 'Crises / Convulsions',
      category: 'neurological',
      priority: 'high',
      steps: [
        'Stay calm and note the time the seizure started',
        'Clear the area of hard or sharp objects',
        'Place something soft under the head if possible',
        'Turn person on their side (recovery position)',
        'DO NOT put anything in the mouth',
        'DO NOT restrain or hold the person down',
        'Stay with the person until seizure ends',
        'Time the seizure - if longer than 5 minutes, this is emergency',
        'After seizure ends, keep person on side, check breathing',
        'Speak calmly and reassure as they regain awareness',
      ],
      stepsSw: [
        'Tulia na andika muda kifafa kilianza',
        'Ondoa vitu vigumu au vikali karibu',
        'Weka kitu laini chini ya kichwa ikiwezekana',
        'Mgeuze mtu upande wake (nafasi ya kupona)',
        'USIWEKE chochote mdomoni',
        'USIMZUIE au kumshika mtu chini',
        'Kaa na mtu hadi kifafa kiishe',
        'Pima muda wa kifafa - ikiwa zaidi ya dakika 5, hii ni dharura',
        'Baada ya kifafa kuisha, weka mtu upande, angalia kupumua',
        'Ongea kwa utulivu na mhakikishie wanapopata fahamu',
      ],
      stepsFr: [
        'Restez calme et notez l\'heure de début de la crise',
        'Dégagez la zone des objets durs ou pointus',
        'Placez quelque chose de doux sous la tête si possible',
        'Mettez la personne sur le côté (position de récupération)',
        'NE METTEZ RIEN dans la bouche',
        'NE PAS retenir ou immobiliser la personne',
        'Restez avec la personne jusqu\'à la fin de la crise',
        'Chronométrez la crise - si plus de 5 minutes, c\'est une urgence',
        'Après la crise, gardez la personne sur le côté, vérifiez la respiration',
        'Parlez calmement et rassurez pendant la reprise de conscience',
      ],
      warnings: [
        'NEVER put fingers or objects in the mouth',
        'Do not give food or water during or immediately after seizure',
        'Person may be confused for several minutes after - this is normal',
      ],
      referralIndicators: [
        'Seizure lasts more than 5 minutes',
        'Multiple seizures without full recovery between them',
        'First-time seizure',
        'Seizure in pregnant woman',
        'Injury during seizure',
        'Person does not regain consciousness',
        'Fever with seizure in child',
      ],
    ),
    EmergencyProcedure(
      id: '5',
      title: 'Postpartum Hemorrhage',
      titleSw: 'Kutoka Damu Baada ya Kujifungua',
      titleFr: 'Hémorragie Post-Partum',
      category: 'maternal',
      priority: 'critical',
      steps: [
        'Call for help immediately - this is life-threatening',
        'Help mother lie flat and raise her legs',
        'Rub the uterus firmly (massage fundus) to help it contract',
        'Continue fundal massage every 15 minutes',
        'Encourage the baby to breastfeed - this helps uterus contract',
        'If placenta not delivered, do NOT pull on cord',
        'Check for tears - apply pressure if visible bleeding from tear',
        'Start IV fluids if trained and available',
        'Arrange EMERGENCY transport to facility',
        'Keep mother warm and monitor vital signs',
      ],
      stepsSw: [
        'Piga simu kwa msaada mara moja - hii ni hatari kwa maisha',
        'Msaidie mama kulala chini na kuinua miguu yake',
        'Piga uterasi kwa nguvu (masaji fundasi) kusaidia kusinyaa',
        'Endelea na masaji ya fundasi kila dakika 15',
        'Mhimize mtoto kunyonya - hii husaidia uterasi kusinyaa',
        'Ikiwa kondo la nyuma halijatoka, USIVUTE kamba',
        'Angalia michubuko - weka shinikizo ikiwa damu inaonekana kutoka michubuko',
        'Anza maji ya IV ikiwa umefunzwa na yanapatikana',
        'Panga usafiri wa DHARURA kwenda hospitalini',
        'Mweke mama joto na ufuatilie ishara muhimu',
      ],
      stepsFr: [
        'Appelez à l\'aide immédiatement - c\'est une menace vitale',
        'Aidez la mère à s\'allonger et à lever les jambes',
        'Massez fermement l\'utérus (massage du fond) pour aider à la contraction',
        'Continuez le massage utérin toutes les 15 minutes',
        'Encouragez le bébé à téter - cela aide l\'utérus à se contracter',
        'Si le placenta n\'est pas délivré, NE TIREZ PAS sur le cordon',
        'Vérifiez les déchirures - appliquez une pression si saignement visible',
        'Démarrez les perfusions IV si formé et disponible',
        'Organisez un transport d\'URGENCE vers l\'établissement',
        'Gardez la mère au chaud et surveillez les signes vitaux',
      ],
      warnings: [
        'Blood loss can be rapid - act quickly',
        'Never pull on umbilical cord to deliver placenta',
        'Monitor for shock: pale, cold, sweating, rapid pulse',
      ],
      referralIndicators: [
        'Any heavy bleeding after delivery',
        'Placenta not delivered within 30 minutes',
        'Signs of shock',
        'Bleeding with retained placenta',
        'Visible tears requiring stitches',
      ],
    ),
    EmergencyProcedure(
      id: '6',
      title: 'Severe Dehydration in Child',
      titleSw: 'Upungufu Mkubwa wa Maji kwa Mtoto',
      titleFr: 'Déshydratation Sévère chez l\'Enfant',
      category: 'pediatric',
      priority: 'high',
      steps: [
        'Recognize signs: sunken eyes, very dry mouth, skin stays pinched, no tears',
        'If child can drink, give ORS solution frequently',
        'Give small sips often rather than large amounts',
        'Continue breastfeeding if breastfed baby',
        'If child cannot drink or is vomiting everything, this is SEVERE',
        'Place nasogastric tube for rehydration if trained',
        'Give 20ml/kg ORS via NG tube over 30 minutes if unable to drink',
        'Monitor urine output and level of consciousness',
        'Arrange transport to facility for IV fluids',
        'Keep child cool if fever present',
      ],
      stepsSw: [
        'Tambua dalili: macho yaliyozama, mdomo mkavu sana, ngozi inabaki imekunjamana, hakuna machozi',
        'Ikiwa mtoto anaweza kunywa, mpe ORS mara kwa mara',
        'Mpe vinywaji vidogo mara kwa mara kuliko kiasi kikubwa',
        'Endelea kunyonyesha ikiwa mtoto ananyonya',
        'Ikiwa mtoto hawezi kunywa au anatapika kila kitu, hii ni KALI',
        'Weka bomba la nasogastric kwa kumwagilia maji ikiwa umefunzwa',
        'Mpe 20ml/kg ORS kupitia bomba la NG kwa dakika 30 ikiwa hawezi kunywa',
        'Fuatilia pato la mkojo na kiwango cha fahamu',
        'Panga usafiri kwenda hospitalini kwa maji ya IV',
        'Mweke mtoto baridi ikiwa homa ipo',
      ],
      stepsFr: [
        'Reconnaître les signes: yeux enfoncés, bouche très sèche, peau reste pincée, pas de larmes',
        'Si l\'enfant peut boire, donnez fréquemment la solution SRO',
        'Donnez de petites gorgées souvent plutôt que de grandes quantités',
        'Continuez l\'allaitement si bébé allaité',
        'Si l\'enfant ne peut pas boire ou vomit tout, c\'est GRAVE',
        'Placez une sonde nasogastrique pour la réhydratation si formé',
        'Donnez 20ml/kg de SRO par sonde NG en 30 minutes si incapable de boire',
        'Surveillez la diurèse et le niveau de conscience',
        'Organisez le transport vers l\'établissement pour les perfusions IV',
        'Gardez l\'enfant au frais si fièvre présente',
      ],
      warnings: [
        'Severe dehydration can cause death quickly in children',
        'Do not wait - begin ORS immediately',
        'Signs of severe: lethargic/unconscious, unable to drink, sunken fontanelle',
      ],
      referralIndicators: [
        'Unable to drink or keep fluids down',
        'Lethargy or unconsciousness',
        'Sunken eyes with no tears',
        'Skin pinch goes back very slowly (>2 seconds)',
        'No urine for 6+ hours',
        'Bloody diarrhea',
      ],
    ),
    EmergencyProcedure(
      id: '7',
      title: 'Snakebite',
      titleSw: 'Kuumwa na Nyoka',
      titleFr: 'Morsure de Serpent',
      category: 'environmental',
      priority: 'high',
      steps: [
        'Keep the person calm and still - movement spreads venom faster',
        'Remove any rings, watches, tight clothing from affected limb',
        'Immobilize the bitten limb at heart level or slightly below',
        'Mark the edge of swelling with pen and note the time',
        'Do NOT cut the wound or try to suck out venom',
        'Do NOT apply ice or tourniquet',
        'If possible, take photo of snake (only if safe) for identification',
        'Note the time of bite and any symptoms',
        'Arrange IMMEDIATE transport to facility with antivenom',
        'Monitor breathing and consciousness',
      ],
      stepsSw: [
        'Mweke mtu tulivu na bila kusogea - kusogea husambaza sumu haraka',
        'Ondoa pete, saa, nguo zinazobana kutoka kwenye mguu ulioumwa',
        'Weka mguu ulioumwa bila kusogea kwenye kiwango cha moyo au chini kidogo',
        'Weka alama ukingoni mwa uvimbe kwa kalamu na andika muda',
        'USIKATE jeraha au kujaribu kunyonya sumu',
        'USIWEKE barafu au tourniquet',
        'Ikiwezekana, piga picha ya nyoka (tu ikiwa salama) kwa utambuzi',
        'Andika muda wa kuumwa na dalili zozote',
        'Panga usafiri wa HARAKA kwenda hospitalini yenye dawa ya sumu',
        'Fuatilia kupumua na fahamu',
      ],
      stepsFr: [
        'Gardez la personne calme et immobile - le mouvement propage le venin plus vite',
        'Retirez bagues, montres, vêtements serrés du membre affecté',
        'Immobilisez le membre mordu au niveau du cœur ou légèrement en dessous',
        'Marquez le bord du gonflement avec un stylo et notez l\'heure',
        'NE COUPEZ PAS la plaie et n\'essayez pas d\'aspirer le venin',
        'N\'APPLIQUEZ PAS de glace ou de garrot',
        'Si possible, prenez une photo du serpent (seulement si sûr) pour identification',
        'Notez l\'heure de la morsure et les symptômes',
        'Organisez un transport IMMÉDIAT vers un établissement avec antivenin',
        'Surveillez la respiration et la conscience',
      ],
      warnings: [
        'Do NOT apply tight bandages or tourniquets',
        'Do NOT cut or suck the wound',
        'Do NOT apply electric shock or traditional remedies',
        'Time is critical - transport immediately',
      ],
      referralIndicators: [
        'All snakebites should be evaluated at health facility',
        'Swelling spreading beyond bite site',
        'Bleeding from gums or other sites',
        'Difficulty breathing',
        'Drooping eyelids, difficulty swallowing',
        'Change in consciousness',
      ],
    ),
    EmergencyProcedure(
      id: '8',
      title: 'Eclampsia (Seizures in Pregnancy)',
      titleSw: 'Eclampsia (Kifafa wakati wa Ujauzito)',
      titleFr: 'Éclampsie (Convulsions pendant la Grossesse)',
      category: 'maternal',
      priority: 'critical',
      steps: [
        'This is a life-threatening emergency - call for help',
        'Protect the woman from injury during seizure',
        'Turn her on her left side after seizure',
        'Ensure airway is clear - remove any vomit from mouth',
        'Give magnesium sulfate if available and trained (10g IM loading dose)',
        'Check blood pressure - usually very high (>160/110)',
        'Do NOT leave the woman alone',
        'Prepare for rapid transport to hospital',
        'If baby not yet born, this is obstetric emergency',
        'Monitor for repeated seizures',
      ],
      stepsSw: [
        'Hii ni dharura inayohatarisha maisha - piga simu kwa msaada',
        'Mlinde mwanamke kutokana na majeraha wakati wa kifafa',
        'Mgeuze upande wa kushoto baada ya kifafa',
        'Hakikisha njia ya hewa iko wazi - ondoa matapishi yoyote mdomoni',
        'Mpe magnesium sulfate ikiwa inapatikana na umefunzwa (dozi ya kupakia 10g IM)',
        'Angalia shinikizo la damu - kawaida ni juu sana (>160/110)',
        'USIMWACHE mwanamke peke yake',
        'Jiandae kwa usafiri wa haraka kwenda hospitalini',
        'Ikiwa mtoto hajazaliwa bado, hii ni dharura ya uzazi',
        'Fuatilia kifafa kujirudia',
      ],
      stepsFr: [
        'C\'est une urgence vitale - appelez à l\'aide',
        'Protégez la femme des blessures pendant la crise',
        'Tournez-la sur le côté gauche après la crise',
        'Assurez-vous que les voies respiratoires sont dégagées - retirez tout vomissement',
        'Donnez du sulfate de magnésium si disponible et formé (dose de charge 10g IM)',
        'Vérifiez la pression artérielle - généralement très élevée (>160/110)',
        'NE LAISSEZ PAS la femme seule',
        'Préparez un transport rapide vers l\'hôpital',
        'Si le bébé n\'est pas encore né, c\'est une urgence obstétricale',
        'Surveillez les crises répétées',
      ],
      warnings: [
        'Eclampsia can occur before, during, or after delivery',
        'Even one seizure is dangerous - can cause brain damage or death',
        'Baby may also be in danger and need immediate delivery',
      ],
      referralIndicators: [
        'Any seizure in pregnancy - ALL must go to hospital',
        'Severe headache with high blood pressure',
        'Vision changes with high blood pressure',
        'Severe swelling of face and hands',
        'Upper abdominal pain with high blood pressure',
      ],
    ),
  ];

  List<EmergencyProcedure> get _filteredProcedures {
    return _procedures.where((p) {
      final matchesCategory = _selectedCategory == 'all' || p.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          p.title.toLowerCase().contains(_searchQuery.toLowerCase());
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
                    child: _filteredProcedures.isEmpty
                        ? _buildEmptyState(l10n)
                        : ListView.builder(
                            physics: const ClampingScrollPhysics(),
                            padding: EdgeInsets.all(AppTheme.spacingMd),
                            itemCount: _filteredProcedures.length,
                            itemBuilder: (context, index) {
                              return _buildProcedureCard(
                                _filteredProcedures[index],
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
          colors: [Colors.red.shade600, Colors.red.shade800],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
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
                  l10n.translate('emergencyProcedures') ?? 'Emergency Procedures',
                  style: AppTheme.headingMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.translate('lifeSavingProtocols') ?? 'Life-saving protocols for critical situations',
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
            child: const FaIcon(FontAwesomeIcons.heartPulse, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(AppLocalizations l10n) {
    final categories = [
      {'id': 'all', 'label': l10n.translate('all') ?? 'All', 'icon': FontAwesomeIcons.list},
      {'id': 'airway', 'label': l10n.translate('airway') ?? 'Airway', 'icon': FontAwesomeIcons.wind},
      {'id': 'bleeding', 'label': l10n.translate('bleeding') ?? 'Bleeding', 'icon': FontAwesomeIcons.droplet},
      {'id': 'maternal', 'label': l10n.translate('maternal') ?? 'Maternal', 'icon': FontAwesomeIcons.personBreastfeeding},
      {'id': 'pediatric', 'label': l10n.translate('pediatric') ?? 'Pediatric', 'icon': FontAwesomeIcons.baby},
      {'id': 'neurological', 'label': l10n.translate('neurological') ?? 'Neuro', 'icon': FontAwesomeIcons.brain},
      {'id': 'environmental', 'label': l10n.translate('environmental') ?? 'Environment', 'icon': FontAwesomeIcons.tree},
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
                hintText: l10n.translate('searchEmergencies') ?? 'Search emergencies...',
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
                        Text(cat['label'] as String, style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    onSelected: (selected) {
                      setState(() => _selectedCategory = cat['id'] as String);
                    },
                    selectedColor: Colors.red.shade600,
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

  Widget _buildProcedureCard(EmergencyProcedure procedure, AppLocalizations l10n, String lang) {
    final priorityColor = procedure.priority == 'critical' ? Colors.red : Colors.orange;
    
    String getLocalizedTitle() {
      switch (lang) {
        case 'sw':
          return procedure.titleSw ?? procedure.title;
        case 'fr':
          return procedure.titleFr ?? procedure.title;
        default:
          return procedure.title;
      }
    }

    return Card(
      margin: EdgeInsets.only(bottom: AppTheme.spacingSm),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => _showProcedureDetails(procedure, l10n, lang),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: FaIcon(
                    _getCategoryIcon(procedure.category),
                    color: priorityColor,
                    size: 22,
                  ),
                ),
              ),
              SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            getLocalizedTitle(),
                            style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            procedure.priority.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: priorityColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${procedure.steps.length} ${l10n.translate('steps') ?? 'steps'}',
                      style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
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
      case 'airway':
        return FontAwesomeIcons.wind;
      case 'bleeding':
        return FontAwesomeIcons.droplet;
      case 'maternal':
        return FontAwesomeIcons.personBreastfeeding;
      case 'pediatric':
        return FontAwesomeIcons.baby;
      case 'neurological':
        return FontAwesomeIcons.brain;
      case 'environmental':
        return FontAwesomeIcons.tree;
      default:
        return FontAwesomeIcons.kitMedical;
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
            l10n.translate('noEmergenciesFound') ?? 'No procedures found',
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

  void _showProcedureDetails(EmergencyProcedure procedure, AppLocalizations l10n, String lang) {
    List<String> getLocalizedSteps() {
      switch (lang) {
        case 'sw':
          return procedure.stepsSw ?? procedure.steps;
        case 'fr':
          return procedure.stepsFr ?? procedure.steps;
        default:
          return procedure.steps;
      }
    }

    String getLocalizedTitle() {
      switch (lang) {
        case 'sw':
          return procedure.titleSw ?? procedure.title;
        case 'fr':
          return procedure.titleFr ?? procedure.title;
        default:
          return procedure.title;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmergencyDetailScreen(
          procedure: procedure,
          localizedTitle: getLocalizedTitle(),
          localizedSteps: getLocalizedSteps(),
        ),
      ),
    );
  }
}

/// Detail screen for individual emergency procedure
class EmergencyDetailScreen extends StatelessWidget {
  final EmergencyProcedure procedure;
  final String localizedTitle;
  final List<String> localizedSteps;

  const EmergencyDetailScreen({
    super.key,
    required this.procedure,
    required this.localizedTitle,
    required this.localizedSteps,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final priorityColor = procedure.priority == 'critical' ? Colors.red : Colors.orange;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: priorityColor,
        foregroundColor: Colors.white,
        title: Text(localizedTitle, style: AppTheme.headingSmall.copyWith(color: Colors.white)),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.share, size: 18),
            onPressed: () => _shareProtocol(context),
          ),
        ],
      ),
      body: ListView(
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.all(AppTheme.spacingMd),
        children: [
          // Priority banner
          Container(
            padding: EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                FaIcon(FontAwesomeIcons.triangleExclamation, color: priorityColor),
                SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    procedure.priority == 'critical'
                        ? l10n.translate('criticalEmergency') ?? 'CRITICAL - Act immediately, refer urgently'
                        : l10n.translate('highPriorityEmergency') ?? 'HIGH PRIORITY - Requires prompt attention',
                    style: AppTheme.bodyMedium.copyWith(
                      color: priorityColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppTheme.spacingMd),

          // Steps section
          Text(
            l10n.translate('stepByStep') ?? 'Step-by-Step Protocol',
            style: AppTheme.headingSmall,
          ),
          SizedBox(height: AppTheme.spacingSm),
          ...localizedSteps.asMap().entries.map((entry) => _buildStepCard(entry.key + 1, entry.value)),
          SizedBox(height: AppTheme.spacingMd),

          // Warnings section
          if (procedure.warnings.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FaIcon(FontAwesomeIcons.circleExclamation, color: Colors.amber.shade700, size: 18),
                      SizedBox(width: AppTheme.spacingSm),
                      Text(
                        l10n.translate('warnings') ?? 'Warnings',
                        style: AppTheme.labelMedium.copyWith(
                          color: Colors.amber.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppTheme.spacingSm),
                  ...procedure.warnings.map((w) => Padding(
                    padding: EdgeInsets.only(bottom: AppTheme.spacingXs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: TextStyle(color: Colors.amber.shade700)),
                        Expanded(child: Text(w, style: AppTheme.bodySmall)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            SizedBox(height: AppTheme.spacingMd),
          ],

          // Referral indicators
          Container(
            padding: EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FaIcon(FontAwesomeIcons.hospitalUser, color: Colors.blue.shade700, size: 18),
                    SizedBox(width: AppTheme.spacingSm),
                    Text(
                      l10n.translate('whenToRefer') ?? 'When to Refer',
                      style: AppTheme.labelMedium.copyWith(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppTheme.spacingSm),
                ...procedure.referralIndicators.map((r) => Padding(
                  padding: EdgeInsets.only(bottom: AppTheme.spacingXs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FaIcon(FontAwesomeIcons.check, size: 12, color: Colors.blue.shade700),
                      SizedBox(width: AppTheme.spacingXs),
                      Expanded(child: Text(r, style: AppTheme.bodySmall)),
                    ],
                  ),
                )),
              ],
            ),
          ),
          SizedBox(height: AppTheme.spacingLg),

          // Emergency call button
          ElevatedButton.icon(
            onPressed: () => _callEmergency(context),
            icon: const FaIcon(FontAwesomeIcons.phone, size: 18),
            label: Text(l10n.translate('callEmergencyServices') ?? 'Call Emergency Services'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.all(AppTheme.spacingMd),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: AppTheme.spacingMd),
        ],
      ),
    );
  }

  Widget _buildStepCard(int number, String step) {
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingSm),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: AppTheme.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(step, style: AppTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  void _shareProtocol(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing protocol...')),
    );
  }

  void _callEmergency(BuildContext context) {
    // Show confirmation dialog before calling
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call Emergency Services?'),
        content: const Text('This will dial emergency services. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement actual phone call using url_launcher
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calling emergency services...')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Call', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

/// Model for emergency procedures
class EmergencyProcedure {
  final String id;
  final String title;
  final String? titleSw;
  final String? titleFr;
  final String category;
  final String priority;
  final List<String> steps;
  final List<String>? stepsSw;
  final List<String>? stepsFr;
  final List<String> warnings;
  final List<String> referralIndicators;

  EmergencyProcedure({
    required this.id,
    required this.title,
    this.titleSw,
    this.titleFr,
    required this.category,
    required this.priority,
    required this.steps,
    this.stepsSw,
    this.stepsFr,
    required this.warnings,
    required this.referralIndicators,
  });
}
