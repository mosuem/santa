import 'dart:math';

import 'package:flutter/material.dart';

class SnowWidget extends StatefulWidget {
  final int totalSnow;
  final double speed;
  final bool isRunning;

  const SnowWidget(
      {super.key,
      required this.totalSnow,
      required this.speed,
      required this.isRunning});

  @override
  SnowWidgetState createState() => SnowWidgetState();
}

class SnowWidgetState extends State<SnowWidget>
    with SingleTickerProviderStateMixin {
  final Random _rnd = Random();
  AnimationController? controller;
  Animation? animation;
  List<Snow> _snows = [];
  double angle = 0;
  double W = 0;
  double H = 0;
  @override
  void initState() {
    super.initState();
    init();
  }

  void init() {
    if (controller == null) {
      controller = AnimationController(
          lowerBound: 0,
          upperBound: 1,
          vsync: this,
          duration: const Duration(milliseconds: 20000));
      controller!.addListener(() {
        if (mounted) {
          setState(() {
            update();
          });
        }
      });
    }
    if (!widget.isRunning) {
      controller?.stop();
    } else {
      controller?.repeat();
    }
  }

  @override
  dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _createSnow() {
    _snows = <Snow>[];
    for (var i = 0; i < widget.totalSnow; i++) {
      _snows.add(Snow(
          x: _rnd.nextDouble() * W,
          y: _rnd.nextDouble() * H,
          r: _rnd.nextDouble() * 4 + 1,
          d: _rnd.nextDouble() * widget.speed));
    }
  }

  void update() {
    angle += 0.01;
    if (_snows.isEmpty || widget.totalSnow != _snows.length) {
      _createSnow();
    }
    for (var i = 0; i < widget.totalSnow; i++) {
      var snow = _snows[i];
      //We will add 1 to the cos function to prevent negative values which will lead flakes to move upwards
      //Every particle has its own density which can be used to make the downward movement different for each flake
      //Lets make it more random by adding in the radius
      snow.y += (cos(angle + snow.d) + 1 + snow.r / 2) * widget.speed;
      snow.x += sin(angle) * 2 * widget.speed;
      if (snow.x > W + 5 || snow.x < -5 || snow.y > H) {
        if (i % 3 > 0) {
          //66.67% of the flakes
          _snows[i] =
              Snow(x: _rnd.nextDouble() * W, y: -10, r: snow.r, d: snow.d);
        } else {
          //If the flake is exiting from the right
          if (sin(angle) > 0) {
            //Enter from the left
            _snows[i] =
                Snow(x: -5, y: _rnd.nextDouble() * H, r: snow.r, d: snow.d);
          } else {
            //Enter from the right
            _snows[i] =
                Snow(x: W + 5, y: _rnd.nextDouble() * H, r: snow.r, d: snow.d);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isRunning && !(controller?.isAnimating ?? false)) {
      controller?.repeat();
    } else if (!widget.isRunning && (controller?.isAnimating ?? false)) {
      controller?.stop();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (_snows.isEmpty) {
          W = constraints.maxWidth;
          H = constraints.maxHeight;
        }
        return CustomPaint(
          willChange: widget.isRunning,
          painter: SnowPainter(
              // progress: controller.value,
              isRunning: widget.isRunning,
              snows: _snows),
          size: Size.infinite,
        );
      },
    );
  }
}

class Snow {
  double x;
  double y;
  final double r; //radius
  final double d; //density
  Snow({required this.x, required this.y, required this.r, required this.d});
}

class SnowPainter extends CustomPainter {
  final List<Snow>? snows;
  final bool isRunning;

  SnowPainter({required this.isRunning, required this.snows});

  @override
  void paint(Canvas canvas, Size size) {
    if (snows == null || !isRunning) return;
    for (var i = 0; i < snows!.length; i++) {
      var snow = snows![i];
      // canvas.drawCircle(Offset(x, y), snow.r, paint);
      double radius = snow.r / 10;
      Path path_0 = Path();
      double x = snow.x + snow.r;
      double y = snow.y + snow.r;
      path_0.moveTo(x + (radius * 36.18750), y + (radius * 17.56250));
      path_0.lineTo(x + (radius * 33.11175), y + (radius * 17.56250));
      path_0.lineTo(x + (radius * 34.49063), y + (radius * 16.18375));
      path_0.cubicTo(
          x + (radius * 34.85688),
          y + (radius * 15.81762),
          x + (radius * 34.85688),
          y + (radius * 15.22400),
          x + (radius * 34.49075),
          y + (radius * 14.85800));
      path_0.cubicTo(
          x + (radius * 34.12463),
          y + (radius * 14.49188),
          x + (radius * 33.53100),
          y + (radius * 14.49175),
          x + (radius * 33.16500),
          y + (radius * 14.85787));
      path_0.lineTo(x + (radius * 30.46013), y + (radius * 17.56250));
      path_0.lineTo(x + (radius * 25.91400), y + (radius * 17.56250));
      path_0.lineTo(x + (radius * 27.93675), y + (radius * 15.38850));
      path_0.cubicTo(
          x + (radius * 28.28937),
          y + (radius * 15.00950),
          x + (radius * 28.26800),
          y + (radius * 14.41638),
          x + (radius * 27.88887),
          y + (radius * 14.06350));
      path_0.cubicTo(
          x + (radius * 27.73350),
          y + (radius * 13.91900),
          x + (radius * 27.54200),
          y + (radius * 13.83825),
          x + (radius * 27.34575),
          y + (radius * 13.81838));
      path_0.cubicTo(
          x + (radius * 27.22675),
          y + (radius * 13.81250),
          x + (radius * 24.65887),
          y + (radius * 13.81800),
          x + (radius * 24.65887),
          y + (radius * 13.81800));
      path_0.lineTo(x + (radius * 27.66437), y + (radius * 10.81250));
      path_0.lineTo(x + (radius * 31.43750), y + (radius * 10.81250));
      path_0.cubicTo(
          x + (radius * 31.95538),
          y + (radius * 10.81250),
          x + (radius * 32.37500),
          y + (radius * 10.39288),
          x + (radius * 32.37500),
          y + (radius * 9.875000));
      path_0.cubicTo(
          x + (radius * 32.37500),
          y + (radius * 9.357125),
          x + (radius * 31.95538),
          y + (radius * 8.937500),
          x + (radius * 31.43750),
          y + (radius * 8.937500));
      path_0.lineTo(x + (radius * 29.53925), y + (radius * 8.937500));
      path_0.lineTo(x + (radius * 31.75050), y + (radius * 6.726250));
      path_0.cubicTo(
          x + (radius * 32.11662),
          y + (radius * 6.360000),
          x + (radius * 32.11662),
          y + (radius * 5.766500),
          x + (radius * 31.75050),
          y + (radius * 5.400250));
      path_0.cubicTo(
          x + (radius * 31.38425),
          y + (radius * 5.034250),
          x + (radius * 30.77000),
          y + (radius * 5.034250),
          x + (radius * 30.40375),
          y + (radius * 5.400250));
      path_0.lineTo(x + (radius * 28.14588), y + (radius * 7.637500));
      path_0.lineTo(x + (radius * 28.14588), y + (radius * 5.687500));
      path_0.cubicTo(
          x + (radius * 28.14588),
          y + (radius * 5.169625),
          x + (radius * 27.72625),
          y + (radius * 4.750000),
          x + (radius * 27.20838),
          y + (radius * 4.750000));
      path_0.cubicTo(
          x + (radius * 26.69050),
          y + (radius * 4.750000),
          x + (radius * 26.27088),
          y + (radius * 5.169625),
          x + (radius * 26.27088),
          y + (radius * 5.687500));
      path_0.lineTo(x + (radius * 26.27088), y + (radius * 9.512625));
      path_0.lineTo(x + (radius * 23.16625), y + (radius * 12.63813));
      path_0.lineTo(x + (radius * 23.11438), y + (radius * 9.807500));
      path_0.cubicTo(
          x + (radius * 23.11425),
          y + (radius * 9.803000),
          x + (radius * 23.11875),
          y + (radius * 9.798750),
          x + (radius * 23.11863),
          y + (radius * 9.794250));
      path_0.cubicTo(
          x + (radius * 23.11425),
          y + (radius * 9.566250),
          x + (radius * 23.03063),
          y + (radius * 9.339125),
          x + (radius * 22.85988),
          y + (radius * 9.161875));
      path_0.cubicTo(
          x + (radius * 22.50075),
          y + (radius * 8.789125),
          x + (radius * 21.88763),
          y + (radius * 8.778125),
          x + (radius * 21.51475),
          y + (radius * 9.137625));
      path_0.lineTo(x + (radius * 19.52088), y + (radius * 11.04088));
      path_0.lineTo(x + (radius * 19.52088), y + (radius * 6.638375));
      path_0.lineTo(x + (radius * 22.20463), y + (radius * 3.975375));
      path_0.cubicTo(
          x + (radius * 22.57075),
          y + (radius * 3.609125),
          x + (radius * 22.58113),
          y + (radius * 3.015625),
          x + (radius * 22.21500),
          y + (radius * 2.649500));
      path_0.cubicTo(
          x + (radius * 21.84875),
          y + (radius * 2.283500),
          x + (radius * 21.23963),
          y + (radius * 2.283500),
          x + (radius * 20.87350),
          y + (radius * 2.649500));
      path_0.lineTo(x + (radius * 19.52088), y + (radius * 3.986500));
      path_0.lineTo(x + (radius * 19.52088), y + (radius * 0.9375000));
      path_0.cubicTo(
        x + (radius * 19.52088),
        y + (radius * 0.4196250),
        x + (radius * 19.10125),
        y + 0,
        x + (radius * 18.58338),
        y + 0,
      );
      path_0.cubicTo(
          x + (radius * 18.06550),
          y + 0,
          x + (radius * 17.64588),
          y + (radius * 0.4196250),
          x + (radius * 17.64588),
          y + (radius * 0.9375000));
      path_0.lineTo(x + (radius * 17.64588), y + (radius * 3.986625));
      path_0.lineTo(x + (radius * 16.32963), y + (radius * 2.649625));
      path_0.cubicTo(
          x + (radius * 15.96338),
          y + (radius * 2.283625),
          x + (radius * 15.38038),
          y + (radius * 2.283625),
          x + (radius * 15.01413),
          y + (radius * 2.649625));
      path_0.cubicTo(
          x + (radius * 14.64800),
          y + (radius * 3.015875),
          x + (radius * 14.63238),
          y + (radius * 3.609375),
          x + (radius * 14.99850),
          y + (radius * 3.975500));
      path_0.lineTo(x + (radius * 17.64588), y + (radius * 6.638500));
      path_0.lineTo(x + (radius * 17.64588), y + (radius * 11.06612));
      path_0.lineTo(x + (radius * 15.62388), y + (radius * 9.131750));
      path_0.cubicTo(
          x + (radius * 15.24775),
          y + (radius * 8.775875),
          x + (radius * 14.66513),
          y + (radius * 8.792000),
          x + (radius * 14.30888),
          y + (radius * 9.167875));
      path_0.cubicTo(
          x + (radius * 14.17450),
          y + (radius * 9.309875),
          x + (radius * 14.09850),
          y + (radius * 9.482875),
          x + (radius * 14.06963),
          y + (radius * 9.662250));
      path_0.cubicTo(
          x + (radius * 14.05188),
          y + (radius * 9.735125),
          x + (radius * 14.04425),
          y + (radius * 9.810750),
          x + (radius * 14.04450),
          y + (radius * 9.888625));
      path_0.lineTo(x + (radius * 14.03350), y + (radius * 12.54225));
      path_0.lineTo(x + (radius * 10.89600), y + (radius * 9.424250));
      path_0.lineTo(x + (radius * 10.89600), y + (radius * 5.687500));
      path_0.cubicTo(
          x + (radius * 10.89600),
          y + (radius * 5.169625),
          x + (radius * 10.47638),
          y + (radius * 4.750000),
          x + (radius * 9.958500),
          y + (radius * 4.750000));
      path_0.cubicTo(
          x + (radius * 9.440625),
          y + (radius * 4.750000),
          x + (radius * 9.021000),
          y + (radius * 5.169625),
          x + (radius * 9.021000),
          y + (radius * 5.687500));
      path_0.lineTo(x + (radius * 9.021000), y + (radius * 7.549250));
      path_0.lineTo(x + (radius * 6.892750), y + (radius * 5.400250));
      path_0.cubicTo(
          x + (radius * 6.526500),
          y + (radius * 5.034250),
          x + (radius * 5.943500),
          y + (radius * 5.034250),
          x + (radius * 5.577250),
          y + (radius * 5.400250));
      path_0.cubicTo(
          x + (radius * 5.211125),
          y + (radius * 5.766500),
          x + (radius * 5.216375),
          y + (radius * 6.360000),
          x + (radius * 5.582500),
          y + (radius * 6.726250));
      path_0.lineTo(x + (radius * 7.799000), y + (radius * 8.937500));
      path_0.lineTo(x + (radius * 5.812500), y + (radius * 8.937500));
      path_0.cubicTo(
          x + (radius * 5.294625),
          y + (radius * 8.937500),
          x + (radius * 4.875000),
          y + (radius * 9.357125),
          x + (radius * 4.875000),
          y + (radius * 9.875000));
      path_0.cubicTo(
          x + (radius * 4.875000),
          y + (radius * 10.39288),
          x + (radius * 5.294625),
          y + (radius * 10.81250),
          x + (radius * 5.812500),
          y + (radius * 10.81250));
      path_0.lineTo(x + (radius * 9.674000), y + (radius * 10.81250));
      path_0.lineTo(x + (radius * 12.76700), y + (radius * 13.90550));
      path_0.lineTo(x + (radius * 9.884875), y + (radius * 14.00938));
      path_0.cubicTo(
          x + (radius * 9.382250),
          y + (radius * 14.02763),
          x + (radius * 8.944375),
          y + (radius * 14.43875),
          x + (radius * 8.939500),
          y + (radius * 14.93663));
      path_0.cubicTo(
          x + (radius * 8.939000),
          y + (radius * 14.95063),
          x + (radius * 8.895875),
          y + (radius * 14.96475),
          x + (radius * 8.895875),
          y + (radius * 14.97875));
      path_0.cubicTo(
          x + (radius * 8.895875),
          y + (radius * 14.97913),
          x + (radius * 8.895875),
          y + (radius * 14.97963),
          x + (radius * 8.895875),
          y + (radius * 14.98013));
      path_0.cubicTo(
          x + (radius * 8.895875),
          y + (radius * 14.98113),
          x + (radius * 8.939000),
          y + (radius * 14.98225),
          x + (radius * 8.939000),
          y + (radius * 14.98313));
      path_0.cubicTo(
          x + (radius * 8.944625),
          y + (radius * 15.21750),
          x + (radius * 9.058375),
          y + (radius * 15.45013),
          x + (radius * 9.238375),
          y + (radius * 15.62788));
      path_0.lineTo(x + (radius * 11.21850), y + (radius * 17.56250));
      path_0.lineTo(x + (radius * 6.878125), y + (radius * 17.56250));
      path_0.lineTo(x + (radius * 4.173375), y + (radius * 14.85775));
      path_0.cubicTo(
          x + (radius * 3.807125),
          y + (radius * 14.49175),
          x + (radius * 3.213625),
          y + (radius * 14.49175),
          x + (radius * 2.847500),
          y + (radius * 14.85775));
      path_0.cubicTo(
          x + (radius * 2.481375),
          y + (radius * 15.22400),
          x + (radius * 2.481375),
          y + (radius * 15.81750),
          x + (radius * 2.847500),
          y + (radius * 16.18362));
      path_0.lineTo(x + (radius * 4.226250), y + (radius * 17.56237));
      path_0.lineTo(x + (radius * 1.062500), y + (radius * 17.56237));
      path_0.cubicTo(
          x + (radius * 0.5446250),
          y + (radius * 17.56237),
          x + (radius * 0.1250000),
          y + (radius * 17.98200),
          x + (radius * 0.1250000),
          y + (radius * 18.49987));
      path_0.cubicTo(
          x + (radius * 0.1250000),
          y + (radius * 19.01775),
          x + (radius * 0.5446250),
          y + (radius * 19.43737),
          x + (radius * 1.062500),
          y + (radius * 19.43737));
      path_0.lineTo(x + (radius * 4.190000), y + (radius * 19.43737));
      path_0.lineTo(x + (radius * 2.847500), y + (radius * 20.77988));
      path_0.cubicTo(
          x + (radius * 2.481375),
          y + (radius * 21.14613),
          x + (radius * 2.481375),
          y + (radius * 21.73963),
          x + (radius * 2.847500),
          y + (radius * 22.10575));
      path_0.cubicTo(
          x + (radius * 3.030625),
          y + (radius * 22.28875),
          x + (radius * 3.270625),
          y + (radius * 22.38025),
          x + (radius * 3.510500),
          y + (radius * 22.38025));
      path_0.cubicTo(
          x + (radius * 3.750375),
          y + (radius * 22.38025),
          x + (radius * 3.990375),
          y + (radius * 22.28875),
          x + (radius * 4.173500),
          y + (radius * 22.10575));
      path_0.lineTo(x + (radius * 6.841750), y + (radius * 19.43750));
      path_0.lineTo(x + (radius * 11.22012), y + (radius * 19.43750));
      path_0.lineTo(x + (radius * 9.313500), y + (radius * 21.48675));
      path_0.cubicTo(
          x + (radius * 8.960875),
          y + (radius * 21.86575),
          x + (radius * 8.982250),
          y + (radius * 22.45887),
          x + (radius * 9.361375),
          y + (radius * 22.81175));
      path_0.cubicTo(
          x + (radius * 9.541875),
          y + (radius * 22.97975),
          x + (radius * 9.771000),
          y + (radius * 23.06287),
          x + (radius * 9.999625),
          y + (radius * 23.06287));
      path_0.cubicTo(
          x + (radius * 10.00387),
          y + (radius * 23.06287),
          x + (radius * 10.00812),
          y + (radius * 23.06225),
          x + (radius * 10.01250),
          y + (radius * 23.06225));
      path_0.cubicTo(
          x + (radius * 10.01525),
          y + (radius * 23.06225),
          x + (radius * 10.01800),
          y + (radius * 23.06262),
          x + (radius * 10.02062),
          y + (radius * 23.06262));
      path_0.cubicTo(
          x + (radius * 10.02287),
          y + (radius * 23.06262),
          x + (radius * 10.02525),
          y + (radius * 23.06262),
          x + (radius * 10.02750),
          y + (radius * 23.06262));
      path_0.lineTo(x + (radius * 12.77812), y + (radius * 23.04700));
      path_0.lineTo(x + (radius * 9.637625), y + (radius * 26.18750));
      path_0.lineTo(x + (radius * 5.812500), y + (radius * 26.18750));
      path_0.cubicTo(
          x + (radius * 5.294625),
          y + (radius * 26.18750),
          x + (radius * 4.875000),
          y + (radius * 26.60712),
          x + (radius * 4.875000),
          y + (radius * 27.12500));
      path_0.cubicTo(
          x + (radius * 4.875000),
          y + (radius * 27.64288),
          x + (radius * 5.294625),
          y + (radius * 28.06250),
          x + (radius * 5.812500),
          y + (radius * 28.06250));
      path_0.lineTo(x + (radius * 7.762625), y + (radius * 28.06250));
      path_0.lineTo(x + (radius * 5.587750), y + (radius * 30.23738));
      path_0.cubicTo(
          x + (radius * 5.221625),
          y + (radius * 30.60363),
          x + (radius * 5.221625),
          y + (radius * 31.19712),
          x + (radius * 5.587750),
          y + (radius * 31.56325));
      path_0.cubicTo(
          x + (radius * 5.770875),
          y + (radius * 31.74625),
          x + (radius * 6.010875),
          y + (radius * 31.83775),
          x + (radius * 6.250750),
          y + (radius * 31.83775));
      path_0.cubicTo(
          x + (radius * 6.490625),
          y + (radius * 31.83775),
          x + (radius * 6.709750),
          y + (radius * 31.74625),
          x + (radius * 6.892875),
          y + (radius * 31.56325));
      path_0.lineTo(x + (radius * 9.021000), y + (radius * 29.41437));
      path_0.lineTo(x + (radius * 9.021000), y + (radius * 31.31250));
      path_0.cubicTo(
          x + (radius * 9.021000),
          y + (radius * 31.83038),
          x + (radius * 9.440625),
          y + (radius * 32.25000),
          x + (radius * 9.958500),
          y + (radius * 32.25000));
      path_0.cubicTo(
          x + (radius * 10.47638),
          y + (radius * 32.25000),
          x + (radius * 10.89600),
          y + (radius * 31.83038),
          x + (radius * 10.89600),
          y + (radius * 31.31250));
      path_0.lineTo(x + (radius * 10.89600), y + (radius * 27.53937));
      path_0.lineTo(x + (radius * 14.07662), y + (radius * 24.37963));
      path_0.lineTo(x + (radius * 14.19875), y + (radius * 27.42838));
      path_0.cubicTo(
          x + (radius * 14.21725),
          y + (radius * 27.93413),
          x + (radius * 14.63837),
          y + (radius * 28.34163),
          x + (radius * 15.14025),
          y + (radius * 28.33150));
      path_0.cubicTo(
          x + (radius * 15.31075),
          y + (radius * 28.32813),
          x + (radius * 15.49575),
          y + (radius * 28.27338),
          x + (radius * 15.67925),
          y + (radius * 28.13863));
      path_0.cubicTo(
          x + (radius * 15.81212),
          y + (radius * 28.04100),
          x + (radius * 17.64600),
          y + (radius * 26.16212),
          x + (radius * 17.64600),
          y + (radius * 26.16212));
      path_0.lineTo(x + (radius * 17.64600), y + (radius * 30.58525));
      path_0.lineTo(x + (radius * 15.02463), y + (radius * 33.22737));
      path_0.cubicTo(
          x + (radius * 14.65837),
          y + (radius * 33.59350),
          x + (radius * 14.66887),
          y + (radius * 34.18712),
          x + (radius * 15.03487),
          y + (radius * 34.55325));
      path_0.cubicTo(
          x + (radius * 15.21800),
          y + (radius * 34.73637),
          x + (radius * 15.46300),
          y + (radius * 34.82787),
          x + (radius * 15.70300),
          y + (radius * 34.82787));
      path_0.cubicTo(
          x + (radius * 15.94287),
          y + (radius * 34.82787),
          x + (radius * 16.16463),
          y + (radius * 34.73637),
          x + (radius * 16.34763),
          y + (radius * 34.55337));
      path_0.lineTo(x + (radius * 17.64600), y + (radius * 33.23687));
      path_0.lineTo(x + (radius * 17.64600), y + (radius * 36.31250));
      path_0.cubicTo(
          x + (radius * 17.64600),
          y + (radius * 36.83037),
          x + (radius * 18.06563),
          y + (radius * 37.25000),
          x + (radius * 18.58350),
          y + (radius * 37.25000));
      path_0.cubicTo(
          x + (radius * 19.10138),
          y + (radius * 37.25000),
          x + (radius * 19.52100),
          y + (radius * 36.83037),
          x + (radius * 19.52100),
          y + (radius * 36.31250));
      path_0.lineTo(x + (radius * 19.52100), y + (radius * 33.14875));
      path_0.lineTo(x + (radius * 20.94650), y + (radius * 34.55338));
      path_0.cubicTo(
          x + (radius * 21.12963),
          y + (radius * 34.73638),
          x + (radius * 21.38000),
          y + (radius * 34.82788),
          x + (radius * 21.61988),
          y + (radius * 34.82788));
      path_0.cubicTo(
          x + (radius * 21.85975),
          y + (radius * 34.82788),
          x + (radius * 22.10500),
          y + (radius * 34.73638),
          x + (radius * 22.28800),
          y + (radius * 34.55338));
      path_0.cubicTo(
          x + (radius * 22.65413),
          y + (radius * 34.18713),
          x + (radius * 22.63587),
          y + (radius * 33.59363),
          x + (radius * 22.26975),
          y + (radius * 33.22750));
      path_0.lineTo(x + (radius * 19.52100), y + (radius * 30.49688));
      path_0.lineTo(x + (radius * 19.52100), y + (radius * 26.03438));
      path_0.cubicTo(
          x + (radius * 19.52100),
          y + (radius * 26.03438),
          x + (radius * 21.23712),
          y + (radius * 27.64638),
          x + (radius * 21.50800),
          y + (radius * 27.90638));
      path_0.cubicTo(
          x + (radius * 21.77888),
          y + (radius * 28.16638),
          x + (radius * 22.00075),
          y + (radius * 28.31263),
          x + (radius * 22.32363),
          y + (radius * 28.31263));
      path_0.cubicTo(
          x + (radius * 22.32550),
          y + (radius * 28.31263),
          x + (radius * 22.32738),
          y + (radius * 28.31263),
          x + (radius * 22.32938),
          y + (radius * 28.31263));
      path_0.cubicTo(
          x + (radius * 22.84713),
          y + (radius * 28.31263),
          x + (radius * 23.26438),
          y + (radius * 27.86213),
          x + (radius * 23.26125),
          y + (radius * 27.34438));
      path_0.lineTo(x + (radius * 23.22300), y + (radius * 24.38238));
      path_0.lineTo(x + (radius * 26.27100), y + (radius * 27.45125));
      path_0.lineTo(x + (radius * 26.27100), y + (radius * 31.31250));
      path_0.cubicTo(
          x + (radius * 26.27100),
          y + (radius * 31.83038),
          x + (radius * 26.69063),
          y + (radius * 32.25000),
          x + (radius * 27.20850),
          y + (radius * 32.25000));
      path_0.cubicTo(
          x + (radius * 27.72638),
          y + (radius * 32.25000),
          x + (radius * 28.14600),
          y + (radius * 31.83038),
          x + (radius * 28.14600),
          y + (radius * 31.31250));
      path_0.lineTo(x + (radius * 28.14600), y + (radius * 29.32613));
      path_0.lineTo(x + (radius * 30.40400), y + (radius * 31.56325));
      path_0.cubicTo(
          x + (radius * 30.58713),
          y + (radius * 31.74625),
          x + (radius * 30.83738),
          y + (radius * 31.83775),
          x + (radius * 31.07737),
          y + (radius * 31.83775));
      path_0.cubicTo(
          x + (radius * 31.31725),
          y + (radius * 31.83775),
          x + (radius * 31.56237),
          y + (radius * 31.74625),
          x + (radius * 31.74550),
          y + (radius * 31.56325));
      path_0.cubicTo(
          x + (radius * 32.11162),
          y + (radius * 31.19700),
          x + (radius * 32.11425),
          y + (radius * 30.60350),
          x + (radius * 31.74812),
          y + (radius * 30.23738));
      path_0.lineTo(x + (radius * 29.57562), y + (radius * 28.06250));
      path_0.lineTo(x + (radius * 31.43750), y + (radius * 28.06250));
      path_0.cubicTo(
          x + (radius * 31.95538),
          y + (radius * 28.06250),
          x + (radius * 32.37500),
          y + (radius * 27.64288),
          x + (radius * 32.37500),
          y + (radius * 27.12500));
      path_0.cubicTo(
          x + (radius * 32.37500),
          y + (radius * 26.60712),
          x + (radius * 31.95538),
          y + (radius * 26.18750),
          x + (radius * 31.43750),
          y + (radius * 26.18750));
      path_0.lineTo(x + (radius * 27.70075), y + (radius * 26.18750));
      path_0.lineTo(x + (radius * 24.48300), y + (radius * 22.96975));
      path_0.lineTo(x + (radius * 27.36538), y + (radius * 22.86588));
      path_0.cubicTo(
          x + (radius * 27.37562),
          y + (radius * 22.86550),
          x + (radius * 27.38563),
          y + (radius * 22.86388),
          x + (radius * 27.39575),
          y + (radius * 22.86325));
      path_0.cubicTo(
          x + (radius * 27.39950),
          y + (radius * 22.86300),
          x + (radius * 27.40325),
          y + (radius * 22.86263),
          x + (radius * 27.40700),
          y + (radius * 22.86225));
      path_0.cubicTo(
          x + (radius * 27.90413),
          y + (radius * 22.82238),
          x + (radius * 28.28663),
          y + (radius * 22.39863),
          x + (radius * 28.26850),
          y + (radius * 21.89525));
      path_0.cubicTo(
          x + (radius * 28.25763),
          y + (radius * 21.59225),
          x + (radius * 28.10350),
          y + (radius * 21.32888),
          x + (radius * 27.87412),
          y + (radius * 21.16563));
      path_0.lineTo(x + (radius * 26.14225), y + (radius * 19.43750));
      path_0.lineTo(x + (radius * 30.49663), y + (radius * 19.43750));
      path_0.lineTo(x + (radius * 33.16475), y + (radius * 22.10575));
      path_0.cubicTo(
          x + (radius * 33.34787),
          y + (radius * 22.28888),
          x + (radius * 33.58775),
          y + (radius * 22.38038),
          x + (radius * 33.82775),
          y + (radius * 22.38038));
      path_0.cubicTo(
          x + (radius * 34.06762),
          y + (radius * 22.38038),
          x + (radius * 34.30762),
          y + (radius * 22.28888),
          x + (radius * 34.49062),
          y + (radius * 22.10588));
      path_0.cubicTo(
          x + (radius * 34.85687),
          y + (radius * 21.73975),
          x + (radius * 34.85687),
          y + (radius * 21.14613),
          x + (radius * 34.49075),
          y + (radius * 20.78013));
      path_0.lineTo(x + (radius * 33.14825), y + (radius * 19.43763));
      path_0.lineTo(x + (radius * 36.18750), y + (radius * 19.43763));
      path_0.cubicTo(
          x + (radius * 36.70537),
          y + (radius * 19.43763),
          x + (radius * 37.12500),
          y + (radius * 19.01800),
          x + (radius * 37.12500),
          y + (radius * 18.50013));
      path_0.cubicTo(
          x + (radius * 37.12500),
          y + (radius * 17.98225),
          x + (radius * 36.70537),
          y + (radius * 17.56250),
          x + (radius * 36.18750),
          y + (radius * 17.56250));
      path_0.close();
      path_0.moveTo(x + (radius * 25.09937), y + (radius * 15.68538));
      path_0.lineTo(x + (radius * 23.35288), y + (radius * 17.56250));
      path_0.lineTo(x + (radius * 20.91450), y + (radius * 17.56250));
      path_0.lineTo(x + (radius * 22.78975), y + (radius * 15.68725));
      path_0.lineTo(x + (radius * 25.09937), y + (radius * 15.68538));
      path_0.close();
      path_0.moveTo(x + (radius * 21.27625), y + (radius * 11.97300));
      path_0.lineTo(x + (radius * 21.32075), y + (radius * 14.47325));
      path_0.lineTo(x + (radius * 19.52088), y + (radius * 16.26262));
      path_0.lineTo(x + (radius * 19.52088), y + (radius * 13.64500));
      path_0.lineTo(x + (radius * 21.27625), y + (radius * 11.97300));
      path_0.close();
      path_0.moveTo(x + (radius * 15.90788), y + (radius * 11.98312));
      path_0.lineTo(x + (radius * 17.64588), y + (radius * 13.64850));
      path_0.lineTo(x + (radius * 17.64588), y + (radius * 16.17412));
      path_0.lineTo(x + (radius * 15.90525), y + (radius * 14.42312));
      path_0.lineTo(x + (radius * 15.90788), y + (radius * 11.98312));
      path_0.close();
      path_0.moveTo(x + (radius * 12.10775), y + (radius * 15.80550));
      path_0.lineTo(x + (radius * 14.57800), y + (radius * 15.71650));
      path_0.lineTo(x + (radius * 16.42400), y + (radius * 17.56250));
      path_0.lineTo(x + (radius * 13.88662), y + (radius * 17.56250));
      path_0.lineTo(x + (radius * 12.10775), y + (radius * 15.80550));
      path_0.close();
      path_0.moveTo(x + (radius * 12.15575), y + (radius * 21.18463));
      path_0.lineTo(x + (radius * 13.78125), y + (radius * 19.43750));
      path_0.lineTo(x + (radius * 16.38762), y + (radius * 19.43750));
      path_0.lineTo(x + (radius * 14.65750), y + (radius * 21.16763));
      path_0.lineTo(x + (radius * 12.15575), y + (radius * 21.18463));
      path_0.close();
      path_0.moveTo(x + (radius * 15.98287), y + (radius * 25.19987));
      path_0.lineTo(x + (radius * 15.87613), y + (radius * 22.56962));
      path_0.lineTo(x + (radius * 17.64588), y + (radius * 20.78950));
      path_0.lineTo(x + (radius * 17.64588), y + (radius * 23.49000));
      path_0.lineTo(x + (radius * 15.98287), y + (radius * 25.19987));
      path_0.close();
      path_0.moveTo(x + (radius * 21.35237), y + (radius * 25.15800));
      path_0.lineTo(x + (radius * 19.52088), y + (radius * 23.47325));
      path_0.lineTo(x + (radius * 19.52088), y + (radius * 20.70087));
      path_0.lineTo(x + (radius * 21.32613), y + (radius * 22.49575));
      path_0.lineTo(x + (radius * 21.35237), y + (radius * 25.15800));
      path_0.close();
      path_0.moveTo(x + (radius * 25.12388), y + (radius * 21.07050));
      path_0.lineTo(x + (radius * 22.67213), y + (radius * 21.15875));
      path_0.lineTo(x + (radius * 20.95087), y + (radius * 19.43750));
      path_0.lineTo(x + (radius * 23.48738), y + (radius * 19.43750));
      path_0.lineTo(x + (radius * 25.12388), y + (radius * 21.07050));
      path_0.close();

      Paint paint = Paint()..style = PaintingStyle.fill;
      paint.color = Colors.blueGrey[400]!.withAlpha(255);
      canvas.drawPath(path_0, paint);
    }
  }

  @override
  bool shouldRepaint(SnowPainter oldDelegate) => isRunning;
}
