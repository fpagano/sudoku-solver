import 'package:flutter/material.dart';
import 'result_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sudoku Solver',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const int n = 9; // Fisso a 9
  List<List<String>> matrix = [];
  List<List<int>> tavola = [];
  List<List<bool>> booleanMatrix = [];

  @override
  void initState() {
    super.initState();
    _createMatrix();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sudoku Solver'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inserisci i numeri del Sudoku (9x9):',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // Matrice di listbox con divisioni dei quadranti
            Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calcola la dimensione ottimale delle celle
                  double availableWidth =
                      MediaQuery.of(context).size.width - 32; // padding
                  double maxCellSize =
                      (availableWidth - 20) / 9; // 20px per bordi e margini
                  double cellSize = maxCellSize.clamp(25.0, 45.0);

                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 3),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(9, (i) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(9, (j) {
                            int quadrante = _getQuadrante(i, j);

                            return Container(
                              width: cellSize,
                              height: cellSize,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: (i == 0 || i == 3 || i == 6)
                                        ? Colors.black
                                        : Colors.grey.shade400,
                                    width:
                                        (i == 0 || i == 3 || i == 6) ? 2 : 0.5,
                                  ),
                                  bottom: BorderSide(
                                    color: (i == 2 || i == 5 || i == 8)
                                        ? Colors.black
                                        : Colors.transparent,
                                    width: (i == 2 || i == 5 || i == 8) ? 2 : 0,
                                  ),
                                  left: BorderSide(
                                    color: (j == 0 || j == 3 || j == 6)
                                        ? Colors.black
                                        : Colors.grey.shade400,
                                    width:
                                        (j == 0 || j == 3 || j == 6) ? 2 : 0.5,
                                  ),
                                  right: BorderSide(
                                    color: (j == 2 || j == 5 || j == 8)
                                        ? Colors.black
                                        : Colors.transparent,
                                    width: (j == 2 || j == 5 || j == 8) ? 2 : 0,
                                  ),
                                ),
                                color: quadrantColors[quadrante],
                              ),
                              child: DropdownButton<String>(
                                value: matrix[i][j],
                                isExpanded: true,
                                underline: Container(),
                                items: _getDropdownItems(),
                                onChanged: (value) {
                                  setState(() {
                                    matrix[i][j] = value!;
                                  });
                                },
                                style: TextStyle(
                                  fontSize: (cellSize * 0.4).clamp(10.0, 16.0),
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                                dropdownColor: quadrantColors[quadrante],
                              ),
                            );
                          }),
                        );
                      }),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 30),

            // Bottone per risolvere
            Center(
              child: ElevatedButton(
                onPressed: _processMatrix,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text('Risolvi Sudoku', style: TextStyle(fontSize: 18)),
              ),
            ),
            SizedBox(height: 30),

            // Bottone per risolvere
            Center(
              child: ElevatedButton(
                onPressed: _clearMatrix,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                ),
                child: Text('Azzera tutto', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _getDropdownItems() {
    List<DropdownMenuItem<String>> items = [
      DropdownMenuItem(value: '', child: Text(' ')),
    ];

    for (int i = 1; i <= 9; i++) {
      items.add(DropdownMenuItem(
        value: i.toString(),
        child: Text(i.toString()),
      ));
    }

    return items;
  }

  void _createMatrix() {
    setState(() {
      matrix = List.generate(n, (i) => List.generate(n, (j) => ''));
      tavola = [];
      booleanMatrix = [];
    });
  }

  void _clearMatrix() {
    setState(() {
      matrix = List.generate(n, (i) => List.generate(n, (j) => ''));
      tavola = [];
      booleanMatrix = [];
    });

    // Mostra feedback all'utente
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sudoku azzerato!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _processMatrix() {
    // Controlla duplicati nelle righe, colonne e quadranti
    String? errorMessage = _validateMatrix();
    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Crea la matrice "tavola" con i numeri selezionati
    tavola = List.generate(
        n,
        (i) => List.generate(n, (j) {
              String value = matrix[i][j];
              return value.isEmpty ? 0 : int.parse(value);
            }));

    // Crea la matrice boolean
    booleanMatrix = List.generate(
        n,
        (i) => List.generate(n, (j) {
              return matrix[i][j].isNotEmpty;
            }));

    // Naviga alla pagina dei risultati
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultPage(
          tavola: tavola,
          booleanMatrix: booleanMatrix,
        ),
      ),
    );
  }

  // Colori per i 9 quadranti
  final List<Color> quadrantColors = [
    Colors.red.shade50, // Quadrante 0
    Colors.blue.shade50, // Quadrante 1
    Colors.green.shade50, // Quadrante 2
    Colors.orange.shade50, // Quadrante 3
    Colors.purple.shade50, // Quadrante 4
    Colors.teal.shade50, // Quadrante 5
    Colors.pink.shade50, // Quadrante 6
    Colors.amber.shade50, // Quadrante 7
    Colors.cyan.shade50, // Quadrante 8
  ];

  int _getQuadrante(int i, int j) {
    return (i ~/ 3) * 3 + (j ~/ 3);
  }

  String? _validateMatrix() {
    // Controlla duplicati nelle righe
    for (int i = 0; i < n; i++) {
      Map<String, int> valuesInRow = {};
      for (int j = 0; j < n; j++) {
        String value = matrix[i][j];
        if (value.isNotEmpty) {
          if (valuesInRow.containsKey(value)) {
            return 'Errore: Il numero $value è duplicato nella riga ${i + 1}';
          }
          valuesInRow[value] = j;
        }
      }
    }

    // Controlla duplicati nelle colonne
    for (int j = 0; j < n; j++) {
      Map<String, int> valuesInColumn = {};
      for (int i = 0; i < n; i++) {
        String value = matrix[i][j];
        if (value.isNotEmpty) {
          if (valuesInColumn.containsKey(value)) {
            return 'Errore: Il numero $value è duplicato nella colonna ${j + 1}';
          }
          valuesInColumn[value] = i;
        }
      }
    }

    // Controlla duplicati nei quadranti 3x3
    for (int quadrante = 0; quadrante < 9; quadrante++) {
      Map<String, String> valuesInQuadrant = {};
      int startRow = (quadrante ~/ 3) * 3;
      int startCol = (quadrante % 3) * 3;

      for (int i = startRow; i < startRow + 3; i++) {
        for (int j = startCol; j < startCol + 3; j++) {
          String value = matrix[i][j];
          if (value.isNotEmpty) {
            if (valuesInQuadrant.containsKey(value)) {
              return 'Errore: Il numero $value è duplicato nel quadrante ${(quadrante ~/ 3) + 1}-${(quadrante % 3) + 1} (posizioni ${i + 1},${j + 1} e ${valuesInQuadrant[value]})';
            }
            valuesInQuadrant[value] = '${i + 1},${j + 1}';
          }
        }
      }
    }

    return null; // Nessun errore
  }
}
