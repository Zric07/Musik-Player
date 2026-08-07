import 'dart:io';

import 'package:flutter/widgets.dart';

ImageProvider? fileProvider(String path) => FileImage(File(path));
