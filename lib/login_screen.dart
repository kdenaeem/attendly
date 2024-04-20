import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Flutter Widget Example'),
        ),
        body: Center(
          child: MyWidget(),
        ),
      ),
    );
  }
}

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Welcome to Attendly',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 20.0),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Enter rabbit number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        SizedBox(height: 20.0),
        ElevatedButton(
          onPressed: () {
            // Add your button functionality here
          },
          child: Text('Enter'),
        ),
      ],
    );
  }
}
