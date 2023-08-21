import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/notifications/notification_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/reminder.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension _ReminderReady on ReminderPB {
  DateTime get scheduledDate =>
      DateTime.fromMillisecondsSinceEpoch(scheduledAt.toInt() * 1000);

  bool isBefore(DateTime date) => scheduledDate.isBefore(date);
}

class NotificationDialog extends StatelessWidget {
  const NotificationDialog({
    super.key,
    required this.views,
    required this.mutex,
  });

  final List<ViewPB> views;
  final PopoverMutex mutex;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReminderBloc>.value(
      value: getIt<ReminderBloc>(),
      child: BlocBuilder<ReminderBloc, ReminderState>(
        builder: (context, state) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 10,
                        ),
                        child: FlowyText.semibold(
                          LocaleKeys.notificationHub_title.tr(),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const VSpace(4),
              if (state.reminders.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: FlowyText.regular(
                      LocaleKeys.notificationHub_empty.tr(),
                    ),
                  ),
                )
              else
                ...state.reminders
                    .where((reminder) => reminder.isBefore(DateTime.now()))
                    .sorted((a, b) => b.scheduledAt.compareTo(a.scheduledAt))
                    .map((reminder) {
                  return NotificationItem(
                    key: ValueKey(reminder.id),
                    title: reminder.title,
                    scheduled: reminder.scheduledAt,
                    body: reminder.message,
                    onDelete: () => context
                        .read<ReminderBloc>()
                        .add(ReminderEvent.remove(reminderId: reminder.id)),
                    onAction: () {
                      final view = views.firstWhereOrNull(
                        (view) => view.id == reminder.reminderObjectId,
                      );

                      if (view == null) {
                        return;
                      }

                      getIt<TabsBloc>().add(
                        TabsEvent.openPlugin(plugin: view.plugin(), view: view),
                      );

                      mutex.close();
                    },
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
