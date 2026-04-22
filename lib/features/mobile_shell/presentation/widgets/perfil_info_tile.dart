import 'package:flutter/material.dart';

class PerfilInfoTile extends StatelessWidget {
  const PerfilInfoTile({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            Expanded(child: Text(label)),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}