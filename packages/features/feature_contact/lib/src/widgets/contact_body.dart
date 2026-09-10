import 'package:feature_contact/src/application/contact_links.dart';
import 'package:feature_contact/src/application/legacy_import_notice.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';
import 'package:na_ports/na_ports.dart';

final class ContactBody extends ConsumerWidget {
  const ContactBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(appInfoProvider);
    return NaScrollBody(
      children: [
        switch (info.approval) {
          BuildApproval.trial => const NotApprovedCard(),
          BuildApproval.approved => const SizedBox.shrink(),
        },
        const MeetingListCard(),
        const NaOnlineCard(),
        AboutAppCard(info: info),
        const FinePrintCard(),
      ],
    );
  }
}

final class NotApprovedCard extends StatelessWidget {
  const NotApprovedCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return NaCard(
      key: const Key('contact-not-approved'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NaCardTitle(text: l10n.contactNotApprovedTitle),
          Text(
            l10n.contactNotApprovedBody,
            style: NaTheme.of(context).typography.body,
          ),
        ],
      ),
    );
  }
}

final class MeetingListCard extends ConsumerWidget {
  const MeetingListCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final links = ref.watch(contactLinksProvider);
    return NaCard(
      key: const Key('contact-meeting-list'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NaCardTitle(text: l10n.contactMeetingListChangesTitle),
          LinkButton(
            key: LinkButton.keyFor(name: 'meeting-list-servant'),
            label: l10n.contactMeetingListServant,
            target: links.meetingListServant,
          ),
        ],
      ),
    );
  }
}

final class NaOnlineCard extends ConsumerWidget {
  const NaOnlineCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final links = ref.watch(contactLinksProvider);
    return NaCard(
      key: const Key('contact-na-online'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NaCardTitle(text: l10n.contactNaOnlineTitle),
          LinkButton(
            key: LinkButton.keyFor(name: 'website'),
            label: 'nadanmark.dk',
            target: links.website,
          ),
          LinkButton(
            key: LinkButton.keyFor(name: 'na-world'),
            label: 'na.org',
            target: links.naWorld,
          ),
        ],
      ),
    );
  }
}

final class AboutAppCard extends ConsumerWidget {
  const AboutAppCard({required this.info, super.key});

  final AppInfo info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final links = ref.watch(contactLinksProvider);
    final typography = NaTheme.of(context).typography;
    final notice = switch (ref.watch(legacyImportNoticeProvider)) {
      AsyncData(:final value) => value,
      AsyncLoading() || AsyncError() => ImportNotice.hidden,
    };
    return NaCard(
      key: const Key('contact-about-app'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NaCardTitle(text: l10n.contactAboutTitle),
          LinkButton(
            key: LinkButton.keyFor(name: 'source-code'),
            label: l10n.contactSourceCode,
            target: links.sourceCode,
          ),
          LinkButton(
            key: LinkButton.keyFor(name: 'bug-reports'),
            label: l10n.contactBugReports,
            target: links.bugReports,
          ),
          const SizedBox(height: Space.sm),
          Text(
            l10n.contactBuildType(info.buildType.value),
            key: const Key('contact-build-type'),
            style: typography.body,
          ),
          Text(
            l10n.contactVersion(info.version),
            key: const Key('contact-version'),
            style: typography.body,
          ),
          switch (notice) {
            ImportNotice.shown => Text(
              l10n.contactImportedSettings,
              key: const Key('contact-imported-settings'),
              style: typography.caption,
            ),
            ImportNotice.hidden => const SizedBox.shrink(),
          },
        ],
      ),
    );
  }
}

final class FinePrintCard extends StatelessWidget {
  const FinePrintCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return NaCard(
      key: const Key('contact-fine-print'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NaCardTitle(text: l10n.contactFinePrintTitle),
          Text(
            l10n.contactFinePrintBody,
            style: NaTheme.of(context).typography.body,
          ),
        ],
      ),
    );
  }
}

final class LinkButton extends ConsumerWidget {
  const LinkButton({required this.label, required this.target, super.key});

  static Key keyFor({required String name}) => Key('contact-link-$name');

  final String label;
  final Uri target;

  @override
  Widget build(BuildContext context, WidgetRef ref) => NaButton(
    label: label,
    onPressed: () => ref.read(externalLinksPortProvider).open(uri: target),
  );
}
