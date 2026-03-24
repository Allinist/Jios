import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../database/dao/taskBookDao.dart';
import '../../database/dao/taskDao.dart';
import '../../models/task.dart';
import '../../models/taskBook.dart';
import '../../services/appThemeService.dart';
import '../../services/dataTransferService.dart';
import '../../services/widgetServices.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _busy = false;
  String _systemTheme = AppThemeService.themeBlue;
  String _widgetAppearanceTheme = WidgetService.widgetThemeAuto;
  String _widgetLogoVariant = WidgetService.widgetLogoPink;
  String _appLogoVariant = WidgetService.widgetLogoPink;

  String _configuredWidgetMode = 'today';
  int? _configuredWidgetTaskBookId;
  List<int> _configuredWidgetTaskIds = [];
  int? _bookWidgetTaskBookId;
  List<int> _selectedWidgetTaskIds = [];
  List<int> _lockSelectedWidgetTaskIds = [];

  List<TaskBook> _books = [];
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadWidgetConfigData();
  }

  Future<void> _loadWidgetConfigData() async {
    final books = await TaskBookDao().getAll();
    final tasks = await TaskDao().getAll();
    final configured = await WidgetService.loadWidgetConfig(
      scope: WidgetService.scopeConfigured,
    );
    final book = await WidgetService.loadWidgetConfig(
      scope: WidgetService.scopeBook,
    );
    final selected = await WidgetService.loadWidgetConfig(
      scope: WidgetService.scopeSelected,
    );
    final lockSelected = await WidgetService.loadWidgetConfig(
      scope: WidgetService.scopeLockSelected,
    );
    final appearanceTheme = await WidgetService.loadWidgetAppearanceTheme();
    final logoVariant = await WidgetService.loadWidgetLogoVariant();
    final appLogoVariant = await WidgetService.loadAppLogoVariant();
    final systemTheme = await AppThemeService.loadTheme();

    if (!mounted) return;

    setState(() {
      _books = books;
      _tasks = tasks;
      _configuredWidgetMode = configured['mode'] as String? ?? 'today';
      _configuredWidgetTaskBookId = configured['task_book_id'] as int?;
      _configuredWidgetTaskIds =
          (configured['task_ids'] as List? ?? []).whereType<int>().toList();
      _bookWidgetTaskBookId = book['task_book_id'] as int?;
      _selectedWidgetTaskIds =
          (selected['task_ids'] as List? ?? []).whereType<int>().toList();
      _lockSelectedWidgetTaskIds =
          (lockSelected['task_ids'] as List? ?? []).whereType<int>().toList();
      _systemTheme = systemTheme;
      _widgetAppearanceTheme = appearanceTheme;
      _widgetLogoVariant = logoVariant;
      _appLogoVariant = appLogoVariant;
    });
  }

  Future<void> _saveConfiguredWidgetConfig() async {
    await WidgetService.saveWidgetConfig(
      scope: WidgetService.scopeConfigured,
      mode: _configuredWidgetMode,
      taskBookId: _configuredWidgetTaskBookId,
      taskIds: _configuredWidgetTaskIds,
    );
    await WidgetService.syncWidgetData();
    await WidgetService.refreshWidget();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configured widget saved.')),
    );
  }

  Future<void> _saveBookWidgetConfig() async {
    await WidgetService.saveWidgetConfig(
      scope: WidgetService.scopeBook,
      mode: 'book',
      taskBookId: _bookWidgetTaskBookId,
      taskIds: const [],
    );
    await WidgetService.syncWidgetData();
    await WidgetService.refreshWidget();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task book widget saved.')),
    );
  }

  Future<void> _saveSelectedWidgetConfig() async {
    await WidgetService.saveWidgetConfig(
      scope: WidgetService.scopeSelected,
      mode: 'selected',
      taskBookId: null,
      taskIds: _selectedWidgetTaskIds,
    );
    await WidgetService.syncWidgetData();
    await WidgetService.refreshWidget();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selected widget saved.')),
    );
  }

  Future<void> _saveLockSelectedWidgetConfig() async {
    await WidgetService.saveWidgetConfig(
      scope: WidgetService.scopeLockSelected,
      mode: 'selected',
      taskBookId: null,
      taskIds: _lockSelectedWidgetTaskIds,
    );
    await WidgetService.syncWidgetData();
    await WidgetService.refreshWidget();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lock screen widget saved.')),
    );
  }

  Future<void> _saveWidgetAppearanceTheme() async {
    await WidgetService.saveWidgetAppearanceTheme(_widgetAppearanceTheme);
    await WidgetService.saveWidgetLogoVariant(_widgetLogoVariant);
    await WidgetService.saveAppLogoVariant(_appLogoVariant);
    await WidgetService.refreshWidget();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enhanced widget appearance saved.')),
    );
  }

  Future<void> _saveSystemTheme() async {
    await AppThemeService.saveTheme(_systemTheme);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('System theme saved.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _buildConfiguredWidgetTile(),
          _buildBookWidgetTile(),
          _buildSelectedWidgetTile(),
          _buildLockSelectedWidgetTile(),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Export all data (JSON)'),
            subtitle: const Text(
              'Export task_books / tasks / repeat_rules / task_records',
            ),
            onTap: _busy ? null : _exportJson,
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Import all data (JSON)'),
            subtitle: const Text('Import will overwrite all current data'),
            onTap: _busy ? null : _importJson,
          ),
          _buildSystemThemeTile(),
          _buildWidgetAppearanceTile(),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildConfiguredWidgetTile() {
    return ExpansionTile(
      key: const PageStorageKey<String>('settings_tile_configured_widget'),
      title: const Text('Configured widget'),
      subtitle: const Text('For the configured schedule widget'),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        DropdownButtonFormField<String>(
          initialValue: _configuredWidgetMode,
          decoration: const InputDecoration(
            labelText: 'Display mode',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'today', child: Text('Today')),
            DropdownMenuItem(value: 'book', child: Text('Task book')),
            DropdownMenuItem(value: 'selected', child: Text('Selected tasks')),
          ],
          onChanged: (value) {
            setState(() {
              _configuredWidgetMode = value ?? 'today';
            });
          },
        ),
        const SizedBox(height: 12),
        if (_configuredWidgetMode == 'book')
          DropdownButtonFormField<int?>(
            initialValue: _configuredWidgetTaskBookId,
            decoration: const InputDecoration(
              labelText: 'Task book',
              border: OutlineInputBorder(),
            ),
            items: _books
                .map(
                  (book) => DropdownMenuItem<int?>(
                    value: book.id,
                    child: Text(book.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _configuredWidgetTaskBookId = value;
              });
            },
          ),
        if (_configuredWidgetMode == 'selected')
          OutlinedButton.icon(
            onPressed: () => _pickWidgetTasks(configured: true),
            icon: const Icon(Icons.checklist),
            label: Text(
              '${_configuredWidgetTaskIds.length} selected, tap to edit',
            ),
          ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _saveConfiguredWidgetConfig,
          icon: const Icon(Icons.save),
          label: const Text('Save configured widget'),
        ),
      ],
    );
  }

  Widget _buildBookWidgetTile() {
    return ExpansionTile(
      key: const PageStorageKey<String>('settings_tile_book_widget'),
      title: const Text('Task book widget'),
      subtitle: const Text('For the task book schedule widget'),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        DropdownButtonFormField<int?>(
          initialValue: _bookWidgetTaskBookId,
          decoration: const InputDecoration(
            labelText: 'Task book',
            border: OutlineInputBorder(),
          ),
          items: _books
              .map(
                (book) => DropdownMenuItem<int?>(
                  value: book.id,
                  child: Text(book.name),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _bookWidgetTaskBookId = value;
            });
          },
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _saveBookWidgetConfig,
          icon: const Icon(Icons.save),
          label: const Text('Save task book widget'),
        ),
      ],
    );
  }

  Widget _buildSelectedWidgetTile() {
    return ExpansionTile(
      key: const PageStorageKey<String>('settings_tile_selected_widget'),
      title: const Text('Selected widget'),
      subtitle: const Text('For the selected schedule widget'),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        OutlinedButton.icon(
          onPressed: () => _pickWidgetTasks(configured: false),
          icon: const Icon(Icons.checklist),
          label: Text('${_selectedWidgetTaskIds.length} selected, tap to edit'),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _saveSelectedWidgetConfig,
          icon: const Icon(Icons.save),
          label: const Text('Save selected widget'),
        ),
      ],
    );
  }

  Widget _buildLockSelectedWidgetTile() {
    return ExpansionTile(
      key: const PageStorageKey<String>('settings_tile_lock_selected_widget'),
      title: const Text('Lock screen selected widget'),
      subtitle: const Text('For the lock screen selected widget'),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        OutlinedButton.icon(
          onPressed: () =>
              _pickWidgetTasks(configured: false, lockSelected: true),
          icon: const Icon(Icons.checklist),
          label: Text(
            '${_lockSelectedWidgetTaskIds.length} selected, tap to edit',
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _saveLockSelectedWidgetConfig,
          icon: const Icon(Icons.save),
          label: const Text('Save lock screen widget'),
        ),
      ],
    );
  }

  Widget _buildSystemThemeTile() {
    return ExpansionTile(
      key: const PageStorageKey<String>('settings_tile_system_theme'),
      title: const Text('System theme'),
      subtitle: const Text('Theme color for the app'),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        DropdownButtonFormField<String>(
          initialValue: _systemTheme,
          decoration: const InputDecoration(
            labelText: 'Theme palette',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(
              value: AppThemeService.themeBlue,
              child: Text('Blue'),
            ),
            DropdownMenuItem(
              value: AppThemeService.themePink,
              child: Text('Pink'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _systemTheme = value ?? AppThemeService.themeBlue;
            });
          },
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _saveSystemTheme,
          icon: const Icon(Icons.color_lens_outlined),
          label: const Text('Save system theme'),
        ),
      ],
    );
  }

  Widget _buildWidgetAppearanceTile() {
    return ExpansionTile(
      key: const PageStorageKey<String>('settings_tile_widget_appearance'),
      initiallyExpanded: true,
      title: const Text('Enhanced widget appearance'),
      subtitle: const Text('Theme and logo for enhanced widgets'),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        DropdownButtonFormField<String>(
          initialValue: _widgetAppearanceTheme,
          decoration: const InputDecoration(
            labelText: 'Background theme',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(
              value: WidgetService.widgetThemeAuto,
              child: Text('Auto'),
            ),
            DropdownMenuItem(
              value: WidgetService.widgetThemeMistLight,
              child: Text('Mist light'),
            ),
            DropdownMenuItem(
              value: WidgetService.widgetThemeSlateBlue,
              child: Text('Slate blue'),
            ),
            DropdownMenuItem(
              value: WidgetService.widgetThemeWarmSand,
              child: Text('Warm sand'),
            ),
            DropdownMenuItem(
              value: WidgetService.widgetThemeRoseBlush,
              child: Text('Pink'),
            ),
            DropdownMenuItem(
              value: WidgetService.widgetThemeNightGraphite,
              child: Text('Night graphite'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _widgetAppearanceTheme = value ?? WidgetService.widgetThemeAuto;
            });
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _appLogoVariant,
          decoration: const InputDecoration(
            labelText: 'App logo',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(
              value: WidgetService.widgetLogoPink,
              child: Text('PinkLogo'),
            ),
            DropdownMenuItem(
              value: WidgetService.widgetLogoBlue,
              child: Text('BlueLogo'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _appLogoVariant = value ?? WidgetService.widgetLogoPink;
            });
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _widgetLogoVariant,
          decoration: const InputDecoration(
            labelText: 'Widget logo',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(
              value: WidgetService.widgetLogoPink,
              child: Text('PinkLogo'),
            ),
            DropdownMenuItem(
              value: WidgetService.widgetLogoBlue,
              child: Text('BlueLogo'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _widgetLogoVariant = value ?? WidgetService.widgetLogoPink;
            });
          },
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _saveWidgetAppearanceTheme,
          icon: const Icon(Icons.palette_outlined),
          label: const Text('Save enhanced widget appearance'),
        ),
      ],
    );
  }

  Future<void> _pickWidgetTasks({
    required bool configured,
    bool lockSelected = false,
  }) async {
    final selected = lockSelected
        ? {..._lockSelectedWidgetTaskIds}
        : configured
            ? {..._configuredWidgetTaskIds}
            : {..._selectedWidgetTaskIds};

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Select tasks'),
          content: SizedBox(
            width: 520,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final task in _tasks)
                  CheckboxListTile(
                    value: selected.contains(task.id),
                    title: Text(task.title),
                    onChanged: (value) {
                      if (task.id == null) return;
                      setDialogState(() {
                        if (value == true) {
                          selected.add(task.id!);
                        } else {
                          selected.remove(task.id!);
                        }
                      });
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;

    setState(() {
      if (lockSelected) {
        _lockSelectedWidgetTaskIds = selected.toList();
      } else if (configured) {
        _configuredWidgetTaskIds = selected.toList();
      } else {
        _selectedWidgetTaskIds = selected.toList();
      }
    });
  }

  Future<void> _exportJson() async {
    setState(() {
      _busy = true;
    });

    try {
      final jsonText = await DataTransferService.exportAllAsJson();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Export JSON'),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: SelectableText(jsonText),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: jsonText));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard.')),
                  );
                },
                child: const Text('Copy'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _importJson() async {
    final controller = TextEditingController();

    final shouldImport = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Import JSON'),
          content: SizedBox(
            width: 560,
            child: TextField(
              controller: controller,
              minLines: 12,
              maxLines: 20,
              decoration: const InputDecoration(
                hintText: 'Paste exported JSON here',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Import'),
            ),
          ],
        );
      },
    );

    if (shouldImport != true) {
      return;
    }

    final jsonText = controller.text.trim();

    if (jsonText.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter JSON content.')),
      );
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      await DataTransferService.importAllFromJson(jsonText);
      await _loadWidgetConfigData();
      await WidgetService.syncWidgetData();
      await WidgetService.refreshWidget();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Import completed and widget data refreshed.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }
}
