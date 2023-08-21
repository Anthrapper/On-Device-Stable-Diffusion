import 'package:flutter_diffusion/app/modules/home/bindings/home_binding.dart';
import 'package:flutter_diffusion/app/modules/home/views/home_view.dart';
import 'package:get/get.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.homePage;

  static final routes = [
    GetPage(
      name: _Paths.homePage,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
  ];
}
