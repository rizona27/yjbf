import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/settings_page.dart';
import 'pages/client_page.dart';
import 'services/data_manager.dart';
import 'services/fund_service.dart';
import 'models/fund_holding.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FundService()),
        ChangeNotifierProxyProvider<FundService, DataManager>(
          create: (context) => DataManager(fundService: context.read<FundService>()),
          update: (context, fundService, dataManager) => dataManager!..fundService = fundService,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '基金管家',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    OverviewPage(),
    ClientsPage(),
    RankingPage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('基金管家'),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: '一览',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: '客户',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: '排名',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('一览页面', style: TextStyle(fontSize: 24)),
    );
  }
}

class RankingPage extends StatelessWidget {
  const RankingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('排名页面', style: TextStyle(fontSize: 24)),
    );
  }
}