import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riyobox/providers/football_provider.dart';
import 'package:riyobox/models/football.dart';

class SportsScreen extends StatefulWidget {
  const SportsScreen({super.key});

  @override
  State<SportsScreen> createState() => _SportsScreenState();
}

class _SportsScreenState extends State<SportsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final provider = Provider.of<FootballProvider>(context, listen: false);
      provider.fetchAll();
      provider.startLivePolling();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF141414),
        appBar: AppBar(
          backgroundColor: const Color(0xFF141414),
          title: const Text('FOOTBALL', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          actions: [
            _buildLeagueSelector(context),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search matches, teams or players...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                const TabBar(
                  indicatorColor: Colors.yellow,
                  labelColor: Colors.yellow,
                  unselectedLabelColor: Colors.white70,
                  tabs: [
                    Tab(text: 'MATCHES'),
                    Tab(text: 'STANDINGS'),
                    Tab(text: 'TEAMS'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: Consumer<FootballProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.fixtures.isEmpty && provider.teams.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: Colors.yellow));
            }

            if (provider.error != null && provider.fixtures.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('Error: ${provider.error}', style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.fetchAll(),
                      child: const Text('Retry'),
                    )
                  ],
                ),
              );
            }

            return TabBarView(
              children: [
                _buildMatchesTab(provider.fixtures),
                _buildStandingsTab(provider.standings),
                _buildTeamsTab(provider.teams),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLeagueSelector(BuildContext context) {
    final provider = Provider.of<FootballProvider>(context);
    final leagues = [
      {'id': 39, 'name': 'Premier League'},
      {'id': 140, 'name': 'La Liga'},
      {'id': 78, 'name': 'Bundesliga'},
      {'id': 135, 'name': 'Serie A'},
      {'id': 61, 'name': 'Ligue 1'},
    ];

    return PopupMenuButton<int>(
      icon: const Icon(Icons.filter_list, color: Colors.yellow),
      onSelected: (int id) {
        provider.setLeague(id);
      },
      itemBuilder: (BuildContext context) {
        return leagues.map((league) {
          return PopupMenuItem<int>(
            value: league['id'] as int,
            child: Text(league['name'] as String),
          );
        }).toList();
      },
    );
  }

  Widget _buildMatchesTab(List<FootballFixture> fixtures) {
    final filtered = fixtures.where((f) {
      return f.homeTeam.toLowerCase().contains(_searchQuery) ||
             f.awayTeam.toLowerCase().contains(_searchQuery) ||
             f.leagueName.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) return const Center(child: Text('No matches found', style: TextStyle(color: Colors.white)));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final fixture = filtered[index];
        return Card(
          color: const Color(0xFF262626),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(fixture.leagueName, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Image.network(fixture.homeLogo, height: 40),
                          const SizedBox(height: 8),
                          Text(fixture.homeTeam, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Text(
                            fixture.homeGoals != null ? '${fixture.homeGoals} - ${fixture.awayGoals}' : 'VS',
                            style: const TextStyle(color: Colors.yellow, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(fixture.status, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                          if (fixture.elapsed != null)
                            Text('${fixture.elapsed}\'', style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Image.network(fixture.awayLogo, height: 40),
                          const SizedBox(height: 8),
                          Text(fixture.awayTeam, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStandingsTab(List<FootballStanding> standings) {
    final filtered = standings.where((s) => s.teamName.toLowerCase().contains(_searchQuery)).toList();

    if (filtered.isEmpty) return const Center(child: Text('No standings found', style: TextStyle(color: Colors.white)));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('#', style: TextStyle(color: Colors.white))),
            DataColumn(label: Text('TEAM', style: TextStyle(color: Colors.white))),
            DataColumn(label: Text('P', style: TextStyle(color: Colors.white))),
            DataColumn(label: Text('W', style: TextStyle(color: Colors.white))),
            DataColumn(label: Text('D', style: TextStyle(color: Colors.white))),
            DataColumn(label: Text('L', style: TextStyle(color: Colors.white))),
            DataColumn(label: Text('PTS', style: TextStyle(color: Colors.white))),
          ],
          rows: filtered.map((s) => DataRow(
            cells: [
              DataCell(Text('${s.rank}', style: const TextStyle(color: Colors.white))),
              DataCell(Row(
                children: [
                  Image.network(s.teamLogo, height: 20),
                  const SizedBox(width: 8),
                  Text(s.teamName, style: const TextStyle(color: Colors.white)),
                ],
              )),
              DataCell(Text('${s.played}', style: const TextStyle(color: Colors.white70))),
              DataCell(Text('${s.win}', style: const TextStyle(color: Colors.white70))),
              DataCell(Text('${s.draw}', style: const TextStyle(color: Colors.white70))),
              DataCell(Text('${s.lose}', style: const TextStyle(color: Colors.white70))),
              DataCell(Text('${s.points}', style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold))),
            ],
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildTeamsTab(List<Map<String, dynamic>> teams) {
    final filtered = teams.where((t) {
      final teamName = t['team']['name'].toString().toLowerCase();
      return teamName.contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) return const Center(child: Text('No teams found', style: TextStyle(color: Colors.white)));

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final team = filtered[index]['team'];
        final venue = filtered[index]['venue'];
        return InkWell(
          onTap: () => _showTeamDetails(context, team, venue),
          child: Column(
            children: [
              Expanded(child: Image.network(team['logo'])),
              const SizedBox(height: 8),
              Text(team['name'], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      },
    );
  }

  void _showTeamDetails(BuildContext context, dynamic team, dynamic venue) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1B1F),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return _TeamDetailsView(team: team, venue: venue, scrollController: scrollController);
          },
        );
      },
    );
  }
}

class _TeamDetailsView extends StatelessWidget {
  final dynamic team;
  final dynamic venue;
  final ScrollController scrollController;

  const _TeamDetailsView({required this.team, required this.venue, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 4,
          width: 40,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
        ),
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  Image.network(team['logo'], height: 80),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(team['name'], style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        Text('Founded: ${team['founded']}', style: const TextStyle(color: Colors.white54)),
                        Text(team['country'], style: const TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text('STADIUM', style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(venue['image'], height: 150, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 12),
              Text(venue['name'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${venue['city']}, ${venue['address']}', style: const TextStyle(color: Colors.white54)),
              Text('Capacity: ${venue['capacity']}', style: const TextStyle(color: Colors.white54)),
              const SizedBox(height: 32),
              const Text('PLAYERS', style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              const SizedBox(height: 12),
              FutureBuilder<List<FootballPlayerStats>>(
                future: Provider.of<FootballProvider>(context, listen: false).getTeamPlayers(team['id']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.yellow));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No players found', style: TextStyle(color: Colors.white54));
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final player = snapshot.data![index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(backgroundImage: NetworkImage(player.photo)),
                        title: Text(player.name, style: const TextStyle(color: Colors.white)),
                        trailing: Text('${player.goals} G / ${player.assists} A', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 32),
              _buildNotificationToggle(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationToggle() {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isEnabled = false;
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Match Notifications', style: TextStyle(color: Colors.white)),
          subtitle: const Text('Get notified when this team plays', style: TextStyle(color: Colors.white54, fontSize: 12)),
          value: isEnabled,
          activeColor: Colors.yellow,
          onChanged: (value) {
            setState(() => isEnabled = value);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(value ? 'Notifications enabled for ${team['name']}' : 'Notifications disabled')),
            );
          },
        );
      },
    );
  }
}
