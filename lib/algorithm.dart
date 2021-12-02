import 'dart:math';

List<String> letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 
  'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'];

class TicketAlgorithm {

  List<List<Seat>> seats = [];
  int seatsToBuy = 0;
  int desiredRow = 0;
  int columnCenter = 0;
  int maxClusterDistance = 0;
  int maxClusterCenterDistance = 0;
  int maxRowRange = 0;

  Cluster? searchSeats(
    List<List<Seat>> seats,
    int seatsToBuy,
    int desiredRow,
    int maxColumn,
    int maxClusterDistance,
    int maxClusterCenterDistance,
    int maxRowRange,
    int maxRow,
  ) {
    _initValues(
        seats,
        seatsToBuy,
        desiredRow,
        maxColumn,
        maxClusterDistance,
        maxClusterCenterDistance,
        maxRowRange,
    );
    List<List<Cluster>> clusters = _generateClusters();
    Cluster? res = _isValidRow(clusters[this.desiredRow]);
    if (res != null) return res;
    int actualRange = 1;
    while (true) {
      if (actualRange > this.maxRowRange) {
        return null;
      }
      if (this.desiredRow + actualRange < maxRow) {
        res = _isValidRow(clusters[this.desiredRow + actualRange]);
        if (res != null) return res;
      }
      if (this.desiredRow - actualRange >= 0) {
        res = _isValidRow(clusters[this.desiredRow - actualRange]);
        if (res != null) return res;
      }
      actualRange++;
    }
  }

  void _initValues(
    List<List<Seat>> seats,
    int seatsToBuy,
    int desiredRow,
    int maxColumn,
    int maxClusterDistance,
    int maxClusterCenterDistance,
    int maxRowRange,
  ) {
    this.seats = seats;
    this.seatsToBuy = seatsToBuy;
    this.desiredRow = desiredRow;
    columnCenter = (maxColumn / 2).round() - 1;
    this.maxClusterDistance = maxClusterDistance;
    this.maxClusterCenterDistance = maxClusterCenterDistance;
    this.maxRowRange = maxRowRange;

  }

  List<List<Cluster>> _generateClusters() {
    List<List<Cluster>> res = [];
    for (List<Seat> row in seats) {
      row.sort((a, b) => a.number.compareTo(b.number));
      List<Seat> cluster = [];
      List<Cluster> resRow = [];
      int? actual;
      for (Seat seat in row) {
        if (actual == null) {
          actual = seat.number;
          cluster.add(seat);
          continue;
        }
        if (seat.number != actual + 1) {
          resRow.add(Cluster(
            List.from(cluster),
            0
          ));
          cluster.clear();
        }
        cluster.add(seat);
        actual = seat.number;
      }
      if (cluster.isNotEmpty) {
        resRow.add(Cluster(
          List.from(cluster),
          0
        ));
      }
      res.add(resRow);
    }
    return res;
  }

  Cluster? _isValidRow(List<Cluster> rowClusters) {
    int centerIndex = 0;
    int _tempPoints = 1000;
    List<int> points = [];

    /// Find more center cluster
    for (Cluster cluster in rowClusters) {
      points.add(_clusterDistanceToCenter(cluster));
    }
    for (int i = 0; i < rowClusters.length; i++) {
      if (points[i] < _tempPoints) {
        _tempPoints = points[i];
        centerIndex = i;
      }
    }
    if (points[centerIndex] > maxClusterCenterDistance) {
      return null; /// Not valid
    }
    if (rowClusters[centerIndex].cluster.length >= seatsToBuy) {
      return rowClusters[centerIndex]; /// BUY
    }


    List<int> validClusterIndex = [];
    List<int> availableClusters = [];
    Cluster actualCluster = Cluster(
      List.from(rowClusters[centerIndex].cluster),
      0
    );

    for (int i = 0; i < rowClusters.length; i++) {
      if(i == centerIndex) continue;
      availableClusters.add(i);
    }

    /// Join clusters
    while (availableClusters.isNotEmpty) {
      validClusterIndex.clear();
      for (var index in availableClusters) {
        int distance = _clusterDistanceToCluster(
            actualCluster,
            rowClusters[index]
        );
        if (distance <= maxClusterDistance) {
          validClusterIndex.add(index);
        }
      }
      if (validClusterIndex.isEmpty) break;

      /// Get the bigger first
      /// Is missing to verify if the first cluster is bigger than the seatsToBuy
      /// for more efficiency
      validClusterIndex.sort((a,b) => a.compareTo(b) * -1);

      for (var index in validClusterIndex) {
        actualCluster = _joinClusters(actualCluster, rowClusters[index]);
        if (actualCluster.cluster.length >= seatsToBuy) {
          return actualCluster; /// BUY
        }
        availableClusters.remove(index);
      }
    }

    return null;
  }

  int _clusterDistanceToCenter(Cluster cluster) {
    return cluster.cluster.map((e) => _sitDistanceToCenter(e)).reduce(min);
  }

  int _clusterDistanceToCluster(Cluster a, Cluster b) {
    return [(a.maxNumber - b.minNumber).abs(), (a.minNumber - b.maxNumber).abs()].reduce(min);
  }

  int _sitDistanceToCenter(Seat sit) {
    return (columnCenter - sit.number).abs().toInt();
  }

  Cluster _joinClusters(Cluster a, Cluster b) {
    List<Seat> res = [];
    res.addAll(a.cluster);
    res.addAll(b.cluster);
    return Cluster(res, 0);
  }
}


class Seat {

  final element;
  final int number;
  final int row;

  Seat(
    this.element,
    this.number,
    this.row,
  );

}

class Cluster {

  List<Seat> cluster;
  double points;

  Cluster(this.cluster, this.points);

  Iterable<int> get numbers => cluster.map((e) => e.number);
  int get minNumber => numbers.reduce(min);
  int get maxNumber => numbers.reduce(max);

  void printCluster() {
    for (var seat in cluster) {
      print(letters[seat.row] + '-' + seat.number.toString());
    }
  }

}