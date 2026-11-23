// ignore_for_file: deprecated_member_use
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'models/tarefa.dart';
import 'providers/tarefa_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configura o SQLite para funcionar no navegador.
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => TarefaProvider()..carregarTarefas(),
      child: const TarefasApp(),
    ),
  );
}

class TarefasApp extends StatelessWidget {
  const TarefasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tarefas Provider SQLite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<String?> _mostrarDialogo({
    required BuildContext context,
    required String titulo,
    String textoInicial = '',
  }) async {
    final controller = TextEditingController(text: textoInicial);

    final resultado = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(titulo),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'Descrição da tarefa',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.edit_note),
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                Navigator.pop(dialogContext, value.trim());
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.pop(dialogContext, controller.text.trim());
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return resultado;
  }

  Future<void> _adicionar(BuildContext context) async {
    final titulo = await _mostrarDialogo(
      context: context,
      titulo: 'Nova tarefa',
    );

    if (titulo != null && context.mounted) {
      await context.read<TarefaProvider>().adicionarTarefa(titulo);
    }
  }

  Future<void> _editar(BuildContext context, Tarefa tarefa) async {
    final titulo = await _mostrarDialogo(
      context: context,
      titulo: 'Editar tarefa',
      textoInicial: tarefa.titulo,
    );

    if (titulo != null && context.mounted) {
      await context.read<TarefaProvider>().editarTarefa(tarefa, titulo);
    }
  }

  Future<void> _confirmarExclusao(BuildContext context, Tarefa tarefa) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir tarefa?'),
        content: Text('Deseja excluir "${tarefa.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true && tarefa.id != null && context.mounted) {
      await context.read<TarefaProvider>().removerTarefa(tarefa.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Minhas Tarefas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Consumer<TarefaProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              _buildResumo(provider),
              _buildFiltros(provider),
              if (provider.erro != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    color: Colors.red.shade50,
                    child: ListTile(
                      leading: const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                      ),
                      title: Text(
                        provider.erro!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ),
              Expanded(child: _buildLista(context, provider)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _adicionar(context),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova tarefa'),
      ),
    );
  }

  Widget _buildResumo(TarefaProvider provider) {
    final percentual = provider.total == 0
        ? 0.0
        : provider.totalConcluidas / provider.total;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seu progresso',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${provider.totalConcluidas} de ${provider.total} concluídas',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${(percentual * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.indigo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: percentual,
              minHeight: 9,
              borderRadius: BorderRadius.circular(10),
              backgroundColor: Colors.indigo.shade50,
              color: Colors.indigo,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _indicador('Total', provider.total, Colors.indigo),
                _indicador('Pendentes', provider.totalPendentes, Colors.orange),
                _indicador(
                  'Concluídas',
                  provider.totalConcluidas,
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _indicador(String titulo, int quantidade, Color cor) {
    return Column(
      children: [
        Text(
          '$quantidade',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: cor,
          ),
        ),
        Text(titulo, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildFiltros(TarefaProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SegmentedButton<FiltroTarefas>(
        segments: const [
          ButtonSegment(
            value: FiltroTarefas.todas,
            label: Text('Todas'),
            icon: Icon(Icons.list),
          ),
          ButtonSegment(
            value: FiltroTarefas.pendentes,
            label: Text('Pendentes'),
            icon: Icon(Icons.pending_actions),
          ),
          ButtonSegment(
            value: FiltroTarefas.concluidas,
            label: Text('Concluídas'),
            icon: Icon(Icons.check_circle_outline),
          ),
        ],
        selected: {provider.filtro},
        onSelectionChanged: (selecionados) {
          provider.alterarFiltro(selecionados.first);
        },
        showSelectedIcon: false,
      ),
    );
  }

  Widget _buildLista(BuildContext context, TarefaProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final tarefas = provider.tarefasFiltradas;

    if (tarefas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.task_alt, size: 72, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                provider.total == 0
                    ? 'Nenhuma tarefa cadastrada ainda!'
                    : 'Nenhuma tarefa neste filtro.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 6),
              Text(
                provider.total == 0
                    ? 'Toque em "Nova tarefa" para começar.'
                    : 'Experimente selecionar outra categoria.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
      itemCount: tarefas.length,
      itemBuilder: (context, index) {
        final tarefa = tarefas[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            onLongPress: () => _editar(context, tarefa),
            leading: Checkbox(
              value: tarefa.concluida,
              activeColor: Colors.green,
              onChanged: (_) {
                context.read<TarefaProvider>().alternarStatus(tarefa);
              },
            ),
            title: Text(
              tarefa.titulo,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                decoration: tarefa.concluida
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                color: tarefa.concluida ? Colors.grey : Colors.black87,
              ),
            ),
            subtitle: Text(
              tarefa.concluida ? 'Concluída' : 'Pendente',
              style: TextStyle(
                color: tarefa.concluida ? Colors.green : Colors.orange,
              ),
            ),
            trailing: IconButton(
              tooltip: 'Excluir tarefa',
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmarExclusao(context, tarefa),
            ),
          ),
        );
      },
    );
  }
}
