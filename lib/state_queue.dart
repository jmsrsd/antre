library state_queue;

import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';

typedef StateQueueEvent<T> = FutureOr<T> Function(
  StateQueue<T> queue,
);
typedef StateQueueCreate<T> = T Function();
typedef StateQueueListener<T> = void Function(T state);
typedef StateQueueViewBuilder<T> = Widget Function(
  BuildContext context,
  StateQueue<T> queue,
);

class StateQueue<T> {
  late final Queue<StateQueueEvent<T>> _queue;
  late final List<StateQueueListener<T>> _listeners;
  late T _state;
  late Future<void>? _processor;

  StateQueue(StateQueueCreate<T> create) {
    _queue = Queue<StateQueueEvent<T>>();
    _listeners = <StateQueueListener<T>>[];
    _state = create();
    _processor = null;
  }

  bool get isEmpty {
    return _queue.isEmpty;
  }

  bool get isNotEmpty {
    return _queue.isNotEmpty;
  }

  int get length {
    return _queue.length;
  }

  T get state {
    return _state;
  }

  void enqueue(StateQueueEvent<T> event) {
    _queue.addLast(event);
    notifyListeners();
    _processor ??= Future(() async {
      while (isNotEmpty) {
        _state = await _queue.first(this);
        _queue.removeFirst();
        notifyListeners();
      }
      _processor = null;
    });
  }

  void listen(StateQueueListener<T> listener) {
    if (_listeners.contains(listener)) return;
    _listeners.add(listener);
    listener(_state);
  }

  void unlisten(StateQueueListener<T> listener) {
    _listeners.remove(listener);
  }

  void notifyListeners() {
    for (final listener in _listeners) {
      listener(_state);
    }
  }

  Widget view({
    void Function()? init,
    void Function()? dispose,
    required StateQueueViewBuilder<T> builder,
  }) {
    return _StateQueueView<T>(
      queue: this,
      init: init ?? () {},
      dispose: dispose ?? () {},
      builder: builder,
    );
  }
}

class _StateQueueView<T> extends StatefulWidget {
  final StateQueue<T> queue;
  final void Function() init;
  final void Function() dispose;
  final StateQueueViewBuilder<T> builder;

  const _StateQueueView({
    super.key,
    required this.queue,
    required this.init,
    required this.dispose,
    required this.builder,
  });

  @override
  _StateQueueViewState<T> createState() {
    return _StateQueueViewState<T>();
  }
}

class _StateQueueViewState<T> extends State<_StateQueueView<T>> {
  void onState(T state) {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.init();
  }

  @override
  void dispose() {
    widget.dispose();
    widget.queue.unlisten(onState);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widget.queue.listen(onState);
    return widget.builder(context, widget.queue);
  }
}
