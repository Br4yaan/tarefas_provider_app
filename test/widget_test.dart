import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:tarefas_provider_app/main.dart';
import 'package:tarefas_provider_app/providers/tarefa_provider.dart';

void main() {
  testWidgets('Aplicativo exibe a tela principal', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TarefaProvider(),
        child: const TarefasApp(),
      ),
    );

    expect(find.text('Minhas Tarefas'), findsOneWidget);
    expect(find.text('Seu progresso'), findsOneWidget);
    expect(find.text('Nenhuma tarefa cadastrada ainda!'), findsOneWidget);
  });
}
