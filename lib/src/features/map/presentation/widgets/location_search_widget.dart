import 'package:flutter/material.dart';
import 'dart:async';

class LocationSearchWidget extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final Function(String)? onSubmit;
  final String hintText;

  const LocationSearchWidget({
    super.key,
    required this.controller,
    required this.onSearch,
    this.onSubmit,
    this.hintText = 'Buscar direcciÃ³n...',
  });

  @override
  State<LocationSearchWidget> createState() => _LocationSearchWidgetState();
}

class _LocationSearchWidgetState extends State<LocationSearchWidget> {
  final _debounceDuration = const Duration(milliseconds: 500);
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_debounceTimer != null) {
      _debounceTimer!.cancel();
    }

    _debounceTimer = Timer(_debounceDuration, () {
      if (widget.controller.text.length >= 3) {
        widget.onSearch(widget.controller.text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      onSubmitted: widget.onSubmit,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.search, color: Color(0xFFFFFF00)),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.white54),
                onPressed: () {
                  widget.controller.clear();
                  widget.onSearch('');
                },
              ),
            IconButton(
              icon: const Icon(Icons.search, color: Color(0xFFFFFF00)),
              onPressed: () {
                final q = widget.controller.text.trim();
                if (q.isNotEmpty) {
                  if (widget.onSubmit != null) {
                    widget.onSubmit!(q);
                  } else {
                    widget.onSearch(q);
                  }
                }
              },
            ),
          ],
        ),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFFF00)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }
}
