import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../data/app_database.dart';

class TareasPage extends StatefulWidget {
  const TareasPage({super.key});

  @override
  State<TareasPage> createState() => _TareasPageState();
}

class _TareasPageState extends State<TareasPage> {
  final AppDatabase db = AppDatabase();
  final TextEditingController _tituloController = TextEditingController();

  // 1. CREAR (Insert)
  Future<void> _agregarTarea() async {
    final titulo = _tituloController.text.trim();
    if (titulo.isEmpty || titulo.length > 100) return;

    await db.into(db.tareas).insert(
          TareasCompanion.insert(
            titulo: titulo,
            completada: const Value(false),
          ),
        );

    _tituloController.clear();
  }

  // 2. ACTUALIZAR ESTADO (Alternar completada)
  Future<void> _alternarCompletada(Tarea tarea, bool completada) async {
    await (db.update(db.tareas)..where((t) => t.id.equals(tarea.id))).write(
      TareasCompanion(
        completada: Value(completada),
      ),
    );
  }

  // 3. ACTUALIZAR TÍTULO (Editar)
  Future<void> _editarTarea(Tarea tarea) async {
    final editController = TextEditingController(text: tarea.titulo);

    final nuevoTitulo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar tarea'),
        content: TextField(
          controller: editController,
          autofocus: true,
          maxLength: 100,
          decoration: const InputDecoration(
            labelText: 'Título de la tarea',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(editController.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    editController.dispose();

    if (nuevoTitulo == null || nuevoTitulo.isEmpty || nuevoTitulo.length > 100) {
      return;
    }

    await (db.update(db.tareas)..where((t) => t.id.equals(tarea.id))).write(
      TareasCompanion(
        titulo: Value(nuevoTitulo),
      ),
    );
  }

  // 4. ELIMINAR (Delete)
  Future<void> _eliminarTarea(Tarea tarea) async {
    await (db.delete(db.tareas)..where((t) => t.id.equals(tarea.id))).go();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestor de tareas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _tituloController,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Nueva tarea',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _agregarTarea(),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _agregarTarea,
              icon: const Icon(Icons.add),
              label: const Text('Agregar tarea'),
            ),
            const SizedBox(height: 12),
            const Text('Mis tareas', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Expanded(
              // 5. LEER / ESCUCHAR EN TIEMPO REAL (StreamBuilder)
              child: StreamBuilder<List<Tarea>>(
                stream: db.select(db.tareas).watch(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error al cargar tareas: ${snapshot.error}'),
                    );
                  }

                  final tareas = snapshot.data ?? [];

                  if (tareas.isEmpty) {
                    return const Center(
                      child: Text('Todavía no hay tareas guardadas'),
                    );
                  }

                  return ListView.builder(
                    itemCount: tareas.length,
                    itemBuilder: (context, index) {
                      final tarea = tareas[index];
                      return Card(
                        child: ListTile(
                          leading: Checkbox(
                            value: tarea.completada,
                            onChanged: (valor) {
                              if (valor != null) {
                                _alternarCompletada(tarea, valor);
                              }
                            },
                          ),
                          title: Text(
                            tarea.titulo,
                            style: TextStyle(
                              decoration: tarea.completada
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          subtitle: Text('ID: ${tarea.id}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Editar',
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editarTarea(tarea),
                              ),
                              IconButton(
                                tooltip: 'Eliminar',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _eliminarTarea(tarea),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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