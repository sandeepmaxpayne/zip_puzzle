import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/app_progress.dart';

class ClassicPuzzleArgs {
  const ClassicPuzzleArgs({required this.year, required this.day});

  final int year;
  final int day;
}

class ClassicPuzzleScreen extends StatefulWidget {
  const ClassicPuzzleScreen({super.key, required this.args});

  static const routeName = '/classic-puzzle';

  final ClassicPuzzleArgs args;

  @override
  State<ClassicPuzzleScreen> createState() => _ClassicPuzzleScreenState();
}

class _ClassicPuzzleScreenState extends State<ClassicPuzzleScreen> {
  final GlobalKey _boardKey = GlobalKey();

  late ClassicDifficulty _difficulty;
  late ClassicPuzzleDefinition _definition;
  late ClassicPuzzleBoard _board;
  bool _isDragging = false;
  bool _showHint = false;
  bool _completionHandled = false;

  @override
  void initState() {
    super.initState();
    _difficulty = ClassicDifficulty.easy;
    _loadBoard();
  }

  void _loadBoard() {
    _definition = ClassicPuzzleFactory.create(
      year: widget.args.year,
      day: widget.args.day,
      difficulty: _difficulty,
    );
    _board = ClassicPuzzleBoard(definition: _definition);
    _completionHandled = false;
  }

  void _changeDifficulty(ClassicDifficulty difficulty) {
    setState(() {
      _difficulty = difficulty;
      _showHint = false;
      _loadBoard();
    });
  }

  void _resetBoard() {
    setState(() {
      _showHint = false;
      _loadBoard();
    });
  }

  void _undo() {
    setState(() {
      _board.backtrack();
      _showHint = false;
    });
  }

  bool _startDrag(Offset globalPosition) {
    final point = _pointFromGlobalOffset(globalPosition);
    if (point == null) {
      return false;
    }
    final started = _board.begin(point);
    if (started) {
      setState(() => _showHint = false);
    }
    return started;
  }

  void _handlePointer(Offset globalPosition) {
    final point = _pointFromGlobalOffset(globalPosition);
    if (point == null) {
      return;
    }
    var shouldHandleCompletion = false;
    setState(() {
      _showHint = false;
      if (_board.canBacktrackTo(point)) {
        _board.backtrack();
      } else {
        _board.tryMove(point);
      }
      if (_board.isComplete && !_completionHandled) {
        shouldHandleCompletion = true;
      }
    });
    if (shouldHandleCompletion) {
      _handleCompletion();
    }
  }

  Future<void> _handleCompletion() async {
    _completionHandled = true;
    final controller = AppScope.of(context);
    await controller.markClassicLevelCompleted(
      year: widget.args.year,
      day: widget.args.day,
      difficulty: _difficulty,
    );
    if (!mounted) {
      return;
    }
    final totalScore = AppScope.of(context).progress.totalScore;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Text('Day ${widget.args.day} cleared'),
          content: Text(
            'You solved the ${_difficulty.label.toLowerCase()} route and earned +5 points. Your total score is now $totalScore.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Stay'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context)
                  ..pop()
                  ..pop();
              },
              child: const Text('Back To Days'),
            ),
          ],
        );
      },
    );
  }

  ClassicPoint? _pointFromGlobalOffset(Offset globalPosition) {
    final context = _boardKey.currentContext;
    if (context == null) {
      return null;
    }
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) {
      return null;
    }
    final local = box.globalToLocal(globalPosition);
    final size = box.size.width;
    if (local.dx < 0 || local.dy < 0 || local.dx > size || local.dy > size) {
      return null;
    }
    final cell = size / _definition.size;
    final row = (local.dy / cell).floor();
    final col = (local.dx / cell).floor();
    if (row < 0 || row >= _definition.size || col < 0 || col >= _definition.size) {
      return null;
    }
    return ClassicPoint(row, col);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hint = _showHint ? _board.nextHintPoint : null;
    final totalScore = AppScope.of(context).progress.totalScore;
    return Scaffold(
      appBar: AppBar(
        title: Text('Classic Day ${widget.args.day}'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxHeight < 760 || constraints.maxWidth < 390;
            final horizontalPadding = compact ? 12.0 : 14.0;
            final topPadding = compact ? 4.0 : 6.0;
            final bottomPadding = compact ? 12.0 : 18.0;
            final topPanelEstimate = compact ? 96.0 : 108.0;
            final bottomPanelEstimate = compact ? 84.0 : 92.0;
            final boardAvailableHeight = math.max(
              180.0,
              constraints.maxHeight -
                  topPanelEstimate -
                  bottomPanelEstimate -
                  36.0,
            );
            final boardSize = math.min(
              math.min(constraints.maxWidth - (horizontalPadding * 2), 430.0),
              boardAvailableHeight,
            );
            return Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                topPadding,
                horizontalPadding,
                bottomPadding,
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 12 : 14,
                      vertical: compact ? 10 : 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFF1CC), Color(0xFFE0FFF2)],
                      ),
                    ),
                    child: Column(
                      children: [
                        SegmentedButton<ClassicDifficulty>(
                          segments: ClassicDifficulty.values
                              .map(
                                (difficulty) => ButtonSegment<ClassicDifficulty>(
                                  value: difficulty,
                                  label: Text(difficulty.label),
                                ),
                              )
                              .toList(),
                          selected: {_difficulty},
                          onSelectionChanged: (selection) {
                            _changeDifficulty(selection.first);
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _ClassicStatChip(
                                icon: Icons.stars_rounded,
                                label: 'Your Score',
                                value: '$totalScore',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ClassicStatChip(
                                icon: Icons.add_circle_outline_rounded,
                                label: 'Win Reward',
                                value: '+5',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 12),
                  Expanded(
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, boardConstraints) {
                          final actualBoardSize = math.min(
                            boardSize,
                            math.min(
                              boardConstraints.maxWidth,
                              boardConstraints.maxHeight,
                            ),
                          );
                          return SizedBox(
                            width: actualBoardSize,
                            height: actualBoardSize,
                            child: Listener(
                              key: _boardKey,
                              behavior: HitTestBehavior.opaque,
                              onPointerDown: (event) {
                                _isDragging = _startDrag(event.position);
                              },
                              onPointerMove: (event) {
                                if (_isDragging) {
                                  _handlePointer(event.position);
                                }
                              },
                              onPointerUp: (_) => _isDragging = false,
                              onPointerCancel: (_) => _isDragging = false,
                              child: _ClassicPuzzleBoardView(
                                definition: _definition,
                                board: _board,
                                hintPoint: hint,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 12),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(compact ? 12 : 16),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _difficulty.flavor,
                              style: (compact
                                      ? theme.textTheme.bodyMedium
                                      : theme.textTheme.titleSmall)
                                  ?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(height: compact ? 8 : 10),
                          Row(
                            children: [
                              Expanded(
                                child: _ActionIconButton(
                                  onPressed: _board.path.length > 1 ? _undo : null,
                                  icon: Icons.undo_rounded,
                                  tooltip: 'Undo',
                                  isFilled: true,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _ActionIconButton(
                                  onPressed: _resetBoard,
                                  icon: Icons.restart_alt_rounded,
                                  tooltip: 'Reset',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _ActionIconButton(
                                  onPressed: _board.isComplete
                                      ? null
                                      : () {
                                          setState(() {
                                            _showHint = !_showHint;
                                          });
                                        },
                                  icon: _showHint
                                      ? Icons.visibility_off_rounded
                                      : Icons.lightbulb_rounded,
                                  tooltip: _showHint ? 'Hide Hint' : 'Hint',
                                  isPrimary: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ClassicStatChip extends StatelessWidget {
  const _ClassicStatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF153936)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF153936).withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF153936),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    this.isFilled = false,
    this.isPrimary = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;
  final bool isFilled;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = isPrimary
        ? theme.colorScheme.primary
        : isFilled
            ? theme.colorScheme.primary.withValues(alpha: 0.14)
            : Colors.transparent;
    final foregroundColor = isPrimary
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.primary;

    return SizedBox(
      height: 56,
      child: Tooltip(
        message: tooltip,
        triggerMode: TooltipTriggerMode.longPress,
        child: Material(
          color: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: isFilled || isPrimary
                ? BorderSide.none
                : BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.35),
                  ),
          ),
          child: IconButton(
            onPressed: onPressed,
            tooltip: tooltip,
            icon: Icon(icon),
            color: foregroundColor,
          ),
        ),
      ),
    );
  }
}

class _ClassicPuzzleBoardView extends StatelessWidget {
  const _ClassicPuzzleBoardView({
    required this.definition,
    required this.board,
    required this.hintPoint,
  });

  final ClassicPuzzleDefinition definition;
  final ClassicPuzzleBoard board;
  final ClassicPoint? hintPoint;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cell = constraints.maxWidth / definition.size;
          return Stack(
            children: [
              CustomPaint(
                size: Size.square(constraints.maxWidth),
                painter: _ClassicPathPainter(board: board, cellSize: cell),
              ),
              Column(
                children: List.generate(definition.size, (row) {
                  return Expanded(
                    child: Row(
                      children: List.generate(definition.size, (col) {
                        final point = ClassicPoint(row, col);
                        final anchorValue = definition.anchorValueFor(point);
                        final isVisited = board.path.contains(point);
                        final isHint = hintPoint == point;
                        return Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: isHint
                                  ? const Color(0xFFBCEEFF)
                                  : isVisited
                                      ? const Color(0xFFE1FFF4)
                                      : Colors.transparent,
                              border: Border.all(
                                color: const Color(0xFFB8BBB3),
                                width: 0.9,
                              ),
                            ),
                            child: Center(
                              child: anchorValue == null
                                  ? const SizedBox.shrink()
                                  : Container(
                                      width: cell * 0.46,
                                      height: cell * 0.46,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black,
                                        border: Border.all(
                                          color: board.path.isNotEmpty &&
                                                  board.path.last == point
                                              ? const Color(0xFF08B6F3)
                                              : Colors.transparent,
                                          width: 4,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '$anchorValue',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ClassicPuzzleFactory {
  static ClassicPuzzleDefinition create({
    required int year,
    required int day,
    required ClassicDifficulty difficulty,
  }) {
    final size = switch (difficulty) {
      ClassicDifficulty.easy => 5,
      ClassicDifficulty.medium => 6,
      ClassicDifficulty.hard => 6,
    };
    final random = math.Random((year * 1000) + (day * 13) + difficulty.index);
    final path = _applyTransform(_buildSerpentine(size), size, random.nextInt(8));
    final anchorCounts = <ClassicDifficulty, int>{
      ClassicDifficulty.easy: math.max(6, size + 3),
      ClassicDifficulty.medium: math.max(5, size),
      ClassicDifficulty.hard: 4,
    };
    final revealValues = <int>{1, size * size};
    final candidates = List<int>.generate((size * size) - 2, (index) => index + 2)
      ..shuffle(random);
    revealValues.addAll(candidates.take(anchorCounts[difficulty]! - 2));

    return ClassicPuzzleDefinition(
      size: size,
      solutionPath: path,
      anchorValues: revealValues,
    );
  }

  static List<ClassicPoint> _buildSerpentine(int size) {
    final result = <ClassicPoint>[];
    for (var row = 0; row < size; row++) {
      if (row.isEven) {
        for (var col = 0; col < size; col++) {
          result.add(ClassicPoint(row, col));
        }
      } else {
        for (var col = size - 1; col >= 0; col--) {
          result.add(ClassicPoint(row, col));
        }
      }
    }
    return result;
  }

  static List<ClassicPoint> _applyTransform(
    List<ClassicPoint> path,
    int size,
    int variant,
  ) {
    return path.map((point) {
      final row = point.row;
      final col = point.col;
      switch (variant) {
        case 0:
          return ClassicPoint(row, col);
        case 1:
          return ClassicPoint(col, size - 1 - row);
        case 2:
          return ClassicPoint(size - 1 - row, size - 1 - col);
        case 3:
          return ClassicPoint(size - 1 - col, row);
        case 4:
          return ClassicPoint(row, size - 1 - col);
        case 5:
          return ClassicPoint(size - 1 - row, col);
        case 6:
          return ClassicPoint(col, row);
        default:
          return ClassicPoint(size - 1 - col, size - 1 - row);
      }
    }).toList();
  }
}

class ClassicPuzzleDefinition {
  ClassicPuzzleDefinition({
    required this.size,
    required this.solutionPath,
    required Set<int> anchorValues,
  }) : anchorValues = anchorValues.toSet();

  final int size;
  final List<ClassicPoint> solutionPath;
  final Set<int> anchorValues;

  int? anchorValueFor(ClassicPoint point) {
    final index = solutionPath.indexOf(point);
    if (index == -1) {
      return null;
    }
    final value = index + 1;
    return anchorValues.contains(value) ? value : null;
  }

  ClassicPoint pointForStep(int step) => solutionPath[step - 1];
}

class ClassicPuzzleBoard {
  ClassicPuzzleBoard({required this.definition});

  final ClassicPuzzleDefinition definition;
  final List<ClassicPoint> path = <ClassicPoint>[];

  bool get isComplete => path.length == definition.solutionPath.length;

  ClassicPoint? get nextHintPoint {
    if (path.isEmpty) {
      return definition.pointForStep(1);
    }
    final nextStep = path.length + 1;
    if (nextStep > definition.solutionPath.length) {
      return null;
    }
    return definition.pointForStep(nextStep);
  }

  bool begin(ClassicPoint point) {
    if (point != definition.pointForStep(1)) {
      return false;
    }
    path
      ..clear()
      ..add(point);
    return true;
  }

  bool tryMove(ClassicPoint point) {
    if (path.isEmpty || path.contains(point)) {
      return false;
    }
    if (!_isAdjacent(path.last, point)) {
      return false;
    }
    final nextExpected = definition.pointForStep(path.length + 1);
    if (nextExpected != point) {
      return false;
    }
    path.add(point);
    return true;
  }

  bool canBacktrackTo(ClassicPoint point) {
    return path.length > 1 && path[path.length - 2] == point;
  }

  void backtrack() {
    if (path.length > 1) {
      path.removeLast();
    }
  }

  bool _isAdjacent(ClassicPoint a, ClassicPoint b) {
    final rowDelta = (a.row - b.row).abs();
    final colDelta = (a.col - b.col).abs();
    return (rowDelta + colDelta) == 1;
  }
}

class ClassicPoint {
  const ClassicPoint(this.row, this.col);

  final int row;
  final int col;

  @override
  bool operator ==(Object other) {
    return other is ClassicPoint && other.row == row && other.col == col;
  }

  @override
  int get hashCode => Object.hash(row, col);
}

class _ClassicPathPainter extends CustomPainter {
  const _ClassicPathPainter({required this.board, required this.cellSize});

  final ClassicPuzzleBoard board;
  final double cellSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (board.path.length < 2) {
      return;
    }
    final points = board.path
        .map(
          (point) => Offset(
            (point.col * cellSize) + (cellSize / 2),
            (point.row * cellSize) + (cellSize / 2),
          ),
        )
        .toList();

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    final glow = Paint()
      ..color = const Color(0xFF08B6F3).withValues(alpha: 0.22)
      ..strokeWidth = cellSize * 0.32
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final stroke = Paint()
      ..color = const Color(0xFF0A80D8)
      ..strokeWidth = cellSize * 0.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, glow);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _ClassicPathPainter oldDelegate) {
    return oldDelegate.board.path != board.path ||
        oldDelegate.cellSize != cellSize;
  }
}
