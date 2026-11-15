import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'app/router.dart';
import 'l10n/strings.dart';
import 'app/theme.dart';
import 'state/providers.dart';

void main() => runApp(const ProviderScope(child: SeerahApp()));

class SeerahApp extends ConsumerStatefulWidget {
  const SeerahApp({super.key});
  @override
  ConsumerState<SeerahApp> createState() => _SeerahAppState();
}

class _SeerahAppState extends ConsumerState<SeerahApp> {
  late final GoRouter _router = buildRouter(ref.read(appStateProvider));

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    return MaterialApp.router(
      title: 'Seerah Timeline',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: state.themeMode,
      routerConfig: _router,
      locale: Locale(state.lang),
      supportedLocales: Strings.supported.map((c) => Locale(c)).toList(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(state.textScale)),
        child: child!,
      ),
    );
  }
}
