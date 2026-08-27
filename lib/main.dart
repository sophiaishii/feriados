import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MeuApp());
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Consulta de Feriados',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const TelaConsultaFeriados(),
    );
  }
}

class TelaConsultaFeriados extends StatefulWidget {
  const TelaConsultaFeriados({super.key});

  @override
  State<TelaConsultaFeriados> createState() =>
      _TelaConsultaFeriadosState();
}

class _TelaConsultaFeriadosState
    extends State<TelaConsultaFeriados> {
  final TextEditingController controladorAno =
      TextEditingController();

  // API; todos os feriados do ano digitado
  List<dynamic> feriados = [];

  // lista já filtrada: só os feriados que ainda vão acontecer a partir de hoje
  List<dynamic> feriadosFuturos = [];

  bool carregando = false;
  String? mensagemErro;

  // guarda qual feriado o usuário selecionou na lista, para mostrar
  // "faltam X dias" para ele especificamente.
  Map<String, dynamic>? feriadoSelecionado;

  Future<void> buscarFeriados() async {
    final ano = controladorAno.text.trim();

    // verifica se o usuário digitou um ano
    if (ano.isEmpty) {
      setState(() {
        mensagemErro = 'Digite um ano para realizar a busca.';
        feriados = [];
        feriadosFuturos = [];
        feriadoSelecionado = null;
      });
      return;
    }

    // verifica se o ano possui 4 números
    if (ano.length != 4 || int.tryParse(ano) == null) {
      setState(() {
        mensagemErro = 'Digite um ano válido, por exemplo: 2026.';
        feriados = [];
        feriadosFuturos = [];
        feriadoSelecionado = null;
      });
      return;
    }

    setState(() {
      carregando = true;
      mensagemErro = null;
      feriados = [];
      feriadosFuturos = [];
      feriadoSelecionado = null;
    });

    final url = Uri.parse(
      'https://brasilapi.com.br/api/feriados/v1/$ano',
    );

    try {
      final resposta = await http.get(url);

      if (resposta.statusCode == 200) {
        final dados = jsonDecode(resposta.body);

        setState(() {
          feriados = dados;
          // assim que os dados chegam, já filtramos e ordenamos
          // para deixar pronta a lista de feriados futuros.
          feriadosFuturos = filtrarFeriadosFuturos(dados);
          carregando = false;
        });
      } else {
        setState(() {
          mensagemErro =
              'Não foi possível encontrar os feriados desse ano.';
          carregando = false;
        });
      }
    } catch (erro) {
      setState(() {
        mensagemErro =
            'Não foi possível conectar. Verifique sua internet.';
        carregando = false;
        feriados = [];
        feriadosFuturos = [];
      });
    }
  }

  // FILTRA SÓ OS FERIADOS QUE AINDA VÃO ACONTECER (a partir de hoje)
  // a API retorna a data como String no formato "yyyy-MM-dd".
  // para comparar com "hoje", convertemos essa String em DateTime.
  List<dynamic> filtrarFeriadosFuturos(List<dynamic> listaCompleta) {
    // "hoje" sem horas/minutos/segundos, só a data,
    // para comparar dia com dia sem erro de horário.
    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);

    // filtra deixando só as datas maiores ou iguais a hoje
    final futuros = listaCompleta.where((feriado) {
      final dataFeriado = DateTime.parse(feriado['date']);
      return !dataFeriado.isBefore(hojeSemHora);
    }).toList();

    // ordena da data mais próxima para a mais distante,
    // assim o primeiro item da lista sempre é o "próximo feriado".
    futuros.sort((a, b) {
      final dataA = DateTime.parse(a['date']);
      final dataB = DateTime.parse(b['date']);
      return dataA.compareTo(dataB);
    });

    return futuros;
  }

  // CALCULA QUANTOS DIAS FALTAM ENTRE HOJE E UMA DATA DE FERIADO
  int calcularDiasRestantes(String dataFeriadoTexto) {
    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);

    final dataFeriado = DateTime.parse(dataFeriadoTexto);

    // difference().inDays dá a diferença em dias completos
    return dataFeriado.difference(hojeSemHora).inDays;
  }

  String formatarData(String data) {
    final partes = data.split('-');

    if (partes.length == 3) {
      return '${partes[2]}/${partes[1]}/${partes[0]}';
    }

    return data;
  }

  // chamado quando o usuário toca em um feriado da lista
  void selecionarFeriado(Map<String, dynamic> feriado) {
    setState(() {
      feriadoSelecionado = feriado;
    });
  }

  @override
  Widget build(BuildContext context) {
    // o próximo feriado é sempre o primeiro da lista já filtrada/ordenada
    final bool temProximoFeriado = feriadosFuturos.isNotEmpty;
    final proximoFeriado =
        temProximoFeriado ? feriadosFuturos.first : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consulta de Feriados'),
        centerTitle: true,
      ),

      // SingleChildScrollView permite rolar a tela inteira (cabeçalho,
      // campo de busca, cards e lista de feriados) quando o conteúdo
      // é maior do que a altura disponível na tela.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 12),

            const Icon(
              Icons.calendar_month,
              size: 60,
            ),

            const SizedBox(height: 12),

            const Text(
              'Feriados Nacionais',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Digite um ano para consultar os feriados nacionais.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            TextField(
              controller: controladorAno,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: InputDecoration(
                labelText: 'Digite o ano',
                hintText: 'Ex.: 2026',
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: carregando ? null : buscarFeriados,
                icon: const Icon(Icons.search),
                label: const Text(
                  'Buscar feriados',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (carregando)
              const CircularProgressIndicator(),

            if (mensagemErro != null) ...[
              const SizedBox(height: 16),
              Text(
                mensagemErro!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
            ],

            // CARTÃO DE DESTAQUE: PRÓXIMO FERIADO
            // só aparece quando existe pelo menos um feriado futuro.
            if (!carregando &&
                mensagemErro == null &&
                temProximoFeriado)
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.orange),
                          const SizedBox(width: 8),
                          const Text(
                            'Próximo feriado',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        proximoFeriado['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Data: ${formatarData(proximoFeriado['date'])}',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        // calcularDiasRestantes devolve 0 quando o
                        // feriado é hoje mesmo.
                        calcularDiasRestantes(proximoFeriado['date']) == 0
                            ? 'É hoje!'
                            : 'Faltam ${calcularDiasRestantes(proximoFeriado['date'])} dia(s)',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // CARTÃO: DIAS RESTANTES PARA O FERIADO SELECIONADO
            // só aparece depois que o usuário tocar em algum item da lista.
            if (!carregando &&
                mensagemErro == null &&
                feriadoSelecionado != null)
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.touch_app),
                          const SizedBox(width: 8),
                          const Text(
                            'Feriado selecionado',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        feriadoSelecionado!['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Data: ${formatarData(feriadoSelecionado!['date'])}',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        calcularDiasRestantes(
                                    feriadoSelecionado!['date']) ==
                                0
                            ? 'É hoje!'
                            : 'Faltam ${calcularDiasRestantes(feriadoSelecionado!['date'])} dia(s)',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // LISTA DE FERIADOS FUTUROS
            // feriadosFuturos (e não feriados) para mostrar
            // só os que ainda vão acontecer a partir de hoje.
            if (!carregando &&
                mensagemErro == null &&
                feriadosFuturos.isNotEmpty)
              // shrinkWrap: true faz a lista ocupar só o espaço que
              // seus itens precisam, em vez de tentar preencher a tela.
              // physics: NeverScrollableScrollPhysics() desativa a
              // rolagem própria da lista, porque quem rola agora é o
              // SingleChildScrollView que envolve a tela inteira.
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: feriadosFuturos.length,
                itemBuilder: (context, index) {
                  final feriado = feriadosFuturos[index];
                  final dias = calcularDiasRestantes(feriado['date']);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      onTap: () => selecionarFeriado(feriado),
                      leading: const CircleAvatar(
                        child: Icon(Icons.event),
                      ),
                      title: Text(
                        feriado['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Data: ${formatarData(feriado['date'])}\n'
                        '${dias == 0 ? 'É hoje!' : 'Faltam $dias dia(s)'}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  );
                },
              ),

            // MENSAGEM QUANDO A BUSCA JÁ ACONTECEU, MAS NÃO SOBROU
            // NENHUM FERIADO FUTURO (por exemplo: ano já terminou)
            if (!carregando &&
                mensagemErro == null &&
                feriados.isNotEmpty &&
                feriadosFuturos.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  'Não há mais feriados futuros para o ano digitado.',
                  textAlign: TextAlign.center,
                ),
              ),

            // MENSAGEM INICIAL, ANTES DE QUALQUER BUSCA
            if (!carregando &&
                mensagemErro == null &&
                feriados.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  'Digite um ano e clique em "Buscar feriados".',
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    controladorAno.dispose();
    super.dispose();
  }
}
