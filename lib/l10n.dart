import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static Map<String, Map<String, String>> _localizedValues = {
    'es': {
      'app_title': 'SODITA - Reservas',
      'reserve_table': 'Reservar Mesa',
      'choose_table': 'Elige tu mesa en el piso superior',
      'when': '¿Cuándo?',
      'what_time': '¿A qué hora?',
      'how_many_people': '¿Cuántas personas?',
      'person': 'persona',
      'people': 'personas',
      'select_table': 'Selecciona tu mesa',
      'available_tables': 'mesas disponibles para',
      'up_to': 'Hasta',
      'important_15_min': '⚠️ IMPORTANTE: Política de 15 minutos',
      'policy_message': 'Tienes 15 minutos desde tu hora de reserva para llegar. Si no llegas a tiempo, tu mesa se liberará automáticamente.',
      'free_reservation': '¡Reserva GRATIS!',
      'only_pay_consume': 'Solo paga lo que consumas en el restaurante',
      'reserve_table_num': 'Reservar Mesa',
      'select_time_table': 'Selecciona hora y mesa',
      'reservation_confirmed': 'Reserva Confirmada',
      'table_reserved_for': 'reservada para',
      'date': 'Fecha',
      'time': 'Hora',
      'reminder_15_min': '⚠️ RECORDATORIO: Tienes 15 minutos para llegar o se libera tu mesa.',
      'understood': 'Entendido',
      'admin_access': 'Acceso Admin',
      'email': 'Email',
      'password': 'Contraseña',
      'cancel': 'Cancelar',
      'enter': 'Ingresar',
      'wrong_credentials': 'Credenciales incorrectas',
      'table_control': 'SODITA - Control de Mesas',
      'free': 'Libres',
      'occupied': 'Ocupadas',
      'reserved': 'Reservadas',
      'expired': 'Vencidas',
      'free_status': 'Libre',
      'occupied_status': 'Ocupada',
      'reserved_status': 'Reservada',
      'expired_status': 'Vencida',
      'upper_floor_status': 'Estado del Piso Superior',
      'policy_15_min': 'Política de 15 Minutos',
      'grace_time': '⏰ Tiempo de gracia: 15 minutos',
      'policy_detail1': '• Si el comensal no llega en 15 minutos, la mesa se libera automáticamente',
      'policy_detail2': '• Las mesas vencidas aparecen en gris y pueden liberarse manualmente',
      'available': 'Disponible',
      'mon': 'Lun',
      'tue': 'Mar',
      'wed': 'Mié',
      'thu': 'Jue',
      'fri': 'Vie',
      'sat': 'Sáb',
      'sun': 'Dom',
      'jan': 'Ene',
      'feb': 'Feb',
      'mar': 'Mar',
      'apr': 'Abr',
      'may': 'May',
      'jun': 'Jun',
      'jul': 'Jul',
      'aug': 'Ago',
      'sep': 'Sep',
      'oct': 'Oct',
      'nov': 'Nov',
      'dec': 'Dic',
    },
    'en': {
      'app_title': 'SODITA - Reservations',
      'reserve_table': 'Reserve Table',
      'choose_table': 'Choose your table on the upper floor',
      'when': 'When?',
      'what_time': 'What time?',
      'how_many_people': 'How many people?',
      'person': 'person',
      'people': 'people',
      'select_table': 'Select your table',
      'available_tables': 'tables available for',
      'up_to': 'Up to',
      'important_15_min': '⚠️ IMPORTANT: 15-minute policy',
      'policy_message': 'You have 15 minutes from your reservation time to arrive. If you don\'t arrive on time, your table will be automatically released.',
      'free_reservation': 'FREE Reservation!',
      'only_pay_consume': 'Only pay for what you consume at the restaurant',
      'reserve_table_num': 'Reserve Table',
      'select_time_table': 'Select time and table',
      'reservation_confirmed': 'Reservation Confirmed',
      'table_reserved_for': 'reserved for',
      'date': 'Date',
      'time': 'Time',
      'reminder_15_min': '⚠️ REMINDER: You have 15 minutes to arrive or your table will be released.',
      'understood': 'Understood',
      'admin_access': 'Admin Access',
      'email': 'Email',
      'password': 'Password',
      'cancel': 'Cancel',
      'enter': 'Enter',
      'wrong_credentials': 'Wrong credentials',
      'table_control': 'SODITA - Table Control',
      'free': 'Free',
      'occupied': 'Occupied',
      'reserved': 'Reserved',
      'expired': 'Expired',
      'free_status': 'Free',
      'occupied_status': 'Occupied',
      'reserved_status': 'Reserved',
      'expired_status': 'Expired',
      'upper_floor_status': 'Upper Floor Status',
      'policy_15_min': '15-Minute Policy',
      'grace_time': '⏰ Grace time: 15 minutes',
      'policy_detail1': '• If the customer doesn\'t arrive in 15 minutes, the table is automatically released',
      'policy_detail2': '• Expired tables appear in gray and can be manually released',
      'available': 'Available',
      'mon': 'Mon',
      'tue': 'Tue',
      'wed': 'Wed',
      'thu': 'Thu',
      'fri': 'Fri',
      'sat': 'Sat',
      'sun': 'Sun',
      'jan': 'Jan',
      'feb': 'Feb',
      'mar': 'Mar',
      'apr': 'Apr',
      'may': 'May',
      'jun': 'Jun',
      'jul': 'Jul',
      'aug': 'Aug',
      'sep': 'Sep',
      'oct': 'Oct',
      'nov': 'Nov',
      'dec': 'Dec',
    },
    'zh': {
      'app_title': 'SODITA - 预订',
      'reserve_table': '预订餐桌',
      'choose_table': '选择您在楼上的餐桌',
      'when': '什么时候？',
      'what_time': '几点？',
      'how_many_people': '多少人？',
      'person': '人',
      'people': '人',
      'select_table': '选择您的餐桌',
      'available_tables': '张桌子可供',
      'up_to': '最多',
      'important_15_min': '⚠️ 重要：15分钟政策',
      'policy_message': '您有15分钟的时间从预订时间到达。如果您没有按时到达，您的桌子将自动释放。',
      'free_reservation': '免费预订！',
      'only_pay_consume': '只需支付您在餐厅消费的费用',
      'reserve_table_num': '预订餐桌',
      'select_time_table': '选择时间和桌子',
      'reservation_confirmed': '预订确认',
      'table_reserved_for': '为',
      'date': '日期',
      'time': '时间',
      'reminder_15_min': '⚠️ 提醒：您有15分钟到达，否则您的桌子将被释放。',
      'understood': '明白了',
      'admin_access': '管理员访问',
      'email': '邮箱',
      'password': '密码',
      'cancel': '取消',
      'enter': '进入',
      'wrong_credentials': '凭据错误',
      'table_control': 'SODITA - 餐桌控制',
      'free': '空闲',
      'occupied': '占用',
      'reserved': '预订',
      'expired': '过期',
      'free_status': '空闲',
      'occupied_status': '占用',
      'reserved_status': '预订',
      'expired_status': '过期',
      'upper_floor_status': '楼上状态',
      'policy_15_min': '15分钟政策',
      'grace_time': '⏰ 宽限时间：15分钟',
      'policy_detail1': '• 如果顾客在15分钟内没有到达，桌子将自动释放',
      'policy_detail2': '• 过期的桌子显示为灰色，可以手动释放',
      'available': '可用',
      'mon': '周一',
      'tue': '周二',
      'wed': '周三',
      'thu': '周四',
      'fri': '周五',
      'sat': '周六',
      'sun': '周日',
      'jan': '1月',
      'feb': '2月',
      'mar': '3月',
      'apr': '4月',
      'may': '5月',
      'jun': '6月',
      'jul': '7月',
      'aug': '8月',
      'sep': '9月',
      'oct': '10月',
      'nov': '11月',
      'dec': '12月',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Métodos de conveniencia
  String get appTitle => translate('app_title');
  String get reserveTable => translate('reserve_table');
  String get chooseTable => translate('choose_table');
  String get when => translate('when');
  String get whatTime => translate('what_time');
  String get howManyPeople => translate('how_many_people');
  String get person => translate('person');
  String get people => translate('people');
  String get selectTable => translate('select_table');
  String get availableTables => translate('available_tables');
  String get upTo => translate('up_to');
  String get important15Min => translate('important_15_min');
  String get policyMessage => translate('policy_message');
  String get freeReservation => translate('free_reservation');
  String get onlyPayConsume => translate('only_pay_consume');
  String get reserveTableNum => translate('reserve_table_num');
  String get selectTimeTable => translate('select_time_table');
  String get reservationConfirmed => translate('reservation_confirmed');
  String get tableReservedFor => translate('table_reserved_for');
  String get date => translate('date');
  String get time => translate('time');
  String get reminder15Min => translate('reminder_15_min');
  String get understood => translate('understood');
  String get adminAccess => translate('admin_access');
  String get email => translate('email');
  String get password => translate('password');
  String get cancel => translate('cancel');
  String get enter => translate('enter');
  String get wrongCredentials => translate('wrong_credentials');
  String get tableControl => translate('table_control');
  String get free => translate('free');
  String get occupied => translate('occupied');
  String get reserved => translate('reserved');
  String get expired => translate('expired');
  String get freeStatus => translate('free_status');
  String get occupiedStatus => translate('occupied_status');
  String get reservedStatus => translate('reserved_status');
  String get expiredStatus => translate('expired_status');
  String get upperFloorStatus => translate('upper_floor_status');
  String get policy15Min => translate('policy_15_min');
  String get graceTime => translate('grace_time');
  String get policyDetail1 => translate('policy_detail1');
  String get policyDetail2 => translate('policy_detail2');
  String get available => translate('available');

  // Días de la semana
  String getDayName(int weekday) {
    switch (weekday) {
      case 1: return translate('mon');
      case 2: return translate('tue');
      case 3: return translate('wed');
      case 4: return translate('thu');
      case 5: return translate('fri');
      case 6: return translate('sat');
      case 7: return translate('sun');
      default: return '';
    }
  }

  // Meses
  String getMonthName(int month) {
    switch (month) {
      case 1: return translate('jan');
      case 2: return translate('feb');
      case 3: return translate('mar');
      case 4: return translate('apr');
      case 5: return translate('may');
      case 6: return translate('jun');
      case 7: return translate('jul');
      case 8: return translate('aug');
      case 9: return translate('sep');
      case 10: return translate('oct');
      case 11: return translate('nov');
      case 12: return translate('dec');
      default: return '';
    }
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['es', 'en', 'zh'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}