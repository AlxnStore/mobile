import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService.init();

  print('Initial Active: ${TicketHistoryService.getActiveTickets()}');
  runApp(const TixIDApp());
}

// ==================== SETTINGS SERVICE ====================

class SettingsService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Dark Mode
  static bool getDarkMode() {
    return _prefs?.getBool('darkMode') ?? false;
  }

  static Future<void> setDarkMode(bool value) async {
    await _prefs?.setBool('darkMode', value);
  }

  // PIN Security
  static bool isPinEnabled() {
    return _prefs?.getBool('pinEnabled') ?? false;
  }

  static Future<void> setPinEnabled(bool value) async {
    await _prefs?.setBool('pinEnabled', value);
  }

  static String? getPin() {
    return _prefs?.getString('pin');
  }

  static Future<void> setPin(String pin) async {
    await _prefs?.setString('pin', pin);
  }

  static Future<void> removePin() async {
    await _prefs?.remove('pin');
    await _prefs?.setBool('pinEnabled', false);
  }

  // Biometric
  static bool isBiometricEnabled() {
    return _prefs?.getBool('biometricEnabled') ?? false;
  }

  static Future<void> setBiometricEnabled(bool value) async {
    await _prefs?.setBool('biometricEnabled', value);
  }
}

// ==================== BIOMETRIC SERVICE ====================

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Verifikasi identitas Anda untuk melanjutkan',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      print('Biometric auth error: $e');
      return false;
    }
  }
}

class TixIDApp extends StatefulWidget {
  const TixIDApp({Key? key}) : super(key: key);

  @override
  State<TixIDApp> createState() => _TixIDAppState();

  static void updateTheme(BuildContext context) {
    final state = context.findAncestorStateOfType<_TixIDAppState>();
    state?.updateTheme();
  }
}

class _TixIDAppState extends State<TixIDApp> {
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    isDarkMode = SettingsService.getDarkMode();
  }

  void updateTheme() {
    setState(() {
      isDarkMode = SettingsService.getDarkMode();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CINEMA 1',
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        primaryColor: const Color(0xfffafafb),
        useMaterial3: true,
        fontFamily: null,
        iconTheme: const IconThemeData(
          color: Color(0xFF001A4D),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF001A4D),
          primary: const Color(0xFF001A4D),
          secondary: const Color(0xFFFFB800),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        primaryColor: const Color(0xFF1a1a1a),
        useMaterial3: true,
        fontFamily: null,
        iconTheme: const IconThemeData(
          color: Color(0xFFFFB800),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFB800),
          primary: const Color(0xFFFFB800),
          secondary: const Color(0xFF001A4D),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
      ),
      home: const SecurityCheckPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ==================== SECURITY CHECK PAGE ====================

class SecurityCheckPage extends StatefulWidget {
  const SecurityCheckPage({Key? key}) : super(key: key);

  @override
  State<SecurityCheckPage> createState() => _SecurityCheckPageState();
}

class _SecurityCheckPageState extends State<SecurityCheckPage> {
  @override
  void initState() {
    super.initState();
    _checkSecurity();
  }

  Future<void> _checkSecurity() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final isPinEnabled = SettingsService.isPinEnabled();
    final isBiometricEnabled = SettingsService.isBiometricEnabled();

    if (isPinEnabled || isBiometricEnabled) {
      // Show security verification
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const SecurityVerificationPage(),
        ),
      );
    } else {
      // Go directly to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFB800)),
      ),
    );
  }
}

// ==================== SECURITY VERIFICATION PAGE ====================

class SecurityVerificationPage extends StatefulWidget {
  const SecurityVerificationPage({Key? key}) : super(key: key);

  @override
  State<SecurityVerificationPage> createState() =>
      _SecurityVerificationPageState();
}

class _SecurityVerificationPageState extends State<SecurityVerificationPage> {
  String enteredPin = '';
  bool isError = false;

  @override
  void initState() {
    super.initState();
    _tryBiometric();
  }

  Future<void> _tryBiometric() async {
    if (SettingsService.isBiometricEnabled()) {
      await Future.delayed(const Duration(milliseconds: 500));
      final success = await BiometricService.authenticate();
      if (success && mounted) {
        _onSuccess();
      }
    }
  }

  void _onNumberPressed(String number) {
    if (enteredPin.length < 4) {
      setState(() {
        enteredPin += number;
        isError = false;
      });

      if (enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onDeletePressed() {
    if (enteredPin.isNotEmpty) {
      setState(() {
        enteredPin = enteredPin.substring(0, enteredPin.length - 1);
        isError = false;
      });
    }
  }

  void _verifyPin() {
    final savedPin = SettingsService.getPin();
    if (enteredPin == savedPin) {
      _onSuccess();
    } else {
      setState(() {
        isError = true;
        enteredPin = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN salah!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _onSuccess() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Verifikasi Keamanan'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Lock Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB800).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock,
                size: 60,
                color: Color(0xFFFFB800),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Masukkan PIN Anda',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            // PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < enteredPin.length
                        ? (isError ? Colors.red : const Color(0xFFFFB800))
                        : (isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade300),
                  ),
                ),
              ),
            ),
            if (isError)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'PIN salah, coba lagi',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 14,
                  ),
                ),
              ),
            const Spacer(),
            // Number Pad
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                if (index == 9) {
                  // Biometric Button
                  return SettingsService.isBiometricEnabled()
                      ? InkWell(
                          onTap: _tryBiometric,
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                            ),
                            child: const Icon(
                              Icons.fingerprint,
                              size: 30,
                              color: Color(0xFFFFB800),
                            ),
                          ),
                        )
                      : const SizedBox();
                } else if (index == 10) {
                  // Number 0
                  return _buildNumberButton('0', isDark);
                } else if (index == 11) {
                  // Delete Button
                  return InkWell(
                    onTap: _onDeletePressed,
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                      ),
                      child: const Icon(
                        Icons.backspace_outlined,
                        size: 24,
                      ),
                    ),
                  );
                } else {
                  // Numbers 1-9
                  return _buildNumberButton('${index + 1}', isDark);
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number, bool isDark) {
    return InkWell(
      onTap: () => _onNumberPressed(number),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
        child: Center(
          child: Text(
            number,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== MODELS ====================

class Film {
  final String id;
  final String title;
  final String genre;
  final String duration;
  final String rating;
  final String director;
  final String ageRating;
  final String imageUrl;
  final String trailerUrl;

  Film({
    required this.id,
    required this.title,
    required this.genre,
    required this.duration,
    required this.rating,
    required this.director,
    required this.ageRating,
    required this.imageUrl,
    required this.trailerUrl,
  });
}

class Schedule {
  final String date;
  final String day;
  final List<String> times;

  Schedule({required this.date, required this.day, required this.times});
}

class CinemaLocation {
  final String name;
  final String type;
  final List<String> times;

  CinemaLocation({
    required this.name,
    required this.type,
    required this.times,
  });
}

class PaymentMethod {
  final String id;
  final String name;
  final String description;
  final IconData iconData;
  final Color iconColor;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.iconData,
    required this.iconColor,
  });
}

class UserProfile {
  final String username;
  String name;
  String phoneNumber;
  String email;
  String profileImageUrl;
  String backgroundImageUrl;
  DateTime? birthDate;
  String? gender;

  UserProfile({
    required this.username,
    required this.name,
    required this.phoneNumber,
    this.email = '',
    required this.profileImageUrl,
    required this.backgroundImageUrl,
    this.birthDate,
    this.gender,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'backgroundImageUrl': backgroundImageUrl,
      'birthDate': birthDate?.toIso8601String(),
      'gender': gender,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      username: json['username'],
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      email: json['email'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      backgroundImageUrl: json['backgroundImageUrl'],
      birthDate:
          json['birthDate'] != null ? DateTime.parse(json['birthDate']) : null,
      gender: json['gender'],
    );
  }
}

class TicketHistory {
  final String id;
  final String userId;
  final Film film;
  final String cinema;
  final String date;
  final String time;
  final List<String> seats;
  final int totalAmount;
  final String bookingId;
  final DateTime purchaseDate;
  final String status;

  TicketHistory({
    required this.id,
    required this.userId,
    required this.film,
    required this.cinema,
    required this.date,
    required this.time,
    required this.seats,
    required this.totalAmount,
    required this.bookingId,
    required this.purchaseDate,
    this.status = 'active',
  });
}

// ==================== AUTH SERVICE ====================

class AuthService {
  static final Map<String, String> _users = {
    'alfian': '123',
    'dika': '456',
    'ricky': '789',
    'rizki': '157',
    'faisal': '246',
    'isan': '2025',
  };

  static final Map<String, UserProfile> _userProfiles = {
    'alfian': UserProfile(
      username: 'alfian',
      name: 'Alfian',
      phoneNumber: 'Frontend Developer',
      profileImageUrl:
          'https://i.pinimg.com/736x/c8/05/30/c80530f1ad4fa82dfc8a78a7665cd8f7.jpg',
      backgroundImageUrl:
          'https://i.pinimg.com/736x/04/7b/ab/047bab988a4771be2f77d0e3bf36c5ff.jpg',
    ),
    'dika': UserProfile(
      username: 'dika',
      name: 'Muhamad Handika',
      phoneNumber: '082345678901',
      profileImageUrl:
          'https://i.pinimg.com/736x/3f/f7/33/3ff733986fd0fc54710b774eaf87a486.jpg',
      backgroundImageUrl:
          'https://i.pinimg.com/736x/f4/5b/8e/f45b8e6f4e3c8d9a2b1c0d9e8f7a6b5c.jpg',
    ),
    'ricky': UserProfile(
      username: 'ricky',
      name: 'Ricky Martin',
      phoneNumber: '083456789012',
      profileImageUrl:
          'https://i.pinimg.com/736x/12/e1/4a/12e14a55930073942ab8398fc7a8450f.jpg',
      backgroundImageUrl:
          'https://i.pinimg.com/736x/2d/4e/a5/2d4ea5b6c7d8e9f0a1b2c3d4e5f6a7b8.jpg',
    ),
    'rizki': UserProfile(
      username: 'rizki',
      name: 'Muhamad Rizki Fauzi',
      phoneNumber: '084567890123',
      profileImageUrl:
          'https://i.pinimg.com/736x/8a/e3/40/8ae340e8624735b4c5dfa51ac984dac7.jpg',
      backgroundImageUrl:
          'https://i.pinimg.com/736x/4f/6a/c7/4f6ac7d8e9f0a1b2c3d4e5f6a7b8c9d0.jpg',
    ),
    'faisal': UserProfile(
      username: 'faisal',
      name: 'Faisal',
      phoneNumber: '085678901234',
      profileImageUrl:
          'https://i.pinimg.com/736x/4a/22/a3/4a22a3e8108b7c2393e8121fec7a29a6.jpg',
      backgroundImageUrl:
          'https://i.pinimg.com/736x/6b/8c/e9/6b8ce9f0a1b2c3d4e5f6a7b8c9d0e1f2.jpg',
    ),
    'isan': UserProfile(
      username: 'isan',
      name: 'Ikhsan Nur Aditya',
      phoneNumber: '086789012345',
      profileImageUrl:
          'https://i.pinimg.com/736x/05/87/e4/0587e4e17575afa0fc708990c8e9b793.jpg',
      backgroundImageUrl:
          'https://i.pinimg.com/736x/8d/ae/fb/8daefbc2d3e4f5a6b7c8d9e0f1a2b3c4.jpg',
    ),
  };

  static String? _currentUsername;

  static bool authenticate(String username, String password) {
    if (_users.containsKey(username) && _users[username] == password) {
      _currentUsername = username;
      return true;
    }
    return false;
  }

  static bool register(String username, String password) {
    if (_users.containsKey(username)) {
      return false;
    }
    _users[username] = password;

    _userProfiles[username] = UserProfile(
      username: username,
      name: username[0].toUpperCase() + username.substring(1),
      phoneNumber: '08xxxxxxxxxx',
      profileImageUrl: '',
      backgroundImageUrl: '',
    );

    _currentUsername = username;
    return true;
  }

  static bool isUsernameTaken(String username) {
    return _users.containsKey(username);
  }

  static String? getCurrentUsername() {
    return _currentUsername;
  }

  static UserProfile? getCurrentUserProfile() {
    if (_currentUsername == null) return null;
    return _userProfiles[_currentUsername];
  }

  static void updateUserProfile(UserProfile profile) {
    if (_currentUsername != null) {
      _userProfiles[_currentUsername!] = profile;
    }
  }

  static void logout() {
    _currentUsername = null;
  }
}

// ==================== FILM SERVICE ====================

class FilmService {
  static final List<Film> _films = [
    Film(
      id: '1',
      title: 'Spiderman No Way Home',
      genre: 'Animation, Fantasy',
      duration: '1 jam 40 menit',
      rating: '9.7',
      director: 'Tatsuya Yoshihara',
      ageRating: 'R 13+',
      imageUrl:
          'https://i.pinimg.com/1200x/a8/d3/92/a8d3924657c811bd76f298e5ab2cadc8.jpg',
      trailerUrl: 'https://youtu.be/JfVOs4VSpmA?si=i-Nh5BznkPedw0me',
    ),
    Film(
      id: '2',
      title: 'Avenger Infinity War',
      genre: 'Fantasi',
      duration: '2 jam',
      rating: '8.3',
      director: 'Alfian',
      ageRating: 'R 13+',
      imageUrl:
          'https://i.pinimg.com/736x/2f/bf/02/2fbf02248319c6e9152b079234b63fa4.jpg',
      trailerUrl: 'https://youtu.be/6ZfuNTqbHE8?si=ZGQ060LPpVLWznUg',
    ),
    Film(
      id: '3',
      title: 'Avenger End Game',
      genre: 'Action, Adventure',
      duration: '1 jam 50 menit',
      rating: '8.8',
      director: 'Jeff Fowler',
      ageRating: 'SU',
      imageUrl:
          'https://i.pinimg.com/1200x/91/e8/b2/91e8b28b4cb04f5bd07d7fcd3bf08e16.jpg',
      trailerUrl: 'https://youtu.be/TcMBFSGVi1c?si=4ypF0bxKdsvDR63p',
    ),
    Film(
      id: '4',
      title: 'Black Panther',
      genre: 'Animation, Adventure',
      duration: '1 jam 58 menit',
      rating: '9.0',
      director: 'Barry Jenkins',
      ageRating: 'SU',
      imageUrl:
          'https://i.pinimg.com/1200x/94/ea/8e/94ea8e36ed6403d1979f7e3890d9d8fa.jpg',
      trailerUrl: 'https://youtu.be/xjDjIWPwcPU?si=zNV5eHf35ibCkan2',
    ),
    Film(
      id: '5',
      title: 'Pengabdi Setan',
      genre: 'Horor',
      duration: '2 jam 40 menit',
      rating: '9.2',
      director: 'Jon M. Chu',
      ageRating: 'R 13+',
      imageUrl:
          'https://i.pinimg.com/736x/1d/08/d5/1d08d56fc156d4a3e1d1bc5de518e7dd.jpg',
      trailerUrl: 'https://youtu.be/0hSptYxWB3E?si=LMJAF08cjrPyKGUh',
    ),
    Film(
      id: '6',
      title: 'Ejen Ali the movie 2',
      genre: 'Action, animation',
      duration: '2 jam 28 menit',
      rating: '8.5',
      director: 'Ridley Scott',
      ageRating: 'D 17+',
      imageUrl:
          'https://i.pinimg.com/736x/c1/f8/5a/c1f85a944ae734a70ae73760c40e19a3.jpg',
      trailerUrl: 'https://youtu.be/5nD1LWmAeKc?si=0EpOXy68EWCgqVND',
    ),
  ];

  static void addFilm(Film film) {
    _films.add(film);
  }

  static List<Film> getAllFilms() {
    return List.unmodifiable(_films);
  }

  static Film? getFilmById(String id) {
    try {
      return _films.firstWhere((film) => film.id == id);
    } catch (e) {
      return null;
    }
  }

  static bool updateFilm(Film updatedFilm) {
    final index = _films.indexWhere((film) => film.id == updatedFilm.id);
    if (index != -1) {
      _films[index] = updatedFilm;
      return true;
    }
    return false;
  }

  static bool deleteFilm(String id) {
    final index = _films.indexWhere((film) => film.id == id);
    if (index != -1) {
      _films.removeAt(index);
      return true;
    }
    return false;
  }
}

// ==================== TICKET HISTORY SERVICE (UPDATE) ====================

// ==================== TICKET HISTORY SERVICE (UPDATE) ====================

class TicketHistoryService {
  static final List<TicketHistory> _history = [];

  static void addTicket(TicketHistory ticket) {
    _history.insert(0, ticket);
  }

  static List<TicketHistory> getActiveTickets() {
    final currentUser = AuthService.getCurrentUsername();
    if (currentUser == null) return [];

    return _history
        .where((ticket) =>
            ticket.status == 'active' && ticket.userId == currentUser)
        .toList();
  }

  static List<TicketHistory> getUsedTickets() {
    final currentUser = AuthService.getCurrentUsername();
    if (currentUser == null) return [];

    return _history
        .where(
            (ticket) => ticket.status == 'used' && ticket.userId == currentUser)
        .toList();
  }

  static TicketHistory? getTicketById(String id) {
    try {
      return _history.firstWhere((ticket) => ticket.id == id);
    } catch (e) {
      return null;
    }
  }

  // ✅ TAMBAHAN UNTUK ADMIN
  static List<TicketHistory> getAllTickets() {
    return List.unmodifiable(_history);
  }

  static List<TicketHistory> getTicketsByUserId(String userId) {
    return _history.where((ticket) => ticket.userId == userId).toList();
  }
}

// ==================== SEAT SERVICE ====================

const String MOCKAPI_URL = 'https://68f11ba50b966ad5003567dd.mockapi.io';

class SeatService {
  static Future<List<Map<String, dynamic>>> getSeats({
    required String filmId,
    required String cinema,
    required String date,
    required String time,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$MOCKAPI_URL/seats?filmId=$filmId&cinema=$cinema&date=$date&time=$time'),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        print('Loaded ${data.length} seats from API');
        return data.cast<Map<String, dynamic>>();
      }
      print('Failed to load seats: ${response.statusCode}');
      return [];
    } catch (e) {
      print('Error getting seats: $e');
      return [];
    }
  }

  static Future<bool> selectSeat({
    required String seatId,
    required String userId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$MOCKAPI_URL/seats/$seatId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'status': 'selected',
          'userId': userId,
        }),
      );
      print('Select seat $seatId: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error selecting seat: $e');
      return false;
    }
  }

  static Future<bool> unselectSeat({required String seatId}) async {
    try {
      final response = await http.put(
        Uri.parse('$MOCKAPI_URL/seats/$seatId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'status': 'available',
          'userId': null,
        }),
      );
      print('Unselect seat $seatId: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error unselecting seat: $e');
      return false;
    }
  }

  static Future<bool> bookSeats({
    required List<String> seatIds,
    required String userId,
    required String filmId,
    required String cinema,
    required String date,
    required String time,
  }) async {
    try {
      for (String seatId in seatIds) {
        await http.put(
          Uri.parse('$MOCKAPI_URL/seats/$seatId'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'status': 'booked',
            'userId': userId,
          }),
        );
      }

      for (String seatId in seatIds) {
        await http.post(
          Uri.parse('$MOCKAPI_URL/bookings'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'filmId': filmId,
            'cinema': cinema,
            'date': date,
            'time': time,
            'seatId': seatId,
            'userId': userId,
            'status': 'booked',
            'createdAt': DateTime.now().toIso8601String(),
          }),
        );
      }

      print('Booking completed for ${seatIds.length} seats');
      return true;
    } catch (e) {
      print('Error booking seats: $e');
      return false;
    }
  }

  static Future<void> initializeSeats({
    required String filmId,
    required String cinema,
    required String date,
    required String time,
  }) async {
    final List<List<String>> seatLayout = [
      ['A7', 'A6', 'A5', 'A4', '', '', 'A3', 'A2', 'A1'],
      ['B7', 'B6', 'B5', 'B4', '', '', 'B3', 'B2', 'B1'],
      ['C7', 'C6', 'C5', 'C4', '', '', 'C3', 'C2', 'C1'],
      ['D7', 'D6', 'D5', 'D4', '', '', 'D3', 'D2', 'D1'],
      ['E7', 'E6', 'E5', 'E4', '', '', 'E3', 'E2', 'E1'],
      ['F7', 'F6', 'F5', 'F4', '', '', 'F3', 'F2', 'F1'],
      ['G7', 'G6', 'G5', 'G4', '', '', 'G3', 'G2', 'G1'],
      ['H7', 'H6', 'H5', 'H4', '', '', 'H3', 'H2', 'H1'],
    ];

    print('Initializing seats for $cinema on $date at $time...');

    for (var row in seatLayout) {
      for (var seat in row) {
        if (seat.isNotEmpty) {
          try {
            final response = await http.post(
              Uri.parse('$MOCKAPI_URL/seats'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'filmId': filmId,
                'cinema': cinema,
                'date': date,
                'time': time,
                'seatNumber': seat,
                'status': 'available',
                'userId': null,
              }),
            );

            if (response.statusCode == 201) {
              print('Seat $seat initialized successfully');
            }
          } catch (e) {
            print('Error initializing seat $seat: $e');
          }
        }
      }
    }

    print('Seat initialization completed!');
  }
}

class WatchlistService {
  static final Map<String, List<String>> _watchlists = {};

  static void addToWatchlist(String userId, String filmId) {
    if (!_watchlists.containsKey(userId)) {
      _watchlists[userId] = [];
    }
    if (!_watchlists[userId]!.contains(filmId)) {
      _watchlists[userId]!.add(filmId);
    }
  }

  static void removeFromWatchlist(String userId, String filmId) {
    if (_watchlists.containsKey(userId)) {
      _watchlists[userId]!.remove(filmId);
    }
  }

  static bool isInWatchlist(String userId, String filmId) {
    if (!_watchlists.containsKey(userId)) return false;
    return _watchlists[userId]!.contains(filmId);
  }

  static List<Film> getWatchlistFilms(String userId) {
    if (!_watchlists.containsKey(userId)) return [];

    List<Film> films = [];
    for (String filmId in _watchlists[userId]!) {
      Film? film = FilmService.getFilmById(filmId);
      if (film != null) {
        films.add(film);
      }
    }
    return films;
  }

  static int getWatchlistCount(String userId) {
    if (!_watchlists.containsKey(userId)) return 0;
    return _watchlists[userId]!.length;
  }
}

class WatchlistPage extends StatefulWidget {
  const WatchlistPage({Key? key}) : super(key: key);

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  List<Film> watchlistFilms = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWatchlist();
  }

  void _loadWatchlist() {
    setState(() {
      isLoading = true;
    });

    final userId = AuthService.getCurrentUsername();
    if (userId != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            watchlistFilms = WatchlistService.getWatchlistFilms(userId);
            isLoading = false;
          });
        }
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _removeFromWatchlist(Film film) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = AuthService.getCurrentUsername();
    if (userId == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 22),
            SizedBox(width: 8),
            Text('Hapus dari Watchlist?'),
          ],
        ),
        content: Text(
            'Apakah Anda yakin ingin menghapus "${film.title}" dari watchlist?',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              WatchlistService.removeFromWatchlist(userId, film.id);
              Navigator.pop(context);
              _loadWatchlist();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text('${film.title} dihapus dari watchlist'),
                    ],
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            },
            icon: const Icon(Icons.delete, color: Colors.white),
            label: const Text('Hapus', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color:
                  isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(Icons.favorite, color: Colors.red, size: 22),
            const SizedBox(width: 8),
            Text(
              'My Watchlist',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF001A4D),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          if (watchlistFilms.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(
                    '${watchlistFilms.length} Film',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: isDark
                      ? const Color(0xFFFFB800)
                      : const Color(0xFF001A4D)),
            )
          : watchlistFilms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border,
                          size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Watchlist Kosong',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tambahkan film favorit Anda ke watchlist',
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.movie, color: Colors.white),
                        label: const Text('Jelajahi Film',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFFFFB800)
                              : const Color(0xFF001A4D),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    _loadWatchlist();
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: watchlistFilms.length,
                    itemBuilder: (context, index) {
                      final film = watchlistFilms[index];
                      return _buildWatchlistCard(film);
                    },
                  ),
                ),
    );
  }

  Widget _buildWatchlistCard(Film film) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FilmDetailPage(
              film: film,
              onUpdate: _loadWatchlist,
            ),
          ),
        ).then((_) => _loadWatchlist());
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: Image.network(
                      film.imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFDDDDDD),
                          alignment: Alignment.center,
                          child: const Icon(Icons.movie,
                              size: 40, color: Colors.white),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB800),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 12, color: Colors.white),
                          const SizedBox(width: 2),
                          Text(
                            film.rating,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: () => _removeFromWatchlist(film),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.favorite,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    film.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    film.genre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? Colors.grey.shade400
                          : const Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isDark
                              ? const Color(0xFFFFB800)
                              : const Color(0xFF001A4D))
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      film.ageRating,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFFFB800)
                            : const Color(0xFF001A4D),
                      ),
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
}

class NotificationService {
  static final List<NotificationItem> _notifications = [];

  static void addNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) {
    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: title,
      message: message,
      type: type,
      createdAt: DateTime.now(),
      data: data,
    );
    _notifications.insert(0, notification);

    print('🔔 Notification Added: $title');
    print('   User: $userId');
    print('   Total Notifications: ${_notifications.length}');
  }

  static List<NotificationItem> getUserNotifications(String userId) {
    return _notifications.where((notif) => notif.userId == userId).toList();
  }

  static int getUnreadCount(String userId) {
    return _notifications
        .where((notif) => notif.userId == userId && !notif.isRead)
        .length;
  }

  static void markAsRead(String notificationId) {
    try {
      final notification =
          _notifications.firstWhere((n) => n.id == notificationId);
      notification.isRead = true;
    } catch (e) {
      print('Notification not found: $notificationId');
    }
  }

  static void markAllAsRead(String userId) {
    for (var notification in _notifications) {
      if (notification.userId == userId) {
        notification.isRead = true;
      }
    }
  }

  static void clearNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
  }

  static void clearAllNotifications(String userId) {
    _notifications.removeWhere((n) => n.userId == userId);
  }
}

class AdminNotificationService {
  static final List<AdminNotificationItem> _notifications = [];

  // ✅ CALLBACK UNTUK OVERLAY NOTIFICATION
  static Function(AdminNotificationItem)? onNotificationAdded;

  static void addNotification({
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) {
    final notification = AdminNotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      createdAt: DateTime.now(),
      data: data,
    );
    _notifications.insert(0, notification);

    print('🔔 Admin Notification Added: $title');
    print('   Total Admin Notifications: ${_notifications.length}');

    // ✅ TRIGGER OVERLAY NOTIFICATION
    if (onNotificationAdded != null) {
      onNotificationAdded!(notification);
    }
  }

  static List<AdminNotificationItem> getAllNotifications() {
    return List.unmodifiable(_notifications);
  }

  static int getUnreadCount() {
    return _notifications.where((notif) => !notif.isRead).length;
  }

  static void markAsRead(String notificationId) {
    try {
      final notification =
          _notifications.firstWhere((n) => n.id == notificationId);
      notification.isRead = true;
    } catch (e) {
      print('Notification not found: $notificationId');
    }
  }

  static void markAllAsRead() {
    for (var notification in _notifications) {
      notification.isRead = true;
    }
  }

  static void clearNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
  }

  static void clearAllNotifications() {
    _notifications.clear();
  }
}

// ==================== CHAT SERVICE ====================

class ChatConversation {
  final String id;
  final String userId;
  final String userName;
  final List<ChatMessageData> messages;
  DateTime lastMessageTime;
  bool hasUnreadAdmin; // untuk admin
  bool hasUnreadUser; // untuk user

  ChatConversation({
    required this.id,
    required this.userId,
    required this.userName,
    required this.messages,
    required this.lastMessageTime,
    this.hasUnreadAdmin = false,
    this.hasUnreadUser = false,
  });
}

class ChatMessageData {
  final String id;
  final String text;
  final bool isFromUser;
  final DateTime timestamp;
  bool isRead;

  ChatMessageData({
    required this.id,
    required this.text,
    required this.isFromUser,
    required this.timestamp,
    this.isRead = false,
  });
}

class ChatService {
  static final Map<String, ChatConversation> _conversations = {};

  // Callback untuk notifikasi real-time
  static Function(String userId)? onNewMessageForAdmin;
  static Function(String userId)? onNewMessageForUser;

  // User kirim pesan
  static void sendMessageFromUser({
    required String userId,
    required String userName,
    required String message,
  }) {
    final conversationId = userId;

    if (!_conversations.containsKey(conversationId)) {
      _conversations[conversationId] = ChatConversation(
        id: conversationId,
        userId: userId,
        userName: userName,
        messages: [],
        lastMessageTime: DateTime.now(),
      );
    }

    // Baris 1268-1274
    final newMessage = ChatMessageData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: message,
      isFromUser: true, // ✅ User yang mengirim
      timestamp: DateTime.now(),
      isRead: false,
    );

    _conversations[conversationId]!.messages.add(newMessage);
    _conversations[conversationId]!.lastMessageTime = DateTime.now();
    _conversations[conversationId]!.hasUnreadAdmin = true;

    // Notifikasi untuk admin
    AdminNotificationService.addNotification(
      title: '💬 Pesan Baru dari $userName',
      message: message.length > 50 ? '${message.substring(0, 50)}...' : message,
      type: 'chat',
      data: {
        'userId': userId,
        'userName': userName,
        'messageId': newMessage.id,
      },
    );

    // Trigger callback
    if (onNewMessageForAdmin != null) {
      onNewMessageForAdmin!(userId);
    }

    print('');
    print('═══════════════════════════════════════');
    print('💬 NEW MESSAGE FROM USER');
    print('═══════════════════════════════════════');
    print('User: $userName ($userId)');
    print('Message: $message');
    print('Time: ${DateTime.now()}');
    print('═══════════════════════════════════════');
    print('');
  }

  // Admin kirim pesan
  static void sendMessageFromAdmin({
    required String userId,
    required String message,
  }) {
    if (!_conversations.containsKey(userId)) {
      print('❌ Conversation not found for user: $userId');
      return;
    }

    final newMessage = ChatMessageData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: message,
      isFromUser: false,
      timestamp: DateTime.now(),
      isRead: false,
    );

    _conversations[userId]!.messages.add(newMessage);
    _conversations[userId]!.lastMessageTime = DateTime.now();
    _conversations[userId]!.hasUnreadUser = true;
    _conversations[userId]!.hasUnreadAdmin = false;

    // Notifikasi untuk user
    NotificationService.addNotification(
      userId: userId,
      title: '💬 Balasan dari Admin',
      message: message.length > 50 ? '${message.substring(0, 50)}...' : message,
      type: 'info',
      data: {
        'messageId': newMessage.id,
      },
    );

    // Trigger callback
    if (onNewMessageForUser != null) {
      onNewMessageForUser!(userId);
    }

    print('');
    print('═══════════════════════════════════════');
    print('💬 NEW MESSAGE FROM ADMIN');
    print('═══════════════════════════════════════');
    print('To User: $userId');
    print('Message: $message');
    print('Time: ${DateTime.now()}');
    print('═══════════════════════════════════════');
    print('');
  }

  // Get conversation untuk user tertentu
  static ChatConversation? getConversation(String userId) {
    return _conversations[userId];
  }

  // Get semua conversations (untuk admin)
  static List<ChatConversation> getAllConversations() {
    final conversations = _conversations.values.toList();
    conversations
        .sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    return conversations;
  }

  // Get unread count untuk admin
  static int getUnreadCountForAdmin() {
    return _conversations.values.where((conv) => conv.hasUnreadAdmin).length;
  }

  // Get unread count untuk user tertentu
  static int getUnreadCountForUser(String userId) {
    final conv = _conversations[userId];
    if (conv == null) return 0;
    return conv.hasUnreadUser ? 1 : 0;
  }

  // Mark as read untuk admin
  static void markAsReadByAdmin(String userId) {
    if (_conversations.containsKey(userId)) {
      _conversations[userId]!.hasUnreadAdmin = false;
      for (var msg in _conversations[userId]!.messages) {
        if (msg.isFromUser) {
          msg.isRead = true;
        }
      }
    }
  }

  // Mark as read untuk user
  static void markAsReadByUser(String userId) {
    if (_conversations.containsKey(userId)) {
      _conversations[userId]!.hasUnreadUser = false;
      for (var msg in _conversations[userId]!.messages) {
        if (!msg.isFromUser) {
          msg.isRead = true;
        }
      }
    }
  }

  // Clear conversation
  static void clearConversation(String userId) {
    _conversations.remove(userId);
  }

  // Get last message preview
  static String getLastMessagePreview(String userId) {
    final conv = _conversations[userId];
    if (conv == null || conv.messages.isEmpty) {
      return 'Belum ada pesan';
    }
    final lastMsg = conv.messages.last;
    return lastMsg.text.length > 30
        ? '${lastMsg.text.substring(0, 30)}...'
        : lastMsg.text;
  }
}

class OverlayNotificationManager {
  static OverlayEntry? _currentOverlay;
  static Timer? _timer;

  static void showNotification(
    BuildContext context,
    AdminNotificationItem notification,
  ) {
    // Hapus notifikasi sebelumnya jika ada
    removeNotification();

    _currentOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: -100.0, end: 0.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, value),
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFB800),
                    const Color(0xFFFFB800).withValues(alpha: 0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.admin_panel_settings,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'ADMIN NOTIFICATION',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notification.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => removeNotification(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);

    // Auto hide setelah 5 detik
    _timer = Timer(const Duration(seconds: 120), () {
      removeNotification();
    });
  }

  static void removeNotification() {
    _timer?.cancel();
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}
// ==================== LOGIN PAGE ====================
// ==================== LOGIN PAGE ====================

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  void _handleLogin() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showDialog('Error', 'Username dan password harus diisi!');
      return;
    }

    setState(() => _isLoading = true);

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      final isAuthenticated = AuthService.authenticate(username, password);

      setState(() => _isLoading = false);

      if (isAuthenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        _showDialog('Error', 'Username atau password salah!');
      }
    });
  }

  void _showDialog(String title, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(title,
            style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: Text(message,
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),

              // Header Logo
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E1E1E)
                      : const Color(0xfffbfcfd),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2A2A2A)
                                : const Color(0xffffffff),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: (isDark
                                        ? const Color(0xFFFFB800)
                                        : const Color(0xfffcfdfe))
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.local_movies,
                            color: isDark
                                ? const Color(0xFFFFB800)
                                : const Color(0xFFFFB800),
                            size: 36,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'CINEMA 1',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFFFFB800)
                                : const Color(0xff13013b),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cinema Booking System',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey.shade400
                            : const Color(0xFF666666),
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              Text(
                'Masuk ke CINEMA 1',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xff0a0118),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Username Field
              Text(
                'USERNAME',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey.shade400 : Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'Masukkan username',
                  hintStyle: TextStyle(
                      color:
                          isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFFFFB800)
                            : const Color(0xFF001A4D)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // Password Field
              Text(
                'PASSWORD',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey.shade400 : Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'Masukkan Password',
                  hintStyle: TextStyle(
                      color:
                          isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFFFFB800)
                            : const Color(0xFF001A4D)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: isDark ? Colors.grey.shade400 : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible =
                            !_isPasswordVisible; // NO COMMA HERE
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Reset Password',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFFFB800)
                          : const Color(0xFF001A4D),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Login Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFFFFB800)
                      : const Color(0xFF001A4D),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Masuk',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),

              const SizedBox(height: 16),

              // Admin Button
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFB800).withValues(alpha: 0.1),
                      const Color(0xFFFFB800).withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFFB800),
                    width: 2,
                  ),
                ),
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminLoginPage(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.admin_panel_settings,
                    color: Color(0xFFFFB800),
                    size: 22,
                  ),
                  label: const Text(
                    'Login sebagai Admin',
                    style: TextStyle(
                      color: Color(0xFFFFB800),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Register Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Belum punya akun? ',
                      style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.black)),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RegisterPage()),
                      );
                    },
                    child: Text(
                      'Daftar Sekarang',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFFFB800)
                            : const Color(0xFF001A4D),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// ==================== REGISTER PAGE ====================

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  void _handleRegister() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showDialog('Error', 'Semua field harus diisi!');
      return;
    }

    if (username.length < 3) {
      _showDialog('Error', 'Username minimal 3 karakter!');
      return;
    }

    if (password.length < 3) {
      _showDialog('Error', 'Password minimal 3 karakter!');
      return;
    }

    if (password != confirmPassword) {
      _showDialog('Error', 'Password tidak cocok!');
      return;
    }

    setState(() => _isLoading = true);

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      final success = AuthService.register(username, password);

      setState(() => _isLoading = false);

      if (success) {
        _showDialog(
          'Berhasil',
          'Akun berhasil dibuat! Silakan login.',
          onOk: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
        );
      } else {
        _showDialog('Error', 'Username sudah digunakan!');
      }
    });
  }

  void _showDialog(String title, String message, {VoidCallback? onOk}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(title,
            style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: Text(message,
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onOk != null) onOk();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color:
                  isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E1E1E)
                      : const Color(0xfffbfcfd),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'CINEMA 1',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFFFFB800)
                        : const Color(0xff050644),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Daftar Akun Baru',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF001A4D),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Text(
                'USERNAME',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey.shade400 : Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'Masukkan username',
                  hintStyle: TextStyle(
                      color:
                          isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFFFFB800)
                            : const Color(0xFF001A4D)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'PASSWORD',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey.shade400 : Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'Masukkan password',
                  hintStyle: TextStyle(
                      color:
                          isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFFFFB800)
                            : const Color(0xFF001A4D)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: isDark ? Colors.grey.shade400 : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'KONFIRMASI PASSWORD',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey.shade400 : Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'Konfirmasi password',
                  hintStyle: TextStyle(
                      color:
                          isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFFFFB800)
                            : const Color(0xFF001A4D)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: isDark ? Colors.grey.shade400 : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFFFFB800)
                      : const Color(0xFF001A4D),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Daftar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Sudah punya akun? ',
                      style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.black)),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFFFB800)
                            : const Color(0xFF001A4D),
                        fontWeight: FontWeight.bold,
                      ),
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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

class HomePage extends StatefulWidget {
  final int initialTab;
  const HomePage({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int selectedTab;
  String selectedCity = 'JAKARTA';
  final searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Film> filteredFilms = [];
  List<String> favoriteCinemas = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _filmSectionKey = GlobalKey();

  // PageController untuk carousel
  late PageController _pageController;
  double _currentPage = 0;

  final List<String> cinemas = [
    'AEON MALL JGC CGV',
    'AEON MALL TANJUNG BARAT XXI',
    'AGORA MALL IMAX',
    'AGORA MALL PREMIERE',
    'CGV GRAND INDONESIA',
    'CINEPOLIS PLAZA SENAYAN',
    'XXI PLAZA INDONESIA',
  ];

  @override
  void initState() {
    super.initState();
    selectedTab = widget.initialTab;
    _loadFilms();

    // Initialize PageController
    _pageController = PageController(
      viewportFraction: 0.8,
      initialPage: 0,
    );

    // Listen to page changes
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0;
      });
    });
  }

  void _loadFilms() {
    setState(() {
      filteredFilms = FilmService.getAllFilms();
    });
  }

  void _searchFilms(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredFilms = FilmService.getAllFilms();
      } else {
        filteredFilms = FilmService.getAllFilms()
            .where((film) =>
                film.title.toLowerCase().contains(query.toLowerCase()) ||
                film.genre.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
    if (query.isNotEmpty && filteredFilms.isNotEmpty) {
      _scrollToFilmSection();
    }
  }

  void _scrollToFilmSection() {
    if (_filmSectionKey.currentContext != null) {
      Scrollable.ensureVisible(
        _filmSectionKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
    }
  }

  void _toggleFavoriteCinema(String cinema) {
    setState(() {
      if (favoriteCinemas.contains(cinema)) {
        favoriteCinemas.remove(cinema);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.delete_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('$cinema dihapus dari favorit'),
          ]),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.red.shade600,
        ));
      } else {
        favoriteCinemas.add(cinema);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.star, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('$cinema ditambahkan ke favorit'),
          ]),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.green.shade600,
        ));
      }
    });
  }

  List<String> _getSortedCinemas() {
    List<String> sorted = List.from(cinemas);
    sorted.sort((a, b) {
      bool aIsFav = favoriteCinemas.contains(a);
      bool bIsFav = favoriteCinemas.contains(b);
      if (aIsFav && !bIsFav) return -1;
      if (!aIsFav && bIsFav) return 1;
      return 0;
    });
    return sorted;
  }

  void _showCinemaSelectionDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade700 : const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              const Icon(Icons.location_on, color: Color(0xFFFFB800), size: 28),
              const SizedBox(width: 12),
              Text('Pilih Bioskop Favorit',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  )),
            ]),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Tandai bioskop favorit untuk akses lebih cepat',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isDark ? Colors.grey.shade400 : const Color(0xFF666666),
                )),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: cinemas.length,
              itemBuilder: (context, index) {
                final cinema = cinemas[index];
                final isFavorite = favoriteCinemas.contains(cinema);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isFavorite
                          ? const Color(0xFFFFB800)
                          : (isDark
                              ? Colors.grey.shade700
                              : const Color(0xFFDDDDDD)),
                      width: isFavorite ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: isFavorite
                        ? (isDark
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFFFFF8E1))
                        : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isFavorite
                            ? const Color(0xFFFFB800).withValues(alpha: 0.2)
                            : (isDark
                                ? Colors.grey.shade800
                                : const Color(0xFFEEEEEE)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isFavorite ? Icons.star : Icons.star_outline,
                        color: isFavorite
                            ? const Color(0xFFFFB800)
                            : (isDark
                                ? Colors.grey.shade600
                                : const Color(0xFFCCCCCC)),
                        size: 24,
                      ),
                    ),
                    title: Text(cinema,
                        style: TextStyle(
                          fontWeight:
                              isFavorite ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black,
                        )),
                    trailing: isFavorite
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB800),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check,
                                    size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text('Favorit',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    )),
                              ],
                            ),
                          )
                        : null,
                    onTap: () => _toggleFavoriteCinema(cinema),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(
                      color: isDark
                          ? Colors.grey.shade800
                          : const Color(0xFFDDDDDD))),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check_circle,
                    size: 20, color: Colors.white),
                label: const Text('SELESAI',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF001A4D),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu,
              color: isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D),
              size: 28),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          tooltip: 'Menu',
        ),
        title: Row(children: [
          Icon(Icons.movie,
              color: isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D),
              size: 24),
          const SizedBox(width: 8),
          Text('cinema 1',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF001A4D),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              )),
        ]),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined,
                    color: isDark
                        ? const Color(0xFFFFB800)
                        : const Color(0xFF001A4D),
                    size: 26),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationPage(),
                    ),
                  ).then((_) => setState(() {}));
                },
                tooltip: 'Notifikasi',
              ),
              if (NotificationService.getUnreadCount(
                      AuthService.getCurrentUsername() ?? '') >
                  0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${NotificationService.getUnreadCount(AuthService.getCurrentUsername() ?? '')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.account_circle_outlined,
                color:
                    isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D),
                size: 26),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()));
            },
            tooltip: 'Profil',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: selectedTab == 0
          ? _buildBerandaTab()
          : selectedTab == 1
              ? const TicketHistoryPage()
              : const ProfilePage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedTab,
        selectedItemColor:
            isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D),
        unselectedItemColor: const Color(0xFFCCCCCC),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 26),
            activeIcon: Icon(Icons.home, size: 28),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number_outlined, size: 26),
            activeIcon: Icon(Icons.confirmation_number, size: 28),
            label: 'Tiket',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 26),
            activeIcon: Icon(Icons.person, size: 28),
            label: 'Profil',
          ),
        ],
        onTap: (index) {
          setState(() => selectedTab = index);
        },
      ),
    );
  }

  Widget _buildDrawer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProfile = AuthService.getCurrentUserProfile();
    final activeTickets = TicketHistoryService.getActiveTickets();

    return Drawer(
      child: Container(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF2A2A2A), const Color(0xFF1E1E1E)]
                      : [
                          const Color(0xFF001A4D),
                          const Color(0xFF0066CC).withValues(alpha: 0.8)
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: userProfile?.profileImageUrl.isNotEmpty == true
                    ? ClipOval(
                        child: Image.network(
                          userProfile!.profileImageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.person,
                                size: 40,
                                color: isDark
                                    ? const Color(0xFFFFB800)
                                    : const Color(0xFF001A4D));
                          },
                        ),
                      )
                    : Icon(Icons.person,
                        size: 40,
                        color: isDark
                            ? const Color(0xFFFFB800)
                            : const Color(0xFF001A4D)),
              ),
              accountName: Text(
                userProfile?.name ?? 'Pengguna',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              accountEmail: Text(
                userProfile?.phoneNumber ?? '',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0F8FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDark
                        ? const Color(0xFFFFB800)
                        : const Color(0xFF0066CC)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Icon(Icons.confirmation_number,
                          color: isDark
                              ? const Color(0xFFFFB800)
                              : const Color(0xFF0066CC),
                          size: 28),
                      const SizedBox(height: 8),
                      Text(
                        '${activeTickets.length}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFFFFB800)
                              : const Color(0xFF0066CC),
                        ),
                      ),
                      Text(
                        'Tiket Aktif',
                        style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.grey.shade400
                                : const Color(0xFF666666)),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color:
                        isDark ? Colors.grey.shade700 : const Color(0xFFDDDDDD),
                  ),
                  Column(
                    children: [
                      Icon(Icons.history,
                          color: isDark
                              ? Colors.grey.shade400
                              : const Color(0xFF666666),
                          size: 28),
                      const SizedBox(height: 8),
                      Text(
                        '${TicketHistoryService.getUsedTickets().length}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.grey.shade400
                              : const Color(0xFF666666),
                        ),
                      ),
                      Text(
                        'Riwayat',
                        style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.grey.shade400
                                : const Color(0xFF666666)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            _buildDrawerItem(
              icon: Icons.home,
              title: 'Beranda',
              onTap: () {
                Navigator.pop(context);
                setState(() => selectedTab = 0);
              },
            ),
            _buildDrawerItem(
              icon: Icons.confirmation_number,
              title: 'Tiket Saya',
              badge: activeTickets.length,
              onTap: () {
                Navigator.pop(context);
                setState(() => selectedTab = 1);
              },
            ),
            _buildDrawerItem(
              icon: Icons.notifications,
              title: 'Notifikasi',
              badge: NotificationService.getUnreadCount(
                  AuthService.getCurrentUsername() ?? ''),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationPage(),
                  ),
                ).then((_) => setState(() {}));
              },
            ),
            const Divider(),
            _buildDrawerItem(
              icon: Icons.person,
              title: 'Profil Saya',
              onTap: () {
                Navigator.pop(context);
                setState(() => selectedTab = 2);
              },
            ),
            const Divider(),
            _buildDrawerItem(
              icon: Icons.favorite,
              title: 'Watchlist',
              badge: WatchlistService.getWatchlistCount(
                  AuthService.getCurrentUsername() ?? ''),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const WatchlistPage()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.star,
              title: 'Bioskop Favorit',
              onTap: () {
                Navigator.pop(context);
                _showCinemaSelectionDialog();
              },
            ),
            _buildDrawerItem(
              icon: Icons.settings,
              title: 'Pengaturan',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.help,
              title: 'Bantuan',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HelpPage()),
                );
              },
            ),
            const Divider(),
            _buildDrawerItem(
              icon: Icons.logout,
              title: 'Keluar',
              textColor: Colors.red,
              iconColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF1E1E1E)
                            : Colors.white,
                    title: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red, size: 22),
                        SizedBox(width: 8),
                        Text('Keluar'),
                      ],
                    ),
                    content: const Text('Apakah Anda yakin ingin keluar?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          AuthService.logout();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginPage()),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: const Text('Keluar',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'CINEMA 1 v1.0.0',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
    int? badge,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon,
              color: iconColor ??
                  (isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D)),
              size: 24),
          if (badge != null && badge > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  badge > 99 ? '99+' : badge.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor ?? (isDark ? Colors.white : Colors.black87),
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildBerandaTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      controller: _scrollController,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: searchController,
            onChanged: _searchFilms,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'Cari film di cinema 1',
              hintStyle: TextStyle(
                  color:
                      isDark ? Colors.grey.shade600 : const Color(0xFF666666)),
              prefixIcon: Icon(Icons.search,
                  color:
                      isDark ? Colors.grey.shade600 : const Color(0xFF666666)),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close,
                          color: isDark
                              ? Colors.grey.shade600
                              : const Color(0xFF666666)),
                      onPressed: () {
                        searchController.clear();
                        _searchFilms('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(
                    color: isDark
                        ? Colors.grey.shade800
                        : const Color(0xFFDDDDDD)),
              ),
              filled: true,
              fillColor:
                  isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Icon(Icons.location_on, color: Color(0xFFFFB800), size: 24),
            DropdownButton<String>(
              value: selectedCity,
              dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              items: ['JAKARTA', 'BANDUNG', 'SURABAYA']
                  .map((city) =>
                      DropdownMenuItem(value: city, child: Text(city)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedCity = value ?? 'JAKARTA';
                });
              },
              underline: Container(),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F8FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color:
                    isDark ? const Color(0xFFFFB800) : const Color(0xFF0066CC),
                width: 1),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB800),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.star, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tandai bioskop favoritmu!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black,
                        )),
                    const SizedBox(height: 4),
                    Text('Akses bioskop favorit dengan lebih cepat',
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.grey.shade400
                                : const Color(0xFF666666))),
                  ]),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _showCinemaSelectionDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Pilih',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  )),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _getSortedCinemas().length,
            itemBuilder: (context, index) {
              final cinema = _getSortedCinemas()[index];
              final isFavorite = favoriteCinemas.contains(cinema);
              return GestureDetector(
                onTap: () => _toggleFavoriteCinema(cinema),
                child: Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isFavorite
                          ? const Color(0xFFFFB800)
                          : (isDark
                              ? Colors.grey.shade800
                              : const Color(0xFFDDDDDD)),
                      width: isFavorite ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: isFavorite
                        ? (isDark
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFFFFF8E1))
                        : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isFavorite
                                    ? const Color(0xFFFFB800)
                                        .withValues(alpha: 0.2)
                                    : (isDark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                isFavorite ? Icons.star : Icons.star_outline,
                                size: 16,
                                color: isFavorite
                                    ? const Color(0xFFFFB800)
                                    : (isDark
                                        ? Colors.grey.shade600
                                        : const Color(0xFFCCCCCC)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(cinema,
                                  style: TextStyle(
                                    fontWeight: isFavorite
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 12,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ]),
                        ),
                        if (isFavorite)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB800),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.favorite,
                                      color: Colors.white, size: 10),
                                  SizedBox(width: 4),
                                  Text('Favorit',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      )),
                                ],
                              ),
                            ),
                          ),
                      ]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Container(
          key: _filmSectionKey,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(Icons.local_movies,
                    color: isDark
                        ? const Color(0xFFFFB800)
                        : const Color(0xFF001A4D),
                    size: 22),
                const SizedBox(width: 8),
                Text(
                  searchController.text.isEmpty
                      ? 'Sedang Tayang'
                      : 'Hasil Pencarian (${filteredFilms.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ]),
              if (searchController.text.isEmpty)
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AllFilmsPage(onUpdate: _loadFilms),
                      ),
                    );
                  },
                  icon: const Icon(Icons.grid_view, size: 16),
                  label: const Text('Semua'),
                  style: TextButton.styleFrom(
                    foregroundColor: isDark
                        ? const Color(0xFFFFB800)
                        : const Color(0xFF001A4D),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ✅ CAROUSEL FILM DENGAN ANIMASI 3D
        if (filteredFilms.isEmpty)
          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(children: [
              Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('Film tidak ditemukan',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  )),
              const SizedBox(height: 8),
              Text('Coba cari dengan kata kunci lain',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            ]),
          )
        else
          SizedBox(
            height: 480,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: filteredFilms.length,
                  itemBuilder: (context, index) {
                    return _buildCarouselFilmCard(filteredFilms[index], index);
                  },
                ),
                // Left Button
                if (_currentPage > 0)
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.7)
                                : Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.chevron_left,
                            color:
                                isDark ? Colors.white : const Color(0xFF001A4D),
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Right Button
                if (_currentPage < filteredFilms.length - 1)
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.7)
                                : Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.chevron_right,
                            color:
                                isDark ? Colors.white : const Color(0xFF001A4D),
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  // ✅ CAROUSEL FILM CARD DENGAN ANIMASI SCALE
  Widget _buildCarouselFilmCard(Film film, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate scale based on current page position
    double scale = 1.0;
    if (_pageController.hasClients) {
      scale = max(0.85, (1 - ((_currentPage - index).abs() * 0.15)));
    }

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: scale, end: scale),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FilmDetailPage(
                film: film,
                onUpdate: _loadFilms,
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Film Poster
                Positioned.fill(
                  child: Image.network(
                    film.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFDDDDDD),
                        alignment: Alignment.center,
                        child: const Icon(Icons.movie,
                            size: 80, color: Colors.white),
                      );
                    },
                  ),
                ),

                // Gradient Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                // Film Info
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          film.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB800),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star,
                                      size: 16, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    film.rating,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                film.ageRating,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          film.genre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          film.duration,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}

// ==================== ALL FILMS PAGE ====================

class AllFilmsPage extends StatefulWidget {
  final VoidCallback onUpdate;

  const AllFilmsPage({Key? key, required this.onUpdate}) : super(key: key);

  @override
  State<AllFilmsPage> createState() => _AllFilmsPageState();
}

class _AllFilmsPageState extends State<AllFilmsPage> {
  List<Film> films = [];
  List<Film> filteredFilms = [];
  TextEditingController searchController = TextEditingController();
  String selectedGenre = 'Semua';

  final List<String> genres = [
    'Semua',
    'Action',
    'Animation',
    'Fantasy',
    'Horor',
    'Adventure',
  ];

  @override
  void initState() {
    super.initState();
    _loadFilms();
  }

  void _loadFilms() {
    setState(() {
      films = FilmService.getAllFilms();
      filteredFilms = films;
    });
  }

  void _filterFilms() {
    setState(() {
      filteredFilms = films.where((film) {
        final matchesSearch = searchController.text.isEmpty ||
            film.title
                .toLowerCase()
                .contains(searchController.text.toLowerCase()) ||
            film.genre
                .toLowerCase()
                .contains(searchController.text.toLowerCase());

        final matchesGenre = selectedGenre == 'Semua' ||
            film.genre.toLowerCase().contains(selectedGenre.toLowerCase());

        return matchesSearch && matchesGenre;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? Colors.white : const Color(0xFF001A4D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Semua Film',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF001A4D),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onChanged: (value) => _filterFilms(),
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Cari film...',
                hintStyle: TextStyle(
                    color: isDark
                        ? Colors.grey.shade600
                        : const Color(0xFF666666)),
                prefixIcon: Icon(Icons.search,
                    color: isDark
                        ? Colors.grey.shade600
                        : const Color(0xFF666666)),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close,
                            color: isDark
                                ? Colors.grey.shade600
                                : const Color(0xFF666666)),
                        onPressed: () {
                          searchController.clear();
                          _filterFilms();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(
                      color: isDark
                          ? Colors.grey.shade800
                          : const Color(0xFFDDDDDD)),
                ),
                filled: true,
                fillColor:
                    isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Genre Filter
          Container(
            height: 50,
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: genres.length,
              itemBuilder: (context, index) {
                final genre = genres[index];
                final isSelected = selectedGenre == genre;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedGenre = genre;
                    });
                    _filterFilms();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                              ? const Color(0xFFFFB800)
                              : const Color(0xFF001A4D))
                          : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? (isDark
                                ? const Color(0xFFFFB800)
                                : const Color(0xFF001A4D))
                            : (isDark
                                ? Colors.grey.shade700
                                : const Color(0xFFDDDDDD)),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        genre,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Film Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
            child: Row(
              children: [
                Icon(Icons.movie,
                    color: isDark
                        ? const Color(0xFFFFB800)
                        : const Color(0xFF001A4D),
                    size: 20),
                const SizedBox(width: 8),
                Text(
                  'Menampilkan ${filteredFilms.length} film',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Films Grid
          Expanded(
            child: filteredFilms.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Film tidak ditemukan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Coba cari dengan kata kunci lain',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      _loadFilms();
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    color: isDark
                        ? const Color(0xFFFFB800)
                        : const Color(0xFF001A4D),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: filteredFilms.length,
                      itemBuilder: (context, index) {
                        return _buildFilmCard(filteredFilms[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilmCard(Film film) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FilmDetailPage(
              film: film,
              onUpdate: () {
                _loadFilms();
                widget.onUpdate();
              },
            ),
          ),
        ).then((_) => _loadFilms());
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: Image.network(
                      film.imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFDDDDDD),
                          alignment: Alignment.center,
                          child: const Icon(Icons.movie,
                              size: 40, color: Colors.white),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB800),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 12, color: Colors.white),
                          const SizedBox(width: 2),
                          Text(
                            film.rating,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    film.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    film.genre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? Colors.grey.shade400
                          : const Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isDark
                              ? const Color(0xFFFFB800)
                              : const Color(0xFF001A4D))
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      film.ageRating,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFFFB800)
                            : const Color(0xFF001A4D),
                      ),
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

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

// ==================== FILM 3D CARD ====================

class _Film3DCard extends StatelessWidget {
  final Film film;
  final VoidCallback onTap;
  const _Film3DCard({required this.film, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: const Color(0xFF001A4D).withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(children: [
            Positioned.fill(
              child: Image.network(
                film.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFDDDDDD),
                    alignment: Alignment.center,
                    child:
                        const Icon(Icons.movie, size: 60, color: Colors.white),
                  );
                },
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      film.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB800),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(children: [
                          const Icon(Icons.star, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            film.rating,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          film.ageRating,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Text(
                      film.genre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class FilmDetailPage extends StatefulWidget {
  final Film film;
  final VoidCallback onUpdate;

  const FilmDetailPage({
    Key? key,
    required this.film,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<FilmDetailPage> createState() => _FilmDetailPageState();
}

class _FilmDetailPageState extends State<FilmDetailPage>
    with SingleTickerProviderStateMixin {
  String selectedSchedule = '13 Okt';
  String selectedCinema = 'Semua';
  String selectedTime = '';
  String selectedCinemaLocation = '';
  int selectedTab = 1;

  late YoutubePlayerController _youtubeController;
  bool _showTrailer = false;
  late TabController _tabController;
  bool isInWatchlist = false;

  final List<Schedule> schedules = [
    Schedule(date: '24 Nov', day: 'Sen', times: []),
    Schedule(date: '25 Nov', day: 'Sel', times: []),
    Schedule(date: '26 Nov', day: 'Rab', times: []),
    Schedule(date: '27 Nov', day: 'Kam', times: []),
    Schedule(date: '28 Nov', day: 'Jum', times: []),
    Schedule(date: '29 Nov', day: 'Sab', times: []),
    Schedule(date: '30 Nov', day: 'Min', times: []),
  ];

  final List<CinemaLocation> cinemas = [
    CinemaLocation(
        name: 'AEON MALL JGC CGV',
        type: 'CGV',
        times: ['10:00', '13:00', '16:00', '19:00']),
    CinemaLocation(
        name: 'AEON MALL TANJUNG BARAT XXI',
        type: 'XXI',
        times: ['11:00', '14:00', '17:00', '20:00']),
    CinemaLocation(
        name: 'AGORA MALL IMAX',
        type: 'IMAX',
        times: ['12:00', '15:00', '18:00', '21:00']),
    CinemaLocation(
        name: 'AGORA MALL PREMIERE',
        type: 'XXI',
        times: ['10:30', '13:30', '16:30', '19:30']),
    CinemaLocation(
        name: 'CGV GRAND INDONESIA',
        type: 'CGV',
        times: ['11:30', '14:30', '17:30', '20:30']),
    CinemaLocation(
        name: 'CINEPOLIS PLAZA SENAYAN',
        type: 'CINEPOLIS',
        times: ['10:15', '13:15', '16:15', '19:15']),
    CinemaLocation(
        name: 'XXI PLAZA INDONESIA',
        type: 'XXI',
        times: ['12:30', '15:30', '18:30', '21:30']),
  ];

  String? _extractYoutubeId(String url) {
    try {
      if (url.contains('youtu.be/')) {
        final parts = url.split('youtu.be/');
        if (parts.length > 1) {
          String id = parts[1].split('?').first.split('&').first;
          if (id.isNotEmpty) {
            return id;
          }
        }
      }

      if (url.contains('youtube.com') && url.contains('v=')) {
        final uri = Uri.parse(url);
        String? id = uri.queryParameters['v'];
        if (id != null && id.isNotEmpty) {
          return id;
        }
      }

      String? id = YoutubePlayerController.convertUrlToId(url);
      if (id != null && id.isNotEmpty) {
        return id;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  void _initYoutubeController() {
    try {
      String? videoId = _extractYoutubeId(widget.film.trailerUrl);

      if (videoId == null || videoId.isEmpty) {
        videoId = 'JfVOs4VSpmA';
      }

      _youtubeController = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showControls: true,
          mute: false,
          showFullscreenButton: true,
          loop: false,
        ),
      );
    } catch (e) {
      _youtubeController = YoutubePlayerController.fromVideoId(
        videoId: 'JfVOs4VSpmA',
        autoPlay: false,
        params: const YoutubePlayerParams(
          showControls: true,
          mute: false,
          showFullscreenButton: true,
          loop: false,
        ),
      );
    }
  }

  void _checkWatchlistStatus() {
    final userId = AuthService.getCurrentUsername();
    if (userId != null) {
      setState(() {
        isInWatchlist = WatchlistService.isInWatchlist(userId, widget.film.id);
      });
    }
  }

  void _toggleWatchlist() {
    final userId = AuthService.getCurrentUsername();
    if (userId == null) return;

    setState(() {
      if (isInWatchlist) {
        WatchlistService.removeFromWatchlist(userId, widget.film.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.remove_circle_outline,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('${widget.film.title} dihapus dari watchlist'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        WatchlistService.addToWatchlist(userId, widget.film.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.favorite, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('${widget.film.title} ditambahkan ke watchlist'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      isInWatchlist = !isInWatchlist;
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          selectedTab = _tabController.index;
        });
      }
    });

    _initYoutubeController();
    _checkWatchlistStatus();
  }

  void _toggleTrailer() {
    setState(() {
      _showTrailer = !_showTrailer;
    });

    if (_showTrailer) {
      _youtubeController.playVideo();
    } else {
      _youtubeController.pauseVideo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.getCurrentUsername() ?? '';
    final watchlistCount = WatchlistService.getWatchlistCount(userId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: _showTrailer ? 300 : 250,
            pinned: true,
            backgroundColor:
                isDark ? const Color(0xFF1E1E1E) : const Color(0xFF001A4D),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (_showTrailer)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                  onPressed: () {
                    _toggleTrailer();
                  },
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (_showTrailer)
                    Padding(
                      padding: const EdgeInsets.only(top: 56),
                      child: YoutubePlayer(
                        controller: _youtubeController,
                        aspectRatio: 16 / 9,
                      ),
                    )
                  else
                    Image.network(
                      widget.film.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: isDark
                              ? const Color(0xFF1E1E1E)
                              : const Color(0xFF001A4D),
                          alignment: Alignment.center,
                          child: const Icon(Icons.movie,
                              size: 100, color: Colors.white),
                        );
                      },
                    ),
                  if (!_showTrailer)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.3),
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  if (!_showTrailer)
                    Center(
                      child: GestureDetector(
                        onTap: _toggleTrailer,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.play_arrow,
                              color: Colors.white, size: 40),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  color: isDark ? const Color(0xFF121212) : Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.film.imageUrl,
                          width: 120,
                          height: 170,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 120,
                              height: 170,
                              color: const Color(0xFFDDDDDD),
                              alignment: Alignment.center,
                              child: const Icon(Icons.movie,
                                  size: 40, color: Colors.white),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.film.title.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow('Genre', widget.film.genre, isDark),
                            const SizedBox(height: 4),
                            _buildInfoRow(
                                'Durasi', widget.film.duration, isDark),
                            const SizedBox(height: 4),
                            _buildInfoRow(
                                'Sutradara', widget.film.director, isDark),
                            const SizedBox(height: 4),
                            _buildInfoRow(
                                'Rating Usia', widget.film.ageRating, isDark),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: isDark ? const Color(0xFF121212) : Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.film.rating,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFFB800),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ...List.generate(
                                5,
                                (index) => const Icon(Icons.star,
                                    color: Color(0xFFFFB800), size: 20),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '5.984 Vote ▸',
                            style: TextStyle(
                                color: isDark
                                    ? Colors.grey.shade500
                                    : const Color(0xFF999999),
                                fontSize: 12),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          GestureDetector(
                            onTap: _toggleWatchlist,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isInWatchlist
                                    ? Colors.red
                                    : (isDark
                                        ? const Color(0xFF1E1E1E)
                                        : Colors.white),
                                border: Border.all(color: Colors.red),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isInWatchlist
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isInWatchlist
                                        ? Colors.white
                                        : Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isInWatchlist
                                        ? 'Di Watchlist'
                                        : 'Masukkan watchlist',
                                    style: TextStyle(
                                      color: isInWatchlist
                                          ? Colors.white
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$watchlistCount Orang',
                            style: TextStyle(
                                color: isDark
                                    ? Colors.grey.shade500
                                    : const Color(0xFF999999),
                                fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  color: isDark ? const Color(0xFF121212) : Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: isDark
                        ? const Color(0xFFFFB800)
                        : const Color(0xFF001A4D),
                    unselectedLabelColor:
                        isDark ? Colors.grey.shade600 : const Color(0xFF999999),
                    indicatorColor: isDark
                        ? const Color(0xFFFFB800)
                        : const Color(0xFF001A4D),
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(text: 'SINOPSIS'),
                      Tab(text: 'JADWAL'),
                    ],
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      SingleChildScrollView(
                        padding: EdgeInsets.all(16),
                        child: Container(
                          color:
                              isDark ? const Color(0xFF121212) : Colors.white,
                          child: Text(
                            'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                            style: TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color:
                                    isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ),
                      _buildJadwalTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style: TextStyle(
                  color:
                      isDark ? Colors.grey.shade500 : const Color(0xFF999999),
                  fontSize: 12)),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black)),
        ),
      ],
    );
  }

  Widget _buildJadwalTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Container(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        child: Column(
          children: [
            const SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: schedules.length,
                itemBuilder: (context, index) {
                  final schedule = schedules[index];
                  final isSelected = selectedSchedule == schedule.date;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedSchedule = schedule.date;
                        selectedTime = '';
                        selectedCinemaLocation = '';
                      });
                    },
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                ? const Color(0xFFFFB800)
                                : const Color(0xFF001A4D))
                            : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                        border: Border.all(
                          color: isSelected
                              ? (isDark
                                  ? const Color(0xFFFFB800)
                                  : const Color(0xFF001A4D))
                              : (isDark
                                  ? Colors.grey.shade700
                                  : const Color(0xFFDDDDDD)),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            schedule.date,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white : Colors.black),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            schedule.day,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? Colors.white70
                                  : (isDark
                                      ? Colors.grey.shade400
                                      : const Color(0xFF999999)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFilterButton('Bioskop', selectedCinema, () {
                      _showCinemaFilter();
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _getFilteredCinemas().length,
              itemBuilder: (context, index) {
                final cinema = _getFilteredCinemas()[index];
                return _buildCinemaCard(cinema);
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, String value, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isDark ? Colors.grey.shade700 : const Color(0xFFDDDDDD)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? Colors.grey.shade400
                              : const Color(0xFF999999))),
                  Text(value,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down,
                color: isDark ? Colors.grey.shade400 : const Color(0xFF999999)),
          ],
        ),
      ),
    );
  }

  Widget _buildCinemaCard(CinemaLocation cinema) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.star_outline,
                    size: 24,
                    color: isDark
                        ? Colors.grey.shade600
                        : const Color(0xFFCCCCCC)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(cinema.name,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFFFFB800)
                        : const Color(0xFF001A4D),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    cinema.type,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F8F8),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.theater_comedy,
                        color: isDark
                            ? Colors.grey.shade400
                            : const Color(0xFF666666),
                        size: 16),
                    const SizedBox(width: 8),
                    Text('Layar besar, suara hebat!',
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.grey.shade400
                                : const Color(0xFF666666))),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: cinema.times.map((time) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SeatSelectionPageWithAPI(
                              film: widget.film,
                              cinema: cinema.name,
                              date: selectedSchedule,
                              time: time,
                              userId: AuthService.getCurrentUsername() ?? '',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          border: Border.all(
                              color: isDark
                                  ? Colors.grey.shade700
                                  : const Color(0xFFDDDDDD)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(time,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: isDark ? Colors.white : Colors.black)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCinemaFilter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade700 : const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('Pilih Bioskop',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.check_circle_outline,
                  color: isDark
                      ? const Color(0xFFFFB800)
                      : const Color(0xFF001A4D)),
              title: Text('Semua Bioskop',
                  style:
                      TextStyle(color: isDark ? Colors.white : Colors.black)),
              trailing: selectedCinema == 'Semua'
                  ? Icon(Icons.check,
                      color: isDark
                          ? const Color(0xFFFFB800)
                          : const Color(0xFF001A4D))
                  : null,
              onTap: () {
                setState(() => selectedCinema = 'Semua');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_movies, color: Colors.red),
              title: Text('CGV',
                  style:
                      TextStyle(color: isDark ? Colors.white : Colors.black)),
              trailing: selectedCinema == 'CGV'
                  ? Icon(Icons.check,
                      color: isDark
                          ? const Color(0xFFFFB800)
                          : const Color(0xFF001A4D))
                  : null,
              onTap: () {
                setState(() => selectedCinema = 'CGV');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.local_movies,
                  color: isDark
                      ? const Color(0xFFFFB800)
                      : const Color(0xFF001A4D)),
              title: Text('XXI',
                  style:
                      TextStyle(color: isDark ? Colors.white : Colors.black)),
              trailing: selectedCinema == 'XXI'
                  ? Icon(Icons.check,
                      color: isDark
                          ? const Color(0xFFFFB800)
                          : const Color(0xFF001A4D))
                  : null,
              onTap: () {
                setState(() => selectedCinema = 'XXI');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_movies, color: Colors.blue),
              title: Text('IMAX',
                  style:
                      TextStyle(color: isDark ? Colors.white : Colors.black)),
              trailing: selectedCinema == 'IMAX'
                  ? Icon(Icons.check,
                      color: isDark
                          ? const Color(0xFFFFB800)
                          : const Color(0xFF001A4D))
                  : null,
              onTap: () {
                setState(() => selectedCinema = 'IMAX');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_movies, color: Colors.orange),
              title: Text('CINEPOLIS',
                  style:
                      TextStyle(color: isDark ? Colors.white : Colors.black)),
              trailing: selectedCinema == 'CINEPOLIS'
                  ? Icon(Icons.check,
                      color: isDark
                          ? const Color(0xFFFFB800)
                          : const Color(0xFF001A4D))
                  : null,
              onTap: () {
                setState(() => selectedCinema = 'CINEPOLIS');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  List<CinemaLocation> _getFilteredCinemas() {
    if (selectedCinema == 'Semua') {
      return cinemas;
    }
    return cinemas.where((cinema) => cinema.type == selectedCinema).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _youtubeController.close();
    super.dispose();
  }
}

class SeatSelectionPageWithAPI extends StatefulWidget {
  final Film film;
  final String cinema;
  final String date;
  final String time;
  final String userId;

  const SeatSelectionPageWithAPI({
    Key? key,
    required this.film,
    required this.cinema,
    required this.date,
    required this.time,
    required this.userId,
  }) : super(key: key);

  @override
  State<SeatSelectionPageWithAPI> createState() =>
      _SeatSelectionPageWithAPIState();
}

class _SeatSelectionPageWithAPIState extends State<SeatSelectionPageWithAPI> {
  List<String> selectedSeats = [];
  Map<String, Map<String, dynamic>> seatsData = {};
  bool isLoading = true;

  final List<List<String>> seatLayout = [
    ['A7', 'A6', 'A5', 'A4', '', '', 'A3', 'A2', 'A1'],
    ['B7', 'B6', 'B5', 'B4', '', '', 'B3', 'B2', 'B1'],
    ['C7', 'C6', 'C5', 'C4', '', '', 'C3', 'C2', 'C1'],
    ['D7', 'D6', 'D5', 'D4', '', '', 'D3', 'D2', 'D1'],
    ['E7', 'E6', 'E5', 'E4', '', '', 'E3', 'E2', 'E1'],
    ['F7', 'F6', 'F5', 'F4', '', '', 'F3', 'F2', 'F1'],
    ['G7', 'G6', 'G5', 'G4', '', '', 'G3', 'G2', 'G1'],
    ['H7', 'H6', 'H5', 'H4', '', '', 'H3', 'H2', 'H1'],
  ];

  @override
  void initState() {
    super.initState();
    _initializeAndLoadSeats();
  }

  Future<void> _initializeAndLoadSeats() async {
    final existingSeats = await SeatService.getSeats(
      filmId: widget.film.id,
      cinema: widget.cinema,
      date: widget.date,
      time: widget.time,
    );

    if (existingSeats.isEmpty) {
      await SeatService.initializeSeats(
        filmId: widget.film.id,
        cinema: widget.cinema,
        date: widget.date,
        time: widget.time,
      );
      await Future.delayed(const Duration(seconds: 2));
    }

    await _loadSeats();
  }

  Future<void> _loadSeats() async {
    final seats = await SeatService.getSeats(
      filmId: widget.film.id,
      cinema: widget.cinema,
      date: widget.date,
      time: widget.time,
    );

    if (mounted) {
      setState(() {
        seatsData.clear();
        for (var seat in seats) {
          seatsData[seat['seatNumber']] = seat;
        }
        isLoading = false;
      });
    }
  }

  Future<void> _toggleSeat(String seatNumber) async {
    final seatData = seatsData[seatNumber];
    if (seatData == null) return;

    if (seatData['status'] == 'booked') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.block, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Kursi $seatNumber sudah dipesan'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (seatData['status'] == 'selected' &&
        seatData['userId'] != widget.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Kursi $seatNumber sedang dipilih pengguna lain'),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      if (selectedSeats.contains(seatNumber)) {
        selectedSeats.remove(seatNumber);
        SeatService.unselectSeat(seatId: seatData['id'].toString());
      } else {
        selectedSeats.add(seatNumber);
        SeatService.selectSeat(
          seatId: seatData['id'].toString(),
          userId: widget.userId,
        );
      }
    });
  }

  Color getSeatColor(String seatNumber) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final seatData = seatsData[seatNumber];

    if (seatData == null) {
      return isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D);
    }

    if (selectedSeats.contains(seatNumber)) {
      return isDark ? const Color(0xFF0066CC) : const Color(0xFF0066CC);
    }

    if (seatData['status'] == 'booked') {
      return isDark ? Colors.grey.shade700 : const Color(0xFFCCCCCC);
    }

    if (seatData['status'] == 'selected' &&
        seatData['userId'] != widget.userId) {
      return isDark ? Colors.grey.shade800 : const Color(0xFFEEEEEE);
    }

    return isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color:
                    isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Memuat kursi...',
            style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF001A4D),
                fontSize: 14),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                  color: isDark
                      ? const Color(0xFFFFB800)
                      : const Color(0xFF001A4D)),
              const SizedBox(height: 16),
              Text('Memuat data kursi...',
                  style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? Colors.grey.shade400
                          : const Color(0xFF666666))),
              const SizedBox(height: 8),
              Text('Harap tunggu',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
        ),
      );
    }

    if (seatsData.isEmpty) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color:
                    isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('Gagal memuat data kursi',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 8),
              Text('Periksa koneksi internet Anda',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                  });
                  _initializeAndLoadSeats();
                },
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Coba Lagi',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFFFFB800)
                      : const Color(0xFF001A4D),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color:
                  isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.cinema,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF001A4D),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${widget.date} | ${widget.time}',
              style: TextStyle(
                  color:
                      isDark ? Colors.grey.shade400 : const Color(0xFF666666),
                  fontSize: 10),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.access_time,
                color:
                    isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor:
                      isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  title: Row(
                    children: [
                      Icon(Icons.access_time,
                          color: isDark
                              ? const Color(0xFFFFB800)
                              : const Color(0xFF001A4D),
                          size: 22),
                      const SizedBox(width: 8),
                      Text('Waktu Pemesanan',
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.black)),
                    ],
                  ),
                  content: Text(
                      'Kursi yang dipilih akan direservasi selama 10 menit.',
                      style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLegend(
                        isDark
                            ? const Color(0xFFFFB800)
                            : const Color(0xFF001A4D),
                        'Tersedia',
                        isDark),
                    _buildLegend(
                        isDark ? Colors.grey.shade700 : const Color(0xFFCCCCCC),
                        'Tidak Tersedia',
                        isDark),
                    _buildLegend(const Color(0xFF0066CC), 'Pilihanmu', isDark),
                    _buildLegend(
                        isDark ? Colors.grey.shade800 : const Color(0xFFEEEEEE),
                        'Dipilih Lain',
                        isDark),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: isDark
                            ? Colors.grey.shade700
                            : const Color(0xFFDDDDDD)),
                    borderRadius: BorderRadius.circular(8),
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  ),
                  child: Text(
                    'LAYAR',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.grey.shade400
                          : const Color(0xFF999999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: seatLayout.length,
                  itemBuilder: (context, rowIndex) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          seatLayout[rowIndex].length,
                          (seatIndex) {
                            String seat = seatLayout[rowIndex][seatIndex];
                            if (seat.isEmpty) {
                              return const SizedBox(width: 32, height: 32);
                            }

                            final seatData = seatsData[seat];
                            bool isBooked = seatData?['status'] == 'booked';
                            bool isSelectedByOther =
                                seatData?['status'] == 'selected' &&
                                    seatData?['userId'] != widget.userId;

                            return GestureDetector(
                              onTap: isBooked || isSelectedByOther
                                  ? null
                                  : () => _toggleSeat(seat),
                              child: Container(
                                width: 32,
                                height: 32,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: getSeatColor(seat),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  seat.length > 2 ? seat.substring(0, 2) : seat,
                                  style: TextStyle(
                                    color: selectedSeats.contains(seat)
                                        ? Colors.white
                                        : (isBooked || isSelectedByOther
                                            ? const Color(0xFF999999)
                                            : Colors.white),
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('TOTAL HARGA',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : const Color(0xFF666666))),
                            Text('TEMPAT DUDUK',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : const Color(0xFF666666))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Rp${selectedSeats.length * 55000}',
                              style: const TextStyle(
                                color: Color(0xFF0066CC),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                selectedSeats.isEmpty
                                    ? '-'
                                    : selectedSeats.join(', '),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: selectedSeats.isEmpty
                          ? null
                          : () async {
                              bool success = await SeatService.bookSeats(
                                seatIds: selectedSeats
                                    .map((s) => seatsData[s]!['id'].toString())
                                    .toList(),
                                userId: widget.userId,
                                filmId: widget.film.id,
                                cinema: widget.cinema,
                                date: widget.date,
                                time: widget.time,
                              );

                              if (success && mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CheckoutPage(
                                      selectedSeats: selectedSeats,
                                      film: widget.film,
                                      cinema: widget.cinema,
                                      date: widget.date,
                                      time: widget.time,
                                    ),
                                  ),
                                );
                              } else if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.error,
                                            color: Colors.white, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                            'Gagal booking kursi. Silakan coba lagi.'),
                                      ],
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                      icon: Icon(
                        selectedSeats.isEmpty
                            ? Icons.event_seat
                            : Icons.arrow_forward,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: Text(
                        selectedSeats.isEmpty
                            ? 'PILIH KURSI TERLEBIH DAHULU'
                            : 'LANJUT KE PEMBAYARAN',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedSeats.isEmpty
                            ? (isDark
                                ? Colors.grey.shade800
                                : const Color(0xFFCCCCCC))
                            : (isDark
                                ? const Color(0xFFFFB800)
                                : const Color(0xFF001A4D)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label, bool isDark) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 9,
                color: isDark ? Colors.grey.shade400 : Colors.black87)),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// ==================== CHECKOUT PAGE ====================

class CheckoutPage extends StatefulWidget {
  final List<String> selectedSeats;
  final Film film;
  final String cinema;
  final String date;
  final String time;

  const CheckoutPage({
    Key? key,
    required this.selectedSeats,
    required this.film,
    required this.cinema,
    required this.date,
    required this.time,
  }) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int _remainingTime = 405;
  String? selectedPaymentMethod;

  final List<PaymentMethod> paymentMethods = [
    PaymentMethod(
      id: 'dana',
      name: 'DANA',
      description:
          'Dapatkan gratis biaya admin Rp16.000 khusus transaksi menggunakan DANA',
      iconData: Icons.account_balance_wallet,
      iconColor: Colors.blue,
    ),
    PaymentMethod(
      id: 'gopay',
      name: 'GoPay',
      description:
          'Cashback 50% maks. 20rb untuk transaksi pertama kamu pakai Aplikasi GoPay',
      iconData: Icons.account_balance_wallet,
      iconColor: Colors.green,
    ),
    PaymentMethod(
      id: 'shopeepay',
      name: 'ShopeePay',
      description:
          'Cashback s/d 20rb Koin Shopee untuk semua pengguna ShopeePay/SPayLater',
      iconData: Icons.account_balance_wallet,
      iconColor: Colors.orange,
    ),
    PaymentMethod(
      id: 'ovo',
      name: 'OVO',
      description:
          'Dapatkan Cashback hingga 10.000 dan cashback 99% khusus pengguna OVO Nabung',
      iconData: Icons.account_balance_wallet,
      iconColor: Colors.purple,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _remainingTime > 0) {
        setState(() => _remainingTime--);
        _startTimer();
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int totalPrice = widget.selectedSeats.length * 55000;
    int serviceFee = widget.selectedSeats.length * 4000;
    int finalPrice = totalPrice + serviceFee;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color:
                  isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ringkasan Pembayaran',
          style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF001A4D),
              fontWeight: FontWeight.bold,
              fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.red.withValues(alpha: 0.1),
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Selesaikan dalam ${_formatTime(_remainingTime)}',
                  style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildFilmInfo(isDark),
                const SizedBox(height: 16),
                _buildTransactionDetail(
                    totalPrice, serviceFee, finalPrice, isDark),
                const SizedBox(height: 16),
                _buildPaymentMethods(isDark),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
                blurRadius: 4,
                offset: const Offset(0, -2))
          ],
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: selectedPaymentMethod == null
                ? null
                : () {
                    final selectedMethod = paymentMethods
                        .firstWhere((m) => m.id == selectedPaymentMethod);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentConfirmPage(
                          paymentMethod: selectedMethod,
                          totalAmount: finalPrice,
                          film: widget.film,
                          cinema: widget.cinema,
                          date: widget.date,
                          time: widget.time,
                          selectedSeats: widget.selectedSeats,
                        ),
                      ),
                    );
                  },
            icon: Icon(
              selectedPaymentMethod == null
                  ? Icons.payment
                  : Icons.arrow_forward,
              color: Colors.white,
              size: 20,
            ),
            label: const Text(
              'LANJUT PEMBAYARAN',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedPaymentMethod == null
                  ? (isDark ? Colors.grey.shade800 : const Color(0xFFCCCCCC))
                  : (isDark
                      ? const Color(0xFFFFB800)
                      : const Color(0xFF001A4D)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilmInfo(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              widget.film.imageUrl,
              width: 80,
              height: 110,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 80,
                height: 110,
                color: const Color(0xFFDDDDDD),
                child: const Icon(Icons.movie, size: 40, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.film.title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Color(0xFFFFB800)),
                    const SizedBox(width: 4),
                    Text(widget.film.rating,
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white : Colors.black)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? const Color(0xFFFFB800)
                                : const Color(0xFF001A4D))
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.film.ageRating,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFFFFB800)
                                : const Color(0xFF001A4D)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 12,
                        color: isDark
                            ? Colors.grey.shade400
                            : const Color(0xFF666666)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.cinema,
                        style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.grey.shade400
                                : const Color(0xFF666666)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 12,
                        color: isDark
                            ? Colors.grey.shade400
                            : const Color(0xFF666666)),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.date}, ${widget.time}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionDetail(
      int totalPrice, int serviceFee, int finalPrice, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long,
                  color: isDark
                      ? const Color(0xFFFFB800)
                      : const Color(0xFF001A4D),
                  size: 20),
              const SizedBox(width: 8),
              Text('Detail Transaksi',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black)),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.confirmation_number,
            label: '${widget.selectedSeats.length} Tiket',
            value: widget.selectedSeats.join(', '),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            icon: Icons.local_offer,
            label: 'Harga Tiket',
            value:
                'Rp${(totalPrice ~/ widget.selectedSeats.length).toString()} x ${widget.selectedSeats.length}',
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            icon: Icons.build,
            label: 'Biaya Layanan',
            value: 'Rp${serviceFee.toString()}',
            isDark: isDark,
          ),
          Divider(
              height: 24,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet,
                      color: isDark
                          ? const Color(0xFFFFB800)
                          : const Color(0xFF001A4D),
                      size: 20),
                  const SizedBox(width: 8),
                  Text('TOTAL BAYAR',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black)),
                ],
              ),
              Text(
                'Rp${finalPrice.toString()}',
                style: const TextStyle(
                    color: Color(0xFF0066CC),
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon,
            size: 16,
            color: isDark ? Colors.grey.shade400 : const Color(0xFF666666)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color:
                      isDark ? Colors.grey.shade400 : const Color(0xFF666666))),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black),
              textAlign: TextAlign.right),
        ),
      ],
    );
  }

  Widget _buildPaymentMethods(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment,
                  color: isDark
                      ? const Color(0xFFFFB800)
                      : const Color(0xFF001A4D),
                  size: 20),
              const SizedBox(width: 8),
              Text('Metode Pembayaran',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black)),
            ],
          ),
          const SizedBox(height: 12),
          ...paymentMethods.map((method) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPaymentOption(method, isDark),
              )),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(PaymentMethod method, bool isDark) {
    final isSelected = selectedPaymentMethod == method.id;
    return GestureDetector(
      onTap: () => setState(() => selectedPaymentMethod = method.id),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? (isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D))
                : (isDark ? Colors.grey.shade800 : const Color(0xFFDDDDDD)),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F8FF))
              : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? (isDark
                          ? const Color(0xFFFFB800)
                          : const Color(0xFF001A4D))
                      : (isDark
                          ? Colors.grey.shade700
                          : const Color(0xFFCCCCCC)),
                  width: 2,
                ),
                color: isSelected
                    ? (isDark
                        ? const Color(0xFFFFB800)
                        : const Color(0xFF001A4D))
                    : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Icon(method.iconData, color: method.iconColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.name,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 4),
                  Text(
                    method.description,
                    style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.grey.shade400
                            : const Color(0xFF666666)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentConfirmPage extends StatefulWidget {
  final PaymentMethod paymentMethod;
  final int totalAmount;
  final Film film;
  final String cinema;
  final String date;
  final String time;
  final List<String> selectedSeats;

  const PaymentConfirmPage({
    Key? key,
    required this.paymentMethod,
    required this.totalAmount,
    required this.film,
    required this.cinema,
    required this.date,
    required this.time,
    required this.selectedSeats,
  }) : super(key: key);

  @override
  State<PaymentConfirmPage> createState() => _PaymentConfirmPageState();
}

class _PaymentConfirmPageState extends State<PaymentConfirmPage> {
  int _remainingTime = 371;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _remainingTime > 0) {
        setState(() => _remainingTime--);
        _startTimer();
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _launchQRISUrl() async {
    final Uri url = Uri.parse(
        'https://qris.online/homepage/plink/TIX${widget.totalAmount}');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Tidak dapat membuka link QRIS'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadQRCode() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF001A4D)),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));

      if (context.mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      'QR Code berhasil diunduh!\nTotal: Rp${widget.totalAmount}'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'LIHAT',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('File tersimpan di Downloads/CINEMA1/QRIS/'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Gagal mengunduh: $e'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessNotificationAndNavigate() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pembayaran Berhasil!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Terima kasih telah membeli tiket.\nTiket Anda berhasil dipesan.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : const Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Pesanan Berhasil!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Tiket telah berhasil dipesan',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.only(
                      bottom: MediaQuery.of(context).size.height - 150,
                      left: 16,
                      right: 16,
                    ),
                    duration: const Duration(seconds: 3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                  ),
                );

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TicketSuccessPage(
                      film: widget.film,
                      cinema: widget.cinema,
                      date: widget.date,
                      time: widget.time,
                      selectedSeats: widget.selectedSeats,
                      totalAmount: widget.totalAmount,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            title: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange, size: 22),
                const SizedBox(width: 8),
                Text('Batalkan Pembayaran?',
                    style:
                        TextStyle(color: isDark ? Colors.white : Colors.black)),
              ],
            ),
            content: Text(
                'Apakah Anda yakin ingin membatalkan proses pembayaran?',
                style:
                    TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.close),
                label: const Text('Tidak'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text('Ya, Batalkan',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color:
                    isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D)),
            onPressed: () async {
              final shouldPop = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor:
                      isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  title: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange, size: 22),
                      const SizedBox(width: 8),
                      Text('Batalkan Pembayaran?',
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.black)),
                    ],
                  ),
                  content: Text(
                      'Apakah Anda yakin ingin membatalkan proses pembayaran?',
                      style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87)),
                  actions: [
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context, false),
                      icon: const Icon(Icons.close),
                      label: const Text('Tidak'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text('Ya, Batalkan',
                          style: TextStyle(color: Colors.white)),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ],
                ),
              );
              if (shouldPop == true && mounted) Navigator.pop(context);
            },
          ),
          title: Text(
            'Pembayaran ${widget.paymentMethod.name}',
            style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF001A4D),
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
        ),
        body: ListView(
          children: [
            Container(
              color: Colors.red.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.access_time, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Selesaikan dalam ${_formatTime(_remainingTime)}',
                    style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.3 : 0.05),
                            blurRadius: 8)
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(widget.paymentMethod.iconData,
                                color: widget.paymentMethod.iconColor,
                                size: 32),
                            const SizedBox(width: 12),
                            Text(
                              widget.paymentMethod.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: isDark ? Colors.white : Colors.black),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2A2A2A)
                                : const Color(0xFFF0F8FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: isDark
                                    ? const Color(0xFFFFB800)
                                    : const Color(0xFF0066CC)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.account_balance_wallet,
                                      color: isDark
                                          ? const Color(0xFFFFB800)
                                          : const Color(0xFF0066CC),
                                      size: 20),
                                  const SizedBox(width: 8),
                                  Text('Total Pembayaran',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: isDark
                                              ? Colors.grey.shade400
                                              : const Color(0xFF666666))),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Rp${widget.totalAmount}',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? const Color(0xFFFFB800)
                                        : const Color(0xFF0066CC)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner,
                          color: isDark
                              ? const Color(0xFFFFB800)
                              : const Color(0xFF001A4D),
                          size: 22),
                      const SizedBox(width: 8),
                      Text('Pindai kode QR untuk membayar',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Mohon jangan menutup aplikasi ini',
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey.shade400
                              : const Color(0xFF666666))),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.3 : 0.05),
                            blurRadius: 8)
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2A2A2A)
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.network(
                            'https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=https://qris.online/homepage/plink/TIX${widget.totalAmount}',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.qr_code,
                                      size: 80, color: Color(0xFFCCCCCC)),
                                  SizedBox(height: 8),
                                  Text('QR CODE',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFFCCCCCC))),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Scan dengan aplikasi e-wallet Anda',
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : const Color(0xFF666666))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tombol BUKA LINK QRIS
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _launchQRISUrl,
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('BUKA LINK QRIS'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? const Color(0xFFFFB800)
                            : const Color(0xFF001A4D),
                        side: BorderSide(
                            color: isDark
                                ? const Color(0xFFFFB800)
                                : const Color(0xFF001A4D),
                            width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tombol DOWNLOAD QR CODE
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _downloadQRCode,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('UNDUH QR CODE'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? const Color(0xFFFFB800)
                            : const Color(0xFF001A4D),
                        side: BorderSide(
                            color: isDark
                                ? const Color(0xFFFFB800)
                                : const Color(0xFF001A4D),
                            width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: isDark
                              ? const Color(0xFFFFB800)
                              : const Color(0xFFFFB800)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Color(0xFFFFB800), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Pastikan pembayaran berhasil sebelum menutup halaman',
                            style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.grey.shade300
                                    : const Color(0xFF666666)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showSuccessNotificationAndNavigate,
                      icon: const Icon(Icons.check_circle,
                          color: Colors.white, size: 20),
                      label: const Text(
                        'CEK STATUS PEMBAYARAN',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFFFFB800)
                            : const Color(0xFF001A4D),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
}

class TicketSuccessPage extends StatefulWidget {
  final Film film;
  final String cinema;
  final String date;
  final String time;
  final List<String> selectedSeats;
  final int totalAmount;

  const TicketSuccessPage({
    Key? key,
    required this.film,
    required this.cinema,
    required this.date,
    required this.time,
    required this.selectedSeats,
    required this.totalAmount,
  }) : super(key: key);

  @override
  State<TicketSuccessPage> createState() => _TicketSuccessPageState();
}

class _TicketSuccessPageState extends State<TicketSuccessPage> {
  late String bookingId;
  late TicketHistory ticket;

  @override
  void initState() {
    super.initState();
    bookingId = 'TIX${DateTime.now().millisecondsSinceEpoch}';

    ticket = TicketHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: AuthService.getCurrentUsername() ?? '',
      film: widget.film,
      cinema: widget.cinema,
      date: widget.date,
      time: widget.time,
      seats: widget.selectedSeats,
      totalAmount: widget.totalAmount,
      bookingId: bookingId,
      purchaseDate: DateTime.now(),
      status: 'active',
    );

    TicketHistoryService.addTicket(ticket);

    NotificationService.addNotification(
      userId: ticket.userId,
      title: '🎉 Pesanan Berhasil!',
      message:
          'Tiket ${widget.film.title} berhasil dipesan. Kursi: ${widget.selectedSeats.join(", ")}',
      type: 'success',
      data: {
        'ticketId': ticket.id,
        'bookingId': bookingId,
        'filmTitle': widget.film.title,
        'seats': widget.selectedSeats,
      },
    );

    AdminNotificationService.addNotification(
      title: '🎫 Pesanan Baru!',
      message:
          'User ${ticket.userId} memesan ${widget.selectedSeats.length} tiket untuk ${widget.film.title}',
      type: 'booking',
      data: {
        'ticketId': ticket.id,
        'bookingId': bookingId,
        'userId': ticket.userId,
        'filmTitle': widget.film.title,
        'cinema': widget.cinema,
        'seats': widget.selectedSeats,
        'totalAmount': widget.totalAmount,
        'date': widget.date,
        'time': widget.time,
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSuccessNotification();
    });

    print('');
    print('═══════════════════════════════════════');
    print('✅ TIKET BERHASIL DISIMPAN!');
    print('═══════════════════════════════════════');
    print('📌 Booking ID: $bookingId');
    print('📌 User: ${ticket.userId}');
    print('📌 Film: ${ticket.film.title}');
    print('📌 Cinema: ${ticket.cinema}');
    print('📌 Date: ${ticket.date}');
    print('📌 Time: ${ticket.time}');
    print('📌 Seats: ${ticket.seats.join(", ")}');
    print('📌 Total: Rp${ticket.totalAmount}');
    print('📌 Status: ${ticket.status}');
    print(
        '📌 Total Active Tickets: ${TicketHistoryService.getActiveTickets().length}');
    print(
        '📌 Admin Notifications: ${AdminNotificationService.getUnreadCount()}');
    print('═══════════════════════════════════════');
    print('');
  }

  void _showSuccessNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '🎉 Pesanan Berhasil!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tiket ${widget.film.title} berhasil dipesan',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kursi: ${widget.selectedSeats.join(", ")}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 180,
          left: 16,
          right: 16,
        ),
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 10,
        padding: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _downloadETicket() async {
    try {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D),
          ),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'E-Ticket berhasil diunduh!\nBooking ID: $bookingId',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'LIHAT',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('File tersimpan di Downloads/CINEMA1/'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Gagal mengunduh: $e'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'E-Ticket Anda',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF001A4D),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: ListView(
        children: [
          Container(
            color: Colors.green.withValues(alpha: 0.1),
            padding: const EdgeInsets.all(16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 12),
                Text(
                  'Pembayaran Anda berhasil!',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E1E1E)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDark
                            ? Colors.grey.shade800
                            : const Color(0xFFDDDDDD)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.cinema,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: widget.cinema.contains('CGV')
                                  ? Colors.red
                                  : widget.cinema.contains('IMAX')
                                      ? Colors.blue
                                      : (isDark
                                          ? const Color(0xFFFFB800)
                                          : const Color(0xFF001A4D)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.cinema.contains('CGV')
                                  ? 'CGV'
                                  : widget.cinema.contains('XXI')
                                      ? 'XXI'
                                      : widget.cinema.contains('IMAX')
                                          ? 'IMAX'
                                          : 'CINEMA',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'REGULAR 2D, AUDI #2',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.grey.shade400
                              : const Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${widget.date}, ${widget.time}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${widget.selectedSeats.length} TIKET',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.grey.shade400
                              : const Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.selectedSeats.join(', '),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isDark
                              ? const Color(0xFFFFB800)
                              : const Color(0xFF001A4D),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TOTAL BAYAR',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : const Color(0xFF666666),
                            ),
                          ),
                          Text(
                            'Rp${widget.totalAmount}',
                            style: const TextStyle(
                              color: Color(0xFF0066CC),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDark
                            ? Colors.grey.shade800
                            : const Color(0xFFDDDDDD)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'E-TICKET QR CODE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tunjukkan QR code ini di bioskop',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey.shade400
                              : const Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: isDark
                                  ? Colors.grey.shade700
                                  : const Color(0xFFDDDDDD)),
                        ),
                        child: Image.network(
                          'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=$bookingId',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.qr_code,
                                  size: 80,
                                  color: isDark
                                      ? Colors.grey.shade700
                                      : const Color(0xFFCCCCCC),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'QR CODE',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.grey.shade700
                                        : const Color(0xFFCCCCCC),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Booking ID: $bookingId',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.grey.shade400
                              : const Color(0xFF666666),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFF0F8FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isDark
                            ? const Color(0xFFFFB800)
                            : const Color(0xFF0066CC)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: isDark
                            ? const Color(0xFFFFB800)
                            : const Color(0xFF0066CC),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Simpan e-ticket ini dan tunjukkan saat memasuki bioskop. Screenshot atau foto juga dapat digunakan.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.grey.shade300
                                : const Color(0xFF666666),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _downloadETicket,
                  icon: Icon(Icons.download,
                      size: 18,
                      color: isDark
                          ? const Color(0xFFFFB800)
                          : const Color(0xFF001A4D)),
                  label: Text(
                    'DOWNLOAD E-TICKET',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFFFB800)
                          : const Color(0xFF001A4D),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isDark
                          ? const Color(0xFFFFB800)
                          : const Color(0xFF001A4D),
                      width: 2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const HomePage(initialTab: 1),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.confirmation_number,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    'LIHAT TIKET SAYA',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFFFFB800)
                        : const Color(0xFF001A4D),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ==================== TICKET HISTORY PAGE ====================

class TicketHistoryPage extends StatefulWidget {
  const TicketHistoryPage({Key? key}) : super(key: key);

  @override
  State<TicketHistoryPage> createState() => _TicketHistoryPageState();
}

class _TicketHistoryPageState extends State<TicketHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _printDebugInfo();
  }

  void _printDebugInfo() {
    print('');
    print('═══════════════════════════════════════');
    print('🎫 TICKET HISTORY PAGE INITIALIZED');
    print('═══════════════════════════════════════');
    final currentUser = AuthService.getCurrentUsername();
    final activeTickets = TicketHistoryService.getActiveTickets();
    final usedTickets = TicketHistoryService.getUsedTickets();

    print('Current User: $currentUser');
    print('Active Tickets: ${activeTickets.length}');
    print('Used Tickets: ${usedTickets.length}');

    for (int i = 0; i < activeTickets.length; i++) {
      final ticket = activeTickets[i];
      print('  [$i] Film: ${ticket.film.title}');
      print('       Cinema: ${ticket.cinema}');
      print('       Seats: ${ticket.seats.join(", ")}');
      print('       User ID: ${ticket.userId}');
      print('       Booking ID: ${ticket.bookingId}');
    }
    print('═══════════════════════════════════════');
    print('');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeTickets = TicketHistoryService.getActiveTickets();
    final usedTickets = TicketHistoryService.getUsedTickets();

    print('📊 Building TicketHistoryPage');
    print('   Active: ${activeTickets.length}, Used: ${usedTickets.length}');

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: Column(
        children: [
          Container(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor:
                  isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D),
              unselectedLabelColor:
                  isDark ? Colors.grey.shade600 : const Color(0xFF999999),
              indicatorColor:
                  isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D),
              indicatorWeight: 3,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.confirmation_number, size: 18),
                      const SizedBox(width: 6),
                      Text('AKTIF (${activeTickets.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history, size: 18),
                      const SizedBox(width: 6),
                      Text('RIWAYAT (${usedTickets.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTicketList(activeTickets, isActive: true),
                _buildTicketList(usedTickets, isActive: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketList(List<TicketHistory> tickets,
      {required bool isActive}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    print(
        'Building ${isActive ? "AKTIF" : "RIWAYAT"} list with ${tickets.length} tickets');

    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.confirmation_number_outlined : Icons.history,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              isActive ? 'Belum ada tiket aktif' : 'Belum ada riwayat tiket',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isActive
                  ? 'Pesan tiket sekarang!'
                  : 'Riwayat tiket akan muncul di sini',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            if (isActive)
              ElevatedButton.icon(
                onPressed: () {
                  final homeState =
                      context.findAncestorStateOfType<_HomePageState>();
                  if (homeState != null) {
                    homeState.setState(() {
                      homeState.selectedTab = 0;
                    });
                  }
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Pesan Tiket',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFFFFB800)
                      : const Color(0xFF001A4D),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          return _buildTicketCard(tickets[index], isActive: isActive);
        },
      ),
    );
  }

  Widget _buildTicketCard(TicketHistory ticket, {required bool isActive}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive
                  ? (isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D))
                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? Icons.confirmation_number : Icons.check_circle,
                  color: isActive
                      ? Colors.white
                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isActive ? 'TIKET AKTIF' : 'SUDAH DIGUNAKAN',
                  style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : (isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.qr_code,
                  color: isActive
                      ? Colors.white70
                      : (isDark ? Colors.grey.shade600 : Colors.grey.shade500),
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  'ID: ${ticket.bookingId.length > 13 ? ticket.bookingId.substring(0, 13) : ticket.bookingId}...',
                  style: TextStyle(
                    color: isActive
                        ? Colors.white70
                        : (isDark
                            ? Colors.grey.shade600
                            : Colors.grey.shade500),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    ticket.film.imageUrl,
                    width: 80,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 110,
                      color: isDark
                          ? Colors.grey.shade800
                          : const Color(0xFFDDDDDD),
                      child: Icon(
                        Icons.movie,
                        size: 40,
                        color: isDark ? Colors.grey.shade600 : Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.film.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              size: 14, color: Color(0xFFFFB800)),
                          const SizedBox(width: 4),
                          Text(
                            ticket.film.rating,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isDark
                                      ? const Color(0xFFFFB800)
                                      : const Color(0xFF001A4D))
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              ticket.film.ageRating,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? const Color(0xFFFFB800)
                                    : const Color(0xFF001A4D),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: isDark
                                ? Colors.grey.shade400
                                : const Color(0xFF666666),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ticket.cinema,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : const Color(0xFF666666),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: isDark
                                ? Colors.grey.shade400
                                : const Color(0xFF666666),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${ticket.date}, ${ticket.time}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.event_seat,
                            size: 12,
                            color: isDark
                                ? Colors.grey.shade400
                                : const Color(0xFF666666),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Kursi: ${ticket.seats.join(', ')}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : const Color(0xFF666666),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 14,
                          color: isDark
                              ? Colors.grey.shade400
                              : const Color(0xFF666666),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Total Pembayaran',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.grey.shade400
                                : const Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp${ticket.totalAmount}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0066CC),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TicketDetailPage(ticket: ticket),
                      ),
                    );
                  },
                  icon:
                      const Icon(Icons.qr_code, color: Colors.white, size: 16),
                  label: const Text(
                    'LIHAT DETAIL',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFFFFB800)
                        : const Color(0xFF001A4D),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class NotificationItem {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // 'success', 'info', 'warning'
  final DateTime createdAt;
  bool isRead;
  final Map<String, dynamic>? data;

  NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });
}

// ==================== TICKET DETAIL PAGE (DENGAN DOWNLOAD & SHARE) ====================

class TicketDetailPage extends StatelessWidget {
  final TicketHistory ticket;

  const TicketDetailPage({Key? key, required this.ticket}) : super(key: key);

  // ✅ FUNGSI DOWNLOAD E-TICKET
  Future<void> _downloadETicket(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF001A4D)),
        ),
      );

      // Simulasi download (dalam production, gunakan package seperti screenshot atau pdf)
      await Future.delayed(const Duration(seconds: 2));

      if (context.mounted) {
        Navigator.pop(context); // Tutup loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'E-Ticket berhasil diunduh!\nBooking ID: ${ticket.bookingId}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'LIHAT',
              textColor: Colors.white,
              onPressed: () {
                // Buka file manager atau gallery
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('File tersimpan di Downloads/CINEMA1/'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Tutup loading jika ada
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Gagal mengunduh: $e'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ FUNGSI SHARE E-TICKET
  Future<void> _shareETicket(BuildContext context) async {
    try {
      final String shareText = '''
🎬 CINEMA 1 E-TICKET 🎬

Film: ${ticket.film.title}
Bioskop: ${ticket.cinema}
Tanggal: ${ticket.date}
Waktu: ${ticket.time}
Kursi: ${ticket.seats.join(", ")}
Total Bayar: Rp${ticket.totalAmount}

Booking ID: ${ticket.bookingId}

Tunjukkan e-ticket ini di bioskop.
      ''';

      // Tampilkan bottom sheet dengan opsi share
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Bagikan E-Ticket',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Copy Text
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.copy, color: Colors.blue),
                ),
                title: const Text('Salin Teks'),
                subtitle: const Text('Salin detail e-ticket'),
                onTap: () {
                  // Copy ke clipboard (perlu import package flutter/services.dart)
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Teks berhasil disalin!'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),

              // Share as Image
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.image, color: Colors.green),
                ),
                title: const Text('Bagikan sebagai Gambar'),
                subtitle: const Text('Screenshot e-ticket'),
                onTap: () async {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF001A4D)),
                    ),
                  );

                  await Future.delayed(const Duration(seconds: 1));

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text('E-Ticket berhasil dibagikan!'),
                          ],
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),

              // Share QR Code
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.qr_code, color: Colors.orange),
                ),
                title: const Text('Bagikan QR Code'),
                subtitle: const Text('Kirim booking ID'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.share,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('Booking ID: ${ticket.bookingId}'),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF001A4D),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Gagal membagikan: $e'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF001A4D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail E-Ticket',
          style: TextStyle(
              color: Color(0xFF001A4D),
              fontWeight: FontWeight.bold,
              fontSize: 16),
        ),
        actions: [
          // ✅ TOMBOL SHARE
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF001A4D)),
            onPressed: () => _shareETicket(context),
            tooltip: 'Bagikan E-Ticket',
          ),
          // ✅ TOMBOL DOWNLOAD
          IconButton(
            icon: const Icon(Icons.download, color: Color(0xFF001A4D)),
            onPressed: () => _downloadETicket(context),
            tooltip: 'Download E-Ticket',
          ),
        ],
      ),
      body: ListView(
        children: [
          Container(
            color: ticket.status == 'active'
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  ticket.status == 'active'
                      ? Icons.check_circle
                      : Icons.history,
                  color: ticket.status == 'active'
                      ? Colors.green
                      : Colors.grey.shade600,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  ticket.status == 'active'
                      ? 'Tiket Aktif'
                      : 'Tiket Sudah Digunakan',
                  style: TextStyle(
                    color: ticket.status == 'active'
                        ? Colors.green
                        : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: Color(0xFF001A4D), size: 18),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(ticket.cinema,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: ticket.cinema.contains('CGV')
                                  ? Colors.red
                                  : ticket.cinema.contains('IMAX')
                                      ? Colors.blue
                                      : const Color(0xFF001A4D),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              ticket.cinema.contains('CGV')
                                  ? 'CGV'
                                  : ticket.cinema.contains('XXI')
                                      ? 'XXI'
                                      : ticket.cinema.contains('IMAX')
                                          ? 'IMAX'
                                          : 'CINEMA',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Icon(Icons.movie, color: Color(0xFF666666), size: 14),
                          SizedBox(width: 6),
                          Text('REGULAR 2D, AUDI #2',
                              style: TextStyle(
                                  fontSize: 11, color: Color(0xFF666666))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              color: Color(0xFF001A4D), size: 14),
                          const SizedBox(width: 6),
                          Text('${ticket.date}, ${ticket.time}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          const Icon(Icons.event_seat,
                              color: Color(0xFF666666), size: 16),
                          const SizedBox(width: 6),
                          Text('${ticket.seats.length} TIKET',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF666666))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(ticket.seats.join(', '),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF001A4D))),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.account_balance_wallet,
                                  color: Color(0xFF001A4D), size: 18),
                              SizedBox(width: 6),
                              Text('TOTAL BAYAR',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            ],
                          ),
                          Text('Rp${ticket.totalAmount}',
                              style: const TextStyle(
                                  color: Color(0xFF0066CC),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8)
                    ],
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_2,
                              color: Color(0xFF001A4D), size: 22),
                          SizedBox(width: 8),
                          Text('E-TICKET QR CODE',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('Tunjukkan QR code ini di bioskop',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF666666))),
                      const SizedBox(height: 20),
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFDDDDDD)),
                        ),
                        child: Image.network(
                          'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${ticket.bookingId}',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.qr_code,
                                    size: 80, color: Color(0xFFCCCCCC)),
                                SizedBox(height: 8),
                                Text('QR CODE',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFFCCCCCC))),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.confirmation_number,
                              color: Color(0xFF666666), size: 14),
                          const SizedBox(width: 6),
                          Text('Booking ID: ${ticket.bookingId}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF666666),
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F8FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF0066CC)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Color(0xFF0066CC), size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Simpan e-ticket ini dan tunjukkan saat memasuki bioskop. Screenshot atau foto juga dapat digunakan.',
                          style:
                              TextStyle(fontSize: 11, color: Color(0xFF666666)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // ✅ TOMBOL DOWNLOAD
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _downloadETicket(context),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('DOWNLOAD'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF001A4D),
                    side: const BorderSide(color: Color(0xFF001A4D), width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // ✅ TOMBOL SHARE
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _shareETicket(context),
                  icon: const Icon(Icons.share, size: 18, color: Colors.white),
                  label: const Text('BAGIKAN',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF001A4D),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ==================== PROFILE PAGE ====================

// ==================== PROFILE PAGE ====================

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserProfile? userProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    setState(() {
      userProfile = AuthService.getCurrentUserProfile();
    });
  }

  void _showEditDialog(String field) {
    if (userProfile == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final controller = TextEditingController(
      text: field == 'name'
          ? userProfile!.name
          : field == 'phone'
              ? userProfile!.phoneNumber
              : field == 'email'
                  ? userProfile!.email
                  : field == 'profile'
                      ? userProfile!.profileImageUrl
                      : field == 'background'
                          ? userProfile!.backgroundImageUrl
                          : userProfile!.gender ?? '',
    );

    if (field == 'birthdate') {
      _showBirthDatePicker();
      return;
    }

    if (field == 'gender') {
      _showGenderPicker();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Row(
          children: [
            Icon(
              field == 'name'
                  ? Icons.person
                  : field == 'phone'
                      ? Icons.phone
                      : field == 'email'
                          ? Icons.email
                          : field == 'profile'
                              ? Icons.image
                              : Icons.wallpaper,
              color: isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D),
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              field == 'name'
                  ? 'Edit Nama'
                  : field == 'phone'
                      ? 'Edit Nomor Telepon'
                      : field == 'email'
                          ? 'Edit Email'
                          : field == 'profile'
                              ? 'Edit Foto Profil'
                              : 'Edit Background',
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: field == 'name'
                ? 'Masukkan nama'
                : field == 'phone'
                    ? 'Masukkan nomor telepon'
                    : field == 'email'
                        ? 'Masukkan email'
                        : field == 'profile'
                            ? 'Masukkan URL foto profil'
                            : 'Masukkan URL background',
            hintStyle: TextStyle(
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            ),
            prefixIcon: Icon(
              field == 'name'
                  ? Icons.person
                  : field == 'phone'
                      ? Icons.phone
                      : field == 'email'
                          ? Icons.email
                          : Icons.link,
              color: isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D),
            ),
          ),
          keyboardType: field == 'phone'
              ? TextInputType.phone
              : field == 'email'
                  ? TextInputType.emailAddress
                  : TextInputType.text,
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            label: Text('Batal',
                style: TextStyle(
                    color:
                        isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.error, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Field tidak boleh kosong!'),
                      ],
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              setState(() {
                if (field == 'name') {
                  userProfile!.name = controller.text.trim();
                } else if (field == 'phone') {
                  userProfile!.phoneNumber = controller.text.trim();
                } else if (field == 'email') {
                  userProfile!.email = controller.text.trim();
                } else if (field == 'profile') {
                  userProfile!.profileImageUrl = controller.text.trim();
                } else if (field == 'background') {
                  userProfile!.backgroundImageUrl = controller.text.trim();
                }
                AuthService.updateUserProfile(userProfile!);
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${field == "name" ? "Nama" : field == "phone" ? "Nomor telepon" : field == "email" ? "Email" : field == "profile" ? "Foto profil" : "Background"} berhasil diperbarui!',
                      ),
                    ],
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Simpan', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D)),
          ),
        ],
      ),
    );
  }

  void _showBirthDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: userProfile!.birthDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        userProfile!.birthDate = picked;
        AuthService.updateUserProfile(userProfile!);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Tanggal lahir berhasil diperbarui!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showGenderPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Row(
          children: [
            Icon(Icons.wc,
                color:
                    isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D),
                size: 22),
            const SizedBox(width: 8),
            Text('Edit Jenis Kelamin',
                style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text('Laki-laki',
                  style:
                      TextStyle(color: isDark ? Colors.white : Colors.black)),
              value: 'Laki-laki',
              groupValue: userProfile!.gender,
              activeColor:
                  isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D),
              onChanged: (value) {
                setState(() {
                  userProfile!.gender = value;
                  AuthService.updateUserProfile(userProfile!);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Jenis kelamin berhasil diperbarui!'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            RadioListTile<String>(
              title: Text('Perempuan',
                  style:
                      TextStyle(color: isDark ? Colors.white : Colors.black)),
              value: 'Perempuan',
              groupValue: userProfile!.gender,
              activeColor:
                  isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D),
              onChanged: (value) {
                setState(() {
                  userProfile!.gender = value;
                  AuthService.updateUserProfile(userProfile!);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Jenis kelamin berhasil diperbarui!'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            label: Text('Batal',
                style: TextStyle(
                    color:
                        isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (userProfile == null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        body: Center(
          child: CircularProgressIndicator(
              color:
                  isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D)),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor:
                isDark ? const Color(0xFF1E1E1E) : const Color(0xFF001A4D),
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    userProfile!.backgroundImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF2A2A2A),
                                  const Color(0xFF1E1E1E)
                                ]
                              : [
                                  const Color(0xFF001A4D),
                                  const Color(0xFF0066CC)
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.7)
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 50,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit,
                            color: Colors.white, size: 20),
                        onPressed: () => _showEditDialog('background'),
                        tooltip: 'Edit Background',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Transform.translate(
                  offset: const Offset(0, 0),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: isDark
                                      ? const Color(0xFFFFB800)
                                      : Colors.white,
                                  width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: isDark
                                  ? const Color(0xFF2A2A2A)
                                  : const Color(0xFF001A4D),
                              child: ClipOval(
                                child: Image.network(
                                  userProfile!.profileImageUrl,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.person,
                                        size: 60,
                                        color: isDark
                                            ? const Color(0xFFFFB800)
                                            : Colors.white);
                                  },
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFFFFB800)
                                    : const Color(0xFF001A4D),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF2A2A2A)
                                        : Colors.white,
                                    width: 2),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 20),
                                onPressed: () => _showEditDialog('profile'),
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(userProfile!.name,
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF001A4D))),
                      const SizedBox(height: 4),
                      Text(userProfile!.phoneNumber,
                          style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : const Color(0xFF666666))),
                      if (userProfile!.email.isNotEmpty)
                        Text(userProfile!.email,
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey.shade500
                                    : const Color(0xFF999999))),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      _buildProfileSection(),
                      const SizedBox(height: 16),
                      _buildMenuSection(),
                      const SizedBox(height: 16),
                      _buildLogoutButton(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: isDark
                        ? const Color(0xFFFFB800)
                        : const Color(0xFF001A4D),
                    size: 20),
                const SizedBox(width: 8),
                Text('Informasi Profil',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color:
                            isDark ? Colors.white : const Color(0xFF001A4D))),
              ],
            ),
          ),
          _buildProfileItem(
            icon: Icons.person,
            title: 'Nama Lengkap',
            subtitle: userProfile!.name,
            onTap: () => _showEditDialog('name'),
          ),
          Divider(
              height: 1,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          _buildProfileItem(
            icon: Icons.phone,
            title: 'Nomor Telepon',
            subtitle: userProfile!.phoneNumber,
            onTap: () => _showEditDialog('phone'),
          ),
          Divider(
              height: 1,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          _buildProfileItem(
            icon: Icons.email,
            title: 'Email',
            subtitle:
                userProfile!.email.isEmpty ? 'Belum diisi' : userProfile!.email,
            onTap: () => _showEditDialog('email'),
          ),
          Divider(
              height: 1,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          _buildProfileItem(
            icon: Icons.cake,
            title: 'Tanggal Lahir',
            subtitle: userProfile!.birthDate != null
                ? '${userProfile!.birthDate!.day}/${userProfile!.birthDate!.month}/${userProfile!.birthDate!.year}'
                : 'Belum diisi',
            onTap: () => _showEditDialog('birthdate'),
          ),
          Divider(
              height: 1,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          _buildProfileItem(
            icon: Icons.wc,
            title: 'Jenis Kelamin',
            subtitle: userProfile!.gender ?? 'Belum diisi',
            onTap: () => _showEditDialog('gender'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D))
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            color: isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D),
            size: 20),
      ),
      title: Text(title,
          style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey.shade400 : const Color(0xFF666666))),
      subtitle: Text(subtitle,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black)),
      trailing: Icon(Icons.edit,
          color: isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D),
          size: 20),
      onTap: onTap,
    );
  }

  Widget _buildMenuSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = AuthService.getCurrentUsername() ?? '';
    final watchlistCount = WatchlistService.getWatchlistCount(userId);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.confirmation_number,
            title: 'Tiket Saya',
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomePage(initialTab: 1),
                ),
              );
            },
          ),
          Divider(
              height: 1,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          _buildMenuItem(
            icon: Icons.favorite,
            title: 'Watchlist',
            badge: watchlistCount,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WatchlistPage()),
              );
            },
          ),
          Divider(
              height: 1,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          _buildMenuItem(
            icon: Icons.settings,
            title: 'Pengaturan',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          Divider(
              height: 1,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          _buildMenuItem(
            icon: Icons.help,
            title: 'Bantuan',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    int? badge,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D))
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            color: isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D),
            size: 20),
      ),
      title: Text(title,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null && badge > 0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge > 99 ? '99+' : badge.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Icon(Icons.chevron_right,
              color: isDark ? Colors.grey.shade600 : const Color(0xFF666666),
              size: 20),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              title: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 22),
                  const SizedBox(width: 8),
                  Text('Keluar',
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black)),
                ],
              ),
              content: Text('Apakah Anda yakin ingin keluar?',
                  style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87)),
              actions: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close,
                      color:
                          isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                  label: Text('Batal',
                      style: TextStyle(
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600)),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    AuthService.logout();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text('Keluar',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('KELUAR'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<NotificationItem> notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    final userId = AuthService.getCurrentUsername();
    if (userId != null) {
      setState(() {
        notifications = NotificationService.getUserNotifications(userId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unreadCount = NotificationService.getUnreadCount(
        AuthService.getCurrentUsername() ?? '');

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? Colors.white : const Color(0xFF001A4D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(Icons.notifications,
                color:
                    isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D),
                size: 22),
            const SizedBox(width: 8),
            Text(
              'Notifikasi',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF001A4D),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          if (notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  color: isDark ? Colors.white : const Color(0xFF001A4D)),
              onSelected: (value) {
                if (value == 'markAllRead') {
                  NotificationService.markAllAsRead(
                      AuthService.getCurrentUsername() ?? '');
                  setState(() {
                    _loadNotifications();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Semua notifikasi ditandai sudah dibaca'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                } else if (value == 'clearAll') {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor:
                          isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      title: const Text('Hapus Semua'),
                      content: const Text(
                          'Apakah Anda yakin ingin menghapus semua notifikasi?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            NotificationService.clearAllNotifications(
                                AuthService.getCurrentUsername() ?? '');
                            setState(() {
                              _loadNotifications();
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          child: const Text('Hapus',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'markAllRead',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, size: 20),
                      SizedBox(width: 8),
                      Text('Tandai Semua Sudah Dibaca'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clearAll',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Hapus Semua', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Belum Ada Notifikasi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Notifikasi Anda akan muncul di sini',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFF0F8FF),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: isDark
                                ? const Color(0xFFFFB800)
                                : const Color(0xFF0066CC),
                            size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Anda memiliki $unreadCount notifikasi belum dibaca',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFFFFB800)
                                : const Color(0xFF0066CC),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(notifications[index]);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color typeColor;
    IconData typeIcon;

    switch (notification.type) {
      case 'success':
        typeColor = Colors.green;
        typeIcon = Icons.check_circle;
        break;
      case 'warning':
        typeColor = Colors.orange;
        typeIcon = Icons.warning;
        break;
      default:
        typeColor = Colors.blue;
        typeIcon = Icons.info;
    }

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        NotificationService.clearNotification(notification.id);
        setState(() {
          notifications.remove(notification);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifikasi dihapus'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          if (!notification.isRead) {
            NotificationService.markAsRead(notification.id);
            setState(() {
              _loadNotifications();
            });
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: notification.isRead
                ? (isDark ? const Color(0xFF1E1E1E) : Colors.white)
                : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F8FF)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead
                  ? (isDark ? Colors.grey.shade800 : const Color(0xFFDDDDDD))
                  : (isDark
                      ? const Color(0xFFFFB800)
                      : const Color(0xFF0066CC).withValues(alpha: 0.3)),
              width: notification.isRead ? 1 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead
                                    ? FontWeight.w600
                                    : FontWeight.bold,
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF001A4D),
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFFFFB800)
                                    : const Color(0xFF0066CC),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.grey.shade400
                              : const Color(0xFF666666),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDateTime(notification.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

// ==================== ICON TEST PAGE ====================

// ==================== ICON TEST PAGE ====================

class IconTestPage extends StatelessWidget {
  const IconTestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Icon Test',
          style: TextStyle(
            color: Color(0xFF001A4D),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF001A4D)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: const Row(
              children: [
                Icon(Icons.info, color: Colors.orange, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Jika icon terlihat sebagai kotak □, ada masalah dengan Material Icons',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Test Icons:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildIconTest(Icons.home, 'Home'),
          _buildIconTest(Icons.person, 'Person'),
          _buildIconTest(Icons.settings, 'Settings'),
          _buildIconTest(Icons.search, 'Search'),
          _buildIconTest(Icons.favorite, 'Favorite'),
          _buildIconTest(Icons.star, 'Star'),
          _buildIconTest(Icons.movie, 'Movie'),
          _buildIconTest(Icons.confirmation_number, 'Ticket'),
          _buildIconTest(Icons.location_on, 'Location'),
          _buildIconTest(Icons.calendar_today, 'Calendar'),
          _buildIconTest(Icons.phone, 'Phone'),
          _buildIconTest(Icons.email, 'Email'),
          _buildIconTest(Icons.edit, 'Edit'),
          _buildIconTest(Icons.delete, 'Delete'),
          _buildIconTest(Icons.arrow_forward, 'Arrow Forward'),
          _buildIconTest(Icons.check_circle, 'Check Circle'),
          _buildIconTest(Icons.info, 'Info'),
          _buildIconTest(Icons.warning, 'Warning'),
          _buildIconTest(Icons.qr_code, 'QR Code'),
          _buildIconTest(Icons.account_balance_wallet, 'Wallet'),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Jika semua icon muncul normal:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '✅ Material Icons sudah ter-load dengan benar\n✅ Tidak perlu perbaikan tambahan',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconTest(IconData icon, String label) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF001A4D).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF001A4D), size: 24),
        ),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: Icon(icon, size: 20, color: const Color(0xFF666666)),
      ),
    );
  }
}

// ==================== ADMIN MODEL ====================

class AdminUser {
  final String username;
  final String password;
  final String name;
  final String role;

  AdminUser({
    required this.username,
    required this.password,
    required this.name,
    this.role = 'admin',
  });
}

// ==================== ADMIN SERVICE ====================

class AdminService {
  static final Map<String, AdminUser> _admins = {
    'admin': AdminUser(
      username: 'admin',
      password: 'admin123',
      name: 'Super Admin',
      role: 'admin',
    ),
    'admin2': AdminUser(
      username: 'admin2',
      password: 'admin456',
      name: 'Admin Manager',
      role: 'admin',
    ),
  };

  static AdminUser? _currentAdmin;

  static bool authenticateAdmin(String username, String password) {
    if (_admins.containsKey(username) &&
        _admins[username]!.password == password) {
      _currentAdmin = _admins[username];
      return true;
    }
    return false;
  }

  static bool isAdmin() {
    return _currentAdmin != null;
  }

  static AdminUser? getCurrentAdmin() {
    return _currentAdmin;
  }

  static void logoutAdmin() {
    _currentAdmin = null;
  }

  // Analytics
  static Map<String, dynamic> getBookingStatistics() {
    final allTickets = TicketHistoryService.getAllTickets();
    int totalBookings = allTickets.length;
    int totalRevenue =
        allTickets.fold(0, (sum, ticket) => sum + ticket.totalAmount);
    int activeTickets = allTickets.where((t) => t.status == 'active').length;
    int usedTickets = allTickets.where((t) => t.status == 'used').length;

    return {
      'totalBookings': totalBookings,
      'totalRevenue': totalRevenue,
      'activeTickets': activeTickets,
      'usedTickets': usedTickets,
    };
  }

  static Map<String, int> getBookingsByUser() {
    final allTickets = TicketHistoryService.getAllTickets();
    Map<String, int> userBookings = {};

    for (var ticket in allTickets) {
      userBookings[ticket.userId] = (userBookings[ticket.userId] ?? 0) + 1;
    }

    return userBookings;
  }

  static Map<String, int> getBookingsByFilm() {
    final allTickets = TicketHistoryService.getAllTickets();
    Map<String, int> filmBookings = {};

    for (var ticket in allTickets) {
      filmBookings[ticket.film.title] =
          (filmBookings[ticket.film.title] ?? 0) + 1;
    }

    return filmBookings;
  }

  static List<TicketHistory> getRecentBookings({int limit = 10}) {
    final allTickets = TicketHistoryService.getAllTickets();
    allTickets.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
    return allTickets.take(limit).toList();
  }

  static Map<String, dynamic> getDashboardAnalytics() {
    final allTickets = TicketHistoryService.getAllTickets();
    final allFilms = FilmService.getAllFilms();

    // Revenue per day (last 7 days)
    Map<String, int> revenuePerDay = {};
    for (var ticket in allTickets) {
      String dateKey =
          '${ticket.purchaseDate.day}/${ticket.purchaseDate.month}';
      revenuePerDay[dateKey] =
          (revenuePerDay[dateKey] ?? 0) + ticket.totalAmount;
    }

    // Top performing films
    Map<String, int> filmRevenue = {};
    for (var ticket in allTickets) {
      filmRevenue[ticket.film.title] =
          (filmRevenue[ticket.film.title] ?? 0) + ticket.totalAmount;
    }

    // User activity
    Set<String> activeUsers = allTickets
        .where((t) => t.status == 'active')
        .map((t) => t.userId)
        .toSet();

    return {
      'revenuePerDay': revenuePerDay,
      'filmRevenue': filmRevenue,
      'totalFilms': allFilms.length,
      'activeUsers': activeUsers.length,
      'averageTicketPrice': allTickets.isEmpty
          ? 0
          : allTickets.fold(0, (sum, t) => sum + t.totalAmount) ~/
              allTickets.length,
    };
  }
}

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({Key? key}) : super(key: key);

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill untuk testing (hapus di production)
    _usernameController.text = '';
    _passwordController.text = '';
  }

  void _handleLogin() {
    // Trim whitespace dari input (SUDAH DIPERBAIKI - TANPA toLowerCase)
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    print('═══════════════════════════════════════');
    print('🔐 ADMIN LOGIN ATTEMPT');
    print('═══════════════════════════════════════');
    print('Input Username: "$username"');
    print('Input Password: "$password"');
    print('Username Length: ${username.length}');
    print('Password Length: ${password.length}');

    if (username.isEmpty || password.isEmpty) {
      print('❌ VALIDATION FAILED: Empty fields');
      _showDialog('Error', 'Username dan password harus diisi!');
      return;
    }

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;

      print('Attempting authentication...');
      final isAuthenticated =
          AdminService.authenticateAdmin(username, password);

      print('Authentication Result: $isAuthenticated');
      print('═══════════════════════════════════════');

      setState(() => _isLoading = false);

      if (isAuthenticated) {
        print('✅ LOGIN SUCCESS - Navigating to Dashboard');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
        );
      } else {
        print('❌ LOGIN FAILED - Invalid credentials');
        _showDialog(
            'Error',
            'Username atau password admin salah!\n\n'
                'Gunakan:\n'
                'Username: admin\n'
                'Password: admin123\n\n'
                'atau\n\n'
                'Username: admin2\n'
                'Password: admin456');
      }
    });
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              title == 'Error' ? Icons.error : Icons.info,
              color: title == 'Error' ? Colors.red : Colors.blue,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),

              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFB800), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB800),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFB800)
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'admin',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF001A4D),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cinema Management System',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              const Text(
                'Login Admin',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF001A4D),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Username Field
              const Text(
                'USERNAME',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameController,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  hintText: 'Masukkan username admin',
                  prefixIcon: const Icon(Icons.admin_panel_settings,
                      color: Color(0xFFFFB800)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Color(0xFFFFB800), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),

              const SizedBox(height: 16),

              // Password Field
              const Text(
                'PASSWORD',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  hintText: 'Masukkan Password',
                  prefixIcon: const Icon(Icons.lock, color: Color(0xFFFFB800)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Color(0xFFFFB800), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                onSubmitted: (_) => _handleLogin(),
              ),

              const SizedBox(height: 24),

              // Login Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB800),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Login sebagai Admin',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),

              const SizedBox(height: 24),

              // Back to User Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Bukan admin? '),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()),
                      );
                    },
                    child: const Text(
                      'Login sebagai User',
                      style: TextStyle(
                        color: Color(0xFF001A4D),
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCredentialRow(
      String label1, String value1, String label2, String value2) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label1,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  value1,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label2,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  value2,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int selectedTab = 0; // ✅ CHANGE: default ke tab pertama

  @override
  void initState() {
    super.initState();
    // ✅ SETUP LISTENER UNTUK OVERLAY NOTIFICATION
    AdminNotificationService.onNotificationAdded = (notification) {
      if (mounted) {
        OverlayNotificationManager.showNotification(context, notification);

        // Play sound atau vibration (optional)
        print('🔔 OVERLAY NOTIFICATION TRIGGERED!');
        print('   Title: ${notification.title}');
        print('   Message: ${notification.message}');

        // Refresh UI untuk update badge
        setState(() {});
      }
    };
    print('');
    print('═══════════════════════════════════════');
    print('👨‍💼 ADMIN DASHBOARD INITIALIZED');
    print('═══════════════════════════════════════');
    final admin = AdminService.getCurrentAdmin();
    print('Admin: ${admin?.name} (${admin?.username})');
    print('Total Films: ${FilmService.getAllFilms().length}');
    print('Total Tickets: ${TicketHistoryService.getAllTickets().length}');
    print('Total Chats: ${ChatService.getAllConversations().length}'); // ✅ NEW
    print('═══════════════════════════════════════');
    print('');
  }

  @override
  void dispose() {
    // ✅ CLEANUP LISTENER
    AdminNotificationService.onNotificationAdded = null;
    OverlayNotificationManager.removeNotification();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFB800),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings,
                color: Colors.white, size: 26),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  AdminService.getCurrentAdmin()?.name ?? 'Administrator',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // ✅ TOMBOL NOTIFIKASI DENGAN BADGE
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.chat_outlined,
                    color: Colors.white, size: 26),
                onPressed: () {
                  setState(() => selectedTab = 3); // ✅ Langsung ke tab chat
                },
                tooltip: 'Chat',
              ),
              if (ChatService.getUnreadCountForAdmin() > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${ChatService.getUnreadCountForAdmin()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 26),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminNotificationPage(),
                    ),
                  ).then((_) => setState(() {}));
                },
                tooltip: 'Notifikasi',
              ),
              if (AdminNotificationService.getUnreadCount() > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${AdminNotificationService.getUnreadCount()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red, size: 22),
                      SizedBox(width: 8),
                      Text('Logout Admin'),
                    ],
                  ),
                  content: const Text(
                      'Apakah Anda yakin ingin keluar dari panel admin?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        AdminService.logoutAdmin();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
                          (route) => false,
                        );
                      },
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Logout',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: selectedTab == 1
          ? const AdminFilmManagementTab()
          : selectedTab == 2
              ? const AdminTicketManagementTab()
              : selectedTab == 3
                  ? const AdminChatManagementTab() // ✅ NEW TAB
                  : const AdminProfileTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedTab,
        selectedItemColor: const Color(0xFFFFB800),
        unselectedItemColor: const Color(0xFFCCCCCC),
        selectedFontSize: 12,
        unselectedFontSize: 11,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard, size: 26),
            activeIcon: Icon(Icons.dashboard, size: 28),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.movie_outlined, size: 26),
            activeIcon: Icon(Icons.movie, size: 28),
            label: 'Film',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number_outlined, size: 26),
            activeIcon: Icon(Icons.confirmation_number, size: 28),
            label: 'Tiket',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.chat_outlined, size: 24),
                if (ChatService.getUnreadCountForAdmin() > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        ChatService.getUnreadCountForAdmin() > 99
                            ? '99+'
                            : '${ChatService.getUnreadCountForAdmin()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            activeIcon: const Icon(Icons.chat, size: 26),
            label: 'Chat',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 24),
            activeIcon: Icon(Icons.person, size: 26),
            label: 'Profil',
          ),
        ],
        onTap: (index) {
          setState(() => selectedTab = index);
        },
      ),
    );
  }
}
// ==================== ADMIN OVERVIEW TAB ====================

// ==================== ADMIN OVERVIEW TAB ====================

class AdminOverviewTab extends StatelessWidget {
  const AdminOverviewTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stats = AdminService.getBookingStatistics();
    final analytics = AdminService.getDashboardAnalytics();
    final recentBookings = AdminService.getRecentBookings(limit: 5);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Welcome Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFFB800),
                const Color(0xFFFFB800).withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB800).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome, ${AdminService.getCurrentAdmin()?.name ?? "Admin"}!',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time,
                              color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'Last updated: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Quick Stats Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildStatCard(
              icon: Icons.confirmation_number,
              title: 'Total Booking',
              value: '${stats['totalBookings']}',
              color: Colors.blue,
              trend: '+12%',
            ),
            _buildStatCard(
              icon: Icons.attach_money,
              title: 'Revenue',
              value: 'Rp${_formatCurrency(stats['totalRevenue'] ~/ 1000)}K',
              color: Colors.green,
              trend: '+8%',
            ),
            _buildStatCard(
              icon: Icons.people,
              title: 'Active Users',
              value: '${analytics['activeUsers']}',
              color: Colors.purple,
              trend: '+5%',
            ),
            _buildStatCard(
              icon: Icons.movie,
              title: 'Total Films',
              value: '${analytics['totalFilms']}',
              color: Colors.orange,
              trend: 'Stable',
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Performance Metrics
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB800).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.bar_chart,
                      color: Color(0xFFFFB800),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Performance Metrics',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildMetricRow(
                'Active Tickets',
                stats['activeTickets'],
                stats['totalBookings'],
                Colors.green,
              ),
              const SizedBox(height: 12),
              _buildMetricRow(
                'Used Tickets',
                stats['usedTickets'],
                stats['totalBookings'],
                Colors.grey,
              ),
              const SizedBox(height: 12),
              _buildMetricRow(
                'Avg Ticket Price',
                analytics['averageTicketPrice'] ~/ 1000,
                100,
                Colors.blue,
                suffix: 'K',
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Revenue Chart (Simple Bar Representation)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Revenue Overview',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ..._buildRevenueChart(analytics['revenuePerDay']),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Recent Bookings
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.history,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Recent Bookings',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (recentBookings.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.inbox, size: 50, color: Color(0xFFCCCCCC)),
                        SizedBox(height: 8),
                        Text(
                          'Belum ada booking',
                          style: TextStyle(color: Color(0xFF666666)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...recentBookings
                    .map((ticket) => _buildRecentBookingItem(ticket)),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Top Films
        _buildTopFilmsSection(),

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    String? trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              if (trend != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trend,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF001A4D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    int value,
    int total,
    Color color, {
    String suffix = '',
  }) {
    final percentage = total > 0 ? (value / total * 100).toInt() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
              ),
            ),
            Text(
              '$value$suffix',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage / 100,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildRevenueChart(Map<String, int> revenueData) {
    if (revenueData.isEmpty) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'No revenue data',
              style: TextStyle(color: Color(0xFF666666)),
            ),
          ),
        ),
      ];
    }

    final maxRevenue = revenueData.values.reduce((a, b) => a > b ? a : b);

    // ✅ PERBAIKAN: Buat list baru yang mutable dari entries
    final entries = revenueData.entries.toList();

    return entries.take(7).map((entry) {
      final heightPercent = (entry.value / maxRevenue * 100).toInt();

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              child: Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF666666),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Stack(
                children: [
                  Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: heightPercent / 100,
                    child: Container(
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green, Colors.green.shade300],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        'Rp${_formatCurrency(entry.value ~/ 1000)}K',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildRecentBookingItem(TicketHistory ticket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ticket.status == 'active'
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              ticket.film.imageUrl,
              width: 50,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 50,
                height: 70,
                color: const Color(0xFFDDDDDD),
                child: const Icon(Icons.movie, size: 24, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.film.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 12,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ticket.userId,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Seats: ${ticket.seats.join(", ")}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rp${_formatCurrency(ticket.totalAmount)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF0066CC),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ticket.status == 'active' ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ticket.status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopFilmsSection() {
    final filmBookings = AdminService.getBookingsByFilm();

    // ✅ PERBAIKAN: Buat list mutable dari entries, lalu sort
    final sortedFilms = filmBookings.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB800).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      color: Color(0xFFFFB800),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Top Performing Films',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB800).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Top ${sortedFilms.length}',
                  style: const TextStyle(
                    color: Color(0xFFFFB800),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (sortedFilms.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.movie_outlined,
                        size: 50, color: Color(0xFFCCCCCC)),
                    SizedBox(height: 8),
                    Text(
                      'Belum ada data',
                      style: TextStyle(color: Color(0xFF666666)),
                    ),
                  ],
                ),
              ),
            )
          else
            ...sortedFilms.take(5).map((entry) => _buildFilmRankItem(
                  entry.key,
                  entry.value,
                  sortedFilms.indexOf(entry) + 1,
                )),
        ],
      ),
    );
  }

  Widget _buildFilmRankItem(String filmTitle, int bookings, int rank) {
    Color rankColor;
    IconData rankIcon;

    switch (rank) {
      case 1:
        rankColor = const Color(0xFFFFD700); // Gold
        rankIcon = Icons.emoji_events;
        break;
      case 2:
        rankColor = const Color(0xFFC0C0C0); // Silver
        rankIcon = Icons.emoji_events;
        break;
      case 3:
        rankColor = const Color(0xFFCD7F32); // Bronze
        rankIcon = Icons.emoji_events;
        break;
      default:
        rankColor = const Color(0xFF001A4D);
        rankIcon = Icons.star;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: rank <= 3
              ? [rankColor.withValues(alpha: 0.1), Colors.white]
              : [const Color(0xFFF5F5F5), const Color(0xFFF5F5F5)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rank <= 3
              ? rankColor.withValues(alpha: 0.3)
              : const Color(0xFFEEEEEE),
          width: rank <= 3 ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: rank <= 3
                    ? [rankColor, rankColor.withValues(alpha: 0.7)]
                    : [const Color(0xFF001A4D), const Color(0xFF0066CC)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: rankColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(rankIcon, color: Colors.white, size: 16),
                Text(
                  '#$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filmTitle,
                  style: TextStyle(
                    fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.confirmation_number,
                      size: 12,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$bookings bookings',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0066CC).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF0066CC).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.trending_up,
                  color: Color(0xFF0066CC),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  '$bookings',
                  style: const TextStyle(
                    color: Color(0xFF0066CC),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

// ==================== ADMIN FILM MANAGEMENT TAB ====================

class AdminFilmManagementTab extends StatefulWidget {
  const AdminFilmManagementTab({Key? key}) : super(key: key);

  @override
  State<AdminFilmManagementTab> createState() => _AdminFilmManagementTabState();
}

class _AdminFilmManagementTabState extends State<AdminFilmManagementTab> {
  List<Film> films = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFilms();
  }

  void _loadFilms() {
    setState(() {
      films = FilmService.getAllFilms();
    });
  }

  void _searchFilms(String query) {
    setState(() {
      if (query.isEmpty) {
        films = FilmService.getAllFilms();
      } else {
        films = FilmService.getAllFilms()
            .where((film) =>
                film.title.toLowerCase().contains(query.toLowerCase()) ||
                film.genre.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _showAddFilmDialog() {
    final titleController = TextEditingController();
    final genreController = TextEditingController();
    final durationController = TextEditingController();
    final ratingController = TextEditingController();
    final directorController = TextEditingController();
    final ageRatingController = TextEditingController();
    final imageUrlController = TextEditingController();
    final trailerUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_circle, color: Color(0xFFFFB800), size: 24),
            SizedBox(width: 8),
            Text('Tambah Film Baru'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Judul Film',
                  prefixIcon: const Icon(Icons.movie, color: Color(0xFFFFB800)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: genreController,
                decoration: InputDecoration(
                  labelText: 'Genre',
                  prefixIcon:
                      const Icon(Icons.category, color: Color(0xFFFFB800)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durationController,
                decoration: InputDecoration(
                  labelText: 'Durasi',
                  prefixIcon:
                      const Icon(Icons.schedule, color: Color(0xFFFFB800)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ratingController,
                decoration: InputDecoration(
                  labelText: 'Rating',
                  prefixIcon: const Icon(Icons.star, color: Color(0xFFFFB800)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: directorController,
                decoration: InputDecoration(
                  labelText: 'Director',
                  prefixIcon:
                      const Icon(Icons.person, color: Color(0xFFFFB800)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ageRatingController,
                decoration: InputDecoration(
                  labelText: 'Age Rating',
                  prefixIcon: const Icon(Icons.info, color: Color(0xFFFFB800)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: imageUrlController,
                decoration: InputDecoration(
                  labelText: 'Image URL',
                  prefixIcon: const Icon(Icons.image, color: Color(0xFFFFB800)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: trailerUrlController,
                decoration: InputDecoration(
                  labelText: 'YouTube Trailer URL',
                  hintText: 'https://youtu.be/...',
                  prefixIcon:
                      const Icon(Icons.play_circle, color: Color(0xFFFFB800)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (titleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Judul film harus diisi!'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final newFilm = Film(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: titleController.text,
                genre: genreController.text,
                duration: durationController.text,
                rating: ratingController.text,
                director: directorController.text,
                ageRating: ageRatingController.text,
                imageUrl: imageUrlController.text,
                trailerUrl: trailerUrlController.text,
              );

              FilmService.addFilm(newFilm);
              _loadFilms();
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Film berhasil ditambahkan!'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Simpan', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB800)),
          ),
        ],
      ),
    );
  }

  void _showEditFilmDialog(Film film) {
    final titleController = TextEditingController(text: film.title);
    final genreController = TextEditingController(text: film.genre);
    final durationController = TextEditingController(text: film.duration);
    final ratingController = TextEditingController(text: film.rating);
    final directorController = TextEditingController(text: film.director);
    final ageRatingController = TextEditingController(text: film.ageRating);
    final imageUrlController = TextEditingController(text: film.imageUrl);
    final trailerUrlController = TextEditingController(text: film.trailerUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit, color: Color(0xFFFFB800), size: 22),
            SizedBox(width: 8),
            Text('Edit Film'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Film',
                  prefixIcon: Icon(Icons.movie, color: Color(0xFFFFB800)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: genreController,
                decoration: const InputDecoration(
                  labelText: 'Genre',
                  prefixIcon: Icon(Icons.category, color: Color(0xFFFFB800)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(
                  labelText: 'Durasi',
                  prefixIcon: Icon(Icons.schedule, color: Color(0xFFFFB800)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ratingController,
                decoration: const InputDecoration(
                  labelText: 'Rating',
                  prefixIcon: Icon(Icons.star, color: Color(0xFFFFB800)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: directorController,
                decoration: const InputDecoration(
                  labelText: 'Director',
                  prefixIcon: Icon(Icons.person, color: Color(0xFFFFB800)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ageRatingController,
                decoration: const InputDecoration(
                  labelText: 'Age Rating',
                  prefixIcon: Icon(Icons.info, color: Color(0xFFFFB800)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  prefixIcon: Icon(Icons.image, color: Color(0xFFFFB800)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: trailerUrlController,
                decoration: const InputDecoration(
                  labelText: 'Trailer URL',
                  prefixIcon: Icon(Icons.play_circle, color: Color(0xFFFFB800)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final updatedFilm = Film(
                id: film.id,
                title: titleController.text,
                genre: genreController.text,
                duration: durationController.text,
                rating: ratingController.text,
                director: directorController.text,
                ageRating: ageRatingController.text,
                imageUrl: imageUrlController.text,
                trailerUrl: trailerUrlController.text,
              );

              FilmService.updateFilm(updatedFilm);
              _loadFilms();
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Film berhasil diupdate!'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Update', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB800)),
          ),
        ],
      ),
    );
  }

  void _deleteFilm(Film film) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text('Hapus Film'),
          ],
        ),
        content: Text('Apakah Anda yakin ingin menghapus "${film.title}"?'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              FilmService.deleteFilm(film.id);
              _loadFilms();
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Film berhasil dihapus!'),
                    ],
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            },
            icon: const Icon(Icons.delete, color: Colors.white),
            label: const Text('Hapus', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: _searchFilms,
                      decoration: InputDecoration(
                        hintText: 'Cari film...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  searchController.clear();
                                  _searchFilms('');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide:
                              const BorderSide(color: Color(0xFFDDDDDD)),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showAddFilmDialog,
                    icon: const Icon(Icons.add, color: Colors.white, size: 20),
                    label: const Text('Tambah',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB800),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.movie, color: Color(0xFFFFB800), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Total: ${films.length} Film',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: films.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.movie_outlined,
                          size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Tidak ada film',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: films.length,
                  itemBuilder: (context, index) {
                    final film = films[index];
                    return _buildFilmCard(film);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilmCard(Film film) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Image.network(
                    film.imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFDDDDDD),
                        alignment: Alignment.center,
                        child: const Icon(Icons.movie,
                            size: 40, color: Colors.white),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB800),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 12, color: Colors.white),
                        const SizedBox(width: 2),
                        Text(
                          film.rating,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showEditFilmDialog(film),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.edit,
                              size: 14, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _deleteFilm(film),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.delete,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  film.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  film.genre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF001A4D).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    film.ageRating,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF001A4D),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

// ==================== ADMIN TICKET MANAGEMENT TAB ====================

class AdminTicketManagementTab extends StatefulWidget {
  const AdminTicketManagementTab({Key? key}) : super(key: key);

  @override
  State<AdminTicketManagementTab> createState() =>
      _AdminTicketManagementTabState();
}

class _AdminTicketManagementTabState extends State<AdminTicketManagementTab> {
  String selectedFilter = 'all';
  String selectedUser = 'all';
  List<TicketHistory> tickets = [];
  List<String> users = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      tickets = TicketHistoryService.getAllTickets();
      users = tickets.map((t) => t.userId).toSet().toList();
    });
  }

  List<TicketHistory> get filteredTickets {
    var result = tickets;

    // Filter by status
    if (selectedFilter == 'active') {
      result = result.where((t) => t.status == 'active').toList();
    } else if (selectedFilter == 'used') {
      result = result.where((t) => t.status == 'used').toList();
    }

    // Filter by user
    if (selectedUser != 'all') {
      result = result.where((t) => t.userId == selectedUser).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredTickets;

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildFilterButton(
                      'Semua',
                      'all',
                      Icons.list,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterButton(
                      'Aktif',
                      'active',
                      Icons.check_circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterButton(
                      'Digunakan',
                      'used',
                      Icons.history,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedUser,
                decoration: InputDecoration(
                  labelText: 'Filter by User',
                  prefixIcon:
                      const Icon(Icons.person, color: Color(0xFFFFB800)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: [
                  const DropdownMenuItem(
                      value: 'all', child: Text('Semua User')),
                  ...users.map((user) => DropdownMenuItem(
                        value: user,
                        child: Text(user),
                      )),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedUser = value ?? 'all';
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.confirmation_number,
                      color: Color(0xFFFFB800), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Total: ${filtered.length} Tiket',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.confirmation_number_outlined,
                          size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Tidak ada tiket',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _buildTicketCard(filtered[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterButton(String label, String value, IconData icon) {
    final isSelected = selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFB800) : Colors.white,
          border: Border.all(
            color:
                isSelected ? const Color(0xFFFFB800) : const Color(0xFFDDDDDD),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF666666),
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF666666),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(TicketHistory ticket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ticket.status == 'active'
                  ? const Color(0xFFFFB800)
                  : Colors.grey.shade300,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  ticket.status == 'active'
                      ? Icons.confirmation_number
                      : Icons.check_circle,
                  color: ticket.status == 'active'
                      ? Colors.white
                      : Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  ticket.status == 'active' ? 'TIKET AKTIF' : 'SUDAH DIGUNAKAN',
                  style: TextStyle(
                    color: ticket.status == 'active'
                        ? Colors.white
                        : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ticket.status == 'active'
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'User: ${ticket.userId}',
                    style: TextStyle(
                      color: ticket.status == 'active'
                          ? Colors.white
                          : Colors.grey.shade700,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    ticket.film.imageUrl,
                    width: 80,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 110,
                      color: const Color(0xFFDDDDDD),
                      child: const Icon(Icons.movie,
                          size: 40, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.film.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 12, color: Color(0xFF666666)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ticket.cinema,
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF666666)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 12, color: Color(0xFF666666)),
                          const SizedBox(width: 4),
                          Text(
                            '${ticket.date}, ${ticket.time}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.event_seat,
                              size: 12, color: Color(0xFF666666)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Kursi: ${ticket.seats.join(', ')}',
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF666666)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.qr_code,
                              size: 12, color: Color(0xFF666666)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'ID: ${ticket.bookingId}',
                              style: const TextStyle(
                                  fontSize: 10, color: Color(0xFF666666)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.account_balance_wallet,
                            size: 14, color: Color(0xFF666666)),
                        SizedBox(width: 4),
                        Text(
                          'Total Pembayaran',
                          style:
                              TextStyle(fontSize: 11, color: Color(0xFF666666)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp${ticket.totalAmount}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0066CC),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Dibeli pada',
                      style: TextStyle(fontSize: 10, color: Color(0xFF666666)),
                    ),
                    Text(
                      '${ticket.purchaseDate.day}/${ticket.purchaseDate.month}/${ticket.purchaseDate.year}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== ADMIN PROFILE TAB ====================

class AdminProfileTab extends StatefulWidget {
  const AdminProfileTab({Key? key}) : super(key: key);

  @override
  State<AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<AdminProfileTab> {
  String profileImageUrl =
      'https://i.pinimg.com/736x/43/aa/ad/43aaada331e1435c354145a1d7481462.jpg';

  void _showEditProfileImageDialog() {
    final controller = TextEditingController(text: profileImageUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.image, color: Color(0xFFFFB800), size: 22),
            SizedBox(width: 8),
            Text('Edit Foto Profil'),
          ],
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Masukkan URL foto profil',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.link, color: Color(0xFFFFB800)),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('URL tidak boleh kosong!'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              setState(() {
                profileImageUrl = controller.text.trim();
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Foto profil berhasil diperbarui!'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Simpan', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = AdminService.getCurrentAdmin();
    final stats = AdminService.getBookingStatistics();

    return ListView(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFFB800),
                const Color(0xFFFFB800).withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: ClipOval(
                        child: Image.network(
                          profileImageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.person,
                                size: 50, color: Color(0xFFFFB800));
                          },
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showEditProfileImageDialog,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFFFB800), width: 2),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Color(0xFFFFB800),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                admin?.name ?? 'Administrator',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.admin_panel_settings,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      admin?.role.toUpperCase() ?? 'ADMIN',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Statistics
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.analytics,
                            color: Color(0xFFFFB800), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Statistik Sistem',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow('Total Booking', '${stats['totalBookings']}',
                        Icons.confirmation_number),
                    const Divider(height: 20),
                    _buildStatRow(
                      'Total Revenue',
                      'Rp${_formatCurrency(stats['totalRevenue'])}',
                      Icons.attach_money,
                    ),
                    const Divider(height: 20),
                    _buildStatRow('Tiket Aktif', '${stats['activeTickets']}',
                        Icons.check_circle),
                    const Divider(height: 20),
                    _buildStatRow('Tiket Digunakan', '${stats['usedTickets']}',
                        Icons.history),
                    const Divider(height: 20),
                    _buildStatRow('Total Film',
                        '${FilmService.getAllFilms().length}', Icons.movie),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Admin Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Color(0xFFFFB800), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Informasi Admin',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                        'Username', admin?.username ?? '-', Icons.person),
                    const Divider(height: 20),
                    _buildInfoRow('Nama', admin?.name ?? '-', Icons.badge),
                    const Divider(height: 20),
                    _buildInfoRow('Role', admin?.role.toUpperCase() ?? '-',
                        Icons.admin_panel_settings),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red, size: 22),
                            SizedBox(width: 8),
                            Text('Logout Admin'),
                          ],
                        ),
                        content: const Text(
                            'Apakah Anda yakin ingin keluar dari panel admin?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Batal'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              AdminService.logoutAdmin();
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const LoginPage()),
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            child: const Text('Logout',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('KELUAR DARI admin'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFB800).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFFFB800), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF001A4D),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFB800).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFFFB800), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF001A4D),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatCurrency(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

// ==================== ADMIN CHAT MANAGEMENT TAB ====================

class AdminChatManagementTab extends StatefulWidget {
  const AdminChatManagementTab({Key? key}) : super(key: key);

  @override
  State<AdminChatManagementTab> createState() => _AdminChatManagementTabState();
}

class _AdminChatManagementTabState extends State<AdminChatManagementTab> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();

    // Setup callback untuk notifikasi pesan baru
    ChatService.onNewMessageForAdmin = (userId) {
      if (mounted) {
        setState(() {});
      }
    };
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversations = ChatService.getAllConversations();
    final unreadCount = ChatService.getUnreadCountForAdmin();

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.chat, color: Color(0xFFFFB800), size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chat Management',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Kelola percakapan dengan user',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$unreadCount Baru',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        Expanded(
          child: conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada percakapan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'User akan muncul di sini setelah mengirim pesan',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    return _buildConversationCard(conversations[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildConversationCard(ChatConversation conversation) {
    final lastMessage =
        conversation.messages.isNotEmpty ? conversation.messages.last : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:
            conversation.hasUnreadAdmin ? Colors.orange.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: conversation.hasUnreadAdmin
              ? Colors.orange
              : const Color(0xFFDDDDDD),
          width: conversation.hasUnreadAdmin ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF001A4D).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  conversation.userName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF001A4D),
                  ),
                ),
              ),
            ),
            if (conversation.hasUnreadAdmin)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                conversation.userName,
                style: TextStyle(
                  fontWeight: conversation.hasUnreadAdmin
                      ? FontWeight.bold
                      : FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB800).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFB800)),
              ),
              child: Text(
                '${conversation.messages.length} pesan',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFB800),
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  lastMessage?.isFromUser == true
                      ? Icons.person
                      : Icons.admin_panel_settings,
                  size: 12,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    lastMessage?.text ?? 'Belum ada pesan',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(conversation.lastMessageTime),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF666666)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminChatDetailPage(
                conversation: conversation,
              ),
            ),
          ).then((_) => setState(() {}));
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Baru saja';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m yang lalu';
    } else if (diff.inDays < 1) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month}';
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    ChatService.onNewMessageForAdmin = null;
    super.dispose();
  }
}

// ==================== ADMIN CHAT DETAIL PAGE ====================

class AdminChatDetailPage extends StatefulWidget {
  final ChatConversation conversation;

  const AdminChatDetailPage({
    Key? key,
    required this.conversation,
  }) : super(key: key);

  @override
  State<AdminChatDetailPage> createState() => _AdminChatDetailPageState();
}

class _AdminChatDetailPageState extends State<AdminChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatConversation _conversation;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
    ChatService.markAsReadByAdmin(_conversation.userId);
    _startAutoRefresh();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    // Setup callback untuk notifikasi pesan baru
    ChatService.onNewMessageForAdmin = (userId) {
      if (userId == _conversation.userId && mounted) {
        _loadConversation();
      }
    };
  }

  void _loadConversation() {
    final conv = ChatService.getConversation(_conversation.userId);
    if (conv != null && mounted) {
      setState(() {
        _conversation = conv;
      });
      ChatService.markAsReadByAdmin(_conversation.userId);
      _scrollToBottom();
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _loadConversation();
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();

    ChatService.sendMessageFromAdmin(
      userId: _conversation.userId,
      message: messageText,
    );

    _messageController.clear();
    _loadConversation();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFB800),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  _conversation.userName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFB800),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _conversation.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'User ID: ${_conversation.userId}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'clear') {
                _clearConversation();
              } else if (value == 'info') {
                _showUserInfo();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info, size: 20, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Info User'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Hapus Percakapan'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _conversation.messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada pesan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _conversation.messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_conversation.messages[index]);
                    },
                  ),
          ),

          // Quick Replies (Optional)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickReply('Terima kasih telah menghubungi kami! 😊'),
                  const SizedBox(width: 8),
                  _buildQuickReply('Bisa jelaskan lebih detail?'),
                  const SizedBox(width: 8),
                  _buildQuickReply('Kami akan segera membantu Anda'),
                  const SizedBox(width: 8),
                  _buildQuickReply('Selamat menonton! 🎬'),
                ],
              ),
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ketik balasan...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide:
                              const BorderSide(color: Color(0xFFDDDDDD)),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFB800),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon:
                          const Icon(Icons.send, color: Colors.white, size: 22),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageData message) {
    return Align(
      alignment:
          message.isFromUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isFromUser ? Colors.white : const Color(0xFFFFB800),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: message.isFromUser
                ? const Radius.circular(4)
                : const Radius.circular(16),
            bottomRight: message.isFromUser
                ? const Radius.circular(16)
                : const Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.isFromUser)
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: Color(0xFF001A4D)),
                  const SizedBox(width: 4),
                  Text(
                    _conversation.userName,
                    style: const TextStyle(
                      color: Color(0xFF001A4D),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            if (message.isFromUser) const SizedBox(height: 4),
            Text(
              message.text,
              style: TextStyle(
                color: message.isFromUser ? Colors.black87 : Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    color: message.isFromUser
                        ? Colors.grey.shade500
                        : Colors.white70,
                    fontSize: 10,
                  ),
                ),
                if (!message.isFromUser) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead ? Colors.blue : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReply(String text) {
    return GestureDetector(
      onTap: () {
        _messageController.text = text;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFB800).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFB800)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFFFFB800),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Baru saja';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m yang lalu';
    } else if (diff.inDays < 1) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  void _clearConversation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 22),
            SizedBox(width: 8),
            Text('Hapus Percakapan'),
          ],
        ),
        content: Text(
            'Apakah Anda yakin ingin menghapus percakapan dengan ${_conversation.userName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              ChatService.clearConversation(_conversation.userId);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close chat page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Percakapan berhasil dihapus'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showUserInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Color(0xFFFFB800), size: 22),
            SizedBox(width: 8),
            Text('Info User'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Nama', _conversation.userName),
            const Divider(),
            _buildInfoRow('User ID', _conversation.userId),
            const Divider(),
            _buildInfoRow('Total Pesan', '${_conversation.messages.length}'),
            const Divider(),
            _buildInfoRow(
              'Percakapan Dimulai',
              _formatTime(_conversation.messages.first.timestamp),
            ),
            const Divider(),
            _buildInfoRow(
              'Pesan Terakhir',
              _formatTime(_conversation.lastMessageTime),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
              ),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 12)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    ChatService.onNewMessageForAdmin = null;
    super.dispose();
  }
}

class AdminNotificationItem {
  final String id;
  final String title;
  final String message;
  final String type; // 'booking', 'payment', 'system'
  final DateTime createdAt;
  bool isRead;
  final Map<String, dynamic>? data;

  AdminNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });
}

// ==================== ADMIN NOTIFICATION PAGE ====================

class AdminNotificationPage extends StatefulWidget {
  const AdminNotificationPage({Key? key}) : super(key: key);

  @override
  State<AdminNotificationPage> createState() => _AdminNotificationPageState();
}

class _AdminNotificationPageState extends State<AdminNotificationPage> {
  List<AdminNotificationItem> notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    setState(() {
      notifications = AdminNotificationService.getAllNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = AdminNotificationService.getUnreadCount();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFB800),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.notifications, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              'Notifikasi Admin',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          if (notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'markAllRead') {
                  AdminNotificationService.markAllAsRead();
                  setState(() {
                    _loadNotifications();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Semua notifikasi ditandai sudah dibaca'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                } else if (value == 'clearAll') {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Hapus Semua'),
                      content: const Text(
                          'Apakah Anda yakin ingin menghapus semua notifikasi?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            AdminNotificationService.clearAllNotifications();
                            setState(() {
                              _loadNotifications();
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          child: const Text('Hapus',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'markAllRead',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, size: 20),
                      SizedBox(width: 8),
                      Text('Tandai Semua Sudah Dibaca'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clearAll',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Hapus Semua', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Belum Ada Notifikasi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Notifikasi pesanan akan muncul di sini',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.orange.shade50,
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Anda memiliki $unreadCount notifikasi baru',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(notifications[index]);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildNotificationCard(AdminNotificationItem notification) {
    Color typeColor;
    IconData typeIcon;

    switch (notification.type) {
      case 'booking':
        typeColor = Colors.green;
        typeIcon = Icons.confirmation_number;
        break;
      case 'payment':
        typeColor = Colors.blue;
        typeIcon = Icons.payment;
        break;
      default:
        typeColor = Colors.orange;
        typeIcon = Icons.info;
    }

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        AdminNotificationService.clearNotification(notification.id);
        setState(() {
          notifications.remove(notification);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifikasi dihapus'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          if (!notification.isRead) {
            AdminNotificationService.markAsRead(notification.id);
            setState(() {
              _loadNotifications();
            });
          }

          // Tampilkan detail jika ada data booking
          if (notification.data != null) {
            _showBookingDetail(notification.data!);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead
                  ? const Color(0xFFDDDDDD)
                  : Colors.orange.withValues(alpha: 0.3),
              width: notification.isRead ? 1 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead
                                    ? FontWeight.w600
                                    : FontWeight.bold,
                                fontSize: 14,
                                color: const Color(0xFF001A4D),
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.message,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF666666),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDateTime(notification.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBookingDetail(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFFFFB800), size: 22),
            SizedBox(width: 8),
            Text('Detail Pesanan'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Booking ID', data['bookingId'] ?? '-'),
              const Divider(),
              _buildDetailRow('User', data['userId'] ?? '-'),
              const Divider(),
              _buildDetailRow('Film', data['filmTitle'] ?? '-'),
              const Divider(),
              _buildDetailRow('Cinema', data['cinema'] ?? '-'),
              const Divider(),
              _buildDetailRow('Tanggal', data['date'] ?? '-'),
              const Divider(),
              _buildDetailRow('Waktu', data['time'] ?? '-'),
              const Divider(),
              _buildDetailRow(
                  'Kursi', (data['seats'] as List?)?.join(', ') ?? '-'),
              const Divider(),
              _buildDetailRow('Total', 'Rp${data['totalAmount'] ?? 0}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
              ),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 12)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;
  bool emailNotifications = false;
  late bool darkModeEnabled;
  String selectedLanguage = 'Bahasa Indonesia';
  late bool pinEnabled;
  late bool biometricEnabled;

  @override
  void initState() {
    super.initState();
    darkModeEnabled = SettingsService.getDarkMode();
    pinEnabled = SettingsService.isPinEnabled();
    biometricEnabled = SettingsService.isBiometricEnabled();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? Colors.white : const Color(0xFF001A4D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(Icons.settings,
                color:
                    isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D),
                size: 22),
            const SizedBox(width: 8),
            Text(
              'Pengaturan',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF001A4D),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Notifikasi Section
          _buildSectionTitle('Notifikasi', isDark),
          _buildSettingsCard(isDark, [
            SwitchListTile(
              title: const Text('Notifikasi Push'),
              subtitle: const Text('Terima notifikasi dari aplikasi'),
              value: notificationsEnabled,
              activeColor: const Color(0xFFFFB800),
              onChanged: (value) {
                setState(() {
                  notificationsEnabled = value;
                });
                _showSnackBar(value
                    ? 'Notifikasi diaktifkan'
                    : 'Notifikasi dinonaktifkan');
              },
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Email Notifikasi'),
              subtitle: const Text('Terima notifikasi via email'),
              value: emailNotifications,
              activeColor: const Color(0xFFFFB800),
              onChanged: (value) {
                setState(() {
                  emailNotifications = value;
                });
                _showSnackBar(value
                    ? 'Email notifikasi diaktifkan'
                    : 'Email notifikasi dinonaktifkan');
              },
            ),
          ]),

          const SizedBox(height: 20),

          // Tampilan Section
          _buildSectionTitle('Tampilan', isDark),
          _buildSettingsCard(isDark, [
            SwitchListTile(
              title: const Text('Mode Gelap'),
              subtitle: const Text('Ubah tema aplikasi'),
              value: darkModeEnabled,
              activeColor: const Color(0xFFFFB800),
              onChanged: (value) async {
                setState(() {
                  darkModeEnabled = value;
                });
                await SettingsService.setDarkMode(value);

                // Update theme secara real-time TANPA restart
                if (mounted) {
                  TixIDApp.updateTheme(context);
                  _showSnackBar(value
                      ? 'Mode Gelap diaktifkan'
                      : 'Mode Terang diaktifkan');
                }
              },
            ),
            const Divider(height: 1),
            ListTile(
              title: const Text('Bahasa'),
              subtitle: Text(selectedLanguage),
              trailing: Icon(Icons.chevron_right,
                  color:
                      isDark ? Colors.grey.shade600 : const Color(0xFF666666)),
              onTap: () => _showLanguageDialog(),
            ),
          ]),

          const SizedBox(height: 20),

          // Keamanan Section
          _buildSectionTitle('Keamanan & Privasi', isDark),
          _buildSettingsCard(isDark, [
            SwitchListTile(
              title: const Text('PIN 4 Digit'),
              subtitle: Text(
                  pinEnabled ? 'PIN aktif' : 'Tambahkan PIN untuk keamanan'),
              value: pinEnabled,
              activeColor: const Color(0xFFFFB800),
              onChanged: (value) {
                if (value) {
                  _setupPin();
                } else {
                  _removePin();
                }
              },
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Keamanan Biometrik'),
              subtitle: Text(biometricEnabled
                  ? 'Fingerprint/Face ID aktif'
                  : 'Gunakan sidik jari / Face ID'),
              value: biometricEnabled,
              activeColor: const Color(0xFFFFB800),
              onChanged: pinEnabled
                  ? (value) {
                      _toggleBiometric(value);
                    }
                  : null,
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.lock,
                  color: isDark
                      ? const Color(0xFFFFB800)
                      : const Color(0xFF001A4D)),
              title: const Text('Ubah PIN'),
              trailing: Icon(Icons.chevron_right,
                  color:
                      isDark ? Colors.grey.shade600 : const Color(0xFF666666)),
              enabled: pinEnabled,
              onTap: pinEnabled ? () => _changePin() : null,
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.privacy_tip,
                  color: isDark
                      ? const Color(0xFFFFB800)
                      : const Color(0xFF001A4D)),
              title: const Text('Kebijakan Privasi'),
              trailing: Icon(Icons.chevron_right,
                  color:
                      isDark ? Colors.grey.shade600 : const Color(0xFF666666)),
              onTap: () => _showPrivacyPolicy(),
            ),
          ]),

          const SizedBox(height: 20),

          // Tentang Aplikasi
          _buildSectionTitle('Tentang Aplikasi', isDark),
          _buildSettingsCard(isDark, [
            ListTile(
              leading: Icon(Icons.info,
                  color: isDark
                      ? const Color(0xFFFFB800)
                      : const Color(0xFF001A4D)),
              title: const Text('Versi Aplikasi'),
              subtitle: const Text('v1.0.0'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: const Text(
                  'Terbaru',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.grey.shade400 : const Color(0xFF666666),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Future<void> _setupPin() async {
    final pin = await _showPinSetupDialog();
    if (pin != null && pin.length == 4) {
      await SettingsService.setPin(pin);
      await SettingsService.setPinEnabled(true);
      setState(() {
        pinEnabled = true;
      });
      _showSnackBar('PIN berhasil diatur!');
    }
  }

  Future<void> _removePin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nonaktifkan PIN'),
        content: const Text('Apakah Anda yakin ingin menonaktifkan PIN?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Nonaktifkan',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await SettingsService.removePin();
      await SettingsService.setBiometricEnabled(false);
      setState(() {
        pinEnabled = false;
        biometricEnabled = false;
      });
      _showSnackBar('PIN berhasil dinonaktifkan!');
    }
  }

  Future<void> _changePin() async {
    final pin = await _showPinSetupDialog(isChange: true);
    if (pin != null && pin.length == 4) {
      await SettingsService.setPin(pin);
      _showSnackBar('PIN berhasil diubah!');
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final canCheck = await BiometricService.canCheckBiometrics();
      final isSupported = await BiometricService.isDeviceSupported();

      if (!canCheck || !isSupported) {
        _showSnackBar('Perangkat Anda tidak mendukung biometrik');
        return;
      }

      final authenticated = await BiometricService.authenticate();
      if (authenticated) {
        await SettingsService.setBiometricEnabled(true);
        setState(() {
          biometricEnabled = true;
        });
        _showSnackBar('Keamanan biometrik diaktifkan!');
      }
    } else {
      await SettingsService.setBiometricEnabled(false);
      setState(() {
        biometricEnabled = false;
      });
      _showSnackBar('Keamanan biometrik dinonaktifkan!');
    }
  }

  Future<String?> _showPinSetupDialog({bool isChange = false}) async {
    String pin = '';
    String confirmPin = '';
    bool isConfirming = false;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isChange ? 'Ubah PIN' : 'Buat PIN Baru'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isConfirming ? 'Konfirmasi PIN' : 'Masukkan PIN 4 digit',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index <
                                (isConfirming ? confirmPin.length : pin.length)
                            ? const Color(0xFFFFB800)
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    if (index == 9) return const SizedBox();

                    if (index == 10) {
                      return _buildDialogNumberButton('0', () {
                        setDialogState(() {
                          if (isConfirming) {
                            if (confirmPin.length < 4) confirmPin += '0';
                          } else {
                            if (pin.length < 4) pin += '0';
                          }
                        });
                      });
                    }

                    if (index == 11) {
                      return InkWell(
                        onTap: () {
                          setDialogState(() {
                            if (isConfirming) {
                              if (confirmPin.isNotEmpty) {
                                confirmPin = confirmPin.substring(
                                    0, confirmPin.length - 1);
                              }
                            } else {
                              if (pin.isNotEmpty) {
                                pin = pin.substring(0, pin.length - 1);
                              }
                            }
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade200,
                          ),
                          child: const Icon(Icons.backspace_outlined),
                        ),
                      );
                    }

                    return _buildDialogNumberButton('${index + 1}', () {
                      setDialogState(() {
                        if (isConfirming) {
                          if (confirmPin.length < 4) {
                            confirmPin += '${index + 1}';
                          }
                        } else {
                          if (pin.length < 4) {
                            pin += '${index + 1}';
                          }
                        }
                      });
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed:
                    (isConfirming ? confirmPin.length == 4 : pin.length == 4)
                        ? () {
                            if (!isConfirming) {
                              setDialogState(() {
                                isConfirming = true;
                              });
                            } else {
                              if (pin == confirmPin) {
                                Navigator.pop(context, pin);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('PIN tidak cocok!'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                setDialogState(() {
                                  confirmPin = '';
                                  isConfirming = false;
                                });
                              }
                            }
                          }
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB800),
                ),
                child: Text(
                  isConfirming ? 'Simpan' : 'Lanjut',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDialogNumberButton(String number, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade200,
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Bahasa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Bahasa Indonesia'),
              value: 'Bahasa Indonesia',
              groupValue: selectedLanguage,
              activeColor: const Color(0xFFFFB800),
              onChanged: (value) {
                setState(() => selectedLanguage = value!);
                Navigator.pop(context);
                _showSnackBar('Bahasa diubah ke $value');
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'English',
              groupValue: selectedLanguage,
              activeColor: const Color(0xFFFFB800),
              onChanged: (value) {
                setState(() => selectedLanguage = value!);
                Navigator.pop(context);
                _showSnackBar('Language changed to $value');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kebijakan Privasi'),
        content: const SingleChildScrollView(
          child: Text(
            'CINEMA 1 berkomitmen untuk melindungi privasi pengguna.\n\n'
            '1. Pengumpulan Data\n'
            'Kami mengumpulkan data yang Anda berikan saat mendaftar.\n\n'
            '2. Penggunaan Data\n'
            'Data digunakan untuk memberikan layanan terbaik.\n\n'
            '3. Keamanan Data\n'
            'Kami menggunakan enkripsi untuk melindungi data Anda.\n\n'
            '4. Hak Pengguna\n'
            'Anda berhak mengakses, mengubah, atau menghapus data Anda.',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class HelpPage extends StatelessWidget {
  const HelpPage({Key? key}) : super(key: key);

  Future<void> _launchWhatsApp(BuildContext context) async {
    const phoneNumber = '6288291389753';
    const message = 'Halo CINEMA 1, saya membutuhkan bantuan.';

    final whatsappUrl = Uri.parse(
        'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(
          whatsappUrl,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (context.mounted) {
          _showErrorDialog(
            context,
            'WhatsApp tidak ditemukan',
            'Pastikan WhatsApp sudah terinstal di perangkat Anda.',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(
          context,
          'Gagal membuka WhatsApp',
          'Terjadi kesalahan: $e',
        );
      }
    }
  }

  void _openChatCS(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatCSPage(),
      ),
    );
  }

  Future<void> _launchPhone(BuildContext context) async {
    const phoneNumber = '6288291389753';
    final phoneUrl = Uri.parse('tel:$phoneNumber');

    try {
      if (await canLaunchUrl(phoneUrl)) {
        await launchUrl(phoneUrl);
      } else {
        if (context.mounted) {
          _showSnackBar(context, '📞 Nomor: 0882-9138-9753');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, '📞 Nomor: 0882-9138-9753');
      }
    }
  }

  Future<void> _launchEmail(BuildContext context) async {
    final emailUrl =
        Uri.parse('mailto:alfianawinanto7@gmail.com?subject=Bantuan CINEMA 1');

    try {
      if (await canLaunchUrl(emailUrl)) {
        await launchUrl(emailUrl);
      } else {
        if (context.mounted) {
          _showSnackBar(context, '📧 alfianawinanto7@gmail.com');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, '📧 alfianawinanto7@gmail.com');
      }
    }
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 22),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          ],
        ),
        content: Text(message,
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? Colors.white : const Color(0xFF001A4D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(Icons.help,
                color:
                    isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D),
                size: 22),
            const SizedBox(width: 8),
            Text(
              'Bantuan',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF001A4D),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Search Bar
          TextField(
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'Cari pertanyaan...',
              hintStyle: TextStyle(
                  color:
                      isDark ? Colors.grey.shade600 : const Color(0xFF666666)),
              prefixIcon: Icon(Icons.search,
                  color:
                      isDark ? Colors.grey.shade600 : const Color(0xFF666666)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(
                    color: isDark
                        ? Colors.grey.shade800
                        : const Color(0xFFDDDDDD)),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            ),
          ),

          const SizedBox(height: 24),

          _buildSectionTitle('Pertanyaan Umum', isDark),
          _buildFAQItem(
            context,
            'Bagaimana cara memesan tiket?',
            '1. Pilih film yang ingin ditonton\n'
                '2. Pilih jadwal dan bioskop\n'
                '3. Pilih kursi yang diinginkan\n'
                '4. Lakukan pembayaran\n'
                '5. Tiket akan muncul di menu "Tiket Saya"',
            Icons.confirmation_number,
            isDark,
          ),

          _buildFAQItem(
            context,
            'Bagaimana cara membatalkan tiket?',
            'Maaf, tiket yang sudah dibeli tidak dapat dibatalkan atau direfund. '
                'Pastikan Anda sudah memilih jadwal dan kursi yang tepat sebelum melakukan pembayaran.',
            Icons.cancel,
            isDark,
          ),

          _buildFAQItem(
            context,
            'Metode pembayaran apa saja yang tersedia?',
            'CINEMA 1 menerima berbagai metode pembayaran:\n'
                '• DANA\n'
                '• GoPay\n'
                '• ShopeePay\n'
                '• OVO\n',
            Icons.payment,
            isDark,
          ),

          _buildFAQItem(
            context,
            'Bagaimana cara menggunakan e-ticket?',
            '1. Buka menu "Tiket Saya"\n'
                '2. Pilih tiket yang ingin digunakan\n'
                '3. Tunjukkan QR Code ke petugas\n'
                '4. Petugas akan memindai QR Code Anda\n'
                '5. Selamat menonton!',
            Icons.qr_code_scanner,
            isDark,
          ),

          _buildFAQItem(
            context,
            'Apa itu Watchlist?',
            'Watchlist adalah fitur untuk menyimpan film favorit Anda. '
                'Film yang ada di watchlist dapat Anda akses dengan mudah tanpa harus mencari lagi.',
            Icons.favorite,
            isDark,
          ),

          const SizedBox(height: 24),

          _buildSectionTitle('Hubungi Kami', isDark),
          _buildContactCard(context, isDark),

          const SizedBox(height: 24),

          _buildSectionTitle('Aksi Cepat', isDark),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  context,
                  'Chat CS',
                  Icons.chat,
                  () => _openChatCS(context),
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  context,
                  'Email',
                  Icons.email,
                  () => _launchEmail(context),
                  isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.grey.shade400 : const Color(0xFF666666),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFAQItem(
    BuildContext context,
    String question,
    String answer,
    IconData icon,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          unselectedWidgetColor: isDark ? Colors.grey.shade600 : null,
        ),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  (isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D))
                      .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                color:
                    isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D),
                size: 20),
          ),
          title: Text(
            question,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          iconColor: isDark ? Colors.white : Colors.black,
          collapsedIconColor: isDark ? Colors.white : Colors.black,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                answer,
                style: TextStyle(
                  fontSize: 13,
                  color:
                      isDark ? Colors.grey.shade400 : const Color(0xFF666666),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFFFFB800),
                  const Color(0xFFFFB800).withValues(alpha: 0.7),
                ]
              : [
                  const Color(0xFF001A4D),
                  const Color(0xFF0066CC).withValues(alpha: 0.8),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D))
                .withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.support_agent, color: Colors.white, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Customer Service',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kami siap membantu Anda 24/7',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildContactButton(
                context,
                Icons.phone,
                'Telepon',
                () => _launchPhone(context),
              ),
              _buildContactButton(
                context,
                Icons.email,
                'Email',
                () => _launchEmail(context),
              ),
              _buildContactButton(
                context,
                Icons.chat,
                'WhatsApp',
                () => _launchWhatsApp(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
    bool isDark,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon,
          color: isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D),
          size: 20),
      label: Text(
        label,
        style: TextStyle(
          color: isDark ? const Color(0xFFFFB800) : const Color(0xFF001A4D),
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
// ==================== CHAT CS PAGE (UPDATED) ====================

class ChatCSPage extends StatefulWidget {
  const ChatCSPage({Key? key}) : super(key: key);

  @override
  State<ChatCSPage> createState() => _ChatCSPageState();
}

class _ChatCSPageState extends State<ChatCSPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ChatConversation? _conversation;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadConversation();
    _startAutoRefresh();

    // Setup callback untuk notifikasi pesan baru
    ChatService.onNewMessageForUser = (userId) {
      if (userId == AuthService.getCurrentUsername() && mounted) {
        _loadConversation();
      }
    };
  }

  void _loadConversation() {
    final userId = AuthService.getCurrentUsername();
    if (userId != null) {
      setState(() {
        _conversation = ChatService.getConversation(userId);
        if (_conversation != null) {
          ChatService.markAsReadByUser(userId);
        }
      });
      _scrollToBottom();
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _loadConversation();
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final userId = AuthService.getCurrentUsername();
    final userProfile = AuthService.getCurrentUserProfile();

    if (userId == null || userProfile == null) return;

    final messageText = _messageController.text.trim();

    ChatService.sendMessageFromUser(
      userId: userId,
      userName: userProfile.name,
      message: messageText,
    );

    _messageController.clear();
    _loadConversation();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = _conversation?.messages ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF001A4D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFB800), width: 2),
              ),
              child: const Icon(
                Icons.support_agent,
                color: Color(0xFF001A4D),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer Service',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Admin CINEMA 1',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'whatsapp') {
                _launchWhatsApp();
              } else if (value == 'clear') {
                _clearChat();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'whatsapp',
                child: Row(
                  children: [
                    Icon(Icons.chat, size: 20, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Chat via WhatsApp'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Hapus Percakapan'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada percakapan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kirim pesan untuk memulai chat dengan admin',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade500),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(messages[index]);
                    },
                  ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ketik pesan...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide:
                              const BorderSide(color: Color(0xFFDDDDDD)),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF001A4D),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon:
                          const Icon(Icons.send, color: Colors.white, size: 22),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageData message) {
    return Align(
      alignment:
          message.isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isFromUser ? const Color(0xFF001A4D) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: message.isFromUser
                ? const Radius.circular(16)
                : const Radius.circular(4),
            bottomRight: message.isFromUser
                ? const Radius.circular(4)
                : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isFromUser)
              Row(
                children: [
                  const Icon(Icons.admin_panel_settings,
                      size: 14, color: Color(0xFFFFB800)),
                  const SizedBox(width: 4),
                  Text(
                    'Admin',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            if (!message.isFromUser) const SizedBox(height: 4),
            Text(
              message.text,
              style: TextStyle(
                color: message.isFromUser ? Colors.white : Colors.black87,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    color: message.isFromUser
                        ? Colors.white70
                        : Colors.grey.shade500,
                    fontSize: 10,
                  ),
                ),
                if (message.isFromUser) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead ? Colors.blue : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Baru saja';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m yang lalu';
    } else if (diff.inDays < 1) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 22),
            SizedBox(width: 8),
            Text('Hapus Percakapan'),
          ],
        ),
        content: const Text(
            'Apakah Anda yakin ingin menghapus semua percakapan dengan admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final userId = AuthService.getCurrentUsername();
              if (userId != null) {
                ChatService.clearConversation(userId);
                _loadConversation();
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Percakapan berhasil dihapus'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchWhatsApp() async {
    const phoneNumber = '6288291389753';
    const message = 'Halo CINEMA 1, saya membutuhkan bantuan.';

    final whatsappUrl = Uri.parse(
        'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('WhatsApp tidak ditemukan'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka WhatsApp: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    ChatService.onNewMessageForUser = null;
    super.dispose();
  }
}

// ==================== CHAT MESSAGE MODEL ====================

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
