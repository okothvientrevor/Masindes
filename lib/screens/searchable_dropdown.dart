import 'package:flutter/material.dart';

class SearchableDropdown extends StatefulWidget {
  final String? value;
  final String hint;
  final List<Map<String, dynamic>> items;
  final Function(String?) onChanged;
  final String? Function(String?)? validator;

  const SearchableDropdown({
    super.key,
    this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  State<SearchableDropdown> createState() => _SearchableDropdownState();
}

class _SearchableDropdownState extends State<SearchableDropdown> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _filteredItems = [];
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    if (widget.value != null) {
      final selectedItem = widget.items.firstWhere(
        (item) => item['id'] == widget.value,
        orElse: () => {},
      );
      _controller.text = selectedItem['name'] ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      _filteredItems = widget.items
          .where(
            (item) => (item['name'] ?? '').toLowerCase().contains(
              query.toLowerCase(),
            ),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: widget.hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                ),
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
              ),
            ),
            onTap: () {
              setState(() {
                _isExpanded = true;
              });
            },
            onChanged: _filterItems,
            validator: widget.validator,
          ),
          if (_isExpanded)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  return ListTile(
                    title: Text(item['name'] ?? ''),
                    onTap: () {
                      setState(() {
                        _controller.text = item['name'] ?? '';
                        _isExpanded = false;
                      });
                      widget.onChanged(item['id']);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
