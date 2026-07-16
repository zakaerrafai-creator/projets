import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(const VoisinageApp());
}

class VoisinageApp extends StatefulWidget {
  const VoisinageApp({super.key});

  @override
  State<VoisinageApp> createState() => _VoisinageAppState();
}

class _VoisinageAppState extends State<VoisinageApp> {
  UserProfile _profile = const UserProfile();
  bool _isLoggedIn = false;
  bool _authReady = false;

  static const _profilePhotoKey = 'profile_photo_path';

  final List<MatchProfile> _matches = const [
    MatchProfile(name: 'Claire', age: 68, distance: 'à 250 m', sharedInterest: 'balades du matin'),
    MatchProfile(name: 'Jean', age: 72, distance: 'à 400 m', sharedInterest: 'jardinage'),
    MatchProfile(name: 'Aline', age: 64, distance: 'à 150 m', sharedInterest: 'lecture'),
    MatchProfile(name: 'Michel', age: 70, distance: 'à 300 m', sharedInterest: 'marché local'),
  ];

  final List<ActivityPlan> _activityPlans = [
    const ActivityPlan(
      title: 'Promenade courte',
      place: 'Parc du quartier',
      date: '15/02/2026 10:30',
      category: 'Sortie légère',
      description: 'Circuit de 20 minutes, rythme tranquille',
    ),
    const ActivityPlan(
      title: 'Café de proximité',
      place: 'Café des Tilleuls',
      date: '16/02/2026 15:00',
      category: 'Discussion',
      description: 'Rencontre conviviale autour d’un café',
    ),
  ];

  final List<ServiceOffer> _serviceOffers = [
    const ServiceOffer(
      skill: 'Aide administrative simple',
      availability: 'Mardi matin',
      description: 'Remplir un formulaire ou classer des papiers',
      offerType: 'Je propose',
    ),
    const ServiceOffer(
      skill: 'Jardinage léger',
      availability: 'Jeudi après-midi',
      description: 'Arrosage ou entretien de balcon',
      offerType: 'Je peux aider',
    ),
  ];

  final List<MessageThread> _messageThreads = [
    const MessageThread(
      name: 'Claire',
      lastMessage: 'On se retrouve au parc demain ?',
      lastTime: 'Hier 18:40',
      aiSuggestion: 'Proposer une heure précise pour la balade',
    ),
    const MessageThread(
      name: 'Jean',
      lastMessage: 'Merci pour la recette !',
      lastTime: 'Aujourd’hui 09:15',
      aiSuggestion: 'Demander un souvenir de jardinage préféré',
    ),
  ];

  final List<GazetteItem> _gazetteItems = const [
    GazetteItem(
      title: 'Travaux rue du Parc',
      category: 'Info locale',
      detail: 'Les travaux commencent lundi, circulation reduite pendant 3 jours.',
    ),
    GazetteItem(
      title: 'Menu brasserie du coin',
      category: 'Bon plan',
      detail: 'Plat du jour: blanquette maison avec dessert inclus.',
    ),
    GazetteItem(
      title: 'Saviez-vous ? La boulangerie etait une forge',
      category: 'Anecdote',
      detail: 'Avant 1950, la boutique etait un atelier de ferronnerie.',
    ),
  ];

  final List<RoutineReminder> _routineReminders = const [
    RoutineReminder(
      title: 'Petite marche',
      detail: '10 minutes autour du square, il fait beau.',
      timeLabel: '10:30',
    ),
    RoutineReminder(
      title: 'Hydratation',
      detail: 'Boire un grand verre d\'eau.',
      timeLabel: '11:00',
    ),
  ];

  final List<GroupEvent> _groupEvents = const [
    GroupEvent(
      title: 'Table d\'hote locale',
      timeLabel: 'Mercredi 16:00',
      place: 'Cafe du square',
      detail: 'Gouter collectif a 5 voisins.',
    ),
    GroupEvent(
      title: 'Pedibus senior',
      timeLabel: 'Jeudi 10:00',
      place: 'Depart pied d’immeuble',
      detail: 'Marche en groupe vers le parc.',
    ),
  ];

  final List<MemoryItem> _memoryItems = const [
    MemoryItem(
      title: 'Rue des Tilleuls en 1972',
      contributor: 'Marie, 73 ans',
      description: 'Photo ancienne du quartier avant les renovations.',
    ),
    MemoryItem(
      title: 'La fete du village',
      contributor: 'Jacques, 76 ans',
      description: 'Souvenir de la kermesse annuelle.',
    ),
  ];

  final List<CommunityGroup> _communityGroups = [
    const CommunityGroup(
      name: 'Marche du parc',
      theme: 'Balades régulières',
      nextMeetup: 'Mercredi 10:00',
      members: '8 voisins',
    ),
    const CommunityGroup(
      name: 'Belote du mercredi',
      theme: 'Jeux de cartes',
      nextMeetup: 'Mercredi 16:00',
      members: '5 voisins',
    ),
  ];

  final List<VitalityInsight> _vitalityInsights = const [
    VitalityInsight(
      title: 'Activité en baisse',
      description: 'Moins d’échanges ces 5 derniers jours',
      status: VitalityStatus.attention,
    ),
    VitalityInsight(
      title: 'Sorties régulières',
      description: '2 sorties prévues cette semaine',
      status: VitalityStatus.good,
    ),
  ];

  void _saveProfile(UserProfile profile) {
    setState(() {
      _profile = profile;
    });
    _persistProfilePhoto(profile.photoPath);
  }

  @override
  void initState() {
    super.initState();
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('logged_in') ?? false;
    final photoPath = prefs.getString(_profilePhotoKey) ?? '';
    setState(() {
      _profile = UserProfile(
        name: _profile.name,
        age: _profile.age,
        interests: _profile.interests,
        availability: _profile.availability,
        neighborhood: _profile.neighborhood,
        preferences: _profile.preferences,
        skills: _profile.skills,
        photoPath: photoPath,
      );
      _isLoggedIn = loggedIn;
      _authReady = true;
    });
  }

  Future<void> _persistProfilePhoto(String path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path.isEmpty) {
      await prefs.remove(_profilePhotoKey);
    } else {
      await prefs.setString(_profilePhotoKey, path);
    }
  }

  Future<void> _setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('logged_in', value);
    setState(() {
      _isLoggedIn = value;
    });
  }

  Future<void> _handleLogin(BuildContext context) async {
    await _setLoggedIn(true);
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  Future<void> _handleLogout(BuildContext context) async {
    await _setLoggedIn(false);
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  Widget _buildAuthGate(BuildContext context) {
    if (!_authReady) {
      return const SplashScreen();
    }
    if (_isLoggedIn) {
      return HomeScreen(
        profile: _profile,
        activityPlans: _activityPlans,
        serviceOffers: _serviceOffers,
        messageThreads: _messageThreads,
        communityGroups: _communityGroups,
        vitalityInsights: _vitalityInsights,
        onGoProfile: () => Navigator.pushNamed(context, '/profile'),
        onGoMatches: () => Navigator.pushNamed(context, '/matches'),
        onGoLocation: () => Navigator.pushNamed(context, '/location'),
        onGoActivities: () => Navigator.pushNamed(context, '/activities'),
        onGoServices: () => Navigator.pushNamed(context, '/services'),
        onGoMessages: () => Navigator.pushNamed(context, '/messages'),
        onGoCommunities: () => Navigator.pushNamed(context, '/communities'),
        onGoVitality: () => Navigator.pushNamed(context, '/vitality'),
        onGoCoach: () => Navigator.pushNamed(context, '/coach'),
        onGoGazette: () => Navigator.pushNamed(context, '/gazette'),
        onGoWellbeing: () => Navigator.pushNamed(context, '/wellbeing'),
        onGoGroupEvents: () => Navigator.pushNamed(context, '/group-events'),
        onGoMemories: () => Navigator.pushNamed(context, '/memories'),
        onGoSettings: () => Navigator.pushNamed(context, '/settings'),
      );
    }
    return AuthChoiceScreen(
      onLogin: () => Navigator.pushNamed(context, '/login'),
      onRegister: () => Navigator.pushNamed(context, '/register'),
    );
  }

  void _addActivityPlan(ActivityPlan plan) {
    setState(() {
      _activityPlans.insert(0, plan);
    });
  }

  void _addServiceOffer(ServiceOffer offer) {
    setState(() {
      _serviceOffers.insert(0, offer);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voisin’Âge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB85B3A),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F1EB),
        textTheme: GoogleFonts.workSansTextTheme().copyWith(
          displayLarge: GoogleFonts.fraunces(fontWeight: FontWeight.w600),
          displayMedium: GoogleFonts.fraunces(fontWeight: FontWeight.w600),
          displaySmall: GoogleFonts.fraunces(fontWeight: FontWeight.w600),
          headlineLarge: GoogleFonts.fraunces(fontWeight: FontWeight.w600),
          headlineMedium: GoogleFonts.fraunces(fontWeight: FontWeight.w600),
          headlineSmall: GoogleFonts.fraunces(fontWeight: FontWeight.w600),
          titleLarge: GoogleFonts.fraunces(fontWeight: FontWeight.w600),
          titleMedium: GoogleFonts.fraunces(fontWeight: FontWeight.w600),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF6F1EB),
          foregroundColor: Color(0xFF2A211B),
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFFFF8F1),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            side: const BorderSide(color: Color(0xFFB85B3A)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFF8F1),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFB85B3A), width: 1.5),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFFFE8D4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      home: Builder(builder: (context) => _buildAuthGate(context)),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (context) => AuthChoiceScreen(
                onLogin: () => Navigator.pushNamed(context, '/login'),
                onRegister: () => Navigator.pushNamed(context, '/register'),
              ),
            );
          case '/login':
            return MaterialPageRoute(
              builder: (context) => LoginScreen(
                onLogin: () => _handleLogin(context),
                onRegister: () => Navigator.pushReplacementNamed(context, '/register'),
              ),
            );
          case '/register':
            return MaterialPageRoute(
              builder: (context) => RegisterScreen(
                onRegister: () => _handleLogin(context),
                onLogin: () => Navigator.pushReplacementNamed(context, '/login'),
              ),
            );
          case '/home':
            return MaterialPageRoute(
              builder: (context) => HomeScreen(
                profile: _profile,
                activityPlans: _activityPlans,
                serviceOffers: _serviceOffers,
                messageThreads: _messageThreads,
                communityGroups: _communityGroups,
                vitalityInsights: _vitalityInsights,
                onGoProfile: () => Navigator.pushNamed(context, '/profile'),
                onGoMatches: () => Navigator.pushNamed(context, '/matches'),
                onGoLocation: () => Navigator.pushNamed(context, '/location'),
                onGoActivities: () => Navigator.pushNamed(context, '/activities'),
                onGoServices: () => Navigator.pushNamed(context, '/services'),
                onGoMessages: () => Navigator.pushNamed(context, '/messages'),
                onGoCommunities: () => Navigator.pushNamed(context, '/communities'),
                onGoVitality: () => Navigator.pushNamed(context, '/vitality'),
                onGoCoach: () => Navigator.pushNamed(context, '/coach'),
                onGoGazette: () => Navigator.pushNamed(context, '/gazette'),
                onGoWellbeing: () => Navigator.pushNamed(context, '/wellbeing'),
                onGoGroupEvents: () => Navigator.pushNamed(context, '/group-events'),
                onGoMemories: () => Navigator.pushNamed(context, '/memories'),
                onGoSettings: () => Navigator.pushNamed(context, '/settings'),
              ),
            );
          case '/profile':
            return MaterialPageRoute(
              builder: (context) => ProfileScreen(
                profile: _profile,
                onSave: _saveProfile,
              ),
            );
          case '/matches':
            return MaterialPageRoute(
              builder: (context) => MatchesScreen(
                profile: _profile,
                matches: _matches,
              ),
            );
          case '/location':
            return MaterialPageRoute(builder: (context) => const LocationScreen());
          case '/activities':
            return MaterialPageRoute(
              builder: (context) => ActivitiesScreen(
                plans: _activityPlans,
                onPublish: _addActivityPlan,
              ),
            );
          case '/services':
            return MaterialPageRoute(
              builder: (context) => ServicesScreen(
                offers: _serviceOffers,
                onPublish: _addServiceOffer,
              ),
            );
          case '/messages':
            return MaterialPageRoute(
              builder: (context) => MessagesScreen(threads: _messageThreads),
            );
          case '/communities':
            return MaterialPageRoute(
              builder: (context) => CommunitiesScreen(groups: _communityGroups),
            );
          case '/vitality':
            return MaterialPageRoute(
              builder: (context) => VitalityScreen(insights: _vitalityInsights),
            );
          case '/settings':
            return MaterialPageRoute(
              builder: (context) => SettingsScreen(onLogout: () => _handleLogout(context)),
            );
          case '/coach':
            return MaterialPageRoute(
              builder: (context) => VoiceCoachScreen(onAddActivityPlan: _addActivityPlan),
            );
          case '/gazette':
            return MaterialPageRoute(
              builder: (context) => GazetteScreen(items: _gazetteItems),
            );
          case '/wellbeing':
            return MaterialPageRoute(
              builder: (context) => WellbeingScreen(reminders: _routineReminders),
            );
          case '/group-events':
            return MaterialPageRoute(
              builder: (context) => GroupEventsScreen(events: _groupEvents),
            );
          case '/memories':
            return MaterialPageRoute(
              builder: (context) => MemoriesScreen(items: _memoryItems),
            );
        }
        return null;
      },
    );
  }
}

@immutable
class UserProfile {
  final String name;
  final String age;
  final String interests;
  final String availability;
  final String neighborhood;
  final String preferences;
  final String skills;
  final String photoPath;

  const UserProfile({
    this.name = '',
    this.age = '',
    this.interests = '',
    this.availability = '',
    this.neighborhood = '',
    this.preferences = '',
    this.skills = '',
    this.photoPath = '',
  });
}

@immutable
class MatchProfile {
  final String name;
  final int age;
  final String distance;
  final String sharedInterest;

  const MatchProfile({
    required this.name,
    required this.age,
    required this.distance,
    required this.sharedInterest,
  });
}

@immutable
class ActivityPlan {
  final String title;
  final String place;
  final String date;
  final String category;
  final String description;

  const ActivityPlan({
    required this.title,
    required this.place,
    required this.date,
    required this.category,
    required this.description,
  });
}

@immutable
class ServiceOffer {
  final String skill;
  final String availability;
  final String description;
  final String offerType;

  const ServiceOffer({
    required this.skill,
    required this.availability,
    required this.description,
    required this.offerType,
  });
}

@immutable
class MessageThread {
  final String name;
  final String lastMessage;
  final String lastTime;
  final String aiSuggestion;

  const MessageThread({
    required this.name,
    required this.lastMessage,
    required this.lastTime,
    required this.aiSuggestion,
  });
}

@immutable
class GazetteItem {
  final String title;
  final String category;
  final String detail;

  const GazetteItem({
    required this.title,
    required this.category,
    required this.detail,
  });
}

@immutable
class RoutineReminder {
  final String title;
  final String detail;
  final String timeLabel;

  const RoutineReminder({
    required this.title,
    required this.detail,
    required this.timeLabel,
  });
}

@immutable
class GroupEvent {
  final String title;
  final String timeLabel;
  final String place;
  final String detail;

  const GroupEvent({
    required this.title,
    required this.timeLabel,
    required this.place,
    required this.detail,
  });
}

@immutable
class MemoryItem {
  final String title;
  final String contributor;
  final String description;

  const MemoryItem({
    required this.title,
    required this.contributor,
    required this.description,
  });
}

@immutable
class OnboardingQuestion {
  final String prompt;
  final List<String> options;

  const OnboardingQuestion({
    required this.prompt,
    required this.options,
  });
}

@immutable
class CommunityGroup {
  final String name;
  final String theme;
  final String nextMeetup;
  final String members;

  const CommunityGroup({
    required this.name,
    required this.theme,
    required this.nextMeetup,
    required this.members,
  });
}

enum VitalityStatus { good, attention }

@immutable
class VitalityInsight {
  final String title;
  final String description;
  final VitalityStatus status;

  const VitalityInsight({
    required this.title,
    required this.description,
    required this.status,
  });
}

@immutable
class ReminderItem {
  final String title;
  final String subtitle;
  final DateTime? dateTime;

  const ReminderItem({
    required this.title,
    required this.subtitle,
    required this.dateTime,
  });
}

@immutable
class NeighborhoodRank {
  final String name;
  final int points;
  final int distanceMeters;

  const NeighborhoodRank({
    required this.name,
    required this.points,
    required this.distanceMeters,
  });
}

DateTime? parseDateTime(String text) {
  final value = text.trim();
  if (value.isEmpty) return null;
  final parts = value.split(' ');
  if (parts.length != 2) return null;
  final dateParts = parts[0].split('/');
  final timeParts = parts[1].split(':');
  if (dateParts.length != 3 || timeParts.length != 2) return null;
  final day = int.tryParse(dateParts[0]);
  final month = int.tryParse(dateParts[1]);
  final year = int.tryParse(dateParts[2]);
  final hour = int.tryParse(timeParts[0]);
  final minute = int.tryParse(timeParts[1]);
  if (day == null || month == null || year == null || hour == null || minute == null) {
    return null;
  }
  if (month < 1 || month > 12 || day < 1 || day > 31 || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
    return null;
  }
  return DateTime(year, month, day, hour, minute);
}

String formatDateTime(DateTime dateTime) {
  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final year = dateTime.year.toString();
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _ScreenBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFB85B3A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              Text('Voisin’Âge', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('Chargement...'),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthChoiceScreen extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  const AuthChoiceScreen({
    super.key,
    required this.onLogin,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bienvenue')),
      body: _ScreenBackground(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoCard(
                title: 'Accédez à votre compte Voisin’Âge',
                subtitle: 'Identifiez-vous ou créez un compte pour continuer.',
              ),
              const SizedBox(height: 24),
              _PillButton(
                label: 'S’identifier',
                icon: Icons.login,
                onTap: onLogin,
                filled: true,
                expand: true,
              ),
              const SizedBox(height: 12),
              _PillButton(
                label: 'Créer un compte',
                icon: Icons.person_add_alt,
                onTap: onRegister,
                filled: false,
                expand: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  const LoginScreen({
    super.key,
    required this.onLogin,
    required this.onRegister,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('S’identifier')),
      body: _ScreenBackground(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FormCard(
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Mot de passe'),
                    obscureText: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _PillButton(
                label: 'Se connecter',
                icon: Icons.lock_open,
                onTap: widget.onLogin,
                filled: true,
                expand: true,
              ),
              const SizedBox(height: 12),
              _PillButton(
                label: 'Créer un compte',
                icon: Icons.person_add_alt,
                onTap: widget.onRegister,
                filled: false,
                expand: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  final VoidCallback onRegister;
  final VoidCallback onLogin;

  const RegisterScreen({
    super.key,
    required this.onRegister,
    required this.onLogin,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final List<OnboardingQuestion> _questions = const [
    OnboardingQuestion(
      prompt: 'Quel est votre moment prefere pour sortir ou discuter ?',
      options: ['Le matin', 'Le midi', "L'apres-midi", 'Le debut de soiree'],
    ),
    OnboardingQuestion(
      prompt: 'Quelle est votre activite physique favorite en ce moment ?',
      options: [
        'Une petite marche tranquille dans le quartier',
        'Une balade plus longue (parc, foret)',
        'Une activite douce (gym douce, yoga, etirements)',
        'Je prefere rester assis pour discuter',
      ],
    ),
    OnboardingQuestion(
      prompt: "Qu'est-ce qui vous passionne le plus parmi ces choix ?",
      options: ['Les arts', 'La nature', 'La cuisine', 'Les jeux'],
    ),
    OnboardingQuestion(
      prompt: 'Quel type de rencontre recherchez-vous en priorite ?',
      options: [
        'Un(e) ami(e) pour des sorties regulieres',
        "Quelqu'un pour discuter de temps en temps",
        "De l'entraide (petit service, informatique, bricolage)",
        'Participer a des petits groupes (3-4 personnes)',
      ],
    ),
    OnboardingQuestion(
      prompt: 'Comment decririez-vous votre caractere ?',
      options: ['Plutot reserve(e) et calme', 'Tres sociable et dynamique', 'Curieux(se)', "Tres a l'ecoute"],
    ),
    OnboardingQuestion(
      prompt: 'Quel est votre rapport a votre quartier ?',
      options: [
        "J'y habite depuis toujours, je connais tout",
        'Je suis la depuis quelques annees',
        "Je viens d'arriver et je veux decouvrir",
        'Je ne sors pas beaucoup, je veux mieux le connaitre',
      ],
    ),
    OnboardingQuestion(
      prompt: 'Si vous deviez choisir un service a rendre, ce serait quoi ?',
      options: [
        'Expliquer le numerique (smartphone, tablette)',
        'Un petit coup de main (couture, plantes, courrier)',
        'Preparer un gateau ou partager un savoir-faire',
        'Offrir une oreille attentive',
      ],
    ),
    OnboardingQuestion(
      prompt: 'Quel est votre sujet de conversation favori ?',
      options: ['Les souvenirs et l\'histoire', "L'actualite", 'La culture', 'La famille'],
    ),
    OnboardingQuestion(
      prompt: 'Quelle distance maximum pouvez-vous parcourir a pied ?',
      options: [
        "Juste au pied de mon immeuble ou dans ma rue",
        'Dans un rayon de 5 a 10 minutes (mon quartier)',
        'Je peux prendre le bus pour aller un peu plus loin',
        'Je suis vehicule(e) ou tres bon marcheur',
      ],
    ),
    OnboardingQuestion(
      prompt: "Qu'attendez-vous de l'application Voisin'Age aujourd'hui ?",
      options: ['Rompre la solitude', 'Me motiver a sortir plus souvent', "Me sentir utile", 'Decouvrir de nouvelles activites'],
    ),
  ];
  late final List<int?> _answers;
  int _questionIndex = 0;
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    _answers = List<int?>.filled(_questions.length, null);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showForm) {
      final question = _questions[_questionIndex];
      final progress = (_questionIndex + 1) / _questions.length;
      return Scaffold(
        appBar: AppBar(title: const Text('Creer un compte')),
        body: _ScreenBackground(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Question ${_questionIndex + 1}/${_questions.length}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 16),
                Text(question.prompt, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Expanded(
                  child: Card(
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: question.options.asMap().entries.map((entry) {
                        final index = entry.key;
                        final option = entry.value;
                        return RadioListTile<int>(
                          value: index,
                          groupValue: _answers[_questionIndex],
                          onChanged: (value) => setState(() => _answers[_questionIndex] = value),
                          title: Text(option),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (_questionIndex > 0)
                      _PillButton(
                        label: 'Retour',
                        icon: Icons.arrow_back,
                        onTap: () => setState(() => _questionIndex -= 1),
                        filled: false,
                      ),
                    if (_questionIndex > 0) const SizedBox(width: 12),
                    Expanded(
                      child: _PillButton(
                        label: _questionIndex == _questions.length - 1
                            ? 'Continuer vers les informations'
                            : 'Suivant',
                        icon: Icons.arrow_forward,
                        onTap: _answers[_questionIndex] == null
                            ? null
                            : () {
                                if (_questionIndex == _questions.length - 1) {
                                  setState(() => _showForm = true);
                                } else {
                                  setState(() => _questionIndex += 1);
                                }
                              },
                        filled: true,
                        expand: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: _ScreenBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FormCard(
                children: [
                  TextField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: 'Prénom'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Nom'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Mot de passe'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmController,
                    decoration: const InputDecoration(labelText: 'Confirmer le mot de passe'),
                    obscureText: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _PillButton(
                label: 'Créer mon compte',
                icon: Icons.check_circle,
                onTap: widget.onRegister,
                filled: true,
                expand: true,
              ),
              const SizedBox(height: 12),
              _PillButton(
                label: 'J’ai déjà un compte',
                icon: Icons.login,
                onTap: widget.onLogin,
                filled: false,
                expand: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final UserProfile profile;
  final List<ActivityPlan> activityPlans;
  final List<ServiceOffer> serviceOffers;
  final List<MessageThread> messageThreads;
  final List<CommunityGroup> communityGroups;
  final List<VitalityInsight> vitalityInsights;
  final VoidCallback onGoProfile;
  final VoidCallback onGoMatches;
  final VoidCallback onGoLocation;
  final VoidCallback onGoActivities;
  final VoidCallback onGoServices;
  final VoidCallback onGoMessages;
  final VoidCallback onGoCommunities;
  final VoidCallback onGoVitality;
  final VoidCallback onGoCoach;
  final VoidCallback onGoGazette;
  final VoidCallback onGoWellbeing;
  final VoidCallback onGoGroupEvents;
  final VoidCallback onGoMemories;
  final VoidCallback onGoSettings;

  const HomeScreen({
    super.key,
    required this.profile,
    required this.activityPlans,
    required this.serviceOffers,
    required this.messageThreads,
    required this.communityGroups,
    required this.vitalityInsights,
    required this.onGoProfile,
    required this.onGoMatches,
    required this.onGoLocation,
    required this.onGoActivities,
    required this.onGoServices,
    required this.onGoMessages,
    required this.onGoCommunities,
    required this.onGoVitality,
    required this.onGoCoach,
    required this.onGoGazette,
    required this.onGoWellbeing,
    required this.onGoGroupEvents,
    required this.onGoMemories,
    required this.onGoSettings,
  });

  @override
  Widget build(BuildContext context) {
    final reminders = <ReminderItem>[
      ...activityPlans.map(
        (plan) => ReminderItem(
          title: 'Activité : ${plan.title}',
          subtitle: '${plan.place} • ${plan.date}',
          dateTime: parseDateTime(plan.date),
        ),
      ),
    ]
      ..sort((a, b) {
        final aTime = a.dateTime?.millisecondsSinceEpoch ?? 1 << 60;
        final bTime = b.dateTime?.millisecondsSinceEpoch ?? 1 << 60;
        return aTime.compareTo(bTime);
      });

    return Scaffold(
      body: _ScreenBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileHeader(
                  name: profile.name.isNotEmpty ? profile.name : 'Mon profil',
                  neighborhood: profile.neighborhood.isNotEmpty
                      ? profile.neighborhood
                      : 'Quartier a renseigner',
                  photoPath: profile.photoPath,
                  fallbackAsset: 'assets/profile_photo.png',
                  onSos: () => _showSosDialog(context),
                  onTap: onGoProfile,
                ),
                const SizedBox(height: 20),
                _HighlightCard(
                  title: 'Vitalité sociale : 78/100',
                  subtitle: 'Stable cette semaine • 2 sorties prévues',
                  actionLabel: 'Voir mes indicateurs',
                  onAction: onGoVitality,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _StatChip(label: 'Activités', value: activityPlans.length.toString()),
                    _StatChip(label: 'Messages', value: messageThreads.length.toString()),
                    _StatChip(label: 'Groupes', value: communityGroups.length.toString()),
                    _StatChip(label: 'Entraide', value: serviceOffers.length.toString()),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Acces rapide', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _ActionCard(
                  title: 'Mon profil',
                  subtitle: 'Infos personnelles et preferences',
                  icon: Icons.person,
                  onTap: onGoProfile,
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  title: 'Voisins proches',
                  subtitle: 'Rencontres et affinites locales',
                  icon: Icons.people_alt,
                  onTap: onGoMatches,
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  title: 'Gazette',
                  subtitle: 'Infos et bons plans du quartier',
                  icon: Icons.article,
                  onTap: onGoGazette,
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  title: 'Rappels',
                  subtitle: 'Routine bien-etre et notifications',
                  icon: Icons.notifications_active,
                  onTap: onGoWellbeing,
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  title: 'Mode groupe',
                  subtitle: 'Evenements flash et sorties',
                  icon: Icons.event,
                  onTap: onGoGroupEvents,
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  title: 'Souvenirs',
                  subtitle: 'Album du quartier',
                  icon: Icons.photo_album,
                  onTap: onGoMemories,
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  title: 'Activites',
                  subtitle: 'Marches, cafes, sorties locales',
                  icon: Icons.directions_walk,
                  onTap: onGoActivities,
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  title: 'Messages',
                  subtitle: 'Discussions et suggestions IA',
                  icon: Icons.chat_bubble,
                  onTap: onGoMessages,
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  title: 'Groupes',
                  subtitle: 'Micro-communautes du voisinage',
                  icon: Icons.groups,
                  onTap: onGoCommunities,
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  title: 'Entraide',
                  subtitle: 'Tutorat et services locaux',
                  icon: Icons.volunteer_activism,
                  onTap: onGoServices,
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  title: 'Rayon',
                  subtitle: 'Zone geographique et proximite',
                  icon: Icons.map,
                  onTap: onGoLocation,
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  title: 'Confidentialite',
                  subtitle: 'Parametres et securite',
                  icon: Icons.lock,
                  onTap: onGoSettings,
                ),
                const SizedBox(height: 24),
                _InfoCard(
                  title: 'Suggestions du jour',
                  subtitle: vitalityInsights.isNotEmpty
                      ? vitalityInsights.first.description
                      : 'Proposez une activite simple a un voisin.',
                ),
                const SizedBox(height: 24),
                Text('Rappels des rendez-vous', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                if (reminders.isEmpty)
                  const Text('Aucun rendez-vous prevu pour le moment.')
                else
                  Column(
                    children: reminders.take(4).map((reminder) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ReminderCard(reminder: reminder),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _showSosDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('SOS envoye'),
        content: const Text('Votre cercle de confiance a ete prevenu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      );
    },
  );
}

class ProfileScreen extends StatefulWidget {
  final UserProfile profile;
  final ValueChanged<UserProfile> onSave;

  const ProfileScreen({
    super.key,
    required this.profile,
    required this.onSave,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _neighborhoodController;
  late final TextEditingController _interestsController;
  late final TextEditingController _availabilityController;
  late final TextEditingController _preferencesController;
  late final TextEditingController _skillsController;
  final ImagePicker _picker = ImagePicker();
  String _photoPath = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _ageController = TextEditingController(text: widget.profile.age);
    _neighborhoodController = TextEditingController(text: widget.profile.neighborhood);
    _interestsController = TextEditingController(text: widget.profile.interests);
    _availabilityController = TextEditingController(text: widget.profile.availability);
    _preferencesController = TextEditingController(text: widget.profile.preferences);
    _skillsController = TextEditingController(text: widget.profile.skills);
    _photoPath = widget.profile.photoPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _neighborhoodController.dispose();
    _interestsController.dispose();
    _availabilityController.dispose();
    _preferencesController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    widget.onSave(
      UserProfile(
        name: _nameController.text,
        age: _ageController.text,
        neighborhood: _neighborhoodController.text,
        interests: _interestsController.text,
        availability: _availabilityController.text,
        preferences: _preferencesController.text,
        skills: _skillsController.text,
        photoPath: _photoPath,
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _pickPhoto() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 90,
    );
    if (image == null) return;
    if (!mounted) return;
    setState(() => _photoPath = image.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: _ScreenBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoCard(
                title: 'Mon profil',
                subtitle: 'Mettez a jour vos informations personnelles.',
              ),
              const SizedBox(height: 16),
              _FormCard(
                title: 'Photo de profil',
                children: [
                  Row(
                    children: [
                      _ProfileAvatar(
                        photoPath: _photoPath,
                        fallbackAsset: 'assets/profile_photo.png',
                        size: 72,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Choisissez une photo depuis votre galerie.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _PillButton(
                    label: 'Choisir dans la galerie',
                    icon: Icons.photo_library,
                    onTap: _pickPhoto,
                    filled: true,
                    expand: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _FormCard(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Prénom'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ageController,
                    decoration: const InputDecoration(labelText: 'Âge'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _neighborhoodController,
                    decoration: const InputDecoration(labelText: 'Quartier'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _interestsController,
                    decoration: const InputDecoration(labelText: 'Centres d’intérêt'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _availabilityController,
                    decoration: const InputDecoration(labelText: 'Disponibilités'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _preferencesController,
                    decoration: const InputDecoration(labelText: 'Préférences relationnelles'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _skillsController,
                    decoration: const InputDecoration(labelText: 'Ce que je sais faire / rendre'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
                  _PillButton(
                    label: 'Enregistrer le profil',
                    icon: Icons.save,
                    onTap: _saveProfile,
                    filled: true,
                    expand: true,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class MatchesScreen extends StatelessWidget {
  final UserProfile profile;
  final List<MatchProfile> matches;

  const MatchesScreen({
    super.key,
    required this.profile,
    required this.matches,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rencontres proches')),
      body: _ScreenBackground(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoCard(
                title: profile.name.isNotEmpty
                    ? 'Bonjour ${profile.name}'
                    : 'Voisins proches',
                subtitle: profile.name.isNotEmpty
                    ? 'Voici des voisins compatibles pres de vous.'
                    : 'Voici quelques voisins a proximite.',
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: matches.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final match = matches[index];
                    return _ListCard(
                      title: '${match.name}, ${match.age} ans',
                      subtitle: '${match.distance} • Point commun : ${match.sharedInterest}',
                      description: 'Proposition : discuter autour d’une activité locale',
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  double _radius = 500;
  final String _selectedAddress = '12 Rue des Tilleuls, Quartier Centre';
  final List<NeighborhoodRank> _ranking = const [
    NeighborhoodRank(name: 'Claire', points: 92, distanceMeters: 250),
    NeighborhoodRank(name: 'Jean', points: 88, distanceMeters: 400),
    NeighborhoodRank(name: 'Aline', points: 84, distanceMeters: 150),
    NeighborhoodRank(name: 'Michel', points: 79, distanceMeters: 700),
    NeighborhoodRank(name: 'Sophie', points: 76, distanceMeters: 950),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choisir un rayon')),
      body: _ScreenBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoCard(
                title: 'Carte GPS',
                subtitle: 'Cette version Flutter affiche un aperçu. La carte réelle sera ajoutée avec une clé API.',
              ),
              const SizedBox(height: 16),
              _FormCard(
                title: 'Adresse du voisin',
                children: [
                  Text(_selectedAddress, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8F1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(Icons.map_outlined, size: 64, color: Colors.black45),
                    ),
                    Positioned(
                      right: 90,
                      top: 70,
                      child: Column(
                        children: const [
                          Icon(Icons.location_pin, color: Color(0xFFB85B3A), size: 36),
                          SizedBox(height: 4),
                          Text('Adresse', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Rayon: ${_radius.toInt()} m', style: Theme.of(context).textTheme.titleMedium),
              Slider(
                value: _radius,
                min: 200,
                max: 2000,
                onChanged: (value) => setState(() => _radius = value),
              ),
              const SizedBox(height: 16),
              Text('Classement du voisinage', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _RankingList(
                entries: _ranking
                    .where((entry) => entry.distanceMeters <= _radius)
                    .toList()
                  ..sort((a, b) => b.points.compareTo(a.points)),
              ),
              const SizedBox(height: 12),
                  _PillButton(
                    label: 'Valider le rayon',
                    icon: Icons.check,
                    onTap: () => Navigator.pop(context),
                    filled: true,
                    expand: true,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActivitiesScreen extends StatefulWidget {
  final List<ActivityPlan> plans;
  final ValueChanged<ActivityPlan> onPublish;

  const ActivitiesScreen({
    super.key,
    required this.plans,
    required this.onPublish,
  });

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final _titleController = TextEditingController();
  final _placeController = TextEditingController();
  final _dateController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _placeController.dispose();
    _dateController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _publish() {
    if (_titleController.text.trim().isEmpty) return;
    widget.onPublish(
      ActivityPlan(
        title: _titleController.text.trim(),
        place: _placeController.text.trim().isEmpty ? 'Lieu à préciser' : _placeController.text.trim(),
        date: _dateController.text.trim().isEmpty ? 'Date à préciser' : _dateController.text.trim(),
        category: _categoryController.text.trim().isEmpty
            ? 'Rencontre conviviale'
            : _categoryController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? 'Activité ouverte au voisinage'
            : _descriptionController.text.trim(),
      ),
    );
    _titleController.clear();
    _placeController.clear();
    _dateController.clear();
    _categoryController.clear();
    _descriptionController.clear();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null) return;
    final dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    _dateController.text = formatDateTime(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activités suggérées')),
      body: _ScreenBackground(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoCard(
                title: 'Activites suggerees',
                subtitle: 'Proposez une sortie simple et retrouvez les activites locales.',
              ),
              const SizedBox(height: 16),
              _FormCard(
                title: 'Proposer une activité simple',
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Activité'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _placeController,
                    decoration: const InputDecoration(labelText: 'Lieu de proximité'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: 'Date / heure (JJ/MM/AAAA HH:mm)',
                      suffixIcon: Icon(Icons.event),
                    ),
                    readOnly: true,
                    onTap: _pickDateTime,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _categoryController,
                    decoration: const InputDecoration(labelText: 'Catégorie (promenade, café, appel)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Message'),
                  ),
                  const SizedBox(height: 12),
                  _PillButton(
                    label: 'Publier l’activité',
                    icon: Icons.publish,
                    onTap: _publish,
                    filled: true,
                    expand: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Activités disponibles', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: widget.plans.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final plan = widget.plans[index];
                    return _ListCard(
                      title: plan.title,
                      subtitle: '${plan.place} • ${plan.date}',
                      description: '${plan.category} • ${plan.description}',
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ServicesScreen extends StatefulWidget {
  final List<ServiceOffer> offers;
  final ValueChanged<ServiceOffer> onPublish;

  const ServicesScreen({
    super.key,
    required this.offers,
    required this.onPublish,
  });

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final _skillController = TextEditingController();
  final _availabilityController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _offerType = 'Je propose';

  @override
  void dispose() {
    _skillController.dispose();
    _availabilityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _publish() {
    if (_skillController.text.trim().isEmpty) return;
    widget.onPublish(
      ServiceOffer(
        skill: _skillController.text.trim(),
        availability: _availabilityController.text.trim().isEmpty
            ? 'Disponibilité à préciser'
            : _availabilityController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? 'Entraide locale'
            : _descriptionController.text.trim(),
        offerType: _offerType,
      ),
    );
    _skillController.clear();
    _availabilityController.clear();
    _descriptionController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final helpIdeas = const [
      'Portage de sac: rapporter un pack d\'eau ou un sac lourd.',
      'Compagnon de salle d\'attente: trajet et attente ensemble.',
      'Aide numerique: envoyer un mail, imprimer un document.',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Entraide locale')),
      body: _ScreenBackground(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoCard(
                title: 'Entraide locale',
                subtitle: 'Tutorat, petits services et entraide de proximite.',
              ),
              const SizedBox(height: 16),
              _FormCard(
                title: 'Partager un service',
                children: [
                  DropdownButtonFormField<String>(
                    value: _offerType,
                    items: const [
                      DropdownMenuItem(value: 'Je propose', child: Text('Je propose')),
                      DropdownMenuItem(value: 'Je cherche', child: Text('Je cherche')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _offerType = value);
                    },
                    decoration: const InputDecoration(labelText: 'Type de service'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _skillController,
                    decoration: const InputDecoration(labelText: 'Compétence ou besoin'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _availabilityController,
                    decoration: const InputDecoration(labelText: 'Disponibilité'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Détails'),
                  ),
                  const SizedBox(height: 12),
                  _PillButton(
                    label: 'Publier l’entraide',
                    icon: Icons.volunteer_activism,
                    onTap: _publish,
                    filled: true,
                    expand: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _FormCard(
                title: 'Coup de Pouce Voisinage',
                children: helpIdeas
                    .map((idea) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _IdeaChip(text: idea),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              Text('Services proches', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: widget.offers.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final offer = widget.offers[index];
                    return _ListCard(
                      title: offer.skill,
                      subtitle: '${offer.offerType} • ${offer.availability}',
                      description: offer.description,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessagesScreen extends StatelessWidget {
  final List<MessageThread> threads;

  const MessagesScreen({
    super.key,
    required this.threads,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: _ScreenBackground(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoCard(
                title: 'Relances bienveillantes',
                subtitle: 'L’IA propose un texte pour relancer sans gêne.',
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: threads.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final thread = threads[index];
                    return _ListCard(
                      title: thread.name,
                      subtitle: '${thread.lastTime} • ${thread.lastMessage}',
                      description: 'Suggestion IA : ${thread.aiSuggestion}',
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GazetteScreen extends StatelessWidget {
  final List<GazetteItem> items;

  const GazetteScreen({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gazette du quartier')),
      body: _ScreenBackground(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoCard(
                title: 'Actualites locales',
                subtitle: 'Infos utiles, bons plans et anecdotes du quartier.',
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return _ListCard(
                      title: item.title,
                      subtitle: item.category,
                      description: item.detail,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WellbeingScreen extends StatefulWidget {
  final List<RoutineReminder> reminders;

  const WellbeingScreen({
    super.key,
    required this.reminders,
  });

  @override
  State<WellbeingScreen> createState() => _WellbeingScreenState();
}

class _WellbeingScreenState extends State<WellbeingScreen> {
  bool _coucouDone = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rappels bien-etre')),
      body: _ScreenBackground(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoCard(
                title: 'Bouton Coucou du matin',
                subtitle: _coucouDone
                    ? 'Merci, votre cercle est rassure.'
                    : 'Appuyez pour dire que tout va bien.',
              ),
              const SizedBox(height: 12),
              _PillButton(
                label: _coucouDone ? 'Coucou envoye' : 'Je suis reveille et en forme',
                icon: Icons.waving_hand,
                onTap: _coucouDone ? null : () => setState(() => _coucouDone = true),
                filled: true,
                expand: true,
              ),
              const SizedBox(height: 16),
              Text('Rappels de routine', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: widget.reminders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final reminder = widget.reminders[index];
                    return _ListCard(
                      title: reminder.title,
                      subtitle: reminder.timeLabel,
                      description: reminder.detail,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GroupEventsScreen extends StatelessWidget {
  final List<GroupEvent> events;

  const GroupEventsScreen({
    super.key,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mode groupe')),
      body: _ScreenBackground(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoCard(
                title: 'Evenements flash',
                subtitle: 'L\'IA propose des rencontres en petit groupe.',
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final event = events[index];
                    return _ListCard(
                      title: event.title,
                      subtitle: '${event.timeLabel} • ${event.place}',
                      description: event.detail,
                      actionLabel: 'S\'inscrire',
                      onAction: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Inscription envoyee pour ${event.title}.'),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MemoriesScreen extends StatelessWidget {
  final List<MemoryItem> items;

  const MemoriesScreen({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coffre aux souvenirs')),
      body: _ScreenBackground(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoCard(
                title: 'Album du quartier',
                subtitle: 'Partagez des photos anciennes et des souvenirs.',
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return _ListCard(
                      title: item.title,
                      subtitle: item.contributor,
                      description: item.description,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CommunitiesScreen extends StatelessWidget {
  final List<CommunityGroup> groups;

  const CommunitiesScreen({
    super.key,
    required this.groups,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Micro-communautés')),
      body: _ScreenBackground(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoCard(
                title: 'Groupes locaux',
                subtitle: 'Partagez une activité régulière avec des voisins proches.',
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: groups.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final group = groups[index];
                    return _ListCard(
                      title: group.name,
                      subtitle: '${group.theme} • ${group.members}',
                      description: 'Prochain rendez-vous : ${group.nextMeetup}',
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VitalityScreen extends StatelessWidget {
  final List<VitalityInsight> insights;

  const VitalityScreen({
    super.key,
    required this.insights,
  });

  @override
  Widget build(BuildContext context) {
    const score = 78;
    const trend = 'Stable cette semaine';

    return Scaffold(
      appBar: AppBar(title: const Text('Vitalité sociale')),
      body: _ScreenBackground(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoCard(
                title: 'Score de vitalité : $score/100',
                subtitle: trend,
              ),
              const SizedBox(height: 16),
              Text('Détecteur d’isolement silencieux', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: insights.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final insight = insights[index];
                    return _StatusCard(insight: insight);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const SettingsScreen({
    super.key,
    required this.onLogout,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class VoiceCoachScreen extends StatefulWidget {
  final ValueChanged<ActivityPlan> onAddActivityPlan;

  const VoiceCoachScreen({
    super.key,
    required this.onAddActivityPlan,
  });

  @override
  State<VoiceCoachScreen> createState() => _VoiceCoachScreenState();
}

class _VoiceCoachScreenState extends State<VoiceCoachScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _speechReady = false;
  bool _listening = false;
  String _status = 'Appuyez sur le micro pour poser une question.';
  String _heard = '';
  String _reply = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _listening = false);
          _handleReply();
        }
      },
      onError: (error) {
        setState(() {
          _listening = false;
          _status = 'Micro non disponible. Autorisez le micro.';
        });
      },
    );
    setState(() {
      _speechReady = available;
      _status = available
          ? 'Dites par exemple: "Comment trouver une activite ?"'
          : 'Reconnaissance vocale indisponible.';
    });
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(0.45);
    await _tts.awaitSpeakCompletion(true);
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  Future<void> _toggleListen() async {
    if (!_speechReady) return;
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    setState(() {
      _listening = true;
      _status = 'Je vous ecoute...';
    });
    await _speech.listen(
      localeId: 'fr_FR',
      onResult: (result) {
        setState(() {
          _heard = result.recognizedWords;
          _status = result.finalResult ? 'Question recue.' : 'Je vous ecoute...';
        });
      },
    );
  }

  String _normalize(String input) {
    final lower = input.toLowerCase();
    return lower
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('ç', 'c');
  }

  int? _weekdayFromText(String text) {
    const weekdays = {
      'lundi': DateTime.monday,
      'mardi': DateTime.tuesday,
      'mercredi': DateTime.wednesday,
      'jeudi': DateTime.thursday,
      'vendredi': DateTime.friday,
      'samedi': DateTime.saturday,
      'dimanche': DateTime.sunday,
    };
    for (final entry in weekdays.entries) {
      if (text.contains(entry.key)) return entry.value;
    }
    return null;
  }

  DateTime? _dateFromText(String text) {
    final now = DateTime.now();
    if (text.contains('demain')) {
      return DateTime(now.year, now.month, now.day + 1);
    }
    if (text.contains("aujourd'hui") || text.contains('aujourdhui')) {
      return DateTime(now.year, now.month, now.day);
    }
    if (text.contains('ce week-end') || text.contains('weekend') || text.contains('week-end')) {
      final saturday = _nextOccurrence(DateTime.saturday, const TimeOfDay(hour: 9, minute: 0));
      return DateTime(saturday.year, saturday.month, saturday.day);
    }
    return null;
  }

  TimeOfDay? _timeFromText(String text) {
    final compact = RegExp(r'(\d{1,2})\s*h\s*(\d{2})?');
    final colon = RegExp(r'(\d{1,2})\s*:\s*(\d{2})');
    final compactMatch = compact.firstMatch(text);
    if (compactMatch != null) {
      final hour = int.tryParse(compactMatch.group(1) ?? '');
      final minute = int.tryParse(compactMatch.group(2) ?? '0');
      if (hour != null && minute != null && hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }
    final colonMatch = colon.firstMatch(text);
    if (colonMatch != null) {
      final hour = int.tryParse(colonMatch.group(1) ?? '');
      final minute = int.tryParse(colonMatch.group(2) ?? '');
      if (hour != null && minute != null && hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }
    if (text.contains('matin')) return const TimeOfDay(hour: 10, minute: 0);
    if (text.contains('midi')) return const TimeOfDay(hour: 12, minute: 0);
    if (text.contains('apres-midi') || text.contains('apres midi')) {
      return const TimeOfDay(hour: 15, minute: 0);
    }
    if (text.contains('soir')) return const TimeOfDay(hour: 19, minute: 0);
    return null;
  }

  DateTime _nextOccurrence(int weekday, TimeOfDay time) {
    final now = DateTime.now();
    var daysAhead = (weekday - now.weekday + 7) % 7;
    final candidate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (daysAhead == 0 && !candidate.isAfter(now)) {
      daysAhead = 7;
    }
    return DateTime(now.year, now.month, now.day + daysAhead, time.hour, time.minute);
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String _activityTitleFromText(String text) {
    if (text.contains('echec')) return 'Jeu d\'echecs';
    if (text.contains('belote')) return 'Belote';
    if (text.contains('scrabble')) return 'Scrabble';
    if (text.contains('petanque')) return 'Petanque';
    if (text.contains('marche') || text.contains('balade')) return 'Marche de quartier';
    if (text.contains('cafe')) return 'Cafe de quartier';
    if (text.contains('yoga')) return 'Yoga doux';
    return 'Activite planifiee';
  }

  String _activityCategoryFromText(String text) {
    if (text.contains('echec') || text.contains('belote') || text.contains('scrabble') || text.contains('petanque') || text.contains('jeu')) {
      return 'Jeu';
    }
    if (text.contains('marche') || text.contains('balade')) return 'Sortie';
    if (text.contains('cafe') || text.contains('discussion')) return 'Discussion';
    if (text.contains('yoga')) return 'Bien-etre';
    return 'Activite';
  }

  String _activityPlaceFromText(String text) {
    if (text.contains('echec') || text.contains('belote') || text.contains('scrabble')) {
      return 'Salle commune';
    }
    if (text.contains('petanque')) return 'Terrain de petanque';
    if (text.contains('marche') || text.contains('balade')) return 'Parc du quartier';
    if (text.contains('cafe')) return 'Cafe du coin';
    if (text.contains('yoga')) return 'Maison de quartier';
    return 'Lieu a confirmer';
  }

  ActivityPlan? _activityFromSpeech(String question) {
    final text = _normalize(question);
    final wantsPlan = text.contains('planifi') || text.contains('organis') || text.contains('programme');
    if (!wantsPlan) return null;
    final time = _timeFromText(text) ?? const TimeOfDay(hour: 15, minute: 0);
    final directDate = _dateFromText(text);
    DateTime? dateTime;
    if (directDate != null) {
      dateTime = DateTime(directDate.year, directDate.month, directDate.day, time.hour, time.minute);
      if (!dateTime.isAfter(DateTime.now())) {
        dateTime = dateTime.add(const Duration(days: 1));
      }
    } else {
      final weekday = _weekdayFromText(text);
      if (weekday == null) return null;
      dateTime = _nextOccurrence(weekday, time);
    }
    return ActivityPlan(
      title: _activityTitleFromText(text),
      place: _activityPlaceFromText(text),
      date: _formatDateTime(dateTime),
      category: _activityCategoryFromText(text),
      description: 'Planifie via le coach vocal.',
    );
  }

  String? _routeFromSpeech(String question) {
    final text = _normalize(question);
    if (text.contains('accueil')) return '/home';
    if (text.contains('profil')) return '/profile';
    if (text.contains('voisin') || text.contains('match')) return '/matches';
    if (text.contains('activite') || text.contains('sortir') || text.contains('balade')) return '/activities';
    if (text.contains('entraide') || text.contains('service') || text.contains('coup de pouce')) return '/services';
    if (text.contains('message') || text.contains('parler')) return '/messages';
    if (text.contains('gazette') || text.contains('actus') || text.contains('journal')) return '/gazette';
    if (text.contains('rappel') || text.contains('bien etre') || text.contains('coucou')) return '/wellbeing';
    if (text.contains('mode groupe') || text.contains('evenement') || text.contains('table d')) {
      return '/group-events';
    }
    if (text.contains('groupe') || text.contains('communaute')) return '/communities';
    if (text.contains('souvenir') || text.contains('album')) return '/memories';
    if (text.contains('rayon') || text.contains('distance') || text.contains('quartier')) return '/location';
    if (text.contains('vitalite') || text.contains('isolement')) return '/vitality';
    if (text.contains('confidentialite') || text.contains('donnees')) return '/settings';
    if (text.contains('coach')) return '/coach';
    return null;
  }

  String _routeLabel(String route) {
    switch (route) {
      case '/home':
        return 'Accueil';
      case '/profile':
        return 'Mon profil';
      case '/matches':
        return 'Voisins proches';
      case '/activities':
        return 'Activites suggerees';
      case '/services':
        return 'Entraide';
      case '/messages':
        return 'Messages';
      case '/gazette':
        return 'Gazette du quartier';
      case '/wellbeing':
        return 'Rappels bien-etre';
      case '/group-events':
        return 'Mode groupe';
      case '/communities':
        return 'Groupes locaux';
      case '/memories':
        return 'Coffre aux souvenirs';
      case '/location':
        return 'Rayon';
      case '/vitality':
        return 'Vitalite sociale';
      case '/settings':
        return 'Confidentialite';
      case '/coach':
        return 'Coach vocal';
    }
    return 'Ecran';
  }

  String _generateReply(String question) {
    final route = _routeFromSpeech(question);
    if (route != null) {
      return 'D\'accord, j\'ouvre ${_routeLabel(route)}.';
    }
    return 'Je peux ouvrir un ecran ou planifier une activite, par exemple "Planifie un jeu d\'echecs mercredi a 15h".';
  }

  String _planReply(ActivityPlan plan) {
    return 'D\'accord, j\'ai planifie ${plan.title.toLowerCase()} le ${plan.date}.';
  }

  Future<void> _handleReply() async {
    if (_heard.trim().isEmpty) return;
    final plan = _activityFromSpeech(_heard);
    final route = plan != null ? '/activities' : _routeFromSpeech(_heard);
    final response = plan != null ? _planReply(plan) : _generateReply(_heard);
    setState(() => _reply = response);
    if (plan != null) {
      widget.onAddActivityPlan(plan);
    }
    await _tts.speak(response);
    if (!mounted) return;
    if (route != null) {
      if (route == '/home') {
        Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
      } else if (route != '/coach') {
        Navigator.pushNamed(context, route);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coach vocal')),
      body: _ScreenBackground(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoCard(
                title: "Parlez a Voisin'Age",
                subtitle: _status,
              ),
              const SizedBox(height: 16),
              _FormCard(
                title: 'Votre question',
                children: [
                  Text(_heard.isEmpty ? 'Aucune question pour le moment.' : _heard),
                ],
              ),
              const SizedBox(height: 12),
              _FormCard(
                title: 'Reponse du coach',
                children: [
                  Text(_reply.isEmpty ? 'Je suis pret a vous aider.' : _reply),
                  const SizedBox(height: 8),
                  _PillButton(
                    label: 'Reecouter',
                    icon: Icons.volume_up,
                    onTap: _reply.isEmpty ? null : () => _tts.speak(_reply),
                    filled: false,
                    expand: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _FormCard(
                title: 'Commandes vocales',
                children: const [
                  Text('Exemples: "Ouvre activites", "Va a gazette", "Ouvre entraide".'),
                  SizedBox(height: 6),
                  Text('Planification: "Planifie un jeu d\'echecs mercredi a 15h".'),
                  SizedBox(height: 6),
                  Text('Vous pouvez dire: "demain", "ce week-end", "apres-midi", "soir".'),
                ],
              ),
              const Spacer(),
              _PillButton(
                label: _listening ? 'Arreter' : 'Parler au coach',
                icon: _listening ? Icons.stop : Icons.mic,
                onTap: _toggleListen,
                filled: true,
                expand: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _profileVisible = true;
  bool _approxLocation = true;
  bool _voiceAssistant = true;
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confidentialité')),
      body: _ScreenBackground(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoCard(
                title: 'Contrôle de vos données',
                subtitle: 'Vos choix restent modifiables à tout moment.',
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _profileVisible,
                onChanged: (value) => setState(() => _profileVisible = value),
                title: const Text('Profil visible aux voisins proches'),
              ),
              SwitchListTile(
                value: _approxLocation,
                onChanged: (value) => setState(() => _approxLocation = value),
                title: const Text('Localisation approximative uniquement'),
              ),
              SwitchListTile(
                value: _voiceAssistant,
                onChanged: (value) => setState(() => _voiceAssistant = value),
                title: const Text('Assistant vocal activé'),
              ),
              SwitchListTile(
                value: _notifications,
                onChanged: (value) => setState(() => _notifications = value),
                title: const Text('Notifications bienveillantes'),
              ),
              const SizedBox(height: 12),
              _PillButton(
                label: 'Se déconnecter',
                icon: Icons.logout,
                onTap: widget.onLogout,
                filled: true,
                expand: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _InfoCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String neighborhood;
  final String? photoPath;
  final String fallbackAsset;
  final VoidCallback onSos;
  final VoidCallback onTap;

  const _ProfileHeader({
    required this.name,
    required this.neighborhood,
    required this.photoPath,
    required this.fallbackAsset,
    required this.onSos,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _ProfileAvatar(
                photoPath: photoPath,
                fallbackAsset: fallbackAsset,
                size: 56,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(neighborhood, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              _SosButton(onTrigger: onSos),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? photoPath;
  final String fallbackAsset;
  final double size;

  const _ProfileAvatar({
    required this.photoPath,
    required this.fallbackAsset,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final path = photoPath ?? '';
    Widget image;
    if (path.isNotEmpty && File(path).existsSync()) {
      image = Image.file(
        File(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    } else {
      image = Image.asset(
        fallbackAsset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: const Color(0xFFFFE8D4),
          child: Icon(Icons.person, color: const Color(0xFFB85B3A), size: size * 0.5),
        ),
      );
    }

    return ClipOval(child: image);
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE8D4),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Color(0xFFB85B3A), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFB85B3A)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScreenBackground extends StatelessWidget {
  final Widget child;

  const _ScreenBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF4E8), Color(0xFFF1ECE5)],
        ),
      ),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 450),
        tween: Tween(begin: 0, end: 1),
        curve: Curves.easeOut,
        builder: (context, value, animatedChild) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 12 * (1 - value)),
              child: animatedChild,
            ),
          );
        },
        child: child,
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _HighlightCard({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: const Color(0xFFFFE8D4),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFB85B3A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: onAction, child: Text(actionLabel)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label : $value'),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8F1),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFB85B3A), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1AB85B3A),
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE8D4),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Color(0xFFB85B3A), size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;
  final bool expand;

  const _PillButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.filled,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final background = filled
      ? (enabled ? const Color(0xFFB85B3A) : const Color(0xFFD8C1B7))
      : const Color(0xFFFFF8F1);
    final foreground = filled
      ? (enabled ? Colors.white : const Color(0xFFF5F1EE))
      : (enabled ? const Color(0xFF2A211B) : const Color(0xFF9A8F87));
    final borderColor = filled ? const Color(0xFFB85B3A) : const Color(0xFFB85B3A);

    final button = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: enabled
              ? const [
                  BoxShadow(
                    color: Color(0x1AB85B3A),
                    blurRadius: 10,
                    offset: Offset(0, 6),
                  ),
                ]
              : const [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: foreground, size: 20),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: foreground,
                    ),
              ),
            ),
          ],
        ),
      ),
    );

    if (!expand) {
      return button;
    }

    return SizedBox(width: double.infinity, child: button);
  }
}

class _SosButton extends StatefulWidget {
  final VoidCallback onTrigger;

  const _SosButton({required this.onTrigger});

  @override
  State<_SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<_SosButton> {
  Timer? _timer;
  bool _holding = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startHold() {
    _timer?.cancel();
    setState(() => _holding = true);
    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _holding = false);
      widget.onTrigger();
    });
  }

  void _cancelHold() {
    _timer?.cancel();
    if (_holding) {
      setState(() => _holding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _startHold(),
      onTapUp: (_) => _cancelHold(),
      onTapCancel: _cancelHold,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _holding ? const Color(0xFFB85B3A) : const Color(0xFFFFE8D4),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFB85B3A), width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.sos, color: _holding ? Colors.white : const Color(0xFFB85B3A)),
            const SizedBox(width: 6),
            Text(
              'SOS',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _holding ? Colors.white : const Color(0xFFB85B3A),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _FormCard({this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Text(title!, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
            ],
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _ListCard({
    required this.title,
    required this.subtitle,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFF8F1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 6),
            Text(description, style: Theme.of(context).textTheme.bodySmall),
            if (actionLabel != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: _PillButton(
                  label: actionLabel!,
                  icon: Icons.event_available,
                  onTap: onAction,
                  filled: true,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IdeaChip extends StatelessWidget {
  final String text;

  const _IdeaChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8D4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB85B3A), width: 1),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final ReminderItem reminder;

  const _ReminderCard({required this.reminder});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reminder.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(reminder.subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final VitalityInsight insight;

  const _StatusCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final color = insight.status == VitalityStatus.good
        ? const Color(0xFF2B6F6A)
        : Theme.of(context).colorScheme.error;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(insight.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(insight.description, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankingList extends StatelessWidget {
  final List<NeighborhoodRank> entries;

  const _RankingList({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Text('Aucun voisin dans ce rayon pour le moment.');
    }

    return Column(
      children: entries.take(5).toList().asMap().entries.map((entry) {
        final index = entry.key + 1;
        final rank = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFB85B3A),
                    child: Text(
                      '$index',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rank.name, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text('${rank.distanceMeters} m • ${rank.points} points',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const Icon(Icons.emoji_events_outlined, color: Color(0xFFB85B3A)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
