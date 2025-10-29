import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static final Map<String, Map<String, String>> _localizedValues = {
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
      
      // Nuevas traducciones para historial y estadísticas
      'customer_history': 'Historial de Clientes',
      'statistics': 'Estadísticas',
      'calendar_view': 'Vista Calendario',
      'last_7_days': 'Últimos 7 días',
      'last_15_days': 'Últimos 15 días',
      'last_30_days': 'Últimos 30 días',
      'completion_rate': 'Tasa de Completadas',
      'no_show_rate': 'Tasa de No-Shows',
      'total_reservations': 'Total de Reservas',
      'completed_reservations': 'Reservas Completadas',
      'cancelled_reservations': 'Reservas Canceladas',
      'no_show_reservations': 'No Vinieron',
      'confirmed_reservations': 'Confirmadas',
      'in_table_reservations': 'En Mesa',
      'reservation_trends': 'Tendencias de Reservas',
      'performance_metrics': 'Métricas de Rendimiento',
      'view_details': 'Ver Detalles',
      'expired_reservation': 'Reserva Vencida',
      'time_remaining': 'Tiempo Restante',
      'critical_period': 'Período Crítico',
      'late_arrival': 'Llegada Tardía',
      'cancelled_tables': 'Mesas Canceladas',
      'table_layout_notice': 'Información de Mesas',
      'table_layout_description': 'El restaurante cuenta con 10 mesas ubicadas en la planta alta: 5 barras altas, 5 mesas bajas y 1 área de living para mayor comodidad.',
      'upper_floor_info': 'Todas las mesas están en la planta alta',
      'table_occupied': 'Mesa Ocupada',
      'table_not_available': 'No Disponible',
      'language_selector': 'Idioma',
      'spanish': 'Español',
      'english': 'English',
      'chinese': '中文',
      'table_reserved': 'Mesa Reservada',
      'table_reserved_message': 'Esta mesa ya está reservada para hoy. Por favor elige otra mesa disponible.',
      'choose_another_table': 'Elegir otra mesa',
      'analytics': 'Análisis',
      'ratings': 'Valoraciones',
      'reservations': 'Reservas',
      'comments': 'Comentarios',
      'last_7_days_menu': 'Últimos 7 días',
      'last_15_days_menu': 'Últimos 15 días',
      'last_30_days_menu': 'Últimos 30 días',
      'last_90_days_menu': 'Últimos 90 días',
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
      
      // Nuevas traducciones para historial y estadísticas
      'customer_history': 'Customer History',
      'statistics': 'Statistics',
      'calendar_view': 'Calendar View',
      'last_7_days': 'Last 7 days',
      'last_15_days': 'Last 15 days',
      'last_30_days': 'Last 30 days',
      'completion_rate': 'Completion Rate',
      'no_show_rate': 'No-Show Rate',
      'total_reservations': 'Total Reservations',
      'completed_reservations': 'Completed Reservations',
      'cancelled_reservations': 'Cancelled Reservations',
      'no_show_reservations': 'No Shows',
      'confirmed_reservations': 'Confirmed',
      'in_table_reservations': 'At Table',
      'reservation_trends': 'Reservation Trends',
      'performance_metrics': 'Performance Metrics',
      'view_details': 'View Details',
      'table_layout_notice': 'Table Information',
      'table_layout_description': 'The restaurant has 10 tables located on the upper floor: 5 high bar tables, 5 low tables and 1 living area for greater comfort.',
      'upper_floor_info': 'All tables are on the upper floor',
      'table_occupied': 'Table Occupied',
      'table_not_available': 'Not Available',
      'language_selector': 'Language',
      'spanish': 'Español',
      'english': 'English',
      'chinese': '中文',
      'table_reserved': 'Table Reserved',
      'table_reserved_message': 'This table is already reserved for today. Please choose another available table.',
      'choose_another_table': 'Choose another table',
      'analytics': 'Analytics',
      'ratings': 'Ratings',
      'reservations': 'Reservations',
      'comments': 'Comments',
      'last_7_days_menu': 'Last 7 days',
      'last_15_days_menu': 'Last 15 days',
      'last_30_days_menu': 'Last 30 days',
      'last_90_days_menu': 'Last 90 days',
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
      
      // Nuevas traducciones para historial y estadísticas
      'customer_history': '客户历史',
      'statistics': '统计数据',
      'calendar_view': '日历视图',
      'last_7_days': '最近7天',
      'last_15_days': '最近15天',
      'last_30_days': '最近30天',
      'completion_rate': '完成率',
      'no_show_rate': '未到率',
      'total_reservations': '总预订数',
      'completed_reservations': '已完成预订',
      'cancelled_reservations': '已取消预订',
      'no_show_reservations': '未到预订',
      'confirmed_reservations': '已确认',
      'in_table_reservations': '就餐中',
      'reservation_trends': '预订趋势',
      'performance_metrics': '性能指标',
      'view_details': '查看详情',
      'table_layout_notice': '餐桌信息',
      'table_layout_description': '餐厅在二楼设有10张餐桌：5张高吧台桌、5张低桌和1个休息区，更加舒适。',
      'upper_floor_info': '所有餐桌都在二楼',
      'table_occupied': '餐桌已被占用',
      'table_not_available': '不可用',
      'language_selector': '语言',
      'spanish': 'Español',
      'english': 'English',
      'chinese': '中文',
      'table_reserved': '餐桌已预订',
      'table_reserved_message': '这张餐桌今天已经被预订了。请选择其他可用餐桌。',
      'choose_another_table': '选择其他餐桌',
      'analytics': '分析',
      'ratings': '评分',
      'reservations': '预订',
      'comments': '评论',
      'last_7_days_menu': '最近7天',
      'last_15_days_menu': '最近15天',
      'last_30_days_menu': '最近30天',
      'last_90_days_menu': '最近90天',
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
  
  // Nuevos getters para historial y estadísticas
  String get customerHistory => translate('customer_history');
  String get statistics => translate('statistics');
  String get calendarView => translate('calendar_view');
  String get last7Days => translate('last_7_days');
  String get last15Days => translate('last_15_days');
  String get last30Days => translate('last_30_days');
  String get completionRate => translate('completion_rate');
  String get noShowRate => translate('no_show_rate');
  String get totalReservations => translate('total_reservations');
  String get completedReservations => translate('completed_reservations');
  String get cancelledReservations => translate('cancelled_reservations');
  String get noShowReservations => translate('no_show_reservations');
  String get confirmedReservations => translate('confirmed_reservations');
  String get inTableReservations => translate('in_table_reservations');
  String get reservationTrends => translate('reservation_trends');
  String get performanceMetrics => translate('performance_metrics');
  String get viewDetails => translate('view_details');
  String get tableLayoutNotice => translate('table_layout_notice');
  String get tableLayoutDescription => translate('table_layout_description');
  String get upperFloorInfo => translate('upper_floor_info');
  String get tableOccupied => translate('table_occupied');
  String get tableNotAvailable => translate('table_not_available');
  String get languageSelector => translate('language_selector');
  String get spanish => translate('spanish');
  String get english => translate('english');
  String get chinese => translate('chinese');
  String get tableReserved => translate('table_reserved');
  String get tableReservedMessage => translate('table_reserved_message');
  String get chooseAnotherTable => translate('choose_another_table');
  String get analytics => translate('analytics');
  String get ratings => translate('ratings');
  String get reservations => translate('reservations');
  String get comments => translate('comments');
  String get last7DaysMenu => translate('last_7_days_menu');
  String get last15DaysMenu => translate('last_15_days_menu');
  String get last30DaysMenu => translate('last_30_days_menu');
  String get last90DaysMenu => translate('last_90_days_menu');

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