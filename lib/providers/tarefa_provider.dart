import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/tarefa.dart';

enum FiltroTarefas { todas, pendentes, concluidas }

class TarefaProvider extends ChangeNotifier {
  final DatabaseHelper _database = DatabaseHelper.instance;

  List<Tarefa> _tarefas = [];
  bool _isLoading = false;
  String? _erro;
  FiltroTarefas _filtro = FiltroTarefas.todas;

  List<Tarefa> get tarefas => List.unmodifiable(_tarefas);
  bool get isLoading => _isLoading;
  String? get erro => _erro;
  FiltroTarefas get filtro => _filtro;

  int get total => _tarefas.length;

  int get totalConcluidas =>
      _tarefas.where((tarefa) => tarefa.concluida).length;

  int get totalPendentes => total - totalConcluidas;

  List<Tarefa> get tarefasFiltradas {
    switch (_filtro) {
      case FiltroTarefas.todas:
        return tarefas;
      case FiltroTarefas.pendentes:
        return _tarefas.where((tarefa) => !tarefa.concluida).toList();
      case FiltroTarefas.concluidas:
        return _tarefas.where((tarefa) => tarefa.concluida).toList();
    }
  }

  void alterarFiltro(FiltroTarefas novoFiltro) {
    _filtro = novoFiltro;
    notifyListeners();
  }

  Future<void> carregarTarefas() async {
    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      _tarefas = await _database.queryAll();
    } catch (e) {
      _erro = 'Não foi possível carregar as tarefas: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> adicionarTarefa(String titulo) async {
    final texto = titulo.trim();
    if (texto.isEmpty) return;

    try {
      final novaTarefa = Tarefa(titulo: texto);
      final id = await _database.insert(novaTarefa);

      _tarefas.insert(0, novaTarefa.copyWith(id: id));
      _erro = null;
      notifyListeners();
    } catch (e) {
      _erro = 'Não foi possível adicionar a tarefa: $e';
      notifyListeners();
    }
  }

  Future<void> alternarStatus(Tarefa tarefa) async {
    if (tarefa.id == null) return;

    final atualizada = tarefa.copyWith(concluida: !tarefa.concluida);

    try {
      await _database.update(atualizada);

      final index = _tarefas.indexWhere((item) => item.id == tarefa.id);

      if (index != -1) {
        _tarefas[index] = atualizada;
        _erro = null;
        notifyListeners();
      }
    } catch (e) {
      _erro = 'Não foi possível atualizar a tarefa: $e';
      notifyListeners();
    }
  }

  Future<void> editarTarefa(Tarefa tarefa, String novoTitulo) async {
    final texto = novoTitulo.trim();
    if (texto.isEmpty || tarefa.id == null) return;

    final atualizada = tarefa.copyWith(titulo: texto);

    try {
      await _database.update(atualizada);

      final index = _tarefas.indexWhere((item) => item.id == tarefa.id);

      if (index != -1) {
        _tarefas[index] = atualizada;
        _erro = null;
        notifyListeners();
      }
    } catch (e) {
      _erro = 'Não foi possível editar a tarefa: $e';
      notifyListeners();
    }
  }

  Future<void> removerTarefa(int id) async {
    try {
      await _database.delete(id);
      _tarefas.removeWhere((tarefa) => tarefa.id == id);
      _erro = null;
      notifyListeners();
    } catch (e) {
      _erro = 'Não foi possível remover a tarefa: $e';
      notifyListeners();
    }
  }
}
