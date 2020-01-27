import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fund_tracker/models/preferences.dart';
import 'package:fund_tracker/services/databaseWrapper.dart';
import 'package:fund_tracker/shared/library.dart';
import 'package:fund_tracker/shared/loader.dart';
import 'package:fund_tracker/shared/mainDrawer.dart';
import 'package:provider/provider.dart';

class PreferencesForm extends StatefulWidget {
  @override
  _PreferencesFormState createState() => _PreferencesFormState();
}

class _PreferencesFormState extends State<PreferencesForm> {
  final _formKey = GlobalKey<FormState>();

  String _limit = '';
  DateTime _limitByDate;
  bool _isLimitDaysEnabled;
  bool _isLimitPeriodsEnabled;
  bool _isLimitByDateEnabled;
  bool _wasUpdated = false;

  @override
  Widget build(BuildContext context) {
    final _user = Provider.of<FirebaseUser>(context);
    final _prefs = Provider.of<Preferences>(context);

    if (_prefs != null) {
      _isLimitDaysEnabled = _isLimitDaysEnabled != null
          ? _isLimitDaysEnabled
          : _prefs.isLimitDaysEnabled;

      _isLimitPeriodsEnabled = _isLimitPeriodsEnabled != null
          ? _isLimitPeriodsEnabled
          : _prefs.isLimitPeriodsEnabled;

      _isLimitByDateEnabled = _isLimitByDateEnabled != null
          ? _isLimitByDateEnabled
          : _prefs.isLimitByDateEnabled;
    }

    return Scaffold(
      drawer: MainDrawer(_user),
      appBar: AppBar(
        title: Text('Preferences'),
      ),
      body: _prefs == null
          ? Loader()
          : Container(
              padding: EdgeInsets.symmetric(
                vertical: 20.0,
                horizontal: 10.0,
              ),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    SizedBox(height: 20.0),
                    Center(
                      child:
                          Text('Limit # of Days/Periods prior to current date'),
                    ),
                    SizedBox(height: 20.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        Expanded(
                          child: FlatButton(
                            padding: EdgeInsets.all(15.0),
                            color: _isLimitDaysEnabled
                                ? Theme.of(context).primaryColor
                                : Colors.grey[100],
                            child: Text(
                              'Days',
                              style: TextStyle(
                                  fontWeight: _isLimitDaysEnabled
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: _isLimitDaysEnabled
                                      ? Colors.white
                                      : Colors.black),
                            ),
                            onPressed: () => setState(() {
                              _isLimitDaysEnabled = true;
                              _isLimitPeriodsEnabled = false;
                              _isLimitByDateEnabled = false;
                            }),
                          ),
                        ),
                        Expanded(
                          child: FlatButton(
                            padding: EdgeInsets.all(15.0),
                            color: _isLimitPeriodsEnabled
                                ? Theme.of(context).primaryColor
                                : Colors.grey[100],
                            child: Text(
                              'Periods',
                              style: TextStyle(
                                  fontWeight: _isLimitPeriodsEnabled
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: _isLimitPeriodsEnabled
                                      ? Colors.white
                                      : Colors.black),
                            ),
                            onPressed: () => setState(() {
                              _isLimitPeriodsEnabled = true;
                              _isLimitDaysEnabled = false;
                              _isLimitByDateEnabled = false;
                            }),
                          ),
                        ),
                        Expanded(
                          child: FlatButton(
                            padding: EdgeInsets.all(15.0),
                            color: _isLimitByDateEnabled
                                ? Theme.of(context).primaryColor
                                : Colors.grey[100],
                            child: Text(
                              'Start Date',
                              style: TextStyle(
                                  fontWeight: _isLimitByDateEnabled
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: _isLimitByDateEnabled
                                      ? Colors.white
                                      : Colors.black),
                            ),
                            onPressed: () => setState(() {
                              _isLimitByDateEnabled = true;
                              _isLimitDaysEnabled = false;
                              _isLimitPeriodsEnabled = false;
                            }),
                          ),
                        ),
                      ],
                    ),
                    _isLimitByDateEnabled
                        ? FlatButton(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(getDate(
                                    _limitByDate ?? _prefs.limitByDate)),
                                Icon(Icons.date_range),
                              ],
                            ),
                            onPressed: () async {
                              DateTime date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now().subtract(
                                  Duration(days: 365),
                                ),
                                lastDate: DateTime.now().add(
                                  Duration(days: 365),
                                ),
                              );
                              if (date != null) {
                                setState(() => _limitByDate = date);
                              }
                            },
                          )
                        : TextFormField(
                            autovalidate: _limit.isNotEmpty,
                            validator: (val) {
                              if (val.isNotEmpty) {
                                if (val.contains('.')) {
                                  return 'This value must be an integer.';
                                } else if (int.parse(val) <= 0) {
                                  return 'This value must be greater than 0';
                                }
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText:
                                  'Current Value: ${_isLimitDaysEnabled ? _prefs.limitDays : _prefs.limitPeriods}',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (val) {
                              setState(() => _limit = val);
                            },
                          ),
                    SizedBox(height: 20.0),
                    RaisedButton(
                      color: Theme.of(context).primaryColor,
                      child:
                          Text('Save', style: TextStyle(color: Colors.white)),
                      onPressed: () async {
                        if (_formKey.currentState.validate()) {
                          int limitDays = _limit != '' && _isLimitDaysEnabled
                              ? int.parse(_limit)
                              : _prefs.limitDays;
                          int limitPeriods =
                              _limit != '' && _isLimitPeriodsEnabled
                                  ? int.parse(_limit)
                                  : _prefs.limitPeriods;
                          DateTime limitByDate =
                              _limitByDate != null && _isLimitByDateEnabled
                                  ? _limitByDate
                                  : _prefs.limitByDate;

                          Preferences prefs = Preferences(
                            pid: _user.uid,
                            limitDays: limitDays,
                            isLimitDaysEnabled: _isLimitDaysEnabled ??
                                _prefs.isLimitDaysEnabled,
                            limitPeriods: limitPeriods,
                            isLimitPeriodsEnabled: _isLimitPeriodsEnabled ??
                                _prefs.isLimitPeriodsEnabled,
                            limitByDate: limitByDate,
                            isLimitByDateEnabled: _isLimitByDateEnabled ??
                                _prefs.isLimitByDateEnabled,
                          );
                          DatabaseWrapper(_user.uid).updatePreferences(prefs);
                          displayUpdated();
                        }
                      },
                    ),
                    SizedBox(height: 20.0),
                    _wasUpdated ? Center(child: Text('Updated!')) : Container(),
                    SizedBox(height: 60.0),
                    RaisedButton(
                      child: Text('Reset Categories'),
                      onPressed: () {
                        DatabaseWrapper(_user.uid).resetCategories();
                      },
                    ),
                    SizedBox(height: 20.0),
                    RaisedButton(
                      child: Text('Reset Preferences'),
                      onPressed: () {
                        DatabaseWrapper(_user.uid).resetPreferences();
                      },
                    )
                  ],
                ),
              ),
            ),
    );
  }

  void displayUpdated() {
    setState(() => _wasUpdated = true);
    Future.delayed(
      Duration(seconds: 1),
      () => setState(() => _wasUpdated = false),
    );
  }
}
