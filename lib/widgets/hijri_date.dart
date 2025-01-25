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
    initializeDateFormatting('id_ID',null);
    getTanggal();
    startPeriodicUpdate();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void getTanggal() {
    _khgt = Hijriyah.now();
    
    
  }

  void startPeriodicUpdate() {
    _timer = Timer.periodic(const Duration(hours: 24), (timer) {
      setState(() {
        getTanggal();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellowAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 7,
              child: Text(
                _khgt.hDay.toString(),
                style: const TextStyle(
                  fontSize: 100,
                  fontWeight: FontWeight.bold,
                  color: Colors.yellowAccent,
                ),
                textAlign: TextAlign.center,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
