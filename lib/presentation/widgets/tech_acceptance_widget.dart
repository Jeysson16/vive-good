import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TechAcceptanceWidget extends StatefulWidget {
  final VoidCallback? onCompleted;
  final bool showInProfile;
  
  const TechAcceptanceWidget({
    Key? key,
    this.onCompleted,
    this.showInProfile = false,
  }) : super(key: key);

  @override
  State<TechAcceptanceWidget> createState() => _TechAcceptanceWidgetState();
}

class _TechAcceptanceWidgetState extends State<TechAcceptanceWidget> {
  bool _hasCompleted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkIfCompleted();
  }

  Future<void> _checkIfCompleted() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await Supabase.instance.client
          .from('app_ratings')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      setState(() {
        _hasCompleted = response != null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showTechAcceptanceDialog() {
    showDialog(
      context: context,
      builder: (context) => _TechAcceptanceDialog(
        onSaved: () {
          setState(() {
            _hasCompleted = true;
          });
          widget.onCompleted?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    // Only hide if completed AND not showing in profile
    if (_hasCompleted && !widget.showInProfile) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: _showTechAcceptanceDialog,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.star_fill,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.showInProfile && _hasCompleted 
                          ? 'Aceptación tecnológica'
                          : 'Evaluar aceptación tecnológica',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.showInProfile && _hasCompleted
                          ? 'Toca para editar tu evaluación'
                          : 'Califica tu experiencia con la aplicación',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_right,
                color: Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TechAcceptanceDialog extends StatefulWidget {
  final VoidCallback onSaved;

  const _TechAcceptanceDialog({
    required this.onSaved,
  });

  @override
  State<_TechAcceptanceDialog> createState() => _TechAcceptanceDialogState();
}

class _TechAcceptanceDialogState extends State<_TechAcceptanceDialog> {
  int _selectedRating = 0;
  bool _acceptsTechTools = false;
  bool _isLoading = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('app_ratings')
          .select('rating, accepts_tech_tools, comment')
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _selectedRating = response['rating'] ?? 0;
          _acceptsTechTools = response['accepts_tech_tools'] ?? false;
          _commentController.text = response['comment'] ?? '';
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _saveRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona al menos una estrella'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      await Supabase.instance.client.from('app_ratings').upsert({
        'user_id': user.id,
        'rating': _selectedRating,
        'accepts_tech_tools': _acceptsTechTools,
        'comment': _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Calificación guardada exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        'Aceptación Tecnológica',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Evalúa tu nivel de aceptación de la aplicación',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Calificación:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRating = starIndex;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      CupertinoIcons.star_fill,
                      size: 32,
                      color: starIndex <= _selectedRating
                          ? Colors.amber
                          : Colors.grey.shade300,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Switch(
                  value: _acceptsTechTools,
                  onChanged: (value) {
                    setState(() {
                      _acceptsTechTools = value;
                    });
                  },
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '¿Acepta el uso de herramientas tecnológicas?',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Comentarios (opcional):',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Comparte tu experiencia o sugerencias...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _saveRating,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(CupertinoIcons.checkmark),
          label: const Text('Guardar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}