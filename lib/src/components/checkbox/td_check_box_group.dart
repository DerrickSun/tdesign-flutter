import 'package:flutter/cupertino.dart';

import '../../util/map_ext.dart';
import 'td_check_box.dart';

///
/// CheckBoxGroup变化监听器
///
typedef OnGroupChange = void Function(List<String> checkedIds);

///
/// 控制CheckBoxGroup
///
class TDCheckboxGroupController {
  TDCheckboxGroupState? _state;

  ///
  /// 选择全部
  /// 这个方法会忽略最大可够选数
  ///
  void toggleAll(bool check) {
    _state?.toggleAll(check);
  }

  ///
  /// 反选
  ///
  void reverseAll() {
    _state?._reverseAll();
  }

  ///
  /// 选中某一个选项
  ///
  void toggle(String id, bool check) {
    _state?.toggle(id, check, true);
  }

  ///
  /// 打勾的选项
  ///
  List<String> allChecked() {
    return _state?.checkBoxStates.where((k, v) => v).keys.toList() ?? [];
  }

  ///
  /// 某一项的选中状态
  ///
  bool checked(String id) {
    var list = allChecked();
    return list.contains(id);
  }
}

///
/// CheckBox组，可以通过控制器控制组内的多个CheckBox的选择状态
///
/// child的属性可以是任意包含TDCheckBox的容器组件，例如：
/// ```dart
/// TDCheckboxGroup(
///   child: Row(
///     children: [
///       TDCheckBox(),
///       Column(
///         children: [
///           TDCheckBox()
///           ...
///         ]
///       )
///       ...
///     ]
///   )
/// )
/// ```
///
///
class TDCheckboxGroup extends StatefulWidget {
  ///
  /// 可以是任意包含TDCheckBox的容器，比如：
  /// ```
  /// Row(
  ///   children: [
  ///     TDCheckBox(),
  ///     TDCheckBox(),
  ///     ...
  ///   ]
  /// )
  /// ```
  ///
  final Widget child;

  ///
  /// 状态变化监听器
  ///
  final OnGroupChange? onChangeGroup;

  ///
  /// 可以通过控制器操作勾选状态
  ///
  final TDCheckboxGroupController? controller;

  ///
  /// 最多可以勾选多少
  ///
  final int? maxChecked;

  ///
  /// 勾选的CheckBox id列表
  ///
  final List<String>? checkedIds;

  ///
  /// 超过最大可勾选的个数
  ///
  final VoidCallback? onOverloadChecked;

  /// CheckBox标题的行数
  final int? titleMaxLine;


  /// CheckBox完全自定义内容
  final ContentBuilder? customContentBuilder;

  /// CheckBoxicon和文字的距离
  final double? spacing;

  /// CheckBox复选框样式：圆形或方形
  final TDCheckboxStyle? style;

  ///
  /// 文字相对icon的方位
  ///
  final TDContentDirection? contentDirection;

  /// 自定义选择icon的样式
  final IconBuilder? customIconBuilder;

  const TDCheckboxGroup(
      {required this.child,
        Key? key,
      this.onChangeGroup,
      this.controller,
      this.checkedIds,
      this.maxChecked,
      this.titleMaxLine,
      this.customContentBuilder,
        this.contentDirection,
      this.style,
      this.spacing,
      this.customIconBuilder,
      this.onOverloadChecked}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return TDCheckboxGroupState();
  }
}


class TDCheckboxGroupState extends State<TDCheckboxGroup> {
  ///
  /// 管理所有子CheckBox的状态
  ///
  Map<String, bool> checkBoxStates = {};

  @override
  void initState() {
    super.initState();
    // 如果有controller的话，把state设置给controller
    widget.controller?._state = this;

    _syncCheckState(widget.checkedIds);
  }

  /// 把group中配置的默认选中id，同步到状态中
  void _syncCheckState(List<String>? checkIds) {
    checkBoxStates.clear();
    checkIds?.forEach((element) {
      checkBoxStates[element] = true;
    });
  }


  @override
  void didUpdateWidget(TDCheckboxGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldCheckIds = oldWidget.checkedIds;
    final newCheckIds = widget.checkedIds;
    if (oldCheckIds != newCheckIds) {
      _syncCheckState(newCheckIds);
    }
  }


  ///
  /// 根据id获取CheckBox的勾选状态
  ///
  ///
  bool getCheckBoxStateById(String id, bool checked) {
    if (checkBoxStates[id] == null) {
      // checkBox本身的状态
      checkBoxStates[id] = checked;
    }
    return checkBoxStates[id]!;
  }

  /// 勾选单个CheckBox
  bool toggle(String id, bool check, [bool notify = false]) {
    // 检查是否超过用户设置的最大可勾选数
    if (widget.maxChecked != null && check) {
      if (checkBoxStates.count((k, v) => v) >= widget.maxChecked!) {
        widget.onOverloadChecked?.call();
        return false;
      }
    }
    checkBoxStates[id] = check;
    if (notify) {
      setState(() {});
    }
    _notifyChange();
    return true;
  }

  /// 操作所有CheckBox
  void toggleAll(bool check, [bool notify = true]) {
    var isChanged = false;
    checkBoxStates.forEachCanBreak((k, v) {
      if (check) {
        if (!toggle(k, check)) {
          // 勾选失败，退出循环
          return true;
        }
      } else {
        toggle(k, check);
      }
      isChanged = true;
      return false;
    });

    if (isChanged && notify) {
      setState(() {});
      _notifyChange();
    }
  }

  /// 反选
  void _reverseAll() {
    final reverseValue =
        checkBoxStates.map((key, value) => MapEntry(key, !value));
    checkBoxStates.forEach((key, value) {
      checkBoxStates[key] = false;
    });
    checkBoxStates.forEach((k, v) {
      var check = reverseValue[k] ?? false;
      toggle(k, check);
    });
    setState(() {});
    _notifyChange();
  }

  void _notifyChange() {
    final change = widget.onChangeGroup;
    if (change != null) {
      final checkedIds = checkBoxStates.where((k, v) => v).keys.toList();
      change.call(checkedIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TDCheckboxGroupInherited(this, widget.child);
  }
}

class TDCheckboxGroupInherited extends InheritedWidget {
  final TDCheckboxGroupState state;

  ///
  /// 获取树上的Group节点
  ///
  static TDCheckboxGroupInherited? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TDCheckboxGroupInherited>();
  }

  const TDCheckboxGroupInherited(this.state, Widget child, {Key? key}) : super(child: child, key: key);

  @override
  bool updateShouldNotify(covariant TDCheckboxGroupInherited oldWidget) {
    return true;
  }
}
