class FootballFixture {
  final int id;
  final String date;
  final String status;
  final int? elapsed;
  final String homeTeam;
  final String awayTeam;
  final String homeLogo;
  final String awayLogo;
  final int? homeGoals;
  final int? awayGoals;
  final String leagueName;

  FootballFixture({
    required this.id,
    required this.date,
    required this.status,
    this.elapsed,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeLogo,
    required this.awayLogo,
    this.homeGoals,
    this.awayGoals,
    required this.leagueName,
  });

  factory FootballFixture.fromJson(Map<String, dynamic> json) {
    return FootballFixture(
      id: json['fixture']['id'],
      date: json['fixture']['date'],
      status: json['fixture']['status']['long'],
      elapsed: json['fixture']['status']['elapsed'],
      homeTeam: json['teams']['home']['name'],
      awayTeam: json['teams']['away']['name'],
      homeLogo: json['teams']['home']['logo'],
      awayLogo: json['teams']['away']['logo'],
      homeGoals: json['goals']['home'],
      awayGoals: json['goals']['away'],
      leagueName: json['league']['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fixture': {
        'id': id,
        'date': date,
        'status': {'long': status, 'elapsed': elapsed},
      },
      'teams': {
        'home': {'name': homeTeam, 'logo': homeLogo},
        'away': {'name': awayTeam, 'logo': awayLogo},
      },
      'goals': {'home': homeGoals, 'away': awayGoals},
      'league': {'name': leagueName},
    };
  }
}

class FootballStanding {
  final int rank;
  final String teamName;
  final String teamLogo;
  final int points;
  final int played;
  final int win;
  final int draw;
  final int lose;
  final int goalsFor;
  final int goalsAgainst;

  FootballStanding({
    required this.rank,
    required this.teamName,
    required this.teamLogo,
    required this.points,
    required this.played,
    required this.win,
    required this.draw,
    required this.lose,
    required this.goalsFor,
    required this.goalsAgainst,
  });

  factory FootballStanding.fromJson(Map<String, dynamic> json) {
    return FootballStanding(
      rank: json['rank'],
      teamName: json['team']['name'],
      teamLogo: json['team']['logo'],
      points: json['points'],
      played: json['all']['played'],
      win: json['all']['win'],
      draw: json['all']['draw'],
      lose: json['all']['lose'],
      goalsFor: json['all']['goals']['for'],
      goalsAgainst: json['all']['goals']['against'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'team': {'name': teamName, 'logo': teamLogo},
      'points': points,
      'all': {
        'played': played,
        'win': win,
        'draw': draw,
        'lose': lose,
        'goals': {'for': goalsFor, 'against': goalsAgainst},
      },
    };
  }
}

class FootballPlayerStats {
  final String name;
  final String photo;
  final String teamName;
  final int goals;
  final int assists;
  final int appearances;

  FootballPlayerStats({
    required this.name,
    required this.photo,
    required this.teamName,
    required this.goals,
    required this.assists,
    required this.appearances,
  });

  factory FootballPlayerStats.fromJson(Map<String, dynamic> json) {
    final player = json['player'];
    final statistics = json['statistics'][0];
    return FootballPlayerStats(
      name: player['name'],
      photo: player['photo'],
      teamName: statistics['team']['name'],
      goals: statistics['goals']['total'] ?? 0,
      assists: statistics['goals']['assists'] ?? 0,
      appearances: statistics['games']['appearences'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'player': {'name': name, 'photo': photo},
      'statistics': [
        {
          'team': {'name': teamName},
          'goals': {'total': goals, 'assists': assists},
          'games': {'appearences': appearances},
        }
      ],
    };
  }
}
