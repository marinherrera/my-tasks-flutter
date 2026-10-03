import 'package:flutter/material.dart';

void main() {
  runApp(const MeuMiniApp());
}

//1. DART: Modelo de Dados

class Item {
  String titulo;
  bool isConcluido;

  Item({required this.titulo, this.isConcluido = false});
}

enum FiltroTarefa { todas, pendentes, concluidas }

class MeuMiniApp extends StatelessWidget {
  const MeuMiniApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stressed Out Tasks',
      theme: ThemeData(primaryColor: Colors.purple),
      home: const TelaPrincipal(),
    );
  }
}

// 2. Flutter: Tela reativa (StatefulWidget)

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  // Controlador para o campo de texto
  final TextEditingController _controller = TextEditingController();

  final Color _corPrincipal = const Color.fromARGB(255, 209, 90, 233);

  String? _erroCampo;

  FiltroTarefa _filtro = FiltroTarefa.todas;

  //Lista em Memória

  final Map<String, List<Item>> _secoes = {
    'Geral': [
      Item(titulo: 'Revisar Conceitos de DART'),
      Item(titulo: 'Criar primeiro Widget Flutter'),
    ],
  };
  String _secaoAtual = 'Geral';

  List<Item> get _itens => _secoes[_secaoAtual]!;

  int get _total => _itens.length;
  int get _concluidas => _itens.where((item) => item.isConcluido).length;

  List<Item> get _itensFiltrados {
    switch (_filtro) {
      case FiltroTarefa.pendentes:
        return _itens.where((item) => !item.isConcluido).toList();
      case FiltroTarefa.concluidas:
        return _itens.where((item) => item.isConcluido).toList();
      case FiltroTarefa.todas:
        return _itens;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _mostrarMensagemCentral(String texto) {
    var fechamentoAgendado = false;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Mensagem',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (context, animation, __, child) {
        final zoom = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: zoom, child: child),
        );
      },
      pageBuilder: (dialogContext, __, ___) {
        if (!fechamentoAgendado) {
          fechamentoAgendado = true;
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          });
        }

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Chip(
              avatar: const Icon(Icons.check_circle, color: Colors.white),
              label: Text(
                texto,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: _corPrincipal,
              elevation: 8,
              shadowColor: Colors.black,
              shape: const StadiumBorder(),
              side: BorderSide.none,
              padding: const EdgeInsets.all(14),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmarExclusao(String titulo, String mensagem) async {
    final resposta = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apagar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    return resposta == true;
  }

  void _adicionarItem() {
    if (_controller.text.trim().isEmpty) {
      setState(() => _erroCampo = 'O título da tarefa não pode estar vazio!');
      return;
    }

    setState(() {
      _erroCampo = null;
      _itens.add(Item(titulo: _controller.text.trim()));
      _controller.clear();
    });

    _mostrarMensagemCentral('Tarefa adicionada com sucesso!');
  }

  void _alternarStatus(Item item) {
    setState(() {
      item.isConcluido = !item.isConcluido;
    });
  }

  void _reordenar(int indiceAntigo, int indiceNovo) {
    setState(() {
      final item = _itens.removeAt(indiceAntigo);
      _itens.insert(indiceNovo, item);
    });
  }

  Future<void> _removerItem(Item item) async {
    final confirmou = await _confirmarExclusao(
      'Excluir tarefa',
      'Tem certeza que deseja apagar esta tarefa?',
    );

    if (!mounted || !confirmou) return;

    setState(() {
      _itens.remove(item);
    });
  }

  Future<void> _adicionarSecao() async {
    final nome = await showDialog<String>(
      context: context,
      builder: (_) => DialogNovaSecao(existentes: _secoes.keys.toList()),
    );

    if (!mounted || nome == null) return;

    setState(() {
      _secoes[nome] = [];
      _secaoAtual = nome;
    });
  }

  Future<void> _removerSecao() async {
    final nome = _secaoAtual;

    final confirmou = await _confirmarExclusao(
      'Apagar seção',
      'Apagar a seção "$nome" e todas as suas tarefas?',
    );

    if (!mounted || !confirmou) return;

    setState(() {
      _secoes.remove(nome);
      _secaoAtual = _secoes.keys.first;
    });
  }

  Widget _caixaResumo(String rotulo, int valor, IconData icone) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _corPrincipal.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icone, color: _corPrincipal),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$valor',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  rotulo,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itensExibidos = _itensFiltrados;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        backgroundColor: _corPrincipal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final nome in _secoes.keys)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(nome),
                        selected: nome == _secaoAtual,
                        onSelected: (_) => setState(() => _secaoAtual = nome),
                      ),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: const Text('Seção'),
                    onPressed: _adicionarSecao,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            //Campo de Entrada de Texto + Botão
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: (_) {
                      if (_erroCampo != null) {
                        setState(() => _erroCampo = null);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Nova tarefa em "$_secaoAtual"',
                      border: const OutlineInputBorder(),
                      errorText: _erroCampo,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _adicionarItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 199, 100, 245),
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),

            const SizedBox(height: 16),

            SegmentedButton<FiltroTarefa>(
              segments: const [
                ButtonSegment(value: FiltroTarefa.todas, label: Text('Todas')),
                ButtonSegment(
                  value: FiltroTarefa.pendentes,
                  label: Text('Pendentes'),
                ),
                ButtonSegment(
                  value: FiltroTarefa.concluidas,
                  label: Text('Concluídas'),
                ),
              ],
              selected: {_filtro},
              onSelectionChanged: (selecao) {
                setState(() => _filtro = selecao.first);
              },
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                _caixaResumo('Total', _total, Icons.list_alt),
                const SizedBox(width: 12),
                _caixaResumo('Concluídas', _concluidas, Icons.check_circle),
                IconButton(
                  tooltip: 'Apagar seção',
                  icon: const Icon(Icons.folder_delete_outlined),
                  onPressed: _secoes.length > 1 ? _removerSecao : null,
                ),
              ],
            ),

            const SizedBox(height: 8),

            //Lista Dinâmica
            Expanded(
              child: itensExibidos.isEmpty
                  ? const Center(child: Text('Nenhuma tarefa'))
                  : ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      itemCount: itensExibidos.length,
                      onReorderItem: _reordenar,
                      itemBuilder: (context, index) {
                        final item = itensExibidos[index];
                        return Card(
                          key: ValueKey(item),
                          elevation: 2,
                          child: ListTile(
                            leading: Checkbox(
                              value: item.isConcluido,
                              onChanged: (_) => _alternarStatus(item),
                            ),
                            title: Text(
                              item.titulo,
                              style: TextStyle(
                                decoration: item.isConcluido
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                LixeiraAnimada(
                                  onPressed: () => _removerItem(item),
                                ),
                                if (_filtro == FiltroTarefa.todas)
                                  IconeArrastar(indice: index),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// 3. criar uma nova seção

class DialogNovaSecao extends StatefulWidget {
  final List<String> existentes;

  const DialogNovaSecao({super.key, required this.existentes});

  @override
  State<DialogNovaSecao> createState() => _DialogNovaSecaoState();
}

class _DialogNovaSecaoState extends State<DialogNovaSecao> {
  final TextEditingController _controller = TextEditingController();
  String? _erro;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirmar() {
    final nome = _controller.text.trim();

    if (nome.isEmpty) {
      setState(() => _erro = 'O nome não pode estar vazio!');
      return;
    }

    final jaExiste = widget.existentes.any(
      (existente) => existente.toLowerCase() == nome.toLowerCase(),
    );
    if (jaExiste) {
      setState(() => _erro = 'Esse nome já existe!');
      return;
    }

    Navigator.pop(context, nome);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova seção'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        onSubmitted: (_) => _confirmar(),
        onChanged: (_) {
          if (_erro != null) setState(() => _erro = null);
        },
        decoration: InputDecoration(
          labelText: 'Nome da seção',
          border: const OutlineInputBorder(),
          errorText: _erro,
          errorMaxLines: 2,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(onPressed: _confirmar, child: const Text('Criar')),
      ],
    );
  }
}

// 4. icone de arrastar

class IconeArrastar extends StatefulWidget {
  final int indice;

  const IconeArrastar({super.key, required this.indice});

  @override
  State<IconeArrastar> createState() => _IconeArrastarState();
}

class _IconeArrastarState extends State<IconeArrastar> {
  bool _passouMouse = false;

  @override
  Widget build(BuildContext context) {
    return ReorderableDragStartListener(
      index: widget.indice,
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        onEnter: (_) => setState(() => _passouMouse = true),
        onExit: (_) => setState(() => _passouMouse = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _passouMouse
                ? Colors.grey.withValues(alpha: 0.25)
                : Colors.transparent,
          ),
          child: AnimatedScale(
            scale: _passouMouse ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.drag_handle,
              color: _passouMouse ? Colors.black87 : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}

// 5. lixeira

class LixeiraAnimada extends StatefulWidget {
  final VoidCallback onPressed;

  const LixeiraAnimada({super.key, required this.onPressed});

  @override
  State<LixeiraAnimada> createState() => _LixeiraAnimadaState();
}

class _LixeiraAnimadaState extends State<LixeiraAnimada> {
  bool _passouMouse = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _passouMouse = true),
      onExit: (_) => setState(() => _passouMouse = false),
      child: IconButton(
        onPressed: widget.onPressed,
        icon: TweenAnimationBuilder<double>(
          tween: Tween(end: _passouMouse ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          builder: (context, abertura, _) => CustomPaint(
            size: const Size(24, 24),
            painter: _LixeiraPainter(abertura: abertura, cor: Colors.red),
          ),
        ),
      ),
    );
  }
}

// animação lixeira
class _LixeiraPainter extends CustomPainter {
  final double abertura;
  final Color cor;

  _LixeiraPainter({required this.abertura, required this.cor});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);

    final tinta = Paint()..color = cor;

    final corpo = Path()
      ..moveTo(5.5, 9)
      ..lineTo(18.5, 9)
      ..lineTo(17.4, 20.2)
      ..quadraticBezierTo(17.3, 21.5, 16, 21.5)
      ..lineTo(8, 21.5)
      ..quadraticBezierTo(6.7, 21.5, 6.6, 20.2)
      ..close();
    canvas.drawPath(corpo, tinta);

    final risca = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(10, 12), const Offset(10.3, 18.5), risca);
    canvas.drawLine(const Offset(14, 12), const Offset(13.7, 18.5), risca);

    canvas.save();
    canvas.translate(3.5, 6.7);
    canvas.rotate(-abertura * 0.55);
    canvas.translate(-3.5, -6.7);
    canvas.drawRRect(
      RRect.fromLTRBR(3, 5.5, 21, 7.8, const Radius.circular(1.1)),
      tinta,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(9.2, 3, 14.8, 5.5, const Radius.circular(1)),
      tinta,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LixeiraPainter antigo) {
    return antigo.abertura != abertura || antigo.cor != cor;
  }
}
