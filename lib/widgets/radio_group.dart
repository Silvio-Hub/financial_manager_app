import 'package:flutter/material.dart';

/// Widget personalizado para agrupar Radio buttons e evitar warnings de deprecação
class CustomRadioGroup<T> extends StatelessWidget {
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final Widget child;

  const CustomRadioGroup({
    super.key,
    required this.groupValue,
    required this.onChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _RadioGroupScope<T>(
      groupValue: groupValue,
      onChanged: onChanged,
      child: child,
    );
  }

  /// Método estático para obter os valores do CustomRadioGroup mais próximo na árvore de widgets
  static (T?, ValueChanged<T?>?) of<T>(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_RadioGroupScope<T>>();
    return (scope?.groupValue, scope?.onChanged);
  }
}

/// InheritedWidget para propagar os valores do CustomRadioGroup
class _RadioGroupScope<T> extends InheritedWidget {
  final T? groupValue;
  final ValueChanged<T?>? onChanged;

  const _RadioGroupScope({
    required this.groupValue,
    required this.onChanged,
    required super.child,
  });

  @override
  bool updateShouldNotify(_RadioGroupScope<T> oldWidget) {
    return groupValue != oldWidget.groupValue ||
           onChanged != oldWidget.onChanged;
  }
}

/// Radio button personalizado que funciona com CustomRadioGroup
class RadioButton<T> extends StatelessWidget {
  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;

  const RadioButton({
    super.key,
    required this.value,
    this.groupValue,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final (scopeGroupValue, scopeOnChanged) = CustomRadioGroup.of<T>(context);
    final effectiveGroupValue = groupValue ?? scopeGroupValue;
    final effectiveOnChanged = onChanged ?? scopeOnChanged;

    return GestureDetector(
      onTap: () => effectiveOnChanged?.call(value),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: effectiveGroupValue == value
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: 2,
          ),
        ),
        child: effectiveGroupValue == value
            ? Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}