
### 2. Documentar a arquitetura

```bash
cat > docs/arquitetura.md <<'EOF'
# Documentação da Arquitetura

## 1. Modelo Tarefa

Arquivo: `lib/models/tarefa.dart`

A classe `Tarefa` representa uma tarefa cadastrada no aplicativo.

Atributos:
- `id`: identificador único gerado pelo banco.
- `titulo`: descrição da tarefa.
- `concluida`: indica se a tarefa foi finalizada.

Métodos:
- `toMap()`: converte o objeto em um mapa compatível com SQLite.
- `fromMap()`: cria um objeto a partir dos dados retornados pelo banco.
- `copyWith()`: cria uma cópia permitindo alterar atributos específicos.

## 2. DatabaseHelper

Arquivo: `lib/database/database_helper.dart`

Responsável pelo acesso aos dados e pela comunicação com SQLite.

A classe utiliza uma instância compartilhada do banco e cria a tabela `tarefas` na primeira inicialização.

Operações implementadas:
- `insert()`: insere uma tarefa.
- `queryAll()`: consulta todas as tarefas.
- `update()`: atualiza uma tarefa.
- `delete()`: exclui uma tarefa.

A interface não executa comandos SQL diretamente.

## 3. TarefaProvider

Arquivo: `lib/providers/tarefa_provider.dart`

A classe estende `ChangeNotifier` e centraliza o estado da aplicação.

Responsabilidades:
- Manter a lista de tarefas em memória.
- Carregar os registros do banco.
- Adicionar, editar, concluir e remover tarefas.
- Calcular os totais de tarefas.
- Aplicar filtros.
- Controlar o estado de carregamento.
- Notificar a interface por meio de `notifyListeners()`.

As operações de banco são assíncronas, evitando bloquear a interface durante o acesso aos dados.

## 4. Interface

Arquivo: `lib/main.dart`

A interface utiliza `ChangeNotifierProvider` para disponibilizar o Provider e `Consumer` para reconstruir a tela quando o estado muda.

A tela apresenta:
- Resumo do progresso.
- Contadores de tarefas.
- Filtros por situação.
- Lista de tarefas.
- Formulário de cadastro e edição.
- Confirmação de exclusão.
- Indicador de carregamento e mensagens para listas vazias.

## 5. Persistência no Flutter Web

O projeto configura `databaseFactoryFfiWeb` no início da aplicação quando executado no navegador.

A dependência `sqflite_common_ffi_web` permite utilizar a API do sqflite no ambiente Web, com persistência apoiada pelo IndexedDB.

Os arquivos `sqlite3.wasm` e `sqflite_sw.js`, gerados pela configuração do pacote, são mantidos na pasta `web/`.

## 6. Fluxo de atualização

Exemplo: quando o usuário conclui uma tarefa:

1. A interface chama `alternarStatus()`.
2. O Provider cria uma cópia da tarefa com o novo estado.
3. O DatabaseHelper atualiza o registro no SQLite.
4. O Provider atualiza a lista em memória.
5. `notifyListeners()` comunica a alteração.
6. O Consumer reconstrói a interface com o novo estado.

Esse fluxo mantém a persistência e a interface sincronizadas.
EOF