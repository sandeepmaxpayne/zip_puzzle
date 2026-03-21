import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  runApp(const ZipPuzzleApp());
}

enum DifficultyMode { easy, hard }

extension DifficultyModeLabel on DifficultyMode {
  String get description => switch (this) {
    DifficultyMode.easy => 'Follow the hidden original route.',
    DifficultyMode.hard => 'Move through any blank path and time checkpoints.',
  };
}

class ZipPuzzleApp extends StatefulWidget {
  const ZipPuzzleApp({super.key});

  @override
  State<ZipPuzzleApp> createState() => _ZipPuzzleAppState();
}

class _ZipPuzzleAppState extends State<ZipPuzzleApp> {
  ThemeMode _themeMode = ThemeMode.light;
  bool _showSplash = true;

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zip Puzzle',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _showSplash
            ? SplashScreen(
                key: const ValueKey('splash'),
                onFinished: () {
                  if (!mounted) {
                    return;
                  }
                  setState(() {
                    _showSplash = false;
                  });
                },
              )
            : ZipPuzzleHome(
                key: const ValueKey('home'),
                themeMode: _themeMode,
                onThemeChanged: _toggleTheme,
              ),
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: isDark ? const Color(0xFF6DE0C8) : const Color(0xFF0A7B83),
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF08131B)
          : const Color(0xFFF4F7F8),
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
        bodyColor: isDark ? const Color(0xFFE9F4F1) : const Color(0xFF10212B),
        displayColor: isDark
            ? const Color(0xFFE9F4F1)
            : const Color(0xFF10212B),
      ),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF11232E) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward();
    Future<void>.delayed(const Duration(milliseconds: 2600), widget.onFinished);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    Color(0xFF071018),
                    Color(0xFF0E2736),
                    Color(0xFF163F46),
                  ]
                : const [
                    Color(0xFFF7FCFF),
                    Color(0xFFDDF6F0),
                    Color(0xFFB8E8E0),
                  ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final curve = CurvedAnimation(
                parent: _controller,
                curve: Curves.easeOutCubic,
              );
              return Opacity(
                opacity: Tween<double>(
                  begin: 0,
                  end: 1,
                ).evaluate(curve).clamp(0.0, 1.0).toDouble(),
                child: Transform.scale(
                  scale: Tween<double>(begin: 0.72, end: 1).evaluate(curve),
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1CC9A6), Color(0xFF0A7B83)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0A7B83).withOpacity(0.28),
                        blurRadius: 26,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: LogoPainter(progress: _controller.value),
                        child: const SizedBox.expand(),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Zip Puzzle Studio',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'An original pathfinding challenge built for this project',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ZipPuzzleHome extends StatefulWidget {
  const ZipPuzzleHome({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<ZipPuzzleHome> createState() => _ZipPuzzleHomeState();
}

class _ZipPuzzleHomeState extends State<ZipPuzzleHome> {
  static const int gridSize = 6;

  late PuzzleBoardData _board;
  final GlobalKey _boardKey = GlobalKey();
  final math.Random _random = math.Random();
  DifficultyMode _mode = DifficultyMode.easy;
  bool _isDragging = false;
  bool _showHint = false;
  String _statusText = 'Easy mode: follow the true route from 1.';

  @override
  void initState() {
    super.initState();
    _board = PuzzleGenerator(_random).createBoard();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = widget.themeMode == ThemeMode.dark;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            final maxContentWidth = math.min(viewport.maxWidth, 760.0);
            final horizontalPadding = viewport.maxWidth < 420 ? 14.0 : 18.0;
            final boardSize = math.min(
              maxContentWidth - (horizontalPadding * 2),
              420.0,
            );

            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.surface,
                    theme.scaffoldBackgroundColor,
                    isDark ? const Color(0xFF061017) : const Color(0xFFE2F5F0),
                  ],
                ),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  10,
                  horizontalPadding,
                  22,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxContentWidth,
                      minHeight: viewport.maxHeight - 32,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(theme, isDark),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: boardSize,
                          height: boardSize,
                          child: GestureDetector(
                            key: _boardKey,
                            onPanStart: (details) {
                              _isDragging = _startDrag(details.globalPosition);
                            },
                            onPanUpdate: (details) {
                              if (_isDragging) {
                                _handlePointer(details.globalPosition);
                              }
                            },
                            onPanEnd: (_) => _isDragging = false,
                            onPanCancel: () => _isDragging = false,
                            child: _buildBoard(boardSize),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _buildBottomPanel(theme),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    final progress = _board.currentStep / PuzzleBoardData.maxStep;
    final nextTarget = _board.nextTargetNumber;
    final stepsRemaining = _board.stepsUntilNextTarget;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zip Puzzle Studio',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _mode == DifficultyMode.easy
                            ? 'Easy mode guides you through the original internal route.'
                            : 'Hard mode turns the board into a freeform strategy maze.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.72),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _showInfoSheet,
                  icon: const Icon(Icons.info_outline_rounded),
                  tooltip: 'Info',
                ),
                const SizedBox(width: 12),
                Switch(value: isDark, onChanged: widget.onThemeChanged),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<DifficultyMode>(
                segments: const [
                  ButtonSegment<DifficultyMode>(
                    value: DifficultyMode.easy,
                    label: Text('Easy'),
                    icon: Icon(Icons.route_rounded),
                  ),
                  ButtonSegment<DifficultyMode>(
                    value: DifficultyMode.hard,
                    label: Text('Hard'),
                    icon: Icon(Icons.alt_route_rounded),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) {
                  _changeMode(selection.first);
                },
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _mode.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.65),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: 150,
                  child: _StatChip(
                    label: 'Step',
                    value: '${_board.currentStep}',
                    color: const Color(0xFF0A7B83),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: _StatChip(
                    label: 'Next',
                    value: nextTarget == null ? 'Done' : '$nextTarget',
                    color: const Color(0xFFF4A259),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: _StatChip(
                    label: 'Moves Left',
                    value: stepsRemaining == null ? '0' : '$stepsRemaining',
                    color: const Color(0xFF1CC9A6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 11,
                value: progress.clamp(0.0, 1.0).toDouble(),
                backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoard(double boardSize) {
    final cellSize = boardSize / gridSize;
    final hintTarget = _showHint ? _board.nextHintPoint(_mode) : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(boardSize, boardSize),
            painter: PathPainter(path: _board.path, cellSize: cellSize),
          ),
          Column(
            children: List.generate(gridSize, (row) {
              return Expanded(
                child: Row(
                  children: List.generate(gridSize, (col) {
                    final point = GridPoint(row, col);
                    return Expanded(
                      child: _PuzzleCellWidget(
                        cell: _board.grid[row][col],
                        isEndpoint:
                            _board.path.isNotEmpty && _board.path.last == point,
                        isHintTarget: hintTarget == point,
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(ThemeData theme) {
    final isComplete = _board.isComplete;
    final nextTarget = _board.nextTargetNumber;
    final hintPoint = _board.nextHintPoint(_mode);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isComplete ? 'Puzzle complete!' : _statusText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isComplete)
                  const Icon(
                    Icons.celebration_rounded,
                    color: Color(0xFFF4A259),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _helperText(isComplete, nextTarget, hintPoint),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: _resetCurrentPuzzle,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Reset'),
                ),
                FilledButton.tonalIcon(
                  onPressed: isComplete ? null : _toggleHint,
                  icon: Icon(
                    _showHint ? Icons.visibility_off_rounded : Icons.lightbulb,
                  ),
                  label: Text(_showHint ? 'Hide Hint' : 'Hint'),
                ),
                OutlinedButton.icon(
                  onPressed: _newPuzzle,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('New Puzzle'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _helperText(bool isComplete, int? nextTarget, GridPoint? hintPoint) {
    if (isComplete) {
      return 'You completed the full board using the original Zip Puzzle ruleset.';
    }
    if (_mode == DifficultyMode.easy) {
      return _showHint && hintPoint != null
          ? 'Hint: follow the highlighted next studio path step.'
          : 'Easy mode only accepts the exact hidden route generated for this board.';
    }
    if (nextTarget == null) {
      return 'Keep filling the remaining cells.';
    }
    return _showHint && hintPoint != null
        ? 'Hint: checkpoint $nextTarget is near row ${hintPoint.row + 1}, column ${hintPoint.col + 1}.'
        : 'Hard mode allows any blank-cell route, but checkpoint $nextTarget must still be reached on time.';
  }

  void _showInfoSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About Zip Puzzle Studio',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This game uses an original in-house visual treatment, custom UI language, and internally generated puzzle layouts.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'It is designed as a distinct puzzle experience rather than a recreation of any third-party branded game presentation.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                Text(
                  'Copyright Appruloft',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showPrivacySheet();
                  },
                  icon: const Icon(Icons.privacy_tip_outlined),
                  label: const Text('Privacy Policy'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPrivacySheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Privacy Policy',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Zip Puzzle Studio by Appruloft is designed as a general-audience puzzle game.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'This app is intended to run locally and does not require account creation to play.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'Based on the current implementation in this project, Appruloft does not intentionally collect, store, or share personal data from players inside the app experience.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'If future versions add analytics, ads, sign-in, cloud saves, payments, or crash reporting, the Play Console Data safety form and this privacy policy should be updated before release.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'Data retention: no player profile or personal data retention is described for this local-only version.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'Contact: Appruloft should provide a public support email and hosted privacy-policy URL in the Google Play Console before publishing.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                Text(
                  'Copyright Appruloft',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _startDrag(Offset globalPosition) {
    final point = _pointFromGlobalPosition(globalPosition);
    if (point == null) {
      return false;
    }

    if (_board.path.isEmpty) {
      if (_board.cellAt(point).fixedValue == 1) {
        setState(() {
          _board.begin(point);
          _statusText = _mode == DifficultyMode.easy
              ? 'Started at 1. Stay on the true route.'
              : 'Started at 1. Work toward ${_board.nextTargetNumber}.';
        });
        return true;
      }
      return false;
    }

    if (point == _board.path.last || point == _board.path.first) {
      return true;
    }

    if (_board.cellAt(point).fixedValue == 1) {
      setState(() {
        _board = _board.copyReset();
        _showHint = false;
        _board.begin(point);
        _statusText = 'Restarted from 1.';
      });
      return true;
    }

    return false;
  }

  void _handlePointer(Offset globalPosition) {
    final point = _pointFromGlobalPosition(globalPosition);
    if (point == null) {
      return;
    }
    _onCellDragged(point);
  }

  GridPoint? _pointFromGlobalPosition(Offset globalPosition) {
    final renderObject = _boardKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) {
      return null;
    }

    final localPosition = renderObject.globalToLocal(globalPosition);
    final size = renderObject.size;
    if (localPosition.dx < 0 ||
        localPosition.dy < 0 ||
        localPosition.dx > size.width ||
        localPosition.dy > size.height) {
      return null;
    }

    final cellSize = size.width / gridSize;
    final row = (localPosition.dy / cellSize)
        .floor()
        .clamp(0, gridSize - 1)
        .toInt();
    final col = (localPosition.dx / cellSize)
        .floor()
        .clamp(0, gridSize - 1)
        .toInt();
    return GridPoint(row, col);
  }

  void _onCellDragged(GridPoint point) {
    if (_board.path.isEmpty || _board.path.last == point) {
      return;
    }

    if (_board.canBacktrackTo(point)) {
      setState(() {
        _board.backtrack();
        _statusText = 'Backtracked one step.';
      });
      return;
    }

    final result = _board.tryMove(point, _mode);
    if (!result.moved) {
      return;
    }

    setState(() {
      if (_board.isComplete) {
        _statusText = 'Puzzle complete!';
      } else if (result.hitTarget) {
        _statusText = 'Nice. Now work toward ${_board.nextTargetNumber}.';
      } else if (_mode == DifficultyMode.easy) {
        _statusText = 'Correct route. Keep tracing forward.';
      } else {
        _statusText = 'Good path. Keep going.';
      }
    });
  }

  void _toggleHint() {
    setState(() {
      _showHint = !_showHint;
      _statusText = _showHint ? 'Hint enabled.' : 'Hint hidden.';
    });
  }

  void _changeMode(DifficultyMode mode) {
    if (mode == _mode) {
      return;
    }
    setState(() {
      _mode = mode;
      _board = _board.copyReset();
      _showHint = false;
      _statusText = mode == DifficultyMode.easy
          ? 'Easy mode: follow the true route from 1.'
          : 'Hard mode: use any blank path and time each checkpoint.';
    });
  }

  void _resetCurrentPuzzle() {
    setState(() {
      _board = _board.copyReset();
      _showHint = false;
      _statusText = _mode == DifficultyMode.easy
          ? 'Puzzle reset. Follow the true route from 1.'
          : 'Puzzle reset. Start again from 1 and plan your own path.';
    });
  }

  void _newPuzzle() {
    setState(() {
      _board = PuzzleGenerator(_random).createBoard();
      _showHint = false;
      _statusText = _mode == DifficultyMode.easy
          ? 'Fresh easy puzzle ready.'
          : 'Fresh hard puzzle ready.';
    });
  }
}

class _PuzzleCellWidget extends StatelessWidget {
  const _PuzzleCellWidget({
    required this.cell,
    required this.isEndpoint,
    required this.isHintTarget,
  });

  final PuzzleCell cell;
  final bool isEndpoint;
  final bool isHintTarget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final background = cell.fixedValue != null
        ? const Color(0xFFF4A259).withOpacity(isDark ? 0.22 : 0.18)
        : cell.isVisited
        ? const Color(0xFF1CC9A6).withOpacity(isDark ? 0.22 : 0.14)
        : Colors.transparent;

    final borderColor = isHintTarget
        ? const Color(0xFFF4A259)
        : isEndpoint
        ? theme.colorScheme.primary
        : theme.dividerColor.withOpacity(isDark ? 0.22 : 0.16);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: borderColor, width: isHintTarget ? 2.5 : 1),
      ),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: isEndpoint || cell.fixedValue != null ? 40 : 18,
          height: isEndpoint || cell.fixedValue != null ? 40 : 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cell.fixedValue != null
                ? const Color(0xFFF4A259)
                : isEndpoint
                ? const Color(0xFF1CC9A6)
                : cell.isVisited
                ? const Color(0xFF1CC9A6).withOpacity(0.75)
                : Colors.transparent,
            boxShadow: cell.fixedValue != null || isHintTarget
                ? [
                    BoxShadow(
                      color: const Color(0xFFF4A259).withOpacity(0.24),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : const [],
          ),
          alignment: Alignment.center,
          child: cell.fixedValue == null
              ? null
              : Text(
                  '${cell.fixedValue}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF10212B),
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.72),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class PuzzleGenerator {
  PuzzleGenerator(this.random);

  final math.Random random;
  static const int gridSize = 6;

  PuzzleBoardData createBoard() {
    final path = _applyTransform(_buildSerpentinePath(), random.nextInt(8));
    final solutionMap = <GridPoint, int>{};
    for (var i = 0; i < path.length; i++) {
      solutionMap[path[i]] = i + 1;
    }

    final revealValues = _buildRevealValues().toList()..sort();
    final grid = List.generate(gridSize, (row) {
      return List.generate(gridSize, (col) {
        final point = GridPoint(row, col);
        final solutionValue = solutionMap[point]!;
        final fixedValue = revealValues.contains(solutionValue)
            ? solutionValue
            : null;
        return PuzzleCell(solutionValue: solutionValue, fixedValue: fixedValue);
      });
    });

    return PuzzleBoardData(grid: grid, revealedValues: revealValues);
  }

  List<GridPoint> _buildSerpentinePath() {
    final points = <GridPoint>[];
    for (var row = 0; row < gridSize; row++) {
      if (row.isEven) {
        for (var col = 0; col < gridSize; col++) {
          points.add(GridPoint(row, col));
        }
      } else {
        for (var col = gridSize - 1; col >= 0; col--) {
          points.add(GridPoint(row, col));
        }
      }
    }
    return points;
  }

  List<GridPoint> _applyTransform(List<GridPoint> path, int variant) {
    return path.map((point) {
      final row = point.row;
      final col = point.col;
      switch (variant) {
        case 0:
          return GridPoint(row, col);
        case 1:
          return GridPoint(col, gridSize - 1 - row);
        case 2:
          return GridPoint(gridSize - 1 - row, gridSize - 1 - col);
        case 3:
          return GridPoint(gridSize - 1 - col, row);
        case 4:
          return GridPoint(row, gridSize - 1 - col);
        case 5:
          return GridPoint(gridSize - 1 - row, col);
        case 6:
          return GridPoint(col, row);
        default:
          return GridPoint(gridSize - 1 - col, gridSize - 1 - row);
      }
    }).toList();
  }

  Set<int> _buildRevealValues() {
    final values = <int>{1, 36};
    final candidates = List<int>.generate(34, (index) => index + 2)
      ..shuffle(random);
    values.addAll(candidates.take(7));
    return values;
  }
}

class PuzzleBoardData {
  PuzzleBoardData({required this.grid, required this.revealedValues});

  static const int maxStep = 36;

  final List<List<PuzzleCell>> grid;
  final List<int> revealedValues;
  final List<GridPoint> path = <GridPoint>[];
  int currentStep = 1;

  PuzzleCell cellAt(GridPoint point) => grid[point.row][point.col];

  int? get nextTargetNumber {
    for (final value in revealedValues) {
      if (value > currentStep) {
        return value;
      }
    }
    return null;
  }

  GridPoint? get nextTargetPoint {
    final target = nextTargetNumber;
    if (target == null) {
      return null;
    }

    for (var row = 0; row < grid.length; row++) {
      for (var col = 0; col < grid[row].length; col++) {
        if (grid[row][col].fixedValue == target) {
          return GridPoint(row, col);
        }
      }
    }
    return null;
  }

  int? get stepsUntilNextTarget {
    final target = nextTargetNumber;
    return target == null ? null : target - currentStep;
  }

  bool get isComplete => currentStep == maxStep && path.length == maxStep;

  void begin(GridPoint point) {
    path
      ..clear()
      ..add(point);
    currentStep = 1;
    cellAt(point).isVisited = true;
  }

  MoveResult tryMove(GridPoint next, DifficultyMode mode) {
    final last = path.last;
    final nextCell = cellAt(next);
    if (!_isAdjacent(last, next) || path.contains(next)) {
      return const MoveResult(moved: false, hitTarget: false);
    }

    final expectedStep = currentStep + 1;
    if (mode == DifficultyMode.easy && nextCell.solutionValue != expectedStep) {
      return const MoveResult(moved: false, hitTarget: false);
    }
    if (mode == DifficultyMode.hard &&
        nextCell.fixedValue != null &&
        nextCell.fixedValue != expectedStep) {
      return const MoveResult(moved: false, hitTarget: false);
    }

    path.add(next);
    nextCell.isVisited = true;
    currentStep = expectedStep;

    return MoveResult(
      moved: true,
      hitTarget: nextCell.fixedValue == expectedStep,
    );
  }

  bool canBacktrackTo(GridPoint next) {
    return path.length > 1 && path[path.length - 2] == next;
  }

  void backtrack() {
    if (path.length <= 1) {
      return;
    }
    final removed = path.removeLast();
    cellAt(removed).isVisited = false;
    currentStep--;
  }

  GridPoint? nextHintPoint(DifficultyMode mode) {
    if (path.isEmpty) {
      return _pointForSolutionValue(1);
    }
    if (mode == DifficultyMode.easy) {
      final nextStep = currentStep + 1;
      if (nextStep > maxStep) {
        return null;
      }
      return _pointForSolutionValue(nextStep);
    }
    return nextTargetPoint;
  }

  PuzzleBoardData copyReset() {
    final copiedGrid = grid
        .map(
          (row) => row
              .map(
                (cell) => PuzzleCell(
                  solutionValue: cell.solutionValue,
                  fixedValue: cell.fixedValue,
                ),
              )
              .toList(),
        )
        .toList();

    return PuzzleBoardData(
      grid: copiedGrid,
      revealedValues: List<int>.from(revealedValues),
    );
  }

  GridPoint? _pointForSolutionValue(int value) {
    for (var row = 0; row < grid.length; row++) {
      for (var col = 0; col < grid[row].length; col++) {
        final cell = grid[row][col];
        if (cell.solutionValue == value) {
          return GridPoint(row, col);
        }
      }
    }
    return null;
  }

  bool _isAdjacent(GridPoint a, GridPoint b) {
    return (a.row - b.row).abs() <= 1 &&
        (a.col - b.col).abs() <= 1 &&
        !(a.row == b.row && a.col == b.col);
  }
}

class MoveResult {
  const MoveResult({required this.moved, required this.hitTarget});

  final bool moved;
  final bool hitTarget;
}

class PuzzleCell {
  PuzzleCell({required this.solutionValue, required this.fixedValue});

  final int solutionValue;
  final int? fixedValue;
  bool isVisited = false;
}

class GridPoint {
  const GridPoint(this.row, this.col);

  final int row;
  final int col;

  @override
  bool operator ==(Object other) {
    return other is GridPoint && other.row == row && other.col == col;
  }

  @override
  int get hashCode => Object.hash(row, col);
}

class PathPainter extends CustomPainter {
  const PathPainter({required this.path, required this.cellSize});

  final List<GridPoint> path;
  final double cellSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2) {
      return;
    }

    final glowPaint = Paint()
      ..color = const Color(0xFF1CC9A6).withOpacity(0.22)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final strokePaint = Paint()
      ..color = const Color(0xFF0A7B83)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final points = path.map(_offsetForCell).toList();
    final pathShape = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      pathShape.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(pathShape, glowPaint);
    canvas.drawPath(pathShape, strokePaint);
  }

  Offset _offsetForCell(GridPoint point) {
    return Offset(
      point.col * cellSize + cellSize / 2,
      point.row * cellSize + cellSize / 2,
    );
  }

  @override
  bool shouldRepaint(covariant PathPainter oldDelegate) {
    return oldDelegate.path != path || oldDelegate.cellSize != cellSize;
  }
}

class LogoPainter extends CustomPainter {
  LogoPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFEEFDF9), Color(0xFFC6FFF1)],
      ).createShader(rect);

    final border = Paint()
      ..color = const Color(0xFF083C46).withOpacity(0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final cell = size.width / 4.6;
    final startX = (size.width - cell * 3) / 2;
    final startY = (size.height - cell * 3) / 2;

    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 3; col++) {
        final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            startX + col * cell,
            startY + row * cell,
            cell - 8,
            cell - 8,
          ),
          const Radius.circular(12),
        );
        canvas.drawRRect(rrect, fill);
        canvas.drawRRect(rrect, border);
      }
    }

    final route = [
      Offset(startX + cell / 2 - 4, startY + cell / 2 - 4),
      Offset(startX + cell * 1.5 - 4, startY + cell / 2 - 4),
      Offset(startX + cell * 1.5 - 4, startY + cell * 1.5 - 4),
      Offset(startX + cell * 2.5 - 4, startY + cell * 1.5 - 4),
      Offset(startX + cell * 2.5 - 4, startY + cell * 2.5 - 4),
    ];

    final routePath = Path()..moveTo(route.first.dx, route.first.dy);
    for (final point in route.skip(1)) {
      routePath.lineTo(point.dx, point.dy);
    }

    final metric = routePath.computeMetrics().first;
    final extracted = metric.extractPath(0, metric.length * progress);
    final routePaint = Paint()
      ..color = const Color(0xFF0A7B83)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(extracted, routePaint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Z',
        style: TextStyle(
          color: Color(0xFF083C46),
          fontSize: 52,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, size.height - 74),
    );
  }

  @override
  bool shouldRepaint(covariant LogoPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
