import "package:flutter/material.dart";
import "dart:async";
import 'package:hijriyah_khgt/hijriyah_khgt.dart';
import 'package:hijriyah_khgt/exstensions/word_extension.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class HijriKHGT extends StatefulWidget {
  const HijriKHGT({super.key});

  @override
  State<HijriKHGT> createState() => _HijriKHGTState();
}

class _HijriKHGTState extends State<HijriKHGT> {
  late Hijriyah _khgt;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    getTanggal();
    scheduleMidnightUpdate();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void getTanggal() {
    try {
      _khgt = Hijriyah.now();
    } catch (e) {
      // fallback if Hijriyah.now() fails
      _khgt = Hijriyah.hijri(1447, 1, 1);
    }
  }

  void scheduleMidnightUpdate() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final durationToMidnight = nextMidnight.difference(now);

    _timer = Timer(durationToMidnight, () {
      setState(() {
        getTanggal();
      });
      // Schedule next midnight update
      scheduleMidnightUpdate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive font sizes
    final dayFontSize = screenWidth < 400 ? 60.0 : 100.0;
    final headerFontSize = screenWidth < 400 ? 20.0 : 32.0;

    return Card(
      elevation: 4.0,
      clipBehavior: Clip.antiAlias,
      color: const Color.fromARGB(255, 2, 73, 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Align(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "${_khgt.dayWeName.toTitleCase()} ${_khgt.nmPasaran}",
                  style: TextStyle(
                    fontSize: headerFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellowAccent,
                  ),
                  textAlign: TextAlign.center,
                  semanticsLabel: "Hari dan pasaran Hijriyah",
                ),
              ),
            ),
            Expanded(
              flex: 7,
              child: Text(
                _khgt.hDay.toString(),
                style: TextStyle(
                  fontSize: dayFontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.yellowAccent,
                ),
                textAlign: TextAlign.center,
                semanticsLabel: "Tanggal Hijriyah",
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                "${_khgt.longMonthName} ${_khgt.hYear} H",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                semanticsLabel: "Bulan dan tahun Hijriyah",
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                "[ ${DateFormat.yMMMMEEEEd('id_ID').format(DateTime.now())} ]",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                semanticsLabel: "Tanggal Masehi",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
