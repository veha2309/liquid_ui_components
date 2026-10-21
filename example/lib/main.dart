import 'package:flutter/material.dart';
import 'package:liquid_retina_navigation/liquid_retina_navigation.dart';

void main() => runApp(const NavigationExample());

class NavigationExample extends StatefulWidget {
  const NavigationExample({super.key});

  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  int index = 0;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: ThemeData(colorSchemeSeed: Colors.deepPurple),
    darkTheme: ThemeData(
      colorSchemeSeed: Colors.deepPurple,
      brightness: Brightness.dark,
    ),
    home: Scaffold(
      extendBody: true,
      appBar: AppBar(title: const Text('Liquid Retina Navigation')),
      body: IndexedStack(
        index: index,
        children: const [
          ColoredBox(
            color: Color(0xffe9d8fc),
            child: Center(child: Text('Home')),
          ),
          ColoredBox(
            color: Color(0xffd1f0e7),
            child: Center(child: Text('Explore')),
          ),
          ColoredBox(
            color: Color(0xffffe2cf),
            child: Center(child: Text('Profile')),
          ),
        ],
      ),
      bottomNavigationBar: LiquidRetinaNavigationBar(
        selectedIndex: index,
        onTap: (value) => setState(() => index = value),
        items: const [
          LiquidRetinaNavigationItem(label: 'Home', icon: Icons.home_outlined),
          LiquidRetinaNavigationItem(
            label: 'Explore',
            icon: Icons.explore_outlined,
          ),
          LiquidRetinaNavigationItem(
            label: 'Profile',
            icon: Icons.person_outline,
          ),
        ],
      ),
    ),
  );
}
