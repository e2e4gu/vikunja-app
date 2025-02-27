import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vikunja_app/api/response.dart';
import 'package:vikunja_app/components/string_extension.dart';
import 'package:vikunja_app/global.dart';

import '../main.dart';


class Client {
  GlobalKey<ScaffoldMessengerState>? global_scaffold_key;
  final JsonDecoder _decoder = new JsonDecoder();
  final JsonEncoder _encoder = new JsonEncoder();
  String _token = '';
  String _base = '';
  bool authenticated = false;
  bool ignoreCertificates = false;
  bool showSnackBar = true;

  String get base => _base;
  String get token => _token;

  String? post_body;



  bool operator ==(dynamic otherClient) {
    return otherClient._token == _token;
  }

  Client(this.global_scaffold_key,
      {String? token, String? base, bool authenticated = false}) {
    configure(token: token, base: base, authenticated: authenticated);
  }

  void reload_ignore_certs(bool? val) {
    ignoreCertificates = val ?? false;
    HttpOverrides.global = new IgnoreCertHttpOverrides(ignoreCertificates);
    if(global_scaffold_key == null || global_scaffold_key!.currentContext == null) return;
    VikunjaGlobal
        .of(global_scaffold_key!.currentContext!)
        .settingsManager
        .setIgnoreCertificates(ignoreCertificates);
  }

  get _headers =>
      {
        'Authorization': _token != '' ? 'Bearer $_token' : '',
        'Content-Type': 'application/json',
        'User-Agent': 'Vikunja Mobile App'
      };

  @override
  int get hashCode => _token.hashCode;

  void configure({String? token, String? base, bool? authenticated}) {
    if (token != null)
      _token = token;
    if (base != null) {
      base = base.replaceAll(" ", "");
      if(base.endsWith("/"))
        base = base.substring(0,base.length-1);
      _base = base.endsWith('/api/v1') ? base : '$base/api/v1';
    }
    if (authenticated != null)
      this.authenticated = authenticated;

  }


  void reset() {
    _token = _base = '';
    authenticated = false;
  }

  Future<Response?> get(String url,
      [Map<String, List<String>>? queryParameters]) {
    Uri uri = Uri.tryParse('${this.base}$url')!;
    // why are we doing it like this? because Uri doesnt have setters. wtf.
    print(uri.toString());

    uri = Uri(
      scheme: uri.scheme,
        userInfo: uri.userInfo,
        host: uri.host,
        port: uri.port,
        path: uri.path,
        //queryParameters: {...uri.queryParameters, ...?queryParameters},
        queryParameters: queryParameters,
        fragment: uri.fragment
    );

    return http.get(uri, headers: _headers)
        .then(_handleResponse).onError((error, stackTrace) =>
        _handleError(error, stackTrace));
  }

  Future<Response?> delete(String url) {
    return http.delete(
      '${this.base}$url'.toUri()!,
      headers: _headers,
    ).then(_handleResponse).onError((error, stackTrace) =>
        _handleError(error, stackTrace));
  }

  Future<Response?> post(String url, {dynamic body}) {
    return http.post(
      '${this.base}$url'.toUri()!,
      headers: _headers,
      body: _encoder.convert(body),
    )
        .then(_handleResponse).onError((error, stackTrace) =>
        _handleError(error, stackTrace));
  }

  Future<Response?> put(String url, {dynamic body}) {
    return http.put(
      '${this.base}$url'.toUri()!,
      headers: _headers,
      body: _encoder.convert(body),
    )
        .then(_handleResponse).onError((error, stackTrace) =>
        _handleError(error, stackTrace));
  }

  Response? _handleError(Object? e, StackTrace? st) {
    if(global_scaffold_key == null) return null;
    SnackBar snackBar = SnackBar(
      content: Text("Error on request: " + e.toString()),
      action: SnackBarAction(label: "Clear", onPressed: () => global_scaffold_key!.currentState?.clearSnackBars()),);
    global_scaffold_key!.currentState?.showSnackBar(snackBar);
    return null;
  }

  Map<String, String> headersToMap(HttpHeaders headers) {
    Map<String, String> map = {};
    headers.forEach((name, values) {
      map[name] = values[0].toString();
    });
    return map;
  }


  Error? _handleResponseErrors(http.Response response) {
    if (response.statusCode < 200 ||
        response.statusCode >= 400) {
      Map<String, dynamic> error;
      error = _decoder.convert(response.body);


      final SnackBar snackBar = SnackBar(
        content: Text(
            "Error code " + response.statusCode.toString() + " received."),
        action: globalNavigatorKey.currentContext == null ? null : SnackBarAction(
          label: ("Details"),
          onPressed: () {
            showDialog(
              context: globalNavigatorKey.currentContext!,
                builder: (BuildContext context) =>
                    AlertDialog(
                      title: Text("Error ${response.statusCode}"),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Message: ${error["message"]}", textAlign: TextAlign.start,),
                          Text("Url: ${response.request!.url.toString()}"),
                        ],
                      )
                    )
            );
          },
        ),
      );
      if(global_scaffold_key != null && showSnackBar)
        global_scaffold_key!.currentState?.showSnackBar(snackBar);
      else
        print("error on request: ${error["message"]}");
    }
    return null;
  }

  Response? _handleResponse(http.Response response) {
    Error? error = _handleResponseErrors(response);
    return Response(
        _decoder.convert(response.body), response.statusCode, response.headers);
  }
}

class InvalidRequestApiException extends ApiException {
  final String message;

  InvalidRequestApiException(int errorCode, String path, this.message)
      : super(errorCode, path);

  @override
  String toString() {
    return this.message;
  }
}

class ApiException implements Exception {
  final int errorCode;
  final String path;

  ApiException(this.errorCode, this.path);

  @override
  String toString() {
    return "Can't fetch data from server. (Error-Code: $errorCode)";
  }
}
