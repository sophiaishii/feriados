import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MeuApp());
}

// cores da paleta de cores do app, para manter consistência visual
class Paleta {
  static const Color fundo = Color(0xFFF7F2E7);
  static const Color papel = Color(0xFFFFFFFF);
  static const Color tinta = Color(0xFF1B2340);
  static const Color tintaSuave = Color(0xFF5B6178);
  static const Color dourado = Color(0xFFC9A227);
  static const Color linha = Color(0xFFE4DCC8);
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Consulta de Feriados',
      theme: ThemeData(
        scaffoldBackgroundColor: Paleta.fundo,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Paleta.tinta,
          primary: Paleta.tinta,
          secondary: Paleta.dourado,
        ),
        useMaterial3: true,
      ),
      home: const TelaConsultaFeriados(),
    );
  }
}

// abreviações de mês em português, usadas na "folhinha" de calendário
const List<String> _mesesAbreviados = [
  'JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN',
  'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ',
];

// cor temática de cada feriado — usada na faixa superior da "folhinha"
// e nos detalhes do card.
Color obterCorFeriado(String nome) {
  final n = nome.toLowerCase();

  final cores = <String, Color>{
    'confraternização': const Color(0xFFC9A227), // dourado
    'ano novo': const Color(0xFFC9A227), // dourado
    'tiradentes': const Color(0xFF3E5C76), // azul-petróleo
    'trabalh': const Color(0xFFB4622D), // marrom-terracota
    'independência': const Color(0xFF1E7145), // verde-bandeira
    'aparecida': const Color(0xFF6B4E71), // roxo
    'finados': const Color(0xFF5C6672), // cinza
    'república': const Color(0xFF2C4770), // azul-marinho
    'consciência negra': const Color(0xFF6B4226), // marrom-escuro
    'natal': const Color(0xFFA13D3D), // vermelho
    'carnaval': const Color(0xFF9C4F6E), // rosa
    'páscoa': const Color(0xFF6E8F5C), // verde
    'sexta-feira santa': const Color(0xFF3B3B6D), // azul-escuro
    'paixão de cristo': const Color(0xFF3B3B6D), // azul-escuro
    'corpus christi': const Color(0xFFC9962C), // amarelo 
  };

  for (final chave in cores.keys) {
    if (n.contains(chave)) return cores[chave]!;
  }

  return Paleta.tinta;
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

  List<dynamic> feriados = [];
  List<dynamic> feriadosFuturos = [];

  bool carregando = false;
  String? mensagemErro;

  Map<String, dynamic>? feriadoSelecionado;

  Future<void> buscarFeriados() async {
    final ano = controladorAno.text.trim();

    if (ano.isEmpty) {
      setState(() {
        mensagemErro = 'Digite um ano para realizar a busca.';
        feriados = [];
        feriadosFuturos = [];
        feriadoSelecionado = null;
      });
      return;
    }

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

  List<dynamic> filtrarFeriadosFuturos(List<dynamic> listaCompleta) {
    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);

    final futuros = listaCompleta.where((feriado) {
      final dataFeriado = DateTime.parse(feriado['date']);
      return !dataFeriado.isBefore(hojeSemHora);
    }).toList();

    futuros.sort((a, b) {
      final dataA = DateTime.parse(a['date']);
      final dataB = DateTime.parse(b['date']);
      return dataA.compareTo(dataB);
    });

    return futuros;
  }

  int calcularDiasRestantes(String dataFeriadoTexto) {
    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
    final dataFeriado = DateTime.parse(dataFeriadoTexto);
    return dataFeriado.difference(hojeSemHora).inDays;
  }

  String formatarData(String data) {
    final partes = data.split('-');
    if (partes.length == 3) {
      return '${partes[2]}/${partes[1]}/${partes[0]}';
    }
    return data;
  }

  void selecionarFeriado(Map<String, dynamic> feriado) {
    setState(() {
      feriadoSelecionado = feriado;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool temProximoFeriado = feriadosFuturos.isNotEmpty;
    final proximoFeriado =
        temProximoFeriado ? feriadosFuturos.first : null;

    return Scaffold(
      backgroundColor: Paleta.fundo,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CABEÇALHO 
              _buildCabecalho(),

              const SizedBox(height: 22),

              // CAMPO DE ANO + BOTÃO
              Text(
                'ANO DA CONSULTA',
                style: TextStyle(
                  color: Paleta.tintaSuave,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controladorAno,
                keyboardType: TextInputType.number,
                maxLength: 4,
                style: const TextStyle(
                  color: Paleta.tinta,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Ex.: 2026',
                  hintStyle: TextStyle(color: Paleta.tintaSuave.withOpacity(0.6)),
                  filled: true,
                  fillColor: Paleta.papel,
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Paleta.linha),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Paleta.dourado,
                      width: 1.6,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Paleta.linha),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Paleta.tinta,
                    foregroundColor: Paleta.papel,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: carregando ? null : buscarFeriados,
                  child: const Text(
                    'BUSCAR FERIADOS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (carregando)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: CircularProgressIndicator(
                      color: Paleta.dourado,
                    ),
                  ),
                ),

              if (mensagemErro != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBEAEA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE3AFAF)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFA13D3D), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          mensagemErro!,
                          style: const TextStyle(
                            color: Color(0xFF8A2E2E),
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // PRÓXIMO FERIADO
              if (!carregando && mensagemErro == null && temProximoFeriado)
                _buildCartaoDestaque(
                  rotulo: 'PRÓXIMO FERIADO',
                  feriado: proximoFeriado,
                ),

              // FERIADO SELECIONADO
              if (!carregando &&
                  mensagemErro == null &&
                  feriadoSelecionado != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _buildCartaoDestaque(
                    rotulo: 'FERIADO SELECIONADO',
                    feriado: feriadoSelecionado!,
                  ),
                ),

              // LISTA DE FERIADOS FUTUROS
              if (!carregando &&
                  mensagemErro == null &&
                  feriadosFuturos.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 26, bottom: 10),
                  child: Row(
                    children: [
                      Text(
                        'TODOS OS PRÓXIMOS',
                        style: TextStyle(
                          color: Paleta.tintaSuave,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(height: 1, color: Paleta.linha),
                      ),
                    ],
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: feriadosFuturos.length,
                  itemBuilder: (context, index) {
                    final feriado = feriadosFuturos[index];
                    return _buildItemLista(feriado);
                  },
                ),
              ],

              if (!carregando &&
                  mensagemErro == null &&
                  feriados.isNotEmpty &&
                  feriadosFuturos.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Center(
                    child: Text(
                      'Não há mais feriados futuros para o ano digitado.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Paleta.tintaSuave),
                    ),
                  ),
                ),

              if (!carregando && mensagemErro == null && feriados.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: Center(
                    child: Text(
                      'Digite um ano e toque em "Buscar feriados".',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Paleta.tintaSuave),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // CABEÇALHO — bloco escuro com "pontinhos" de espiral no topo
  Widget _buildCabecalho() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: Paleta.tinta,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // pontinhos de espiral, como um bloco de agenda preso por argolas
          Row(
            children: List.generate(8, (i) {
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: Paleta.fundo.withOpacity(0.85),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),
          const Text(
            'Feriados Nacionais',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Consulte o ano e acompanhe o que ainda vem por aí',
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // "FOLHINHA" DE CALENDÁRIO — mês em cima, dia embaixo, na cor
  // temática do feriado.
  Widget _buildFolhinha(String dataTexto, Color cor, {double largura = 56}) {
    final data = DateTime.parse(dataTexto);
    final mes = _mesesAbreviados[data.month - 1];
    final dia = data.day.toString().padLeft(2, '0');

    return SizedBox(
      width: largura,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: cor,
              alignment: Alignment.center,
              child: Text(
                mes,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Paleta.papel,
                border: Border.all(color: Paleta.linha, width: 1),
              ),
              alignment: Alignment.center,
              child: Text(
                dia,
                style: TextStyle(
                  color: Paleta.tinta,
                  fontSize: largura * 0.34,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CARTÃO DE DESTAQUE (próximo feriado / selecionado)
  Widget _buildCartaoDestaque({
    required String rotulo,
    required Map<String, dynamic> feriado,
  }) {
    final cor = obterCorFeriado(feriado['name']);
    final dias = calcularDiasRestantes(feriado['date']);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Paleta.papel,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: cor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Paleta.tinta.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildFolhinha(feriado['date'], cor, largura: 62),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rotulo,
                  style: TextStyle(
                    color: cor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feriado['name'],
                  style: const TextStyle(
                    color: Paleta.tinta,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  formatarData(feriado['date']),
                  style: const TextStyle(
                    color: Paleta.tintaSuave,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  dias == 0 ? 'HOJE' : '$dias',
                  style: TextStyle(
                    color: cor,
                    fontSize: dias == 0 ? 14 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (dias != 0)
                  Text(
                    dias == 1 ? 'dia' : 'dias',
                    style: TextStyle(
                      color: cor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ITEM DA LISTA
  Widget _buildItemLista(Map<String, dynamic> feriado) {
    final cor = obterCorFeriado(feriado['name']);
    final dias = calcularDiasRestantes(feriado['date']);
    final estaSelecionado = feriadoSelecionado != null &&
        feriadoSelecionado!['date'] == feriado['date'] &&
        feriadoSelecionado!['name'] == feriado['name'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Paleta.papel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: estaSelecionado ? cor : Paleta.linha,
          width: estaSelecionado ? 1.6 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => selecionarFeriado(feriado),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildFolhinha(feriado['date'], cor, largura: 46),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feriado['name'],
                        style: const TextStyle(
                          color: Paleta.tinta,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dias == 0 ? 'É hoje' : 'Faltam $dias dia(s)',
                        style: TextStyle(
                          color: cor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Paleta.tintaSuave.withOpacity(0.5)),
              ],
            ),
          ),
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