import 'package:flutter/material.dart';

class ResultPage extends StatefulWidget {
  final List<List<int>> tavola;
  final List<List<bool>> booleanMatrix;

  const ResultPage(
      {Key? key, required this.tavola, required this.booleanMatrix})
      : super(key: key);

  @override
  _ResultPageState createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  static const int n = 9;
  late List<List<int>> currentTavola;
  late List<List<bool>> currentBooleanMatrix;
  late List<Set<int>> rigaSets;
  late List<Set<int>> colonnaSets;
  late List<Set<int>> quadrantiSets;
  bool isCompleted = false;
  bool isSolving = false;
  bool hasError = false;
  String errorMessage = '';
  int iterazioni = 0;
  int maxIterazioni = 10000; // Limite massimo di iterazioni

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

  @override
  void initState() {
    super.initState();
    // Crea copie delle matrici originali
    currentTavola = widget.tavola.map((row) => List<int>.from(row)).toList();
    currentBooleanMatrix =
        widget.booleanMatrix.map((row) => List<bool>.from(row)).toList();

    // Inizializza i set e avvia la risoluzione
    _initializeSets();

    // Avvia la risoluzione dopo un breve delay
    Future.delayed(Duration(milliseconds: 500), () {
      _startSolving();
    });
  }

  void _initializeSets() {
    // Inizializza i set per righe, colonne e quadranti
    rigaSets =
        List.generate(n, (i) => Set<int>.from(List.generate(n, (j) => j + 1)));
    colonnaSets =
        List.generate(n, (i) => Set<int>.from(List.generate(n, (j) => j + 1)));
    quadrantiSets =
        List.generate(9, (i) => Set<int>.from(List.generate(n, (j) => j + 1)));

    // Rimuovi i numeri già presenti nella tavola dai set corrispondenti
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        if (currentTavola[i][j] != 0) {
          int quadrante = _getQuadrante(i, j);
          rigaSets[i].remove(currentTavola[i][j]);
          colonnaSets[j].remove(currentTavola[i][j]);
          quadrantiSets[quadrante].remove(currentTavola[i][j]);
        }
      }
    }
  }

  int _getQuadrante(int i, int j) {
    // Calcola l'indice del quadrante (0-8) data la posizione (i,j)
    return (i ~/ 3) * 3 + (j ~/ 3);
  }

  void _startSolving() {
    setState(() {
      isSolving = true;
      iterazioni = 0;
      hasError = false; // Reset dell'errore
      errorMessage = '';
    });
    _risolvi().then((success) {
      if (!success && !hasError && !isCompleted) {
        // Solo se non abbiamo già mostrato un errore specifico
        setState(() {
          hasError = true;
          errorMessage =
              'Sudoku impossibile: Esaurite tutte le possibilità di risoluzione dopo $iterazioni tentativi';
          isSolving = false;
        });
      }
    });
  }

  Future<bool> _risolvi() async {
    iterazioni++;

    // Controllo timeout
    if (iterazioni > maxIterazioni) {
      setState(() {
        hasError = true;
        errorMessage =
            'Timeout: Il Sudoku potrebbe non avere soluzione o essere troppo complesso';
        isSolving = false;
      });
      return false;
    }

    // Prima fase: trova celle con intersezione di cardinalità 1
    bool foundSingleValue = true;
    int singleValueIterations = 0;

    while (foundSingleValue && singleValueIterations < 100) {
      foundSingleValue = false;
      singleValueIterations++;

      for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
          if (!currentBooleanMatrix[i][j] && currentTavola[i][j] == 0) {
            int quadrante = _getQuadrante(i, j);

            // Calcola l'intersezione dei 3 set
            Set<int> intersezione = rigaSets[i]
                .intersection(colonnaSets[j])
                .intersection(quadrantiSets[quadrante]);

            if (intersezione.isEmpty) {
              // Situazione impossibile durante la prima fase - continua il backtracking
              break;
            }

            if (intersezione.length == 1) {
              // Trovata una cella con un solo valore possibile
              int numero = intersezione.first;

              // Inserisci il numero
              currentTavola[i][j] = numero;
              currentBooleanMatrix[i][j] = true;

              // Rimuovi dai set
              rigaSets[i].remove(numero);
              colonnaSets[j].remove(numero);
              quadrantiSets[quadrante].remove(numero);

              foundSingleValue = true;

              // Aggiorna la visualizzazione
              setState(() {});
              await Future.delayed(Duration(milliseconds: 200));

              break; // Ricomincia il ciclo dall'inizio
            }
          }
        }
        if (foundSingleValue) break;
      }
    }

    // Controlla se il Sudoku è completo E valido
    if (_isComplete()) {
      setState(() {
        isCompleted = true;
        isSolving = false;
      });
      return true;
    }

    // Seconda fase: usa backtracking per le celle rimanenti
    // Ordina le celle per cardinalità dell'intersezione (strategia euristica)
    List<CellInfo> cellsToFill = [];
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        if (!currentBooleanMatrix[i][j] && currentTavola[i][j] == 0) {
          int quadrante = _getQuadrante(i, j);
          Set<int> intersezione = rigaSets[i]
              .intersection(colonnaSets[j])
              .intersection(quadrantiSets[quadrante]);

          if (intersezione.isEmpty) {
            // Durante la raccolta delle celle - continua con le altre
            continue;
          }

          cellsToFill
              .add(CellInfo(i, j, intersezione.length, Set.from(intersezione)));
        }
      }
    }

    if (cellsToFill.isEmpty) {
      // Tutte le celle sono riempite - verifica se la soluzione è valida
      if (_isValidSolution()) {
        setState(() {
          isCompleted = true;
          isSolving = false;
        });
        return true;
      } else {
        // Tutte le celle riempite ma soluzione non valida
        setState(() {
          hasError = true;
          errorMessage =
              'Errore: Tutte le celle sono riempite ma la soluzione non rispetta le regole del Sudoku';
          isSolving = false;
        });
        return false;
      }
    }

    // Controlla se ci sono celle senza opzioni (situazione impossibile)
    if (cellsToFill.any((cell) => cell.cardinality == 0)) {
      setState(() {
        hasError = true;
        errorMessage =
            'Sudoku impossibile: Non esistono soluzioni valide per la configurazione inserita';
        isSolving = false;
      });
      return false;
    }

    // Ordina per cardinalità crescente (less constraining value heuristic)
    cellsToFill.sort((a, b) => a.cardinality.compareTo(b.cardinality));

    // Prendi la prima cella (con meno opzioni)
    CellInfo cellInfo = cellsToFill.first;
    int i = cellInfo.row;
    int j = cellInfo.col;
    int quadrante = _getQuadrante(i, j);

    // Ricalcola l'intersezione (potrebbe essere cambiata)
    Set<int> intersezione = rigaSets[i]
        .intersection(colonnaSets[j])
        .intersection(quadrantiSets[quadrante]);

    if (intersezione.isEmpty) {
      // Nessuna opzione per questa cella - backtrack
      return false;
    }

    // Prova ogni numero nell'intersezione
    for (int numero in intersezione.toList()) {
      // Salva lo stato corrente
      List<List<int>> backupTavola =
          currentTavola.map((row) => List<int>.from(row)).toList();
      List<List<bool>> backupBoolean =
          currentBooleanMatrix.map((row) => List<bool>.from(row)).toList();
      List<Set<int>> backupRighe =
          rigaSets.map((set) => Set<int>.from(set)).toList();
      List<Set<int>> backupColonne =
          colonnaSets.map((set) => Set<int>.from(set)).toList();
      List<Set<int>> backupQuadranti =
          quadrantiSets.map((set) => Set<int>.from(set)).toList();

      // Inserisci il numero
      currentTavola[i][j] = numero;
      rigaSets[i].remove(numero);
      colonnaSets[j].remove(numero);
      quadrantiSets[quadrante].remove(numero);

      // Aggiorna la visualizzazione
      setState(() {});
      await Future.delayed(Duration(milliseconds: 50));

      // Chiamata ricorsiva
      if (await _risolvi()) {
        return true; // Soluzione trovata
      }

      // Backtrack: ripristina lo stato precedente
      currentTavola = backupTavola;
      currentBooleanMatrix = backupBoolean;
      rigaSets = backupRighe;
      colonnaSets = backupColonne;
      quadrantiSets = backupQuadranti;

      // Aggiorna la visualizzazione del backtrack
      setState(() {});
      await Future.delayed(Duration(milliseconds: 25));
    }

    // Se arriviamo qui, nessun numero ha funzionato - potrebbe essere impossibile
    return false;
  }

  bool _isComplete() {
    // Prima controlla che non ci siano celle vuote
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        if (currentTavola[i][j] == 0) {
          return false;
        }
      }
    }

    // Poi verifica che la soluzione rispetti le regole del Sudoku
    return _isValidSolution();
  }

  bool _isValidSolution() {
    // Controlla che ogni riga contenga tutti i numeri da 1 a 9
    for (int i = 0; i < n; i++) {
      Set<int> numeriRiga = {};
      for (int j = 0; j < n; j++) {
        int num = currentTavola[i][j];
        if (num < 1 || num > 9 || numeriRiga.contains(num)) {
          return false; // Numero duplicato o non valido nella riga
        }
        numeriRiga.add(num);
      }
      if (numeriRiga.length != 9)
        return false; // Non tutti i numeri 1-9 presenti
    }

    // Controlla che ogni colonna contenga tutti i numeri da 1 a 9
    for (int j = 0; j < n; j++) {
      Set<int> numeriColonna = {};
      for (int i = 0; i < n; i++) {
        int num = currentTavola[i][j];
        if (num < 1 || num > 9 || numeriColonna.contains(num)) {
          return false; // Numero duplicato o non valido nella colonna
        }
        numeriColonna.add(num);
      }
      if (numeriColonna.length != 9)
        return false; // Non tutti i numeri 1-9 presenti
    }

    // Controlla che ogni quadrante contenga tutti i numeri da 1 a 9
    for (int quadrante = 0; quadrante < 9; quadrante++) {
      Set<int> numeriQuadrante = {};
      int startRow = (quadrante ~/ 3) * 3;
      int startCol = (quadrante % 3) * 3;

      for (int i = startRow; i < startRow + 3; i++) {
        for (int j = startCol; j < startCol + 3; j++) {
          int num = currentTavola[i][j];
          if (num < 1 || num > 9 || numeriQuadrante.contains(num)) {
            return false; // Numero duplicato o non valido nel quadrante
          }
          numeriQuadrante.add(num);
        }
      }
      if (numeriQuadrante.length != 9)
        return false; // Non tutti i numeri 1-9 presenti
    }

    return true; // Tutte le regole rispettate
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sudoku Solver - Risultati'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sudoku:',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isSolving)
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Risolvendo...'),
                        ],
                      ),
                    if (isCompleted)
                      Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text('Completato!',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    if (hasError)
                      Row(
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Errore!',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    Text('Iterazioni: $iterazioni',
                        style: TextStyle(fontSize: 12)),
                    if (isCompleted && _isValidSolution())
                      Text('✓ Soluzione valida',
                          style: TextStyle(fontSize: 12, color: Colors.green)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),

            // Sudoku grid
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
                            bool wasOriginal = widget.booleanMatrix[i][j];
                            bool isFilled = currentTavola[i][j] != 0;
                            int quadrante = _getQuadrante(i, j);

                            Color cellColor;
                            if (isFilled) {
                              if (wasOriginal) {
                                // Numeri originali: versione più scura del colore del quadrante
                                cellColor = Color.alphaBlend(
                                    Colors.blue.withOpacity(0.3),
                                    quadrantColors[quadrante]);
                              } else {
                                // Numeri risolti: versione più scura del colore del quadrante
                                cellColor = Color.alphaBlend(
                                    Colors.red.withOpacity(0.3),
                                    quadrantColors[quadrante]);
                              }
                            } else {
                              // Celle vuote: colore normale del quadrante
                              cellColor = quadrantColors[quadrante];
                            }

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
                                color: cellColor,
                              ),
                              child: Center(
                                child: Text(
                                  isFilled
                                      ? currentTavola[i][j].toString()
                                      : '',
                                  style: TextStyle(
                                    fontSize:
                                        (cellSize * 0.4).clamp(10.0, 18.0),
                                    fontWeight: FontWeight.bold,
                                    color: wasOriginal
                                        ? Colors.blue.shade800
                                        : Colors.red.shade800,
                                  ),
                                ),
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
            SizedBox(height: 20),

            // Messaggio di errore se presente
            if (hasError) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Problema rilevato:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(errorMessage,
                        style: TextStyle(color: Colors.red.shade700)),
                    SizedBox(height: 8),
                    Text(
                        'Controlla che non ci siano duplicati nelle righe, colonne o quadranti.',
                        style: TextStyle(
                            fontSize: 12, color: Colors.red.shade600)),
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],

            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: Text('Torna Indietro', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CellInfo {
  final int row;
  final int col;
  final int cardinality;
  final Set<int> possibleValues;

  CellInfo(this.row, this.col, this.cardinality, this.possibleValues);
}
