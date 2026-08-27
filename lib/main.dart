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

  List<dynamic> feriados = [];

  bool carregando = false;
  String? mensagemErro;

  Future<void> buscarFeriados() async {
    final ano = controladorAno.text.trim();

    // Verifica se o usuário digitou um ano
    if (ano.isEmpty) {
      setState(() {
        mensagemErro = 'Digite um ano para realizar a busca.';
        feriados = [];
      });
      return;
    }

    // Verifica se o ano possui 4 números
    if (ano.length != 4 || int.tryParse(ano) == null) {
      setState(() {
        mensagemErro = 'Digite um ano válido, por exemplo: 2026.';
        feriados = [];
      });
      return;
    }

    setState(() {
      carregando = true;
      mensagemErro = null;
      feriados = [];
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
      });
    }
  }

  String formatarData(String data) {
    final partes = data.split('-');

    if (partes.length == 3) {
      return '${partes[2]}/${partes[1]}/${partes[0]}';
    }

    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consulta de Feriados'),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Icon(
              Icons.calendar_month,
              size: 70,
            ),

            const SizedBox(height: 16),

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

            const SizedBox(height: 24),

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

            const SizedBox(height: 24),

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

            if (!carregando &&
                mensagemErro == null &&
                feriados.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: feriados.length,
                  itemBuilder: (context, index) {
                    final feriado = feriados[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
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
                          'Data: ${formatarData(feriado['date'])}',
                        ),
                      ),
                    );
                  },
                ),
              ),

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