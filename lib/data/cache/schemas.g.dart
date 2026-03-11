// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schemas.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MovieCacheAdapter extends TypeAdapter<MovieCache> {
  @override
  final int typeId = 0;

  @override
  MovieCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MovieCache(
      id: fields[0] as String,
      title: fields[1] as String,
      overview: fields[2] as String,
      posterPath: fields[3] as String,
      backdropPath: fields[4] as String?,
      releaseDate: fields[5] as String,
      voteAverage: fields[6] as double,
      runtime: fields[7] as int?,
      genres: (fields[8] as List?)?.cast<String>(),
      isTvShow: fields[9] as bool,
      contentType: fields[10] as String,
      cachedAt: fields[11] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MovieCache obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.overview)
      ..writeByte(3)
      ..write(obj.posterPath)
      ..writeByte(4)
      ..write(obj.backdropPath)
      ..writeByte(5)
      ..write(obj.releaseDate)
      ..writeByte(6)
      ..write(obj.voteAverage)
      ..writeByte(7)
      ..write(obj.runtime)
      ..writeByte(8)
      ..write(obj.genres)
      ..writeByte(9)
      ..write(obj.isTvShow)
      ..writeByte(10)
      ..write(obj.contentType)
      ..writeByte(11)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MovieCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PlaybackProgressCacheAdapter extends TypeAdapter<PlaybackProgressCache> {
  @override
  final int typeId = 3;

  @override
  PlaybackProgressCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlaybackProgressCache(
      movieId: fields[0] as String,
      positionSeconds: fields[1] as int,
      durationSeconds: fields[2] as int,
      lastWatched: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PlaybackProgressCache obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.movieId)
      ..writeByte(1)
      ..write(obj.positionSeconds)
      ..writeByte(2)
      ..write(obj.durationSeconds)
      ..writeByte(3)
      ..write(obj.lastWatched);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaybackProgressCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CategoryCacheAdapter extends TypeAdapter<CategoryCache> {
  @override
  final int typeId = 1;

  @override
  CategoryCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategoryCache(
      name: fields[0] as String,
      cachedAt: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CategoryCache obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HomeSectionCacheAdapter extends TypeAdapter<HomeSectionCache> {
  @override
  final int typeId = 2;

  @override
  HomeSectionCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HomeSectionCache(
      title: fields[0] as String,
      type: fields[1] as String,
      genre: fields[2] as String?,
      movieIds: (fields[3] as List).cast<String>(),
      cachedAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, HomeSectionCache obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.genre)
      ..writeByte(3)
      ..write(obj.movieIds)
      ..writeByte(4)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeSectionCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
