import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riyo/providers/media_sniffer_provider.dart';
import 'package:go_router/go_router.dart';

class MediaSnifferScreen extends StatefulWidget {
  const MediaSnifferScreen({super.key});

  @override
  State<MediaSnifferScreen> createState() => _MediaSnifferScreenState();
}

class _MediaSnifferScreenState extends State<MediaSnifferScreen> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _handleSniff() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      context.read<MediaSnifferProvider>().sniffUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Sniffer (1DM Style)'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      hintText: 'Enter URL to sniff...',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _handleSniff,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  ),
                  child: const Icon(Icons.search),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Consumer<MediaSnifferProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.purple),
                          SizedBox(height: 16),
                          Text('Sniffing network traffic...', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    );
                  }

                  if (provider.error != null) {
                    return Center(child: Text(provider.error!, style: const TextStyle(color: Colors.red)));
                  }

                  if (provider.detectedResources.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.link_off, size: 64, color: Colors.white24),
                          SizedBox(height: 16),
                          Text('No media streams detected yet.', style: TextStyle(color: Colors.white24)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: provider.detectedResources.length,
                    itemBuilder: (context, index) {
                      final resource = provider.detectedResources[index];
                      return Card(
                        color: Colors.white10,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(
                            resource.type == 'hls' ? Icons.stream : Icons.movie,
                            color: Colors.purple,
                          ),
                          title: Text(
                            resource.url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text('Type: ${resource.type.toUpperCase()}', style: const TextStyle(fontSize: 12, color: Colors.white54)),
                          trailing: IconButton(
                            icon: const Icon(Icons.play_arrow, color: Colors.green),
                            onPressed: () {
                              context.push('/movie/external/play?url=${Uri.encodeComponent(resource.url)}');
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
