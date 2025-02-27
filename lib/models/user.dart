import 'package:flutter/cupertino.dart';
import 'package:vikunja_app/global.dart';

class User {
  final int id;
  final String name, username;
  final DateTime created, updated;

  User({
    this.id = 0,
    this.name = '',
    required this.username,
    DateTime? created,
    DateTime? updated,
  })  : this.created = created ?? DateTime.now(),
        this.updated = updated ?? DateTime.now();

  User.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json.containsKey('name') ? json['name'] : '',
        username = json['username'],
        created = DateTime.parse(json['created']),
        updated = DateTime.parse(json['updated']);

  toJSON() => {
        'id': id,
        'name': name,
        'username': username,
        'created': created.toUtc().toIso8601String(),
        'updated': updated.toUtc().toIso8601String(),
      };

  String avatarUrl(BuildContext context) {
    return VikunjaGlobal.of(context).client.base + "/avatar/${this.username}";
  }
}

class UserTokenPair {
  final User? user;
  final String? token;
  final int error;
  final String errorString;
  UserTokenPair(this.user, this.token, {this.error = 0, this.errorString = ""});
}

class BaseTokenPair {
  final String base;
  final String token;
  BaseTokenPair(this.base, this.token);
}
