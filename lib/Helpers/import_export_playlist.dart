

import 'dart:convert';
import 'dart:io';

import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/Helpers/picker.dart';
import 'package:blackhole/Helpers/songs_count.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> exportPlaylist(
  BuildContext context,
  String playlistName,
  String showName,
) async {
  final String dirPath = await Picker.selectFolder(
    context: context,
    message: AppLocalizations.of(context)!.selectExportLocation,
  );
  if (dirPath == '') {
    ShowSnackBar().showSnackBar(
      context,
      '${AppLocalizations.of(context)!.failedExport} "$showName"',
    );
    return;
  }
  await Hive.openBox(playlistName);
  final Box playlistBox = Hive.box(playlistName);
  final Map _songsMap = playlistBox.toMap();
  final String _songs = json.encode(_songsMap);
  final File file =
      await File('$dirPath/$showName.json').create(recursive: true);
  await file.writeAsString(_songs);
  ShowSnackBar().showSnackBar(
    context,
    '${AppLocalizations.of(context)!.exported} "$showName"',
  );
}

Future<void> sharePlaylist(
  BuildContext context,
  String playlistName,
  String showName,
) async {
  final Directory appDir = await getApplicationDocumentsDirectory();
  final String temp = appDir.path;

  await Hive.openBox(playlistName);
  final Box playlistBox = Hive.box(playlistName);
  final Map _songsMap = playlistBox.toMap();
  final String _songs = json.encode(_songsMap);
  final File file = await File('$temp/$showName.json').create(recursive: true);
  await file.writeAsString(_songs);

  await Share.shareFiles(
    [file.path],
    text: AppLocalizations.of(context)!.playlistShareText,
  );
  await Future.delayed(const Duration(seconds: 10), () {});
  if (await file.exists()) {
    await file.delete();
  }
}

Future<List> importPlaylist(BuildContext context, List playlistNames) async {
  try {
    final String temp = await Picker.selectFile(
      context: context,
      ext: ['json'],
      message: AppLocalizations.of(context)!.selectJsonImport,
    );
    if (temp == '') {
      ShowSnackBar().showSnackBar(
        context,
        AppLocalizations.of(context)!.failedImport,
      );
      return playlistNames;
    }

    final RegExp avoid = RegExp(r'[\.\\\*\:\"\?#/;\|]');
    String playlistName = temp
        .split('/')
        .last
        .replaceAll('.json', '')
        .replaceAll(avoid, '')
        .replaceAll('  ', ' ');

    final File file = File(temp);
    final String finString = await file.readAsString();
    final Map _songsMap = json.decode(finString) as Map;
    final List _songs = _songsMap.values.toList();
    // playlistBox.put(mediaItem.id.toString(), info);
    // Hive.box(play)

    if (playlistName.trim() == '') {
      playlistName = 'Playlist ${playlistNames.length}';
    }
    if (playlistNames.contains(playlistName)) {
      playlistName = '$playlistName (1)';
    }
    playlistNames.add(playlistName);

    await Hive.openBox(playlistName);
    final Box playlistBox = Hive.box(playlistName);
    await playlistBox.putAll(_songsMap);

    addSongsCount(
      playlistName,
      _songs.length,
      _songs.length >= 4
          ? _songs.sublist(0, 4)
          : _songs.sublist(0, _songs.length),
    );
    ShowSnackBar().showSnackBar(
      context,
      '${AppLocalizations.of(context)!.importSuccess} "$playlistName"',
    );
    return playlistNames;
  } catch (e) {
    ShowSnackBar().showSnackBar(
      context,
      AppLocalizations.of(context)!.failedImport,
    );
  }
  return playlistNames;
}
