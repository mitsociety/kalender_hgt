import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:hijriyah_khgt/hijriyah_khgt.dart';

class CalendarKHGT extends StatefulWidget {
  const CalendarKHGT({super.key});

  @override
  State<CalendarKHGT> createState() => _CalendarKHGTState();
}

class _CalendarKHGTState extends State<CalendarKHGT> {
  //late MuhDateTime _currentMonth;
  late Hijriyah _currentMonth;
  //late String pasaran = '-';
  late Timer? _timer;
  final PageController _pageController = PageController(initialPage: DateTime.now().month - 1);
  late int selectedYear;

  @override
  void initState() {
    super.initState();
    initializeCalendar();
    _timer = Timer.periodic(const Duration(hours: 24), (_) => initializeCalendar());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void initializeCalendar() {
    setState(() {
      Hijriyah khgt = Hijriyah.now();
      debugPrint("tahun : ${khgt.hYear}, bulan : ${khgt.hMonth}, tanggal : ${khgt.hDay}");
      // Get the Gregorian date for the first of current Hijri month
      DateTime firstOfMonth = khgt.hijriToGregorian(khgt.hYear, khgt.hMonth, 1);
      debugPrint("First of month (Gregorian): ${firstOfMonth.toIso8601String()}");
      
      // Create new Hijri object from that Gregorian date
      _currentMonth = Hijriyah.fromDate(firstOfMonth);
      selectedYear = _currentMonth.hYear;
      debugPrint("selectedYear: ${selectedYear.toString()}");
      //pasaran = _currentMonth.pasaran;
    });
  }

  String getPasaranOffset(int startIndex, String psrOffset) {
    List<String> psrn =  ['Kliwon', 'Legi', 'Pahing', 'Pon', 'Wage'];
    int offset = psrn.indexOf(psrOffset);
    if (offset == -1) {
      throw ArgumentError("Invalid pasaran offset value: $psrOffset");
    }
    return psrn[(startIndex + offset) % psrn.length];
  }

  DateTime getMasehi(int hYear, int hMonth, int hDay) {
    final DateTime masehi = Hijriyah().hijriToGregorian(hYear, hMonth, hDay);
    return masehi;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(flex: 1, child: _buildHeader()),
        _buildWeeks(),
        Expanded(
          flex: 8,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentMonth = Hijriyah.hijri(selectedYear, index + 1, 1);
                //pasaran = _currentMonth.pasaran;
              });
            },
            itemCount: 12 * 23,
            itemBuilder: (context, pageIndex) {
              int month = pageIndex % 12;
              return _calGrid(month, selectedYear);
            },
          ),
        ),
        Expanded(flex: 1, child: _buildFooter()),
      ],
    );
  }

  Widget _buildHeader() {
    final List<int> years =  [for (var i = 1447; i <= 1494; i++) i];//data.keys.toList();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: (_pageController.hasClients && _pageController.page! > 0)
                ? () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                : null, // Disable if at first page
          ),
          const SizedBox(width: 20),
          Text(
            _currentMonth.longMonthName,
            style: const TextStyle(fontSize: 18,
            fontWeight: FontWeight.bold,),
          ),
          const SizedBox(width: 20),
          DropdownButton<int>(
            value: selectedYear,
            items: years.map((year) {
              return DropdownMenuItem<int>(
                value: year,
                child: Text(year.toString()),
              );
            }).toList(),
            onChanged: (int? newValue) {
              setState(() {
                selectedYear = newValue ?? selectedYear;
                // Reset to Muharram (month 1) when year changes
                _currentMonth = Hijriyah.hijri(selectedYear, 1, 1);
                _pageController.jumpToPage(0);
              });
            },
          ),
          const SizedBox(width: 20),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: (_pageController.hasClients && _pageController.page! < (12 * 23 - 1))
                ? () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                : null, // Disable if at last page
          ),
          
        ],
      ),
    );
  }

  Widget _buildWeeks() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ...['Ahad','Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu' ].map(_buildWeekDay)
        ],
      ),
    );
  }

  Widget _buildWeekDay(String day) {
    Color txtColor = Colors.black;
    if(day == "Ahad"){
      txtColor = Colors.red;
    }
    if(day == "Jumat"){
      txtColor = Colors.green;
    }
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
      child: Text(
        day,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color:txtColor,),
      ),
    );
  }

  Widget _dayCell(int tgl, String psrn, DateTime masehi) {
    Color bgColor = Colors.white;
    Color bdColor = Colors.black;
    final now = DateTime.now();
    final today = DateTime(now.year,now.month,now.day);
    final msh = DateTime(masehi.year,masehi.month,masehi.day);
    if(msh == today){
      bgColor = Colors.blueAccent;
    }
    if(tgl == 13|| tgl == 14 || tgl==15){
      bgColor = Colors.yellowAccent;
      bdColor = Colors.deepOrange;
    }
    if(masehi.weekday == 7){
      bgColor = Colors.redAccent;
    }
    if(masehi.weekday == 5){
      bgColor = Colors.greenAccent;
    }
    

    return Container(
      margin: const EdgeInsets.all(2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color:bdColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.topRight,
              child: Card(
                color: bgColor,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    DateFormat('dd/MM/yy').format(masehi),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "$tgl",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 0, 0)
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            // child: Text(psrn),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                psrn
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _calGrid(int hijriMonth, int yearCh) {
    int weekdayOfFirstDay = _currentMonth.wkDay;
     if (weekdayOfFirstDay == 7) {
      weekdayOfFirstDay = 0;
    }
    int totalCells = _currentMonth.lengthOfMonth + weekdayOfFirstDay ;
    String myPsrn = _currentMonth.nmPasaran;
    
    int rows = (totalCells / 7).ceil();
    int itemCount = rows * 7;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.6,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < weekdayOfFirstDay || index >= _currentMonth.lengthOfMonth + weekdayOfFirstDay ) {
          return const SizedBox.shrink();
        }
        return _dayCell(
          index - weekdayOfFirstDay + 1,
          getPasaranOffset(index - weekdayOfFirstDay, myPsrn),
          getMasehi(_currentMonth.hYear,_currentMonth.hMonth,_currentMonth.hDay).add(Duration(days: index - weekdayOfFirstDay)),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Align(
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "Copyleft 🄯 1446 acepby All Right Reversed inspired by falakmu.id/khgt",
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }
}
