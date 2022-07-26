import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mcd_bot/bot.provider.dart';

class Order {
  final int id;
  final bool vip;
  final bool pending;
  Order({
    required this.id,
    required this.vip,
    required this.pending,
  });

  Order copyWith({
    int? id,
    bool? vip,
    bool? pending,
  }) {
    return Order(
      id: id ?? this.id,
      vip: vip ?? this.vip,
      pending: pending ?? this.pending,
    );
  }
}

typedef Orders = List<Order>;

class OrderController extends StateNotifier<Orders> {
  final Reader _read;
  OrderController(this._read) : super([]);

  BotController get botController => _read(botProvider.notifier);

  Orders get availableOrders => state.where((state) => state.pending).toList();

  void newOrder({required bool isVip}) {
    final orderId = state.length + 1;
    if (!isVip) {
      state = [...state, Order(id: orderId, vip: isVip, pending: true)];
    } else {
      final lastVipOrderIndex = state.lastIndexWhere((order) => order.vip);
      final hasVipOrders = lastVipOrderIndex != -1;
      if (hasVipOrders) {
        state = [
          ...state
            ..insert(
              lastVipOrderIndex + 1,
              Order(id: orderId, vip: true, pending: true),
            )
        ];
      } else {
        state = [
          Order(id: orderId, vip: true, pending: true),
          ...state,
        ];
      }
    }
    botController.processOrder();
  }

  void completeOrder(int orderId) {
    state = state
        .map((order) =>
            order.id == orderId ? order.copyWith(pending: false) : order)
        .toList();
    botController.removeBotProcessingOrder(orderId);
  }
}

final orderProvider = StateNotifierProvider<OrderController, Orders>(
    (ref) => OrderController(ref.read));
