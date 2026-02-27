import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

void main() => runApp(const AuroraSasApp());

class AuroraSasApp extends StatelessWidget {
  const AuroraSasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AURORA SAS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0B0F),
        cardColor: const Color(0xFF14141B),
        useMaterial3: true,
      ),
      home: const TelaPrincipal(),
    );
  }
}

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  int _aba = 0;

  // Local/tempo
  String _localHumano = 'Carregando...';
  String _horarioLocal = '--:--:--';
  String _statusLocal = 'Iniciando…';
  Timer? _timer;

  // Clima (placeholder: depois conectamos no backend)
  String _clima = 'Aguardando conexão';
  String _umidade = 'Aguardando conexão';
  String _chuvaRisco = 'Aguardando conexão';

  // Alertas
  bool _modoJoias = true;
  bool _modoLogistica = true;

  // Growth (placeholder)
  int _leads = 0;
  double _vendas = 0;

  // Insights (placeholder)
  String _insights = 'Sem dados suficientes ainda. Registre KPIs e conecte o backend para insights.';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _horarioLocal = DateFormat('HH:mm:ss').format(DateTime.now());
      });
    });
    _atualizarLocal();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _atualizarLocal() async {
    setState(() => _statusLocal = 'Pedindo permissão de localização…');

    final ok = await _garantirPermissao();
    if (!ok) {
      setState(() {
        _statusLocal = 'Permissão negada ou GPS desligado.';
        _localHumano = 'Sem localização';
      });
      return;
    }

    setState(() => _statusLocal = 'Buscando GPS…');
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() => _statusLocal = 'Traduzindo coordenadas (cidade/bairro)…');
    final locais = await placemarkFromCoordinates(
      pos.latitude,
      pos.longitude,
      localeIdentifier: 'pt_BR',
    );

    final pm = locais.isNotEmpty ? locais.first : null;

    final bairro = (pm?.subLocality ?? pm?.subAdministrativeArea ?? '').trim();
    final cidade = (pm?.locality ?? '').trim();
    final uf = (pm?.administrativeArea ?? '').trim();

    final parts = <String>[];
    if (bairro.isNotEmpty) parts.add(bairro);
    if (cidade.isNotEmpty) parts.add(cidade);
    if (uf.isNotEmpty) parts.add(uf);

    setState(() {
      _localHumano = parts.isEmpty ? 'Local não identificado' : parts.join(' • ');
      _statusLocal = 'Localização ok';
    });

    // Aqui futuramente: chamar backend /context e /forecast e preencher clima/umidade/risco.
    // Por enquanto deixo como aguardando.
  }

  Future<bool> _garantirPermissao() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always || perm == LocationPermission.whileInUse;
  }

  @override
  Widget build(BuildContext context) {
    final telas = [
      _telaDashboard(),
      _telaClima(),
      _telaAlertas(),
      _telaGrowth(),
      _telaInsights(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('AURORA SAS'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _atualizarLocal,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: telas[_aba],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _aba,
        onDestinationSelected: (i) => setState(() => _aba = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.cloud), label: 'Clima'),
          NavigationDestination(icon: Icon(Icons.notifications), label: 'Alertas'),
          NavigationDestination(icon: Icon(Icons.trending_up), label: 'Growth'),
          NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'Insights'),
        ],
      ),
    );
  }

  Widget _card({required String titulo, required Widget child}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _linhaValor(String rotulo, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(rotulo, style: const TextStyle(fontSize: 14, color: Colors.white70)),
        Flexible(
          child: Text(
            valor,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  // ========== TELAS ==========

  Widget _telaDashboard() {
    return ListView(
      key: const ValueKey('dash'),
      children: [
        _card(
          titulo: 'Local',
          child: Column(
            children: [
              _linhaValor('Cidade/Bairro', _localHumano),
              const SizedBox(height: 8),
              _linhaValor('Horário', _horarioLocal),
              const SizedBox(height: 8),
              _linhaValor('Status', _statusLocal),
            ],
          ),
        ),
        _card(
          titulo: 'Clima (conexão em breve)',
          child: Column(
            children: [
              _linhaValor('Condição', _clima),
              const SizedBox(height: 8),
              _linhaValor('Umidade', _umidade),
              const SizedBox(height: 8),
              _linhaValor('Risco de chuva', _chuvaRisco),
              const SizedBox(height: 12),
              const Text(
                'Observação: clima/umidade/forecast vão aparecer quando conectarmos o backend.',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              )
            ],
          ),
        ),
        _card(
          titulo: 'Atalhos rápidos',
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _atualizarLocal,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Atualizar local'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _telaClima() {
    return ListView(
      key: const ValueKey('clima'),
      children: [
        _card(
          titulo: 'Clima e umidade',
          child: Column(
            children: [
              _linhaValor('Local', _localHumano),
              const SizedBox(height: 8),
              _linhaValor('Condição', _clima),
              const SizedBox(height: 8),
              _linhaValor('Umidade', _umidade),
              const SizedBox(height: 8),
              _linhaValor('Risco', _chuvaRisco),
            ],
          ),
        ),
        _card(
          titulo: 'Notas rápidas',
          child: const Text(
            'Assim que conectarmos /context e /forecast, essa tela vira “painel de previsão” completo.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }

  Widget _telaAlertas() {
    return ListView(
      key: const ValueKey('alertas'),
      children: [
        _card(
          titulo: 'Modos',
          child: Column(
            children: [
              SwitchListTile(
                value: _modoJoias,
                onChanged: (v) => setState(() => _modoJoias = v),
                title: const Text('Modo Joias'),
                subtitle: const Text('Alerta quando umidade estiver alta (prata sofre)'),
              ),
              SwitchListTile(
                value: _modoLogistica,
                onChanged: (v) => setState(() => _modoLogistica = v),
                title: const Text('Modo Logística'),
                subtitle: const Text('Alerta de chuva e sugestão de horário/rota (quando backend estiver ligado)'),
              ),
            ],
          ),
        ),
        _card(
          titulo: 'Prévia de recomendações',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _modoJoias
                    ? '• Joias: quando umidade > 70% (no futuro), recomendar sílica gel + embalagem selada.'
                    : '• Joias: desativado.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                _modoLogistica
                    ? '• Logística: quando chance de chuva alta (no futuro), sugerir sair mais cedo.'
                    : '• Logística: desativado.',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _telaGrowth() {
    return ListView(
      key: const ValueKey('growth'),
      children: [
        _card(
          titulo: 'Registrar KPI (manual por enquanto)',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _campoNumero(
                      rotulo: 'Leads',
                      valorAtual: _leads.toString(),
                      onSalvar: (v) => setState(() => _leads = v),
                      inteiro: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _campoNumero(
                      rotulo: 'Vendas (R$)',
                      valorAtual: _vendas.toStringAsFixed(2),
                      onSalvar: (v) => setState(() => _vendas = v.toDouble()),
                      inteiro: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Depois: isso vai mandar evento para /log e alimentar o modelo do SAS.',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _telaInsights() {
    return ListView(
      key: const ValueKey('insights'),
      children: [
        _card(
          titulo: 'Insights (SAS)',
          child: Text(
            _insights,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        _card(
          titulo: 'O que vem depois',
          child: const Text(
            'Quando o backend estiver ligado: regressão/árvore + recomendações automáticas.\n'
            'Ex: “Hoje a umidade + previsão de chuva indicam queda de fluxo; foque em WhatsApp e remarketing.”',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }

  // Campo simples para KPI
  Widget _campoNumero({
    required String rotulo,
    required String valorAtual,
    required void Function(num) onSalvar,
    required bool inteiro,
  }) {
    final ctrl = TextEditingController(text: valorAtual);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(rotulo, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onSubmitted: (txt) {
            final v = num.tryParse(txt.replaceAll(',', '.'));
            if (v == null) return;
            onSalvar(inteiro ? v.toInt() : v);
          },
        ),
      ],
    );
  }
}
