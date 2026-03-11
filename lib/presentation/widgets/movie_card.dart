
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:riyo/models/movie.dart';
import 'package:riyo/presentation/widgets/shimmer_loading.dart';

class MovieCard extends StatefulWidget {
  final Movie movie;
  final double height;

  const MovieCard({super.key, required this.movie, this.height = 200});

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
      onTap: () {
        final id = widget.movie.backendId ?? widget.movie.id.toString();
        context.push('/movie/$id');
      },
      child: Stack(
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: SizedBox(
              height: widget.height,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: widget.movie.posterPath.isNotEmpty
                  ? (widget.movie.posterPath.startsWith('http') ? widget.movie.posterPath : 'https://image.tmdb.org/t/p/w500${widget.movie.posterPath}')
                  : 'https://picsum.photos/seed/${widget.movie.id}/200/300',
                fit: BoxFit.cover,
                memCacheHeight: (widget.height * 2).toInt(),
                memCacheWidth: (widget.height * 1.4).toInt(), // Aspect ratio ~2:3
                placeholder: (context, url) => ShimmerLoading.rectangular(height: widget.height),
                errorWidget: (context, url, error) => const Center(child: Icon(Icons.movie, color: Colors.white24)),
              ),
            ),
          ),
          if (widget.movie.contentType == 'premium')
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.yellow,
                  borderRadius: BorderRadius.circular(4),
                ),
                      child: const Text('PREMIUM', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900)),
              ),
            ),
          if (widget.movie.isDownloaded)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 16),
              ),
            ),
          if (widget.movie.isDownloading)
            Positioned(
              bottom: 4,
              left: 4,
              right: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: widget.movie.downloadProgress,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent),
                  minHeight: 3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
