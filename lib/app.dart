import 'course_catalog.dart';
import 'skills_page.dart';
import 'package:flutter/material.dart';
import 'data.dart';
import 'lesson_page.dart';
import 'auth_service.dart';
import 'auth_page.dart';
import 'content_repository.dart';
import 'admin_page.dart';
import 'branding.dart';
import 'tutor_page.dart';

const purple = Color(0xFF7566E8);
const ink = Color(0xFF292641);
const muted = Color(0xFF858198);
const green = Color(0xFF34B785);
const background = Color(0xFFF8F7FF);

class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key, required this.store});
  final LearningStore store;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final language in learningLanguages)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: store.languageCode == language.code
                  ? const Color(0xFFEDE9FF)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                leading: Text(
                  language.flag,
                  style: const TextStyle(fontSize: 26),
                ),
                title: Text(language.name),
                subtitle: Text(
                  '${courseLevels[language.code]!.length} cấp độ · ${store.lessons.where((l) => l.languageCode == language.code).length} bài học',
                ),
                trailing: store.languageCode == language.code
                    ? const Icon(Icons.check_circle, color: purple)
                    : null,
                onTap: () => store.selectLanguage(language.code),
              ),
            ),
          ),
      ],
    ),
  );
}

class LingoGoApp extends StatelessWidget {
  const LingoGoApp({super.key, required this.auth, this.store, this.content});
  final ContentRepository? content;
  final AuthService auth;
  // Optional store injection is used by widget tests. Production stores are scoped by UID.
  final LearningStore? store;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: auth,
    builder: (context, _) => AuthScope(
      auth: auth,
      content: content,
      child: MaterialApp(
        key: ValueKey(auth.account?.uid ?? 'signed-out'),
        title: 'LingoGo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: background,
          colorScheme: ColorScheme.fromSeed(seedColor: purple),
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: ink,
            ),
            headlineMedium: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: ink,
            ),
            titleLarge: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: ink,
            ),
            titleMedium: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
            bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: ink),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: background,
            foregroundColor: ink,
            centerTitle: false,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E1F5)),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: purple,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        home: !auth.ready
            ? const SplashScreen(message: 'Đang khôi phục phiên đăng nhập…')
            : auth.account == null
            ? AuthPage(auth: auth)
            : AccountLearningHome(
                account: auth.account!,
                store: store,
                content: content,
              ),
      ),
    ),
  );
}

class AuthScope extends InheritedWidget {
  const AuthScope({
    super.key,
    required this.auth,
    required super.child,
    this.content,
  });
  final AuthService auth;
  final ContentRepository? content;
  static ContentRepository? contentOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()!.content;
  static AuthService of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()!.auth;
  @override
  bool updateShouldNotify(AuthScope oldWidget) => true;
}

class AccountLearningHome extends StatefulWidget {
  const AccountLearningHome({
    super.key,
    required this.account,
    this.store,
    this.content,
  });
  final ContentRepository? content;
  final Account account;
  final LearningStore? store;
  @override
  State<AccountLearningHome> createState() => _AccountLearningHomeState();
}

class _AccountLearningHomeState extends State<AccountLearningHome> {
  late final LearningStore store;
  late final Future<void> loading;
  @override
  void initState() {
    super.initState();
    store = widget.store ?? LearningStore(userId: widget.account.uid);
    loading = initialize();
  }

  Future<void> initialize() async {
    if (widget.store == null) await store.load();
    if (widget.content != null) store.connectContent(widget.content!);
    if (store.displayName == 'Bạn mới') {
      final name = widget.account.name?.trim();
      store.displayName = name != null && name.isNotEmpty
          ? name
          : widget.account.email.split('@').first;
      if (store.displayName.isEmpty) store.displayName = 'Bạn mới';
    }
  }

  @override
  void dispose() {
    // Only this session owns production stores; injected stores belong to tests.
    if (widget.store == null) store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: loading,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return ListenableBuilder(
        listenable: store,
        builder: (context, _) => store.onboarded
            ? HomeShell(store: store)
            : WelcomePage(store: store),
      );
    },
  );
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFEEEBF7)),
    ),
    child: child,
  );
}

class Primary extends StatelessWidget {
  const Primary(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Icon(icon, size: 20),
      ],
    ),
  );
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key, required this.store});
  final LearningStore store;
  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  int step = 0, goal = 10;
  final name = TextEditingController();
  @override
  void initState() {
    super.initState();
    name.text = widget.store.displayName == 'Bạn mới'
        ? ''
        : widget.store.displayName;
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(28),
            children: [
              const SizedBox(height: 24),
              const Center(child: BrandWordmark(size: 38, fontSize: 30)),
              const SizedBox(height: 24),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FF),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Center(
                  child: Text('🌍', style: TextStyle(fontSize: 110)),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                step == 0
                    ? 'Một ngôn ngữ mới.\nMột thế giới mới.'
                    : 'Bắt đầu từ\nnhững điều nhỏ.',
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Text(
                step == 0
                    ? 'Học một chút mỗi ngày, tự tin hơn mỗi lúc.\nCùng khám phá ngôn ngữ bạn yêu thích nhé!'
                    : 'Thiết lập hành trình học phù hợp với bạn.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: muted, height: 1.7),
              ),
              const SizedBox(height: 28),
              if (step == 0) ...[
                const Panel(
                  child: Row(
                    children: [
                      Icon(Icons.offline_bolt_rounded, color: purple),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Hành trình của riêng bạn\nChọn ngôn ngữ và mục tiêu để bắt đầu',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Primary(
                  'Bắt đầu hành trình',
                  onPressed: () => setState(() => step = 1),
                ),
              ] else ...[
                TextField(
                  controller: name,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 40,
                  decoration: const InputDecoration(
                    labelText: 'Bạn muốn được gọi là gì?',
                    hintText: 'Tên của bạn',
                  ),
                ),
                const SizedBox(height: 16),
                LanguagePicker(store: widget.store),
                const SizedBox(height: 22),
                const Text(
                  'Mục tiêu mỗi ngày',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: [5, 10, 15, 20]
                      .map(
                        (m) => ChoiceChip(
                          label: Text('$m phút'),
                          selected: goal == m,
                          onSelected: (_) => setState(() => goal = m),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                Primary(
                  'Vào học thôi!',
                  onPressed: () {
                    widget.store.displayName = name.text.trim().isEmpty
                        ? 'Bạn mới'
                        : name.text.trim();
                    widget.store.dailyGoal = goal;
                    widget.store.onboarded = true;
                    widget.store.save();
                  },
                ),
              ],
              const SizedBox(height: 22),
              const Text(
                'Bạn có thể đổi ngôn ngữ bất cứ lúc nào.\nMỗi ngôn ngữ có tiến độ riêng.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.store});
  final LearningStore store;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int tab = 0;
  final titles = const [
    'Trang chủ',
    'Bài học',
    'Từ vựng',
    'AI gia sư',
    'Cá nhân',
  ];
  final icons = const [
    Icons.home_rounded,
    Icons.route_rounded,
    Icons.style_rounded,
    Icons.auto_awesome_rounded,
    Icons.person_rounded,
  ];
  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final pages = [
      Dashboard(store: store, changeTab: (i) => setState(() => tab = i)),
      LearningPath(store: store),
      VocabularyPage(store: store),
      TutorPage(
        key: ValueKey('${store.languageCode}:${store.currentLevel}'),
        store: store,
      ),
      ProfilePage(store: store),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                if (wide)
                  Container(
                    width: 220,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        right: BorderSide(color: Color(0xFFEEEBF7)),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 36),
                          child: BrandWordmark(size: 36, fontSize: 28),
                        ),
                        for (var i = 0; i < titles.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 5,
                            ),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              selected: tab == i,
                              selectedTileColor: const Color(0xFFEFECFF),
                              selectedColor: purple,
                              leading: Icon(icons[i]),
                              title: Text(titles[i]),
                              onTap: () => setState(() => tab = i),
                            ),
                          ),
                        const Spacer(),
                        const Padding(
                          padding: EdgeInsets.all(22),
                          child: Text(
                            'Từng bước nhỏ,\nchạm ước mơ lớn. 🌱',
                            style: TextStyle(color: muted, height: 1.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: wide ? 36 : 22,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            if (!wide)
                              const Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: BrandWordmark(
                                      size: 30,
                                      fontSize: 22,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Text(
                                titles[tab],
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            if (wide) const Spacer(),
                            ActionChip(
                              avatar: Text(store.language.flag),
                              label: Text(store.language.name),
                              onPressed: () => showDialog<void>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  scrollable: true,
                                  title: const Text('Ngôn ngữ đang học'),
                                  content: SizedBox(
                                    width: 360,
                                    child: LanguagePicker(store: store),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Đã hiểu'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (wide)
                              CircleAvatar(
                                backgroundColor: const Color(0xFFEDE9FF),
                                child: Text(
                                  store.displayName
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(color: purple),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (store.saveError != null)
                        MaterialBanner(
                          content: Text(store.saveError!),
                          actions: [
                            TextButton(
                              onPressed: store.save,
                              child: const Text('Thử lưu lại'),
                            ),
                          ],
                        ),
                      if (store.contentLoading)
                        const LinearProgressIndicator(minHeight: 2),
                      if (store.contentError != null)
                        MaterialBanner(
                          content: Text(store.contentError!),
                          actions: [
                            TextButton(
                              onPressed: () {
                                final repo = AuthScope.contentOf(context);
                                if (repo != null) store.connectContent(repo);
                              },
                              child: const Text('Tải lại'),
                            ),
                          ],
                        ),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1100),
                            child: IndexedStack(index: tab, children: pages),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: tab,
                  onDestinationSelected: (i) => setState(() => tab = i),
                  backgroundColor: Colors.white,
                  indicatorColor: const Color(0xFFEAE5FF),
                  destinations: List.generate(
                    5,
                    (i) => NavigationDestination(
                      icon: Icon(icons[i]),
                      label: titles[i],
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key, required this.store, required this.changeTab});
  final LearningStore store;
  final ValueChanged<int> changeTab;
  @override
  Widget build(BuildContext context) {
    final next = store.nextLesson;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      children: [
        CourseControls(store: store),
        const SizedBox(height: 20),
        Text(
          'CHÀO MỪNG TRỞ LẠI ☀️',
          style: TextStyle(
            color: muted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Xin chào, ${store.displayName}!',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        const Text(
          'Hôm nay là một ngày tuyệt vời để học điều mới.',
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8070EE), Color(0xFF6353D5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Color(0xFFFFD886), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'MỖI NGÀY MỘT CHÚT TIẾN BỘ',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Thế giới rộng lớn.\nBắt đầu bằng một lời chào.',
                style: TextStyle(
                  fontSize: 27,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${store.language.name} ${store.currentLevel} · ${store.published.length} bài học ngắn',
                style: const TextStyle(color: Color(0xFFE9E3FF), height: 1.6),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: purple,
                ),
                onPressed: next == null
                    ? null
                    : () => openLesson(context, store, next),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  store.completedCount == store.published.length
                      ? 'Ôn lại bài học'
                      : 'Tiếp tục học',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              stat(
                '🔥',
                '${store.streak}',
                'Ngày liên tiếp',
                (constraints.maxWidth - 20) / 3,
              ),
              stat(
                '⚡',
                '${store.xp}',
                'Tổng XP',
                (constraints.maxWidth - 20) / 3,
              ),
              stat(
                '🎯',
                '${store.completedCount}/${store.published.length}',
                'Bài hoàn thành',
                (constraints.maxWidth - 20) / 3,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        section('Hành trình của bạn', 'Xem tất cả', () => changeTab(1)),
        const SizedBox(height: 12),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    store.language.flag,
                    style: const TextStyle(fontSize: 30),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${store.language.name}\n${levelLabel(store.currentLevel)} · Lộ trình đang chọn',
                    ),
                  ),
                  Chip(label: Text(store.currentLevel)),
                ],
              ),
              const SizedBox(height: 18),
              LinearProgressIndicator(
                value: store.published.isEmpty
                    ? 0
                    : store.completedCount / store.published.length,
                borderRadius: BorderRadius.circular(8),
                minHeight: 8,
                backgroundColor: background,
              ),
              const SizedBox(height: 10),
              Text(
                '${store.completedCount} / ${store.published.length} bài học đã hoàn thành',
                style: const TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        section('Một chút từ vựng', 'Khám phá', () => changeTab(2)),
        const SizedBox(height: 12),
        Panel(
          color: Color(0xFFF0EDFF),
          child: Row(
            children: [
              const Text('💬', style: TextStyle(fontSize: 38)),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.words.first.word,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${store.words.first.phonetic} · ${store.words.first.meaning}',
                      style: const TextStyle(color: muted),
                    ),
                    const SizedBox(height: 8),
                    Text(store.words.first.example),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Panel(
          child: Row(
            children: [
              const Icon(Icons.tips_and_updates_outlined, color: green),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Mục tiêu của bạn: ${store.dailyGoal} phút/ngày. Dành một khoảng thời gian nhỏ để tạo thói quen lớn.',
                  style: const TextStyle(color: muted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget stat(String emoji, String value, String label, double width) =>
      SizedBox(
        width: width,
        child: Panel(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 18),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: muted, fontSize: 11),
              ),
            ],
          ),
        ),
      );
}

Widget section(String title, String action, VoidCallback onTap) => Row(
  children: [
    Expanded(
      child: Text(
        title,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
      ),
    ),
    TextButton(onPressed: onTap, child: Text(action)),
  ],
);

class LearningPath extends StatelessWidget {
  const LearningPath({super.key, required this.store});
  final LearningStore store;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      CourseControls(store: store),
      const SizedBox(height: 20),
      Text(
        'Mỗi bước, một khám phá',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 8),
      Text(
        '${store.language.name} ${levelLabel(store.currentLevel)} · Lộ trình thực hành',
        style: const TextStyle(color: muted),
      ),
      const SizedBox(height: 24),
      const Panel(
        color: Color(0xFFEDE9FF),
        child: Row(
          children: [
            Icon(Icons.route_rounded, color: purple, size: 32),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'Lộ trình của cấp độ đang chọn\nĐạt từ 70% để mở khóa bài tiếp theo.',
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      if (store.published.isEmpty)
        const Panel(child: Text('Chưa có bài học được xuất bản.')),
      for (final lesson in store.published)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: store.unlocked(lesson)
                            ? const Color(0xFFF0EDFF)
                            : background,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          lesson.icon,
                          style: const TextStyle(fontSize: 30),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BÀI ${store.published.indexOf(lesson) + 1} · 5 PHÚT',
                            style: const TextStyle(
                              color: muted,
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            lesson.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            lesson.subtitle,
                            style: const TextStyle(color: muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      store.completed(lesson.id)
                          ? Icons.check_circle
                          : store.unlocked(lesson)
                          ? Icons.play_circle_fill_rounded
                          : Icons.lock_outline,
                      color: store.completed(lesson.id) ? green : muted,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Primary(
                    store.completed(lesson.id)
                        ? 'Ôn lại · Điểm cao nhất ${store.scores[lesson.id]}%'
                        : store.unlocked(lesson)
                        ? 'Khám phá bài học'
                        : 'Hoàn thành bài trước để mở khóa',
                    onPressed: store.unlocked(lesson)
                        ? () => openLesson(context, store, lesson)
                        : null,
                    icon: store.unlocked(lesson)
                        ? Icons.arrow_forward
                        : Icons.lock_outline,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

void openLesson(BuildContext context, LearningStore store, Lesson lesson) =>
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => LessonIntro(store: store, lesson: lesson),
      ),
    );

class VocabularyPage extends StatefulWidget {
  const VocabularyPage({super.key, required this.store});
  final LearningStore store;
  @override
  State<VocabularyPage> createState() => _VocabularyPageState();
}

class _VocabularyPageState extends State<VocabularyPage> {
  String query = '';
  bool dueOnly = false;
  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final words = store.words
        .where(
          (w) =>
              (!dueOnly || store.due(w)) &&
              '${w.word} ${w.meaning}'.toLowerCase().contains(
                query.toLowerCase(),
              ),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Gom từ nhỏ, nói điều lớn',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          '${store.words.length} từ vựng · ${store.words.where(store.due).length} từ cần ôn',
          style: const TextStyle(color: muted),
        ),
        const SizedBox(height: 20),
        TextField(
          onChanged: (value) => setState(() => query = value),
          decoration: const InputDecoration(
            hintText: 'Tìm từ hoặc nghĩa tiếng Việt',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          children: [
            ChoiceChip(
              label: const Text('Tất cả'),
              selected: !dueOnly,
              onSelected: (_) => setState(() => dueOnly = false),
            ),
            ChoiceChip(
              label: const Text('Đến hạn ôn'),
              selected: dueOnly,
              onSelected: (_) => setState(() => dueOnly = true),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Primary(
          'Ôn bằng flashcard',
          onPressed: words.isEmpty
              ? null
              : () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => Flashcards(store: store, words: words),
                    ),
                  );
                  if (mounted) setState(() {});
                },
          icon: Icons.style_outlined,
        ),
        const SizedBox(height: 20),
        if (words.isEmpty)
          const Panel(
            child: Text(
              'Không có từ phù hợp. Thử tìm từ khác hoặc quay lại sau nhé!',
            ),
          ),
        for (final word in words)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          word.word,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Icon(
                        store.due(word) ? Icons.schedule : Icons.check_circle,
                        color: store.due(word) ? muted : green,
                      ),
                    ],
                  ),
                  Text(
                    '${word.phonetic} · ${word.meaning}',
                    style: const TextStyle(color: muted),
                  ),
                  const SizedBox(height: 10),
                  Text(word.example),
                  Text(
                    word.translation,
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class Flashcards extends StatefulWidget {
  const Flashcards({super.key, required this.store, required this.words});
  final LearningStore store;
  final List<Vocab> words;
  @override
  State<Flashcards> createState() => _FlashcardsState();
}

class _FlashcardsState extends State<Flashcards> {
  int index = 0;
  bool flipped = false;
  void rate(bool remembered) {
    widget.store.review(widget.words[index], remembered);
    setState(() {
      index++;
      flipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final done = index >= widget.words.length;
    final word = done ? null : widget.words[index];
    return Scaffold(
      appBar: AppBar(title: const Text('Ôn tập flashcard')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                done
                    ? 'Bạn đã ôn xong! 🎉'
                    : 'Từ ${index + 1} / ${widget.words.length}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              if (word != null) ...[
                Semantics(
                  button: true,
                  label: 'Lật thẻ từ vựng',
                  child: GestureDetector(
                    onTap: () => setState(() => flipped = !flipped),
                    child: Panel(
                      color: const Color(0xFFEDE9FF),
                      child: SizedBox(
                        height: 280,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                flipped ? word.meaning : word.word,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                flipped ? word.translation : word.phonetic,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 22),
                              Text(
                                flipped ? word.example : 'Chạm để xem nghĩa',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: muted),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (flipped) ...[
                  Primary(
                    'Đã nhớ · Ôn lại sau 3 ngày',
                    onPressed: () => rate(true),
                    icon: Icons.check,
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => rate(false),
                    child: const Text('Chưa nhớ · Cần ôn lại'),
                  ),
                ] else
                  Primary(
                    'Lật thẻ',
                    onPressed: () => setState(() => flipped = true),
                    icon: Icons.flip,
                  ),
              ] else ...[
                const Panel(
                  child: Text(
                    'Các từ đã nhớ được hẹn ôn sau 3 ngày. Từ chưa nhớ vẫn nằm trong danh sách đến hạn.',
                  ),
                ),
                const SizedBox(height: 22),
                Primary(
                  'Về danh sách từ',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.store});
  final LearningStore store;
  Future<void> signOut(BuildContext context) async {
    final auth = AuthScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất tài khoản?'),
        content: const Text(
          'Tiến độ của bạn vẫn được giữ trên thiết bị này. Bạn cần đăng nhập để tiếp tục học.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ở lại'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await auth.signOut();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(authError(e))));
      }
    }
  }

  Future<void> editName(BuildContext context) async {
    final controller = TextEditingController(text: store.displayName);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tên hiển thị'),
        content: TextField(
          controller: controller,
          maxLength: 40,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (value != null) {
      store.displayName = value;
      await store.save();
    }
    // The dialog route finishes its closing animation before releasing its field.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text(
        'Hành trình của riêng bạn',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 24),
      Panel(
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0xFFEDE9FF),
              child: Text(
                store.displayName.substring(0, 1).toUpperCase(),
                style: const TextStyle(fontSize: 28, color: purple),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.displayName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    AuthScope.of(context).account?.email ?? '',
                    style: const TextStyle(color: muted),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => editName(context),
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Sửa tên',
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const Text(
        'Thống kê học tập',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 12),
      Panel(
        child: Column(
          children: [
            info('Bài học hoàn thành', '${store.completedCount}'),
            info('Tổng XP', '${store.xp}'),
            info('Ngày có hoạt động học', '${store.studyDays.length}'),
            info('Chuỗi ngày liên tiếp', '${store.streak}'),
            info(
              'Từ đã nhớ, chưa đến hạn ôn',
              '${store.words.where((w) => !store.due(w)).length}',
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      const Text(
        'Mục tiêu mỗi ngày',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10,
        children: [5, 10, 15, 20]
            .map(
              (m) => ChoiceChip(
                label: Text('$m phút'),
                selected: store.dailyGoal == m,
                onSelected: (_) {
                  store.dailyGoal = m;
                  store.save();
                },
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 24),
      const Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dữ liệu & quyền riêng tư',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              'Tiến độ học được lưu riêng cho tài khoản của bạn trên thiết bị này, chưa đồng bộ giữa các thiết bị. Xóa dữ liệu ứng dụng sẽ xóa tiến độ đã lưu.',
              style: TextStyle(color: muted),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      if (AuthScope.of(context).account?.isAdmin == true &&
          AuthScope.contentOf(context) != null)
        FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) =>
                  AdminPage(repository: AuthScope.contentOf(context)!),
            ),
          ),
          icon: const Icon(Icons.edit_note_rounded),
          label: const Text('Quản lý bài học'),
        ),
      OutlinedButton.icon(
        onPressed: () => signOut(context),
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Đăng xuất'),
      ),
      OutlinedButton.icon(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Về bản trải nghiệm'),
            content: Text(
              'LingoGo · 4 ngôn ngữ\n${store.lessons.length} bài học · 4 loại bài tập\n\nBài mới được cập nhật khi kết nối mạng. Học từng chút mỗi ngày để tự tin hơn khi giao tiếp.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        ),
        icon: const Icon(Icons.info_outline),
        label: const Text('Về LingoGo'),
      ),
    ],
  );
  Widget info(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: muted)),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, color: purple),
        ),
      ],
    ),
  );
}

class CourseControls extends StatelessWidget {
  const CourseControls({super.key, required this.store});
  final LearningStore store;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DropdownButtonFormField<String>(
        key: ValueKey('course:${store.languageCode}:${store.currentLevel}'),
        initialValue: store.currentLevel,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Khóa học / cấp độ',
          border: OutlineInputBorder(),
        ),
        items: courseLevels[store.languageCode]!
            .map(
              (level) => DropdownMenuItem(
                value: level,
                child: Text(levelLabel(level)),
              ),
            )
            .toList(),
        onChanged: (value) => store.selectLevel(value!),
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => SkillsPage(store: store)),
        ),
        icon: const Icon(Icons.headphones),
        label: const Text('Luyện nghe · nói · viết'),
      ),
      const Text(
        'Bài thực hành theo cấp độ; chưa phải toàn bộ giáo trình luyện thi chính thức.',
        style: TextStyle(color: muted, fontSize: 12),
      ),
    ],
  );
}
