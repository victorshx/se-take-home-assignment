import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mcd_bot/order.provider.dart';

class Bot {
  final int id;
  final int? processingOrderId;
  final Timer? timer;
  Bot({
    required this.id,
    this.processingOrderId,
    this.timer,
  });

  Bot copyWith({
    int? id,
    int? processingOrderId,
    Timer? timer,
  }) {
    return Bot(
      id: id ?? this.id,
      processingOrderId: processingOrderId,
      timer: timer,
    );
  }
}

typedef Bots = List<Bot>;

class BotController extends StateNotifier<Bots> {
  final Reader _read;
  BotController(this._read) : super([]);

  OrderController get orderController => _read(orderProvider.notifier);

  Bots get availableBots =>
      state.where((state) => state.processingOrderId == null).toList();

  Bots get busyBots =>
      state.where((state) => state.processingOrderId != null).toList();

  void addBot() {
    final botId = state.isEmpty ? 1 : state.last.id + 1;
    state = [...state, Bot(id: botId)];
    processOrder();
  }

  void removeBot() {
    if (state.isNotEmpty) {
      Bot botToRemove = state.last;
      if (botToRemove.processingOrderId != null) {
        botToRemove.timer!.cancel();
      }
      state = state.where((bot) => bot.id != botToRemove.id).toList();
      processOrder();
    }
  }

  bool isOrderBeingProcessed(int orderId) {
    return state.any((bot) => bot.processingOrderId == orderId);
  }

  void removeBotProcessingOrder(int orderId) {
    Bot botToUpdate =
        state.firstWhere((bot) => bot.processingOrderId == orderId);
    state = state
        .map((bot) => bot.processingOrderId == orderId
            ? botToUpdate.copyWith(
                processingOrderId: null,
                timer: null,
              )
            : bot)
        .toList();
  }

  void processOrder() {
    final availableOrders = orderController.availableOrders;
    if (availableOrders.isEmpty) {
      return;
    }

    final orderToProcess = availableOrders
        .firstWhereOrNull((order) => !isOrderBeingProcessed(order.id));
    if (orderToProcess == null) {
      return;
    }

    final botToProcess =
        availableBots.firstWhereOrNull((bot) => bot.processingOrderId == null);
    if (botToProcess == null) {
      return;
    }
    state = [
      ...state.where((bot) => bot.id != botToProcess.id),
      botToProcess.copyWith(
        processingOrderId: orderToProcess.id,
        timer: Timer(const Duration(seconds: 10), () {
          orderController.completeOrder(orderToProcess.id);
          processOrder();
        }),
      ),
    ];
  }
}

// state[i].orderId = 2
// state = [...state]

final botProvider = StateNotifierProvider<BotController, Bots>(
    (ref) => BotController(ref.read));
