// 100apps Day 101: スマホアプリをひとまとめにしたハブアプリ
// Day 66〜90 で作ったアプリを1つに集約。不要なものは「非表示」にできます。
// 非表示の設定は端末に保存されます（shared_preferences・ネット通信なし）。

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  runApp(const HubApp());
}

class HubApp extends StatelessWidget {
  const HubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'アプリハブ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF4F46E5),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// 1つのミニアプリの情報（番号・名前・絵文字・色・画面の作り方）
class MiniApp {
  final int day;
  final String name;
  final String emoji;
  final Color color;
  final WidgetBuilder builder;
  const MiniApp(this.day, this.name, this.emoji, this.color, this.builder);
}

// 内蔵する全ミニアプリの一覧
List<MiniApp> buildMiniApps() => [
      MiniApp(66, 'カウンター', '🔢', const Color(0xFF6366F1), (_) => const CounterScreen()),
      MiniApp(67, 'メモ帳', '📝', const Color(0xFFF59E0B), (_) => const NotesScreen()),
      MiniApp(68, 'ToDo', '✅', const Color(0xFF10B981), (_) => const TodoScreen()),
      MiniApp(69, '買い物リスト', '🛒', const Color(0xFFEF4444), (_) => const ShoppingScreen()),
      MiniApp(70, '家計簿', '💰', const Color(0xFF0EA5E9), (_) => const KakeiboScreen()),
      MiniApp(71, '体重記録', '⚖️', const Color(0xFF8B5CF6), (_) => const WeightScreen()),
      MiniApp(72, '習慣トラッカー', '🔥', const Color(0xFFF97316), (_) => const HabitScreen()),
      MiniApp(73, 'ストップウォッチ', '⏱️', const Color(0xFF14B8A6), (_) => const StopwatchScreen()),
      MiniApp(74, 'ポモドーロ', '🍅', const Color(0xFFDC2626), (_) => const PomodoroScreen()),
      MiniApp(75, 'BMI計算', '🩺', const Color(0xFF22C55E), (_) => const BmiScreen()),
      MiniApp(76, '割り勘', '🧾', const Color(0xFF3B82F6), (_) => const WarikanScreen()),
      MiniApp(77, 'チップ計算', '💳', const Color(0xFF06B6D4), (_) => const TipScreen()),
      MiniApp(78, '単位変換', '📏', const Color(0xFF7C3AED), (_) => const UnitScreen()),
      MiniApp(79, '為替計算', '💱', const Color(0xFF059669), (_) => const CurrencyScreen()),
      MiniApp(80, 'パスワード生成', '🔑', const Color(0xFF475569), (_) => const PasswordScreen()),
      MiniApp(81, 'QR表示', '🔳', const Color(0xFF111827), (_) => const QrScreen()),
      MiniApp(82, 'カラーピッカー', '🎨', const Color(0xFFEC4899), (_) => const ColorScreen()),
      MiniApp(83, 'おみくじ', '🎴', const Color(0xFFE11D48), (_) => const OmikujiScreen()),
      MiniApp(84, 'サイコロ', '🎲', const Color(0xFF2563EB), (_) => const DiceScreen()),
      MiniApp(85, '抽選・ガチャ', '🎁', const Color(0xFFD946EF), (_) => const GachaScreen()),
      MiniApp(86, '名言表示', '💬', const Color(0xFF0891B2), (_) => const QuotesScreen()),
      MiniApp(87, '単語帳', '🗂️', const Color(0xFF65A30D), (_) => const FlashcardScreen()),
      MiniApp(88, '日記', '📔', const Color(0xFFB45309), (_) => const DiaryScreen()),
      MiniApp(89, '多言語あいさつ', '👋', const Color(0xFF7C3AED), (_) => const GreetingScreen()),
      MiniApp(90, 'ミニ電卓', '🧮', const Color(0xFF1F2937), (_) => const CalculatorScreen()),
    ];

// ====================== ホーム画面 ======================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<MiniApp> apps = buildMiniApps();
  Set<int> hidden = {}; // 非表示にしたアプリのDay番号
  bool editMode = false; // 編集モード（このときだけ非表示にできる）
  bool loaded = false;

  static const String _prefsKey = 'hidden_days';

  @override
  void initState() {
    super.initState();
    _loadHidden();
  }

  Future<void> _loadHidden() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? [];
    if (!mounted) return;
    setState(() {
      hidden = list.map(int.tryParse).whereType<int>().toSet();
      loaded = true;
    });
  }

  Future<void> _saveHidden() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, hidden.map((e) => e.toString()).toList());
  }

  void _hide(int day) {
    setState(() => hidden.add(day));
    _saveHidden();
  }

  void _unhideAll() {
    setState(() => hidden.clear());
    _saveHidden();
  }

  @override
  Widget build(BuildContext context) {
    final visible = apps.where((a) => !hidden.contains(a.day)).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        title: const Text('📱 アプリハブ'),
        actions: [
          // 非表示の管理ページへ
          IconButton(
            tooltip: '非表示の管理',
            icon: const Icon(Icons.visibility_off),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ManageHiddenPage(
                    apps: apps,
                    initialHidden: hidden,
                    // トグルのたびに親（ここ）が状態を更新して保存する
                    onToggle: (day, show) {
                      setState(() {
                        if (show) {
                          hidden.remove(day);
                        } else {
                          hidden.add(day);
                        }
                      });
                      _saveHidden();
                    },
                  ),
                ),
              );
              if (!mounted) return; // 画面が破棄されていたら何もしない
              setState(() {});
            },
          ),
          // 編集モードの切り替え
          IconButton(
            tooltip: editMode ? '完了' : '編集（非表示にする）',
            icon: Icon(editMode ? Icons.done : Icons.edit),
            onPressed: () => setState(() => editMode = !editMode),
          ),
        ],
      ),
      body: !loaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (editMode)
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFFEF3C7),
                    padding: const EdgeInsets.all(10),
                    child: const Text(
                      '編集モード：カードの×を押すと非表示にできます',
                      textAlign: TextAlign.center,
                    ),
                  ),
                Expanded(
                  child: visible.isEmpty
                      ? const Center(child: Text('表示するアプリがありません。\n右上の管理から戻せます。',
                          textAlign: TextAlign.center))
                      : GridView.builder(
                          padding: const EdgeInsets.all(14),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.82,
                          ),
                          itemCount: visible.length,
                          itemBuilder: (context, i) {
                            final app = visible[i];
                            return _AppTile(
                              app: app,
                              editMode: editMode,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: app.builder),
                              ),
                              onHide: () => _hide(app.day),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: hidden.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _unhideAll,
              backgroundColor: const Color(0xFF4F46E5),
              icon: const Icon(Icons.restore),
              label: Text('全部表示 (${hidden.length})'),
            )
          : null,
    );
  }
}

// ホームの1マス（ポップなアイコンカード）
class _AppTile extends StatelessWidget {
  final MiniApp app;
  final bool editMode;
  final VoidCallback onTap;
  final VoidCallback onHide;
  const _AppTile({
    required this.app,
    required this.editMode,
    required this.onTap,
    required this.onHide,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3)),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: app.color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(app.emoji, style: const TextStyle(fontSize: 26)),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    app.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (editMode)
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onHide,
              child: Container(
                decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                padding: const EdgeInsets.all(3),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

// ====================== 非表示の管理画面 ======================
class ManageHiddenPage extends StatefulWidget {
  final List<MiniApp> apps;
  final Set<int> initialHidden;
  final void Function(int day, bool show) onToggle;
  const ManageHiddenPage({
    super.key,
    required this.apps,
    required this.initialHidden,
    required this.onToggle,
  });

  @override
  State<ManageHiddenPage> createState() => _ManageHiddenPageState();
}

class _ManageHiddenPageState extends State<ManageHiddenPage> {
  // この画面用のコピー。表示はこれで管理し、変更は onToggle で親に伝える
  late final Set<int> local = Set<int>.from(widget.initialHidden);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('表示・非表示の管理')),
      body: ListView(
        children: widget.apps.map((app) {
          final isHidden = local.contains(app.day);
          return SwitchListTile(
            secondary: CircleAvatar(
              backgroundColor: app.color,
              child: Text(app.emoji),
            ),
            title: Text(app.name),
            subtitle: Text('Day ${app.day}'),
            value: !isHidden, // オン=表示
            onChanged: (show) {
              setState(() {
                if (show) {
                  local.remove(app.day);
                } else {
                  local.add(app.day);
                }
              });
              widget.onToggle(app.day, show); // 親が保存する
            },
          );
        }).toList(),
      ),
    );
  }
}

// 各ミニアプリ共通の枠（タイトル付き）
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  const AppScaffold({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

// ====================== 66 カウンター ======================
class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key});
  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  int count = 0;
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'カウンター',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$count', style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton(onPressed: () => setState(() => count--), child: const Text('－')),
                const SizedBox(width: 16),
                FilledButton(onPressed: () => setState(() => count++), child: const Text('＋')),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: () => setState(() => count = 0), child: const Text('リセット')),
          ],
        ),
      ),
    );
  }
}

// ====================== 67 メモ帳 ======================
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final controller = TextEditingController();
  final List<String> notes = [];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void add() {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      notes.insert(0, text);
      controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'メモ帳',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(hintText: 'メモを入力', border: OutlineInputBorder()),
                  onSubmitted: (_) => add(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: add, child: const Text('追加')),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: notes.isEmpty
                ? const Center(child: Text('メモはまだありません'))
                : ListView.builder(
                    itemCount: notes.length,
                    itemBuilder: (_, i) => Card(
                      child: ListTile(
                        title: Text(notes[i]),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => setState(() => notes.removeAt(i)),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ====================== 68 ToDo ======================
class TodoItem {
  String text;
  bool done;
  TodoItem(this.text, {this.done = false});
}

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});
  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final controller = TextEditingController();
  final List<TodoItem> items = [];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void add() {
    final t = controller.text.trim();
    if (t.isEmpty) return;
    setState(() {
      items.add(TodoItem(t));
      controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'ToDo',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(hintText: 'やることを入力', border: OutlineInputBorder()),
                  onSubmitted: (_) => add(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: add, child: const Text('追加')),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) => CheckboxListTile(
                value: items[i].done,
                title: Text(
                  items[i].text,
                  style: TextStyle(
                    decoration: items[i].done ? TextDecoration.lineThrough : null,
                    color: items[i].done ? Colors.grey : null,
                  ),
                ),
                onChanged: (v) => setState(() => items[i].done = v ?? false),
                secondary: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => items.removeAt(i)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ====================== 69 買い物リスト ======================
class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});
  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final controller = TextEditingController();
  final List<TodoItem> items = [];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void add() {
    final t = controller.text.trim();
    if (t.isEmpty) return;
    setState(() {
      items.add(TodoItem(t));
      controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '買い物リスト',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(hintText: '買うものを入力', border: OutlineInputBorder()),
                  onSubmitted: (_) => add(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: add, child: const Text('追加')),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) => CheckboxListTile(
                value: items[i].done,
                title: Text(items[i].text,
                    style: TextStyle(
                      decoration: items[i].done ? TextDecoration.lineThrough : null,
                    )),
                onChanged: (v) => setState(() => items[i].done = v ?? false),
                secondary: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => items.removeAt(i)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ====================== 70 家計簿 ======================
class KakeiboScreen extends StatefulWidget {
  const KakeiboScreen({super.key});
  @override
  State<KakeiboScreen> createState() => _KakeiboScreenState();
}

class _KakeiboScreenState extends State<KakeiboScreen> {
  final labelCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  final List<MapEntry<String, int>> entries = []; // 金額：収入は＋、支出は－

  @override
  void dispose() {
    labelCtrl.dispose();
    amountCtrl.dispose();
    super.dispose();
  }

  void add(bool income) {
    final label = labelCtrl.text.trim();
    final amount = int.tryParse(amountCtrl.text.trim());
    if (label.isEmpty || amount == null || amount <= 0) return;
    setState(() {
      entries.insert(0, MapEntry(label, income ? amount : -amount));
      labelCtrl.clear();
      amountCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final balance = entries.fold<int>(0, (sum, e) => sum + e.value);
    return AppScaffold(
      title: '家計簿',
      child: Column(
        children: [
          Text('残高: $balance 円',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(controller: labelCtrl, decoration: const InputDecoration(hintText: '項目（例: 食費）', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(
            controller: amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: '金額', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: FilledButton(onPressed: () => add(true), child: const Text('収入＋'))),
              const SizedBox(width: 8),
              Expanded(child: FilledButton(onPressed: () => add(false), child: const Text('支出－'))),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (_, i) {
                final e = entries[i];
                final plus = e.value >= 0;
                return ListTile(
                  title: Text(e.key),
                  trailing: Text('${plus ? '+' : ''}${e.value} 円',
                      style: TextStyle(color: plus ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ====================== 71 体重記録 ======================
class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});
  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  final ctrl = TextEditingController();
  final List<double> weights = [];

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  void add() {
    final w = double.tryParse(ctrl.text.trim());
    if (w == null || w <= 0) return;
    setState(() {
      weights.insert(0, w);
      ctrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final latest = weights.isNotEmpty ? weights.first : null;
    return AppScaffold(
      title: '体重記録',
      child: Column(
        children: [
          Text(latest == null ? '記録なし' : '最新: $latest kg',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(hintText: '体重(kg)', border: OutlineInputBorder()),
                  onSubmitted: (_) => add(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: add, child: const Text('記録')),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: weights.length,
              itemBuilder: (_, i) => ListTile(
                leading: Text('${weights.length - i}'),
                title: Text('${weights[i]} kg'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ====================== 72 習慣トラッカー ======================
class HabitScreen extends StatefulWidget {
  const HabitScreen({super.key});
  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen> {
  final ctrl = TextEditingController();
  final List<TodoItem> habits = [];

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  void add() {
    final t = ctrl.text.trim();
    if (t.isEmpty) return;
    setState(() {
      habits.add(TodoItem(t));
      ctrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '習慣トラッカー（今日）',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(hintText: '習慣を追加', border: OutlineInputBorder()),
                  onSubmitted: (_) => add(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: add, child: const Text('追加')),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: habits.length,
              itemBuilder: (_, i) => Card(
                child: ListTile(
                  leading: Text(habits[i].done ? '🔥' : '⬜', style: const TextStyle(fontSize: 22)),
                  title: Text(habits[i].text),
                  trailing: Switch(
                    value: habits[i].done,
                    onChanged: (v) => setState(() => habits[i].done = v),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ====================== 73 ストップウォッチ ======================
class StopwatchScreen extends StatefulWidget {
  const StopwatchScreen({super.key});
  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends State<StopwatchScreen> {
  final Stopwatch _sw = Stopwatch();
  Timer? _timer;

  void _start() {
    _sw.start();
    _timer ??= Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mounted) setState(() {});
    });
  }

  void _stop() {
    _sw.stop();
    _timer?.cancel();
    _timer = null;
    setState(() {});
  }

  void _reset() {
    _sw.reset();
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt() {
    final ms = _sw.elapsedMilliseconds;
    final m = (ms ~/ 60000).toString().padLeft(2, '0');
    final s = ((ms ~/ 1000) % 60).toString().padLeft(2, '0');
    final cs = ((ms ~/ 10) % 100).toString().padLeft(2, '0');
    return '$m:$s.$cs';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'ストップウォッチ',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_fmt(),
                style: const TextStyle(fontSize: 52, fontWeight: FontWeight.bold, fontFeatures: [FontFeature.tabularFigures()])),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton(onPressed: _sw.isRunning ? _stop : _start, child: Text(_sw.isRunning ? 'ストップ' : 'スタート')),
                const SizedBox(width: 16),
                OutlinedButton(onPressed: _reset, child: const Text('リセット')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ====================== 74 ポモドーロ ======================
class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});
  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  static const int workSeconds = 25 * 60;
  int remaining = workSeconds;
  Timer? _timer;

  void _start() {
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (remaining > 0) remaining--;
        // 0になった瞬間にその場で止める（1秒余分に動かさない）
        if (remaining == 0) {
          _timer?.cancel();
          _timer = null;
        }
      });
    });
    setState(() {});
  }

  void _pause() {
    _timer?.cancel();
    _timer = null;
    setState(() {});
  }

  void _reset() {
    _pause();
    setState(() => remaining = workSeconds);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = (remaining ~/ 60).toString().padLeft(2, '0');
    final s = (remaining % 60).toString().padLeft(2, '0');
    final running = _timer != null;
    return AppScaffold(
      title: 'ポモドーロ（25分）',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$m:$s', style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold)),
            if (remaining == 0) const Padding(padding: EdgeInsets.all(8), child: Text('おつかれさま！休憩しましょう🍵')),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton(onPressed: running ? _pause : _start, child: Text(running ? '一時停止' : 'スタート')),
                const SizedBox(width: 16),
                OutlinedButton(onPressed: _reset, child: const Text('リセット')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ====================== 75 BMI ======================
class BmiScreen extends StatefulWidget {
  const BmiScreen({super.key});
  @override
  State<BmiScreen> createState() => _BmiScreenState();
}

class _BmiScreenState extends State<BmiScreen> {
  final hCtrl = TextEditingController();
  final wCtrl = TextEditingController();
  String result = '';

  @override
  void dispose() {
    hCtrl.dispose();
    wCtrl.dispose();
    super.dispose();
  }

  void calc() {
    final h = double.tryParse(hCtrl.text.trim()); // cm
    final w = double.tryParse(wCtrl.text.trim()); // kg
    if (h == null || w == null || h <= 0 || w <= 0) {
      setState(() => result = '身長(cm)と体重(kg)を正しく入力してください。');
      return;
    }
    final bmi = w / ((h / 100) * (h / 100));
    String cat;
    if (bmi < 18.5) {
      cat = 'やせ気味';
    } else if (bmi < 25) {
      cat = '標準';
    } else if (bmi < 30) {
      cat = 'やや肥満';
    } else {
      cat = '肥満';
    }
    setState(() => result = 'BMI: ${bmi.toStringAsFixed(1)}（$cat）');
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'BMI計算',
      child: Column(
        children: [
          TextField(controller: hCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: '身長 (cm)', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: wCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: '体重 (kg)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          FilledButton(onPressed: calc, child: const Text('計算')),
          const SizedBox(height: 16),
          Text(result, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ====================== 76 割り勘 ======================
class WarikanScreen extends StatefulWidget {
  const WarikanScreen({super.key});
  @override
  State<WarikanScreen> createState() => _WarikanScreenState();
}

class _WarikanScreenState extends State<WarikanScreen> {
  final totalCtrl = TextEditingController();
  final peopleCtrl = TextEditingController();
  String result = '';

  @override
  void dispose() {
    totalCtrl.dispose();
    peopleCtrl.dispose();
    super.dispose();
  }

  void calc() {
    final total = int.tryParse(totalCtrl.text.trim());
    final people = int.tryParse(peopleCtrl.text.trim());
    if (total == null || total < 0 || people == null || people < 1) {
      setState(() => result = '合計（0以上）と人数（1以上）を入力してください。');
      return;
    }
    final each = (total / people).ceil();
    final diff = each * people - total;
    setState(() => result = '1人あたり $each 円' + (diff > 0 ? '（$diff 円多め）' : ''));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '割り勘',
      child: Column(
        children: [
          TextField(controller: totalCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '合計金額(円)', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: peopleCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '人数', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          FilledButton(onPressed: calc, child: const Text('計算')),
          const SizedBox(height: 16),
          Text(result, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ====================== 77 チップ計算 ======================
class TipScreen extends StatefulWidget {
  const TipScreen({super.key});
  @override
  State<TipScreen> createState() => _TipScreenState();
}

class _TipScreenState extends State<TipScreen> {
  final billCtrl = TextEditingController();
  double percent = 15;
  String result = '';

  @override
  void dispose() {
    billCtrl.dispose();
    super.dispose();
  }

  void calc() {
    final bill = double.tryParse(billCtrl.text.trim());
    if (bill == null || bill < 0) {
      setState(() => result = '金額を正しく入力してください。');
      return;
    }
    final tip = bill * percent / 100;
    setState(() => result = 'チップ: ${tip.toStringAsFixed(0)} / 合計: ${(bill + tip).toStringAsFixed(0)}');
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'チップ計算',
      child: Column(
        children: [
          TextField(controller: billCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: '金額', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          Text('チップ率: ${percent.toStringAsFixed(0)}%'),
          Slider(value: percent, min: 0, max: 30, divisions: 30, label: '${percent.toStringAsFixed(0)}%', onChanged: (v) => setState(() => percent = v)),
          FilledButton(onPressed: calc, child: const Text('計算')),
          const SizedBox(height: 16),
          Text(result, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ====================== 78 単位変換 ======================
class UnitScreen extends StatefulWidget {
  const UnitScreen({super.key});
  @override
  State<UnitScreen> createState() => _UnitScreenState();
}

class _UnitScreenState extends State<UnitScreen> {
  final ctrl = TextEditingController();
  // メートル基準
  final Map<String, double> units = {'mm': 0.001, 'cm': 0.01, 'm': 1, 'km': 1000, 'inch': 0.0254, 'feet': 0.3048};
  String from = 'm';
  String to = 'cm';
  String result = '';

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  void calc() {
    final v = double.tryParse(ctrl.text.trim());
    if (v == null) {
      setState(() => result = '数値を入力してください。');
      return;
    }
    final meters = v * units[from]!;
    final out = meters / units[to]!;
    setState(() => result = '$v $from = $out $to');
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '単位変換（長さ）',
      child: Column(
        children: [
          TextField(controller: ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: '数値', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _dropdown(from, (v) => setState(() => from = v))),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('→')),
              Expanded(child: _dropdown(to, (v) => setState(() => to = v))),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: calc, child: const Text('変換')),
          const SizedBox(height: 16),
          Text(result, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _dropdown(String value, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(border: OutlineInputBorder()),
      items: units.keys.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

// ====================== 79 為替計算 ======================
class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});
  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  final amountCtrl = TextEditingController();
  final rateCtrl = TextEditingController(text: '150');
  String result = '';

  @override
  void dispose() {
    amountCtrl.dispose();
    rateCtrl.dispose();
    super.dispose();
  }

  void calc() {
    final amount = double.tryParse(amountCtrl.text.trim());
    final rate = double.tryParse(rateCtrl.text.trim());
    if (amount == null || rate == null || rate <= 0) {
      setState(() => result = '金額とレートを正しく入力してください。');
      return;
    }
    setState(() => result = '${(amount * rate).toStringAsFixed(2)} 円');
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '為替計算（レート手入力）',
      child: Column(
        children: [
          TextField(controller: amountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: '外貨の金額', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: rateCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: '1単位あたりの円（レート）', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          FilledButton(onPressed: calc, child: const Text('計算')),
          const SizedBox(height: 16),
          Text(result, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ====================== 80 パスワード生成 ======================
class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});
  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  double length = 12;
  bool useUpper = true;
  bool useNum = true;
  bool useSym = false;
  String result = 'ボタンを押して生成';

  void generate() {
    const lower = 'abcdefghijklmnopqrstuvwxyz';
    const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const nums = '0123456789';
    const syms = '!@#\$%^&*-_=+?';
    final rnd = Random.secure();

    // 使う文字カテゴリ（小文字は常に入れる）
    final categories = <String>[lower];
    if (useUpper) categories.add(upper);
    if (useNum) categories.add(nums);
    if (useSym) categories.add(syms);
    final pool = categories.join();

    final len = length.toInt();
    final chars = <String>[];
    // まず各カテゴリから最低1文字ずつ入れる（選んだ種類が必ず入るように）
    for (final c in categories) {
      chars.add(c[rnd.nextInt(c.length)]);
    }
    // 残りは全体プールから埋める
    while (chars.length < len) {
      chars.add(pool[rnd.nextInt(pool.length)]);
    }
    // 長さがカテゴリ数より短い場合に備えて切り詰め
    final out = chars.take(len).toList();
    // 並びをシャッフル（先頭がカテゴリ順に偏らないように：Fisher-Yates）
    for (var i = out.length - 1; i > 0; i--) {
      final j = rnd.nextInt(i + 1);
      final tmp = out[i];
      out[i] = out[j];
      out[j] = tmp;
    }
    setState(() => result = out.join());
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'パスワード生成',
      child: Column(
        children: [
          Text('長さ: ${length.toInt()}'),
          Slider(value: length, min: 4, max: 32, divisions: 28, label: '${length.toInt()}', onChanged: (v) => setState(() => length = v)),
          SwitchListTile(value: useUpper, title: const Text('大文字を含む'), onChanged: (v) => setState(() => useUpper = v)),
          SwitchListTile(value: useNum, title: const Text('数字を含む'), onChanged: (v) => setState(() => useNum = v)),
          SwitchListTile(value: useSym, title: const Text('記号を含む'), onChanged: (v) => setState(() => useSym = v)),
          FilledButton(onPressed: generate, child: const Text('生成')),
          const SizedBox(height: 16),
          SelectableText(result, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ====================== 81 QR表示 ======================
class QrScreen extends StatefulWidget {
  const QrScreen({super.key});
  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  final ctrl = TextEditingController(text: 'https://vava-180.github.io/100apps/');
  String data = 'https://vava-180.github.io/100apps/';

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'QR表示',
      child: Column(
        children: [
          TextField(
            controller: ctrl,
            decoration: const InputDecoration(labelText: '文字・URL', border: OutlineInputBorder()),
            onChanged: (v) => setState(() => data = v),
          ),
          const SizedBox(height: 20),
          if (data.trim().isEmpty)
            const Text('文字を入力するとQRコードが出ます')
          else
            QrImageView(
              data: data,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
            ),
        ],
      ),
    );
  }
}

// ====================== 82 カラーピッカー ======================
class ColorScreen extends StatefulWidget {
  const ColorScreen({super.key});
  @override
  State<ColorScreen> createState() => _ColorScreenState();
}

class _ColorScreenState extends State<ColorScreen> {
  double r = 79, g = 70, b = 229;

  String get hex {
    String two(int n) => n.toRadixString(16).padLeft(2, '0');
    return '#${two(r.toInt())}${two(g.toInt())}${two(b.toInt())}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = Color.fromARGB(255, r.toInt(), g.toInt(), b.toInt());
    return AppScaffold(
      title: 'カラーピッカー',
      child: Column(
        children: [
          Container(height: 90, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12))),
          const SizedBox(height: 8),
          Text(hex, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          _slider('R', r, Colors.red, (v) => setState(() => r = v)),
          _slider('G', g, Colors.green, (v) => setState(() => g = v)),
          _slider('B', b, Colors.blue, (v) => setState(() => b = v)),
        ],
      ),
    );
  }

  Widget _slider(String label, double value, Color color, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 20, child: Text(label)),
        Expanded(
          child: Slider(value: value, min: 0, max: 255, activeColor: color, onChanged: onChanged),
        ),
        SizedBox(width: 36, child: Text('${value.toInt()}')),
      ],
    );
  }
}

// ====================== 83 おみくじ ======================
class OmikujiScreen extends StatefulWidget {
  const OmikujiScreen({super.key});
  @override
  State<OmikujiScreen> createState() => _OmikujiScreenState();
}

class _OmikujiScreenState extends State<OmikujiScreen> {
  static const fortunes = ['大吉', '中吉', '小吉', '吉', '末吉', '凶'];
  final rnd = Random();
  String current = 'ボタンを押してね';

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'おみくじ',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(current, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            FilledButton(onPressed: () => setState(() => current = fortunes[rnd.nextInt(fortunes.length)]), child: const Text('引く')),
          ],
        ),
      ),
    );
  }
}

// ====================== 84 サイコロ ======================
class DiceScreen extends StatefulWidget {
  const DiceScreen({super.key});
  @override
  State<DiceScreen> createState() => _DiceScreenState();
}

class _DiceScreenState extends State<DiceScreen> {
  final rnd = Random();
  int value = 1;
  static const faces = ['⚀', '⚁', '⚂', '⚃', '⚄', '⚅'];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'サイコロ',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(faces[value - 1], style: const TextStyle(fontSize: 120)),
            Text('$value', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => setState(() => value = rnd.nextInt(6) + 1), child: const Text('振る')),
          ],
        ),
      ),
    );
  }
}

// ====================== 85 抽選・ガチャ ======================
class GachaScreen extends StatefulWidget {
  const GachaScreen({super.key});
  @override
  State<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends State<GachaScreen> {
  final rnd = Random();
  String result = '？';

  // レア度（重み付き）
  String draw() {
    final roll = rnd.nextInt(100);
    if (roll < 5) return '✨ SSR ✨';
    if (roll < 25) return '⭐ SR';
    if (roll < 60) return '🔹 R';
    return '▫️ N';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '抽選・ガチャ',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(result, style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            FilledButton(onPressed: () => setState(() => result = draw()), child: const Text('ガチャを引く')),
          ],
        ),
      ),
    );
  }
}

// ====================== 86 名言表示 ======================
class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});
  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  static const quotes = [
    '継続は力なり。',
    '千里の道も一歩から。',
    '失敗は成功のもと。',
    '思い立ったが吉日。',
    '為せば成る、為さねば成らぬ何事も。',
  ];
  final rnd = Random();
  String current = 'ボタンを押すと名言が出ます';

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '名言表示',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('「$current」', textAlign: TextAlign.center, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => setState(() => current = quotes[rnd.nextInt(quotes.length)]), child: const Text('次の名言')),
          ],
        ),
      ),
    );
  }
}

// ====================== 87 単語帳 ======================
class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});
  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  static const cards = [
    MapEntry('apple', 'りんご'),
    MapEntry('book', '本'),
    MapEntry('cat', 'ねこ'),
    MapEntry('dog', 'いぬ'),
    MapEntry('egg', 'たまご'),
  ];
  int index = 0;
  bool showAnswer = false;

  @override
  Widget build(BuildContext context) {
    final card = cards[index];
    return AppScaffold(
      title: '単語帳（${index + 1}/${cards.length}）',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => setState(() => showAnswer = !showAnswer),
              child: Card(
                child: Container(
                  width: 240,
                  height: 150,
                  alignment: Alignment.center,
                  child: Text(showAnswer ? card.value : card.key, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('カードをタップで答え'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => setState(() {
                index = (index + 1) % cards.length;
                showAnswer = false;
              }),
              child: const Text('次へ'),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================== 88 日記 ======================
class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});
  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final ctrl = TextEditingController();
  final List<MapEntry<String, String>> entries = [];

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  void save() {
    final text = ctrl.text.trim();
    if (text.isEmpty) return;
    final now = DateTime.now();
    final date = '${now.year}/${now.month}/${now.day}';
    setState(() {
      entries.insert(0, MapEntry(date, text));
      ctrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '日記',
      child: Column(
        children: [
          TextField(
            controller: ctrl,
            maxLines: 3,
            decoration: const InputDecoration(hintText: '今日のできごと', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: save, child: const Text('保存')),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (_, i) => Card(
                child: ListTile(
                  title: Text(entries[i].value),
                  subtitle: Text(entries[i].key),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ====================== 89 多言語あいさつ ======================
class GreetingScreen extends StatefulWidget {
  const GreetingScreen({super.key});
  @override
  State<GreetingScreen> createState() => _GreetingScreenState();
}

class _GreetingScreenState extends State<GreetingScreen> {
  final Map<String, String> greetings = {
    '日本語': 'こんにちは',
    'English': 'Hello',
    '中文': '你好',
    '한국어': '안녕하세요',
    'Français': 'Bonjour',
    'Español': 'Hola',
  };
  String lang = '日本語';

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '多言語あいさつ',
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: lang,
            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: '言語'),
            items: greetings.keys.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
            onChanged: (v) => setState(() => lang = v ?? lang),
          ),
          const SizedBox(height: 40),
          Text(greetings[lang]!, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ====================== 90 ミニ電卓 ======================
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});
  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String display = '0';
  double? first;
  String? op;
  bool resetNext = false;

  void tapNumber(String n) {
    setState(() {
      if (display == '0' || resetNext) {
        display = n;
        resetNext = false;
      } else {
        display += n;
      }
    });
  }

  void tapDot() {
    setState(() {
      if (resetNext) {
        display = '0.';
        resetNext = false;
      } else if (!display.contains('.')) {
        display += '.';
      }
    });
  }

  // 2つの数を計算する。0除算なら null を返す。
  double? _compute(double a, double b, String o) {
    switch (o) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        return b == 0 ? null : a / b;
    }
    return null;
  }

  // 整数ならそのまま、小数なら小数で表示する
  String _fmt(double r) => r == r.roundToDouble() ? r.toInt().toString() : r.toString();

  void tapOp(String o) {
    setState(() {
      final current = double.tryParse(display);
      // すでに「数 演算子 数」が入力済みなら、先にそれを計算してから次の演算子へ
      if (first != null && op != null && !resetNext && current != null) {
        final r = _compute(first!, current, op!);
        if (r == null) {
          display = 'エラー';
          first = null;
          op = null;
          resetNext = true;
          return;
        }
        display = _fmt(r);
        first = r;
      } else {
        first = current;
      }
      op = o;
      resetNext = true;
    });
  }

  void equals() {
    final second = double.tryParse(display);
    if (first == null || op == null || second == null) return;
    final r = _compute(first!, second, op!);
    setState(() {
      display = r == null ? 'エラー' : _fmt(r);
      first = null;
      op = null;
      resetNext = true;
    });
  }

  void clear() {
    setState(() {
      display = '0';
      first = null;
      op = null;
      resetNext = false;
    });
  }

  Widget _btn(String label, {VoidCallback? onTap, Color? color}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SizedBox(
          height: 60,
          child: FilledButton(
            style: color != null ? FilledButton.styleFrom(backgroundColor: color) : null,
            onPressed: onTap,
            child: Text(label, style: const TextStyle(fontSize: 22)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'ミニ電卓',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
            child: Text(display, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          Row(children: [
            _btn('C', onTap: clear, color: Colors.grey),
            _btn('÷', onTap: () => tapOp('÷'), color: const Color(0xFF4F46E5)),
            _btn('×', onTap: () => tapOp('×'), color: const Color(0xFF4F46E5)),
            _btn('-', onTap: () => tapOp('-'), color: const Color(0xFF4F46E5)),
          ]),
          Row(children: [
            _btn('7', onTap: () => tapNumber('7')),
            _btn('8', onTap: () => tapNumber('8')),
            _btn('9', onTap: () => tapNumber('9')),
            _btn('+', onTap: () => tapOp('+'), color: const Color(0xFF4F46E5)),
          ]),
          Row(children: [
            _btn('4', onTap: () => tapNumber('4')),
            _btn('5', onTap: () => tapNumber('5')),
            _btn('6', onTap: () => tapNumber('6')),
            _btn('=', onTap: equals, color: const Color(0xFF0EA5E9)),
          ]),
          Row(children: [
            _btn('1', onTap: () => tapNumber('1')),
            _btn('2', onTap: () => tapNumber('2')),
            _btn('3', onTap: () => tapNumber('3')),
            _btn('0', onTap: () => tapNumber('0')),
          ]),
          Row(children: [
            _btn('.', onTap: tapDot),
          ]),
        ],
      ),
    );
  }
}
