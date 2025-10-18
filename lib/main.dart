import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

void main() {
  print('Initial Active: ${TicketHistoryService.getActiveTickets()}');
  runApp(const TixIDApp());
}

class TixIDApp extends StatelessWidget {
  const TixIDApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TIX ID',
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
        ),
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
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
      phoneNumber: '081234567890',
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
      profileImageUrl:
          'https://i.pinimg.com/736x/c8/05/30/c80530f1ad4fa82dfc8a78a7665cd8f7.jpg',
      backgroundImageUrl:
          'https://i.pinimg.com/736x/04/7b/ab/047bab988a4771be2f77d0e3bf36c5ff.jpg',
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

// ==================== TICKET HISTORY SERVICE ====================

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
      ['A15', 'A14', 'A13', 'A12', '', '', 'A9', 'A8', 'A7'],
      ['B15', 'B14', 'B13', 'B12', '', '', 'B9', 'B8', 'B7'],
      ['C15', 'C14', 'C13', 'C12', '', '', 'C9', 'C8', 'C7'],
      ['D15', 'D14', 'D13', 'D12', '', '', 'D9', 'D8', 'D7'],
      ['E15', 'E14', 'E13', 'E12', '', '', 'E9', 'E8', 'E7'],
      ['F15', 'F14', 'F13', 'F12', '', '', 'F9', 'F8', 'F7'],
      ['G15', 'G14', 'G13', 'G12', '', '', 'G9', 'G8', 'G7'],
      ['H15', 'H14', 'H13', 'H12', '', '', 'H9', 'H8', 'H7'],
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
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
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xfffbfcfd),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'TIX ID',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff13013b),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Masuk ke TIX ID',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff0a0118),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
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
                decoration: InputDecoration(
                  hintText: 'Masukkan username',
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
                    borderSide: const BorderSide(color: Color(0xFF001A4D)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                decoration: InputDecoration(
                  hintText: 'Masukkan Password',
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
                    borderSide: const BorderSide(color: Color(0xFF001A4D)),
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
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Reset Password',
                    style: TextStyle(
                      color: Color(0xFF001A4D),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF001A4D),
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
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Belum punya akun? '),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RegisterPage()),
                      );
                    },
                    child: const Text(
                      'Daftar Sekarang',
                      style: TextStyle(
                        color: Color(0xFF001A4D),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF001A4D)),
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
                  color: const Color(0xfffbfcfd),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'TIX ID',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff050644),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Daftar Akun Baru',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF001A4D),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
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
                decoration: InputDecoration(
                  hintText: 'Masukkan username',
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
                    borderSide: const BorderSide(color: Color(0xFF001A4D)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                decoration: InputDecoration(
                  hintText: 'Masukkan password',
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
                    borderSide: const BorderSide(color: Color(0xFF001A4D)),
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
              ),
              const SizedBox(height: 16),
              const Text(
                'KONFIRMASI PASSWORD',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  hintText: 'Konfirmasi password',
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
                    borderSide: const BorderSide(color: Color(0xFF001A4D)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
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
                  backgroundColor: const Color(0xFF001A4D),
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
                  const Text('Sudah punya akun? '),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: Color(0xFF001A4D),
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

// ==================== HOMEPAGE - PART 1 ====================

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
  late PageController _pageController;
  List<Film> filteredFilms = [];
  List<String> favoriteCinemas = [];

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
    _pageController = PageController(viewportFraction: 0.65);
    _loadFilms();

    print('');
    print('═══════════════════════════════════════');
    print('📱 HomePage Initialized');
    print('═══════════════════════════════════════');
    print('📌 Selected Tab: $selectedTab');
    print('📌 Current User: ${AuthService.getCurrentUsername()}');
    print(
        '📌 Active Tickets: ${TicketHistoryService.getActiveTickets().length}');
    print('═══════════════════════════════════════');
    print('');
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
      _scrollController.animateTo(500,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
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
              color: const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Icon(Icons.location_on, color: Color(0xFFFFB800), size: 28),
              SizedBox(width: 12),
              Text('Pilih Bioskop Favorit',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Tandai bioskop favorit untuk akses lebih cepat',
                style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
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
                          : const Color(0xFFDDDDDD),
                      width: isFavorite ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: isFavorite ? const Color(0xFFFFF8E1) : Colors.white,
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isFavorite
                            ? const Color(0xFFFFB800).withOpacity(0.2)
                            : const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isFavorite ? Icons.star : Icons.star_outline,
                        color: isFavorite
                            ? const Color(0xFFFFB800)
                            : const Color(0xFFCCCCCC),
                        size: 24,
                      ),
                    ),
                    title: Text(cinema,
                        style: TextStyle(
                          fontWeight:
                              isFavorite ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
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
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFDDDDDD))),
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
        title: const Row(children: [
          Icon(Icons.add_circle, color: Color(0xFF001A4D), size: 24),
          SizedBox(width: 8),
          Text('Tambah Film Baru'),
        ]),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Judul Film',
                prefixIcon: const Icon(Icons.movie, color: Color(0xFF001A4D)),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: genreController,
              decoration: InputDecoration(
                labelText: 'Genre',
                prefixIcon:
                    const Icon(Icons.category, color: Color(0xFF001A4D)),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: durationController,
              decoration: InputDecoration(
                labelText: 'Durasi',
                prefixIcon:
                    const Icon(Icons.schedule, color: Color(0xFF001A4D)),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ratingController,
              decoration: InputDecoration(
                labelText: 'Rating',
                prefixIcon: const Icon(Icons.star, color: Color(0xFFFFB800)),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: directorController,
              decoration: InputDecoration(
                labelText: 'Director',
                prefixIcon: const Icon(Icons.person, color: Color(0xFF001A4D)),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ageRatingController,
              decoration: InputDecoration(
                labelText: 'Age Rating',
                prefixIcon: const Icon(Icons.info, color: Color(0xFF001A4D)),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: imageUrlController,
              decoration: InputDecoration(
                labelText: 'Image URL',
                prefixIcon: const Icon(Icons.image, color: Color(0xFF001A4D)),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: trailerUrlController,
              decoration: InputDecoration(
                labelText: 'YouTube Trailer URL',
                hintText: 'https://youtu.be/...',
                prefixIcon:
                    const Icon(Icons.play_circle, color: Color(0xFF001A4D)),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ]),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Row(children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Film berhasil ditambahkan!'),
                  ]),
                  backgroundColor: Colors.green,
                ));
              }
            },
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Simpan', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF001A4D)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF001A4D), size: 28),
          onPressed: () {},
          tooltip: 'Menu',
        ),
        title: const Row(children: [
          Icon(Icons.movie, color: Color(0xFF001A4D), size: 24),
          SizedBox(width: 8),
          Text('TIX ID',
              style: TextStyle(
                color: Color(0xFF001A4D),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              )),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: Color(0xFF001A4D), size: 26),
            onPressed: _showAddFilmDialog,
            tooltip: 'Tambah Film',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: Color(0xFF001A4D), size: 26),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tidak ada notifikasi baru')));
            },
            tooltip: 'Notifikasi',
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined,
                color: Color(0xFF001A4D), size: 26),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()));
            },
            tooltip: 'Profil',
          ),
        ],
      ),
      body: selectedTab == 0
          ? _buildBerandaTab()
          : selectedTab == 1
              ? const TicketHistoryPage()
              : const ProfilePage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedTab,
        selectedItemColor: const Color(0xFF001A4D),
        unselectedItemColor: const Color(0xFFCCCCCC),
        selectedFontSize: 12,
        unselectedFontSize: 11,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
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

  Widget _buildBerandaTab() {
    return ListView(
      controller: _scrollController,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: searchController,
            onChanged: _searchFilms,
            decoration: InputDecoration(
              hintText: 'Cari film di TIX ID',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF666666)),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF666666)),
                      onPressed: () {
                        searchController.clear();
                        _searchFilms('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
              ),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
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
            color: const Color(0xFFF0F8FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF0066CC), width: 1),
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
            const Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tandai bioskop favoritmu!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        )),
                    SizedBox(height: 4),
                    Text('Akses bioskop favorit dengan lebih cepat',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF666666))),
                  ]),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _showCinemaSelectionDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF001A4D),
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
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isFavorite
                          ? const Color(0xFFFFB800)
                          : const Color(0xFFDDDDDD),
                      width: isFavorite ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: isFavorite ? const Color(0xFFFFF8E1) : Colors.white,
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
                                    ? const Color(0xFFFFB800).withOpacity(0.2)
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                isFavorite ? Icons.star : Icons.star_outline,
                                size: 16,
                                color: isFavorite
                                    ? const Color(0xFFFFB800)
                                    : const Color(0xFFCCCCCC),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              const Icon(Icons.local_movies,
                  color: Color(0xFF001A4D), size: 22),
              const SizedBox(width: 8),
              Text(
                  searchController.text.isEmpty
                      ? 'Sedang Tayang'
                      : 'Hasil Pencarian (${filteredFilms.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  )),
            ]),
            if (searchController.text.isEmpty)
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Semua'),
              ),
          ]),
        ),
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
          Stack(alignment: Alignment.center, children: [
            SizedBox(
              height: 340,
              child: PageView.builder(
                controller: _pageController,
                itemCount: filteredFilms.length,
                padEnds: false,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double value = 1.0;
                      if (_pageController.position.haveDimensions) {
                        double? page = _pageController.page;
                        if (page != null) {
                          value = page - index;
                          value = (1 - (value.abs() * 0.3)).clamp(0.7, 1.0);
                        }
                      }
                      return Center(
                        child: Transform.scale(
                          scale: Curves.easeInOut.transform(value),
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _Film3DCard(
                        film: filteredFilms[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FilmDetailPage(
                                film: filteredFilms[index],
                                onUpdate: _loadFilms,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.chevron_left,
                      color: Color(0xFF001A4D), size: 30),
                  onPressed: () {
                    if (_pageController.hasClients) {
                      final currentPage = _pageController.page ?? 0;
                      if (currentPage > 0) {
                        _pageController.animateToPage(
                          (currentPage - 1).round(),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    }
                  },
                ),
              ),
            ),
            Positioned(
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.chevron_right,
                      color: Color(0xFF001A4D), size: 30),
                  onPressed: () {
                    if (_pageController.hasClients) {
                      final currentPage = _pageController.page ?? 0;
                      if (currentPage < filteredFilms.length - 1) {
                        _pageController.animateToPage(
                          (currentPage + 1).round(),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    }
                  },
                ),
              ),
            ),
          ]),
        const SizedBox(height: 20),
      ],
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
              color: Colors.black.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: const Color(0xFF001A4D).withOpacity(0.1),
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
                      Colors.black.withOpacity(0.7),
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
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.5)),
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
                        color: Colors.white.withOpacity(0.9),
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

// ==================== FILM DETAIL PAGE - PART 1 ====================
// ==================== FILM DETAIL PAGE - FIXED ====================

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
  bool _isControllerReady = false; // ✅ TAMBAH INI

  late TabController _tabController;

  final List<Schedule> schedules = [
    Schedule(date: '10 Okt', day: 'JUM', times: []),
    Schedule(date: '11 Okt', day: 'SAB', times: []),
    Schedule(date: '12 Okt', day: 'MIN', times: []),
    Schedule(date: '13 Okt', day: 'SEN', times: []),
    Schedule(date: '14 Okt', day: 'SEL', times: []),
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

  // ✅ METODE EKSTRAK VIDEO ID YANG LEBIH ROBUST
  String? _extractYoutubeId(String url) {
    try {
      // Format: https://youtu.be/VIDEO_ID atau https://youtu.be/VIDEO_ID?...
      if (url.contains('youtu.be/')) {
        final parts = url.split('youtu.be/');
        if (parts.length > 1) {
          return parts[1].split('?').first.split('&').first;
        }
      }
      // Format: https://www.youtube.com/watch?v=VIDEO_ID&...
      if (url.contains('youtube.com') && url.contains('v=')) {
        final uri = Uri.parse(url);
        return uri.queryParameters['v'];
      }
      return null;
    } catch (e) {
      print('❌ Error mengekstrak YouTube ID: $e');
      return null;
    }
  }

  @override
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

    // ✅ INISIALISASI DENGAN LISTENER
    try {
      String? videoId = YoutubePlayer.convertUrlToId(widget.film.trailerUrl);

      if (videoId == null || videoId.isEmpty) {
        videoId = _extractYoutubeId(widget.film.trailerUrl);
      }

      if (videoId == null || videoId.isEmpty) {
        print('⚠️ Gagal ekstrak');
        videoId = 'dQw4w9WgXcQ';
      }

      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          disableDragSeek: false,
          loop: false,
          enableCaption: true,
        ),
      );

      // ✅ TAMBAH LISTENER
      _youtubeController.addListener(() {
        if (_youtubeController.value.isReady && !_isControllerReady) {
          setState(() {
            _isControllerReady = true;
          });
          print('✅ YouTube Player READY!');
        }
      });

      // ✅ DELAY UNTUK MEMASTIKAN
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isControllerReady = true;
          });
        }
      });

      print('✅ Controller init dengan ID: $videoId');
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  void _toggleTrailer() {
    if (!_isControllerReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tunggu sebentar, video sedang dimuat...'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _showTrailer = !_showTrailer;
    });

    if (_showTrailer) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _isControllerReady) {
          _youtubeController.play();
          print('▶️ Video mulai diputar');
        }
      });
    } else {
      _youtubeController.pause();
    }
  }

  void _showEditFilmDialog() {
    final titleController = TextEditingController(text: widget.film.title);
    final genreController = TextEditingController(text: widget.film.genre);
    final durationController =
        TextEditingController(text: widget.film.duration);
    final ratingController = TextEditingController(text: widget.film.rating);
    final directorController =
        TextEditingController(text: widget.film.director);
    final ageRatingController =
        TextEditingController(text: widget.film.ageRating);
    final imageUrlController =
        TextEditingController(text: widget.film.imageUrl);
    final trailerUrlController =
        TextEditingController(text: widget.film.trailerUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit, color: Color(0xFF001A4D), size: 22),
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
                  prefixIcon: Icon(Icons.movie, color: Color(0xFF001A4D)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: genreController,
                decoration: const InputDecoration(
                  labelText: 'Genre',
                  prefixIcon: Icon(Icons.category, color: Color(0xFF001A4D)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(
                  labelText: 'Durasi',
                  prefixIcon: Icon(Icons.schedule, color: Color(0xFF001A4D)),
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
                  prefixIcon: Icon(Icons.person, color: Color(0xFF001A4D)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ageRatingController,
                decoration: const InputDecoration(
                  labelText: 'Age Rating',
                  prefixIcon: Icon(Icons.info, color: Color(0xFF001A4D)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  prefixIcon: Icon(Icons.image, color: Color(0xFF001A4D)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: trailerUrlController,
                decoration: const InputDecoration(
                  labelText: 'Trailer URL',
                  hintText: 'https://youtu.be/...',
                  prefixIcon: Icon(Icons.play_circle, color: Color(0xFF001A4D)),
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
                id: widget.film.id,
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
              widget.onUpdate();
              Navigator.pop(context);
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
                ),
              );
            },
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Update', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF001A4D),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteFilm() {
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
        content:
            Text('Apakah Anda yakin ingin menghapus "${widget.film.title}"?'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              FilmService.deleteFilm(widget.film.id);
              widget.onUpdate();
              Navigator.pop(context);
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

  List<CinemaLocation> _getFilteredCinemas() {
    if (selectedCinema == 'Semua') {
      return cinemas;
    }
    return cinemas.where((cinema) => cinema.type == selectedCinema).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: _showTrailer ? 300 : 250,
            pinned: true,
            backgroundColor: const Color(0xFF001A4D),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: _showEditFilmDialog,
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: _deleteFilm,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // ✅ TAMPILKAN YOUTUBE PLAYER LANGSUNG TANPA LOADING
                  if (_showTrailer)
                    YoutubePlayer(
                      controller: _youtubeController,
                      showVideoProgressIndicator: true,
                      progressIndicatorColor: const Color(0xFFFFB800),
                      progressColors: const ProgressBarColors(
                        playedColor: Color(0xFF001A4D),
                        handleColor: Color(0xFFFFB800),
                        bufferedColor: Colors.white24,
                        backgroundColor: Colors.white12,
                      ),
                    )
                  else
                    Image.network(
                      widget.film.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFF001A4D),
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
                            Colors.black.withOpacity(0.3),
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  // ✅ TOMBOL PLAY LANGSUNG SIAP DIGUNAKAN
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
                                color: Colors.black.withOpacity(0.3),
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
                  if (_showTrailer)
                    Positioned(
                      top: 50,
                      right: 16,
                      child: GestureDetector(
                        onTap: _toggleTrailer,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 24),
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
                  color: Colors.white,
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow('Genre', widget.film.genre),
                            const SizedBox(height: 4),
                            _buildInfoRow('Durasi', widget.film.duration),
                            const SizedBox(height: 4),
                            _buildInfoRow('Sutradara', widget.film.director),
                            const SizedBox(height: 4),
                            _buildInfoRow('Rating Usia', widget.film.ageRating),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: Colors.white,
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
                          const Text(
                            '5.984 Vote ▸',
                            style: TextStyle(
                                color: Color(0xFF999999), fontSize: 12),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.red),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.favorite_border,
                                    color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text('Masukkan watchlist',
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '21.441 Orang',
                            style: TextStyle(
                                color: Color(0xFF999999), fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF001A4D),
                    unselectedLabelColor: const Color(0xFF999999),
                    indicatorColor: const Color(0xFF001A4D),
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
                      const SingleChildScrollView(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.\n\nDuis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
                          style: TextStyle(
                              fontSize: 14, height: 1.6, color: Colors.black87),
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF999999), fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildJadwalTab() {
    return SingleChildScrollView(
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
                      color:
                          isSelected ? const Color(0xFF001A4D) : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF001A4D)
                            : const Color(0xFFDDDDDD),
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
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          schedule.day,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? Colors.white70
                                : const Color(0xFF999999),
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
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFilterButton('Sortir', 'Terdekat', () {}),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFilterButton('Studio', 'Semua', () {}),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFDDDDDD)),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.search, color: Color(0xFF001A4D)),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                  ),
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
    );
  }

  Widget _buildFilterButton(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDDDDDD)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style:
                        const TextStyle(fontSize: 10, color: Color(0xFF999999)),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Color(0xFF999999)),
          ],
        ),
      ),
    );
  }

  Widget _buildCinemaCard(CinemaLocation cinema) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.star_outline,
                    size: 24, color: Color(0xFFCCCCCC)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    cinema.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cinema.type == 'CGV'
                        ? Colors.red
                        : cinema.type == 'IMAX'
                            ? Colors.blue
                            : cinema.type == 'CINEPOLIS'
                                ? Colors.orange
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
            decoration: const BoxDecoration(
              color: Color(0xFFF8F8F8),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.theater_comedy,
                        color: Color(0xFF666666), size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Layar besar, suara hebat! Amankan kursimu',
                      style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.local_fire_department,
                        color: Colors.orange, size: 16),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: cinema.times.map((time) {
                    final isSelected = selectedTime == time &&
                        selectedCinemaLocation == cinema.name;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedTime = time;
                          selectedCinemaLocation = cinema.name;
                        });

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
                          color: isSelected
                              ? const Color(0xFF001A4D)
                              : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF001A4D)
                                : const Color(0xFFDDDDDD),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          time,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
            const SizedBox(height: 12),
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
              'Pilih Bioskop',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.check_circle_outline,
                  color: Color(0xFF001A4D)),
              title: const Text('Semua Bioskop'),
              trailing: selectedCinema == 'Semua'
                  ? const Icon(Icons.check, color: Color(0xFF001A4D))
                  : null,
              onTap: () {
                setState(() {
                  selectedCinema = 'Semua';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_movies, color: Colors.red),
              title: const Text('CGV'),
              trailing: selectedCinema == 'CGV'
                  ? const Icon(Icons.check, color: Color(0xFF001A4D))
                  : null,
              onTap: () {
                setState(() {
                  selectedCinema = 'CGV';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_movies, color: Color(0xFF001A4D)),
              title: const Text('XXI'),
              trailing: selectedCinema == 'XXI'
                  ? const Icon(Icons.check, color: Color(0xFF001A4D))
                  : null,
              onTap: () {
                setState(() {
                  selectedCinema = 'XXI';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_movies, color: Colors.blue),
              title: const Text('IMAX'),
              trailing: selectedCinema == 'IMAX'
                  ? const Icon(Icons.check, color: Color(0xFF001A4D))
                  : null,
              onTap: () {
                setState(() {
                  selectedCinema = 'IMAX';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_movies, color: Colors.orange),
              title: const Text('CINEPOLIS'),
              trailing: selectedCinema == 'CINEPOLIS'
                  ? const Icon(Icons.check, color: Color(0xFF001A4D))
                  : null,
              onTap: () {
                setState(() {
                  selectedCinema = 'CINEPOLIS';
                });
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    try {
      _youtubeController.dispose();
    } catch (e) {
      print('Error dispose YouTube controller: $e');
    }
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
    ['A15', 'A14', 'A13', 'A12', '', '', 'A9', 'A8', 'A7'],
    ['B15', 'B14', 'B13', 'B12', '', '', 'B9', 'B8', 'B7'],
    ['C15', 'C14', 'C13', 'C12', '', '', 'C9', 'C8', 'C7'],
    ['D15', 'D14', 'D13', 'D12', '', '', 'D9', 'D8', 'D7'],
    ['E15', 'E14', 'E13', 'E12', '', '', 'E9', 'E8', 'E7'],
    ['F15', 'F14', 'F13', 'F12', '', '', 'F9', 'F8', 'F7'],
    ['G15', 'G14', 'G13', 'G12', '', '', 'G9', 'G8', 'G7'],
    ['H15', 'H14', 'H13', 'H12', '', '', 'H9', 'H8', 'H7'],
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
    final seatData = seatsData[seatNumber];

    if (seatData == null) {
      return const Color(0xFF001A4D);
    }

    if (selectedSeats.contains(seatNumber)) {
      return const Color(0xFF0066CC);
    }

    if (seatData['status'] == 'booked') {
      return const Color(0xFFCCCCCC);
    }

    if (seatData['status'] == 'selected' &&
        seatData['userId'] != widget.userId) {
      return const Color(0xFFEEEEEE);
    }

    return const Color(0xFF001A4D);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF001A4D)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Memuat kursi...',
            style: TextStyle(color: Color(0xFF001A4D), fontSize: 14),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF001A4D)),
              const SizedBox(height: 16),
              const Text('Memuat data kursi...',
                  style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
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
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF001A4D)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('Gagal memuat data kursi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                  backgroundColor: const Color(0xFF001A4D),
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF001A4D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.cinema,
              style: const TextStyle(
                color: Color(0xFF001A4D),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${widget.date} | ${widget.time}',
              style: const TextStyle(color: Color(0xFF666666), fontSize: 10),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.access_time, color: Color(0xFF001A4D)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.access_time,
                          color: Color(0xFF001A4D), size: 22),
                      SizedBox(width: 8),
                      Text('Waktu Pemesanan'),
                    ],
                  ),
                  content: const Text(
                      'Kursi yang dipilih akan direservasi selama 10 menit.'),
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
                    _buildLegend(const Color(0xFF001A4D), 'Tersedia'),
                    _buildLegend(const Color(0xFFCCCCCC), 'Tidak Tersedia'),
                    _buildLegend(const Color(0xFF0066CC), 'Pilihanmu'),
                    _buildLegend(const Color(0xFFEEEEEE), 'Dipilih Lain'),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFDDDDDD)),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: const Text(
                    'LAYAR',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF999999),
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
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
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
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('TOTAL HARGA',
                                style: TextStyle(
                                    fontSize: 11, color: Color(0xFF666666))),
                            const Text('TEMPAT DUDUK',
                                style: TextStyle(
                                    fontSize: 11, color: Color(0xFF666666))),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
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
                            ? const Color(0xFFCCCCCC)
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
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
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
        Text(label, style: const TextStyle(fontSize: 9)),
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
    int totalPrice = widget.selectedSeats.length * 55000;
    int serviceFee = widget.selectedSeats.length * 4000;
    int finalPrice = totalPrice + serviceFee;

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
          'Ringkasan Pembayaran',
          style: TextStyle(
              color: Color(0xFF001A4D),
              fontWeight: FontWeight.bold,
              fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.red.withOpacity(0.1),
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
                _buildFilmInfo(),
                const SizedBox(height: 16),
                _buildTransactionDetail(totalPrice, serviceFee, finalPrice),
                const SizedBox(height: 16),
                _buildPaymentMethods(),
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
                  ? const Color(0xFFCCCCCC)
                  : const Color(0xFF001A4D),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilmInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Color(0xFFFFB800)),
                    const SizedBox(width: 4),
                    Text(widget.film.rating,
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF001A4D).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.film.ageRating,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF001A4D)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 12, color: Color(0xFF666666)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.cinema,
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
                      '${widget.date}, ${widget.time}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
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
      int totalPrice, int serviceFee, int finalPrice) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long, color: Color(0xFF001A4D), size: 20),
              SizedBox(width: 8),
              Text('Detail Transaksi',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.confirmation_number,
            label: '${widget.selectedSeats.length} Tiket',
            value: widget.selectedSeats.join(', '),
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            icon: Icons.local_offer,
            label: 'Harga Tiket',
            value:
                'Rp${(totalPrice ~/ widget.selectedSeats.length).toString()} x ${widget.selectedSeats.length}',
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            icon: Icons.build,
            label: 'Biaya Layanan',
            value: 'Rp${serviceFee.toString()}',
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance_wallet,
                      color: Color(0xFF001A4D), size: 20),
                  SizedBox(width: 8),
                  Text('TOTAL BAYAR',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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

  Widget _buildDetailRow(
      {required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF666666)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right),
        ),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payment, color: Color(0xFF001A4D), size: 20),
              SizedBox(width: 8),
              Text('Metode Pembayaran',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          ...paymentMethods.map((method) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPaymentOption(method),
              )),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(PaymentMethod method) {
    final isSelected = selectedPaymentMethod == method.id;
    return GestureDetector(
      onTap: () => setState(() => selectedPaymentMethod = method.id),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color:
                isSelected ? const Color(0xFF001A4D) : const Color(0xFFDDDDDD),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? const Color(0xFFF0F8FF) : Colors.white,
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
                      ? const Color(0xFF001A4D)
                      : const Color(0xFFCCCCCC),
                  width: 2,
                ),
                color: isSelected ? const Color(0xFF001A4D) : Colors.white,
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
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    method.description,
                    style:
                        const TextStyle(fontSize: 11, color: Color(0xFF666666)),
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

// ==================== PAYMENT CONFIRMATION PAGE ====================

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
    final Uri url =
        Uri.parse('https://qris.online/homepage/plink/TIX1234567890');
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 22),
                SizedBox(width: 8),
                Text('Batalkan Pembayaran?'),
              ],
            ),
            content: const Text(
                'Apakah Anda yakin ingin membatalkan proses pembayaran?'),
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
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF001A4D)),
            onPressed: () async {
              final shouldPop = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 22),
                      SizedBox(width: 8),
                      Text('Batalkan Pembayaran?'),
                    ],
                  ),
                  content: const Text(
                      'Apakah Anda yakin ingin membatalkan proses pembayaran?'),
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
            style: const TextStyle(
                color: Color(0xFF001A4D),
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
        ),
        body: ListView(
          children: [
            Container(
              color: Colors.red.withOpacity(0.1),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
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
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F8FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF0066CC)),
                          ),
                          child: Column(
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.account_balance_wallet,
                                      color: Color(0xFF0066CC), size: 20),
                                  SizedBox(width: 8),
                                  Text('Total Pembayaran',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF666666))),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Rp${widget.totalAmount}',
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0066CC)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner,
                          color: Color(0xFF001A4D), size: 22),
                      SizedBox(width: 8),
                      Text('Pindai kode QR untuk membayar',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Mohon jangan menutup aplikasi ini',
                      style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8)
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
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
                        const Text('Scan dengan aplikasi e-wallet Anda',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF666666))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _launchQRISUrl,
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('BUKA LINK QRIS'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF001A4D),
                        side: const BorderSide(
                            color: Color(0xFF001A4D), width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.info, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text('Fitur unduh QR akan segera hadir'),
                              ],
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('UNDUH QR CODE'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF001A4D),
                        side: const BorderSide(
                            color: Color(0xFF001A4D), width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFB800)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Color(0xFFFFB800), size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Pastikan pembayaran berhasil sebelum menutup halaman',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFF666666)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Row(
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.green, size: 26),
                                SizedBox(width: 8),
                                Text('Pembayaran Berhasil!'),
                              ],
                            ),
                            content: const Text(
                                'Terima kasih telah membeli tiket. Tiket Anda berhasil dipesan.'),
                            actions: [
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
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
                                icon: const Icon(Icons.check),
                                label: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
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
                        backgroundColor: const Color(0xFF001A4D),
                        padding: const EdgeInsets.symmetric(vertical: 16),
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

// ==================== TICKET SUCCESS PAGE ====================

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
    print('═══════════════════════════════════════');
    print('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'E-Ticket Anda',
          style: TextStyle(
            color: Color(0xFF001A4D),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: ListView(
        children: [
          Container(
            color: Colors.green.withOpacity(0.1),
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
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDDDDDD)),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
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
                                      : const Color(0xFF001A4D),
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
                      const Text(
                        'REGULAR 2D, AUDI #2',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${widget.date}, ${widget.time}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${widget.selectedSeats.length} TIKET',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.selectedSeats.join(', '),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF001A4D),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL BAYAR',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF666666),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDDDDDD)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'E-TICKET QR CODE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tunjukkan QR code ini di bioskop',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.network(
                          'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=$bookingId',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.qr_code,
                                  size: 80,
                                  color: Color(0xFFCCCCCC),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'QR CODE',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFFCCCCCC),
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
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF666666),
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
                    color: const Color(0xFFF0F8FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF0066CC)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFF0066CC),
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Simpan e-ticket ini dan tunjukkan saat memasuki bioskop. Screenshot atau foto juga dapat digunakan.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF666666),
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
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, -2),
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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.info, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text('Fitur download e-ticket akan segera hadir'),
                          ],
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('DOWNLOAD E-TICKET'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF001A4D),
                    side: const BorderSide(
                      color: Color(0xFF001A4D),
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
                    backgroundColor: const Color(0xFFFFB800),
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
    final activeTickets = TicketHistoryService.getActiveTickets();
    final usedTickets = TicketHistoryService.getUsedTickets();

    print('📊 Building TicketHistoryPage');
    print('   Active: ${activeTickets.length}, Used: ${usedTickets.length}');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF001A4D),
              unselectedLabelColor: const Color(0xFF999999),
              indicatorColor: const Color(0xFF001A4D),
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
                  color: Colors.grey.shade600),
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
                  backgroundColor: const Color(0xFF001A4D),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF001A4D) : Colors.grey.shade300,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? Icons.confirmation_number : Icons.check_circle,
                  color: isActive ? Colors.white : Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isActive ? 'TIKET AKTIF' : 'SUDAH DIGUNAKAN',
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.qr_code,
                  color: isActive ? Colors.white70 : Colors.grey.shade500,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  'ID: ${ticket.bookingId.length > 13 ? ticket.bookingId.substring(0, 13) : ticket.bookingId}...',
                  style: TextStyle(
                    color: isActive ? Colors.white70 : Colors.grey.shade500,
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
                            fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              size: 14, color: Color(0xFFFFB800)),
                          const SizedBox(width: 4),
                          Text(ticket.film.rating,
                              style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF001A4D).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              ticket.film.ageRating,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF001A4D)),
                            ),
                          ),
                        ],
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
                        Text('Total Pembayaran',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFF666666))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp${ticket.totalAmount}',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0066CC)),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              TicketDetailPage(ticket: ticket)),
                    );
                  },
                  icon:
                      const Icon(Icons.qr_code, color: Colors.white, size: 16),
                  label: const Text(
                    'LIHAT DETAIL',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF001A4D),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
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

// ==================== TICKET DETAIL PAGE ====================

class TicketDetailPage extends StatelessWidget {
  final TicketHistory ticket;

  const TicketDetailPage({Key? key, required this.ticket}) : super(key: key);

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
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF001A4D)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.info, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Fitur share akan segera hadir'),
                    ],
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          Container(
            color: ticket.status == 'active'
                ? Colors.green.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
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
                          color: Colors.black.withOpacity(0.05), blurRadius: 8)
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
                          color: Colors.black.withOpacity(0.05), blurRadius: 8)
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
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Fitur download e-ticket akan segera hadir'),
                      duration: Duration(seconds: 2)),
                );
              },
              icon: const Icon(Icons.download, size: 18),
              label: const Text('DOWNLOAD E-TICKET'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF001A4D),
                side: const BorderSide(color: Color(0xFF001A4D), width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
              color: const Color(0xFF001A4D),
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
            ),
          ],
        ),
        content: TextField(
          controller: controller,
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: Icon(
              field == 'name'
                  ? Icons.person
                  : field == 'phone'
                      ? Icons.phone
                      : field == 'email'
                          ? Icons.email
                          : Icons.link,
              color: const Color(0xFF001A4D),
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
            icon: const Icon(Icons.close),
            label: const Text('Batal'),
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
                backgroundColor: const Color(0xFF001A4D)),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wc, color: Color(0xFF001A4D), size: 22),
            SizedBox(width: 8),
            Text('Edit Jenis Kelamin'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Laki-laki'),
              value: 'Laki-laki',
              groupValue: userProfile!.gender,
              activeColor: const Color(0xFF001A4D),
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
              title: const Text('Perempuan'),
              value: 'Perempuan',
              groupValue: userProfile!.gender,
              activeColor: const Color(0xFF001A4D),
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
            icon: const Icon(Icons.close),
            label: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userProfile == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF001A4D)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF001A4D),
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    userProfile!.backgroundImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF001A4D), Color(0xFF0066CC)],
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
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.7)
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 50,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
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
                  offset: const Offset(0, -50),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundImage:
                                  NetworkImage(userProfile!.profileImageUrl),
                              backgroundColor: const Color(0xFF001A4D),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF001A4D),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
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
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF001A4D))),
                      const SizedBox(height: 4),
                      Text(userProfile!.phoneNumber,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF666666))),
                      if (userProfile!.email.isNotEmpty)
                        Text(userProfile!.email,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF999999))),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF001A4D), size: 20),
                SizedBox(width: 8),
                Text('Informasi Profil',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF001A4D))),
              ],
            ),
          ),
          _buildProfileItem(
            icon: Icons.person,
            title: 'Nama Lengkap',
            subtitle: userProfile!.name,
            onTap: () => _showEditDialog('name'),
          ),
          const Divider(height: 1),
          _buildProfileItem(
            icon: Icons.phone,
            title: 'Nomor Telepon',
            subtitle: userProfile!.phoneNumber,
            onTap: () => _showEditDialog('phone'),
          ),
          const Divider(height: 1),
          _buildProfileItem(
            icon: Icons.email,
            title: 'Email',
            subtitle:
                userProfile!.email.isEmpty ? 'Belum diisi' : userProfile!.email,
            onTap: () => _showEditDialog('email'),
          ),
          const Divider(height: 1),
          _buildProfileItem(
            icon: Icons.cake,
            title: 'Tanggal Lahir',
            subtitle: userProfile!.birthDate != null
                ? '${userProfile!.birthDate!.day}/${userProfile!.birthDate!.month}/${userProfile!.birthDate!.year}'
                : 'Belum diisi',
            onTap: () => _showEditDialog('birthdate'),
          ),
          const Divider(height: 1),
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
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF001A4D).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF001A4D), size: 20),
      ),
      title: Text(title,
          style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
      subtitle: Text(subtitle,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black)),
      trailing: const Icon(Icons.edit, color: Color(0xFF001A4D), size: 20),
      onTap: onTap,
    );
  }

  Widget _buildMenuSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.favorite,
            title: 'Watchlist',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.info, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Fitur akan segera hadir'),
                    ],
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.settings,
            title: 'Pengaturan',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.info, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Fitur akan segera hadir'),
                    ],
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.help,
            title: 'Bantuan',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.info, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Fitur akan segera hadir'),
                    ],
                  ),
                  duration: Duration(seconds: 2),
                ),
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
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF001A4D).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF001A4D), size: 20),
      ),
      title: Text(title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      trailing:
          const Icon(Icons.chevron_right, color: Color(0xFF666666), size: 20),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
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
                  Text('Keluar'),
                ],
              ),
              content: const Text('Apakah Anda yakin ingin keluar?'),
              actions: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Batal'),
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
            color: const Color(0xFF001A4D).withOpacity(0.1),
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
