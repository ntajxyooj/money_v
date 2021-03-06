import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moneyv3/models/model_payment.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:date_format/date_format.dart';

class FormPayment extends StatefulWidget {
  var id;
  FormPayment(this.id);
  @override
  _FormPaymentState createState() => _FormPaymentState(this.id);
}

class _FormPaymentState extends State<FormPayment> {
  var id;
  _FormPaymentState(this.id);
  final _formKey = GlobalKey<FormState>();
  ModelPayment modelPayment = ModelPayment();

  /*===================== Select date picker =================*/
  Future _chooseDate(BuildContext context, String initialDateString) async {
    var now = new DateTime.now();
    var initialDate = convertToDate(initialDateString) ?? now;
    initialDate = (initialDate.year >= 1900 && initialDate.isBefore(now)
        ? initialDate
        : now);

    var result = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: new DateTime(2018),
        lastDate: new DateTime(9999));

    if (result == null) return;

    setState(() {
      modelPayment.date.text = new DateFormat('yyyy-MM-dd').format(result);
    });
  }

  DateTime convertToDate(String input) {
    try {
      var d = new DateFormat('yyyy-MM-dd').parseStrict(input);
      return d;
    } catch (e) {
      return null;
    }
  }

  /*================== load data type payment =================*/
  List<String> listtypename = [''];
  Map<String, dynamic> listtype = {};
  Future listtypepay() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      modelPayment.user_id = prefs.get('token');
    });
    Firestore.instance.collection('type_pay').where('status',isEqualTo:true).snapshots().listen((data) {
      data.documents.forEach((talk) {
        if (mounted) {
          setState(() {
            listtypename.add(talk['name'].toString());
            listtype.addAll({talk['name']: talk.documentID});
          });
        }
      });
    });
  }

/*================  create payment ===============*/
  void createpayment() {
    var amount = modelPayment.amount.text
        .substring(0, modelPayment.amount.text.length - 3);
    var y = modelPayment.date.text.substring(0,modelPayment.date.text.length - 6);
    var m = modelPayment.date.text.substring(5,modelPayment.date.text.length - 3);
    var d = modelPayment.date.text.substring(8,modelPayment.date.text.length - 0);
       
    var date=d+'-'+m+'-'+y;
    int sort=int.parse(y+''+m+''+d);

    Firestore.instance.collection("payment").add({
      'amount': int.parse(amount.replaceAll(',', '')),
      'date':date,
      'description': modelPayment.description.text,
      'type_pay_id': modelPayment.type_id,
      'user': modelPayment.user_id,
      'sort':sort,
    });
    Navigator.of(context).pop();
  }

  /*===================== update payment =================*/
  void updatepayment() {
    var amount = modelPayment.amount.text
        .substring(0, modelPayment.amount.text.length - 3);
    var y = modelPayment.date.text.substring(0,modelPayment.date.text.length - 6);
    var m = modelPayment.date.text.substring(5,modelPayment.date.text.length - 3);
    var d = modelPayment.date.text.substring(8,modelPayment.date.text.length - 0);
       
    var date=d+'-'+m+'-'+y;
    int sort=int.parse(y+''+m+''+d);

    Firestore.instance.collection("payment").document(this.id).updateData({
      'amount': int.parse(amount.replaceAll(',', '')),
      'date': date,
      'description': modelPayment.description.text,
      'type_pay_id': modelPayment.type_id,
      'user': modelPayment.user_id,
      'sort':sort,
    });
    Navigator.of(context).pop();
  }

  /*===================== load data update ==================*/
  void loaddataupdate() async {
    if (this.id != null) {
      DocumentSnapshot payment = await Firestore.instance
          .collection('payment')
          .document(this.id)
          .get();
      DocumentSnapshot payment_type = await Firestore.instance
          .collection('type_pay')
          .document(payment['type_pay_id'].toString())
          .get();
      setState(() {
        modelPayment.amount.text = payment['amount'].toString() + '00';
        modelPayment.date.text =
            payment['date'].toString().replaceAll('-', '/');
        modelPayment.description.text = payment['description'].toString();
        modelPayment.type_pay_id.text = payment_type['name'];
        modelPayment.type_id = payment['type_pay_id'];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    listtypepay();
    loaddataupdate();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text('​ປ້ອນ​ລາຍ​ຈ່າຍ'),
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(10),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              InputDecorator(
                decoration: InputDecoration(
                  errorText: (modelPayment.type_pay_id.text.isEmpty)
                      ? "ທ່ານ​ຕ້ອງເລືອກ​ປະ​ເພດ​ລາຍ​ຈ່າຍ"
                      : null,
                  labelText: 'ເລືອກ​ປະ​ເພດ​ລາຍ​ຈ່າຍ',
                  contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0)),
                ),
                isEmpty: modelPayment.type_pay_id == null,
                child: new DropdownButtonHideUnderline(
                  child: new DropdownButton<String>(
                    value: modelPayment.type_pay_id.text,
                    isDense: true,
                    onChanged: (String newValue) {
                      setState(() {
                        modelPayment.type_pay_id.text = newValue;
                        modelPayment.type_id = listtype[newValue];
                      });
                    },
                    items: listtypename.map((value) {
                      return new DropdownMenuItem<String>(
                        value: value,
                        child: new Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ),
              SizedBox(height: 20.0),
              TextFormField(
                controller: modelPayment.amount,
                validator: (value) {
                  if (value.isEmpty || value == '0.00') {
                    return "ທ່ານ​ຕ້ອງ​ປ້​ອນ​ຈຳ​ນວນ​ເງີນ";
                  }
                },
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'ຈຳນວນ​ເງີນຈ່າຍ',
                  contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0)),
                ),
              ),
              SizedBox(height: 20.0),
              TextFormField(
                controller: modelPayment.description,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'ອະ​ທີ​ບາຍ​ຈ່າຍ​ຍັງ',
                  contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0)),
                ),
              ),
              SizedBox(height: 20.0),
              InkWell(
                onTap: () => _chooseDate(context, modelPayment.date.text),
                child: IgnorePointer(
                  child: TextFormField(
                    // validator: widget.validator,
                    controller: modelPayment.date,
                    validator: (value) {
                      if (value.isEmpty) {
                        return "ທ່ານ​ຕ້ອງ​ເລືອກວັນ​ທີ່";
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'ວັນ​ທີ່​ຈ່າຍ',
                      contentPadding:
                          EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5.0)),
                      suffixIcon: Icon(Icons.date_range),
                    ),
                  ),
                ),
              ),
              RaisedButton.icon(
                icon: Icon(
                  Icons.save,
                  color: Colors.white,
                ),
                label: Text(
                  'ບັນ​ທຶກ',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                key: null,
                onPressed: () {
                  if (_formKey.currentState.validate()) {
                    if (this.id != null) {
                      updatepayment();
                    } else {
                      createpayment();
                    }
                  }
                },
                color: Colors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
