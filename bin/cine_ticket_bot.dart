import 'package:cine_ticket_bot/algorithm.dart';
import 'package:puppeteer/puppeteer.dart';
import 'package:teledart/telegram.dart';

/// Params
List<String> movieTittle = ['spider', 'spiderman']; /// Part of the title of the target movie
bool isPreSale = false; /// If the bot has to search on the pre sale movies list
int seatsToBuy = 9; /// The desired number of seats to buy
String desiredLetter = 'J'; /// The first row to search (the center of the search)
int maxClusterDistance = 2; /// The max desired distance between clusters (2 means 1 empty seat between clusters)
int maxClusterCenterDistance = 10; /// The max desired distance of the columns to the center of the room (To don't buy to far of the center)
int maxRowRange = 7; /// The max desired distance of the rows to the center of the room (To don't buy to far of the center)

/// User params
String firstName = 'Pepito Fabian';
String lastName = 'Perez Lopez';
String email = 'test@test.com';
String phone = '1111111111';
String idDocument = '2222222222';

/// Card params
String cardNumber = '1111111111111';
String cardName = 'Pepito Perez';
String cardDate = '10/2050';
String cardCode = '000';

/// Telegram params. Used to send alert messages
String botToken = '';
String chatId = '';


void main() async {
  var browser = await puppeteer.launch(headless: false);

  while(true) {
    try {
      var page = await browser.newPage();
      await runApp(page);
      break;
    }
    catch (error) {
      print(error);
    }
  }
}

Future<void> runApp(dynamic page) async {
  await page.goto("https://www.cinemark-peru.com/peliculas");
  await page.waitForSelector('.form-control');
  await Future.delayed(Duration(milliseconds: 4000));
  var modals = await page.$$('.modal-theatre-select-body');
  var modal = modals[1];
  var buttons = await modal.$$('.form-control');

  await buttons.first.select(['[object Object]']);
  await clickOnNextButton(page, 4000);

  /// This awaits to the movie on the page
  await searchMovie(page);

  await searchXDTime(page);

  await fillUserData(page);

  /// Selects the general seat
  await page.waitForSelector('.buy-box-container');
  var seatTypes = await page.$$('.buy-box-container');
  var comboSelect;
  if (seatTypes.length == 1) {
    comboSelect = await seatTypes[0].$$('.buy-combo');
  }
  else {
    comboSelect = await seatTypes[1].$$('.buy-combo');
  }
  var seatSelect = await comboSelect[0].$('select');
  seatSelect.select([seatsToBuy.toString()]);
  await clickOnNextButton(page, 1);

  int maxColumn = 0;
  var sittingScheme = await page.waitForSelector('.buy-seating-scheme');
  var rows = await sittingScheme!.$$('.room-row');
  List<List<Seat>> allEmptySeats = [];
  for (int i = 0; i < rows.length; i++) {
    var isEmptyRow = await rows[i].$$('.empty-row');
    if (isEmptyRow.isNotEmpty) continue;
    var emptySeats = await rows[i].$$('.empty');

    /// Verify the max column
    var allSeats = await rows[i].$$('.room-seat');
    if (allSeats.length > maxColumn) maxColumn = allSeats.length;

    List<Seat> seats = [];
    for (var seat in emptySeats) {
      var index = await seat.evaluate("node => node.textContent");
      var disabled = await seat.evaluate("node => node.getAttribute('disabled')");
      if (disabled != null) continue;
      seats.add(Seat(
        seat,
        int.parse(index.toString().trim().split(' ').first.trim()),
        allEmptySeats.length,
      ));
    }
    allEmptySeats.add(seats);
  }

  /// Get better seats
  TicketAlgorithm algorithm = TicketAlgorithm();
  int desiredRow = letters.indexOf(desiredLetter);
  Cluster? desiredRows = algorithm.searchSeats(
    allEmptySeats,
    seatsToBuy,
    desiredRow,
    maxColumn,
    maxClusterDistance,
    maxClusterCenterDistance,
    maxRowRange,
    allEmptySeats.length,
  );

  if (desiredRows == null) {
    sendTelegramMessage("Check: No tickets");
    throw ("No tickets :(");
  }

  desiredRows.printCluster();

  int center = algorithm.columnCenter;
  int range = 0;
  int total = 0;
  int seatIndex = 0;
  desiredRows.cluster.sort((a, b) => a.number.compareTo(b.number));

  while (true){
    if(total == seatsToBuy) break;
    if (range == 0) {
      seatIndex = desiredRows.cluster.indexWhere((element) => element.number == center);
      if (seatIndex != -1) {
        await desiredRows.cluster[seatIndex].element.click();
        total++;
      }
    }
    else {
      seatIndex = desiredRows.cluster.indexWhere((element) => element.number == center + range);
      if (seatIndex != -1) {
        await desiredRows.cluster[seatIndex].element.click();
        total++;
        if(total == seatsToBuy) break;
      }
      seatIndex = desiredRows.cluster.indexWhere((element) => element.number == center - range);
      if (seatIndex != -1) {
        await desiredRows.cluster[seatIndex].element.click();
        total++;
      }
    }
    range++;
  }

  await clickOnNextButton(page, 2000);

  var alerts = await page.$$('.alert-notification');
  if (alerts.isNotEmpty) {
    sendTelegramMessage("Check out: Error alert when buying");
    throw("Error alert when buying");
  }

  /// Food
  await clickOnNextButton(page, 1);

  await page.waitForSelector('.payment-method-container');
  await page.waitForSelector('input[name="number"]');
  await page.type('input[name="number"]', cardNumber);
  await page.type('input[name="name"]', cardName);
  await page.type('input[name="expiry"]', cardDate);
  await page.type('input[name="cvc"]', cardCode);

  sendTelegramMessage("The seats are ready for purchase!!!");

  await Future.delayed(Duration(hours: 5));
}


Future<void> searchMovie(dynamic page) async {
  while(true) {
    var moviesBox;
    if (isPreSale) {
      moviesBox = await page.waitForSelector('div[id="sectionPreSale"]');
    }
    else {
      moviesBox = await page.waitForSelector('.movies-container');
    }
    var movies = await moviesBox?.$$('.movie-box-container');
    for (var movie in movies!) {
      var aElement = await movie.$('.hover-content');
      var movieUrl = await aElement.evaluate("node => node.getAttribute('href')") as String;
      var params = movieUrl.split('?')[1].split('&');
      bool flag = false;
      for (var param in params) {
        var tokens = param.split('=');
        if (tokens.first == 'pelicula') {
          flag = movieTittle.any((element) => tokens.last.contains(element));
        }
        if (flag) break;
      }
      if (flag) {
        var goShow = await movie.$('.go-show');
        await goShow.click();
        await goShow.click();
        sendTelegramMessage("The movie is already there!!!!!");
        await Future.delayed(Duration(seconds: 3));
        return;
      }
    }
    await page.reload();
    await Future.delayed(Duration(seconds: 4));
  }
}

Future<void> searchXDTime(dynamic page) async {
  await page.waitForSelector('.box-movie-format');
  var formats = await page.$$('.box-movie-format');
  for (var format in formats) {
    var tag = await format.$$('.tag-XD');
    if (tag.isEmpty) continue;
    var times = await format.$$('.btn-buy');
    await times.first.click();
    await Future.delayed(Duration(milliseconds: 300));
    await (await page.waitForSelector('a.cta-buy'))?.click();
    return;
  }
  sendTelegramMessage("XD time don't found");
  var times = await formats.first.$$('.btn-buy');
  await times.first.click();
  await Future.delayed(Duration(milliseconds: 300));
  await (await page.waitForSelector('a.cta-buy'))?.click();
}

Future<void> fillUserData(dynamic page) async {
  var loginSelector = await page.waitForSelector('.login-selector');
  var loginButtons = await loginSelector?.$$('button');
  await loginButtons!.last.click();
  await page.type('input[name="firstname"]', firstName);
  await page.type('input[name="lastname"]', lastName);
  await page.type('input[name="email"]', email);
  await page.type('input[name="phone"]', phone);
  await page.type('input[name="docu"]', idDocument);
  await clickOnNextButton(page, 1);
}

Future<void> clickOnNextButton(dynamic page, int milliseconds) async {
  var nextButton = await page.waitForSelector('button.next');
  await nextButton?.click();
  await Future.delayed(Duration(milliseconds: milliseconds));
}

void printSeats(List<List<Seat>> allEmptySeats) {
  for (int i = 0; i < allEmptySeats.length; i++) {
    for (var tt in allEmptySeats[i]) {
    print(letters[tt.row] + '-' + tt.number.toString());
    }
  }
}

Future<void> sendTelegramMessage (String message) async{
  if (botToken != '' && chatId != '') {
    var telegram = Telegram(botToken);
    await telegram.sendMessage(chatId, message);
  }
}

