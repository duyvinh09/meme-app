import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class ReceiptClassifier {
  final List<String> labels;
  final List<double> bias;
  final List<String> accents;
  final int size;
  final ByteData weights;
  ReceiptClassifier(this.labels,this.bias,this.accents,this.size,this.weights);

  static Future<ReceiptClassifier> load() async {
    final m=jsonDecode(await rootBundle.loadString('assets/receipt/model.json'));
    return ReceiptClassifier(List<String>.from(m['labels']),List<double>.from(m['bias']),
        List<String>.from(m['accents']),m['size'],await rootBundle.load('assets/receipt/weights.bin'));
  }
  String? suggest(String input) {
    var s=input.toLowerCase();
    for(final group in accents){
      for(final rune in group.runes){s=s.replaceAll(String.fromCharCode(rune),group[0]);}
    }
    s=' '+RegExp('[a-z]+').allMatches(s).map((m)=>m[0]!).join(' ')+' ';
    if(['phong chieu phim','rap chieu phim','lotte cinema','ve xem phim'].any((p)=>s.contains(p))) return 'entertainment';
    final ids=<int>{};
    for(final n in [3,4,5]){
      for(var i=0;i+n<=s.length;i++){
        var h=0;
        for(var j=i;j<i+n;j++){h=(h*31+s.codeUnitAt(j))%size;}
        ids.add(h);
      }
    }
    if(ids.isEmpty)return null;
    final scores=List<double>.from(bias);
    for(var k=0;k<labels.length;k++){
      for(final id in ids){scores[k]+=weights.getFloat32(4*(k*size+id),Endian.little)/sqrt(ids.length);}
    }
    var best=0;
    for(var k=1;k<scores.length;k++){if(scores[k]>scores[best])best=k;}
    final probability=1/scores.fold<double>(0,(sum,v)=>sum+exp(v-scores[best]));
    return labels[best];
  }
}
