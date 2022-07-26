import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mcd_bot/bot.provider.dart';
import 'package:mcd_bot/order.provider.dart';
import 'package:collection/collection.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: const [
          Expanded(child: BotPanel()),
          VerticalDivider(),
          Expanded(child: PendingOrderPanel()),
          VerticalDivider(),
          Expanded(child: CompletedOrderPanel()),
        ],
      ),
    );
  }
}

class BotPanel extends ConsumerWidget {
  const BotPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contoller = ref.read(botProvider.notifier);
    final bots = ref.watch(botProvider);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: contoller.addBot,
              child: const Text('Add Bot', style: TextStyle(fontSize: 20)),
            ),
            TextButton(
              onPressed: contoller.removeBot,
              child: const Text('Remove Bot', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          child: Column(
            children: bots
                .map((bot) => Card(
                      child: Column(
                        children: [
                          Text('Bot ${bot.id}'),
                          if (bot.processingOrderId != null)
                            Text('Processing Order: ${bot.processingOrderId}'),
                        ],
                      ),
                    ))
                .toList(),
          ),
        )
      ],
    );
  }
}

class PendingOrderPanel extends ConsumerWidget {
  const PendingOrderPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(orderProvider.notifier);
    final pendingOrders =
        ref.watch(orderProvider).where((order) => order.pending).toList();
    ref.watch(botProvider);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => controller.newOrder(isVip: false),
              child: const Text('New Normal Order',
                  style: TextStyle(fontSize: 20)),
            ),
            TextButton(
              onPressed: () => controller.newOrder(isVip: true),
              child:
                  const Text('New VIP Order', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          child: Column(
            children: pendingOrders.map((order) {
              String getLabel() {
                String getBotLabel() {
                  final bot = ref.read(botProvider).firstWhereOrNull(
                      (bot) => bot.processingOrderId == order.id);
                  if (bot == null) {
                    return ' (No Bot)';
                  } else {
                    return '(Processed by Bot ${bot.id})';
                  }
                }

                if (order.vip) {
                  return 'VIP Order ${order.id} ${getBotLabel()}';
                }
                return 'Normal Order ${order.id} ${getBotLabel()}';
              }

              return Card(
                child: Column(
                  children: [
                    Text(getLabel()),
                  ],
                ),
              );
            }).toList(),
          ),
        )
      ],
    );
  }
}

class CompletedOrderPanel extends ConsumerWidget {
  const CompletedOrderPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedOrders =
        ref.watch(orderProvider).where((order) => !order.pending).toList();
    return Column(
      children: [
        const Text(
          'Completed Orders',
          style: TextStyle(
            color: Colors.blue,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        ...completedOrders
            .map((order) => Card(
                  child: Text('Order: ${order.id}'),
                ))
            .toList()
      ],
    );
  }
}
