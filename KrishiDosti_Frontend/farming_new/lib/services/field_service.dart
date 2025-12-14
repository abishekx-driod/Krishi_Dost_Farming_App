import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/field_model.dart';

class FieldService {
  final _fields = FirebaseFirestore.instance.collection("fields");

  Future<void> addField(FieldModel field) async {
    final doc = _fields.doc();
    await doc.set(field.toJson());
  }

  Stream<List<FieldModel>> watchFields() {
    return _fields.snapshots().map((snap) {
      return snap.docs.map((d) => FieldModel.fromJson(d.id, d.data())).toList();
    });
  }

  Future<void> deleteField(String id) async {
    await _fields.doc(id).delete();
  }
}
