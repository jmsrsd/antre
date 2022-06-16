library antre;

import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';

typedef AntreEvent<T> = FutureOr<T> Function(
  Antre<T> antre,
);
typedef AntreCreate<T> = T Function();
typedef AntreOnState<T> = void Function(T state);
typedef AntreViewBuilder<T> = Widget Function(
  BuildContext context,
  Antre<T> antre,
);

class Antre<T> {
  late final Queue<AntreEvent<T>> _antre;
  late final List<AntreOnState<T>> _listeners;
  late T _state;
  late Future<void>? _processor;

  Antre(AntreCreate<T> create) {
    _antre = Queue<AntreEvent<T>>();
    _listeners = <AntreOnState<T>>[];
    _state = create();
    _processor = null;
  }

  bool get isEmpty {
    return _antre.isEmpty;
  }

  bool get isNotEmpty {
    return _antre.isNotEmpty;
  }

  int get length {
    return _antre.length;
  }

  T get state {
    return _state;
  }

  void enqueue(AntreEvent<T> event) {
    _antre.addLast(event);
    notifyListeners();
    _processor ??= Future(() async {
      while (isNotEmpty) {
        _state = await _antre.first(this);
        _antre.removeFirst();
        notifyListeners();
      }
      _processor = null;
    });
  }

  void listen(AntreOnState<T> listener) {
    if (_listeners.contains(listener)) return;
    _listeners.add(listener);
    listener(_state);
  }

  void unlisten(AntreOnState<T> listener) {
    _listeners.remove(listener);
  }

  void notifyListeners() {
    for (final listener in _listeners) {
      listener(_state);
    }
  }

  Widget view({
    AntreOnState<T>? init,
    AntreOnState<T>? dispose,
    required AntreViewBuilder<T> builder,
  }) {
    return _AntreView<T>(
      antre: this,
      init: init ?? (state) {},
      dispose: dispose ?? (state) {},
      builder: builder,
    );
  }
}

class _AntreView<T> extends StatefulWidget {
  final Antre<T> antre;
  final AntreOnState<T> init;
  final AntreOnState<T> dispose;
  final AntreViewBuilder<T> builder;

  const _AntreView({
    super.key,
    required this.antre,
    required this.init,
    required this.dispose,
    required this.builder,
  });

  @override
  _AntreViewState<T> createState() {
    return _AntreViewState<T>();
  }
}

class _AntreViewState<T> extends State<_AntreView<T>> {
  void onState(T state) {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.init(widget.antre.state);
  }

  @override
  void dispose() {
    widget.dispose(widget.antre.state);
    widget.antre.unlisten(onState);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widget.antre.listen(onState);
    return widget.builder(context, widget.antre);
  }
}
